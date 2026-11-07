% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/robots-recursion of the Popper suite of Cropper and Morel (Machine
% Learning 2021), https://github.com/logic-and-learning-lab/Popper, commit
% 5c608d3. Conversion: the positives as labelled examples (Poker generates
% its own negatives, so Popper's are dropped) and the language bias as dyadic
% metarules.
% The grid size is inlined, and clpfd's #< and #= are replaced by < and is/2,
% equivalent on ground input. The monadic predicates are left out, as the
% target needs only the moves, and the positives are ordered by their number
% of moves.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl f/2 \
%       data/forest_examples/benchmarks/survey/popper_robots_recursion.pl

:-module(robots_recursion, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, move_up/2, move_down/2, move_left/2, move_right/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Popper examples/robots-recursion, as a Poker experiment. The grid size 100 is inlined and
% clpfd's #< and #= are replaced by < and is/2, equivalent for ground inputs. The monadic
% at_top/at_left/... predicates are left out: the target needs only move_up.
% Labelled examples are the positives, ordered by the number of moves (100 - Y).
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[4])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[0]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
configuration:metarule_constraints(m(tailrec,P0,P1),fail):- P0==P1.
background_knowledge(f/2,[move_up/2,move_down/2,move_left/2,move_right/2]).
metarules(f/2,[identity,chain,tailrec]).
labelled_example(f/2,f(w(79,95),w(79,100))).
labelled_example(f/2,f(w(81,84),w(81,100))).
labelled_example(f/2,f(w(69,75),w(69,100))).
labelled_example(f/2,f(w(48,73),w(48,100))).
labelled_example(f/2,f(w(53,71),w(53,100))).
labelled_example(f/2,f(w(85,68),w(85,100))).
labelled_example(f/2,f(w(75,68),w(75,100))).
labelled_example(f/2,f(w(44,68),w(44,100))).
labelled_example(f/2,f(w(53,65),w(53,100))).
labelled_example(f/2,f(w(62,64),w(62,100))).
labelled_example(f/2,f(w(96,46),w(96,100))).
labelled_example(f/2,f(w(35,43),w(35,100))).
labelled_example(f/2,f(w(7,40),w(7,100))).
labelled_example(f/2,f(w(48,39),w(48,100))).
labelled_example(f/2,f(w(11,36),w(11,100))).
labelled_example(f/2,f(w(39,22),w(39,100))).
labelled_example(f/2,f(w(71,16),w(71,100))).
labelled_example(f/2,f(w(19,13),w(19,100))).
labelled_example(f/2,f(w(90,4),w(90,100))).
labelled_example(f/2,f(w(14,1),w(14,100))).
unlabelled_example(f/2,_):- fail.
move_right(w(X1,Y),w(X2,Y)):- X1 < 100, X2 is X1 + 1.
move_left(w(X1,Y),w(X2,Y)):- X1 > 1, X2 is X1 - 1.
move_up(w(X,Y1),w(X,Y2)):- Y1 < 100, Y2 is Y1 + 1.
move_down(w(X,Y1),w(X,Y2)):- Y1 > 1, Y2 is Y1 - 1.
