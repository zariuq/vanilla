% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/kinship-pi of the Popper suite of Cropper and Morel (Machine
% Learning 2021), https://github.com/logic-and-learning-lab/Popper, commit
% 5c608d3. Conversion: the positives as labelled examples (Poker generates
% its own negatives, so Popper's are dropped) and the language bias as dyadic
% metarules.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl grandparent/2 \
%       data/forest_examples/benchmarks/survey/popper_kinship_pi.pl

:-module(kinship_pi, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, mother/2, father/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Popper examples/kinship-pi, as a Poker experiment (positives only; Poker generates its own negatives).
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[3])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
background_knowledge(grandparent/2,[mother/2,father/2]).
metarules(grandparent/2,[identity,chain]).
labelled_example(grandparent/2,grandparent(ann,amelia)).
labelled_example(grandparent/2,grandparent(steve,amelia)).
labelled_example(grandparent/2,grandparent(ann,spongebob)).
labelled_example(grandparent/2,grandparent(steve,spongebob)).
labelled_example(grandparent/2,grandparent(linda,amelia)).
unlabelled_example(grandparent/2,_):- fail.
mother(ann,amy).
mother(ann,andy).
mother(amy,amelia).
mother(linda,gavin).
father(steve,amy).
father(steve,andy).
father(gavin,amelia).
father(andy,spongebob).