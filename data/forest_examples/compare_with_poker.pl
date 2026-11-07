% Poker's generalise/3 against the forest's on a Vanilla experiment file: both
% run on the experiment's encapsulated problem, and their outputs, Poker's
% sub-hypotheses after its own sorting and renaming, are compared as terms.
% Run from Vanilla's root with Poker selected as the learner in
% configuration.pl, learner(poker,lib(poker/poker)):
%   swipl data/forest_examples/compare_with_poker.pl TARGET EXPERIMENT [K]
% for example
%   swipl data/forest_examples/compare_with_poker.pl s/2 data/poker_examples/anbn_poker.pl
% (the target comes first: SWI-Prolog loads leading .pl arguments as scripts).
% K, if given, replaces the experiment's clause limit.
:- initialization(main, main).
:- prolog_load_context(directory, Dir),
   atom_concat(Dir, '/../../load_headless', Loader),
   consult(Loader).
:- use_module(lib(forest/forest_poker)).
:- use_module(comparison).

main :-
    poker_selected,
    step(current_prolog_flag(argv, [TargetA, File|Rest]),
         'usage: compare_with_poker.pl TARGET EXPERIMENT [K]'),
    step(term_to_atom(Target, TargetA), 'reading the target'),
    step(load_experiment_file:load_experiment_file(File), 'loading the experiment file'),
    (   catch(experiment_file:set_configs, _, fail) -> true ; true ),
    (   Rest = [KA|_]
    ->  atom_number(KA, K0),
        poker_auxiliaries:set_poker_configuration_option(clause_limit, [K0])
    ;   true
    ),
    poker_configuration:clause_limit(K),
    (   forest_applies
    ->  true
    ;   format("~w: outside the forest's setting (it fetches hypothesis clauses, samples proofs, generalises conjunctions or uses threads)~n",
               [File]),
        halt(2)
    ),
    step(poker_auxiliaries:experiment_data(Target, Ls, Us, BK, MS),
         'reading the experiment data'),
    step(mil_problem:encapsulated_problem(Ls, Us, BK, MS, [Ls_, _Us_, BK_, MS_]),
         'encapsulating the problem'),
    step(auxiliaries:write_problem(user, [BK_], _Refs), 'writing the background knowledge'),
    length(Ls_, NE),
    format("~w, ~w, ~w example(s), clause limit ~w~n", [File, Target, NE, K]),
    compare_generalisations(Ls_, MS_, Outcome),
    (   Outcome == identical -> true ; halt(1) ).

step(Goal, What) :-
    (   catch(Goal, E, (print_message(error, E), fail))
    ->  true
    ;   format(user_error, "Failed: ~w~n", [What]),
        halt(1)
    ).
