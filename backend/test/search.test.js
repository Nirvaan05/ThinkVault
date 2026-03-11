/**
 * ThinkVault Phase 4 Smoke Test — Organization and Search
 * Tests categories, tags, note assignment, full-text search, and filter queries.
 *
 * Usage: node test/search.test.js
 * Requires: backend running on http://localhost:3000
 */

const BASE = 'http://localhost:3000/api';
let passed = 0;
let failed = 0;

async function req(method, path, { body, token, query } = {}) {
    let url = `${BASE}${path}`;
    if (query) url += '?' + new URLSearchParams(query).toString();
    const res = await fetch(url, {
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

async function makeUser(suffix) {
    const email = `search_${suffix}_${Date.now()}@example.com`;
    await req('POST', '/auth/register', {
        body: { name: `Search ${suffix}`, email, password: 'Search@Test123' },
    });
    const r = await req('POST', '/auth/login', {
        body: { email, password: 'Search@Test123' },
    });
    return { token: r.data?.data?.token, userId: r.data?.data?.user?.id };
}

async function run() {
    console.log('\n🔬 ThinkVault Phase 4 Smoke Tests — Organization and Search\n');

    // ── Setup ─────────────────────────────────────────────────────────────────
    console.log('▶ Setup: two test users');
    const userA = await makeUser('A');
    const userB = await makeUser('B');
    assert('User A logged in', !!userA.token);
    assert('User B logged in', !!userB.token);

    // ── Categories CRUD ───────────────────────────────────────────────────────
    console.log('\n▶ Categories');
    const catCreate = await req('POST', '/categories', {
        token: userA.token,
        body: { name: 'Work' },
    });
    assert('POST /categories → 201', catCreate.status === 201, JSON.stringify(catCreate.data));
    const catId = catCreate.data?.data?.id;
    assert('Category has id', !!catId);
    assert('Category name correct', catCreate.data?.data?.name === 'Work');

    // Duplicate name → 409
    const catDup = await req('POST', '/categories', {
        token: userA.token,
        body: { name: 'Work' },
    });
    assert('Duplicate category → 409', catDup.status === 409, JSON.stringify(catDup.data));

    // List categories
    const catList = await req('GET', '/categories', { token: userA.token });
    assert('GET /categories → 200', catList.status === 200);
    assert('List contains Work', catList.data?.data?.some((c) => c.name === 'Work'));

    // Rename category
    const catRename = await req('PATCH', `/categories/${catId}`, {
        token: userA.token,
        body: { name: 'Work-Renamed' },
    });
    assert('PATCH /categories/:id → 200', catRename.status === 200, JSON.stringify(catRename.data));
    assert('Name updated', catRename.data?.data?.name === 'Work-Renamed');

    // Ownership: User B cannot rename User A's category
    const catCrossRename = await req('PATCH', `/categories/${catId}`, {
        token: userB.token,
        body: { name: 'Hacked' },
    });
    assert('User B PATCH User A category → 403', catCrossRename.status === 403);

    // ── Tags CRUD ─────────────────────────────────────────────────────────────
    console.log('\n▶ Tags');
    const tagCreate = await req('POST', '/tags', {
        token: userA.token,
        body: { name: 'urgent' },
    });
    assert('POST /tags → 201', tagCreate.status === 201, JSON.stringify(tagCreate.data));
    const tagId = tagCreate.data?.data?.id;
    assert('Tag has id', !!tagId);

    const tagDup = await req('POST', '/tags', {
        token: userA.token,
        body: { name: 'urgent' },
    });
    assert('Duplicate tag → 409', tagDup.status === 409);

    const tagList = await req('GET', '/tags', { token: userA.token });
    assert('GET /tags → 200', tagList.status === 200);
    assert('List contains urgent', tagList.data?.data?.some((t) => t.name === 'urgent'));

    // User B cannot delete User A's tag
    const tagCrossDel = await req('DELETE', `/tags/${tagId}`, { token: userB.token });
    assert('User B DELETE User A tag → 403', tagCrossDel.status === 403);

    // ── Note with category and tags ───────────────────────────────────────────
    console.log('\n▶ Note with category, tags, and priority');
    const noteCreate = await req('POST', '/notes', {
        token: userA.token,
        body: {
            title: 'Searchable Meeting Notes',
            content: '{"ops":[{"insert":"Discussed quarterly roadmap.\\n"}]}',
            category_id: catId,
            tag_ids: [tagId],
            priority: 'high',
        },
    });
    assert('POST /notes with category+tags → 201', noteCreate.status === 201, JSON.stringify(noteCreate.data));
    const noteId = noteCreate.data?.data?.id;
    assert('Note has id', !!noteId);
    assert('Note has tags array', Array.isArray(noteCreate.data?.data?.tags));
    assert('Note tags include urgent', noteCreate.data?.data?.tags?.some((t) => t.id === tagId));
    assert('Note category_id set', noteCreate.data?.data?.category_id === catId);
    assert('Note priority = high', noteCreate.data?.data?.priority === 'high');

    // ── List with filters ─────────────────────────────────────────────────────
    console.log('\n▶ List notes with filters');
    const listByCat = await req('GET', '/notes', {
        token: userA.token,
        query: { category_id: catId },
    });
    assert('GET /notes?category_id → 200', listByCat.status === 200);
    assert('Filtered list contains our note', listByCat.data?.data?.notes?.some((n) => n.id === noteId));

    const listByTag = await req('GET', '/notes', {
        token: userA.token,
        query: { tag_id: tagId },
    });
    assert('GET /notes?tag_id → 200', listByTag.status === 200);
    assert('Tag-filtered list contains our note', listByTag.data?.data?.notes?.some((n) => n.id === noteId));

    const listByPriority = await req('GET', '/notes', {
        token: userA.token,
        query: { priority: 'high', sort: 'priority', order: 'desc' },
    });
    assert('GET /notes?priority=high → 200', listByPriority.status === 200);
    assert('Priority-filtered list contains our note', listByPriority.data?.data?.notes?.some((n) => n.id === noteId));

    // ── Search ────────────────────────────────────────────────────────────────
    console.log('\n▶ Full-text search');
    const searchRes = await req('GET', '/notes/search', {
        token: userA.token,
        query: { q: 'Meeting' },
    });
    assert('GET /notes/search?q=Meeting → 200', searchRes.status === 200, JSON.stringify(searchRes.data));
    assert('Search returns our note', searchRes.data?.data?.notes?.some((n) => n.id === noteId));
    assert('Search pagination present', !!searchRes.data?.data?.pagination);

    // Search by category
    const searchByCat = await req('GET', '/notes/search', {
        token: userA.token,
        query: { category_id: catId },
    });
    assert('GET /notes/search?category_id → 200', searchByCat.status === 200);
    assert('Category search returns our note', searchByCat.data?.data?.notes?.some((n) => n.id === noteId));

    // Search with no params → 400
    const searchNone = await req('GET', '/notes/search', { token: userA.token });
    assert('GET /notes/search with no params → 400', searchNone.status === 400, JSON.stringify(searchNone.data));

    // ── Cross-user search isolation ───────────────────────────────────────────
    console.log('\n▶ Cross-user search isolation');
    const searchB = await req('GET', '/notes/search', {
        token: userB.token,
        query: { q: 'Meeting' },
    });
    assert('User B search does not return User A notes', !searchB.data?.data?.notes?.some((n) => n.id === noteId));

    // ── Update note tags ───────────────────────────────────────────────────────
    console.log('\n▶ Update note — clear tags');
    const noteUpdate = await req('PATCH', `/notes/${noteId}`, {
        token: userA.token,
        body: { tag_ids: [] },
    });
    assert('PATCH /notes/:id with tag_ids=[] → 200', noteUpdate.status === 200, JSON.stringify(noteUpdate.data));
    assert('Tags cleared', noteUpdate.data?.data?.tags?.length === 0);

    // ── Delete category ───────────────────────────────────────────────────────
    console.log('\n▶ Delete category');
    const catDel = await req('DELETE', `/categories/${catId}`, { token: userA.token });
    assert('DELETE /categories/:id → 200', catDel.status === 200, JSON.stringify(catDel.data));

    // ── Delete tag ────────────────────────────────────────────────────────────
    console.log('\n▶ Delete tag');
    const tagDel = await req('DELETE', `/tags/${tagId}`, { token: userA.token });
    assert('DELETE /tags/:id → 200', tagDel.status === 200, JSON.stringify(tagDel.data));

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Passed: ${passed}  |  Failed: ${failed}  |  Total: ${passed + failed}`);
    if (failed > 0) process.exit(1);
}

run().catch((err) => {
    console.error('\n💥 Test runner error:', err.message);
    process.exit(1);
});
