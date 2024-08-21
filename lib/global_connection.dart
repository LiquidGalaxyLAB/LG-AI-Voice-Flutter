import 'package:dartssh2/dartssh2.dart';

class GlobalConnection {
  static bool isConnected = false;
  static SSHClient? sshClient;
  static int numberOfScreens = 3;
  static String clientPassword = "";
  static String deepgramApiKey = "";
  static String groqApiKey = "";

  static String host = "";
  static String username = "";
  static String port = "22";

  static Future<bool> connect(
      String host,
      String username,
      String password,
      String screenCount,
      String port,
      String deepgramKey,
      String groqKey) async {
    try {
      sshClient = SSHClient(
        await SSHSocket.connect(host, int.parse(port)),
        username: username,
        onPasswordRequest: () => password,
      );
      isConnected = true;
      numberOfScreens = int.parse(screenCount);
      clientPassword = password;
      GlobalConnection.deepgramApiKey = deepgramKey;
      GlobalConnection.groqApiKey = groqKey;
      GlobalConnection.host = host;
      GlobalConnection.username = username;
      GlobalConnection.port = port;

      return true;
    } catch (e) {
      isConnected = false;
      sshClient = null;
      return false;
    }
  }

  static void disconnect() {
    sshClient?.close();
    isConnected = false;
    sshClient = null;
  }
}
