import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/audio_message_widget.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String _chatId;

  @override
  void initState() {
    super.initState();
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final chatVM = Provider.of<ChatViewModel>(context, listen: false);
    _chatId = chatVM.getChatId(authVM.currentUser!.uid, widget.friendId);
    chatVM.loadMessages(_chatId);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final chatVM = Provider.of<ChatViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: chatVM.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: chatVM.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatVM.messages[index];
                      final isMe = message.senderId == authVM.currentUser!.uid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: message.type == 'audio'
                              ? AudioMessageWidget(
                                  audioUrl: message.audioUrl!,
                                  messageId: message.id,
                                  isMe: isMe,
                                  duration: Duration(
                                    seconds: message.audioDuration!,
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.green[100]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(message.text!),
                                ),
                        ),
                      );
                    },
                  ),
          ),

          if (chatVM.isRecording)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.red[100],
              child: Row(
                children: [
                  Icon(Icons.mic, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Recording... ${_formatDuration(chatVM.recordingDuration)}',
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: chatVM.cancelRecording,
                  ),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    chatVM.isRecording ? Icons.stop : Icons.mic,
                    color: chatVM.isRecording ? Colors.red : Colors.grey,
                  ),
                  onPressed: chatVM.isRecording
                      ? () => chatVM.stopRecordingAndSend(
                          _chatId,
                          authVM.currentUser!.uid,
                        )
                      : () async {
                          try {
                            await chatVM.startRecording();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      chatVM.sendTextMessage(
                        _chatId,
                        authVM.currentUser!.uid,
                        _messageController.text.trim(),
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
