% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: data/louise_examples/even_odd.pl of Vanilla, https://github.com/
% stassa/vanilla, commit 1beb7d1: learn even/1 by inventing odd/1 with the
% monadic metarules m1 and m2. Conversion: its positive example even(4) as
% the labelled example; without reuse its refutation takes 5 steps.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl even/1 \
%       data/forest_examples/benchmarks/survey/louise_even_odd.pl

:-module(louise_even_odd, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, zero/1, prev/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Vanilla's data/louise_examples/even_odd.pl (learn even/1 by inventing odd/1), as a Poker
% experiment: the positive example only, no hypothesis reuse, so even(4) takes 5 steps.
configuration: m1 metarule 'P(x):- Q(x)'.
configuration: m2 metarule 'P(x):- Q(x,y), R(y)'.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[5])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
background_knowledge(even/1, [zero/1, prev/2]).
metarules(even/1,[m2,m1]).
labelled_example(even/1,even(4)).
unlabelled_example(even/1,_):- fail.
zero(0).
prev(1,0).
prev(2,1).
prev(3,2).
prev(4,3).
