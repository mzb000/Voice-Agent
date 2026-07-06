import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.currentBaseUrl});
  final String currentBaseUrl;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.currentBaseUrl);
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    if (mounted) _apiKeyController.text = apiKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Backend URL', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text(
                        'Point this to your FastAPI server. Use http://10.0.2.2:8000 on Android emulator, or your computer\'s LAN IP on a real device.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          hintText: 'http://192.168.1.10:8000',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('API Key', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text(
                        'Only needed if your backend has APP_API_KEY set. Sent as the X-API-Key header.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          hintText: 'Optional',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('backend_url', _urlController.text.trim());
                            await prefs.setString('api_key', _apiKeyController.text.trim());
                            if (mounted) Navigator.of(context).pop(_urlController.text.trim());
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
