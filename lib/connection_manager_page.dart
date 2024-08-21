import 'package:flutter/material.dart';
import 'global_connection.dart';

class ConnectionManagerPage extends StatefulWidget {
  const ConnectionManagerPage({super.key});

  @override
  _ConnectionManagerPageState createState() => _ConnectionManagerPageState();
}

class _ConnectionManagerPageState extends State<ConnectionManagerPage> {
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();
  final _numberOfScreensController = TextEditingController();
  final _deepgramApiKeyController = TextEditingController();
  final _groqApiKeyController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isDeepgramApiKeyVisible = false;
  bool _isGroqApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = GlobalConnection.host;
    _usernameController.text = GlobalConnection.username;
    _passwordController.text = GlobalConnection.clientPassword;
    _portController.text = GlobalConnection.port;
    _numberOfScreensController.text =
        GlobalConnection.numberOfScreens.toString();
    _deepgramApiKeyController.text = GlobalConnection.deepgramApiKey;
    _groqApiKeyController.text = GlobalConnection.groqApiKey;
  }

  Future<void> _connect() async {
    bool result = await GlobalConnection.connect(
      _ipController.text,
      _usernameController.text,
      _passwordController.text,
      _numberOfScreensController.text,
      _portController.text,
      _deepgramApiKeyController.text,
      _groqApiKeyController.text,
    );
    _showDialog(
      result ? "Connected!" : "Connection Failed",
      result
          ? "You have successfully connected."
          : "Failed to connect. Please try again.",
    );
    setState(() {});
  }

  void _disconnect() {
    GlobalConnection.disconnect();
    setState(() {});
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      textStyle: const TextStyle(fontSize: 18, color: Colors.white),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status: ${GlobalConnection.isConnected ? 'Connected' : 'Disconnected'}",
                style: TextStyle(
                  color:
                      GlobalConnection.isConnected ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _numberOfScreensController,
                decoration: const InputDecoration(
                  labelText: 'Number of Screens',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deepgramApiKeyController,
                decoration: InputDecoration(
                  labelText: 'Deepgram API Key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isDeepgramApiKeyVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDeepgramApiKeyVisible = !_isDeepgramApiKeyVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isDeepgramApiKeyVisible,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _groqApiKeyController,
                decoration: InputDecoration(
                  labelText: 'Groq API Key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isGroqApiKeyVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isGroqApiKeyVisible = !_isGroqApiKeyVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isGroqApiKeyVisible,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _connect(),
                      style: buttonStyle,
                      child: const Text('Connect'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _disconnect,
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                            GlobalConnection.isConnected
                                ? Colors.red
                                : Colors.grey),
                      ),
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
