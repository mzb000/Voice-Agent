import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/audio_service.dart';
import 'state/agent_controller.dart';
import 'theme/app_theme.dart';

const String kDefaultBaseUrl = 'http://127.0.0.1:8010'; // local backend (web/desktop run)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('backend_url') ?? kDefaultBaseUrl;

  runApp(VoiceAgentApp(initialBaseUrl: baseUrl));
}

class VoiceAgentApp extends StatefulWidget {
  const VoiceAgentApp({super.key, required this.initialBaseUrl});
  final String initialBaseUrl;

  @override
  State<VoiceAgentApp> createState() => _VoiceAgentAppState();
}

class _VoiceAgentAppState extends State<VoiceAgentApp> {
  late String _baseUrl = widget.initialBaseUrl;
  late AgentController _controller = _buildController(_baseUrl);

  AgentController _buildController(String url) {
    return AgentController(
      api: ApiClient(baseUrl: url),
      audio: AudioService(),
    );
  }

  void _onBaseUrlChanged(String url) {
    setState(() {
      _controller.dispose();
      _baseUrl = url;
      _controller = _buildController(url);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: MaterialApp(
        title: 'Voice Agent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: HomeScreen(baseUrl: _baseUrl, onBaseUrlChanged: _onBaseUrlChanged),
      ),
    );
  }
}
