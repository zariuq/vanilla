:- module(comparison, [poker_selected/0,
                       compare_generalisations/3]).

/** <module> Poker's generalise/3 against the forest's, on one problem.

Both run on the same encapsulated positive examples and metarules; their
outputs, Poker's sub-hypotheses after its own sorting, unfolding and renaming
of invented predicates, are compared as terms up to variable renaming.
*/

:- use_module(lib(forest/forest_poker)).

poker_selected :-
    (   configuration:learner(poker, _)
    ->  true
    ;   format(user_error,
               "Select Poker in configuration.pl: learner(poker,lib(poker/poker)).~n",
               []),
        halt(1)
    ).

%!  compare_generalisations(+Pos, +Metarules, -Outcome) is det.
%
%   Outcome is identical or different; the times, inference counts and any
%   differences are printed.
compare_generalisations(Pos, MS, Outcome) :-
    timed(( vanilla:refresh_tables(untable), vanilla:refresh_tables(table),
            poker:generalise(Pos, MS, P) ), P, PMs, PI),
    timed(forest_generalise(Pos, MS, F), F, FMs, FI),
    report(poker, P, PMs, PI),
    report(forest, F, FMs, FI),
    (   P =@= F
    ->  Outcome = identical,
        format("  identical generalisations~n")
    ;   Outcome = different,
        format("  DIFFERENT~n"),
        (   P = [_|_], F = [_|_]
        ->  forall(( member(X, P), \+ ( member(Y, F), Y =@= X ) ),
                   format("  only Poker: ~q~n", [X])),
            forall(( member(Y, F), \+ ( member(X, P), X =@= Y ) ),
                   format("  only forest: ~q~n", [Y]))
        ;   true
        )
    ).

% Poker's generalise/3 fails when no refutation fits within the clause limit;
% that outcome is recorded as none.
timed(Goal, Out, Ms, I) :-
    statistics(inferences, I0), get_time(T0),
    (   catch(Goal, E, (print_message(error, E), fail))
    ->  true
    ;   Out = none
    ),
    get_time(T1), statistics(inferences, I1),
    Ms is (T1 - T0) * 1000, I is I1 - I0.

report(Name, none, Ms, I) :- !,
    format("  ~w: no sub-hypotheses (generalise/3 failed), ~1f ms, ~D inferences~n",
           [Name, Ms, I]).
report(Name, Out, Ms, I) :-
    length(Out, N),
    format("  ~w: ~w sub-hypotheses, ~1f ms, ~D inferences~n", [Name, N, Ms, I]).
