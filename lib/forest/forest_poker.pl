:- module(forest_poker, [forest_generalise/3,
                         forest_supports/4,
                         forest_applies/0,
                         use_forest/0,
                         use_vanilla/0]).

/** <module> The provenance forest behind Poker's generalise/3.

forest_generalise/3 answers as poker:generalise/3 does: it computes the
sub-hypotheses of each positive example with the forest instead of
enumerating Vanilla's refutations, then passes them through Poker's own
constraint check, sorting, unfolding and renaming of invented predicates.

The forest reads the problem as Vanilla does: the encapsulated metarules,
the background knowledge written to module user, the metarule constraints
of the configuration, and Poker's signature of the target and invented
predicates. Where Vanilla resolves goals against background knowledge and
metarules only (fetch_clauses without hypothesis), the clause limit counts
the steps of a refutation and the forest's graded recurrence applies. Where
Vanilla also resolves goals against hypothesis clauses it has built (Vanilla's
default), the clause limit bounds the distinct metasubstitutions of a
refutation, and the supports are the least fixpoint of the same recurrence
without sizes, computed by SWI-Prolog tabling, with the invention state
threaded in Vanilla's depth-first order. forest_applies/0 checks Poker's
other settings.

use_forest/0 makes poker:generalise/3 use the forest wherever it applies,
falling back to Vanilla elsewhere, so that Poker's learn/1 runs on the
forest unchanged; use_vanilla/0 undoes it.
*/

:- use_module(library(prolog_wrap)).

:- dynamic problem_sig/1, problem_metarule/3.

:- include(forest).
:- include(memo_assert).

% ---------- with hypothesis reuse ----------

% reuse_reach(Lit, K, M, S, M2): an instance of Lit has a refutation whose
% metasubstitutions are exactly S (a sorted set of at most K), hypothesis
% clauses reused, starting with the inventions of rank =< M available and
% leaving those of rank =< M2.  A clause headed by the I-th invention is
% introduced only once the (I-1)-th is available, as in Vanilla; a clause met
% again passes, its head already available.
:- table reuse_reach/5.

reuse_reach(Lit, _K, M, [], M) :-
    fv_bk(Lit).
reuse_reach(Lit, K, M, S, M2) :-
    arg(1, Lit, P), fv_sig(Sig), member(P, Sig),
    head_state(P, M, M1),
    fv_metarule(Sub, Lit, Body),
    fv_ok(Sub),
    reuse_body(Body, K, Sub, M1, S0, M2),
    ord_union([Sub], S0, S),
    length(S, N), N =< K.

reuse_body([], _, _, M, [], M).
reuse_body([L|Ls], K, Sub, M, S, M2) :-
    call_pattern(L, G),
    reuse_reach(G, K, M, S1, M1),
    G = L,
    fv_ok(Sub),
    reuse_body(Ls, K, Sub, M1, S2, M2),
    ord_union(S1, S2, S),
    length(S, N), N =< K.

% Vanilla resolves goals against hypothesis clauses it has built.
reuse_mode :-
    configuration:fetch_clauses(F),
    (   F == all
    ->  true
    ;   memberchk(hypothesis, F)
    ).

% ---------- the hooks of the forest ----------

fv_sig(Ss) :- problem_sig(Ss).

rank(S, R) :-
    problem_sig([T|Is]),
    (   S == T
    ->  R = 0
    ;   nth1(R, Is, S0), S0 == S
    ->  true
    ).

fv_metarule(Sub, Head, Body) :- problem_metarule(Sub, Head, Body).

% Background knowledge: the encapsulated clauses Vanilla resolves against.
fv_bk(Lit) :-
    functor(Lit, F, A),
    current_predicate(user:F/A),
    user:Lit.

fv_ok(Sub) :- vanilla:constraints(Sub).

% ---------- the problem ----------

set_problem(Ep, MS) :-
    retractall(problem_sig(_)),
    retractall(problem_metarule(_, _, _)),
    poker:signature(Ep, Ss),
    assertz(problem_sig(Ss)),
    forall(member(M, MS),
           (   metarule_parts(M, Sub, Head, Body)
           ->  assertz(problem_metarule(Sub, Head, Body))
           ;   true
           )),
    memo_reset.

% An expanded metarule Sub :- (Head, Body...), with Sub possibly paired with
% its unfolded form as Sub/_.
metarule_parts(M, Sub, Head, Body) :-
    copy_term(M, (Sub0 :- Conj)),
    (   Sub0 = Sub/_
    ->  true
    ;   Sub = Sub0
    ),
    conj_list(Conj, [Head|Body]).

conj_list((A, B), [A|Bs]) :- !, conj_list(B, Bs).
conj_list(A, [A]).

% ---------- the generalisation step ----------

%!  forest_applies is semidet.
%
%   The forest computes exactly what Vanilla's generalisation does under
%   the current configuration: every proof kept, examples one at a time, no
%   worker threads.
forest_applies :-
    poker_configuration:proof_samples(P), P >= 1.0,
    \+ poker_configuration:generalise_conjunction(true),
    \+ poker_configuration:multithreading(generalise).

%!  forest_supports(+Example, +K, +Metarules, -Supports) is det.
%
%   Supports is the sorted list of the sets of metasubstitutions of the
%   refutations of the encapsulated Example within the clause limit K: at
%   most K steps, or with hypothesis reuse at most K distinct
%   metasubstitutions.
forest_supports(Ep, K, MS, Hs) :-
    set_problem(Ep, MS),
    (   reuse_mode
    ->  abolish_all_tables,
        call_pattern(Ep, G),
        findall(S, ( reuse_reach(G, K, 0, S, _), G = Ep ), Ss),
        sort(Ss, Hs0)
    ;   generalise(Ep, K, Hs0)
    ),
    (   poker_configuration:strict_clause_limit(true)
    ->  include([H]>>length(H, K), Hs0, Hs)
    ;   Hs = Hs0
    ).

% One sub-hypothesis of Ep, as Poker's metasubstitutions/4 gives it: each
% metasubstitution paired with its metarule.
forest_metasubstitutions(Ep, K, MS, Subs) :-
    forest_supports(Ep, K, MS, Hs),
    member(H, Hs),
    findall(Sub-M, (member(Sub, H), poker:metasub_metarule(Sub, MS, M)), Subs).

%!  forest_generalise(+Pos, +Metarules, -Generalised) is det.
%
%   As poker:generalise/3, with the forest computing the sub-hypotheses.
forest_generalise(Pos, MS, Ss_Pos) :-
    poker_configuration:clause_limit(K),
    reset_gensym('_'),
    findall(Subs,
            ( member(Ep, Pos),
              forest_metasubstitutions(Ep, K, MS, Subs),
              forall(member(Sub-_M, Subs), poker:constraints(Sub))
            ),
            Ss_Pos_),
    abolish_all_tables,
    once(poker_auxiliaries:skolem_sort(Ss_Pos_, Ss_Pos_s)),
    poker:unfold_generalised(Ss_Pos_s, Pos, MS, Ss_Pos_u),
    poker:rename_all_invented(Ss_Pos_u, Ss_Pos).

% ---------- running Poker on the forest ----------

use_forest :-
    use_vanilla,
    wrap_predicate(poker:generalise(Pos, MS, Ss), forest, Vanilla,
                   (   forest_poker:forest_applies
                   ->  forest_poker:forest_generalise(Pos, MS, Ss)
                   ;   Vanilla
                   )).

use_vanilla :-
    (   unwrap_predicate(poker:generalise/3, forest)
    ->  true
    ;   true
    ).
