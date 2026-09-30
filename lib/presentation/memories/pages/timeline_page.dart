import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/use_case.dart';
import '../../../di/injector.dart';
import '../../../domain/repositories/location_port.dart';
import '../../capture/pages/capture_page.dart';
import '../../contacts/pages/contacts_page.dart';
import '../bloc/memories_bloc.dart';
import 'memory_detail_page.dart';

class TimelinePage extends StatefulWidget {
  final AppContainer container;

  const TimelinePage({super.key, required this.container});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late final MemoriesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MemoriesBloc(
      onThisDay: widget.container.onThisDayMemories,
      between: widget.container.memoriesBetween,
      nearby: widget.container.memoriesNearby,
    );
    _bloc.add(OnThisDayRequested(referenceLocal: DateTime.now()));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _refreshOnThisDay() {
    _bloc.add(OnThisDayRequested(referenceLocal: DateTime.now()));
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CapturePage(
        container: widget.container,
        onSaved: _refreshOnThisDay,
      ),
    ));
    _refreshOnThisDay();
  }

  Future<void> _openPlaceAlertsOptIn() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable place alerts?'),
        content: const Text(
          'MEMENTO will quietly watch the places tied to your memories and '
          'notify you when you return to one.\n\n'
          'Location is processed entirely on this device - it never leaves '
          'your phone. The system will ask for "Allow all the time" '
          'location permission so this can work in the background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final permission =
        await widget.container.locationPort.requestAlways();
    if (!mounted) return;
    if (permission == LocationPermissionState.deniedPermanently) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Location is permanently denied. Enable it from system settings.'),
      ));
      return;
    }

    final report = await widget.container.hotspotSync.execute(const NoParams());
    final registered = report.getOrNull()?.regionsRegistered ?? 0;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(registered > 0
          ? '$registered memory hotspot(s) are now being watched.'
          : permission == LocationPermissionState.always
              ? 'Place alerts armed. Save a memory with a place to create hotspots.'
              : 'Background location not granted yet - place alerts stay off.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMENTO'),
        actions: [
          IconButton(
            tooltip: 'Memories near me',
            icon: const Icon(Icons.near_me_outlined),
            onPressed: () => _bloc.add(const NearbyRequested()),
          ),
          IconButton(
            tooltip: 'People & birthdays',
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ContactsPage(container: widget.container),
            )),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'on_this_day') _refreshOnThisDay();
              if (value == 'place_alerts') _openPlaceAlertsOptIn();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'on_this_day', child: Text('On this day')),
              PopupMenuItem(value: 'place_alerts', child: Text('Place alerts...')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'capture',
        onPressed: _openCapture,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Capture'),
      ),
      body: BlocBuilder<MemoriesBloc, MemoriesState>(
        bloc: _bloc,
        builder: (context, state) {
          return switch (state) {
            MemoriesInitial() ||
            MemoriesLoadInProgress() =>
              const Center(child: CircularProgressIndicator()),
            MemoriesFailureState(:final failure) => _buildFailure(failure),
            MemoriesReady(:final memories, :final viewLabel) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(viewLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                  Expanded(
                    child: memories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Nothing here yet.'),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _openCapture,
                                  child:
                                      const Text('Capture your first memory'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: memories.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final memory = memories[index];
                              final local = memory.moment.utc.toLocal();
                              final subtitle = StringBuffer(
                                  '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}');
                              if (memory.taggedContactIds.isNotEmpty) {
                                subtitle.write(
                                    ' - with ${memory.taggedContactIds.length} people');
                              }
                              if (memory.photos.isNotEmpty) {
                                subtitle.write(
                                    ' - ${memory.photos.length} photo(s)');
                              }
                              return ListTile(
                                leading: memory.isGeoAnchored
                                    ? const Icon(Icons.place_outlined)
                                    : const Icon(Icons.photo_album_outlined),
                                title: Text(memory.title),
                                subtitle: Text(subtitle.toString()),
                                onTap: () =>
                                    Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => MemoryDetailPage(
                                    container: widget.container,
                                    memory: memory,
                                  ),
                                )),
                              );
                            },
                          ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }

  Widget _buildFailure(Failure failure) {
    final needsPermission = failure is PermissionFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsPermission
                  ? Icons.location_off_outlined
                  : Icons.error_outline,
              size: 42,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(failure.message, textAlign: TextAlign.center),
            if (needsPermission) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _bloc.add(const NearbyRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry after granting access'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _openPlaceAlertsOptIn,
                child: const Text('Why do you need this?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
