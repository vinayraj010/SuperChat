import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../services/firebase_service.dart';
import '../services/audio_recorder_service.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioRecorderService _audioRecorder = AudioRecorderService();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;

  void loadMessages(String chatId) {
    _isLoading = true;
    notifyListeners();

    _firebaseService.getMessages(chatId).listen((messages) {
      _messages = messages;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> sendTextMessage(
    String chatId,
    String senderId,
    String text,
  ) async {
    Message message = Message(
      id: '',
      chatId: chatId,
      senderId: senderId,
      type: 'text',
      text: text,
      timestamp: DateTime.now(),
    );

    await _firebaseService.sendMessage(message);
  }

  Future<void> startRecording() async {
    final hasPermission = await _audioRecorder.requestPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission required');
    }

    _isRecording = true;
    _recordingDuration = Duration.zero;
    notifyListeners();

    await _audioRecorder.startRecording();

    // Update duration
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      if (_isRecording) {
        _recordingDuration += Duration(milliseconds: 100);
        notifyListeners();
        return true;
      }
      return false;
    });
  }

  Future<void> stopRecordingAndSend(String chatId, String senderId) async {
    _isRecording = false;
    notifyListeners();

    final audioFile = await _audioRecorder.stopRecording();
    if (audioFile != null) {
      await _uploadAndSendAudio(chatId, senderId, audioFile);
    }
  }

  Future<void> cancelRecording() async {
    _isRecording = false;
    await _audioRecorder.cancelRecording();
    notifyListeners();
  }

  Future<void> _uploadAndSendAudio(
    String chatId,
    String senderId,
    File audioFile,
  ) async {
    try {
      // Upload to Firebase Storage
      String fileName = 'audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Get duration
      Duration duration = await _audioRecorder.getRecordingDuration(audioFile);

      // Send message
      Message message = Message(
        id: '',
        chatId: chatId,
        senderId: senderId,
        type: 'audio',
        audioUrl: downloadUrl,
        audioDuration: duration.inSeconds,
        timestamp: DateTime.now(),
      );

      await _firebaseService.sendMessage(message);
    } catch (e) {
      print('Error uploading audio: $e');
      rethrow;
    }
  }

  String getChatId(String uid1, String uid2) {
    return _firebaseService.getChatId(uid1, uid2);
  }
}
