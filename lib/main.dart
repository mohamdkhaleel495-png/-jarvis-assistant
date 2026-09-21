import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const JarvisHomeScreen(),
    );
  }
}

class JarvisHomeScreen extends StatefulWidget {
  const JarvisHomeScreen({super.key});

  @override
  State<JarvisHomeScreen> createState() => _JarvisHomeScreenState();
}

class _JarvisHomeScreenState extends State<JarvisHomeScreen> {
  // Yahan 'AAPKI_GEMINI_API_KEY_YAHAN_DAALEIN' hata kar apni real Gemini API key likhein
  static const String _geminiApiKey = 'AAPKI_GEMINI_API_KEY_YAHAN_DAALEIN';

  late final GenerativeModel _model;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _isLoading = false;
  String _userText = "Mic button dabayein aur kuch bole...";
  String _aiResponse = "";

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    _initTts();
  }

  void _initGemini() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(
        'Aap ek intelligent voice assistant hain jiska naam JARVIS hai. '
        'Aap har sawal ka saaf, seedha aur helpful jawab dete hain. '
        'Jawab concise aur easy to understand rakhein.',
      ),
    );
  }

  void _initSpeech() {
    _speech = stt.SpeechToText();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("hi-IN");
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _askGemini(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = "JARVIS soch raha hai...";
    });

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final reply = response.text ?? "Maaf kijiye, koi jawab nahi mila.";

      setState(() {
        _aiResponse = reply;
        _isLoading = false;
      });

      await _flutterTts.speak(reply);
    } catch (e) {
      setState(() {
        _aiResponse = "Error: $e\n(Check karein ki API key valid hai aur Internet chal raha hai)";
        _isLoading = false;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_userText.isNotEmpty && _userText != "Sun raha hoon...") {
              _askGemini(_userText);
            }
          }
        },
        onError: (val) => print('Error: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _userText = "Sun raha hoon...";
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _userText = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_userText.isNotEmpty && _userText != "Sun raha hoon...") {
        _askGemini(_userText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS Assistant'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Aapne kaha:", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_userText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("JARVIS ka jawab:", style: TextStyle(color: Colors.cyanAccent)),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Text(
                          _aiResponse.isEmpty ? "Sawalon ke jawab yahan aayenge..." : _aiResponse,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FloatingActionButton.large(
              onPressed: _listen,
              backgroundColor: _isListening ? Colors.red : Colors.cyan,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 40),
            ),
            const SizedBox(height: 10),
            Text(_isListening ? "Listening..." : "Tap mic to speak"),
          ],
        ),
      ),
    );
  }
}

