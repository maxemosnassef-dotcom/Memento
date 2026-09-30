import '../../core/result.dart';
import '../../core/use_case.dart';
import '../repositories/location_port.dart';
import '../value_objects/geo_anchor.dart';

class ResolveCurrentAnchor extends UseCase<GeoAnchor?, NoParams> {
  final LocationPort _location;

  const ResolveCurrentAnchor(this._location);

  @override
  Future<Result<GeoAnchor?>> execute(NoParams input) async {
    final anchor = await _location.currentPosition(allowStale: false);
    return Result.ok(anchor);
  }
}
