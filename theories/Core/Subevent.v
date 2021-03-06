(** * Extensible effects *)

(** Notations to handle large sums and classes for extensible effects. *)

(* begin hide *)
From ITree Require Import
     Basics.Basics
     Basics.CategoryOps
     Core.ITreeDefinition
     Indexed.Sum
     Indexed.Function.
(* end hide *)

(** Automatic application of commutativity and associativity for
    sums types constructed with [sum1].

    N.B. This is prone to infinite instance resolution loops.
    Put the following option at the top of your [.v] files to
    bound the instance search depth:

[[
  Typeclasses eauto := 5.
]]

    Higher numbers allow bigger instances but grow the search
    space exponentially.
 *)

Notation Subevent E F := (@ReSum (Type -> Type) IFun E F)
  (only parsing).
Notation "E -< F" := (Subevent E F)
  (at level 90, left associativity) : type_scope.

Definition subevent {E F : Type -> Type} `{E -< F} : E ~> F := resum _.

(** Notations to construct and pattern-match on nested sums. *)
Module Import SumNotations.

Delimit Scope sum_scope with sum.
Bind Scope sum_scope with sum1.

Notation "(| x )" := (inr1 x) : sum_scope.
Notation "( x |)" := (inl1 x) : sum_scope.
Notation "(| x |)" := (inl1 (inr1 x)) : sum_scope.
Notation "(|| x )" := (inr1 (inr1 x)) : sum_scope.
Notation "(|| x |)" := (inr1 (inr1 (inl1 x))) : sum_scope.
Notation "(||| x )" := (inr1 (inr1 (inr1 x))) : sum_scope.
Notation "(||| x |)" := (inr1 (inr1 (inr1 (inl1 x)))) : sum_scope.
Notation "(|||| x )" := (inr1 (inr1 (inr1 (inr1 x)))) : sum_scope.
Notation "(|||| x |)" :=
  (inr1 (inr1 (inr1 (inr1 (inl1 x))))) : sum_scope.
Notation "(||||| x )" :=
  (inr1 (inr1 (inr1 (inr1 (inr1 x))))) : sum_scope.
Notation "(||||| x |)" :=
  (inr1 (inr1 (inr1 (inr1 (inr1 (inl1 x)))))) : sum_scope.
Notation "(|||||| x )" :=
  (inr1 (inr1 (inr1 (inr1 (inr1 (inr1 x)))))) : sum_scope.
Notation "(|||||| x |)" :=
  (inr1 (inr1 (inr1 (inr1 (inr1 (inr1 (inl1 x))))))) : sum_scope.
Notation "(||||||| x )" :=
  (inr1 (inr1 (inr1 (inr1 (inr1 (inr1 (inr1 x))))))) : sum_scope.

End SumNotations.

Local Open Scope sum_scope.

(** A polymorphic version of [Vis]. *)
Notation vis e k := (Vis (subevent _ e) k).

(* Called [send] in Haskell implementations of Freer monads. *)
Definition trigger {E F} `{E -< F} : E ~> itree F :=
  fun T e => ITree.trigger (subevent _ e).

Arguments trigger {E F _ T}.

Lemma trigger_is_vis_ret {E F R} `{E -< F} (e : E R) :
  trigger e = vis e (fun r => Ret r).
Proof. reflexivity. Qed.

(* Embedding events into trees.

   For example:
[[
   embed :
     (forall x y z,       E (f x y z)) ->
     (forall x y z, itree E (f x y z))
]]
 *)
Class Embeddable U V :=
  embed : U -> V.

Instance Embeddable_forall {A : Type} {U : A -> Type} {V : A -> Type}
         `(forall a, Embeddable (U a) (V a)) :
  Embeddable (forall a, U a) (forall a, V a) :=
  fun u a => embed (u a).

Instance Embeddable_itree {E F : Type -> Type} {R : Type}
         `(E -< F) :
  Embeddable (E R) (itree F R) :=
  trigger.
