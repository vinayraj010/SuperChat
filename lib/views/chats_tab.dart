import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../views/chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);

    if (userVM.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Add friends to start chatting',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: userVM.friends.length,
      itemBuilder: (context, index) {
        final friend = userVM.friends[index];
        return ListTile(
          leading: CircleAvatar(child: Text(friend.name[0].toUpperCase())),
          title: Text(friend.name),
          subtitle: Text(friend.email),
          trailing: Icon(Icons.chat_bubble_outline),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(friendId: friend.uid, friendName: friend.name),
              ),
            );
          },
        );
      },
    );
  }
}
