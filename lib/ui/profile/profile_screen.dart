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

  bool _isLoading = false;
  bool _isUploadingImage = false; 

  String? _avatarUrl; 

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController(); 

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
      _supabase.from('profiles').select().eq('id', user.id).maybeSingle().then((data) {
        if (data != null && mounted) {
           setState(() {
            _nameController.text = data['first_name'] ?? '';
            _surnameController.text = data['last_name'] ?? '';
            _companyController.text = data['company'] ?? '';
            _locationController.text = data['role'] ?? ''; 
            _avatarUrl = data['avatar_url'];
          });
        }
      });
      
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

      final updates = UserAttributes(
        data: {
          ...user.userMetadata ?? {},
          'name': name,
          'surname': surname,
          'company': company,
        },
      );
      await _supabase.auth.updateUser(updates);

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'first_name': name,
        'last_name': surname,
        'company': company,
        'role': _locationController.text.trim(), 
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await ChatService().syncCompanyChat(company);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo salvato con successo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore logout: $e")));
    }
  }

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
              const Text("Select Company", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Text("Or type manually in the field", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        : "U";

    final String fullName = "${_nameController.text} ${_surnameController.text}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
            ),
          ],
        ),
        centerTitle: true,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildAvatarSection(initials, fullName),
            
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _buildTextField("Name", _nameController),
                  const SizedBox(height: 12),
                  _buildTextField("Surname", _surnameController),
                  const SizedBox(height: 12),
                  _buildTextField("Email", _emailController, icon: Icons.email_outlined, readOnly: true), 
                  const SizedBox(height: 12),
                  _buildTextField("Telephone", _phoneController, icon: Icons.phone_outlined),
                  const SizedBox(height: 12),
                  
                  _buildTextField(
                    "Company", 
                    _companyController, 
                    icon: Icons.business,
                    suffixWidget: IconButton(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.deepPurple),
                      onPressed: _showCompanyPicker,
                      tooltip: "Seleziona da lista",
                    )
                  ),
                  
                  const SizedBox(height: 12),
                  _buildTextField("Role / Position", _locationController, icon: Icons.work_outline),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, 
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                      label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarSection(String initials, String fullName) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
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
                      ? Center(child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)))
                      : null, 
            ),
            Positioned(
              right: 0, bottom: 0,
              child: GestureDetector(
                onTap: _uploadProfileImage, 
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(fullName.isNotEmpty ? fullName : "Utente", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(_emailController.text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false, Widget? suffixWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFF1F1F5), 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}