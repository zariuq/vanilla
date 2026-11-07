% The forest on Poker's a^n b^n experiment for n = 1..Max at clause limit
% 2n - 1, with the memo tables cleared before each run; with print, also the
% sub-hypotheses at n = 3.
% usage: swipl data/forest_examples/anbn_scaling.pl [assert|table] [Max] [print]
:- initialization(main, main).
:- ensure_loaded(forest_loader).

main :-
    current_prolog_flag(argv, Argv),
    (   select(print, Argv, Args) -> Print = true ; Args = Argv, Print = false ),
    (   Args = [Memo|_] -> true ; Memo = assert ),
    (   Args = [_, MaxA|_] -> atom_number(MaxA, Max) ; Max = 5 ),
    load_forest(Memo, anbn),
    forall(between(1, Max, N), run(N)),
    (   Print == true
    ->  forest:memo_reset, forest:ex(3, E), forest:generalise(E, 5, Hs),
        forall(member(H, Hs), (print(H), nl))
    ;   true
    ).

run(N) :-
    K is 2 * N - 1,
    forest:memo_reset,
    forest:ex(N, E),
    statistics(inferences, I0), get_time(T0),
    forest:generalise(E, K, Hs),
    get_time(T1), statistics(inferences, I1),
    length(Hs, D), Ms is (T1 - T0) * 1000, I is I1 - I0,
    forest:memo_stats(St),
    format("a^~w b^~w, clause limit ~w: ~w sub-hypotheses, ~3f ms, ~D inferences, ~w~n",
           [N, N, K, D, Ms, I, St]).
