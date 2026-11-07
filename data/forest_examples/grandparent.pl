% A grandparent problem over the family of Vanilla's kinship examples, for the
% forest's version of Louise's top program construction: father and mother as
% background facts, Identity and Chain, no invented predicates.
m(father, stathis, kostas).
m(father, stefanos, dora).
m(father, kostas, stassa).
m(mother, alexandra, kostas).
m(mother, paraskevi, dora).
m(mother, dora, stassa).

:- dynamic bk_rule/2.

fv_sig([gp]).
fv_ids([identity, chain]).
fv_cons([]).

rank(gp, 0).

pos([m(gp, stathis, stassa), m(gp, stefanos, stassa),
     m(gp, alexandra, stassa), m(gp, paraskevi, stassa)]).
neg([m(gp, stathis, kostas), m(gp, stefanos, dora), m(gp, kostas, stassa),
     m(gp, alexandra, kostas), m(gp, paraskevi, dora), m(gp, dora, stassa),
     m(gp, stassa, stathis), m(gp, stassa, stefanos),
     m(gp, stassa, alexandra), m(gp, stassa, paraskevi)]).
