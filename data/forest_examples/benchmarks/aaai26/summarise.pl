/*  Summaries of the rows aaai26_bench.pl prints.

    swipl summarise.pl gen FILE ...       per language and per iteration
    swipl summarise.pl learn FILE ...     Poker's learn/7, Vanilla against forest
    swipl summarise.pl readoff FILE ...   read-off against direct runs
    swipl summarise.pl tune FILE ...      the iterative deepening

    Times are CPU milliseconds; medians are over the seeds (and iterations,
    where a line covers several). A ratio is Poker's time over the forest's.
*/

:- module(summarise, []).

:- initialization(main, main).

:- discontiguous summary/2.

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(aggregate)).

main :-
    current_prolog_flag(argv, [What|Files]),
    maplist(read_rows, Files, Rowss),
    append(Rowss, Rows),
    summary(What, Rows).

read_rows(File, Rows) :-
    setup_call_cleanup(open(File, read, S), read_terms(S, Rows), close(S)).

% Lines that are not row terms (the repository's load messages) are skipped.
read_terms(S, Rows) :-
    read_line_to_string(S, Line),
    (   Line == end_of_file
    ->  Rows = []
    ;   (   sub_string(Line, 0, _, _, "row("),
            catch(term_string(T, Line), _, fail)
        ->  Rows = [T|Rest]
        ;   Rows = Rest
        ),
        read_terms(S, Rest)
    ).

median(Xs, M) :-
    msort(Xs, S),
    length(S, N),
    (   N =:= 0
    ->  M = '-'
    ;   N mod 2 =:= 1
    ->  I is N // 2, nth0(I, S, M)
    ;   I is N // 2 - 1, nth0(I, S, A), J is I + 1, nth0(J, S, B),
        M is (A + B) / 2
    ).

ms(X, A) :- number(X), !, format(atom(A), "~2f", [X]).
ms(X, X).

ratio(P, F, A) :- number(P), number(F), F > 0, !, R is P / F,
    format(atom(A), "~2f", [R]).
ratio(_, _, '-').

% ---------- the generalisation step ----------

summary(gen, Rows) :-
    findall(L, member(row(gen, L, _, _, _, _, _, _, _), Rows), Ls0),
    sort(Ls0, Ls),
    format("~w~t~28|~w~t~34|~w~t~40|~w~t~47|~w~t~56|~w~t~68|~w~t~80|~w~t~90|~w~n",
           [language, iter, l, rows, agree, 'Poker med', 'forest med',
            ratio, 'subhyps']),
    forall(member(L, Ls), gen_language(L, Rows)),
    format("~nPer language, all iterations and seeds:~n"),
    format("~w~t~28|~w~t~35|~w~t~42|~w~t~55|~w~t~68|~w~t~80|~w~t~92|~w~n",
           [language, rows, agree, 'Poker total', 'forest total',
            'ratio tot', 'ratio min', 'ratio max']),
    forall(member(L, Ls), gen_total(L, Rows)).

gen_language(L, Rows) :-
    findall(I, member(row(gen, L, I, _, _, _, _, _, _), Rows), Is0),
    sort(Is0, Is),
    forall(member(I, Is),
           (   findall(r(NL, P, F, PN, V),
                       ( member(row(gen, L, I, _, _, NL,
                                    poker(_, PN, cost(P, _, _)),
                                    forest(_, _, cost(F, _, _)), V), Rows) ),
                       Rs),
               length(Rs, N),
               include(agrees, Rs, Ag), length(Ag, NA),
               maplist([r(NL, _, _, _, _), NL]>>true, Rs, NLs), median(NLs, NLm),
               maplist([r(_, P, _, _, _), P]>>true, Rs, Ps), median(Ps, Pm),
               maplist([r(_, _, F, _, _), F]>>true, Rs, Fs), median(Fs, Fm),
               maplist([r(_, _, _, PN, _), PN]>>true, Rs, PNs),
               include(number, PNs, PNn),
               (   PNn == []
               ->  Sub = '-'
               ;   min_list(PNn, Lo), max_list(PNn, Hi),
                   format(atom(Sub), "~w-~w", [Lo, Hi])
               ),
               ms(Pm, PA), ms(Fm, FA), ratio(Pm, Fm, RA),
               format("~w~t~28|~w~t~34|~w~t~40|~w~t~47|~w~t~56|~w~t~68|~w~t~80|~w~t~90|~w~n",
                      [L, I, NLm, N, NA, PA, FA, RA, Sub])
           )).

agrees(r(_, _, _, _, identical)).
agrees(r(_, _, _, _, both_failed)).

gen_total(L, Rows) :-
    findall(P-F-V, member(row(gen, L, _, _, _, _, poker(_, _, cost(P, _, _)),
                              forest(_, _, cost(F, _, _)), V), Rows), Rs),
    length(Rs, N),
    aggregate_all(count, ( member(_-_-V, Rs),
                           memberchk(V, [identical, both_failed]) ), NA),
    aggregate_all(sum(P), member(P-_-_, Rs), PT),
    aggregate_all(sum(F), member(_-F-_, Rs), FT),
    findall(R, ( member(P-F-_, Rs), F > 0, R is P / F ), Ratios),
    min_list(Ratios, RMin), max_list(Ratios, RMax),
    ms(PT, PTA), ms(FT, FTA), ratio(PT, FT, RTA), ms(RMin, RMinA), ms(RMax, RMaxA),
    format("~w~t~28|~w~t~35|~w~t~42|~w~t~55|~w~t~68|~w~t~80|~w~t~92|~w~n",
           [L, N, NA, PTA, FTA, RTA, RMinA, RMaxA]).

% ---------- Poker's learn/7 ----------

summary(learn, Rows) :-
    format("~w~t~28|~w~t~33|~w~t~39|~w~t~46|~w~t~53|~w~t~66|~w~t~79|~w~t~92|~w~t~105|~w~n",
           [language, iter, gen, rows, agree, 'learn V', 'learn F',
            'gen V', 'gen F', 'correct']),
    findall(L-I-G, member(row(learn, L, I, _, _, G, _, _, _), Rows), Ks0),
    sort(Ks0, Ks),
    forall(member(L-I-G, Ks), learn_line(L, I, G, Rows)).

learn_line(L, I, G, Rows) :-
    findall(r(VC, FC, VG, FG, V, Ev),
            member(row(learn, L, I, _, _, G,
                       vanilla(_, _, cost(VC, _, _), VG, Ev),
                       forest(_, _, cost(FC, _, _), FG, _), V), Rows),
            Rs),
    length(Rs, N),
    aggregate_all(count, member(r(_, _, _, _, identical, _), Rs), NA),
    aggregate_all(count, ( member(r(_, _, _, _, _, eval(A, _, _, _, _)), Rs),
                           A =:= 1 ), NC),
    maplist([r(X, _, _, _, _, _), X]>>true, Rs, VCs), median(VCs, VCm),
    maplist([r(_, X, _, _, _, _), X]>>true, Rs, FCs), median(FCs, FCm),
    maplist([r(_, _, X, _, _, _), X]>>true, Rs, VGs), median(VGs, VGm),
    maplist([r(_, _, _, X, _, _), X]>>true, Rs, FGs), median(FGs, FGm),
    maplist(ms, [VCm, FCm, VGm, FGm], [A1, A2, A3, A4]),
    format("~w~t~28|~w~t~33|~w~t~39|~w~t~46|~w~t~53|~w~t~66|~w~t~79|~w~t~92|~w~t~105|~w/~w~n",
           [L, I, G, N, NA, A1, A2, A3, A4, NC, N]).

% ---------- read-off ----------

summary(readoff, Rows) :-
    findall(L, member(row(readoff, L, _, _, _, _, _, _, _, _, _), Rows), Ls0),
    sort(Ls0, Ls),
    format("~w~t~28|~w~t~36|~w~t~46|~w~t~58|~w~t~70|~w~t~82|~w~t~96|~w~t~110|~w~n",
           [language, cells, 'agree R=F', 'agree F=P', 'family ms',
            'readoff ms', 'forest ms', 'Poker ms', 'clause limit 1']),
    forall(member(L, Ls), readoff_line(L, Rows)).

readoff_line(L, Rows) :-
    findall(V1-V2-RC, member(row(readoff, L, _, _, _, _, readoff(_, _, cost(RC, _, _)),
                                 _, _, readoff_vs_forest(V1),
                                 forest_vs_poker(V2)), Rows), Cs),
    aggregate_all(sum(FC), member(row(readoff, L, _, _, _, _, _,
                                      forest(_, _, cost(FC, _, _)), _, _, _), Rows), FDT),
    aggregate_all(sum(PC), member(row(readoff, L, _, _, _, _, _, _,
                                      poker(_, _, cost(PC, _, _)), _, _), Rows), PDT),
    length(Cs, N),
    aggregate_all(count, ( member(V1-_-_, Cs),
                           memberchk(V1, [identical, both_failed]) ), N1),
    aggregate_all(count, ( member(_-V2-_, Cs),
                           memberchk(V2, [identical, both_failed]) ), N2),
    aggregate_all(sum(RC), member(_-_-RC, Cs), RT),
    findall(FC, member(row(family, L, _, _, _, _, family(ok, _, cost(FC, _, _))), Rows), FCs),
    sum_list(FCs, FT),
    findall(V, member(row(clause_limit_one, L, _, _, _, _, V), Rows), Vs),
    msort(Vs, VsS), clumped_pairs(VsS, One),
    maplist(ms, [FT, RT, FDT, PDT], [FA, RA, FDA, PDA]),
    format("~w~t~28|~w~t~36|~w~t~46|~w~t~58|~w~t~70|~w~t~82|~w~t~96|~w~t~110|~w~n",
           [L, N, N1, N2, FA, RA, FDA, PDA, One]).

clumped_pairs(Xs, Ps) :- clumped(Xs, Ps).

% ---------- the iterative deepening ----------

summary(tune, Rows) :-
    format("~w~t~28|~w~t~33|~w~t~39|~w~t~44|~w~t~53|~w~t~67|~w~t~81|~w~t~95|~w~n",
           [language, iter, gen, seed, mode, found, 'total ms',
            'gen ms', steps]),
    forall(member(row(tune, L, I, _, Seed, G, Mode, Found, total(T, GT), Steps), Rows),
           (   found_atom(Found, FA),
               length(Steps, NS),
               maplist(ms, [T, GT], [TA, GA]),
               format("~w~t~28|~w~t~33|~w~t~39|~w~t~44|~w~t~53|~w~t~67|~w~t~81|~w~t~95|~w~n",
                      [L, I, G, Seed, Mode, FA, TA, GA, NS])
           )),
    forall(member(row(tune_agreement, L, I, Seed, G, V), Rows),
           format("agreement ~w ~w seed ~w gen ~w: ~w~n", [L, I, Seed, G, V])).

found_atom(found(K, M, _), A) :- !, format(atom(A), "(~w,~w)", [K, M]).
found_atom(stopped(K, M, St), A) :- !,
    (   St = error(_) -> S = error ; S = St ),
    format(atom(A), "~w(~w,~w)", [S, K, M]).
found_atom(none, none).
