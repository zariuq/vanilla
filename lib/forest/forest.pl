% The provenance forest: Poker's generalisation step, computed without
% enumerating derivation trees one at a time.
%
% Poker generalises an example by proving it with Vanilla and keeping, for each
% refutation, the set of metasubstitutions the refutation used: one
% sub-hypothesis. Most refutations share most of their sub-derivations, but an
% untabled prover derives them again in every tree, and tabling Vanilla's
% meta-interpreter cannot share them either, because the hypothesis built so
% far is part of every call.
%
% The forest solves each goal once. A derivation is its root clause and one
% derivation per body literal; each part is memoised on its goal (up to
% variable renaming), its exact size N (the number of clause steps it takes)
% and the invented predicates already available:
%
%   reach(Lit, N, M, L)       L is the sorted list of a(Inst, M2): the
%                             instances Inst of the literal Lit that have a
%                             derivation of size N starting with the inventions
%                             of rank =< M available and leaving those of
%                             rank =< M2 available
%   fam(Inst, N, M, M2, L)    L is the sorted list of the supports of those
%                             derivations of Inst, each a sorted list of
%                             metasubstitutions
%   bk_answers(Lit, L)        L is the sorted list of the instances of Lit the
%                             background knowledge proves (size 0)
%
% Pass 1 (reach) finds which instances each goal reaches at each size; pass 2
% (fam) builds supports only in contexts pass 1 found feasible. The supports of
% a clause are its own metasubstitution together with one support of each body
% literal, for every way of splitting the remaining size among the literals,
% left to right. Work therefore grows with the number of distinct goals and
% supports, not with the number of derivation trees.
%
% generalise/3 collects the supports of an example's derivations of size 1..K.
% Literals are m(P, A1, ..., An), as in Vanilla's encapsulation. A front end
% defines, in the module the forest is loaded into:
%
%   fv_sig(Ss)                  the target, then the invented predicates in order
%   rank(S, R)                  0 for the target, I for the I-th invented predicate
%   fv_metarule(Sub, Head, Body)
%                               a fresh metarule: its metasubstitution, its head
%                               literal and its body literals (a list)
%   fv_bk(Lit)                  the background knowledge proves Lit, binding its
%                               predicate symbol if it is unbound
%   fv_ok(Sub)                  the metarule constraints accept Sub, which may be
%                               partly instantiated
%
% forest_tasks.pl is the front end for the forest's own task files;
% forest_poker.pl reads a Vanilla MIL problem and answers as Poker's
% generalise/3. Memoisation comes from memo_assert.pl or memo_table.pl.

% ---------- small helpers ----------

upto(I, N, I) :- I =< N.
upto(I, N, X) :- I < N, I1 is I + 1, upto(I1, N, X).

% ---------- the invention state ----------

% Invented predicates are introduced in order: the I-th may head a clause only
% once the (I-1)-th is available.
head_state(P, M, M1) :-
    rank(P, R), R =< M + 1, mcap(C), M1 is min(max(R, M), C).

mcap(C) :- fv_sig(Sig), max_rank(Sig, R), C is max(0, R - 1).

max_rank([], 0).
max_rank([P|Ps], R) :- rank(P, R1), max_rank(Ps, R2), R is max(R1, R2).

% ---------- pass 1: instances by exact size ----------

fv_reach(Lit, N, M, a(Lit, M2)) :-
    arg(1, Lit, P),
    head_state(P, M, M1),
    fv_metarule(Sub, Lit, Body),
    fv_ok(Sub),
    N1 is N - 1,
    layout(Body, N1, Sub, M1, lays(_Lay, M2)).

% layout(Body, N, Sub, M, lays(Lay, M2)): split the size N among the body
% literals, left to right, and solve each literal at its share.
layout([], N, _Sub, M, lays([], M)) :- N == 0.
layout([Lit|Rest], N, Sub, M, lays([lay(Lit, N1, M, M1)|More], M2)) :-
    (   Rest == []
    ->  N1 = N
    ;   upto(0, N, N1)
    ),
    lit_reach(Lit, N1, M, M1),
    fv_ok(Sub),
    N2 is N - N1,
    layout(Rest, N2, Sub, M1, lays(More, M2)).

