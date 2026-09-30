import '../../core/result.dart';
import '../entities/contact.dart';
import '../value_objects/month_day.dart';

abstract interface class ContactRepository {
  Future<Result<Contact>> save(Contact contact);

  Future<Result<Contact?>> findById(String id);

  Future<Result<List<Contact>>> findAll();

  Future<Result<List<Contact>>> findBirthdaysOn(MonthDay monthDay);
}
