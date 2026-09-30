import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/error/failures.dart';
import '../../../core/use_case.dart';
import '../../../di/injector.dart';
import '../../../domain/entities/contact.dart';
import '../../../domain/entities/memory.dart';
import '../../../domain/value_objects/photo_reference.dart';

class MemoryDetailPage extends StatefulWidget {
  final AppContainer container;
  final Memory memory;

  const MemoryDetailPage({
    super.key,
    required this.container,
    required this.memory,
  });

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  final Map<String, Uint8List> _decodedPhotos = {};
  final Map<String, Failure> _photoErrors = {};
  Map<String, String>? _contactNames;
  bool _loadingContacts = true;

  Memory get _memory => widget.memory;

  @override
  void initState() {
    super.initState();
    _loadContactNames();
    for (final photo in _memory.photos) {
      _decryptPhoto(photo);
    }
  }

  Future<void> _loadContactNames() async {
    final result = await widget.container.loadContacts.execute(const NoParams());
    if (!mounted) return;
    setState(() {
      _loadingContacts = false;
      result.fold(
        onError: (_) => _contactNames = {},
        onSuccess: (contacts) {
          _contactNames = {
            for (final Contact c in contacts) c.id: c.displayName,
          };
        },
      );
    });
  }

  Future<void> _decryptPhoto(PhotoReference reference) async {
    final result =
        await widget.container.photoImage.execute(reference);
    if (!mounted) return;
    result.fold(
      onError: (failure) => setState(() => _photoErrors[reference.id] = failure),
      onSuccess: (bytes) => setState(() => _decodedPhotos[reference.id] = bytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = _memory.moment.utc.toLocal();
    final taggedNames = <String>[
      for (final id in _memory.taggedContactIds)
        _contactNames?[id] ?? 'Someone',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_memory.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          if (_memory.anchor != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_memory.anchor!.latitude.toStringAsFixed(5)}, '
                    '${_memory.anchor!.longitude.toStringAsFixed(5)}'
                    ' (${_memory.anchor!.geohash})',
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          if (_memory.journal != null) ...[
            Text(_memory.journal!.text,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],
          if (_memory.photos.isNotEmpty) ...[
            Text('Photos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final photo in _memory.photos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPhoto(photo),
              ),
            const SizedBox(height: 8),
          ],
          if (taggedNames.isNotEmpty) ...[
            Text('With',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final name in taggedNames) Chip(label: Text(name)),
              ],
            ),
          ],
          if (!_loadingContacts && _contactNames == null)
            const Text('Could not load contact names'),
        ],
      ),
    );
  }

  Widget _buildPhoto(PhotoReference reference) {
    final bytes = _decodedPhotos[reference.id];
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    }
    final error = _photoErrors[reference.id];
    if (error != null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          error is CryptoFailure
              ? 'This photo failed its integrity check'
              : 'Photo unavailable: ${error.message}',
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
