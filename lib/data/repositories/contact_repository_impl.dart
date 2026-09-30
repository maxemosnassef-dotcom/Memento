import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/mapping.dart';
import '../../core/result.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';
import '../../domain/value_objects/month_day.dart';
import '../datasources/local/contact_local_data_source.dart';
import '../mappers/entity_mappers.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactLocalDataSource _local;

  const ContactRepositoryImpl(this._local);

  @override
  Future<Result<Contact>> save(Contact contact) async => _guard(() async {
        await _local.upsert(ContactMapper.toRow(contact));
        final persisted = await _local.byId(contact.id);
        if (persisted == null) {
          throw StateError('Persisted contact vanished immediately after upsert');
        }
        return ContactMapper.toDomain(persisted);
      });

  @override
  Future<Result<Contact?>> findById(String id) async => _guard(() async {
        final row = await _local.byId(id);
        return row == null ? null : ContactMapper.toDomain(row);
      });

  @override
  Future<Result<List<Contact>>> findAll() async =>
      _guard(() async => ContactMapper.listToDomain(await _local.all()));

  @override
  Future<Result<List<Contact>>> findBirthdaysOn(MonthDay monthDay) async =>
      _guard(() async {
        final rows = await _local.birthdaysOn(
          month: monthDay.month,
          day: monthDay.day,
        );
        return ContactMapper.listToDomain(rows);
      });

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.ok(await operation());
    } on AppException catch (e) {
      return Result.err(e.toFailure());
    } catch (e) {
      return Result.err(DatabaseFailure('$e'));
    }
  }
}
