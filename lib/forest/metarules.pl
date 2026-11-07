% The forest's metarules: mr(Id, P, Sub, Head, Body), where Sub is the
% metasubstitution sub(Id, P, Q, ...) the clause instance stands for.
:- discontiguous mr/5.

mr(identity, P, sub(identity, P, Q), m(P, X, Y), [m(Q, X, Y)]).
mr(inverse, P, sub(inverse, P, Q), m(P, X, Y), [m(Q, Y, X)]).
mr(chain, P, sub(chain, P, Q, R), m(P, X, Y), [m(Q, X, Z), m(R, Z, Y)]).
mr(tailrec, P, sub(tailrec, P, Q), m(P, X, Y), [m(Q, X, Z), m(P, Z, Y)]).
mr(tri_chain, P, sub(tri_chain, P, Q, R, S), m(P, X, Y),
   [m(Q, X, Z), m(R, Z, U), m(S, U, Y)]).
