import '../../core/error/exceptions.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/memory.dart';
import '../../domain/value_objects/geo_anchor.dart';
import '../../domain/value_objects/journal_entry.dart';
import '../../domain/value_objects/memory_moment.dart';
import '../../domain/value_objects/month_day.dart';
import '../../domain/value_objects/photo_reference.dart';
import '../models/rows.dart';

class MemoryMapper {
  const MemoryMapper._();

  static const _encryptedLocalKind = 'encrypted_local';
  static const _cloudKind = 'cloud';

  static Memory toDomain(MemoryRow row) {
    try {
      return Memory(
        id: row.id,
        title: row.title,
        moment: MemoryMoment.fromEpochMs(row.momentUtcMs),
        journal:
            row.journal == null ? null : JournalEntry.of(row.journal!),
        anchor: row.isGeoAnchored
            ? GeoAnchor.of(latitude: row.latitude!, longitude: row.longitude!)
            : null,
        photos: List.unmodifiable(row.photos.map(_photoToDomain)),
        taggedContactIds: Set.unmodifiable(row.contactIds),
        createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
          row.createdAtUtcMs,
          isUtc: true,
        ),
        updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
          row.updatedAtUtcMs,
          isUtc: true,
        ),
      );
    } on ArgumentError catch (e) {
      throw MappingException('Memory ${row.id}: ${e.message ?? e.name}');
    }
  }

  static MemoryRow toRow(Memory memory, {required int seq}) {
    final photos = memory.photos
        .map((photo) => _photoToRow(photo, memory.id))
        .toList(growable: false);
    return MemoryRow(
      seq: seq,
      id: memory.id,
      title: memory.title,
      journal: memory.journal?.text,
      momentUtcMs: memory.moment.epochMs,
      latitude: memory.anchor?.latitude,
      longitude: memory.anchor?.longitude,
      geohash: memory.anchor?.geohash,
      createdAtUtcMs: memory.createdAtUtc.millisecondsSinceEpoch,
      updatedAtUtcMs: memory.updatedAtUtc.millisecondsSinceEpoch,
      photos: photos,
      contactIds: memory.taggedContactIds.toList(growable: false),
    );
  }

  static PhotoReference _photoToDomain(PhotoRow row) {
    switch (row.kind) {
      case _encryptedLocalKind:
        return PhotoReference.encryptedLocal(
          id: row.id,
          sandboxRelativePath: row.sandboxPath!,
          checksumSha256: row.sha256,
        );
      case _cloudKind:
        return PhotoReference.cloud(
          id: row.id,
          remoteUrl: Uri.parse(row.remoteUrl!),
          checksumSha256: row.sha256,
        );
      default:
        throw MappingException('Unknown photo kind "${row.kind}"');
    }
  }

  static PhotoRow _photoToRow(PhotoReference photo, String memoryId) {
    final isLocal = photo.kind == PhotoStorageKind.encryptedLocal;
    return PhotoRow(
      id: photo.id,
      memoryId: memoryId,
      kind: isLocal ? _encryptedLocalKind : _cloudKind,
      sandboxPath: photo.sandboxRelativePath,
      remoteUrl: photo.remoteUrl?.toString(),
      sha256: photo.checksumSha256,
    );
  }

  static List<Memory> listToDomain(List<MemoryRow> rows) =>
      rows.map(toDomain).toList(growable: false);
}

class ContactMapper {
  const ContactMapper._();

  static Contact toDomain(ContactRow row) {
    try {
      return Contact(
        id: row.id,
        displayName: row.displayName,
        birthday: row.birthdayMonth == null || row.birthdayDay == null
            ? null
            : MonthDay.of(month: row.birthdayMonth!, day: row.birthdayDay!),
      );
    } on ArgumentError catch (e) {
      throw MappingException('Contact ${row.id}: ${e.message ?? e.name}');
    }
  }

  static ContactRow toRow(Contact contact) => ContactRow(
        id: contact.id,
        displayName: contact.displayName,
        birthdayMonth: contact.birthday?.month,
        birthdayDay: contact.birthday?.day,
      );

  static List<Contact> listToDomain(List<ContactRow> rows) =>
      rows.map(toDomain).toList(growable: false);
}