% A literal of size 0 is proved by the background knowledge; a larger one is
% headed by the target or an invented predicate. Either is solved as its call
% pattern and the answers are unified with it.
lit_reach(Lit, N, M, Mout) :-
    call_pattern(Lit, G),
    (   N == 0
    ->  bk_answers(G, L), member(Lit, L), Mout = M
    ;   arg(1, Lit, R), fv_sig(Sig), member(R, Sig),
        reach(G, N, M, L), member(a(Lit, Mout), L)
    ).

% call_pattern(+Lit, -G): the goal memoised for Lit. When an argument before the
% last is bound, the last one is left open, as the output of a DCG or of a
% function: every call on the same input then shares one entry. Solving a more
% general goal and unifying its answers with Lit gives exactly Lit's answers,
% so the choice of pattern affects only speed.
call_pattern(Lit, G) :-
    Lit =.. [F, P|As],
    (   append(Init, [_], As), Init \== [], \+ maplist(var, Init)
    ->  append(Init, [_], As1), G =.. [F, P|As1]
    ;   G = Lit
    ).

fv_bk_answers(Lit, L) :- findall(Lit, fv_bk(Lit), L0), sort(L0, L).

% ---------- pass 2: supports of instances in feasible contexts ----------

fv_supports(Inst, N, M, M2, Sorted) :-
    arg(1, Inst, P),
    head_state(P, M, M1),
    fv_metarule(Sub, Inst, Body),
    fv_ok(Sub),
    N1 is N - 1,
    layout(Body, N1, Sub, M1, lays(Lay, M2)),
    product(Lay, SS),
    sort([Sub|SS], Sorted).

product([], []).
product([lay(Lit, N, M, M2)|Rest], Out) :-
    (   N == 0
    ->  product(Rest, Out)
    ;   fam(Lit, N, M, M2, Fs),
        member(S1, Fs),
        product(Rest, S2),
        append(S1, S2, Out)
    ).

% ---------- learner ----------

% generalise(+Example, +K, -Hs): Hs is the sorted list of the supports of the
% derivations of Example of size 1..K.
generalise(Ex, K, Hs) :-
    graded(Ex, K, NHs),
    pairs_values(NHs, Hs0),
    sort(Hs0, Hs).

% graded(+Example, +K, -NHs): NHs is the sorted list of the pairs N-S, S the
% support of a derivation of Example of size N, 1 =< N =< K. A support may
% come with several sizes. The supports within any smaller limit K1 are those
% of the pairs with N =< K1: the memo tables are indexed by exact size, so one
% run at K answers every smaller limit.
graded(Ex, K, NHs) :-
    call_pattern(Ex, G),
    findall(N-F,
            ( upto(1, K, N),
              reach(G, N, 0, As),
              member(a(Inst, M2), As),
              Inst =@= Ex,
              fam(Inst, N, 0, M2, Fs),
              member(F, Fs)
            ),
            L),
    sort(L, NHs).

% ---------- Louise's top program construction, clause limit 1 ----------

supports_all([], _, []).
supports_all([E|Es], K, L) :-
    generalise(E, K, Hs), supports_all(Es, K, Rest), append(Hs, Rest, L).

% tpc1(+Pos, +Neg, -top(Raw, Distinct, Kept, Program)): the supports of the
% positive examples, less those of the negative examples.
tpc1(Pos, Neg, top(NR, NH, NK, Kept)) :-
    supports_all(Pos, 1, Raw), sort(Raw, Hs),
    supports_all(Neg, 1, Bad0), sort(Bad0, Bad),
    ord_subtract(Hs, Bad, Kept),
    length(Raw, NR), length(Hs, NH), length(Kept, NK).
