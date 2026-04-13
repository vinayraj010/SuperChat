import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Check if already recording
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Check and request permission if needed
      if (!await requestPermission()) {
        return false;
      }

      // Get temp directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/audio_$timestamp.m4a';

      // Configure audio settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // Good quality, small size
        bitRate: 64000, // 64 kbps
        sampleRate: 44100, // CD quality
      );

      await _recorder.start(config, path: _recordingPath!);
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and return file
  Future<File?> stopRecording() async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        if (path != null && await File(path).exists()) {
          return File(path);
        }
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  // Check if currently recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  Future<Duration> getRecordingDuration(File audioFile) async {
    try {
      // Using audioplayers to get duration
      final player = AudioPlayer();

      // Set the source first
      await player.setSourceDeviceFile(audioFile.path);

      // Get the duration from the player
      final duration = await player.getDuration();

      // Dispose the player
      await player.dispose();

      return duration ?? Duration.zero;
    } catch (e) {
      print('Error getting duration: $e');
      return Duration.zero;
    }
  }

  // Cancel recording (delete file)
  Future<void> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _recordingPath = null;
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Check if recorder is initialized and ready
  Future<bool> hasPermission() async {
    return await Permission.microphone.isGranted;
  }

  // Dispose recorder
  Future<void> dispose() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      _recorder.dispose();
    } catch (e) {
      print('Error disposing recorder: $e');
    }
  }
}
