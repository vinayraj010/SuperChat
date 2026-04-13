import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';

class BlockedTab extends StatelessWidget {
  const BlockedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);

    if (userVM.blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No blocked users',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: userVM.blockedUsers.length,
      itemBuilder: (context, index) {
        final user = userVM.blockedUsers[index];
        return ListTile(
          leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: IconButton(
            icon: Icon(Icons.block, color: Colors.red),
            onPressed: () => userVM.unblockUser(user.uid),
          ),
        );
      },
    );
  }
}
