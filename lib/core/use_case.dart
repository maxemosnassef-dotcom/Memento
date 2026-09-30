import 'result.dart';

abstract class UseCase<Output, Input> {
  const UseCase();

  Future<Result<Output>> execute(Input input);
}

class NoParams {
  const NoParams();
}
