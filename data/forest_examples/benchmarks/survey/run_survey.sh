#!/bin/bash
# Poker's generalise/3 against the forest's on the task files in this
# directory (each states its source and conversion in its header) and on the
# hypothesis-reuse settings of Poker's own experiments, with
# data/forest_examples/compare_with_poker.pl. Run with Poker selected as the
# learner in configuration.pl, learner(poker,lib(poker/poker)). Some of
# Poker's refutation searches here need a large stack, hence --stack-limit.
# Usage: run_survey.sh [SECONDS]  (each comparison limited to SECONDS, 200)
limit=${1:-200}
cd "$(dirname "$0")/../../../.." || exit 1
if ! grep -qx 'learner(poker,lib(poker/poker)).' configuration.pl; then
    echo "Select Poker in configuration.pl: learner(poker,lib(poker/poker))." >&2
    exit 2
fi
dir=data/forest_examples/benchmarks/survey
compare() { # label target file [option ...]
    local label=$1
    shift
    local out
    out=$(timeout "$limit" swipl --stack-limit=16g \
              data/forest_examples/compare_with_poker.pl "$@" \
              < /dev/null 2> /dev/null)
    local poker forest verdict
    poker=$(grep -o 'poker: .*' <<< "$out")
    forest=$(grep -o 'forest: .*' <<< "$out")
    if grep -q 'identical generalisations' <<< "$out"; then
        verdict=identical
    elif grep -q DIFFERENT <<< "$out"; then
        verdict=DIFFERENT
    elif grep -q 'NOT COMPARED' <<< "$out"; then
        verdict="not compared (exception)"
    else
        verdict="not finished in $limit s"
    fi
    printf '%s | %s | %s | %s\n' "$label" "$verdict" "${poker:--}" "${forest:--}"
}
for spec in dm_reverse_string:s/2 dm_parity_check:s/2 dm_even_pairs_wcgnf:s/2 \
            dm_reverse_string_wcgnf:s/2 dm_cycle_navigation_wcgnf:s/2 \
            dm_parity_check_wcgnf:s/2 popper_robots_linear:f/2 \
            louise_even_odd:even/1 popper_kinship_pi:grandparent/2 \
            popper_andersen:pt/2 hopper_member:f/2 \
            popper_kinship_ancestor:ancestor/2 inverse_probe:child/2 \
            dm_cycle_navigation:s/2 dm_even_pairs:s/2 \
            popper_robots_recursion:f/2; do
    compare "${spec%%:*}" "${spec#*:}" "$dir/${spec%%:*}.pl"
done
# Poker's own settings with hypothesis reuse.
compare hello_world_reuse p/2 data/poker_examples/hello_world_poker.pl
cgnf=data/poker_examples/experiment_script_cgnf.pl
compare cgnf_anbn_reuse s/2 $cgnf lang=anbn 'gen=anbn(all,0,6)'
compare cgnf_anbm_reuse s/2 $cgnf lang=anbm 'gen=anbm(all,0,3)'
compare cgnf_even_reuse q0/2 $cgnf lang=even 'gen=even(all,0,4)'
compare cgnf_parens_reuse p/2 $cgnf lang=parens 'gen=parens(all,0,6)'
