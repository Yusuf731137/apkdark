import 'tts_provider.dart';
import 'native_tts_provider.dart';

class TtsRegistry {
  static final TtsRegistry _instance = TtsRegistry._();
  factory TtsRegistry() => _instance;
  TtsRegistry._();

  final Map<String, TtsProvider> _providers = {};

  TtsProvider get system {
    _providers.putIfAbsent('system', () => NativeTtsProvider());
    return _providers['system']!;
  }

  TtsProvider get(String name) {
    if (name == 'system' || !_providers.containsKey(name)) {
      return system;
    }
    return _providers[name]!;
  }

  void register(TtsProvider p) {
    _providers[p.name] = p;
  }

  List<String> get names => _providers.isEmpty ? ['system'] : _providers.keys.toList();
}