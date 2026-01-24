# Limitless App - Documentazione Tecnica Completa

## 📋 Indice
1. [Panoramica del Progetto](#panoramica-del-progetto)
2. [Tecnologie Utilizzate](#tecnologie-utilizzate)
3. [Architettura del Progetto](#architettura-del-progetto)
4. [Sistema di Autenticazione](#sistema-di-autenticazione)
5. [Funzionalità Principali](#funzionalità-principali)
6. [Servizi e API](#servizi-e-api)
7. [Database e Storage](#database-e-storage)
8. [Interfaccia Utente](#interfaccia-utente)
9. [Configurazione](#configurazione)
10. [Dipendenze](#dipendenze)

---

## 🎯 Panoramica del Progetto

**Limitless App** è un'applicazione mobile cross-platform sviluppata in Flutter che funge da assistente digitale intelligente per la gestione di meeting, registrazioni audio, trascrizioni, calendari e comunicazione di team. L'app integra tecnologie avanzate di Intelligenza Artificiale per automatizzare la trascrizione di audio, la generazione di riassunti, la sintesi vocale e l'assistenza conversazionale.

### Caratteristiche Principali
- **Registrazione Audio**: Cattura e trascrizione automatica di meeting e conversazioni
- **AI Assistant**: Assistente conversazionale con accesso alla memoria dei meeting
- **Calendario Integrato**: Sincronizzazione con Google Calendar e gestione eventi
- **Chat di Team**: Sistema di messaggistica con supporto per chat private e di gruppo
- **Digital Twin Avatar**: Avatar animato con Rive che legge i briefing vocali
- **Lifelog**: Archivio completo di tutte le registrazioni e trascrizioni

---

## 🛠 Tecnologie Utilizzate

### Framework e Linguaggi
- **Flutter SDK 3.9.2**: Framework cross-platform per iOS e Android
- **Dart**: Linguaggio di programmazione principale
- **Material Design**: Sistema di design UI

### Backend e Database
- **Supabase**: Backend-as-a-Service completo
  - **PostgreSQL**: Database relazionale per dati strutturati
  - **Supabase Auth**: Sistema di autenticazione basato su GoTrue
  - **Supabase Storage**: Storage S3-compatibile per file audio e immagini
  - **Row Level Security (RLS)**: Sicurezza a livello di riga per isolamento dati utente
  - **Real-time Subscriptions**: Aggiornamenti in tempo reale per chat e messaggi

### Servizi di Intelligenza Artificiale

#### Microsoft Azure OpenAI
- **Whisper Deployment**: Trascrizione audio speech-to-text
  - Endpoint: `https://limitless-openai-project.openai.azure.com`
  - Deployment: `my-whisper`
  - API Version: `2024-06-01`
  - Formato audio supportato: WebM, M4A
  - Lingua: Inglese (configurabile)

- **GPT-4o Deployment**: Elaborazione linguistica naturale
  - Deployment: `gpt-4o`
  - API Version: `2024-02-01`
  - Funzionalità:
    - Generazione briefing da trascrizioni
    - Estrazione dettagli eventi da testo
    - Assistente conversazionale con contesto
    - Analisi e riassunto meeting

#### ElevenLabs
- **Text-to-Speech API**: Sintesi vocale ad alta fedeltà
  - Voice ID: `iiidtqDt9FBdT1vfBluA`
  - Model: `eleven_multilingual_v2`
  - Formato output: MPEG audio
  - Utilizzato per: Briefing vocali dell'avatar digitale

### Google Cloud Services
- **Google Sign-In**: Autenticazione OAuth 2.0
  - Client ID iOS: `457158269786-1tlbj87qdjbp8qelhajciqv4uql4m36d.apps.googleusercontent.com`
  - Scopes: `https://www.googleapis.com/auth/calendar`
  
- **Google Calendar API**: Integrazione calendario
  - Sincronizzazione eventi bidirezionale
  - Creazione eventi da rilevamento automatico
  - Lettura eventi esistenti

### Animazione e UI
- **Rive**: Animazioni vettoriali interattive
  - File: `assets/rive/robot_agent.riv`
  - State Machine: Controllo animazioni basato su stati
  - Input dinamici: `HeadBobAmount`, `ArmFloatAmount`
  - Utilizzato per: Avatar digitale animato durante briefing

### Altre Tecnologie
- **Provider**: Gestione stato applicazione
- **Hive**: Database locale per cache
- **Google Fonts**: Tipografia personalizzata
- **Image Picker**: Selezione immagini da galleria
- **Permission Handler**: Gestione permessi (microfono, storage)
- **Record**: Registrazione audio nativa
- **Audio Players**: Riproduzione audio

---

## 🏗 Architettura del Progetto

### Struttura Directory

```
lib/
├── config/
│   └── keys.dart              # Configurazione API keys e endpoint
├── core/
│   └── services/              # Servizi business logic
│       ├── ai_service.dart
│       ├── audio_recording_service.dart
│       ├── auth_service.dart
│       ├── briefing_service.dart
│       ├── calendar_service.dart
│       ├── chat_service.dart
│       ├── meeting_repository.dart
│       └── openai_service.dart
├── models/                     # Modelli dati
│   ├── calendar_event_model.dart
│   ├── chat_models.dart
│   ├── conversation_model.dart
│   ├── lifelog_model.dart
│   └── meeting_model.dart
├── ui/                         # Interfaccia utente
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── calendar/
│   │   └── calendar_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── messages/
│   │   ├── conversation_screen.dart
│   │   ├── messages_list_screen.dart
│   │   └── new_chat_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── transcript/
│   │   ├── lifelog_screen.dart
│   │   ├── transcript_detail_screen.dart
│   │   └── transcripts_screen.dart
│   └── main_layout.dart
├── widgets/                    # Widget riutilizzabili
│   ├── briefing_avatar.dart
│   └── custom_buttom_nav.dart
└── main.dart                   # Entry point applicazione
```

### Pattern Architetturali

1. **Service Layer Pattern**: Logica business separata in servizi dedicati
2. **Repository Pattern**: Astrazione accesso dati (MeetingRepository)
3. **Model-View Pattern**: Separazione dati e presentazione
4. **Stream-based State Management**: Aggiornamenti real-time con Supabase Streams

---

## 🔐 Sistema di Autenticazione

### Metodi di Autenticazione Supportati

#### 1. Email e Password (Supabase Auth)
- **Registrazione**: 
  - Campi richiesti: email, password, nome, cognome, data di nascita, azienda, ruolo
  - Metadata salvati in `user_metadata`
  - Verifica email opzionale (configurabile in Supabase)
  
- **Login**:
  - Endpoint: `supabase.auth.signInWithPassword()`
  - Gestione sessioni automatica
  - Refresh token automatico

#### 2. Google OAuth 2.0
- **Flusso di Autenticazione**:
  1. Utente seleziona "Sign in with Google"
  2. App avvia `GoogleSignIn` con scope calendar
  3. Google restituisce `accessToken` e `idToken`
  4. Token inviati a Supabase: `signInWithIdToken(provider: OAuthProvider.google)`
  5. Supabase crea/aggiorna utente e restituisce sessione

- **Configurazione**:
  - Client ID iOS specifico per app iOS
  - Client ID Android gestito automaticamente da Google Sign-In
  - Scopes: Accesso a Google Calendar per sincronizzazione eventi

### Gestione Sessioni
- **Persistenza**: Sessioni salvate automaticamente da Supabase
- **Auto-refresh**: Token rinnovati automaticamente
- **Logout**: 
  - Logout da Supabase: `supabase.auth.signOut()`
  - Logout da Google: `GoogleSignIn().signOut()`
  - Redirect a schermata login

### Profili Utente
- **Tabella `profiles`** in Supabase:
  - `id` (UUID, FK a auth.users)
  - `first_name`, `last_name`
  - `company`, `role`
  - `avatar_url` (URL Supabase Storage)
  - `email`
  - `created_at`, `updated_at`

---

## ⚙️ Funzionalità Principali

### 1. Home Screen (Dashboard)
**File**: `lib/ui/home/home_screen.dart`

**Funzionalità**:
- Visualizzazione eventi calendar del giorno corrente
- Registrazione audio con pulsante dedicato
- Informazioni utente (nome, avatar, data corrente)
- Navigazione rapida al calendario

**Workflow Registrazione**:
1. Utente preme "Record Audio"
2. App richiede permesso microfono
3. Registrazione inizia (formato M4A, 44.1kHz, 128kbps)
4. Durante registrazione: indicatore visivo rosso
5. Stop registrazione: dialog per titolo meeting
6. Elaborazione automatica:
   - Upload audio a Supabase Storage
   - Trascrizione con Azure Whisper
   - Analisi testo per estrazione eventi
   - Generazione briefing con GPT-4o
   - Salvataggio meeting in database

### 2. Calendario
**File**: `lib/ui/calendar/calendar_screen.dart`

**Funzionalità**:
- Vista mensile interattiva
- Visualizzazione eventi per giorno
- Creazione eventi manuale
- Registrazione audio per eventi futuri
- Accesso a trascrizioni per eventi passati
- Sincronizzazione con Google Calendar

**Integrazione Google Calendar**:
- Eventi creati in app → sincronizzati su Google Calendar
- `google_event_id` salvato per riferimento bidirezionale
- Eventi Google esistenti → visualizzati in app

**Rilevamento Automatico Eventi**:
- Analisi trascrizioni per riferimenti a meeting futuri
- Pattern matching: "meeting on Monday", "next Friday"
- Creazione automatica eventi calendar

### 3. AI Assistant (Chat Screen)
**File**: `lib/ui/chat/chat_screen.dart`

**Funzionalità**:
- Chat conversazionale con GPT-4o
- Accesso contestuale a tutti i meeting dell'utente
- Suggerimenti rapidi (summarize, email, tasks, brainstorm)
- Risposte basate su memoria meeting

**Sistema di Memoria**:
- Caricamento automatico tutti i meeting al primo accesso
- Formato contesto: `--- MEETING: [title] ([date]) ---\n[transcription]`
- Contesto inviato a GPT-4o come system message
- AI può rispondere a domande su meeting passati

**Suggerimenti Predefiniti**:
- "Summarize meetings": Riassunto meeting recenti
- "Write email": Draft email basato su ultimo meeting
- "Create task list": Estrazione action items
- "Brainstorm": Idee basate su progetti discussi

### 4. Messaggi (Team Chat)
**File**: `lib/ui/messages/`

**Funzionalità**:
- Chat private tra colleghi
- Chat di gruppo per azienda
- Messaggi in tempo reale (Supabase Realtime)
- Supporto AI in chat (trigger: `@ai` nel messaggio)
- Lista colleghi filtrata per azienda

**Sistema Chat**:
- **Tabella `chats`**: Room chat (private/group)
- **Tabella `chat_participants`**: Membri per chat
- **Tabella `messages`**: Messaggi con flag `is_ai`
- **RPC Functions**:
  - `create_chat_room`: Crea chat di gruppo
  - `get_or_create_private_chat`: Chat 1-to-1
  - `get_or_create_company_chat`: Chat aziendale automatica

**AI in Chat**:
- Messaggi contenenti `@ai` → trigger risposta AI
- AI risponde con contesto meeting dell'utente
- Risposta salvata come messaggio con `is_ai: true`

### 5. Lifelog (Recordings)
**File**: `lib/ui/transcript/lifelog_screen.dart`

**Funzionalità**:
- Lista completa registrazioni
- Ordinamento per data (più recenti prima)
- Accesso rapido a dettagli trascrizione
- Refresh pull-to-refresh

**Dettaglio Meeting**:
- Visualizzazione trascrizione completa
- Briefing vocale con avatar animato
- Data e ora registrazione
- Link audio originale

### 6. Profile
**File**: `lib/ui/profile/profile_screen.dart`

**Funzionalità**:
- Modifica informazioni personali
- Upload avatar (Supabase Storage)
- Selezione azienda da lista predefinita
- Logout

**Aziende Supportate**:
- Politecnico di Milano
- Politecnico di Torino
- Google
- Amazon
- Apple
- Samsung

**Sincronizzazione Chat Aziendale**:
- Aggiornamento azienda → auto-sync chat aziendale
- Aggiunta automatica a chat gruppo azienda
- Rimozione da chat azienda precedente

---

## 🔌 Servizi e API

### AuthService
**File**: `lib/core/services/auth_service.dart`

**Metodi**:
- `login(email, password)`: Login email/password
- `signup(...)`: Registrazione nuovo utente
- `logout()`: Logout completo (Supabase + Google)
- `signInWithGoogle()`: OAuth Google flow

**Dettagli Implementazione**:
- Gestione errori con try-catch
- Validazione token Google
- Scopes calendar per integrazione Google

### AudioRecordingService
**File**: `lib/core/services/audio_recording_service.dart`

**Metodi**:
- `hasPermission()`: Verifica permesso microfono
- `startRecording()`: Avvia registrazione
- `stopRecording()`: Ferma e restituisce path file
- `cancel()`: Annulla registrazione

**Configurazione Audio**:
- Encoder: AAC LC
- Sample Rate: 44.1 kHz
- Bitrate: 128 kbps
- Formato: M4A
- Path: Temporary directory del dispositivo

### OpenAIService
**File**: `lib/core/services/openai_service.dart`

**Metodi**:
- `transcribeAudioBytes(bytes, filename)`: Trascrizione audio
- `getChatResponse(message, contextData)`: Chat con contesto
- `extractEventDetails(text)`: Estrazione eventi da testo

**Trascrizione Audio**:
- Endpoint: Azure Whisper API
- Formato richiesta: Multipart form-data
- Content-Type: `audio/webm`
- Lingua: Inglese (hardcoded)
- Risposta: JSON con campo `text`

**Chat Response**:
- System message personalizzabile
- Contesto meeting opzionale
- Max tokens: 500
- Temperature: 0.7

**Estrazione Eventi**:
- Prompt system dettagliato per parsing date/ora
- Formato output: JSON strutturato
- Conversione automatica a ISO 8601
- Gestione riferimenti temporali ("tomorrow", "next Monday")

### AIService
**File**: `lib/core/services/ai_service.dart`

**Metodi**:
- `sendMessage(userMessage)`: Messaggio generico
- `generateBriefing(transcript)`: Generazione briefing

**Generazione Briefing**:
- Prompt specializzato per stile "announcer"
- Regole: no bullet points, conversazionale, 50-60 parole
- Tone: Professionale (stile Bill Oxley)
- Output: Testo fluido per TTS

### BriefingService
**File**: `lib/core/services/briefing_service.dart`

**Metodi**:
- `getBriefingAudio(text)`: Conversione testo → audio MP3

**Implementazione**:
- API: ElevenLabs Text-to-Speech
- Voice ID: `iiidtqDt9FBdT1vfBluA`
- Model: `eleven_multilingual_v2`
- Formato output: MPEG audio
- Salvataggio: Temporary directory locale
- Utilizzo: Riproduzione con AudioPlayer

### CalendarService
**File**: `lib/core/services/calendar_service.dart`

**Metodi**:
- `addEvent(event)`: Crea evento (app + Google Calendar)
- `getMyEvents()`: Lista eventi utente
- `getEventsForDay(day)`: Eventi per giorno specifico
- `deleteEvent(eventId)`: Elimina evento

**Integrazione Google Calendar**:
- Autenticazione: Google Sign-In con scope calendar
- Creazione evento: `CalendarApi.events.insert()`
- Sincronizzazione: `google_event_id` salvato in Supabase
- Timezone: UTC per consistenza

### ChatService
**File**: `lib/core/services/chat_service.dart`

**Metodi**:
- `createGroupChat(name, userIds)`: Crea chat gruppo
- `getMyChats()`: Lista chat utente
- `getColleagues()`: Colleghi stessa azienda
- `startPrivateChat(colleagueId)`: Avvia chat privata
- `syncCompanyChat(companyName)`: Sync chat aziendale
- `getMessagesStream(chatId)`: Stream messaggi real-time
- `sendMessage(chatId, content)`: Invia messaggio

**Real-time Messaging**:
- Supabase Realtime subscriptions
- Stream automatico nuovi messaggi
- Ordinamento: più recenti prima
- Aggiornamento UI automatico

### MeetingRepository
**File**: `lib/core/services/meeting_repository.dart`

**Metodi**:
- `uploadAudioBytes(bytes)`: Upload audio a Supabase Storage
- `saveMeeting(...)`: Salva meeting in database
- `fetchMeetings()`: Recupera tutti i meeting utente

**Storage Audio**:
- Bucket: `meeting_recordings`
- Path: `{user_id}/{timestamp}.webm`
- FileOptions: Cache control 3600s, no upsert
- Public URL generata post-upload

**Schema Meeting**:
- `user_id`: FK a auth.users
- `title`: Titolo meeting
- `transcription_text`: Trascrizione completa
- `summary`: Briefing generato
- `audio_url`: URL Supabase Storage
- `category`: Categoria (default: 'WORK')
- `created_at`: Timestamp creazione

---

## 💾 Database e Storage

### Schema Database Supabase

#### Tabella `profiles`
```sql
- id (UUID, PK, FK auth.users)
- first_name (TEXT)
- last_name (TEXT)
- company (TEXT)
- role (TEXT)
- email (TEXT)
- avatar_url (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### Tabella `meetings`
```sql
- id (UUID, PK)
- user_id (UUID, FK auth.users)
- title (TEXT)
- transcription_text (TEXT)
- summary (TEXT)
- audio_url (TEXT)
- category (TEXT)
- created_at (TIMESTAMP)
```

#### Tabella `calendar_events`
```sql
- id (UUID, PK)
- user_id (UUID, FK auth.users)
- title (TEXT)
- description (TEXT)
- start_time (TIMESTAMP)
- end_time (TIMESTAMP)
- is_all_day (BOOLEAN)
- google_event_id (TEXT, nullable)
- created_at (TIMESTAMP)
```

#### Tabella `chats`
```sql
- id (UUID, PK)
- name (TEXT, nullable)
- is_group (BOOLEAN)
- created_at (TIMESTAMP)
```

#### Tabella `chat_participants`
```sql
- chat_id (UUID, FK chats)
- user_id (UUID, FK auth.users)
- PRIMARY KEY (chat_id, user_id)
```

#### Tabella `messages`
```sql
- id (UUID, PK)
- chat_id (UUID, FK chats)
- sender_id (UUID, FK auth.users)
- content (TEXT)
- is_ai (BOOLEAN, default false)
- created_at (TIMESTAMP)
```

### Supabase Storage Buckets

#### `meeting_recordings`
- **Scopo**: File audio registrazioni
- **Path Pattern**: `{user_id}/{timestamp}.webm`
- **Permissions**: RLS abilitato, accesso solo owner
- **Public URLs**: Generati automaticamente

#### `avatars`
- **Scopo**: Immagini profilo utente
- **Path Pattern**: `{user_id}_{timestamp}.{ext}`
- **Permissions**: RLS abilitato
- **Public URLs**: Per visualizzazione avatar

### Row Level Security (RLS)

**Politiche Implementate**:
- `meetings`: `(auth.uid() = user_id)`
- `calendar_events`: `(auth.uid() = user_id)`
- `profiles`: Lettura pubblica, scrittura solo owner
- `chats`: Accesso solo per partecipanti
- `messages`: Accesso solo per partecipanti chat

---

## 🎨 Interfaccia Utente

### Design System

**Colori Principali**:
- Primary Gradient: `#3366FF` → `#8844FF` → `#FFAA00`
- Purple Gradient: `#B476FF` → `#7F7CFF`
- Background: `#F8F8FF`
- Cards: `#FFFFFF`
- Text Primary: `#000000`
- Text Secondary: `#808080`

**Tipografia**:
- Font Family: "SF" (San Francisco, iOS default)
- Headings: Bold, 18-28px
- Body: Regular, 14-16px
- Labels: Medium, 12-13px

**Componenti UI**:
- Cards: Border radius 20px, shadow leggera
- Buttons: Border radius 12-40px, gradient backgrounds
- Input Fields: Border radius 12px, background `#F1F1F5`
- AppBar: Gradient trasparente, logo + titolo

### Navigation

**Bottom Navigation Bar**:
- Home (icona home)
- Record (icona mic)
- AI Assistant (logo app)
- Messages (icona chat)
- Profile (icona person)

**Routing**:
- `/login`: Login screen
- `/home`: Main layout (default se autenticato)
- `/lifelog`: Screen registrazioni
- `/chat`: AI Assistant
- `/calendar`: Calendario
- `/transcription`: Dettaglio lifelog
- `/transcriptDetail`: Dettaglio meeting

### Widget Personalizzati

#### BriefingAvatar
**File**: `lib/widgets/briefing_avatar.dart`

**Funzionalità**:
- Animazione Rive interattiva
- Controllo stato basato su `isTalking`
- Input dinamici: `HeadBobAmount`, `ArmFloatAmount`
- Animazioni: Head bob, arm float durante speech

#### CustomBottomNav
**File**: `lib/widgets/custom_buttom_nav.dart`

**Funzionalità**:
- 5 tab navigation
- Indicatore attivo con gradient
- Icone custom (logo app per AI tab)
- Animazioni smooth

---

## ⚙️ Configurazione

### File di Configurazione

#### `lib/config/keys.dart`

**SupabaseConfig**:
```dart
supabaseUrl: 'https://pppybkjdcvxqhbfyqsuz.supabase.co'
supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**AzureConfig**:
```dart
apiKey: 'EuHU0Q57ppItyHjGPJAKQTahO1Ze3bANdmW6ietwb0vwYztiGNoJJQQJ99BKACfhMk5XJ3w3AAAAACOGfZEA'
endpoint: 'https://limitless-openai-project.openai.azure.com'
whisperDeploymentName: 'my-whisper'
gptDeploymentName: 'gpt-4o'
```

**BriefingService** (hardcoded):
```dart
apiKey: 'sk_a1c6644b6df032ce6384a8ae2335a719cc92902209aa29b7'
voiceId: 'iiidtqDt9FBdT1vfBluA'
```

### Inizializzazione App

**File**: `lib/main.dart`

**Setup**:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Supabase.initialize()` con URL e anon key
3. Routing condizionale: `/login` se non autenticato, `/home` se autenticato
4. MaterialApp con theme personalizzato

### Permessi Richiesti

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `INTERNET`
- `RECORD_AUDIO`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`

**iOS** (`ios/Runner/Info.plist`):
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSCameraUsageDescription`

---

## 📦 Dipendenze

### Dependencies Principali

```yaml
# Backend
supabase_flutter: ^2.3.1          # Supabase SDK completo
provider: ^6.0.0                   # State management

# Autenticazione
extension_google_sign_in_as_googleapis_auth: ^2.0.7
google_sign_in: (implicito)        # Google OAuth
googleapis: ^11.0.0                # Google APIs
googleapis_auth: ^1.4.0            # Google Auth

# Database Locale
hive: ^2.2.3                       # Local database
hive_flutter: ^1.1.0               # Hive Flutter integration

# UI
google_fonts: ^6.1.0               # Custom fonts
cupertino_icons: ^1.0.8            # iOS icons
graphview: ^1.1.3                   # Graph visualization
intl: ^0.20.2                       # Internationalization

# Media
image_picker: ^1.0.4               # Image selection
record: ^6.1.2                     # Audio recording
audioplayers: ^5.2.1               # Audio playback
mime: ^2.0.0                        # MIME types

# Animazioni
rive: ^0.13.0                       # Rive animations

# Utilities
http: ^1.2.0                        # HTTP requests
path_provider: ^2.1.2              # File system paths
permission_handler: ^12.0.1         # Permissions
```

### Dev Dependencies

```yaml
flutter_test:
  sdk: flutter
flutter_lints: ^6.0.0
flutter_launcher_icons: ^0.13.1    # App icon generation
```

---

## 🔄 Workflow Completo: Registrazione → Briefing

### Step 1: Registrazione Audio
1. Utente preme "Record Audio" in Home Screen
2. `AudioRecordingService.startRecording()` avvia registrazione
3. File salvato in temporary directory: `temp_recording.m4a`
4. Durante registrazione: UI mostra indicatore rosso

### Step 2: Stop e Titolo
1. Utente ferma registrazione
2. Dialog per inserire titolo meeting (opzionale)
3. File audio letto come `Uint8List`

### Step 3: Upload e Trascrizione
1. Upload audio a Supabase Storage: `meeting_recordings/{user_id}/{timestamp}.webm`
2. Chiamata Azure Whisper API:
   - Endpoint: `/openai/deployments/my-whisper/audio/transcriptions`
   - Multipart form-data con file audio
   - Risposta: JSON con campo `text` (trascrizione)

### Step 4: Analisi e Estrazione Eventi
1. Analisi trascrizione per riferimenti a meeting futuri
2. Pattern matching: giorni settimana, date, orari
3. Se rilevato: creazione automatica evento calendar
4. Sincronizzazione con Google Calendar (se autenticato)

### Step 5: Generazione Briefing
1. Trascrizione inviata a `AIService.generateBriefing()`
2. Prompt specializzato per stile "announcer"
3. GPT-4o genera briefing conversazionale (50-60 parole)
4. Briefing salvato in campo `summary` del meeting

### Step 6: Salvataggio Meeting
1. `MeetingRepository.saveMeeting()` salva:
   - Titolo (utente o auto-generato)
   - Trascrizione completa
   - Briefing generato
   - URL audio Supabase Storage
   - Timestamp creazione

### Step 7: Visualizzazione Briefing
1. Utente apre dettaglio meeting
2. `BriefingService.getBriefingAudio()` chiama ElevenLabs TTS
3. Testo briefing → audio MP3
4. Audio salvato localmente: `temp/briefing.mp3`
5. `AudioPlayer` riproduce audio
6. `BriefingAvatar` anima durante riproduzione
7. Animazioni controllate da `isTalking` state

---

## 🚀 Setup e Installazione

### Prerequisiti
- Flutter SDK 3.9.2 o superiore
- Dart SDK compatibile
- Account Supabase
- Account Azure OpenAI
- Account ElevenLabs
- Google Cloud Console project (per Calendar API)

### Configurazione Supabase
1. Crea nuovo progetto Supabase
2. Crea tabelle: `profiles`, `meetings`, `calendar_events`, `chats`, `chat_participants`, `messages`
3. Configura RLS policies
4. Crea storage buckets: `meeting_recordings`, `avatars`
5. Configura Google OAuth provider in Supabase Auth
6. Copia URL e anon key in `lib/config/keys.dart`

### Configurazione Azure OpenAI
1. Crea Azure OpenAI resource
2. Deploy modelli: Whisper e GPT-4o
3. Copia endpoint e API key in `lib/config/keys.dart`

### Configurazione ElevenLabs
1. Crea account ElevenLabs
2. Seleziona/clona voice
3. Copia API key e voice ID in `BriefingService`

### Configurazione Google Cloud
1. Crea progetto Google Cloud
2. Abilita Calendar API
3. Crea OAuth 2.0 credentials (iOS e Android)
4. Configura redirect URIs
5. Copia Client ID iOS in `AuthService` e `CalendarService`

### Build e Run
```bash
flutter pub get
flutter run
```

---

## 📝 Note Tecniche

### Gestione Errori
- Try-catch blocks in tutti i servizi
- SnackBar per notifiche errori utente
- Logging errori in console

### Performance
- Lazy loading per liste meeting
- Caching immagini avatar
- Stream subscriptions efficienti
- Audio compression per upload

### Sicurezza
- API keys non committate (da spostare in env)
- RLS policies per isolamento dati
- Token OAuth gestiti da SDK
- Validazione input lato client e server

### Limitazioni Attuali
- Trascrizione solo in inglese
- Voice ElevenLabs hardcoded
- Google Calendar sync unidirezionale (app → Google)
- Chat aziendale creata automaticamente ma non eliminabile

---

## 🔮 Possibili Miglioramenti Futuri

1. **Multi-lingua**: Supporto trascrizione in più lingue
2. **Voice Selection**: Scelta voice ElevenLabs dall'UI
3. **Offline Mode**: Cache locale per funzionalità offline
4. **Export**: Esportazione meeting in PDF/Word
5. **Analytics**: Dashboard analytics meeting
6. **Notifications**: Notifiche push per eventi calendar
7. **Search**: Ricerca full-text in trascrizioni
8. **Tags**: Sistema tag per categorizzazione meeting
9. **Sharing**: Condivisione meeting con colleghi
10. **Integration**: Integrazione con Slack, Teams, etc.

---

## 📄 Licenza

Questo progetto è parte del corso Advanced User Interfaces 2025-2026.

---

## 👥 Autori

Sviluppato per il corso di Advanced User Interfaces presso il Politecnico di Milano/Torino.

---

**Ultimo aggiornamento**: Gennaio 2025
