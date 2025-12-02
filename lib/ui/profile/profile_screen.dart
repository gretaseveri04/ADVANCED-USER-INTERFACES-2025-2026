import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Indice del tab selezionato: 0=Account, 1=Notifiche, 2=Privacy, 3=Preferenze
  int _selectedTabIndex = 0;

  // Controller per i campi di testo (Account)
  final _nameController = TextEditingController(text: "Mario");
  final _surnameController = TextEditingController(text: "Rossi");
  final _emailController = TextEditingController(text: "mario.rossi@example.com");
  final _phoneController = TextEditingController(text: "+39 333 1234567");
  final _companyController = TextEditingController(text: "Tech Solutions SRL");
  final _locationController = TextEditingController(text: "Milano, Italia");

  // Stato per gli switch (Notifiche/Privacy)
  bool _dailySummary = true;
  bool _newTranscriptions = true;
  bool _chatMentions = true;
  bool _upcomingEvents = false;
  bool _aiSuggestions = false;
  bool _autoTranscription = true;

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante il logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Sfondo grigio chiaro come nel video
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

              // CARD PRINCIPALE
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
                    // AVATAR E INFO BASE
                    _buildHeaderInfo(),
                    const SizedBox(height: 20),
                    
                    // TAB BAR INTERNA
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
                    
                    // CONTENUTO DINAMICO
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30), // Spazio extra in fondo
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFB476FF), Color(0xFFFFB4E1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "MR",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Mario Rossi",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "mario.rossi@example.com",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {},
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

  // --- SEZIONE 1: ACCOUNT ---
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
        _buildTextField("Email", _emailController, icon: Icons.email_outlined),
        const SizedBox(height: 12),
        _buildTextField("Telefono", _phoneController, icon: Icons.phone_outlined),
        const SizedBox(height: 12),
        _buildTextField("Azienda", _companyController, icon: Icons.business),
        const SizedBox(height: 12),
        _buildTextField("Posizione", _locationController, icon: Icons.location_on_outlined),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Salva Modifiche", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
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

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
            filled: true,
            fillColor: const Color(0xFFF1F1F5),
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

  // --- SEZIONE 2: NOTIFICHE ---
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

  // --- SEZIONE 3: PRIVACY ---
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
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Crittografia", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Tutti i dati sono crittografati", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Text("Attivo", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text("Gestione Dati", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text("Scarica tutti i tuoi dati"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text("Elimina tutti i dati"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- SEZIONE 4: PREFERENZE ---
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