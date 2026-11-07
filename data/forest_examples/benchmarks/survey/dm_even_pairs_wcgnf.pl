% A task for Poker's generalisation step, as a Vanilla experiment file.
% Source: the task even_pairs of Deletang et al., Neural Networks and the
% Chomsky Hierarchy (ICLR 2023), https://github.com/google-deepmind/
% neural_networks_chomsky_hierarchy, commit 2b8eb4b. That repository samples
% its training strings at random; this file fixes a sample.
% Conversion: the class-0 strings as the language of a grammar nonterminal
% s(String, []), each terminal a background grammar rule t([t|R], R), and the
% metarules Identity, Chain and Tri-Chain as the rules P -> Q, P -> Q R and
% P -> Q R S. Labelled examples: all 17 class-0 strings of length 0
% to 4 (the first symbol equals the last).
% Metarule constraints: Poker's weak Chomsky-Greibach normal form.
% Settings (set_configs/0): no hypothesis reuse (fetch_clauses without
% hypothesis), Vanilla untabled, and the clause limit and max_invented set
% there. With Poker selected in configuration.pl, from Vanilla's root:
%   swipl data/forest_examples/compare_with_poker.pl s/2 \
%       data/forest_examples/benchmarks/survey/dm_even_pairs_wcgnf.pl

:-module(dm_even_pairs_wcgnf, [background_knowledge/2, metarules/2, labelled_example/2, unlabelled_example/2, set_configs/0, zero/2, one/2, empty/2]).
:-use_module(project_root(configuration)).
:-use_module(lib(poker/poker_auxiliaries)).
:-use_module(lib(poker/poker_configuration)).
:-use_module(lib(poker/normal_forms/weak_chomsky_greibach_nf)).
% DeepMind neural_networks_chomsky_hierarchy task even_pairs, posed as a recogniser of its class-0 strings, with Poker's weak C-GNF constraints.
set_configs:-
  poker_auxiliaries:set_configuration_option(fetch_clauses,[[builtins,bk,metarules]])
  ,poker_auxiliaries:set_configuration_option(table_meta_interpreter,[false])
  ,poker_auxiliaries:set_configuration_option(untable_meta_interpreter,[true])
  ,poker_auxiliaries:set_poker_configuration_option(unfold_invented,[none])
  ,poker_auxiliaries:set_poker_configuration_option(clause_limit,[4])
  ,poker_auxiliaries:set_poker_configuration_option(max_invented,[1]).
background_knowledge(s/2,[zero/2,one/2,empty/2]).
metarules(s/2,[identity,chain,tri_chain]).
labelled_example(s/2,s([],[])).
labelled_example(s/2,s([0],[])).
labelled_example(s/2,s([1],[])).
labelled_example(s/2,s([0,0],[])).
labelled_example(s/2,s([1,1],[])).
labelled_example(s/2,s([0,0,0],[])).
labelled_example(s/2,s([0,1,0],[])).
labelled_example(s/2,s([1,0,1],[])).
labelled_example(s/2,s([1,1,1],[])).
labelled_example(s/2,s([0,0,0,0],[])).
labelled_example(s/2,s([0,0,1,0],[])).
labelled_example(s/2,s([0,1,0,0],[])).
labelled_example(s/2,s([0,1,1,0],[])).
labelled_example(s/2,s([1,0,0,1],[])).
labelled_example(s/2,s([1,0,1,1],[])).
labelled_example(s/2,s([1,1,0,1],[])).
labelled_example(s/2,s([1,1,1,1],[])).
unlabelled_example(s/2,_):- fail.
zero --> [0].
one --> [1].
empty --> [].
weak_cgnf:target(s).
weak_cgnf:invented(inv_1).
weak_cgnf:preterminal(zero).
weak_cgnf:preterminal(one).
weak_cgnf:preterminal(empty).
