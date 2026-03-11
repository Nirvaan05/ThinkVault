/**
 * ThinkVault Phase 2 Smoke Test
 * Runs basic API checks: register, login, logout (blocklist), lockout, RBAC.
 *
 * Usage: node test/auth.test.js
 * Requires: backend running on http://localhost:3000
 */

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

async function req(method, path, { body, token } = {}) {
    const res = await fetch(`${BASE}${path}`, {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, data };
}

function assert(label, condition, detail = '') {
    if (condition) {
        console.log(`  ✅ ${label}`);
        passed++;
    } else {
        console.error(`  ❌ ${label}${detail ? ' — ' + detail : ''}`);
        failed++;
    }
}

async function run() {
    console.log('\n🔬 ThinkVault Phase 2 Smoke Tests\n');

    // ── Health ────────────────────────────────────────────────────────────────
    console.log('▶ Health check');
    const h = await req('GET', '/health');
    assert('GET /health → 200', h.status === 200);

    // ── Register ──────────────────────────────────────────────────────────────
    console.log('\n▶ Register');
    const email = `smoketest_${Date.now()}@example.com`;
    const r = await req('POST', '/auth/register', {
        body: { name: 'Smoke Test', email, password: 'SmokeTest@1234' },
    });
    assert('POST /auth/register → 201', r.status === 201, JSON.stringify(r.data));

    // ── Login ─────────────────────────────────────────────────────────────────
    console.log('\n▶ Login');
    const l = await req('POST', '/auth/login', {
        body: { email, password: 'SmokeTest@1234' },
    });
    assert('POST /auth/login → 200', l.status === 200, JSON.stringify(l.data));
    const token = l.data?.data?.token;
    assert('Login returns JWT token', !!token);
    const userId = l.data?.data?.user?.id;
    assert('Login returns user id', !!userId);

    // ── Profile (authenticated) ───────────────────────────────────────────────
    console.log('\n▶ Profile');
    const p = await req('GET', '/auth/profile', { token });
    assert('GET /auth/profile → 200', p.status === 200, JSON.stringify(p.data));

    // ── Status ────────────────────────────────────────────────────────────────
    console.log('\n▶ Status');
    const s = await req('GET', '/auth/status', { token });
    assert('GET /auth/status → 200', s.status === 200, JSON.stringify(s.data));
    assert('Status shows is_locked=false', !s.data?.data?.is_locked);
    assert('Status shows otp_enabled=false', !s.data?.data?.otp_enabled);

    // ── Logout ────────────────────────────────────────────────────────────────
    console.log('\n▶ Logout');
    const lo = await req('POST', '/auth/logout', { token });
    assert('POST /auth/logout → 200', lo.status === 200, JSON.stringify(lo.data));

    // ── Blocklist: revoked token rejected ────────────────────────────────────
    console.log('\n▶ Token Blocklist');
    const blocked = await req('GET', '/auth/profile', { token });
    assert('Revoked token → 401', blocked.status === 401, JSON.stringify(blocked.data));

    // ── Lockout: 5 failed attempts ────────────────────────────────────────────
    console.log('\n▶ Account Lockout');
    // Register a fresh account to test lockout without polluting the above user
    const lockEmail = `locktest_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: 'Lock Test', email: lockEmail, password: 'LockTest@5678' },
    });

    let lastStatus = 0;
    for (let i = 0; i < 5; i++) {
        const f = await req('POST', '/auth/login', {
            body: { email: lockEmail, password: 'WrongPass!1' },
        });
        lastStatus = f.status;
    }
    assert('5th failed attempt triggers lockout (423)', lastStatus === 423, `got ${lastStatus}`);

    const lo6 = await req('POST', '/auth/login', {
        body: { email: lockEmail, password: 'LockTest@5678' },
    });
    assert('Locked account → 423 even with correct password', lo6.status === 423, JSON.stringify(lo6.data));

    // ── RBAC: user cannot access /admin ──────────────────────────────────────
    console.log('\n▶ RBAC');
    // Log in with a fresh user (not locked)
    const adminEmail = `rbactest_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: 'RBAC Test', email: adminEmail, password: 'Rbac@1234' },
    });
    const rl = await req('POST', '/auth/login', {
        body: { email: adminEmail, password: 'Rbac@1234' },
    });
    const userToken = rl.data?.data?.token;
    const adminHealth = await req('GET', '/admin/health', { token: userToken });
    assert('User token → /admin/health 403', adminHealth.status === 403, JSON.stringify(adminHealth.data));

    // ── No token → 401 ───────────────────────────────────────────────────────
    console.log('\n▶ Auth Guard');
    const noToken = await req('GET', '/auth/profile');
    assert('No token → 401', noToken.status === 401, JSON.stringify(noToken.data));

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err.message);
    process.exit(1);
});
