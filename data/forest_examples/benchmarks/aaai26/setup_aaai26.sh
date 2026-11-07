#!/bin/bash
# Prepare working copies of the code appendix of Patsantzis, "Self-Supervised
# Inductive Logic Programming", AAAI-26, for aaai26_bench.pl.
#
# Source: https://github.com/stassa/aaai_26_experiments (commit a446fca).
# Usage: setup_aaai26.sh CHECKOUT WORKDIR
#   CHECKOUT  a clone of that repository (left unchanged)
#   WORKDIR   receives two copies, WORKDIR/cgnf and WORKDIR/lnf
#
# Each copy differs from the checkout in the two lines its README tells the
# user to edit: configuration.pl selects Poker as the learner, and
# lib/poker/poker_configuration.pl selects the experiment script (the binary
# context-free languages in cgnf, the L-systems in lnf).
set -euo pipefail
src=${1:?usage: setup_aaai26.sh CHECKOUT WORKDIR}
dst=${2:?usage: setup_aaai26.sh CHECKOUT WORKDIR}

# swap FILE OLD NEW: replace the line OLD, which must occur exactly once.
swap() {
    local n
    n=$(grep -cxF -- "$2" "$1" || true)
    if [ "$n" != 1 ]; then
        echo "$1: expected the line '$2' once, found $n" >&2
        exit 1
    fi
    awk -v old="$2" -v new="$3" '{ if ($0 == old) print new; else print }' \
        "$1" > "$1.new"
    mv "$1.new" "$1"
}

cgnf="experiment_file(data('experiments/experiment_script_binary_cgnf.pl'),binary_cgnf)."
lnf="experiment_file(data('experiments/experiment_script_lnf.pl'),exp_script_lnf)."
for s in cgnf lnf; do
    mkdir -p "$dst/$s"
    rsync -a --exclude .git "$src/" "$dst/$s/"
    swap "$dst/$s/configuration.pl" \
         "%learner(poker,lib(poker/poker))." "learner(poker,lib(poker/poker))."
    swap "$dst/$s/configuration.pl" \
         "learner(louise,lib(louise/louise))." "%learner(louise,lib(louise/louise))."
    if [ "$s" = lnf ]; then
        swap "$dst/$s/lib/poker/poker_configuration.pl" "$cgnf" "%$cgnf"
        swap "$dst/$s/lib/poker/poker_configuration.pl" "%$lnf" "$lnf"
    fi
done
echo "working copies in $dst/cgnf and $dst/lnf"
