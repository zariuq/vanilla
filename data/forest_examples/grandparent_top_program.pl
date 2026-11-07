% The forest's top program construction on the grandparent problem: the
% program learned, the time of the first run and the mean of 50 runs.
% usage: swipl data/forest_examples/grandparent_top_program.pl [assert|table]
:- initialization(main, main).
:- ensure_loaded(forest_loader).

main :-
    current_prolog_flag(argv, Argv),
    (   Argv = [Memo|_] -> true ; Memo = assert ),
    load_forest(Memo, grandparent),
    forest:pos(P), forest:neg(N),
    forest:memo_reset,
    get_time(T0), forest:tpc1(P, N, R), get_time(T1),
    First is (T1 - T0) * 1e6,
    R = top(Raw, Distinct, Kept, Program),
    format("~w supports, ~w distinct, ~w kept after the negative examples:~n",
           [Raw, Distinct, Kept]),
    forall(member(C, Program), (write('  '), print(C), nl)),
    format("first run ~1f us~n", [First]),
    get_time(T2),
    forall(between(1, 50, _), (forest:memo_reset, forest:tpc1(P, N, _))),
    get_time(T3),
    Mean is (T3 - T2) * 1e6 / 50,
    format("mean of 50 runs ~1f us~n", [Mean]).
