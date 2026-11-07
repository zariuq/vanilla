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
% The forest solves each first-order goal once. A derivation is its root clause
% and one derivation per body literal; each part is memoised on its goal, its
% exact size N (the number of clause steps it takes) and the invented
% predicates already in use:
%
%   reach(P, X, N, M, L)        L is the sorted list of r(Y, M2): the
%                               derivations of P(X, Y) of size N that start
%                               with the inventions of rank =< M available
%                               and leave those of rank =< M2 available
%   fam(P, X, Y, N, M, M2, L)   L is the sorted list of the supports of those
%                               derivations, each a sorted list of
%                               metasubstitutions
%
% Pass 1 (reach) finds which endpoints each goal reaches at each size; pass 2
% (fam) builds supports only in contexts pass 1 found feasible. The supports of
% a clause are its own metasubstitution together with one support of each body
% literal, for every way of splitting the remaining size among the literals.
% Work therefore grows with the number of distinct goals and supports, not
% with the number of derivation trees.
%
% generalise/3 collects the supports of an example's derivations of size 1..K.
% On Poker's a^n b^n experiment these are Poker's sub-hypotheses at clause
% limit K: data/forest_examples/poker_comparison.pl compares the two for any N
% and K.
%
% A task defines the background facts and rules m/3 and bk_rule/2, the
% signature fv_sig/1 (the target, then the invented predicates), the metarules
% in use fv_ids/1, the metarule constraints fv_cons/1, and rank/2 (0 for the
% target, I for the I-th invented predicate). Memoisation comes from
% memo_assert.pl or memo_table.pl, which define reach/5, fam/7 and
% bk_answers/2 over the fv_* relations below; the metarules are in
% metarules.pl.

% ---------- small helpers ----------

upto(I, N, I) :- I =< N.
upto(I, N, X) :- I < N, I1 is I + 1, upto(I1, N, X).

% ---------- metarule constraints, by == so that unbound symbols pass ----------

check(direct, S) :- arg(2, S, P), arg(3, S, Q), \+ P == Q.
check(distinct_body, S) :-
    arg(1, S, Id),
    (   Id == chain
    ->  arg(3, S, Q), arg(4, S, R), \+ Q == R
    ;   true
    ).

ok_all([], _).
ok_all([C|Cs], S) :- check(C, S), ok_all(Cs, S).

ok(S) :- fv_cons(Cs), ok_all(Cs, S).

% ---------- background knowledge: derivations of size zero ----------

fv_bk_answers(U, L) :- findall(bk(R, V), bk_solve(U, R, V), L0), sort(L0, L).

bk_solve(U, R, V) :- m(R, U, V).
bk_solve(U, R, V) :- bk_rule(m(R, U, V), Body), bk_body(Body).

bk_body([]).
bk_body([G|Gs]) :- bk_goal(G), bk_body(Gs).

bk_goal(m(R, U, V)) :- !, bk_answers(U, L), member(bk(R, V), L).
bk_goal(G) :- call(G).

% ---------- pass 1: endpoints by exact size ----------

% Invented predicates are introduced in order: inv_I only once inv_(I-1) is
% available.
head_state(Q, M, M1) :-
    rank(Q, R), R =< M + 1, mcap(C), M1 is min(max(R, M), C).

mcap(C) :- fv_sig(Sig), max_rank(Sig, R), C is max(0, R - 1).

max_rank([], 0).
max_rank([P|Ps], R) :- rank(P, R1), max_rank(Ps, R2), R is max(R1, R2).

fv_reach(Q, U, N, M, r(Y, M2)) :-
    head_state(Q, M, M1),
    fv_ids(Ids), member(Id, Ids),
    mr(Id, Q, S, m(Q, U, Y), Body),
    ok(S),
    N1 is N - 1,
    layout(Body, N1, S, M1, lays(_Lay, M2)).

% layout(Body, N, S, M, lays(Lay, M2)): split the size N among the body
% literals, left to right, and solve each literal at its share.
layout([], N, _S, M, lays([], M)) :- N == 0.
layout([Lit|Rest], N, S, M, lays([lay(R, U, V, N1, M, M1)|More], M2)) :-
    Lit = m(R, U, V),
    (   Rest == []
    ->  N1 = N
    ;   upto(0, N, N1)
    ),
    lit_reach(R, U, V, N1, M, M1),
    ok(S),
    N2 is N - N1,
    layout(Rest, N2, S, M1, lays(More, M2)).

% A literal of size 0 is background knowledge; a larger one is a target or
% invented predicate.
lit_reach(R, U, V, N, M, Mout) :-
    (   N == 0
    ->  bk_answers(U, L), member(bk(R, V), L), Mout = M
    ;   fv_sig(Sig), member(R, Sig),
        reach(R, U, N, M, L), member(r(V, M2), L), Mout = M2
    ).

% ---------- pass 2: supports of items in feasible contexts ----------

fv_supports(P, U, Y, N, M, M2, Sorted) :-
    head_state(P, M, M1),
    fv_ids(Ids), member(Id, Ids),
    mr(Id, P, S, m(P, U, Y), Body),
    ok(S),
    N1 is N - 1,
    layout(Body, N1, S, M1, lays(Lay, M2)),
    product(Lay, SS),
    sort([S|SS], Sorted).

product([], []).
product([lay(R, U, V, N, M, M2)|Rest], Out) :-
    (   N == 0
    ->  product(Rest, Out)
    ;   fam(R, U, V, N, M, M2, Fs),
        member(S1, Fs),
        product(Rest, S2),
        append(S1, S2, Out)
    ).

% ---------- learner ----------

% generalise(+Example, +K, -Hs): Hs is the sorted list of the supports of the
% derivations of Example of size 1..K.
generalise(m(Q, X, Y), K, Hs) :-
    findall(F,
            ( upto(1, K, N),
              reach(Q, X, N, 0, Ms),
              member(r(Y2, M2), Ms),
              Y2 == Y,
              fam(Q, X, Y, N, 0, M2, Fs),
              member(F, Fs)
            ),
            L),
    sort(L, Hs).

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
