% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/member, first-order variant, of the Hopper suite of Purgal,
% Cerna and Kaliszyk (IJCAI 2022), https://github.com/Ermine516/HOpper, commit
% 2283c3f. Conversion: f(List, X) holds when X is in List; its positives as
% labelled examples, head/2 and tail/2 as background knowledge, and the
% metarules Identity and Tail-recursion.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl f/2 \
%       data/forest_examples/benchmarks/survey/hopper_member.pl

:-module(hopper_member, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, head/2, tail/2, empty/1]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Hopper examples/member (FO variant), as a Poker experiment: f(List,X) holds when X is in List.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[8])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[0]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(tailrec,P0,P1),fail):- P0==P1.
background_knowledge(f/2,[head/2,tail/2]).
metarules(f/2,[identity,tailrec]).
labelled_example(f/2,f([7, 11, 12, 14, 22, 28, 39, 40, 43, 45, 48, 51, 52, 60, 70, 85, 95, 98, 99],40)).
labelled_example(f/2,f([57, 98],57)).
labelled_example(f/2,f([7, 11, 14, 17, 22, 22, 22, 33, 41, 50, 74, 78, 90, 93, 96, 98],33)).
labelled_example(f/2,f([2, 6, 8, 15, 20, 24, 25, 26, 28, 29, 35, 37, 41, 49, 50, 52, 57, 60, 61, 62, 64, 66, 66, 70, 71, 85, 88, 95, 99, 100],20)).
unlabelled_example(f/2,_):- fail.
tail([_|T],T).
head([H|_],H).
empty([]).
