(** * Theorems about State effects *)

(* begin hide *)
From Coq Require Import
     Program
     Setoid
     Morphisms
     RelationClasses.

From Paco Require Import paco.

From ITree Require Import
     Basics.Basics
     Core.ITreeDefinition
     Core.KTree
     Eq.UpToTausEquivalence
     Indexed.Sum
     Interp.Interp
     Interp.InterpFacts
     Interp.RecursionFacts
     Events.State.

Import ITree.Basics.Basics.Monads.
Import ITreeNotations.

Open Scope itree_scope.

Import Monads.
(* end hide *)

Definition _interp_state {E F S R}
           (f : E ~> stateT S (itree F)) (ot : itreeF E R _)
  : stateT S (itree F) R := fun s =>
  match ot with
  | RetF r => Ret (s, r)
  | TauF t => Tau (interp_state f t s)
  | VisF e k => Tau (f _ e s >>= (fun sx => interp_state f (k (snd sx)) (fst sx)))
  end.

Lemma unfold_interp_state {E F S R} (h : E ~> Monads.stateT S (itree F))
      (t : itree E R) s :
    eq_itree eq
      (interp_state h t s)
      (_interp_state h (observe t) s).
Proof.
  unfold interp_state, interp, aloop, ALoop_stateT0, aloop, ALoop_itree.
  rewrite unfold_aloop'.
  destruct observe; cbn.
  - reflexivity.
  - rewrite bind_ret_.
    reflexivity.
  - rewrite bind_map. eapply eq_itree_Tau.
    eapply eq_itree_bind; reflexivity.
Qed.

Instance eq_itree_interp_state {E F S R} (h : E ~> Monads.stateT S (itree F)) :
  Proper (eq_itree eq ==> eq ==> eq_itree eq)
         (@interp_state _ _ _ _ _ _ h R).
Proof.
  revert_until R.
  ucofix CIH. intros h x y H0 x2 y0 H1.
  rewrite !unfold_interp_state.
  unfold _interp_state.
  uunfold H0; repeat red in H0.
  genobs x ox; destruct ox; simpobs; dependent destruction H0; simpobs; subst.
  - constructor. eauto.
  - constructor. eauto with paco.
  - constructor. uclo eq_itree_clo_bind. econstructor.
    + reflexivity.
    + intros [] _ []. auto with paco.
Qed.

Lemma interp_state_ret {E F : Type -> Type} {R S : Type}
      (f : forall T, E T -> S -> itree F (S * T)%type)
      (s : S) (r : R) :
  (interp_state f (Ret r) s) ≅ (Ret (s, r)).
Proof.
  rewrite itree_eta. reflexivity.
Qed.

Lemma interp_state_vis {E F : Type -> Type} {S T U : Type}
      (e : E T) (k : T -> itree E U) (h : E ~> Monads.stateT S (itree F)) (s : S)
  : interp_state h (Vis e k) s
  ≅ Tau (h T e s >>= fun sx => interp_state h (k (snd sx)) (fst sx)).
Proof.
  rewrite unfold_interp_state; reflexivity.
Qed.

Lemma interp_state_tau {E F : Type -> Type} S {T : Type}
      (t : itree E T) (h : E ~> Monads.stateT S (itree F)) (s : S)
  : interp_state h (Tau t) s ≅ Tau (interp_state h t s).
Proof.
  rewrite unfold_interp_state; reflexivity.
Qed.

Lemma interp_state_trigger {E F : Type -> Type} {R S : Type}
      (e : E R) (f : E ~> Monads.stateT S (itree F)) (s : S)
  : (interp_state f (ITree.trigger e) s) ≅ Tau (f _ e s).
Proof.
  unfold ITree.trigger. rewrite interp_state_vis.
  apply eq_itree_Tau.
  rewrite <- (bind_ret2 (f R e s)) at 2.
  eapply eq_itree_bind.
  - intros []; rewrite interp_state_ret; reflexivity.
  - reflexivity.
Qed.

