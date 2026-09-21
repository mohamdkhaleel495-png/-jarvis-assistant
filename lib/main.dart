import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Battery _battery = Battery();

  bool _isListening = false;
  String _status = "Jarvis Standby par hai";
  String _lastWords = "";

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
    _initTts();
    _listenToPhoneCalls();
  }

  // Sari zaroori permissions lena
  Future<void> _requestAllPermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
      Permission.contacts,
    ].request();
  }

  void _initTts() async {
    await _tts.setLanguage("hi-IN"); // Hindi / Indian Accent
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    setState(() => _status = text);
    await _tts.speak(text);
  }

  // Incoming call monitor karna
  void _listenToPhoneCalls() {
    PhoneState.stream.listen((status) async {
      if (status.status == PhoneStateStatus.CALL_INCOMING) {
        String number = status.number ?? "Unknown Number";
        String callerName = await _getContactName(number);
        _speak("Sir, $callerName ka call aa raha hai.");
      }
    });
  }

  // Contact list se naam nikalna
  Future<String> _getContactName(String phoneNumber) async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          if (phone.number.replaceAll(RegExp(r'\s+'), '').contains(phoneNumber.replaceAll(RegExp(r'\s+'), ''))) {
            return contact.displayName;
          }
        }
      }
    }
    return phoneNumber;
  }

  // Mic shuru karna
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => setState(() => _isListening = false),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          if (result.finalResult) {
            _processJarvisCommand(result.recognizedWords.toLowerCase());
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // Commands process karna
  void _processJarvisCommand(String command) async {
    // Agar command mein "jarvis" ya "hey jarvis" bola gaya ho
    if (command.contains("jarvis") || command.contains("hey jarvis")) {
      if (command.contains("time") || command.contains("samay") || command.contains("kitne baje")) {
        String time = DateFormat('hh:mm a').format(DateTime.now());
        _speak("Sir, abhi $time ho rahe hain.");
      } else if (command.contains("battery")) {
        int batteryLevel = await _battery.batteryLevel;
        _speak("Sir, aapke phone ki battery $batteryLevel percent hai.");
      } else if (command.contains("kaise ho") || command.contains("hal chal")) {
        _speak("Main active hoon sir, bataiye main aapki kya madad kar sakta hoon?");
      } else {
        _speak("Ji sir, sun raha hoon. Command batayein.");
      }
    } else {
      // Agar direct command di ho bina jarvis bole
      if (command.contains("time")) {
        String time = DateFormat('hh:mm a').format(DateTime.now());
        _speak("Abhi $time baje hain.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JARVIS AI"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.cyanAccent.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: _isListening ? Colors.cyanAccent : Colors.blueGrey,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 70,
                  color: _isListening ? Colors.cyanAccent : Colors.white60,
                ),
              ),
              const SizedBox(height: 35),
              Text(
                _lastWords.isEmpty ? "'Hey Jarvis, time kya hai?' bol kar dekhein" : "\"$_lastWords\"",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.cyanAccent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 50),
              FloatingActionButton.extended(
                backgroundColor: _isListening ? Colors.redAccent : Colors.cyan,
                onPressed: _isListening ? _stopListening : _startListening,
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.black),
                label: Text(
                  _isListening ? "Stop" : "Jarvis se Baat Karein",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
