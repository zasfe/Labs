#!/usr/bin/env bash
set -euo pipefail

MODE="dry-run"

usage() {
  cat <<'EOF'
Usage:
  codex-reset-credits.sh [--dry-run]
  codex-reset-credits.sh --execute

Default:
  --dry-run  실제 reset credit 소비 없음

Options:
  --execute  확인 입력 후 가장 빨리 만료되는 reset credit 실제 소비
  -h, --help 도움말 표시
EOF
}

case "${1:-}" in
  ""|--dry-run)
    MODE="dry-run"
    ;;
  --execute)
    MODE="execute"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    printf 'error: unknown option: %s\n\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac

if ! command -v codex >/dev/null 2>&1; then
  printf 'error: codex command not found\n' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  printf 'error: node command not found\n' >&2
  exit 1
fi

exec 4<&0
RESET_MODE="$MODE" node 4<&4 <<'NODE'
const { spawn } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const readline = require('readline');

const mode = process.env.RESET_MODE || 'dry-run';
const kstFormatter = new Intl.DateTimeFormat('ko-KR', {
  timeZone: 'Asia/Seoul',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false,
});

const proc = spawn('codex', ['app-server'], {
  stdio: ['pipe', 'pipe', 'pipe'],
});

const serverLines = readline.createInterface({ input: proc.stdout });
const serverErrors = readline.createInterface({ input: proc.stderr });
const userInput = readline.createInterface({
  input: fs.createReadStream('', { fd: 4, autoClose: false }),
  output: process.stdout,
});
const pending = new Map();
const queuedAnswers = [];

let nextId = 0;

function send(method, params, timeoutMs = 60000) {
  const id = nextId++;
  const payload = { method, id };
  if (params !== undefined) {
    payload.params = params;
  }
  proc.stdin.write(`${JSON.stringify(payload)}\n`);

  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`timeout waiting for ${method}`));
    }, timeoutMs);

    pending.set(id, (message) => {
      clearTimeout(timer);
      if (message.error) {
        reject(new Error(`${method} failed: ${JSON.stringify(message.error)}`));
        return;
      }
      resolve(message.result);
    });
  });
}

function notify(method, params) {
  const payload = { method };
  if (params !== undefined) {
    payload.params = params;
  }
  proc.stdin.write(`${JSON.stringify(payload)}\n`);
}

serverLines.on('line', (line) => {
  let message;
  try {
    message = JSON.parse(line);
  } catch (error) {
    return;
  }

  if (message.id !== undefined && pending.has(message.id)) {
    const complete = pending.get(message.id);
    pending.delete(message.id);
    complete(message);
  }
});

serverErrors.on('line', (line) => {
  if (/error|warn|unauth|login|rate/i.test(line)) {
    process.stderr.write(`${line}\n`);
  }
});

let inputClosed = false;
userInput.on('line', (line) => {
  queuedAnswers.push(line.trim());
});
userInput.on('close', () => {
  inputClosed = true;
});

function question(prompt) {
  return new Promise((resolve) => {
    process.stdout.write(prompt);
    if (queuedAnswers.length > 0) {
      const answer = queuedAnswers.shift();
      process.stdout.write(`${answer}\n`);
      resolve(answer);
      return;
    }
    if (inputClosed) {
      process.stdout.write('\n');
      resolve('');
      return;
    }
    userInput.once('line', (answer) => resolve(answer.trim()));
    userInput.once('close', () => resolve(''));
  });
}

function asDateText(epochSeconds) {
  if (epochSeconds === null || epochSeconds === undefined) {
    return '(만료 없음)';
  }
  return `${kstFormatter.format(new Date(epochSeconds * 1000))} KST`;
}

function getAvailableCredits(snapshot) {
  const credits = snapshot?.rateLimitResetCredits?.credits;
  if (!Array.isArray(credits)) {
    return [];
  }
  return credits
    .filter((credit) => credit && credit.status === 'available')
    .sort((a, b) => {
      const aExpires = a.expiresAt ?? Number.MAX_SAFE_INTEGER;
      const bExpires = b.expiresAt ?? Number.MAX_SAFE_INTEGER;
      return aExpires - bExpires;
    });
}

