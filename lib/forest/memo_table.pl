% The forest's memo tables by SWI-Prolog tabling: each is a tabled predicate
% with a single answer, the sorted list.
:- table reach/5, fam/7, bk_answers/2.

reach(Q, U, N, M, L) :- findall(R, fv_reach(Q, U, N, M, R), Rs), sort(Rs, L).
fam(P, U, Y, N, M, M2, L) :-
    findall(S, fv_supports(P, U, Y, N, M, M2, S), Ss), sort(Ss, L).
bk_answers(U, L) :- fv_bk_answers(U, L).

memo_reset :- abolish_all_tables.

memo_stats(stats(tabled)).
