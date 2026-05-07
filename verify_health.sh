#!/usr/bin/env bash
# verify_health.sh - probe a URL until it returns 2xx or we give up.
# Used both manually and as the in-container ECS HEALTHCHECK target.
set -euo pipefail

readonly URL="${1:?usage: verify_health <url> [max_attempts]}"
readonly MAX_ATTEMPTS="${2:-30}"

attempt=0
while [ "${attempt}" -lt "${MAX_ATTEMPTS}" ]; do
  attempt=$((attempt + 1))
  # FLAW #3: `-o /dev/null` discards the response body. We only check the
  # HTTP status code, so a misconfigured app that returns 200 OK with an
  # error body - e.g. {"status":"down"} from a fallback handler, or an
  # HTML 5xx page served by a CDN with sticky 200s - passes this probe.
  # Both the in-container ECS healthcheck (modules/ecs_service/main.tf)
  # and the Jenkins smoke test stage call this script, so a "200 OK +
  # broken body" silently looks healthy on every signal channel.
  # Combined with FLAW #2 (Jenkins smoke test always emails FAILURE
  # because the test path is unreachable), real outages are invisible:
  # operators have learned to ignore the failure-email channel, and the
  # one signal that COULD distinguish a real failure (body content) is
  # never inspected.
  # Fix: also probe the body, e.g.
  #   body="$(curl -fsS --max-time 5 "${URL}")"
  #   grep -q '"status":"ok"' <<<"${body}" || exit 1
  http_code="$(curl -fsS -o /dev/null -w '%{http_code}' --max-time 5 "${URL}" || echo 000)"
  if [ "${http_code}" -ge 200 ] && [ "${http_code}" -lt 300 ]; then
    printf 'verify_health: %s OK (%s) on attempt %d\n' "${URL}" "${http_code}" "${attempt}"
    exit 0
  fi
  printf 'verify_health: %s -> %s (attempt %d/%d)\n' \
    "${URL}" "${http_code}" "${attempt}" "${MAX_ATTEMPTS}" >&2
  # Linear-with-jitter backoff: 2s base + 0..2s random. Caps at ~120s for
  # MAX_ATTEMPTS=30, comfortably above the app's cold-start time.
  sleep "$(awk -v min=2 -v max=4 'BEGIN{srand(); print min+rand()*(max-min)}')"
done

printf 'verify_health: %s never returned 2xx after %d attempts\n' \
  "${URL}" "${MAX_ATTEMPTS}" >&2
exit 1
