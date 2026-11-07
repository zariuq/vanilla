% The forest's memo tables as asserted facts, keyed on the term hash of the
% ground call (first-argument indexing on an integer); each entry holds one
% sorted list.
:- dynamic memo/3.

memoised(Key, Goal, L) :-
    term_hash(Key, H),
    (   memo(H, Key, L0)
    ->  L = L0
    ;   call(Goal, L1),
        assertz(memo(H, Key, L1)),
        L = L1
    ).

reach(Q, U, N, M, L) :-
    memoised(reach(Q, U, N, M),
             [L0]>>(findall(R, fv_reach(Q, U, N, M, R), Rs), sort(Rs, L0)), L).

fam(P, U, Y, N, M, M2, L) :-
    memoised(fam(P, U, Y, N, M, M2),
             [L0]>>(findall(S, fv_supports(P, U, Y, N, M, M2, S), Ss), sort(Ss, L0)), L).

bk_answers(U, L) :-
    memoised(bk(U), [L0]>>fv_bk_answers(U, L0), L).

memo_reset :- retractall(memo(_, _, _)).

memo_stats(stats(reach_entries(RE), reach_items(RI), fam_entries(FE), fam_items(FI))) :-
    aggregate_all(count, memo(_, reach(_, _, _, _), _), RE),
    aggregate_all(sum(Len), (memo(_, reach(_, _, _, _), L), length(L, Len)), RI),
    aggregate_all(count, memo(_, fam(_, _, _, _, _, _), _), FE),
    aggregate_all(sum(Len), (memo(_, fam(_, _, _, _, _, _), L), length(L, Len)), FI).
