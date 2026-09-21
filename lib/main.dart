import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: JarvisHome(),
  ));
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isAwake = false;
  String _statusText = "Initializing...";
  String _recognizedWords = "";
  String _jarvisReply = "Say 'Hey Jarvis' to wake me up.";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initEngine();
  }

  void _initEngine() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(0.9);
    await _tts.setSpeechRate(0.5);

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          _restartListening();
        }
      },
      onError: (val) {
        _restartListening();
      },
    );

    if (available) {
      setState(() {
        _statusText = "Listening for 'Hey Jarvis'...";
      });
      _startWakeWordLoop();
    } else {
      setState(() {
        _statusText = "Microphone permission denied.";
      });
    }
  }

  void _restartListening() {
    if (mounted && !_speech.isListening) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _startWakeWordLoop();
      });
    }
  }

  void _startWakeWordLoop() {
    _speech.listen(
      onResult: (result) {
        String words = result.recognizedWords.toLowerCase();
        setState(() {
          _recognizedWords = result.recognizedWords;
        });

        if (!_isAwake) {
          if (words.contains("jarvis") || words.contains("hey jarvis")) {
            _onWakeWordTriggered();
          }
        } else {
          if (result.finalResult || words.length > 5) {
            _executeCommand(words);
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _onWakeWordTriggered() async {
    setState(() {
      _isAwake = true;
      _statusText = "Awake! Listening to your command...";
      _jarvisReply = "Yes Sir, I am listening.";
    });
    await _speech.stop();
    await _tts.speak("Yes Sir");

    Future.delayed(const Duration(milliseconds: 700), () {
      _startWakeWordLoop();
    });
  }

  void _executeCommand(String command) async {
    await _speech.stop();
    setState(() {
      _isAwake = false;
      _statusText = "Processing command...";
      _jarvisReply = "Executing: $command";
    });

    String replyText = "Command acknowledged: $command";
    await _tts.speak(replyText);

    setState(() {
      _statusText = "Listening for 'Hey Jarvis'...";
    });

    _restartListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text("J.A.R.V.I.S", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 3)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isAwake ? Colors.greenAccent : Colors.cyanAccent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isAwake ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isAwake ? Icons.graphic_eq : Icons.mic,
                  color: _isAwake ? Colors.greenAccent : Colors.cyanAccent,
                  size: 60,
                ),
              ),
              const SizedBox(height: 35),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 15),
              Text(
                _recognizedWords.isEmpty ? "..." : _recognizedWords,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 25),
              Text(
                _jarvisReply,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
