% A random grammar-learning problem for Poker (seed 7, case 015);
% data/forest_examples/random_problems.sh runs them all.
:-module(fz, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, a/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
configuration:tri_chain metarule 'P(x,y):- Q(x,z), R(z,u), S(u,y)'.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[2])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
configuration:metarule_constraints(m(tri_chain,P0,P1,_,_),fail):- P0==P1.
background_knowledge(s/2,[a/2]).
metarules(s/2,[identity,chain,tri_chain]).
labelled_example(s/2,s([a],[])).
unlabelled_example(s/2,_):- fail.
a --> [a].
