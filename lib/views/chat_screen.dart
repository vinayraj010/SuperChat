import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/audio_message_widget.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    required this.chatId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('ChatScreen initialized with chatId: ${widget.chatId}');
    print('Friend: ${widget.friendName} (${widget.friendId})');

    final chatVM = Provider.of<ChatViewModel>(context, listen: false);
    chatVM.loadMessages(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final chatVM = Provider.of<ChatViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatVM.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with ${widget.friendName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatVM.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatVM.messages[index];
                      final isMe = message.senderId == authVM.currentUser!.uid;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),

          // Recording indicator
          if (chatVM.isRecording)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Recording... ${_formatDuration(chatVM.recordingDuration)}',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: chatVM.cancelRecording,
                  ),
                ],
              ),
            ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                // Audio record button
                IconButton(
                  icon: Icon(
                    chatVM.isRecording ? Icons.stop : Icons.mic,
                    color: chatVM.isRecording ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                  onPressed: chatVM.isRecording
                      ? () async {
                          await chatVM.stopRecordingAndSend(
                            widget.chatId,
                            authVM.currentUser!.uid,
                          );
                          _scrollToBottom();
                        }
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

                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _sendMessage(chatVM, authVM);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      _sendMessage(chatVM, authVM);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatViewModel chatVM, AuthViewModel authVM) {
    if (_messageController.text.trim().isNotEmpty) {
      chatVM.sendTextMessage(
        widget.chatId,
        authVM.currentUser!.uid,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(dynamic message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.type == 'audio'
                  ? AudioMessageWidget(
                      audioUrl: message.audioUrl!,
                      messageId: message.id,
                      isMe: isMe,
                      duration: Duration(seconds: message.audioDuration!),
                    )
                  : Text(message.text!, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimeShort(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTimeShort(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}
