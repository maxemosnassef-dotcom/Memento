import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/use_case.dart';
import '../../../domain/entities/contact.dart';
import '../../../domain/usecases/create_memory.dart';
import '../../../domain/usecases/load_contacts.dart';
import '../../../domain/usecases/resolve_current_anchor.dart';
import '../../../domain/value_objects/geo_anchor.dart';

sealed class CaptureEvent extends Equatable {
  const CaptureEvent();

  @override
  List<Object?> get props => [];
}

final class ContactsLoaded extends CaptureEvent {
  const ContactsLoaded();
}

final class PhotosAdded extends CaptureEvent {
  final List<Uint8List> bytes;

  const PhotosAdded(this.bytes);

  @override
  List<Object?> get props => [bytes];
}

final class PhotoRemoved extends CaptureEvent {
  final int index;

  const PhotoRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

final class CurrentLocationAttachRequested extends CaptureEvent {
  const CurrentLocationAttachRequested();
}

final class LocationPinDetached extends CaptureEvent {
  const LocationPinDetached();
}

final class ContactToggled extends CaptureEvent {
  final String contactId;

  const ContactToggled(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

final class MemorySubmitted extends CaptureEvent {
  final String title;
  final String? journalText;
  final DateTime whenLocal;

  const MemorySubmitted({
    required this.title,
    required this.whenLocal,
    this.journalText,
  });

  @override
  List<Object?> get props => [title, journalText, whenLocal];
}

class CaptureFormState extends Equatable {
  final List<Contact> contacts;
  final List<Uint8List> photos;
  final GeoAnchor? attachedAnchor;
  final bool resolvingLocation;
  final Set<String> selectedContactIds;
  final bool submitting;
  final String? errorMessage;
  final bool submissionSucceeded;

  const CaptureFormState({
    this.contacts = const [],
    this.photos = const [],
    this.attachedAnchor,
    this.resolvingLocation = false,
    this.selectedContactIds = const {},
    this.submitting = false,
    this.errorMessage,
    this.submissionSucceeded = false,
  });

  CaptureFormState copyWith({
    List<Contact>? contacts,
    List<Uint8List>? photos,
    GeoAnchor? Function()? attachedAnchor,
    bool? resolvingLocation,
    Set<String>? selectedContactIds,
    bool? submitting,
    String? Function()? errorMessage,
    bool? submissionSucceeded,
  }) {
    return CaptureFormState(
      contacts: contacts ?? this.contacts,
      photos: photos ?? this.photos,
      attachedAnchor:
          attachedAnchor != null ? attachedAnchor() : this.attachedAnchor,
      resolvingLocation: resolvingLocation ?? this.resolvingLocation,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      submissionSucceeded: submissionSucceeded ?? this.submissionSucceeded,
    );
  }

  @override
  List<Object?> get props => [
        contacts,
        photos,
        attachedAnchor,
        resolvingLocation,
        selectedContactIds,
        submitting,
        errorMessage,
        submissionSucceeded,
      ];
}

class CaptureBloc extends Bloc<CaptureEvent, CaptureFormState> {
  final CreateMemory _createMemory;
  final LoadContacts _loadContacts;
  final ResolveCurrentAnchor _resolveCurrentAnchor;

  CaptureBloc({
    required CreateMemory createMemory,
    required LoadContacts loadContacts,
    required ResolveCurrentAnchor resolveCurrentAnchor,
  })  : _createMemory = createMemory,
        _loadContacts = loadContacts,
        _resolveCurrentAnchor = resolveCurrentAnchor,
        super(const CaptureFormState()) {
    on<ContactsLoaded>(_handleContactsLoaded);
    on<PhotosAdded>(_handlePhotosAdded);
    on<PhotoRemoved>(_handlePhotoRemoved);
    on<CurrentLocationAttachRequested>(_handleLocationAttach);
    on<LocationPinDetached>(_handlePinDetached);
    on<ContactToggled>(_handleContactToggled);
    on<MemorySubmitted>(_handleSubmitted);
  }

  Future<void> _handleContactsLoaded(
    ContactsLoaded event,
    Emitter<CaptureFormState> emit,
  ) async {
    final result = await _loadContacts.execute(const NoParams());
    result.fold(
      onError: (_) => emit(state),
      onSuccess: (contacts) => emit(state.copyWith(contacts: contacts)),
    );
  }

  void _handlePhotosAdded(
    PhotosAdded event,
    Emitter<CaptureFormState> emit,
  ) {
    emit(state.copyWith(
      photos: [...state.photos, ...event.bytes],
      errorMessage: () => null,
    ));
  }

  void _handlePhotoRemoved(
    PhotoRemoved event,
    Emitter<CaptureFormState> emit,
  ) {
    if (event.index < 0 || event.index >= state.photos.length) return;
    final next = [...state.photos]..removeAt(event.index);
    emit(state.copyWith(photos: next));
  }

  Future<void> _handleLocationAttach(
    CurrentLocationAttachRequested event,
    Emitter<CaptureFormState> emit,
  ) async {
    emit(state.copyWith(resolvingLocation: true));
    final result = await _resolveCurrentAnchor.execute(const NoParams());
    final anchor = result.getOrNull();
    emit(state.copyWith(
      resolvingLocation: false,
      attachedAnchor: () => anchor,
      errorMessage: anchor == null
          ? () => 'Could not determine your location - check permission'
          : null,
    ));
  }

  void _handlePinDetached(
    LocationPinDetached event,
    Emitter<CaptureFormState> emit,
  ) {
    emit(state.copyWith(attachedAnchor: () => null));
  }

  void _handleContactToggled(
    ContactToggled event,
    Emitter<CaptureFormState> emit,
  ) {
    final next = <String>{...state.selectedContactIds};
    if (!next.remove(event.contactId)) {
      next.add(event.contactId);
    }
    emit(state.copyWith(selectedContactIds: next));
  }

  Future<void> _handleSubmitted(
    MemorySubmitted event,
    Emitter<CaptureFormState> emit,
  ) async {
    final draft = state;
    emit(draft.copyWith(submitting: true, errorMessage: () => null));
    final result = await _createMemory.execute(MemoryDraft(
      title: event.title,
      whenLocal: event.whenLocal,
      journalText: event.journalText,
      anchor: draft.attachedAnchor,
      rawPhotos: draft.photos,
      taggedContactIds: draft.selectedContactIds,
    ));

    result.fold(
      onError: (failure) => emit(state.copyWith(
        submitting: false,
        errorMessage: () => failure.message,
      )),
      onSuccess: (_) => emit(state.copyWith(
        submitting: false,
        submissionSucceeded: true,
      )),
    );
  }
}
