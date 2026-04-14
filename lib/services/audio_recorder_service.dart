import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      if (!await requestPermission()) {
        return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/audio_$timestamp.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: _recordingPath!);
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

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

  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  Future<Duration> getRecordingDuration(File audioFile) async {
    try {
      final player = AudioPlayer();
      await player.setSourceDeviceFile(audioFile.path);
      final duration = await player.getDuration();
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (e) {
      print('Error getting duration: $e');
      return Duration.zero;
    }
  }

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
