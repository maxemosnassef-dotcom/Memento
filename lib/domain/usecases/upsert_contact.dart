import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';
import '../value_objects/month_day.dart';

class ContactInput {
  final String displayName;
  final int? birthdayMonth;
  final int? birthdayDay;

  const ContactInput({
    required this.displayName,
    this.birthdayMonth,
    this.birthdayDay,
  });
}

class UpsertContact extends UseCase<Contact, ContactInput> {
  final ContactRepository _contacts;
  final String Function() _idFactory;

  const UpsertContact(this._contacts, {required String Function() idFactory})
      : _idFactory = idFactory;

  @override
  Future<Result<Contact>> execute(ContactInput input) {
    return _contacts.save(Contact(
      id: _idFactory(),
      displayName: input.displayName.trim(),
      birthday: input.birthdayMonth == null || input.birthdayDay == null
          ? null
          : MonthDay.of(month: input.birthdayMonth!, day: input.birthdayDay!),
    ));
  }
}
