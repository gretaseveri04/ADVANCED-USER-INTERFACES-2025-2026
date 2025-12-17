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

  // Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();

  // Settings booleans
  bool _dailySummary = true;
  bool _newTranscriptions = true;
  bool _chatMentions = true;
  bool _upcomingEvents = false;
  bool _aiSuggestions = false;
  bool _autoTranscription = true;

  // --- LISTA AZIENDE PER IL PICKER ---
  final List<Map<String, String>> _companies = [
    {'name': 'Politecnico di Milano', 'logo': 'assets/images/politecnicodimilano.png'},
    {'name': 'Politecnico di Torino', 'logo': 'assets/images/politecnicoditorino.png'},
    {'name': 'Google', 'logo': 'assets/images/google.png'},
    {'name': 'Amazon', 'logo': 'assets/images/amazon.png'},
    {'name': 'Apple', 'logo': 'assets/images/apple.png'},
    {'name': 'Samsung', 'logo': 'assets/images/samsung.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Proviamo a prendere i dati dalla tabella profiles (più affidabile dei metadata auth)
      _supabase.from('profiles').select().eq('id', user.id).maybeSingle().then((data) {
        if (data != null && mounted) {
           setState(() {
            _nameController.text = data['first_name'] ?? '';
            _surnameController.text = data['last_name'] ?? '';
            _companyController.text = data['company'] ?? '';
            _locationController.text = data['role'] ?? ''; // Assumendo che tu abbia una colonna 'role' o simile
            // _phoneController.text = ... (se lo salvi nel DB)
            _avatarUrl = data['avatar_url'];
          });
        }
      });
      
      // Fallback: riempiamo email e telefono dai metadata auth se servono
      setState(() {
        _emailController.text = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        if (_phoneController.text.isEmpty) _phoneController.text = metadata['phone'] ?? '';
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

      // Aggiorna auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: { ...user.userMetadata ?? {}, 'avatar_url': imageUrl }),
      );

      // Aggiorna tabella profiles
      await _supabase.from('profiles').update({
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
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

      // 1. Aggiorna Auth Metadata (opzionale, ma utile per sync veloce)
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

      // 2. Aggiorna Tabella Database
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': name,
        'last_name': surname,
        'company': company,
        'role': _locationController.text.trim(), // Assicurati che la colonna esista nel DB
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Sincronizza Chat Aziendale
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

  // --- MENU A TENDINA PER LE AZIENDE ---
  void _showCompanyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Text("Seleziona Azienda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Text("Oppure scrivi manualmente nel campo", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              
              Expanded(
                child: ListView.separated(
                  itemCount: _companies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final company = _companies[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        width: 40, height: 40,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Image.asset(
                          company['logo']!,
                          fit: BoxFit.contain,
                          errorBuilder: (c, o, s) => const Icon(Icons.business, color: Colors.grey),
                        ),
                      ),
                      title: Text(company['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        // Riempie il controller con il nome scelto
                        setState(() {
                          _companyController.text = company['name']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initials = (_nameController.text.isNotEmpty && _surnameController.text.isNotEmpty)
        ? "${_nameController.text[0]}${_surnameController.text[0]}".toUpperCase()
        : "MR";

    final String fullName = "${_nameController.text} ${_surnameController.text}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      // --- HEADER ---
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE0E8FF).withOpacity(0.5),
                const Color(0xFFF8F8FF),
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            const Text(
              "PROFILE",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Settings",
              style: TextStyle(fontSize: 14, color: Colors.grey, letterSpacing: 0.5),
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
                  
                  // TABS
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
  
  // --- HEADER INFO (AVATAR) ---
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
                  ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                  : null,
                gradient: (_avatarUrl == null) 
                  ? const LinearGradient(colors: [Color(0xFFB476FF), Color(0xFFFFB4E1)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              ),
              child: _isUploadingImage
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : (_avatarUrl == null)
                      ? Center(child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)))
                      : null, 
            ),
            
            Positioned(
              right: 0, bottom: 0,
              child: GestureDetector(
                onTap: _uploadProfileImage, 
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(fullName.isNotEmpty ? fullName : "Utente", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_emailController.text, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _selectedTabIndex = 0),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.grey)),
              child: const Text("Modifica Profilo", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.redAccent)),
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
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: return _buildAccountSection();
      case 1: return _buildNotificationsSection();
      case 2: return _buildPrivacySection();
      case 3: return _buildPreferencesSection();
      default: return _buildAccountSection();
    }
  }

  // --- SEZIONE ACCOUNT MODIFICATA PER AZIENDA IBRIDA ---
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
        
        // --- CAMPO AZIENDA CON BOTTONE ---
        _buildTextField(
          "Azienda", 
          _companyController, 
          icon: Icons.business,
          suffixWidget: IconButton( // Aggiungiamo il bottone qui
            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.deepPurple),
            onPressed: _showCompanyPicker,
            tooltip: "Seleziona da lista",
          )
        ),
        
        const SizedBox(height: 12),
        _buildTextField("Ruolo / Posizione", _locationController, icon: Icons.work_outline),
        const SizedBox(height: 30),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Salva Modifiche", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _loadUserProfile, 
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Annulla", style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- HELPER AGGIORNATO CON SUFFIX WIDGET ---
  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false, Widget? suffixWidget}) {
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
            suffixIcon: suffixWidget, // Qui inseriamo il bottone se presente
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFF1F1F5), 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // --- ALTRE SEZIONI (INVARIATE) ---
  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Notifiche Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSwitchTile("Riassunti giornalieri", "Ricevi un riepilogo via email ogni sera", _dailySummary, (v) => setState(() => _dailySummary = v)),
        _buildSwitchTile("Nuove trascrizioni", "Notifica quando una registrazione è trascritta", _newTranscriptions, (v) => setState(() => _newTranscriptions = v)),
        const SizedBox(height: 20),
        const Text("Notifiche Push", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSwitchTile("Menzioni in chat", "Quando qualcuno ti menziona in un messaggio", _chatMentions, (v) => setState(() => _chatMentions = v)),
        _buildSwitchTile("Eventi imminenti", "Promemoria per meeting ed eventi", _upcomingEvents, (v) => setState(() => _upcomingEvents = v)),
        _buildSwitchTile("Suggerimenti AI", "Insights e suggerimenti dall'AI assistant", _aiSuggestions, (v) => setState(() => _aiSuggestions = v)),
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
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Conservazione", style: TextStyle(fontWeight: FontWeight.bold)), Text("Quanto tempo conservare le rec.", style: TextStyle(fontSize: 12, color: Colors.grey))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text("30 giorni", style: TextStyle(fontWeight: FontWeight.bold)))
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile("Trascrizioni Automatiche", "Attiva trascrizione automatica per tutte le rec.", _autoTranscription, (v) => setState(() => _autoTranscription = v)),  
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
          decoration: BoxDecoration(color: const Color(0xFFF1F1F5), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [_buildThemeOption("Chiaro", false), _buildThemeOption("Scuro", false), _buildThemeOption("Sistema", true)]),
        ),
         const SizedBox(height: 20),
        const Text("Lingua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.language, color: Colors.grey), SizedBox(width: 10), Text("Lingua dell'interfaccia")]), Text("Italiano", style: TextStyle(fontWeight: FontWeight.bold))]),
        ),
      ],
    );
  }

  Widget _buildThemeOption(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.deepPurple),
        ],
      ),
    );
  }
}