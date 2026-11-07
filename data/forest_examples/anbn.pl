% Poker's a^n b^n experiment (data/poker_examples/anbn_poker.pl) for the
% forest: the terminals a, b and empty as background facts, the metarules
% Identity and Chain, the target s with one invented predicate, and the
% experiment's metarule constraints (no Identity or Chain with P = Q, no Chain
% with Q = R).
m(a, [a|T], T).
m(b, [b|T], T).
m(empty, X, X).

:- dynamic bk_rule/2.

fv_sig([s, inv_1]).
fv_ids([identity, chain]).
fv_cons([direct, distinct_body]).

rank(s, 0).
rank(inv_1, 1).

% ex(+N, -Example): the example s(a^n b^n, []).
ex(N, m(s, W, [])) :-
    length(As, N), maplist(=(a), As),
    length(Bs, N), maplist(=(b), Bs),
    append(As, Bs, W).
