import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;

    // --- LOGICA MOBILE ---
    // Troviamo una cartella temporanea sicura sull'iPhone
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/temp_recording.m4a';

    // Configuriamo per alta qualità vocale
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc, // Ottimo per iOS
      sampleRate: 44100,
      bitRate: 128000,
    );

    // Se stiamo già registrando, fermiamo prima
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    // Avvia salvando nel file
    await _audioRecorder.start(config, path: filePath);
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
  
  Future<void> cancel() async {
    await _audioRecorder.cancel();
  }
}