enum FieldType { text, tts, audio, image, html }

enum FieldSide { front, back, both }

enum FieldSource { manual, ai, imported }

extension FieldTypeValue on FieldType {
  String get value {
    switch (this) {
      case FieldType.text: return 'TEXT';
      case FieldType.tts: return 'TTS';
      case FieldType.audio: return 'AUDIO';
      case FieldType.image: return 'IMAGE';
      case FieldType.html: return 'HTML';
    }
  }

  static FieldType fromString(String s) {
    switch (s) {
      case 'TTS': return FieldType.tts;
      case 'AUDIO': return FieldType.audio;
      case 'IMAGE': return FieldType.image;
      case 'HTML': return FieldType.html;
      default: return FieldType.text;
    }
  }
}

extension FieldSideValue on FieldSide {
  String get value {
    switch (this) {
      case FieldSide.front: return 'FRONT';
      case FieldSide.back: return 'BACK';
      case FieldSide.both: return 'BOTH';
    }
  }

  static FieldSide fromString(String s) {
    switch (s) {
      case 'BACK': return FieldSide.back;
      case 'BOTH': return FieldSide.both;
      default: return FieldSide.front;
    }
  }
}

extension FieldSourceValue on FieldSource {
  String get value {
    switch (this) {
      case FieldSource.manual: return 'MANUAL';
      case FieldSource.ai: return 'AI';
      case FieldSource.imported: return 'IMPORTED';
    }
  }

  static FieldSource fromString(String s) {
    switch (s) {
      case 'AI': return FieldSource.ai;
      case 'IMPORTED': return FieldSource.imported;
      default: return FieldSource.manual;
    }
  }
}