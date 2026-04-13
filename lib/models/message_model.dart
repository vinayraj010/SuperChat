import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String type; // 'text' or 'audio'
  final String? text;
  final String? audioUrl;
  final int? audioDuration;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.text,
    this.audioUrl,
    this.audioDuration,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'type': type,
      'text': text,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      type: map['type'] ?? 'text',
      text: map['text'],
      audioUrl: map['audioUrl'],
      audioDuration: map['audioDuration'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
