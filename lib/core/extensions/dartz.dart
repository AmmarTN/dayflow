import 'package:dartz/dartz.dart';

extension EitherX<L, R> on Either<L, R> {
  R asRight() => (this as Right).value;
  L asLeft() => (this as Left).value;
}

extension OptionX<T> on Option<T> {
  T asSome() => fold(() => throw Exception('None!'), (value) => value);
}
