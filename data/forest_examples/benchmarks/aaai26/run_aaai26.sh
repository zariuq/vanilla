#!/bin/bash
# The benchmark of Poker against the provenance forest on the experiments of
# Patsantzis, "Self-Supervised Inductive Logic Programming", AAAI-26
# (https://github.com/stassa/aaai_26_experiments), as reported in
# lib/forest/provenance_forest.tex.
#
# Usage: run_aaai26.sh WORKDIR OUTDIR JOBS PROTOCOL [LANG ...]
#   WORKDIR   the working copies made by setup_aaai26.sh
#   OUTDIR    receives LANG.PROTOCOL.rows and LANG.PROTOCOL.err
#   JOBS      languages run in parallel
#   PROTOCOL  gen      every iteration of the range, seeds 1-5, generalise/3
#             learn    iterations 1 and the last, the least and greatest
#                      number of generated examples, seeds 1-3, learn/7
#             readoff  iterations 1 and 2 (Sierpinski: 3 and 6, the first
#                      whose examples have refutations), seeds 1-2, every
#                      clause limit and max_invented up to the language's own
#             tune     the calibration experiment, seed 1, the deepening up
#                      to one more than the language's clause limit (default
#                      languages: all but Hilbert and Sierpinski, whose
#                      candidates take minutes each)
#   LANG      languages (default: all ten)
# Time limits: 600 s per generalisation (gen, readoff), 1200 s per learn/7
# (learn), 300 s per learn/7 (tune).
set -euo pipefail
work=${1:?usage}; out=${2:?usage}; jobs=${3:?usage}; protocol=${4:?usage}
shift 4
bench="$(cd "$(dirname "$0")" && pwd)/aaai26_bench.pl"
langs=("$@")
if [ ${#langs[@]} -eq 0 ]; then
    langs=(hilbert_curve_no_tabling sierpinski_triangle parens_bin
           palindrome_bin koch_curve dragon_curve even_bin anbn_bin
           anbn_uo_bin anbm_bin)
    if [ "$protocol" = tune ]; then
        langs=(anbn_bin even_bin anbm_bin anbn_uo_bin parens_bin
               palindrome_bin dragon_curve koch_curve)
    fi
fi
case "$protocol" in
    gen)     args=(gen LANG all '[1,2,3,4,5]' 600) ;;
    learn)   args=(learn LANG '[1,last]' '[min,max]' '[1,2,3]' 1200) ;;
    readoff) args=(readoff LANG ITERS '[1,2]' 600 her 0) ;;
    tune)    args=(tune LANG '[1]' 300 her+1) ;;
    *) echo "unknown protocol $protocol" >&2; exit 1 ;;
esac
mkdir -p "$out"
one() {
    local lang=$1 copy
    case "$lang" in
        dragon_curve|hilbert_curve_no_tabling|koch_curve|sierpinski_triangle)
            copy=lnf ;;
        *) copy=cgnf ;;
    esac
    local iters='[1,2]'
    if [ "$lang" = sierpinski_triangle ]; then
        iters='[3,6]'
    fi
    local a=("${args[@]/LANG/$lang}")
    swipl "$bench" "$work/$copy" "${a[@]/ITERS/$iters}" \
        > "$out/$lang.$protocol.rows" 2> "$out/$lang.$protocol.err"
}
for lang in "${langs[@]}"; do
    while [ "$(jobs -rp | wc -l)" -ge "$jobs" ]; do
        wait -n || true
    done
    one "$lang" &
done
wait
