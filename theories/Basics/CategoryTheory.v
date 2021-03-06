(** * Category theory *)

(** While [Basics.CategoryOps] gives the _signatures_ of categorical
    operations, this module describes their properties. *)

(* begin hide *)
From ITree.Basics Require Import
     CategoryOps.

Import Carrier.
Import CatNotations.
Local Open Scope cat.
(* end hide *)

(** ** Categories *)

Section CatLaws.

Context {obj : Type} (C : Hom obj).
Context {Eq2C : Eq2 C} {IdC : Id_ C} {CatC : Cat C}.

(** [cat] must have units and be associative. *)

Class CatIdL : Prop :=
  cat_id_l : forall a b (f : C a b), id_ _ >>> f ⩯ f.

Class CatIdR : Prop :=
  cat_id_r : forall a b (f : C a b), f >>> id_ _ ⩯ f.

Class CatAssoc : Prop :=
  cat_assoc : forall a b c d (f : C a b) (g : C b c) (h : C c d),
      (f >>> g) >>> h ⩯ f >>> (g >>> h).

Class Category : Prop := {
  category_cat_id_l :> CatIdL;
  category_cat_id_r :> CatIdR;
  category_cat_assoc :> CatAssoc;
}.

(** *** Initial object *)

(** There is only one morphism between the initial object and
    any other object. *)
Class InitialObject (i : obj) {Initial_i : Initial C i} : Prop :=
  initial_object : forall a (f : C i a), f ⩯ empty.

End CatLaws.

Arguments cat_assoc {obj} C {Eq2C CatC CatAssoc} [a b c d].
Arguments initial_object : clear implicits.
Arguments initial_object {obj} C {Eq2C} i {Initial_i InitialObject}.

(** ** Mono-, Epi-, Iso- morphisms *)

