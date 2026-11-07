% Poker's generalise/3 against the forest's on Poker's a^n b^n experiment
% (data/poker_examples/anbn_poker.pl) at any size: the experiment's example
% is replaced by a^N b^N. Run from Vanilla's root with Poker selected as the
% learner in configuration.pl, learner(poker,lib(poker/poker)):
%   swipl data/forest_examples/poker_comparison.pl [N [K]]
% N defaults to 3 and K to 2N - 1. Poker takes about a second at N = 3 and a
% few minutes at N = 4.
:- initialization(main, main).
:- prolog_load_context(directory, Dir),
   atom_concat(Dir, '/../../load_headless', Loader),
   consult(Loader).
:- use_module(comparison).

main :-
    poker_selected,
    current_prolog_flag(argv, Argv),
    (   Argv = [NA|_] -> atom_number(NA, N) ; N = 3 ),
    (   Argv = [_, KA|_] -> atom_number(KA, K) ; K is 2 * N - 1 ),
    load_experiment_file:load_experiment_file(data('poker_examples/anbn_poker.pl')),
    experiment_file:set_configs,
    poker_auxiliaries:set_poker_configuration_option(clause_limit, [K]),
    length(As, N), maplist(=(a), As),
    length(Bs, N), maplist(=(b), Bs),
    append(As, Bs, W),
    poker_auxiliaries:experiment_data(s/2, _Ls, Us, BK, MS),
    mil_problem:encapsulated_problem([s(W, [])], Us, BK, MS, [Ls_, _Us_, BK_, MS_]),
    auxiliaries:write_problem(user, [BK_], _Refs),
    format("a^~w b^~w, clause limit ~w~n", [N, N, K]),
    compare_generalisations(Ls_, MS_, Outcome),
    (   Outcome == identical -> true ; halt(1) ).
