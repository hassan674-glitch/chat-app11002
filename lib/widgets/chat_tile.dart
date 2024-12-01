import 'package:flutter/material.dart';

import '../Pages/ChatScreen/chat_screen.dart';
class ChatTile extends StatelessWidget {
 final String chatId;
 final String lastMessage;
 final DateTime timeStamp;
final Map<String, dynamic> reciverData;
ChatTile({ required this.chatId,
  required this.lastMessage,
  required this.timeStamp,
  required this.reciverData
});
  @override
  Widget build(BuildContext context) {
    return lastMessage != "" ?ListTile(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(reciverData["imageUrl"]),

      ),
      title: Text(reciverData['name']),
      subtitle: Text(lastMessage,maxLines: 2,),
      trailing: Text('${timeStamp.hour}:${timeStamp.minute}',style: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),),
      onTap: (){
      Navigator.push(context, MaterialPageRoute(builder:
          (context)=>ChatScreen(chatId: chatId,
        reciverId: reciverData['uid'],)));
      },
    ):Container();
  }
}


