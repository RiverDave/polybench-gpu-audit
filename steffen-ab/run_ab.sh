#!/usr/bin/env bash
# Two-arm PolyBench run: control (fork trunk) then treatment (staging branch),
# rebuilding the single LLVM tree between arms. Both arms go through
# run_polybench.py unchanged.
#
#   ./run_ab.sh                 # measure both arms, keep results local
#   PUBLISH=1 ./run_ab.sh       # additionally publish each arm's summary
#   ARMS=B ./run_ab.sh          # only the treatment arm (e.g. resume after a fix)
#   LIMIT=3 ./run_ab.sh         # smoke: cap benchmarks
set -euo pipefail

ARM_A_REF=${ARM_A_REF:-cb73209ee662}                    # control: fork trunk
ARM_B_REF=${ARM_B_REF:-experiment/steffen-staging-on-trunk}  # treatment
ARMS=${ARMS:-AB}
PUBLISH=${PUBLISH:-0}
LIMIT=${LIMIT:-0}

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HARNESS=$(dirname "$HERE")
cd "$HARNESS"

extra=()
[ "$PUBLISH" = 1 ] && extra+=(--publish)
[ "$LIMIT" != 0 ] && extra+=(--limit "$LIMIT")
# Default (no --offload-merge): each arm measures CIR vs OG. The OG column is
# the unchanged-code negative control across arms; the CIR column is the arm's
# own pipeline. OFFLOAD_MERGE=1 swaps the pair to CIR vs CIR-merge.
[ "${OFFLOAD_MERGE:-0}" = 1 ] && extra+=(--offload-merge)

run_arm() {  # $1 = ref, $2 = tag
  local ref=$1 tag=$2
  "$HERE/build_llvm.sh" "$ref" "$tag"
  local sha; sha=$(cd ~/llvm-project && git rev-parse --short HEAD)
  echo "--- arm $tag: run_polybench (accurate) @ $sha ---"
  /usr/bin/python3 run_polybench.py --cuda --runtime --accurate-mode \
      --machine nvidia --log-root "temp-$tag" \
      --clang ~/llvm-project/build/bin/clang++ "${extra[@]}"
  echo "--- arm $tag done: $(ls -d temp-$tag/* 2>/dev/null | tail -1) ---"
}

[[ "$ARMS" == *A* ]] && run_arm "$ARM_A_REF" A
[[ "$ARMS" == *B* ]] && run_arm "$ARM_B_REF" B

echo
echo "summaries:"
ls -d "$HARNESS"/temp-A/* "$HARNESS"/temp-B/* 2>/dev/null || true
echo "compare:  /usr/bin/python3 $HERE/compare_arms.py"