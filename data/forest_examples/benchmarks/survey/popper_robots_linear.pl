% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/robots-linear of the Popper suite of Cropper and Morel (Machine
% Learning 2021), https://github.com/logic-and-learning-lab/Popper, commit
% 5c608d3. Conversion: the positives as labelled examples (Poker generates
% its own negatives, so Popper's are dropped) and the language bias as dyadic
% metarules.
% The grid size is inlined, and clpfd's #< and #= are replaced by < and is/2,
% equivalent on ground input.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl f/2 \
%       data/forest_examples/benchmarks/survey/popper_robots_linear.pl

:-module(robots_linear, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, up/2, down/2, left/2, right/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Popper examples/robots-linear, as a Poker experiment. The grid size 10 is inlined and
% clpfd's #< and #= are replaced by < and is/2, equivalent for ground inputs.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[4])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
background_knowledge(f/2,[up/2,down/2,left/2,right/2]).
metarules(f/2,[identity,chain]).
labelled_example(f/2,f(w(0,0),w(5,0))).
unlabelled_example(f/2,_):- fail.
right(w(X1,Y),w(X2,Y)):- X1 < 10, X2 is X1 + 1.
left(w(X1,Y),w(X2,Y)):- X1 > 1, X2 is X1 - 1.
up(w(X,Y1),w(X,Y2)):- Y1 < 10, Y2 is Y1 + 1.
down(w(X,Y1),w(X,Y2)):- Y1 > 1, Y2 is Y1 - 1.