(** _Semi-isomorphisms_ are morphisms which compose to the identity.
    If [f >>> f' = id_ _], we also say that [f] is a _section_, or
    _split monomorphism_ and [f'] is a _retraction_, or
    _split epimorphism_.
    _Isomorphisms_ are those that compose _both ways_ to the identity.
 *)

(** The most common example is in the category of functions: sections
    are injective functions, retractions are surjective functions.
    A minor detail to mention regarding that example is that
    traditional function composition is denoted backwards:
    [(f >>> f') x = (f' ∘ f) x = f' (f x)].
 *)

Section SemiIso.

Context {obj : Type} (C : Hom obj).
Context {Eq2C : Eq2 C} {IdC : Id_ C} {CatC : Cat C}.

(** An instance [SemiIso C f f'] means that [f] is a section of
    [f'] in the category [C]. *)
Class SemiIso {a b : obj} (f : C a b) (f' : C b a) : Type :=
  semi_iso : f >>> f' ⩯ id_ _.

(** The class of isomorphisms *)
Class Iso {a b : obj} (f : C a b) (f' : C b a) : Type := {
  iso_mono :> SemiIso f f';
  iso_epi :> SemiIso f' f;
}.

End SemiIso.

Arguments semi_iso : clear implicits.
Arguments semi_iso {obj C Eq2C IdC CatC a b} f f'.

(** ** Bifunctors *)

Section BifunctorLaws.

Context {obj : Type} (C : Hom obj).
Context {Eq2_C : Eq2 C} {Id_C : Id_ C} {Cat_C : Cat C}.
Context (bif : binop obj).
Context {Bimap_bif : Bimap C bif}.

(** Vertical composition ([bimap]) must be compatible with horizontal
    composition ([cat]). *)

Class BimapId : Prop :=
  bimap_id : forall a b,
    bimap (id_ a) (id_ b) ⩯ id_ (bif a b).

Class BimapCat : Prop :=
  bimap_cat : forall a1 a2 b1 b2 c1 c2
                     (f1 : C a1 b1) (g1 : C b1 c1)
                     (f2 : C a2 b2) (g2 : C b2 c2),
    bimap f1 f2 >>> bimap g1 g2 ⩯ bimap (f1 >>> g1) (f2 >>> g2).

Class Bifunctor : Prop := {
  bifunctor_bimap_id :> BimapId;
  bifunctor_bimap_cat :> BimapCat;
}.

End BifunctorLaws.

(** ** Coproducts *)

(** These laws capture the essence of sums. *)

Section CoproductLaws.

Context {obj : Type} (C : Hom obj).
Context {Eq2_C : Eq2 C} {Id_C : Id_ C} {Cat_C : Cat C}.
Context (bif : binop obj).
Context {CoprodCase_C : CoprodCase C bif}
        {CoprodInl_C : CoprodInl C bif}
        {CoprodInr_C : CoprodInr C bif}.

Class CaseInl : Prop :=
  case_inl : forall a b c (f : C a c) (g : C b c),
    inl_ >>> case_ f g ⩯ f.

Class CaseInr : Prop :=
  case_inr : forall a b c (f : C a c) (g : C b c),
    inr_ >>> case_ f g ⩯ g.

(** Uniqueness of coproducts *)
Class CaseUniversal : Prop :=
  case_universal :
    forall a b c (f : C a c) (g : C b c) (fg : C (bif a b) c),
      (inl_ >>> fg ⩯ f) ->
      (inr_ >>> fg ⩯ g) ->
      fg ⩯ case_ f g.

Class Coproduct : Prop := {
  coproduct_case_inl :> CaseInl;
  coproduct_case_inr :> CaseInr;
  coproduct_case_universal :> CaseUniversal;
}.

End CoproductLaws.

(** ** Monoidal categories *)

Section MonoidalLaws.

Context {obj : Type} (C : Hom obj).
Context {Eq2_C : Eq2 C} {Id_C : Id_ C} {Cat_C : Cat C}.
Context (bif : binop obj).

Context {AssocR_bif : AssocR C bif}.
Context {AssocL_bif : AssocL C bif}.

(** *** Associators and unitors are isomorphisms *)

(** [assoc_r] and [assoc_l] are mutual inverses. *)
Notation AssocIso :=
  (forall a b c, Iso C (assoc_r_ a b c) assoc_l) (only parsing).
(* TODO: should that be a notation? *)

(** [assoc_r] is a split monomorphism, i.e., a left-inverse,
    [assoc_l] is its retraction. *)
Corollary assoc_r_mono {AssocIso_C : AssocIso} : forall a b c,
    assoc_r >>> assoc_l ⩯ id_ (bif (bif a b) c).
Proof.
  intros; apply semi_iso, AssocIso_C.
Qed.

(** [assoc_r] is a split epimorphism, i.e., a right-inverse,
    [assoc_l] is its section. *)
Corollary assoc_l_mono {AssocIso_C : AssocIso} : forall a b c,
    assoc_l >>> assoc_r ⩯ id_ (bif a (bif b c)).
Proof.
  intros; apply semi_iso, AssocIso_C.
Qed.

Context (i : obj).
Context {UnitL_bif  : UnitL  C bif i}.
Context {UnitL'_bif : UnitL' C bif i}.
Context {UnitR_bif  : UnitR  C bif i}.
Context {UnitR'_bif : UnitR' C bif i}.

(** [unit_l] and [unit_l'] are mutual inverses. *)
Notation UnitLIso :=
  (forall a, Iso C (unit_l_ i a) unit_l') (only parsing).

(** [unit_l] is a split monomorphism, i.e., a left-inverse,
    [unit_l'] is its retraction. *)
Corollary unit_l_mono {UnitLIso_C : UnitLIso} : forall a,
    unit_l >>> unit_l' ⩯ id_ (bif i a).
Proof.
  intros; apply semi_iso, UnitLIso_C.
Qed.

(** [unit_l] is a split epimorphism, [unit_l'] is its section. *)
Corollary unit_l_epi {UnitLIso_C : UnitLIso} : forall a,
    unit_l' >>> unit_l ⩯ id_ a.
Proof.
  intros; apply semi_iso, UnitLIso_C.
Qed.

(** [unit_r] and [unit_r'] are mutual inverses. *)
Notation UnitRIso :=
  (forall a, Iso C (unit_r_ i a) unit_r') (only parsing).

Corollary unit_r_mono {UnitRIso_C : UnitRIso} : forall a,
    unit_r >>> unit_r' ⩯ id_ (bif a i).
Proof.
  intros; apply semi_iso, UnitRIso_C.
Qed.

Corollary unit_r_epi {UnitRIso_C : UnitRIso} : forall a,
    unit_r' >>> unit_r ⩯ id_ a.
Proof.
  intros; apply semi_iso, UnitRIso_C.
Qed.

Context {Bimap_bif : Bimap C bif}.

(** *** Coherence laws *)

(** The Triangle Diagram *)
Class AssocRUnit : Prop :=
  assoc_r_unit : forall a b,
    assoc_r >>> bimap (id_ a) unit_l ⩯ bimap unit_r (id_ b).

(** The Pentagon Diagram *)
Class AssocRAssocR : Prop :=
  assoc_r_assoc_r : forall a b c d,
          bimap (@assoc_r _ _ _ _ a b c) (id_ d)
      >>> assoc_r
      >>> bimap (id_ _) assoc_r
    ⩯ assoc_r >>> assoc_r.

Class Monoidal : Prop := {
  monoidal_category :> Category C;
  monoidal_bifunctor :> Bifunctor C bif;
  monoidal_assoc_iso :> AssocIso;
  monoidal_unit_l_iso :> UnitLIso;
  monoidal_unit_r_iso :> UnitRIso;
  monoidal_assoc_r_unit :> AssocRUnit;
  monoidal_assoc_r_assoc_r :> AssocRAssocR;
}.

(** The [assoc_l] variants can be derived by symmetry,
    because [assoc_l] is the inverse of [assoc_r]. *)

Class AssocLUnit : Prop :=
  assoc_l_unit : forall a b,
    assoc_l >>> bimap unit_r (id_ b) ⩯ bimap (id_ a) unit_l.

Class AssocLAssocL : Prop :=
  assoc_l_assoc_l : forall a b c d,
          bimap (id_ a) (@assoc_l _ _ _ _ b c d)
      >>> assoc_l
      >>> bimap assoc_l (id_ _)
    ⩯ assoc_l >>> assoc_l.

End MonoidalLaws.

(** ** Symmetric monoidal categories *)

Section SymmetricLaws.

Context {obj : Type} (C : Hom obj).
Context {Eq2_C : Eq2 C} {Id_C : Id_ C} {Cat_C : Cat C}.
Context (bif : binop obj).
Context {Swap_bif : Swap C bif}.

(** [swap] is an involution *)
Notation SwapInvolutive :=
  (forall a b, SemiIso C (swap_ a b) swap) (only parsing).

Corollary swap_involutive {SwapInvolutive_C : SwapInvolutive}
  : forall a b, swap >>> swap ⩯ id_ (bif a b).
Proof.
  intros; apply semi_iso, SwapInvolutive_C.
Qed.

Context (i : obj).
Context {UnitL_i  : UnitL  C bif i}.
Context {UnitL'_i : UnitL' C bif i}.
Context {UnitR_i  : UnitR  C bif i}.
Context {UnitR'_i : UnitR' C bif i}.

(** Coherence between [swap] and unitors. *)
Class SwapUnitL : Prop :=
  swap_unit_l : forall a, swap >>> unit_l ⩯ unit_r_ _ a.

Context {Bimap_bif : Bimap C bif}.
Context {AssocR_bif : AssocR C bif}.
Context {AssocL_bif : AssocL C bif}.

(** Coherence between [swap] and associators. *)
Class SwapAssocR : Prop :=
  swap_assoc_r : forall a b c,
    @assoc_r _ _ _ _ a _ _ >>> swap >>> assoc_r
  ⩯ bimap swap (id_ c) >>> assoc_r >>> bimap (id_ b) swap.

(** Symmetric monoidal category. *)
Class SymMonoidal : Prop := {
  symmetric_monoidal : Monoidal C bif i;
  symmetric_swap_involutive : SwapInvolutive;
  symmetric_swap_unit_l : SwapUnitL;
  symmetric_swap_assoc_r : SwapAssocR;
}.
(* The name [Symmetric] is taken by [Setoid]. *)

Class SwapAssocL : Prop :=
  swap_assoc_l : forall a b c,
    @assoc_l _ _ _ _ _ _ c >>> swap >>> assoc_l
  ⩯ bimap (id_ a) swap >>> assoc_l >>> bimap swap (id_ b).

End SymmetricLaws.
