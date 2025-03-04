//

typedef Predicate<T> = bool Function(T it);

//

sealed class Premise<T> {
  const Premise();

  const factory Premise.truth(T value) = _Truth;
  static const Premise<Never> falsehood = _Falsehood();

  static Premise<T> of<T>(T value, Predicate<T> predicate) =>
      predicate(value) ? Premise.truth(value) : Premise.falsehood;
}

//

final class _Truth<T> implements Premise<T> {
  const _Truth(this.value);
  final T value;
}

final class _Falsehood implements Premise<Never> {
  const _Falsehood();
}

//

typedef Consequence<T, R> = R Function(T it);

//

final class Implication<T, R> {
  const Implication._(
    this._premise,
    this._consequence,
  );

  final Premise<T> _premise;
  final Consequence<T, R> _consequence;
}

//

extension PremisePublicAPI<T> on Premise<T> {
  Implication<T, R> implies<R>(Consequence<T, R> consequence) =>
      Implication._(this, consequence);
}

//

extension ImplicationPublicAPI<T, R> on Implication<T, R> {
  R otherwise(Consequence<void, R> consequence) => switch (_premise) {
        _Truth(value: final value) => _consequence(value),
        _Falsehood() => consequence(null),
      };
}

//
