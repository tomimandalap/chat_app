import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chat_app/widgets/message_bubble.dart';

final _firebase = FirebaseAuth.instance;

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = _firebase.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            'created_at',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong...'),
          );
        }

        final dataMessage = snapshot.data!.docs;

        return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 16,
              left: 16,
              right: 16,
            ),
            reverse: true,
            itemCount: dataMessage.length,
            itemBuilder: (ctx, index) {
              final chatMessage = dataMessage[index].data();

              final nextIndex = index + 1;
              final nextChatMessage = nextIndex < dataMessage.length
                  ? dataMessage[nextIndex].data()
                  : null;

              final currentMessageUserId = chatMessage['user_id'];
              final nextMessageUserId =
                  nextChatMessage != null ? nextChatMessage['user_id'] : null;
              final nextUserIdIsSame =
                  nextMessageUserId == currentMessageUserId;

              if (nextUserIdIsSame) {
                return MessageBubble.next(
                  message: chatMessage['text'],
                  isMe: authenticatedUser.uid == currentMessageUserId,
                );
              } else {
                return MessageBubble.first(
                  userImage: chatMessage['user_image'],
                  username: chatMessage['username'],
                  message: chatMessage['text'],
                  isMe: authenticatedUser.uid == currentMessageUserId,
                );
              }
            });
      },
    );
  }
}
