import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

class LoadContacts extends UseCase<List<Contact>, NoParams> {
  final ContactRepository _contacts;

  const LoadContacts(this._contacts);

  @override
  Future<Result<List<Contact>>> execute(NoParams input) => _contacts.findAll();
}
