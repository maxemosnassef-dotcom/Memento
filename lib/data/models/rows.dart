class MemoryRow {
  final int seq;
  final String id;
  final String title;
  final String? journal;
  final int momentUtcMs;
  final double? latitude;
  final double? longitude;
  final String? geohash;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final List<PhotoRow> photos;
  final List<String> contactIds;

  const MemoryRow({
    required this.seq,
    required this.id,
    required this.title,
    required this.journal,
    required this.momentUtcMs,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.photos = const [],
    this.contactIds = const [],
  });

  bool get isGeoAnchored => latitude != null && longitude != null;

  Map<String, Object?> toColumns() => {
        'id': id,
        'title': title,
        'journal': journal,
        'moment_utc_ms': momentUtcMs,
        'latitude': latitude,
        'longitude': longitude,
        'geohash': geohash,
        'created_at_utc_ms': createdAtUtcMs,
        'updated_at_utc_ms': updatedAtUtcMs,
      };

  static MemoryRow fromMap(Map<String, Object?> map) => MemoryRow(
        seq: map['seq']! as int,
        id: map['id']! as String,
        title: map['title']! as String,
        journal: map['journal'] as String?,
        momentUtcMs: map['moment_utc_ms']! as int,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        geohash: map['geohash'] as String?,
        createdAtUtcMs: map['created_at_utc_ms']! as int,
        updatedAtUtcMs: map['updated_at_utc_ms']! as int,
      );

  MemoryRow copyWith({
    List<PhotoRow>? photos,
    List<String>? contactIds,
  }) =>
      MemoryRow(
        seq: seq,
        id: id,
        title: title,
        journal: journal,
        momentUtcMs: momentUtcMs,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        createdAtUtcMs: createdAtUtcMs,
        updatedAtUtcMs: updatedAtUtcMs,
        photos: photos ?? this.photos,
        contactIds: contactIds ?? this.contactIds,
      );
}

class PhotoRow {
  final String id;
  final String memoryId;
  final String kind;
  final String? sandboxPath;
  final String? remoteUrl;
  final String sha256;

  const PhotoRow({
    required this.id,
    required this.memoryId,
    required this.kind,
    required this.sandboxPath,
    required this.remoteUrl,
    required this.sha256,
  });

  Map<String, Object?> toColumns() => {
        'id': id,
        'memory_id': memoryId,
        'kind': kind,
        'sandbox_path': sandboxPath,
        'remote_url': remoteUrl,
        'sha256': sha256,
      };

  static PhotoRow fromMap(Map<String, Object?> map) => PhotoRow(
        id: map['id']! as String,
        memoryId: map['memory_id']! as String,
        kind: map['kind']! as String,
        sandboxPath: map['sandbox_path'] as String?,
        remoteUrl: map['remote_url'] as String?,
        sha256: map['sha256']! as String,
      );
}

class ContactRow {
  final String id;
  final String displayName;
  final int? birthdayMonth;
  final int? birthdayDay;

  const ContactRow({
    required this.id,
    required this.displayName,
    required this.birthdayMonth,
    required this.birthdayDay,
  });

  Map<String, Object?> toColumns() => {
        'id': id,
        'display_name': displayName,
        'birthday_month': birthdayMonth,
        'birthday_day': birthdayDay,
      };

  static ContactRow fromMap(Map<String, Object?> map) => ContactRow(
        id: map['id']! as String,
        displayName: map['display_name']! as String,
        birthdayMonth: map['birthday_month'] as int?,
        birthdayDay: map['birthday_day'] as int?,
      );
}
