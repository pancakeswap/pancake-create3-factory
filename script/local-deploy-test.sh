#!/usr/bin/env bash
# Run the Create3Factory deploy script against a local anvil and verify the result matches bsc.
#
# Requirements:
#   - PRIVATE_KEY in .env must be the original deployer (0xDB1fa6562f3784643c1b547b17dcAEDE0b79CA80)
#   - foundry (anvil / cast / forge) installed
#
# Usage (from repo root):
#   ./script/local-deploy-test.sh
#   ./script/local-deploy-test.sh --dry-run   # simulate only, no --broadcast
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PORT="${ANVIL_PORT:-8546}"
RPC="http://127.0.0.1:${PORT}"
DEPLOYER=0xDB1fa6562f3784643c1b547b17dcAEDE0b79CA80
EXPECTED_FACTORY=0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1
EXPECTED_HASH=0x062e0b9e0e28785406fcd3ea3efde49e1d40668774057ec7ba53f120d0809763
SANITY_SALT=0x0000000000000000000000000000000000000000000000000000000000001234
EXPECTED_SANITY_ADDRESS=0xC9025a31E39f73AD2B0c7Ce16cceC6A3416e52E0

BROADCAST="--broadcast"
if [[ "${1:-}" == "--dry-run" ]]; then
  BROADCAST=""
fi

# ---------------------------------------------------------------- helpers
info() { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[fail]\033[0m %s\n' "$*"; exit 1; }

assert_eq() { # actual expected label
  local actual expected
  actual="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  expected="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  if [[ "$actual" == "$expected" ]]; then
    ok "$3: $1"
  else
    fail "$3 mismatch: got $1, expected $2"
  fi
}

# ---------------------------------------------------------------- pre-checks
[[ -f .env ]] || fail ".env not found in $ROOT_DIR"
grep -qE '^PRIVATE_KEY=0x[0-9a-fA-F]{64}' .env || fail "PRIVATE_KEY (0x-prefixed) not found in .env"
set -a; # shellcheck disable=SC1091
source .env; set +a

assert_eq "$(cast wallet address --private-key "$PRIVATE_KEY")" "$DEPLOYER" "PRIVATE_KEY belongs to deployer"

if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  fail "port $PORT already in use, stop the existing anvil or set ANVIL_PORT"
fi

# ---------------------------------------------------------------- start anvil
info "starting anvil on port $PORT"
anvil -p "$PORT" --silent &
ANVIL_PID=$!
trap 'info "stopping anvil (pid $ANVIL_PID)"; kill "$ANVIL_PID" 2>/dev/null || true' EXIT

for _ in $(seq 1 20); do
  cast chain-id -r "$RPC" >/dev/null 2>&1 && break
  sleep 0.5
done
cast chain-id -r "$RPC" >/dev/null 2>&1 || fail "anvil did not start"

info "funding deployer with 10 ETH"
cast rpc anvil_setBalance "$DEPLOYER" 0x8AC7230489E80000 -r "$RPC" >/dev/null
assert_eq "$(cast nonce "$DEPLOYER" -r "$RPC")" "0" "deployer nonce"

# ---------------------------------------------------------------- run script
info "running deploy script ${BROADCAST:-(dry run)}"
forge script script/01_DeployCreate3Factory.s.sol:DeployCreate3FactoryScript -vvv \
  --rpc-url "$RPC" \
  $BROADCAST

# ---------------------------------------------------------------- verify
if [[ -z "$BROADCAST" ]]; then
  ok "dry run finished, skip on-chain verification"
  exit 0
fi

info "verifying deployed factory against bsc reference values"
CODE_LEN=$(cast code "$EXPECTED_FACTORY" -r "$RPC" | wc -c | tr -d ' ')
[[ "$CODE_LEN" -gt 3 ]] || fail "no code at $EXPECTED_FACTORY"
ok "factory has code at $EXPECTED_FACTORY"

assert_eq "$(cast call "$EXPECTED_FACTORY" 'owner()(address)' -r "$RPC")" "$DEPLOYER" "owner()"
assert_eq "$(cast call "$EXPECTED_FACTORY" 'computeAddress(bytes32)(address)' "$SANITY_SALT" -r "$RPC")" \
  "$EXPECTED_SANITY_ADDRESS" "computeAddress(0x1234)"
assert_eq "$(forge inspect CustomizedProxyChild bytecode | cast keccak)" "$EXPECTED_HASH" "KECCAK256_PROXY_CHILD_BYTECODE"

ok "local deployment matches bsc"
