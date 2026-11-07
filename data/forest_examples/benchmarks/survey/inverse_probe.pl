% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: written for this benchmark, a probe of the Inverse metarule: the
% example child(b,a) and the background facts parent/2.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl child/2 \
%       data/forest_examples/benchmarks/survey/inverse_probe.pl

:-module(inverse_probe, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, parent/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Probe: the Inverse metarule, child(X,Y) <- parent(Y,X).
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[2])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[0]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(inverse,P0,P1),fail):- P0==P1.
background_knowledge(child/2,[parent/2]).
metarules(child/2,[identity,inverse]).
labelled_example(child/2,child(b,a)).
unlabelled_example(child/2,_):- fail.
parent(a,b).
parent(b,c).
parent(x,y).
