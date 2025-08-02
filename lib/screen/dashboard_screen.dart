// 1. <-- IMPORT THE PACKAGES
import 'package:chat_bot_app/screen/chat_screen.dart';
import 'package:chat_bot_app/utils/app_constant.dart';
import 'package:chat_bot_app/utils/util_helper.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  var searchController = TextEditingController();

  // 2. <-- ADD SPEECH-TO-TEXT STATE VARIABLES
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // 3. <-- INITIALIZE THE SPEECH INSTANCE
    _speech = stt.SpeechToText();
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
      body: Padding(
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
                    minLines:
                        1, // Allows the text field to be smaller initially
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
                      // 5. <-- MODIFY THE MICROPHONE WIDGET
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: InkWell(
                          // Use InkWell for the ripple effect
                          onTap: _listen, // Call the listen function
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            decoration: BoxDecoration(
                              // Change color when listening
                              color: _isListening
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                // Change icon when listening
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
                                  builder: (context) =>
                                      ChatScreen(query: searchController.text),
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
            // ... (The rest of your code remains the same)
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
                        padding: const EdgeInsets.symmetric(horizontal: 9),
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
                itemCount:
                    AppConstant.defaultQues[selectedIndex]['question'].length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) {
                  Map<String, dynamic> data =
                      AppConstant.defaultQues[selectedIndex]['question'][index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(query: data['ques']),
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
      ),
    );
  }
}
