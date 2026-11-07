% Poker's generalisation and the forest's on Poker's a^n b^n experiment,
% compared as sets of sub-hypotheses, with their times and inference counts.
% Run from Vanilla's root with Poker selected as the learner in
% configuration.pl, learner(poker,lib(poker/poker)):
%   swipl data/forest_examples/poker_comparison.pl [N [K]]
% N defaults to 3 and K to 2N - 1. Poker takes about a second at N = 3 and a
% few minutes at N = 4.
:- initialization(main, main).
:- ensure_loaded(forest_loader).
:- consult(forest_examples('../../load_headless')).

main :-
    (   configuration:learner(poker, _)
    ->  true
    ;   format(user_error,
               "Select Poker in configuration.pl: learner(poker,lib(poker/poker)).~n",
               []),
        halt(1)
    ),
    current_prolog_flag(argv, Argv),
    (   Argv = [NA|_] -> atom_number(NA, N) ; N = 3 ),
    (   Argv = [_, KA|_] -> atom_number(KA, K) ; K is 2 * N - 1 ),
    poker_generalise(N, K, PokerSubs, PMs, PI),
    maplist(poker_hypothesis, PokerSubs, PH0), sort(PH0, PH),
    load_forest(assert, anbn),
    forest_generalise(N, K, FH, FMs, FI),
    length(PokerSubs, PN), length(PH, PD), length(FH, FD),
    format("a^~w b^~w, clause limit ~w~n", [N, N, K]),
    format("  Poker:  ~w sub-hypotheses (~w distinct), ~1f ms, ~D inferences~n",
           [PN, PD, PMs, PI]),
    format("  forest: ~w sub-hypotheses, ~3f ms, ~D inferences~n", [FD, FMs, FI]),
    (   PH == FH
    ->  format("  identical sets of sub-hypotheses~n")
    ;   ord_subtract(PH, FH, OnlyPoker), ord_subtract(FH, PH, OnlyForest),
        format("  DIFFERENT~n  only Poker: ~q~n  only forest: ~q~n",
               [OnlyPoker, OnlyForest]),
        halt(1)
    ).

poker_generalise(N, K, Subs, Ms, I) :-
    load_experiment_file:load_experiment_file(data('poker_examples/anbn_poker.pl')),
    experiment_file:set_configs,
    poker_auxiliaries:set_poker_configuration_option(clause_limit, [K]),
    anbn_word(N, W),
    poker_auxiliaries:experiment_data(s/2, _Ls, Us, BK, MS),
    mil_problem:encapsulated_problem([s(W, [])], Us, BK, MS, [Ls_, _Us_, BK_, MS_]),
    auxiliaries:write_problem(user, [BK_], _Refs),
    vanilla:refresh_tables(untable), vanilla:refresh_tables(table),
    statistics(inferences, I0), get_time(T0),
    % generalise/3 fails when no refutation fits within the clause limit.
    (   poker:generalise(Ls_, MS_, Subs)
    ->  true
    ;   Subs = [],
        format("  (Poker's generalise/3 failed: no refutation within the clause limit)~n")
    ),
    get_time(T1), statistics(inferences, I1),
    Ms is (T1 - T0) * 1000, I is I1 - I0.

forest_generalise(N, K, Hs, Ms, I) :-
    forest:memo_reset,
    forest:ex(N, E),
    statistics(inferences, I0), get_time(T0),
    forest:generalise(E, K, Hs),
    get_time(T1), statistics(inferences, I1),
    Ms is (T1 - T0) * 1000, I is I1 - I0.

anbn_word(N, W) :-
    length(As, N), maplist(=(a), As),
    length(Bs, N), maplist(=(b), Bs),
    append(As, Bs, W).

% A sub-hypothesis of Poker, a list of Metasubstitution-Metarule pairs, in the
% forest's spelling: m(Id, P, ...) becomes sub(Id, P, ...), and an invented
% symbol inv_I_J (the I-th invention of the J-th sub-hypothesis) becomes inv_I.
poker_hypothesis(Subs, H) :-
    maplist(poker_sub, Subs, H0), sort(H0, H).

poker_sub(M-_Metarule, S) :-
    M =.. [m|Args], maplist(base_symbol, Args, Args1), S =.. [sub|Args1].

base_symbol(A, B) :-
    (   atom(A), atomic_list_concat(Parts, '_', A), Parts = [inv, I, _]
    ->  atomic_list_concat([inv, I], '_', B)
    ;   B = A
    ).
