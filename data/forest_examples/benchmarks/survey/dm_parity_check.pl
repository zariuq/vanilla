% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: the task parity_check of Deletang et al., Neural Networks and the
% Chomsky Hierarchy (ICLR 2023), https://github.com/google-deepmind/
% neural_networks_chomsky_hierarchy, commit 2b8eb4b. That repository samples
% its training strings at random; this file fixes a sample.
% Conversion: the class-0 strings as the language of a grammar nonterminal
% s(String, []), each terminal a background grammar rule t([t|R], R), and the
% metarules Identity, Chain and Tri-Chain as the rules P -> Q, P -> Q R and
% P -> Q R S. Labelled examples: all 16 class-0 strings of length
% 0 to 4 (an even number of 1s).
% Metarule constraints: P differs from Q, and in Chain Q differs from R.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl s/2 \
%       data/forest_examples/benchmarks/survey/dm_parity_check.pl

:-module(dm_parity_check, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, zero/2, one/2, empty/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
configuration:tri_chain metarule 'P(x,y):- Q(x,z), R(z,u), S(u,y)'.
% DeepMind neural_networks_chomsky_hierarchy task parity_check, posed as a recogniser of its class-0 strings.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[5])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
configuration:metarule_constraints(m(identity,P0,P1),fail):- P0==P1.
configuration:metarule_constraints(m(chain,P0,P1,_),fail):- P0==P1.
configuration:metarule_constraints(m(chain,_,P1,P2),fail):- P1==P2.
configuration:metarule_constraints(m(tri_chain,P0,P1,_,_),fail):- P0==P1.
background_knowledge(s/2,[zero/2,one/2,empty/2]).
metarules(s/2,[identity,chain]).
labelled_example(s/2,s([],[])).
labelled_example(s/2,s([0],[])).
labelled_example(s/2,s([0,0],[])).
labelled_example(s/2,s([1,1],[])).
labelled_example(s/2,s([0,0,0],[])).
labelled_example(s/2,s([0,1,1],[])).
labelled_example(s/2,s([1,0,1],[])).
labelled_example(s/2,s([1,1,0],[])).
labelled_example(s/2,s([0,0,0,0],[])).
labelled_example(s/2,s([0,0,1,1],[])).
labelled_example(s/2,s([0,1,0,1],[])).
labelled_example(s/2,s([0,1,1,0],[])).
labelled_example(s/2,s([1,0,0,1],[])).
labelled_example(s/2,s([1,0,1,0],[])).
labelled_example(s/2,s([1,1,0,0],[])).
labelled_example(s/2,s([1,1,1,1],[])).
unlabelled_example(s/2,_):- fail.
zero --> [0].
one --> [1].
empty --> [].
