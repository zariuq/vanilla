% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/kinship-ancestor of the Popper suite of Cropper and Morel (Machine
% Learning 2021), https://github.com/logic-and-learning-lab/Popper, commit
% 5c608d3. Conversion: the positives as labelled examples (Poker generates
% its own negatives, so Popper's are dropped) and the language bias as dyadic
% metarules.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl ancestor/2 \
%       data/forest_examples/benchmarks/survey/popper_kinship_ancestor.pl

:-module(kinship_ancestor, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, mother/2, father/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
% Popper examples/kinship-ancestor, as a Poker experiment.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[3])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[0]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
configuration:metarule_constraints(m(tailrec,P0,P1),fail):- P0==P1.
background_knowledge(ancestor/2,[mother/2,father/2]).
metarules(ancestor/2,[identity,tailrec]).
labelled_example(ancestor/2,ancestor(elizabeth_second,prince_charles)).
labelled_example(ancestor/2,ancestor(george_sixth,prince_harry)).
labelled_example(ancestor/2,ancestor(queen_mother,prince_william)).
unlabelled_example(ancestor/2,_):- fail.
mother(queen_victoria,edward_seventh).
mother(queen_mother,elizabeth_second).
mother(elizabeth_second,prince_charles).
mother(princess_diana,prince_william).
mother(princess_diana,prince_harry).
father(edward_seventh,george_fifth).
father(george_fifth,george_sixth).
father(george_sixth,elizabeth_second).
father(prince_philip,prince_charles).
father(prince_charles,prince_william).
father(prince_charles,prince_harry).
father(prince_william,prince_george).