Lemma interp_state_bind {E F : Type -> Type} {A B S : Type}
      (f : forall T, E T -> S -> itree F (S * T)%type)
      (t : itree E A) (k : A -> itree E B)
      (s : S) :
  (interp_state f (t >>= k) s)
    ≅
  (interp_state f t s >>= fun st => interp_state f (k (snd st)) (fst st)).
Proof.
  revert A t k s.
  ucofix CIH.
  intros A t k s.
  rewrite unfold_bind. (* TODO: slow *)
  rewrite (unfold_interp_state f t).
  destruct (observe t).
  - cbn. rewrite !bind_ret. simpl.
    apply reflexivity.
  - cbn. rewrite !bind_tau, interp_state_tau.
    econstructor. ubase. apply CIH.
  - cbn. rewrite interp_state_vis, bind_tau, bind_bind.
    constructor.
    uclo eq_itree_clo_bind. econstructor.
    + reflexivity.
    + intros u2 ? []. specialize (CIH _ (k0 (snd u2)) k (fst u2)).
      auto with paco.
Qed.

Instance eutt_interp_state {E F: Type -> Type} {S : Type}
         (h : E ~> Monads.stateT S (itree F)) R :
  Proper (eutt eq ==> eq ==> eutt eq) (@interp_state E (itree F) S _ _ _ h R).
Proof.
  repeat intro. subst. revert_until R.
  ucofix CIH. red. ucofix CIH'. intros.

  rewrite !unfold_interp_state. do 2 uunfold H0.
  induction H0; intros; subst; simpl.
  - constructor. eauto.
  - constructor.
    uclo eutt0_clo_bind; econstructor; [reflexivity|].
    intros; subst.
    ubase. eapply CIH'. edestruct EUTTK; eauto with paco.
  - econstructor. eauto 9 with paco.
  - constructor. eutt0_fold.
    rewrite unfold_interp_state; auto.
  - constructor. eutt0_fold.
    rewrite unfold_interp_state; auto.
Qed.

Lemma eutt_interp_state_aloop {E F S I A} (RS : S -> S -> Prop)
      (h : E ~> Monads.stateT S (itree F))
      (t1 t2 : I -> itree E I + A) :
  (forall i s1 s2, RS s1 s2 ->
     sum_rel (fun u1 u2 =>
                eutt (fun a b => RS (fst a) (fst b) /\ snd a = snd b)
                     (interp_state h u1 s1)
                     (interp_state h u2 s2))
             eq (t1 i) (t2 i)) ->
  (forall i s1 s2, RS s1 s2 ->
     eutt (fun a b => RS (fst a) (fst b) /\ snd a = snd b)
          (interp_state h (ITree.aloop t1 i) s1)
          (interp_state h (ITree.aloop t2 i) s2)).
Proof.
  intro Ht.
  ucofix CIH. red. ucofix CIH'. intros.
  rewrite 2 unfold_aloop'.
  destruct (Ht i s1 s2); cbn; auto.
  - rewrite 2 interp_state_tau, 2 interp_state_bind.
    constructor.
    uclo eutt0_clo_bind; econstructor; eauto.
    intros [s1' i1'] [s2' i2'] [? []]; cbn.
    auto with paco.
  - rewrite 2 interp_state_ret.
    constructor; auto.
Qed.

Lemma eutt_interp_state_loop {E F S A B C} (RS : S -> S -> Prop)
      (h : E ~> Monads.stateT S (itree F))
      (t1 t2 : C + A -> itree E (C + B)) :
  (forall ca s1 s2, RS s1 s2 ->
     eutt (fun a b => RS (fst a) (fst b) /\ snd a = snd b)
          (interp_state h (t1 ca) s1)
          (interp_state h (t2 ca) s2)) ->
  (forall a s1 s2, RS s1 s2 ->
     eutt (fun a b => RS (fst a) (fst b) /\ snd a = snd b)
          (interp_state h (loop t1 a) s1)
          (interp_state h (loop t2 a) s2)).
Proof.
  intros.
  unfold loop.
  rewrite 2 interp_state_bind.
  eapply eutt_bind'; eauto.
  intros x1 x2 [? []].
  eapply eutt_interp_state_aloop; auto.
  intros [] s1' s2' Hs'; constructor; auto.
Qed.
