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
%   Outcome is identical, different or error; the times, inference counts
%   and any differences are printed. Both failing (no example has a
%   refutation within the clause limit) is identical; an exception in either
%   (a resource limit, say) is error, never an agreement.
compare_generalisations(Pos, MS, Outcome) :-
    timed(( vanilla:refresh_tables(untable), vanilla:refresh_tables(table),
            poker:generalise(Pos, MS, P) ), P, PMs, PI),
    timed(forest_generalise(Pos, MS, F), F, FMs, FI),
    report(poker, P, PMs, PI),
    report(forest, F, FMs, FI),
    (   ( P = error(_) ; F = error(_) )
    ->  Outcome = error,
        format("  NOT COMPARED: an exception was raised~n")
    ;   P =@= F
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
% that outcome is recorded as none, an exception as error(E).
timed(Goal, Out, Ms, I) :-
    garbage_collect,
    statistics(inferences, I0), get_time(T0),
    catch(( Goal -> true ; Out = none ), E, Out = error(E)),
    get_time(T1), statistics(inferences, I1),
    Ms is (T1 - T0) * 1000, I is I1 - I0,
    (   nonvar(Out), Out = error(_)
    ->  abolish_all_tables
    ;   true
    ).

report(Name, none, Ms, I) :- !,
    format("  ~w: no sub-hypotheses (generalise/3 failed), ~1f ms, ~D inferences~n",
           [Name, Ms, I]).
report(Name, error(E), Ms, _) :- !,
    (   E = error(Formal, _)
    ->  true
    ;   Formal = E
    ),
    format("  ~w: raised ~q after ~1f ms~n", [Name, Formal, Ms]).
report(Name, Out, Ms, I) :-
    length(Out, N),
    format("  ~w: ~w sub-hypotheses, ~1f ms, ~D inferences~n", [Name, N, Ms, I]).
