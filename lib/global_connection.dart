import 'package:dartssh2/dartssh2.dart';

class GlobalConnection {
  static bool isConnected = false;
  static SSHClient? sshClient;
  static int numberOfScreens = 0;
  static String clientPassword = "";

  static Future<bool> connect(String host, String username, String password,
      String screenCount, String port) async {
    try {
      sshClient = SSHClient(
        await SSHSocket.connect(host, int.parse(port)),
        username: username,
        onPasswordRequest: () => password,
      );
      isConnected = true;
      numberOfScreens = int.parse(screenCount);
      clientPassword = password;
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
