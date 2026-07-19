#!/usr/bin/env bash
set -euo pipefail

# §12.1: visual literals may only live in lib/design. The debounce below is
# domain timing rather than visual motion and is deliberately excluded.
matches=$(rg -n 'Color\(0x|Colors\.|BorderRadius\.circular|Curves\.|Duration\(' lib \
  --glob '*.dart' \
  -g '!lib/design/**' \
  -g '!lib/presentation/blocs/tide_bloc.dart' || true)

if [[ -n "$matches" ]]; then
  echo "Design token lint failed:\n$matches"
  exit 1
fi

echo 'Design token lint passed.'
