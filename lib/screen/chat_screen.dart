import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat_bot_app/model/message_model.dart';
import 'package:chat_bot_app/provider/msg_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // 1. <-- IMPORT PACKAGE

import '../utils/util_helper.dart';

class ChatScreen extends StatefulWidget {
  final String query;
  const ChatScreen({super.key, required this.query});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  var chatBoxController = TextEditingController();
  List<MessageModel> listMsg = [];
  DateFormat dateFormat = DateFormat().add_jm();

  // 2. <-- ADD SPEECH-TO-TEXT STATE VARIABLES
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    // 3. <-- INITIALIZE SPEECH INSTANCE
    _speech = stt.SpeechToText();

    /// Send initial query when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<MessageProvider>(
        context,
        listen: false,
      ).sendMessage(message: widget.query);
    });
  }

  // 4. <-- ADD THE LISTEN FUNCTION
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            // Update the controller with the recognized words
            chatBoxController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/icon/robot.jpeg", height: 30),
            Text.rich(
              TextSpan(
                text: "Chat",
                style: mTextStyle25(fontColor: Colors.white),
                children: [
                  TextSpan(
                    text: "bot",
                    style: mTextStyle25(fontColor: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade200.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(100),
              ),
              child: IconButton(icon: const Icon(Icons.face), onPressed: () {}),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// ---------------- Chat List ----------------------- ///
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (_, provider, child) {
                listMsg = provider.listMessage;
                return ListView.builder(
                  reverse: true,
                  itemCount: listMsg.length,
                  itemBuilder: (context, index) {
                    return listMsg[index].sendId == 0
                        ? userChatBox(listMsg[index])
                        : botChatBox(listMsg[index], index); //
                  },
                );
              },
            ),
          ),

          /// Chat box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: chatBoxController,
              style: mTextStyle18(fontColor: Colors.white70),
              decoration: InputDecoration(
                // 5. <-- UPDATE THE PREFIX ICON
                prefixIcon: GestureDetector(
                  onTap: _listen, // Call the listen function on tap
                  child: Icon(
                    // Change icon and color based on listening state
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.white,
                  ),
                ),
                suffixIcon: InkWell(
                  onTap: () {
                    if (chatBoxController.text.isNotEmpty) {
                      Provider.of<MessageProvider>(
                        context,
                        listen: false,
                      ).sendMessage(message: chatBoxController.text);
                      chatBoxController.clear();
                      // If it's listening, stop it
                      if (_isListening) {
                        _speech.stop();
                        setState(() {
                          _isListening = false;
                          chatBoxController.text =
                              ''; // Clear input after sending
                        });
                      }
                    }
                  },
                  child: const Icon(Icons.send, color: Colors.orange),
                ),
                hintText: "Write or say a question!",
                hintStyle: mTextStyle18(fontColor: Colors.white38),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Right Side - User Chat Box
  Widget userChatBox(MessageModel msgModel) {
    var time = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(int.parse(msgModel.sendAt!)),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(21),
            topRight: Radius.circular(21),
            bottomLeft: Radius.circular(21),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msgModel.msg!, style: mTextStyle18(fontColor: Colors.white70)),
            Text(
              time,
              style: mTextStyle11(
                fontColor: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Side - Bot Chat Box
  Widget botChatBox(MessageModel msgModel, int index) {
    var time = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(int.parse(msgModel.sendAt!)),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade300,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(21),
            topRight: Radius.circular(21),
            bottomRight: Radius.circular(21),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Bot Message
            msgModel.isRead!
                ? SelectableText(
                    msgModel.msg!,
                    style: mTextStyle18(fontColor: Colors.black87),
                  )
                : DefaultTextStyle(
                    style: mTextStyle18(fontColor: Colors.black87),
                    child: AnimatedTextKit(
                      repeatForever: false,
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      onFinished: () {
                        context.read<MessageProvider>().updateMessageRead(
                          index,
                        );
                      },
                      animatedTexts: [
                        TypewriterAnimatedText(
                          msgModel.msg!,
                          textStyle: mTextStyle18(fontColor: Colors.black87),
                        ),
                      ],
                    ),
                  ),

            /// Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      "assets/icon/typing.png",
                      height: 30,
                      width: 30,
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msgModel.msg!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Text copied to clipboard!",
                              style: mTextStyle18(fontColor: Colors.white70),
                            ),
                            backgroundColor: Colors.orange.withOpacity(0.8),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.copy_rounded, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: mTextStyle15(
                    fontColor: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Make sure you have these helper functions defined in your utils/util_helper.dart
// Or define them here if you haven't already.

// TextStyle mTextStyle11({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(
//     fontSize: 11,
//     color: fontColor ?? Colors.black,
//     fontWeight: fontWeight ?? FontWeight.normal,
//   );
// }

// TextStyle mTextStyle15({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(
//     fontSize: 15,
//     color: fontColor ?? Colors.black,
//     fontWeight: fontWeight ?? FontWeight.normal,
//   );
// }

// TextStyle mTextStyle18({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(
//     fontSize: 18,
//     color: fontColor ?? Colors.black,
//     fontWeight: fontWeight ?? FontWeight.normal,
//   );
// }

// TextStyle mTextStyle25({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(
//     fontSize: 25,
//     color: fontColor ?? Colors.black,
//     fontWeight: fontWeight ?? FontWeight.bold,
//   );
// }
