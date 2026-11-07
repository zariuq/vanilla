% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: examples/andersen of the Popper suite of Cropper and Morel (Machine
% Learning 2021), https://github.com/logic-and-learning-lab/Popper, commit
% 5c608d3. Conversion: the positives as labelled examples (Poker generates
% its own negatives, so Popper's are dropped) and the language bias as dyadic
% metarules.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl pt/2 \
%       data/forest_examples/benchmarks/survey/popper_andersen.pl

:-module(andersen, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, addr/2, assgn/2, store/2, load/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
configuration:tri_chain metarule 'P(x,y):- Q(x,z), R(z,u), S(u,y)'.
% Popper examples/andersen, as a Poker experiment.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[3])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[0]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
configuration:metarule_constraints(m(tri_chain,P0,P1,_,_),fail):- P0==P1.
background_knowledge(pt/2,[addr/2,assgn/2,store/2,load/2]).
metarules(pt/2,[identity,chain,tri_chain]).
labelled_example(pt/2,pt(v2,v1)).
labelled_example(pt/2,pt(v3,v1)).
labelled_example(pt/2,pt(v4,v1)).
labelled_example(pt/2,pt(v6,v7)).
labelled_example(pt/2,pt(v5,v7)).
labelled_example(pt/2,pt(v7,v1)).
labelled_example(pt/2,pt(v8,v1)).
unlabelled_example(pt/2,_):- fail.
addr(v2,v1).
addr(v6,v7).
assgn(v3,v2).
assgn(v4,v3).
assgn(v5,v6).
store(v5,v4).
load(v8,v5).