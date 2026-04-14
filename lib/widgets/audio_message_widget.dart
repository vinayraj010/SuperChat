import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final String messageId;
  final bool isMe;
  final Duration duration;

  const AudioMessageWidget({
    Key? key,
    required this.audioUrl,
    required this.messageId,
    required this.isMe,
    required this.duration,
  }) : super(key: key);

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((position) {
      setState(() => _currentPosition = position);
    });
    _player.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  Future<void> _playAudio() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _currentPosition.inMilliseconds / widget.duration.inMilliseconds;
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.green[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: widget.isMe ? Colors.green[800] : Colors.grey[700],
              size: 32,
            ),
            SizedBox(width: 8),
            Container(
              width: 150,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress.isNaN ? 0 : progress,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isMe ? Colors.green : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_formatDuration(_currentPosition)} / ${_formatDuration(widget.duration)}',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
