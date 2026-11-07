% The forest's memo tables as asserted facts. A call is keyed by its variant
% hash (variant_sha1/2, which ignores the names of variables) and confirmed
% by =@=; each entry holds one sorted list.
:- dynamic memo/3.

memo_lookup(H, Call, L) :-
    memo(H, K, L0), K =@= Call, !,
    L = L0.

reach(Lit, N, M, L) :-
    variant_sha1(reach(Lit, N, M), H),
    (   memo_lookup(H, reach(Lit, N, M), L0)
    ->  L = L0
    ;   findall(A, fv_reach(Lit, N, M, A), As), sort(As, L1),
        assertz(memo(H, reach(Lit, N, M), L1)), L = L1
    ).

fam(Inst, N, M, M2, L) :-
    variant_sha1(fam(Inst, N, M, M2), H),
    (   memo_lookup(H, fam(Inst, N, M, M2), L0)
    ->  L = L0
    ;   findall(S, fv_supports(Inst, N, M, M2, S), Ss), sort(Ss, L1),
        assertz(memo(H, fam(Inst, N, M, M2), L1)), L = L1
    ).

bk_answers(Lit, L) :-
    variant_sha1(bk(Lit), H),
    (   memo_lookup(H, bk(Lit), L0)
    ->  L = L0
    ;   fv_bk_answers(Lit, L1),
        assertz(memo(H, bk(Lit), L1)), L = L1
    ).

memo_reset :- retractall(memo(_, _, _)).

memo_stats(stats(reach_entries(RE), reach_items(RI), fam_entries(FE), fam_items(FI))) :-
    aggregate_all(count, memo(_, reach(_, _, _), _), RE),
    aggregate_all(sum(Len), (memo(_, reach(_, _, _), L), length(L, Len)), RI),
    aggregate_all(count, memo(_, fam(_, _, _, _), _), FE),
    aggregate_all(sum(Len), (memo(_, fam(_, _, _, _), L), length(L, Len)), FI).
