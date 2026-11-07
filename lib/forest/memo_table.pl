% The forest's memo tables by SWI-Prolog tabling: each is a tabled predicate
% with a single answer, the sorted list; calls are tabled by variant.
:- table reach/4, fam/5, bk_answers/2.

reach(Lit, N, M, L) :- findall(A, fv_reach(Lit, N, M, A), As), sort(As, L).
fam(Inst, N, M, M2, L) :-
    findall(S, fv_supports(Inst, N, M, M2, S), Ss), sort(Ss, L).
bk_answers(Lit, L) :- fv_bk_answers(Lit, L).

memo_reset :- abolish_all_tables.

memo_stats(stats(tabled)).
