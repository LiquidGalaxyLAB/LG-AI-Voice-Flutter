import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'global_connection.dart';
import 'connection_manager_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
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
  final recorder = AudioRecorder();
  String transcript = '';
  bool isRecording = false;

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

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  Future<void> voiceToVoice() async {
    if (isRecording) {
      final audioPath = await recorder.stop();
      setState(() {
        isRecording = false;
      });

      if (audioPath != null) {
        print('Recording saved at $audioPath');
        final audioFile = File(audioPath);
        final sttResult = await deepgram.transcribeFromFile(audioFile);
        setState(() {
          transcript = sttResult.transcript;
        });

        final llmResponse = await sendTextToGroqLLM(transcript);

        final ttsResult = await deepgram.speakFromText(llmResponse);
        await playAudio(ttsResult.data);
      }
    } else {
      if (await recorder.hasPermission()) {
        String path = '${Directory.systemTemp.path}/audio.wav';
        await recorder.start(const RecordConfig(), path: path);
        setState(() {
          isRecording = true;
        });
      }
    }
  }

  Future<void> playAudio(Uint8List audioData) async {
    AudioPlayer audioPlayer = AudioPlayer();
    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/output.wav');
      await tempFile.writeAsBytes(audioData);

      await audioPlayer.play(DeviceFileSource(tempFile.path));
      print('Playing audio from ${tempFile.path}');
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<String> sendTextToGroqLLM(String text) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final apiUrl = dotenv.env['GROQ_LLM_API_URL'] ?? '';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messages': [
          {
            'role': 'user',
            'content': text,
          }
        ],
        'model': 'gemma2-9b-it',
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to communicate with Groq LLM');
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
              onPressed: () => voiceToVoice(),
              style: buttonStyle,
              child: const Text('Voice', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await cleanKML();
                await setRefresh();
              },
              style: buttonStyle,
              child: const Text('Clear KML',
                  style: TextStyle(color: Colors.white)),
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

  Future<void> cleanKML() async {
    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      String kmlContent = '''
    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
      <Document>
      </Document>
    </kml>''';
      int rightScreen = (GlobalConnection.numberOfScreens / 2).floor() + 1;

      await GlobalConnection.sshClient!.execute(
          "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml");
    }
  }

  setRefresh() async {
    String password = GlobalConnection.clientPassword;
    for (var i = 2; i <= GlobalConnection.numberOfScreens; i++) {
      String kmlFileLocation =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href>';
      String changeRefresh =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';

      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$changeRefresh/$kmlFileLocation/" ~/earth/kml/slave/myplaces.kml\'');
      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$kmlFileLocation/$changeRefresh/" ~/earth/kml/slave/myplaces.kml\'');
    }
  }
}
