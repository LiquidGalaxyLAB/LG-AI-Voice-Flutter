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
  String groqResponse = '';
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

        await _sendToGroqAPI(transcript);
      } else {
        print("API Key is invalid or expired.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _sendToGroqAPI(String content) async {
    final String groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final String groqModel = 'gemma2-9b-it';

    final String prePrompt = '''
  Expect a user input where they would ask you to come up or talk about a location somewhere in the world. If the question is asking you for your opinion, pick one location even if you're not exactly sure about what's right. So what I want you to return is a prompt that answers the question as well as the coordinates in a JSON object. Do not say anything else and only return the object with the three things: latitude, longitude, and your response to the question. This is because I am using it for an app and it cannot be in any other format. For example, a user might ask you what the best restaurant in Paris is. Just pick one answer that can fit in, it does not need to be factual since it's an opinion. Let's say you choose the Clover Grill restaurant in Paris. Your response can be something along the lines of:

  {"latitude": "48.86809847865695", "longitude": "2.3409434973723404", "response": "Clover Grill is a popular restaurant located in the heart of Paris, France. The restaurant serves a fusion of French and American cuisine, with a focus on grilled meats and seafood."}

  And do not say ANYTHING ELSE as that will break my application. If you do not know anything about the location or do not know the coordinates or you do not know how to answer the question as the user may have said something unexpected, just return an empty string as the corresponding field(s) and I will handle the rest on my own.

  Here's the user's input:
  ''';

    final String combinedPrompt = '$prePrompt $content';

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $groqApiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'messages': [
        {'role': 'user', 'content': combinedPrompt}
      ],
      'model': groqModel,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        print("Raw JSON response: ${response.body}");

        setState(() {
          groqResponse = jsonResponse['choices'][0]['message']['content'] ??
              'No response available';
        });
        print("Groq API response: $groqResponse");
      } else {
        print("Failed to get response from Groq API: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending request to Groq API: $e");
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
            const SizedBox(height: 20),
            if (groqResponse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  groqResponse,
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
