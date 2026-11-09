import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../services/backup_service.dart';

class BackupsScreen extends StatefulWidget {
  final AppStrings strings;
  const BackupsScreen({super.key, required this.strings});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final _service = BackupService();
  List<BackupInfo> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    try {
      await _service.create();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.backupCreated)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.strings.operationFailed}: $e')),
      );
    }
  }

  Future<void> _restore(BackupInfo b) async {
    final s = widget.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmRestoreTitle),
        content: Text(s.confirmRestore),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.restoreBackup)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.restore(b.file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.restoreBackup)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.operationFailed}: $e')),
      );
    }
  }

  Future<void> _share(BackupInfo b) async {
    try {
      await _service.share(b.file);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.backupsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add),
                          label: Text(s.createBackup),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text(
                            s.noBackups,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) {
                            final b = _items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  title: Text(
                                    b.file.path
                                        .split(Platform.pathSeparator)
                                        .last,
                                    style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${b.createdAt.toString().substring(0, 19)} · '
                                    '${(b.size / 1024).toStringAsFixed(1)} KB',
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share,
                                            size: 18),
                                        onPressed: () => _share(b),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.restore,
                                            size: 18),
                                        onPressed: () => _restore(b),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}