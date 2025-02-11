//

sealed class Nat {
  const Nat();
}

final class Zero implements Nat {
  const Zero();
}

final class Succ<Prev extends Nat> implements Nat {
  const Succ(this.prev);
  final Prev prev;
}

//

typedef Eq<A extends Nat, B extends Nat> = (LTE<A, B>, LTE<B, A>);

typedef GTE<A extends Nat, B extends Nat> = LTE<B, A>;

typedef LT<A extends Nat, B extends Nat> = LTE<Succ<A>, B>;

typedef GT<A extends Nat, B extends Nat> = LT<B, A>;

//

sealed class LTE<X extends Nat, Y extends Nat> {
  const LTE();
}

final class LTEZero<K extends Nat> implements LTE<Zero, K> {
  const LTEZero();
}

final class LTESucc<A extends Nat, B extends Nat>
    implements LTE<Succ<A>, Succ<B>> {
  const LTESucc(this.prev);
  final LTE<A, B> prev;
}

//
