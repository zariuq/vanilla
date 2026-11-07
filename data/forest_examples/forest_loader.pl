% Loads the forest and a task into the module forest, so that its m/3 and
% generalise/3 stay apart from Vanilla's.
:- prolog_load_context(directory, Dir),
   asserta(user:file_search_path(forest_examples, Dir)).

user:file_search_path(forest, forest_examples('../../lib/forest')).

% load_forest(+Memo, +Task): Memo is assert (memo tables as asserted facts
% keyed by term hash) or table (SWI-Prolog tabling); Task is a file in this
% directory.
load_forest(Memo, Task) :-
    atom_concat(memo_, Memo, MemoFile),
    load_files(forest:[forest(forest), forest(forest_tasks), forest(MemoFile),
                       forest(metarules), forest_examples(Task)],
               [if(true)]).
