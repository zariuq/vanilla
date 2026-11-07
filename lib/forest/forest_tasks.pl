% The forest's front end for its own task files (data/forest_examples). A
% task defines background facts m/3 and rules bk_rule(Head, Body), the
% signature fv_sig/1, the metarules in use fv_ids/1 (from metarules.pl), the
% constraints fv_cons/1 and rank/2. Metasubstitutions are spelled
% sub(Id, P, Q, ...).

fv_metarule(Sub, Head, Body) :-
    fv_ids(Ids), member(Id, Ids), mr(Id, _P, Sub, Head, Body).

fv_bk(Lit) :- Lit = m(_, _, _), call(Lit).
fv_bk(Lit) :- bk_rule(Lit, Body), bk_body(Body).

bk_body([]).
bk_body([G|Gs]) :- bk_goal(G), bk_body(Gs).

bk_goal(G) :- G = m(_, _, _), !, bk_answers(G, L), member(G, L).
bk_goal(G) :- call(G).

fv_ok(Sub) :- fv_cons(Cs), ok_all(Cs, Sub).

ok_all([], _).
ok_all([C|Cs], S) :- check(C, S), ok_all(Cs, S).

% The constraints compare symbols by ==, so that unbound symbols pass.
check(direct, S) :- arg(2, S, P), arg(3, S, Q), \+ P == Q.
check(distinct_body, S) :-
    arg(1, S, Id),
    (   Id == chain
    ->  arg(3, S, Q), arg(4, S, R), \+ Q == R
    ;   true
    ).
