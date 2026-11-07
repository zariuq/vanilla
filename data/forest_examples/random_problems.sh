#!/bin/bash
# Poker's generalise/3 against the forest's on the random grammar-learning
# problems in random/. Each problem draws its terminals, its metarules among
# Identity, Chain and Tri-chain, its metarule constraints, one example string
# of length 0 to 5, a clause limit of 1 to 4 and 0 to 2 invented predicates,
# with hypothesis clauses not reused. Run from anywhere, with Poker selected
# as the learner in configuration.pl; two of the problems make Poker use a
# large stack, hence --stack-limit.
cd "$(dirname "$0")/../.." || exit 1
same=0
total=0
for f in data/forest_examples/random/*.pl; do
    total=$((total + 1))
    if swipl --stack-limit=16g data/forest_examples/compare_with_poker.pl s/2 "$f" \
            < /dev/null 2> /dev/null | grep -q 'identical generalisations'; then
        same=$((same + 1))
    else
        echo "differs or fails: $f"
    fi
done
echo "$same of $total random problems: identical generalisations"
