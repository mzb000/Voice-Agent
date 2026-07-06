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
  final apiKey = prefs.getString('api_key') ?? '';

  runApp(VoiceAgentApp(initialBaseUrl: baseUrl, initialApiKey: apiKey));
}

class VoiceAgentApp extends StatefulWidget {
  const VoiceAgentApp({super.key, required this.initialBaseUrl, required this.initialApiKey});
  final String initialBaseUrl;
  final String initialApiKey;

  @override
  State<VoiceAgentApp> createState() => _VoiceAgentAppState();
}

class _VoiceAgentAppState extends State<VoiceAgentApp> {
  late String _baseUrl = widget.initialBaseUrl;
  late String _apiKey = widget.initialApiKey;
  late AgentController _controller = _buildController(_baseUrl, _apiKey);

  AgentController _buildController(String url, String apiKey) {
    return AgentController(
      api: ApiClient(baseUrl: url, apiKey: apiKey),
      audio: AudioService(),
    );
  }

  Future<void> _onBaseUrlChanged(String url) async {
    // The Settings screen saves both backend_url and api_key to prefs before
    // popping, so re-read api_key here in case it changed alongside the URL.
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    if (!mounted) return;
    setState(() {
      _controller.dispose();
      _baseUrl = url;
      _apiKey = apiKey;
      _controller = _buildController(url, apiKey);
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
