import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Help'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/logo.png'),
              width: 500,
            ),
            SizedBox(height: 20),
            Text(
              'App usage\n\nThis app was built to demo the flow of the voice-to-voice feature using various models. To test the feature, create an API key from Deepgram and Groq. Go to the settings page and add the keys along with the details to connect to LG, then ask any questions that will lead to the model pointing out a specific location to get back a response.\n\nFor example, a user can ask "What is the best restaurant in Paris?" and the model will pick out a place and talk briefly about the place while navigating to the location on Liquid Galaxy.\n',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
