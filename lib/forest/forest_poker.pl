:- module(forest_poker, [forest_generalise/3,
                         forest_supports/4,
                         forest_family/3,
                         forest_readoff/4,
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

forest_family/3 keeps one run's supports with their grades, and
forest_readoff/4 reads from them the answer of forest_generalise/3 at any
smaller clause limit (from 2) and max_invented, as a search for those
settings needs.
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
    reuse_literal(L, K, Sub, M, S1, M1),
    reuse_body(Ls, K, Sub, M1, S2, M2),
    ord_union(S1, S2, S),
    length(S, N), N =< K.

% A body literal whose predicate symbol is open (the Q and R of Chain) is
% answered by the background knowledge, with the empty support, or has its
% symbol chosen first among the target and invented predicates: the metarule
% constraints are then checked once per choice rather than once per support,
% and each symbol's goal is tabled apart. The answers are the same as those of
% the open goal.
reuse_literal(L, K, Sub, M, S1, M1) :-
    arg(1, L, P),
    var(P),
    !,
    (   fv_bk(L),
        S1 = [],
        M1 = M,
        fv_ok(Sub)
    ;   fv_sig(Sig),
        member(P, Sig),
        fv_ok(Sub),
        reuse_goal(L, K, Sub, M, S1, M1)
    ).
reuse_literal(L, K, Sub, M, S1, M1) :-
    reuse_goal(L, K, Sub, M, S1, M1).

% The constraints are checked again on each answer only if the literal can
% still bind the metasubstitution: an open symbol, or a variable shared with it.
reuse_goal(L, K, Sub, M, S1, M1) :-
    L =.. [_, P|Args],
    (   nonvar(P),
        \+ shares_variable(Args, Sub)
    ->  Recheck = false
    ;   Recheck = true
    ),
    call_pattern(L, G),
    reuse_reach(G, K, M, S1, M1),
    G = L,
    (   Recheck == true
    ->  fv_ok(Sub)
    ;   true
    ).

shares_variable(A, B) :-
    term_variables(A, AVs),
    term_variables(B, BVs),
    member(V, AVs),
    member(W, BVs),
    V == W,
    !.

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

% The constraints of a metasubstitution depend only on its instance, and the
% forest meets each instance once per answer of the literal that bound it:
% the check is tabled on the instance.
fv_ok(Sub) :- ok_instance(Sub).

:- table ok_instance/1.

ok_instance(Sub) :- vanilla:constraints(Sub).

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
    forest_graded(Ep, K, MS, NHs),
    within_limit(NHs, K, Hs).

% forest_graded(+Ep, +K, +MS, -NHs): NHs is the sorted list of the pairs N-S
% of the supports S of Ep's refutations within the clause limit K, N their
% grade: the number of steps without hypothesis reuse, the number of
% metasubstitutions in S with reuse.
forest_graded(Ep, K, MS, NHs) :-
    set_problem(Ep, MS),
    (   reuse_mode
    ->  abolish_all_tables,
        call_pattern(Ep, G),
        findall(N-S, ( reuse_reach(G, K, 0, S, _), G = Ep, length(S, N) ), L),
        sort(L, NHs)
    ;   graded(Ep, K, NHs)
    ).

% within_limit(+NHs, +K, -Hs): the supports of the grades up to K, as
% Poker's prove_with_clause_limit/6 keeps them.
within_limit(NHs, K, Hs) :-
    findall(S, ( member(N-S, NHs), N =< K ), Ss),
    sort(Ss, Hs0),
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
    poker_output(Ss_Pos_, Pos, MS, Ss_Pos).

% Poker's own post-processing of the sub-hypotheses: sorting, unfolding and
% renaming of invented predicates.
poker_output(Ss_Pos_, Pos, MS, Ss_Pos) :-
    once(poker_auxiliaries:skolem_sort(Ss_Pos_, Ss_Pos_s)),
    poker:unfold_generalised(Ss_Pos_s, Pos, MS, Ss_Pos_u),
    poker:rename_all_invented(Ss_Pos_u, Ss_Pos).

% ---------- smaller limits read off one run ----------

%!  forest_family(+Pos, +Metarules, -Family) is det.
%
%   Family is the list of the pairs Ep-NHs of each positive example Ep and
%   the graded supports of its refutations (forest_graded/4) at the current
%   clause limit and max_invented. forest_readoff/4 reads from it the answer
%   of forest_generalise/3 at every smaller clause limit and max_invented.
forest_family(Pos, MS, Family) :-
    poker_configuration:clause_limit(K),
    findall(Ep-NHs, ( member(Ep, Pos), forest_graded(Ep, K, MS, NHs) ), Family),
    abolish_all_tables.

%!  forest_readoff(+Family, +Pos, +Metarules, -Generalised) is det.
%
%   As forest_generalise(Pos, Metarules, Generalised) under the current
%   clause limit K1 and max_invented M1, read off a Family that
%   forest_family/3 computed at a clause limit K >= K1 and max_invented
%   M >= M1: the supports of grade at most K1 that name no invented predicate
%   outside the first M1. Without reuse the memo tables are indexed by exact
%   size; with reuse the bounded fixpoint at K1 holds exactly the supports of
%   at most K1 metasubstitutions of the fixpoint at K (bfam_iff in
%   ProvenanceForest.lean). A refutation naming only the first M1 invented
%   predicates is one under the smaller signature, and conversely, since
%   Vanilla introduces invented predicates in order and resolves every
%   literal of one against a clause it heads. K1 must be at least 2: at
%   clause limit 1 Poker's top_program/7 also writes the labelled examples
%   as background knowledge, so the problem itself changes.
forest_readoff(Family, Pos, MS, Ss_Pos) :-
    poker_configuration:clause_limit(K1),
    must_be(between(2, inf), K1),
    reset_gensym('_'),
    findall(Subs,
            ( member(Ep, Pos),
              memberchk(Ep-NHs, Family),
              poker:signature(Ep, Sig),
              within_limit(NHs, K1, Hs),
              member(H, Hs),
              within_signature(H, Sig),
              findall(Sub-M,
                      ( member(Sub, H), poker:metasub_metarule(Sub, MS, M) ),
                      Subs),
              forall(member(Sub-_M, Subs), poker:constraints(Sub))
            ),
            Ss_Pos_),
    % As Poker's generalise/3, leave no tables behind: the steps after it
    % start from none.
    abolish_all_tables,
    poker_output(Ss_Pos_, Pos, MS, Ss_Pos).

% within_signature(+Support, +Sig): every invented predicate Support names is
% in Sig.
within_signature(H, Sig) :-
    \+ ( member(Sub, H),
         sub_term(S, Sub),
         atom(S),
         poker:invented_symbol_(_, S),
         \+ memberchk(S, Sig) ).

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
