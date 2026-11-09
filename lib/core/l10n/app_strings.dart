class AppStrings {
  final String language;
  const AppStrings(this.language);

  bool get isAr => language == 'ar';

  String _t(String ar, String en) => isAr ? ar : en;

  // Common
  String get appName => _t('مِداد', 'Midad');
  String get save => _t('حفظ', 'Save');
  String get cancel => _t('إلغاء', 'Cancel');
  String get delete => _t('حذف', 'Delete');
  String get edit => _t('تعديل', 'Edit');
  String get add => _t('إضافة', 'Add');
  String get back => _t('عودة', 'Back');
  String get close => _t('إغلاق', 'Close');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get loading => _t('جارٍ التحميل...', 'Loading...');
  String get error => _t('خطأ', 'Error');
  String get confirm => _t('تأكيد', 'Confirm');
  String get name => _t('الاسم', 'Name');
  String get description => _t('الوصف', 'Description');

  // Nav
  String get navDashboard => _t('الرئيسية', 'Dashboard');
  String get navDecks => _t('المجموعات', 'Decks');
  String get navCards => _t('البطاقات', 'Cards');
  String get navStats => _t('الإحصائيات', 'Statistics');
  String get navSettings => _t('الإعدادات', 'Settings');

  // Dashboard
  String get dashboardTitle => _t('لوحة التحكم', 'Dashboard');
  String get statTotalCards => _t('إجمالي البطاقات', 'Total cards');
  String get statDue => _t('مستحق اليوم', 'Due today');
  String get statNew => _t('جديدة', 'New');
  String get statDecks => _t('المجموعات', 'Decks');
  String get startReview => _t('ابدأ المراجعة', 'Start review');

  // Decks
  String get decksTitle => _t('المجموعات', 'Decks');
  String get newDeck => _t('مجموعة جديدة', 'New deck');
  String get editDeck => _t('تعديل المجموعة', 'Edit deck');
  String get deleteDeck => _t('حذف المجموعة', 'Delete deck');
  String get deckName => _t('اسم المجموعة', 'Deck name');
  String get deckDescription => _t('الوصف (اختياري)', 'Description (optional)');
  String get noDecksYet => _t('لا توجد مجموعات بعد', 'No decks yet');
  String get mustKeepOneDeck => _t('يجب الإبقاء على مجموعة واحدة على الأقل', 'Must keep at least one deck');
  String get deckNameRequired => _t('اسم المجموعة مطلوب', 'Deck name required');

  // Deck Detail
  String get deckCardsTitle => _t('البطاقات', 'Cards');
  String get newCard => _t('بطاقة جديدة', 'New card');
  String get editCard => _t('تعديل البطاقة', 'Edit card');
  String get deleteCard => _t('حذف البطاقة', 'Delete card');
  String get noCardsYet => _t('لا توجد بطاقات', 'No cards yet');
  String get cards => _t('البطاقات', 'Cards');
  String get due => _t('مستحقة', 'Due');
  String get learning => _t('قيد التعلم', 'Learning');
  String get review => _t('مراجعة', 'Review');
  String get suspended => _t('معلّقة', 'Suspended');

  // Card Editor
  String get front => _t('الوجه الأمامي', 'Front');
  String get back => _t('الوجه الخلفي', 'Back');
  String get frontBackRequired => _t('يجب تعبئة الوجهين', 'Both sides required');

  // Fields
  String get fields => _t('الحقول', 'Fields');
  String get addField => _t('＋ حقل جديد', '＋ Add field');
  String get editField => _t('تعديل الحقل', 'Edit field');
  String get deleteField => _t('حذف الحقل', 'Delete field');
  String get fieldName => _t('اسم الحقل', 'Field name');
  String get fieldType => _t('النوع', 'Type');
  String get fieldSide => _t('الجانب', 'Side');
  String get fieldLanguage => _t('اللغة', 'Language');
  String get fontSize => _t('حجم الخط', 'Font size');
  String get ttsProvider => _t('مزوّد الصوت', 'TTS provider');
  String get ttsVoice => _t('الصوت', 'Voice');
  String get ttsRate => _t('السرعة', 'Speed');
  String get source => _t('المصدر', 'Source');
  String get sortOrder => _t('الترتيب', 'Order');
  String get testAudio => _t('اختبار الصوت', 'Test audio');
  String get fieldInUse => _t('لا يمكن حذف حقل يحتوي على بيانات', 'Cannot delete a field with data');

  String get sideFront => _t('أمامي', 'Front');
  String get sideBack => _t('خلفي', 'Back');
  String get sideBoth => _t('كلاهما', 'Both');

  String get typeText => _t('نص', 'Text');
  String get typeTts => _t('نص منطوق', 'TTS');
  String get typeAudio => _t('صوت', 'Audio');
  String get typeImage => _t('صورة', 'Image');
  String get typeHtml => _t('HTML', 'HTML');

  // Review
  String get reviewTitle => _t('جلسة المراجعة', 'Review session');
  String get question => _t('السؤال', 'Question');
  String get answer => _t('الإجابة', 'Answer');
  String get flip => _t('اقلب البطاقة', 'Flip card');
  String get flipHint => _t('اضغط أو اسحب', 'Tap or swipe');
  String get ratingFail => _t('لم أتذكر', 'Fail');
  String get ratingHard => _t('بصعوبة', 'Hard');
  String get ratingGood => _t('جيد', 'Good');
  String get ratingEasy => _t('سهل', 'Easy');
  String get sessionComplete => _t('اكتملت الجلسة 🎉', 'Session complete 🎉');
  String get reviewedCount => _t('بطاقة تمت مراجعتها', 'cards reviewed');
  String get nextReview => _t('المراجعة التالية', 'Next review');

  // Review setup
  String get reviewMode => _t('الوضع', 'Mode');
  String get modeFsrs => _t('FSRS', 'FSRS');
  String get modeRandom => _t('عشوائي', 'Random');
  String get modeCreated => _t('بترتيب الإنشاء', 'Created order');
  String get limitOptional => _t('حد البطاقات (اختياري)', 'Limit (optional)');
  String get noLimit => _t('بلا حد', 'No limit');
  String get cramSession => _t('جلسة تحفيظ مؤقتة', 'Cram session');
  String get cramHint => _t('لا تعدّل جدولة FSRS', "Won't change FSRS schedule");
  String get startSession => _t('ابدأ الجلسة', 'Start session');
  String get noCardsDue => _t('لا توجد بطاقات مستحقة', 'No cards due');

  // Ratings in review
  String get ratingFailFull => _t('لم أتذكر', 'Fail');
  String get ratingHardFull => _t('بصعوبة', 'Hard');
  String get ratingGoodFull => _t('جيد', 'Good');
  String get ratingEasyFull => _t('سهل', 'Easy');

  // Audio
  String get audioUnavailable => _t('الصوت غير متوفر', 'Audio unavailable');
  String get playAudio => _t('تشغيل', 'Play');

  // Auto-pronounce
  String get autoPronounceFront => _t('نطق تلقائي (أمامي)', 'Auto-pronounce front');
  String get autoPronounceBack => _t('نطق تلقائي (خلفي)', 'Auto-pronounce back');
  String get autoPronounceDelay => _t('تأخير النطق (مللي ثانية)', 'Auto-pronounce delay (ms)');

  // Stats
  String get statsTitle => _t('الإحصائيات', 'Statistics');
  String get allDecks => _t('كل المجموعات', 'All decks');
  String get ratingDistribution => _t('توزيع التقييمات', 'Rating distribution');
  String get reviewsLast7Days => _t('آخر 7 أيام', 'Last 7 days');
  String get reviewsLast30Days => _t('آخر 30 يومًا', 'Last 30 days');
  String get gradeDistribution => _t('توزيع الدرجات', 'Grade distribution');
  String get gradeNew => _t('جديدة', 'New');
  String get gradeF => 'F';
  String get gradeE => 'E';
  String get gradeD => 'D';
  String get gradeC => 'C';
  String get gradeB => 'B';
  String get gradeA => 'A';

  // Import
  String get importTitle => _t('استيراد CSV', 'Import CSV');
  String get chooseFile => _t('اختيار ملف', 'Choose file');
  String get importDefaultDeck => _t('المجموعة الافتراضية', 'Default deck');
  String get importButton => _t('استيراد', 'Import');
  String get importedCount => _t('بطاقة تم استيرادها', 'cards imported');

  // Backups
  String get backupsTitle => _t('النسخ الاحتياطية', 'Backups');
  String get restoreSelected => _t('استعادة المحدد', 'Restore selected');
  String get confirmRestore => _t('سيتم استبدال البيانات الحالية. متابعة؟', 'Current data will be replaced. Continue?');

  // Settings
  String get settingsTitle => _t('الإعدادات', 'Settings');
  String get language => _t('اللغة', 'Language');
  String get theme => _t('الثيم', 'Theme');
  String get darkTheme => _t('داكن', 'Dark');
  String get lightTheme => _t('فاتح', 'Light');
  String get newCardsPerDay => _t('بطاقات جديدة في اليوم', 'New cards per day');
  String get reviewsPerDay => _t('مراجعات في اليوم', 'Reviews per day');
  String get unlimited => _t('بلا حد', 'Unlimited');
  String get defaultSpeed => _t('سرعة الصوت الافتراضية', 'Default audio speed');
  String get desiredRetention => _t('نسبة التذكر المستهدفة', 'Desired retention');
  String get maxInterval => _t('أقصى فاصل (أيام)', 'Max interval (days)');

  // Batch 3 additions
  String get audioSpeed => _t('سرعة الصوت', 'Audio speed');
  String get loadingAudio => _t('جارٍ تحميل الصوت...', 'Loading audio...');
  String get speakAgain => _t('نطق مرة أخرى', 'Speak again');
  String get reviewModes => _t('أوضاع المراجعة', 'Review modes');
  String get selectDeck => _t('اختر مجموعة', 'Select deck');
  String get noDecksAvailable => _t('لا توجد مجموعات', 'No decks available');
  String get startCramSession => _t('جلسة تحفيظ', 'Cram session');
  String get sessionReviewCount => _t('بطاقة', 'cards');
  String get dailyLimitReached => _t('تم الوصول للحد اليومي', 'Daily limit reached');
  String get preparingAudio => _t('تحضير الصوت...', 'Preparing audio...');
  String get ttsNotAvailable => _t('النطق غير متاح على هذا الجهاز', 'TTS not available on this device');

  // Batch 4 additions
  String get navStats => _t('الإحصائيات', 'Statistics');
  String get navCards => _t('البطاقات', 'Cards');
  String get filterAll => _t('الكل', 'All');
  String get filterNew => _t('جديدة', 'New');
  String get filterLearning => _t('قيد التعلم', 'Learning');
  String get filterDue => _t('مستحقة', 'Due');
  String get filterReview => _t('مراجعة', 'Review');
  String get filterSuspended => _t('معلّقة', 'Suspended');
  String get sortCreated => _t('تاريخ الإنشاء', 'Created');
  String get sortAlpha => _t('أبجدي', 'Alphabetical');
  String get sortLastReview => _t('آخر مراجعة', 'Last review');
  String get sortDue => _t('الاستحقاق', 'Due date');
  String get sortDifficulty => _t('الصعوبة', 'Difficulty');
  String get sortStability => _t('الاستقرار', 'Stability');
  String get filter => _t('فلترة', 'Filter');
  String get sortBy => _t('ترتيب', 'Sort');
  String get cardCount => _t('عدد البطاقات', 'Card count');
  String get last7Days => _t('آخر 7 أيام', 'Last 7 days');
  String get last30Days => _t('آخر 30 يوم', 'Last 30 days');
  String get last90Days => _t('آخر 90 يوم', 'Last 90 days');
  String get allTime => _t('كل الفترات', 'All time');
  String get reviewedToday => _t('مراجعات اليوم', 'Reviewed today');
  String get reviewsTrend => _t('اتجاه المراجعات', 'Reviews trend');
  String get avgDuration => _t('متوسط المدة', 'Avg duration');
  String get seconds => _t('ثانية', 'seconds');
  String get totalCardsLabel => _t('إجمالي البطاقات', 'Total cards');
  String get newCardsLabel => _t('البطاقات الجديدة', 'New cards');
  String get dueCardsLabel => _t('المستحقة', 'Due cards');
  String get reviewedCardsLabel => _t('المراجعات', 'Reviews');
  String get createBackup => _t('إنشاء نسخة', 'Create backup');
  String get restoreBackup => _t('استعادة', 'Restore');
  String get shareBackup => _t('مشاركة', 'Share');
  String get noBackups => _t('لا توجد نسخ احتياطية', 'No backups yet');
  String get backupCreated => _t('تم إنشاء نسخة احتياطية', 'Backup created');
  String get confirmRestoreTitle => _t('استعادة نسخة احتياطية', 'Restore backup');
  String get importCsvTitle => _t('استيراد CSV', 'Import CSV');
  String get chooseCsv => _t('اختر ملف CSV', 'Choose CSV file');
  String get imported => _t('تم الاستيراد', 'Imported');
  String get importHint => _t('الأعمدة: front,back[,deck] أو السؤال,الإجابة,المجموعة',
      'Columns: front,back[,deck] or question,answer,group');
  String get cacheSize => _t('حجم الكاش', 'Cache size');
  String get clearCache => _t('مسح الكاش', 'Clear cache');
  String get cacheCleared => _t('تم مسح الكاش', 'Cache cleared');
  String get reviewMode2 => _t('وضع المراجعة', 'Review mode');
  String get autoAdvance => _t('تقدم تلقائي', 'Auto advance');
  String get dailyNewLimit => _t('حد البطاقات الجديدة/يوم', 'New cards per day');
  String get dailyReviewLimit => _t('حد المراجعات/يوم', 'Reviews per day');
  String get volumeLabel => _t('مستوى الصوت', 'Volume');
  String get desiredRetentionLabel => _t('نسبة التذكر المستهدفة', 'Desired retention');
  String get maxIntervalLabel => _t('أقصى فاصل (أيام)', 'Max interval (days)');
  String get aboutSection => _t('حول', 'About');
  String get aboutText2 => _t(
    'مِداد — بطاقات بجدولة FSRS. يعمل دون إنترنت.',
    'Midad — flashcards with FSRS. Works offline.',
  );
  String get invalidValues => _t('قيم غير صالحة', 'Invalid values');
  String get operationFailed => _t('فشلت العملية', 'Operation failed');

  // About
  String get about => _t('حول', 'About');
  String get aboutText => _t(
    'مِداد — تطبيق بطاقات تعليمية بجدولة FSRS. يعمل دون إنترنت.',
    'Midad — Flashcards with FSRS scheduling. Works offline.'
  );
}