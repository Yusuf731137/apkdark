import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/settings_repository.dart';
import 'features/shell/main_shell.dart';

class MidadApp extends StatefulWidget {
  const MidadApp({super.key});
  @override
  State<MidadApp> createState() => _MidadAppState();
}

class _MidadAppState extends State<MidadApp> {
  final _settings = SettingsRepository();
  String _lang = 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _settings.get('general.language');
    if (v != null && mounted) setState(() => _lang = v);
  }

  Future<void> _changeLang(String lang) async {
    await _settings.set('general.language', lang);
    if (mounted) setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: Locale(_lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainShell(
        language: _lang,
        onLanguageChanged: _changeLang,
      ),
    );
  }
}