function formatPercent(value) {
  return value === null || value === undefined ? '(정보 없음)' : `${value}%`;
}

function printRateLimits(snapshot, label) {
  const primary = snapshot?.rateLimits?.primary;
  const secondary = snapshot?.rateLimits?.secondary;
  const credits = snapshot?.rateLimitResetCredits;

  console.log('');
  console.log(`[${label}]`);
  console.log(`Weekly limit 사용률: ${formatPercent(primary?.usedPercent)}`);
  console.log(`Weekly reset 시각: ${asDateText(primary?.resetsAt)}`);

  if (secondary) {
    console.log(`5-hour limit 사용률: ${formatPercent(secondary.usedPercent)}`);
    console.log(`5-hour reset 시각: ${asDateText(secondary.resetsAt)}`);
  } else {
    console.log('5-hour limit: 응답에 없음');
  }

  console.log(`남은 reset credit 수: ${credits?.availableCount ?? 0}`);
}

function printCredits(snapshot, label) {
  const available = getAvailableCredits(snapshot);

  console.log('');
  console.log(`[${label}]`);

  if (available.length === 0) {
    console.log('사용 가능한 reset credit 없음');
    return;
  }

  available.forEach((credit, index) => {
    console.log(`${index + 1}. ${credit.title || '(제목 없음)'}`);
    console.log(`   id: ${credit.id}`);
    console.log(`   status: ${credit.status || 'unknown'}`);
    console.log(`   resetType: ${credit.resetType || 'unknown'}`);
    console.log(`   grantedAt: ${asDateText(credit.grantedAt)}`);
    console.log(`   expiresAt: ${asDateText(credit.expiresAt)}`);
    if (credit.description) {
      console.log(`   description: ${credit.description}`);
    }
  });
}

async function main() {
  await send('initialize', {
    clientInfo: {
      name: 'codex_reset_credits_script',
      title: 'Codex Reset Credits Script',
      version: '0.1.0',
    },
    capabilities: {
      experimentalApi: true,
    },
  });
  notify('initialized', {});

  const before = await send('account/rateLimits/read', null);
  const available = getAvailableCredits(before);
  const selected = available[0];

  printRateLimits(before, '현재 사용량');
  printCredits(before, '사용 가능한 reset credit 목록');

  if (!selected) {
    process.exitCode = 0;
    return;
  }

  console.log('');
  console.log('[선택 예정]');
  console.log(`가장 먼저 만료되는 credit: ${selected.id}`);
  console.log(`만료 시각: ${asDateText(selected.expiresAt)}`);

  if (mode !== 'execute') {
    console.log('');
    console.log('[dry-run]');
    console.log('실제 초기화 호출 생략');
    console.log('실제 사용 시: codex-reset-credits.sh --execute');
    return;
  }

  const answer = await question('위 reset credit을 실제로 사용하시겠습니까? reset 입력 시 진행: ');
  if (answer !== 'reset') {
    console.log('취소됨');
    return;
  }

  const idempotencyKey = crypto.randomUUID();
  const consume = await send('account/rateLimitResetCredit/consume', {
    idempotencyKey,
    creditId: selected.id,
  });

  console.log('');
  console.log('[초기화 결과]');
  console.log(`outcome: ${consume.outcome}`);
  console.log(`idempotencyKey: ${idempotencyKey}`);

  const after = await send('account/rateLimits/read', null);
  printRateLimits(after, '초기화 후 사용량');
  printCredits(after, '남은 reset credit 목록');
}

main()
  .catch((error) => {
    console.error(`error: ${error.message}`);
    process.exitCode = 1;
  })
  .finally(() => {
    userInput.close();
    proc.kill('SIGTERM');
  });
NODE
