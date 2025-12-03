import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:limitless_app/core/services/chat_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); 

  int _selectedTabIndex = 0;
  bool _isLoading = false;
  bool _isUploadingImage = false; 

  String? _avatarUrl; 

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();

  bool _dailySummary = true;
  bool _newTranscriptions = true;
  bool _chatMentions = true;
  bool _upcomingEvents = false;
  bool _aiSuggestions = false;
  bool _autoTranscription = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};

      setState(() {
        _emailController.text = user.email ?? '';
        
        _nameController.text = metadata['name'] ?? '';
        _surnameController.text = metadata['surname'] ?? '';
        _companyController.text = metadata['company'] ?? '';
        _locationController.text = metadata['role'] ?? metadata['location'] ?? '';
        _phoneController.text = metadata['phone'] ?? '';
        
        _avatarUrl = metadata['avatar_url'];
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final imageBytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last; 
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName; 

      await _supabase.storage.from('avatars').uploadBinary(
        filePath,
        imageBytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
      );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase.auth.updateUser(
        UserAttributes(data: { ...user.userMetadata ?? {}, 'avatar_url': imageUrl }),
      );

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'avatar_url': imageUrl,
      });
      await _supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      setState(() {
        _avatarUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Immagine aggiornata!')));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore upload: $e')));
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final company = _companyController.text.trim();
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();

      final updates = UserAttributes(
        data: {
          ...user.userMetadata ?? {},
          'name': name,
          'surname': surname,
          'company': company,
          'role': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );
      await _supabase.auth.updateUser(updates);

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': name,
        'last_name': surname,
        'company': company,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await ChatService().syncCompanyChat(company);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo aggiornato e chat aziendale sincronizzata!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore aggiornamento: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initials = (_nameController.text.isNotEmpty && _surnameController.text.isNotEmpty)
        ? "${_nameController.text[0]}${_surnameController.text[0]}".toUpperCase()
        : "MR";

    final String fullName = "${_nameController.text} ${_surnameController.text}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profilo",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                "Impostazioni account",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildHeaderInfo(initials, fullName),
                    const SizedBox(height: 20),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildTabButton("Account", 0),
                          const SizedBox(width: 8),
                          _buildTabButton("Notifiche", 1),
                          const SizedBox(width: 8),
                          _buildTabButton("Privacy", 2),
                          const SizedBox(width: 8),
                          _buildTabButton("Preferenze", 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFF1F1F5)),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildHeaderInfo(String initials, String fullName) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: (_avatarUrl != null && !_isUploadingImage)
                  ? DecorationImage(
                      image: NetworkImage(_avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
                gradient: (_avatarUrl == null) 
                  ? const LinearGradient(
                      colors: [Color(0xFFB476FF), Color(0xFFFFB4E1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              ),
              child: _isUploadingImage
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : (_avatarUrl == null)
                      ? Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null, 
            ),
            
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _uploadProfileImage, 
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          fullName.isNotEmpty ? fullName : "Utente",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() => _selectedTabIndex = 0);
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text("Modifica Profilo", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Colors.redAccent),
              ),
              icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
              label: const Text("Esci", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAccountSection();
      case 1:
        return _buildNotificationsSection();
      case 2:
        return _buildPrivacySection();
      case 3:
        return _buildPreferencesSection();
      default:
        return _buildAccountSection();
    }
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Informazioni Personali", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildTextField("Nome", _nameController),
        const SizedBox(height: 12),
        _buildTextField("Cognome", _surnameController),
        const SizedBox(height: 12),
        _buildTextField("Email", _emailController, icon: Icons.email_outlined, readOnly: true), 
        const SizedBox(height: 12),
        _buildTextField("Telefono", _phoneController, icon: Icons.phone_outlined),
        const SizedBox(height: 12),
        _buildTextField("Azienda", _companyController, icon: Icons.business),
        const SizedBox(height: 12),
        _buildTextField("Ruolo / Posizione", _locationController, icon: Icons.work_outline),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Salva Modifiche", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _loadUserProfile, 
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Annulla", style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFF1F1F5), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Notifiche Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSwitchTile(
          "Riassunti giornalieri",
          "Ricevi un riepilogo via email ogni sera",
          _dailySummary,
          (v) => setState(() => _dailySummary = v),
        ),
        _buildSwitchTile(
          "Nuove trascrizioni",
          "Notifica quando una registrazione è trascritta",
          _newTranscriptions,
          (v) => setState(() => _newTranscriptions = v),
        ),
        const SizedBox(height: 20),
        const Text("Notifiche Push", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSwitchTile(
          "Menzioni in chat",
          "Quando qualcuno ti menziona in un messaggio",
          _chatMentions,
          (v) => setState(() => _chatMentions = v),
        ),
        _buildSwitchTile(
          "Eventi imminenti",
          "Promemoria per meeting ed eventi",
          _upcomingEvents,
          (v) => setState(() => _upcomingEvents = v),
        ),
        _buildSwitchTile(
          "Suggerimenti AI",
          "Insights e suggerimenti dall'AI assistant",
          _aiSuggestions,
          (v) => setState(() => _aiSuggestions = v),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Privacy dei Dati", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Conservazione", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Quanto tempo conservare le rec.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text("30 giorni", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          "Trascrizioni Automatiche",
          "Attiva trascrizione automatica per tutte le rec.",
          _autoTranscription,
          (v) => setState(() => _autoTranscription = v),
        ),  
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Aspetto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildThemeOption("Chiaro", false),
              _buildThemeOption("Scuro", false),
              _buildThemeOption("Sistema", true),
            ],
          ),
        ),
         const SizedBox(height: 20),

        const Text("Lingua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),

         Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          decoration: BoxDecoration(

            border: Border.all(color: Colors.grey.shade200),

            borderRadius: BorderRadius.circular(12),

          ),

          child: const Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Row(

                children: [

                   Icon(Icons.language, color: Colors.grey),

                   SizedBox(width: 10),

                   Text("Lingua dell'interfaccia"),

                ],

              ),

              Text("Italiano", style: TextStyle(fontWeight: FontWeight.bold)),

            ],

          ),

        ),
      ],
    );
  }

  Widget _buildThemeOption(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}