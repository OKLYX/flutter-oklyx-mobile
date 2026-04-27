import 'package:fpdart/fpdart.dart';

extension EitherExtension<L, R> on Either<L, R> {
  Either<L, R> onLeft(Function(L) callback) => fold(
        (left) {
          callback(left);
          return this;
        },
        (right) => this,
      );

  Either<L, R> onRight(Function(R) callback) => fold(
        (left) => this,
        (right) {
          callback(right);
          return this;
        },
      );

  R? getOrNull() => fold((_) => null, (r) => r);

  R getOrElse(Function(L) throwError) => fold(
        (left) => throw throwError(left),
        (right) => right,
      );
}
