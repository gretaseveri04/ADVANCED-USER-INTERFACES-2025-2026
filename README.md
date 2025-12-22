# Limitless: Digital Twin Briefing System - Technical Documentation

## 1. Project Overview
Limitless is a multimodal application designed to transform meeting recordings into an interactive briefing experience. The system integrates advanced Speech-to-Text (STT), Large Language Models (LLM) for summarization, high-fidelity Text-to-Speech (TTS), and real-time vector animations. The architecture is built on a cross-platform Flutter frontend supported by a multi-cloud backend (Supabase, Azure, and Google Cloud).

---

## 2. Technical Stack
### 2.1 Core Framework
* **Flutter (Dart):** Mobile infrastructure using a layered architecture (UI, Domain, Data).

### 2.2 Backend and Persistence
* **Supabase:**
    * **PostgreSQL:** Relational database for meeting metadata.
    * **Supabase Storage:** S3-compatible storage for .webm (raw) and .mp3 (processed) audio files.
    * **Auth:** GoTrue-based authentication for user-specific data isolation via RLS (Row Level Security).

### 2.3 Artificial Intelligence Services
* **Microsoft Azure AI Services:**
    * **Speech-to-Text (STT):** Used for high-precision transcription with Diarization (speaker identification).
    * **Azure OpenAI (GPT-4):** Orchestration of meeting summaries and "News-style" script rewriting.
* **ElevenLabs API:**
    * **Model:** Multilingual v2.
    * **Feature:** High-fidelity voice synthesis for the Digital Twin avatar.

### 2.4 Animation and UI
* **Rive:** State Machine-based vector animations for the interactive avatar.
* **Google Cloud Console:**
    * **Google Calendar API:** Synchronization of meeting events and metadata.
    * **OAuth 2.0:** Secure authorization flow for Google Workspace integration.

---

## 3. Implementation Details

### 3.1 Data Layer: MeetingRepository
The `MeetingRepository` class handles all interactions with the Supabase client.

* **Schema Definition:**
    * `meetings` table: `id` (UUID), `user_id` (UUID), `title` (Text), `transcription_text` (Text), `summary` (Text), `audio_url` (Text), `category` (Text), `created_at` (Timestamp).
* **Storage Logic:**
    Raw audio is uploaded as `Uint8List` using the `uploadBinary` method. Public URLs are generated post-upload to be stored in the database record.

### 3.2 AI Service Orchestration: BriefingService
The conversion of text to an animated briefing involves a multi-step pipeline:

1.  **Script Transformation:** The raw summary is processed via LLM to adopt a conversational "news briefing" tone, eliminating bullet points in favor of fluid prose.
2.  **TTS Generation:** The transformed text is sent to ElevenLabs via POST request to the `/v1/text-to-speech/{voiceId}` endpoint.
3.  **Local Buffering:** The resulting MPEG stream is saved to the device's temporary directory using `path_provider` to ensure gapless playback.

### 3.3 Google Calendar Integration
Managed through the Google Cloud Console:
* **Scopes:** `https://www.googleapis.com/auth/calendar.events` (read/write).
* **Workflow:** The app authenticates the user via `google_sign_in`, retrieves the `accessToken`, and initializes the `CalendarApi` from the `googleapis` package. This allows the system to link meeting recordings directly to specific calendar event IDs.

### 3.4 Rive State Machine Logic
The Digital Twin's behavior is controlled by a Rive State Machine with specific inputs:
* **Input 'isTalking' (Boolean):** Triggered when the `AudioPlayer` state changes to `PlayerState.playing`.
* **Input 'isThinking' (Boolean):** Triggered during the API call latency period (STT/TTS processing).
* **Idle State:** Default state with breathing and blinking animations.

---

## 4. Technical Workflow (Step-by-Step)

1.  **Ingestion:** The app captures audio and uploads the .webm file to Supabase Storage.
2.  **Transcription (Azure):** Azure AI Speech processes the audio, returning a JSON with timestamps and speaker IDs.
3.  **Summarization (Azure OpenAI):** The transcript is summarized into key points and then rewritten into a 30-45 second script.
4.  **Voice Synthesis (ElevenLabs):** The script is converted to a high-quality .mp3 file.
5.  **Metadata Storage:** All texts (transcript, summary, script) and the audio URL are saved in the Supabase PostgreSQL table.
6.  **Interactive Playback:** * The app fetches the summary and the synthesized audio.
    * The Rive controller listens to the audio stream.
    * The UI displays an animated overlay with dynamic "chips" representing meeting keywords extracted via NLP.

---

## 5. Security and Infrastructure
* **RLS Policies:** Each row in the `meetings` table is protected by a policy: `(uid() = user_id)`.
* **API Key Management:** Keys for ElevenLabs and Azure are managed via environment variables and are never hardcoded.
* **Concurrency:** The implementation uses Dart `Futures` and `Streams` to handle simultaneous audio playback and UI animation updates without blocking the main thread.

---

## 6. Dependencies
* `supabase_flutter`: Backend integration.
* `googleapis` & `google_sign_in`: Google Cloud ecosystem.
* `rive`: Vector animation runtime.
* `audioplayers`: Audio playback management.
* `http`: REST API communication for ElevenLabs and Azure.
* `path_provider`: Local file system access.