import '../value_objects/month_day.dart';

class Contact {
  final String id;
  final String displayName;
  final MonthDay? birthday;

  const Contact({
    required this.id,
    required this.displayName,
    this.birthday,
  }) : assert(displayName.length > 0, 'displayName must not be empty');

  bool get hasBirthday => birthday != null;

  Contact copyWith({String? displayName, MonthDay? birthday}) => Contact(
        id: id,
        displayName: displayName ?? this.displayName,
        birthday: birthday ?? this.birthday,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Contact && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Contact($id, $displayName, $birthday)';
}
