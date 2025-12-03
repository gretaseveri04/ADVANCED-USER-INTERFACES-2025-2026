import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    // Richiede permesso microfono
    var statusMic = await Permission.microphone.request();
    // Su Android 13+ potrebbe servire anche gestire i permessi file, 
    // ma per ora concentriamoci sul mic.
    return statusMic.isGranted;
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;

    // Rimuovi la logica di Directory tempDir che usa dart:io
    // e chiama start senza parametri path, così salva in RAM/Blob
    const config = RecordConfig(encoder: AudioEncoder.aacLc); // o opus su web
    
    // Passa toStream: true su web o path null per il blob automatico
    await _audioRecorder.start(config, path: ''); 
  }

  Future<String?> stopRecording() async {
    // Ritorna il percorso del file salvato
    final path = await _audioRecorder.stop();
    return path;
  }
  
  Future<void> cancel() async {
    await _audioRecorder.cancel();
  }
}