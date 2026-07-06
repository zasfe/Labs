#!/usr/bin/env bash
set -euo pipefail

AUTH_FILE="${CODEX_HOME:-$HOME/.codex}/auth.json"
ENDPOINT="https://chatgpt.com/backend-api/wham/rate-limit-reset-credits"

if [[ ! -f "$AUTH_FILE" ]]; then
  printf 'error: Codex auth file not found at %s\n' "$AUTH_FILE" >&2
  exit 1
fi

readarray -t AUTH_VALUES < <(
  node - "$AUTH_FILE" <<'NODE'
const fs = require('fs');

const authPath = process.argv[2];
const auth = JSON.parse(fs.readFileSync(authPath, 'utf8'));
const tokens = auth.tokens ?? {};
const accessToken = tokens.access_token ?? tokens.accessToken;
const accountId = tokens.account_id ?? tokens.accountId ?? '';

if (!accessToken) {
  console.error(`error: missing access token in ${authPath}`);
  process.exit(1);
}

process.stdout.write(`${accessToken}\n${accountId}\n`);
NODE
)

ACCESS_TOKEN="${AUTH_VALUES[0]}"
ACCOUNT_ID="${AUTH_VALUES[1]:-}"

RESPONSE="$(
  curl_args=(
    curl -fsS
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "originator: Codex Desktop" \
    -H "OAI-Product-Sku: CODEX" \
    -H "Accept: application/json" \
  )
  if [[ -n "$ACCOUNT_ID" ]]; then
    curl_args+=(-H "ChatGPT-Account-Id: ${ACCOUNT_ID}")
  fi
  "${curl_args[@]}" "$ENDPOINT"
)"

RESPONSE_PAYLOAD="$RESPONSE" node <<'NODE'
const body = JSON.parse(process.env.RESPONSE_PAYLOAD || '{}');
const fmtLocal = new Intl.DateTimeFormat('ko-KR', {
  timeZone: 'Asia/Seoul',
  dateStyle: 'full',
  timeStyle: 'short',
});
const fmtUtc = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'UTC',
  dateStyle: 'full',
  timeStyle: 'short',
});

const credits = Array.isArray(body.credits) ? body.credits : [];
const availableCount =
  body.available_count ?? body.availableCount ?? credits.filter((credit) => String(credit?.status ?? '').toLowerCase() === 'available').length;

console.log(`available_count: ${availableCount}`);

if (credits.length === 0) {
  console.log('no reset credits returned');
  process.exit(0);
}

credits.forEach((credit, index) => {
  const title = credit?.title || '(no title)';
  const status = credit?.status || 'unknown';
  const expiresRaw = credit?.expires_at ?? credit?.expiresAt ?? null;
  const expiresText = expiresRaw ? new Date(expiresRaw).toISOString() : '(no expiry)';
  const localText = expiresRaw ? fmtLocal.format(new Date(expiresRaw)) : '(no expiry)';
  const utcText = expiresRaw ? fmtUtc.format(new Date(expiresRaw)) : '(no expiry)';

  console.log(`${index + 1}. ${title}`);
  console.log(`   status: ${status}`);
  console.log(`   expires_utc: ${expiresText}`);
  console.log(`   expires_local: ${localText}`);
  console.log(`   expires_utc_pretty: ${utcText}`);
});
NODE
