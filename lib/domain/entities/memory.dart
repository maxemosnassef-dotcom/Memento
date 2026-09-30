import '../value_objects/geo_anchor.dart';
import '../value_objects/journal_entry.dart';
import '../value_objects/memory_moment.dart';
import '../value_objects/month_day.dart';
import '../value_objects/photo_reference.dart';

class Memory {
  final String id;
  final String title;
  final MemoryMoment moment;
  final JournalEntry? journal;
  final GeoAnchor? anchor;
  final List<PhotoReference> photos;
  final Set<String> taggedContactIds;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  const Memory({
    required this.id,
    required this.title,
    required this.moment,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.journal,
    this.anchor,
    this.photos = const [],
    this.taggedContactIds = const {},
  })  : assert(title.length > 0, 'title must not be empty');

  factory Memory.create({
    required String id,
    required String title,
    required DateTime whenLocal,
    JournalEntry? journal,
    GeoAnchor? anchor,
    List<PhotoReference> photos = const [],
    Set<String> taggedContactIds = const {},
  }) {
    final now = DateTime.now().toUtc();
    return Memory(
      id: id,
      title: title.trim(),
      moment: MemoryMoment.at(whenLocal),
      journal: journal,
      anchor: anchor,
      photos: List.unmodifiable(photos),
      taggedContactIds: Set.unmodifiable(taggedContactIds),
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  bool get isGeoAnchored => anchor != null;

  bool wasTakenOn(MonthDay monthDay) => moment.fallsOnCalendarDay(
        month: monthDay.month,
        day: monthDay.day,
      );

  Memory copyWith({
    String? title,
    MemoryMoment? moment,
    JournalEntry? journal,
    GeoAnchor? anchor,
    List<PhotoReference>? photos,
    Set<String>? taggedContactIds,
  }) {
    return Memory(
      id: id,
      title: title ?? this.title,
      moment: moment ?? this.moment,
      journal: journal ?? this.journal,
      anchor: anchor ?? this.anchor,
      photos: photos ?? this.photos,
      taggedContactIds: taggedContactIds ?? this.taggedContactIds,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Memory && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Memory($id, "$title", ${moment.utc})';
}
