import 'package:chat_bot_app/screen/chat_screen.dart';
import 'package:chat_bot_app/utils/app_constant.dart';
// Make sure this path is correct for your project structure
import 'package:chat_bot_app/utils/util_helper.dart'; // Ensure util_helper.dart has mTextStyle functions
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'dart:async'; // For StreamSubscription

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  var searchController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Network connectivity variables
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true; // Assume online initially, will check on init

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Initialize connectivity listener
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription
        .cancel(); // Cancel subscription to prevent memory leaks
    super.dispose();
  }

  // Method to check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
  }

  // Method to update connection status based on ConnectivityResult
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool online = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
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
            searchController.text = val.recognizedWords;
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
      /// -------------- Appbar--------------------------///
      appBar: AppBar(
        title: Text.rich(
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

      /// -----------------------------BODY-----------------------------------///
      body: _isOnline
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline),
                            const SizedBox(width: 4),
                            Text(
                              "New chat",
                              style: mTextStyle18(fontColor: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.history),
                            const SizedBox(width: 4),
                            Text(
                              "History",
                              style: mTextStyle18(fontColor: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// Search Text field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          style: mTextStyle18(fontColor: Colors.white70),
                          onSubmitted: (value) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(query: searchController.text),
                              ),
                            );
                          },
                          maxLines: 6,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: "Write or say a question!",
                            hintStyle: mTextStyle18(fontColor: Colors.white38),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: InkWell(
                                onTap: _listen,
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isListening
                                        ? Colors.red.withOpacity(0.5)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () {
                                  if (_isListening) {
                                    _speech.stop();
                                    setState(() => _isListening = false);
                                  }
                                  if (searchController.text.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          query: searchController.text,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 6,
                                    ),
                                    child: Icon(Icons.send),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab Bar
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      itemCount: AppConstant.defaultQues.length,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: index == selectedIndex
                                  ? Border.all(width: 1, color: Colors.orange)
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                              child: Center(
                                child: Text(
                                  AppConstant.defaultQues[index]["title"],
                                  style: index == selectedIndex
                                      ? mTextStyle18(fontColor: Colors.orange)
                                      : mTextStyle18(fontColor: Colors.white60),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  ///  Quick Questions Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: AppConstant
                          .defaultQues[selectedIndex]['question']
                          .length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            crossAxisCount: 2,
                          ),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data = AppConstant
                            .defaultQues[selectedIndex]['question'][index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(query: data['ques']),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: data['color'],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(data['icon'], size: 30),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      data['ques'],
                                      style: mTextStyle18(
                                        fontColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : Center(
              // Show this when offline
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white60, size: 80),
                  SizedBox(height: 20),
                  Text(
                    "No Internet Connection",
                    style: mTextStyle25(fontColor: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Please check your internet or Wi-Fi.",
                    style: mTextStyle18(fontColor: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _checkInitialConnectivity, // Reload on tap
                    icon: const Icon(Icons.refresh),
                    label: Text("Reload"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: mTextStyle18(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


/// ----------------------------------------------------
/// PLACE THESE HELPER FUNCTIONS IN YOUR util_helper.dart FILE
/// Or, for a quick test, you can leave them here at the bottom of the file.
/// ----------------------------------------------------

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