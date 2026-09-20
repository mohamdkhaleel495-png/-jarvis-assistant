import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  String _userText = "Press mic button and speak...";
  String _jarvisResponse = "JARVIS is ready, Sir.";

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  void _initVoice() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setPitch(0.9);
    await _tts.setSpeechRate(0.5);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _userText = val.recognizedWords;
          });
          if (val.hasConfidenceRating && val.confidence > 0) {
            _askJarvis(val.recognizedWords);
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _askJarvis(String prompt) async {
    _speech.stop();
    setState(() {
      _isListening = false;
      _jarvisResponse = "JARVIS thinking...";
    });

    String reply = "Aapne kaha: $prompt. Main aapki kya madad kar sakta hoon?";
    setState(() => _jarvisResponse = reply);
    await _tts.speak(reply);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("J.A.R.V.I.S", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        _userText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        _jarvisResponse,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FloatingActionButton.large(
              onPressed: _listen,
              backgroundColor: _isListening ? Colors.redAccent : Colors.cyanAccent,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
                size: 36,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
