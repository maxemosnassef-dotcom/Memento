import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/use_case.dart';
import '../../../di/injector.dart';
import '../bloc/capture_bloc.dart';

class CapturePage extends StatelessWidget {
  final AppContainer container;
  final VoidCallback onSaved;

  const CapturePage({
    super.key,
    required this.container,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CaptureBloc>(
      create: (_) => CaptureBloc(
        createMemory: container.createMemory,
        loadContacts: container.loadContacts,
        resolveCurrentAnchor: container.currentAnchor,
      )..add(const ContactsLoaded()),
      child: _CaptureView(container: container, onSaved: onSaved),
    );
  }
}

class _CaptureView extends StatefulWidget {
  final AppContainer container;
  final VoidCallback onSaved;

  const _CaptureView({required this.container, required this.onSaved});

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  final _titleController = TextEditingController();
  final _journalController = TextEditingController();
  DateTime _when = DateTime.now();
  bool _hotspotSyncQueued = false;

  @override
  void dispose() {
    _titleController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 88);
      if (files.isEmpty || !mounted) return;
      final bytesList = <Uint8List>[];
      for (final file in files) {
        bytesList.add(await file.readAsBytes());
      }
      if (!mounted) return;
      context.read<CaptureBloc>().add(PhotosAdded(bytesList));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected photos')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _when = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture a memory')),
      body: BlocConsumer<CaptureBloc, CaptureFormState>(
        listener: (context, state) {
          if (state.submissionSucceeded && !_hotspotSyncQueued) {
            _hotspotSyncQueued = true;
            unawaitedHotspotSync();
            widget.onSaved();
            Navigator.of(context).pop();
          }
          final error = state.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error)));
          }
        },
        builder: (context, state) {
          return AbsorbPointer(
            absorbing: state.submitting,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration:
                      const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _journalController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Journal',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.event_outlined),
                    const SizedBox(width: 8),
                    Text(_formatDate(_when)),
                    const Spacer(),
                    TextButton(onPressed: _pickDate, child: const Text('Change')),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.place_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.attachedAnchor == null
                            ? 'No place attached'
                            : '${state.attachedAnchor!.latitude.toStringAsFixed(5)}, '
                                '${state.attachedAnchor!.longitude.toStringAsFixed(5)}',
                      ),
                    ),
                    if (state.resolvingLocation)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (state.attachedAnchor == null)
                      TextButton(
                        onPressed: () => context
                            .read<CaptureBloc>()
                            .add(const CurrentLocationAttachRequested()),
                        child: const Text('Pin here'),
                      )
                    else
                      TextButton(
                        onPressed: () => context
                            .read<CaptureBloc>()
                            .add(const LocationPinDetached()),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined),
                    const SizedBox(width: 8),
                    Text('${state.photos.length} photo(s)'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (state.photos.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              state.photos[index],
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => context
                                  .read<CaptureBloc>()
                                  .add(PhotoRemoved(index)),
                              child: const Icon(Icons.cancel,
                                  color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(),
                if (state.contacts.isEmpty)
                  const Text('No contacts yet - add some to tag people.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final contact in state.contacts)
                        FilterChip(
                          label: Text(contact.displayName),
                          selected: state.selectedContactIds
                              .contains(contact.id),
                          onSelected: (_) => context.read<CaptureBloc>().add(
                                ContactToggled(contact.id),
                              ),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.submitting ? null : _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(state.submitting
                      ? 'Encrypting & saving...'
                      : 'Preserve this memory'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    context.read<CaptureBloc>().add(MemorySubmitted(
          title: _titleController.text,
          journalText: _journalController.text,
          whenLocal: _when,
        ));
  }

  void unawaitedHotspotSync() {
    unawaited(widget.container.hotspotSync.execute(const NoParams()));
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
