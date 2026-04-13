import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/user_list_tile.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);

    if (userVM.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: userVM.allUsers.length,
      itemBuilder: (context, index) {
        final user = userVM.allUsers[index];
        return UserListTile(
          user: user,
          isFriend: userVM.isFriend(user.uid),
          isRequestSent: userVM.isRequestSent(user.uid),
          isRequestReceived: userVM.isRequestReceived(user.uid),
          onSendRequest: () => userVM.sendFriendRequest(user.uid),
          onAcceptRequest: () => userVM.acceptFriendRequest(user.uid),
          onRejectRequest: () => userVM.rejectFriendRequest(user.uid),
          onCancelRequest: () => userVM.cancelFriendRequest(user.uid),
          onBlock: () => userVM.blockUser(user.uid),
        );
      },
    );
  }
}
