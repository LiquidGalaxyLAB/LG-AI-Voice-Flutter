import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'global_connection.dart';
import 'connection_manager_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Deepgram deepgram;
  String transcript = '';
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    String apiKey = dotenv.env['DEEPGRAM_API_KEY'] ?? '';
    deepgram = Deepgram(apiKey, baseQueryParams: {
      'model': 'nova-2-general',
      'detect_language': true,
      'filler_words': false,
      'punctuation': true,
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      if (_recordingPath != null) {
        await _transcribeRecordedAudio(File(_recordingPath!));
      }
    } else {
      if (await _recorder.hasPermission()) {
        Directory tempDir = await getTemporaryDirectory();
        String filePath = '${tempDir.path}/recorded_audio.m4a';

        await _recorder.start(const RecordConfig(), path: filePath);

        setState(() {
          _isRecording = true;
        });
      } else {
        print("Recording permission not granted");
      }
    }
  }

  Future<void> _transcribeRecordedAudio(File audioFile) async {
    try {
      if (await deepgram.isApiKeyValid()) {
        final sttResult = await deepgram.transcribeFromFile(audioFile);
        setState(() {
          transcript = sttResult.transcript ?? 'No transcript available';
        });
        print("Transcription result: ${sttResult.transcript}");
      } else {
        print("API Key is invalid or expired.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
      textStyle: const TextStyle(fontSize: 20, color: Colors.white),
      minimumSize: const Size(260, 70),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Flutter App'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 50),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ConnectionManagerPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png', width: 400),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleRecording,
              style: buttonStyle,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording',
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            if (transcript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  transcript,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
