import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat_bot_app/model/message_model.dart';
import 'package:chat_bot_app/provider/msg_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'dart:async'; // For StreamSubscription

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

  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Network connectivity variables
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true; // Assume online initially

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Initialize and listen for network changes
    _checkInitialConnectivityAndSendQuery();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // Clean up the listener
    super.dispose();
  }

  // Method to check initial connectivity and send the first message
  Future<void> _checkInitialConnectivityAndSendQuery() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);

    // Only send the initial query if online
    if (_isOnline && mounted) {
      Provider.of<MessageProvider>(context, listen: false)
          .sendMessage(message: widget.query);
    }
  }

  // Method to update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool online = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
    if (online != _isOnline) {
      setState(() {
        _isOnline = online;
      });
    }
  }

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
            // Ensure this asset exists in your project
            Image.asset("assets/icon/robot.png", height: 30, errorBuilder: (context, error, stackTrace) => Icon(Icons.android, color: Colors.white,)),
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
      // Conditional Body based on network status
      body: _isOnline ? _buildChatBody() : _buildOfflineBody(),
    );
  }
  
  // Widget for when the app is OFFLINE
  Widget _buildOfflineBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.white60,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              "You Are Offline",
              style: mTextStyle25(fontColor: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              "Please check your connection and try again.",
              style: mTextStyle18(fontColor: Colors.white70),
              textAlign: TextAlign.center,
            ),
             SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _checkInitialConnectivityAndSendQuery, // Reload on tap
                icon: const Icon(Icons.refresh),
                label: Text("Reload"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: mTextStyle18(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget for when the app is ONLINE
  Widget _buildChatBody() {
    return Column(
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
              prefixIcon: GestureDetector(
                onTap: _listen,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : Colors.white,
                ),
              ),
              suffixIcon: InkWell(
                onTap: () {
                  if (chatBoxController.text.isNotEmpty) {
                    Provider.of<MessageProvider>(context, listen: false)
                        .sendMessage(message: chatBoxController.text);
                    chatBoxController.clear();
                    if (_isListening) {
                      _speech.stop();
                      setState(() {
                        _isListening = false;
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
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.android, color: Colors.black45,),
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

// // These should be in your utils/util_helper.dart file
// TextStyle mTextStyle11({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(fontSize: 11, color: fontColor ?? Colors.black, fontWeight: fontWeight ?? FontWeight.normal);
// }
// TextStyle mTextStyle15({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(fontSize: 15, color: fontColor ?? Colors.black, fontWeight: fontWeight ?? FontWeight.normal);
// }
// TextStyle mTextStyle18({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(fontSize: 18, color: fontColor ?? Colors.black, fontWeight: fontWeight ?? FontWeight.normal);
// }
// TextStyle mTextStyle25({Color? fontColor, FontWeight? fontWeight}) {
//   return TextStyle(fontSize: 25, color: fontColor ?? Colors.black, fontWeight: fontWeight ?? FontWeight.bold);
// }