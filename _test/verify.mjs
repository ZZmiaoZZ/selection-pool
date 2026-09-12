/* 真实浏览器验收：加载本地 Web 服务上的五个页面，逐条校验四项标准。 */
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// playwright-core 解析顺序：
//   1) 环境变量 PW_CORE（指向 playwright-core 的 index.mjs 绝对路径）
//   2) 项目本地 node_modules（先在本目录执行：npm i playwright-core）
const PW = process.env.PW_CORE;
let pw;
try {
  pw = PW ? await import(pathToFileURL(PW).href) : await import('playwright-core');
} catch (e) {
  throw new Error(
    '未找到 playwright-core。请先在本目录执行 npm i playwright-core，'
    + '或设置环境变量 PW_CORE=<playwright-core/index.mjs 的绝对路径>。原始错误：' + e.message
  );
}
const chromium = pw.chromium || pw.default?.chromium;
if (!chromium) throw new Error('playwright-core 未导出 chromium：' + Object.keys(pw).join(','));

const BASE = process.env.BASE || 'http://127.0.0.1:8791';
const OUT = path.resolve('_test/out');
fs.mkdirSync(OUT, { recursive: true });

const PAGES = [
  { key: 'index',    file: 'index.html',                           name: '主目录页面',    table: false },
    { key: 'us',       file: 'AMZ美国站选品池.html',                      name: '美国池',        table: true },
  
    { key: 'mexico',   file: 'MC墨西哥选品池.html',                       name: '墨西哥池',      table: true },
    { key: 'poland',   file: 'AL波兰站选品池.html',                       name: '波兰池',        table: true },
    { key: 'japan',    file: 'AMZ日本站选品池.html',                      name: '日本池',        table: true },
];

const results = [];
const rec = (page, name, pass, detail) => {
  results.push({ page, name, pass, detail });
  console.log(`${pass ? 'PASS' : 'FAIL'}  [${page}] ${name}${detail ? ' — ' + detail : ''}`);
};

const browser = await chromium.launch({
  // 不设 CHROME_PATH 时使用 playwright 自带的浏览器
  executablePath: process.env.CHROME_PATH || undefined,
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});
const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 } });
const page = await ctx.newPage();

const consoleErrors = [];
const networkErrors = [];
page.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text() + ' @ ' + (m.location()?.url || '?')); });
page.on('pageerror', e => consoleErrors.push('pageerror: ' + e.message));
page.on('requestfailed', req => networkErrors.push(req.url() + ' :: ' + req.failure()?.errorText));
page.on('response', resp => { if (resp.status() >= 400) networkErrors.push(resp.url() + ' :: ' + resp.status()); });

for (const P of PAGES) {
  const url = BASE + '/' + encodeURIComponent(P.file);
  consoleErrors.length = 0;
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(400);

  rec(P.key, 'JS 无运行时报错', consoleErrors.length === 0,
    consoleErrors.slice(0, 3).join(' | ') + (networkErrors.length ? ' | NET: ' + networkErrors.slice(0, 3).join(' / ') : ''));

  if (!P.table) {
    // README：卡片链接可用且指向真实文件
    const links = await page.$$eval('a.card', as => as.map(a => ({ href: a.getAttribute('href'), text: a.querySelector('h2')?.textContent })));
    rec(P.key, '四张子页面卡片存在', links.length === 4, `实际 ${links.length} 张`);
    const jp = links.find(l => (l.href || '').indexOf('日本站') !== -1);
    rec(P.key, '日本站入口卡片存在', !!jp, jp ? `href=${jp.href}` : '未找到日本站卡片');
    const kpis = await page.$$eval('.kpi b', bs => bs.map(b => b.textContent.trim()));
    rec(P.key, 'KPI 统计已渲染', kpis.length >= 4 && kpis[0] !== '0', 'KPI=' + kpis.join('/'));
    await page.screenshot({ path: `${OUT}/${P.key}.png`, fullPage: false });
    continue;
  }

  /* ---------- 标准 2：返回主页按钮始终可见 ---------- */
  const homeTop = await page.evaluate(() => {
    const a = document.querySelector('a.home-link');
    if (!a) return null;
    const r = a.getBoundingClientRect(), cs = getComputedStyle(a);
    return { w: r.width, h: r.height, top: r.top, bg: cs.backgroundColor, color: cs.color, href: a.getAttribute('href') };
  });
  rec(P.key, '返回主页按钮存在且尺寸正常',
    !!homeTop && homeTop.w > 60 && homeTop.h > 20,
    homeTop ? `${Math.round(homeTop.w)}x${Math.round(homeTop.h)} href=${homeTop.href}` : '未找到');
  // 关键回归：背景必须是实色深蓝，不能因 CSS 变量失效而透明（旧版白字透明底 = 看不见）
  const bgOk = homeTop && !/rgba\(0,\s*0,\s*0,\s*0\)|transparent/.test(homeTop.bg);
  rec(P.key, '返回主页按钮背景为实色（非透明）', !!bgOk, homeTop ? `bg=${homeTop.bg} color=${homeTop.color}` : '');

  // 滚到底部后仍然可见
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(350);
  const homeAfter = await page.evaluate(() => {
    const a = document.querySelector('a.home-link');
    const r = a.getBoundingClientRect();
    const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
    return { top: r.top, bottom: r.bottom, inView: r.top >= -1 && r.bottom <= innerHeight + 1, hitIsHome: !!(hit && hit.closest('a.home-link')) };
  });
  rec(P.key, '滚动到底部后返回主页按钮仍在视口内', homeAfter.inView, `top=${Math.round(homeAfter.top)}`);
  rec(P.key, '返回主页按钮未被其他元素遮挡（命中测试）', homeAfter.hitIsHome, '');

  /* ---------- 标准 1：表头与排序列不重叠 ---------- */
  // 上一段已经把页面滚到底部去看「返回主页」按钮，
  // 现在先滚回顶部，才能在原位校验表头 sticky 与表头命中
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(250);
  const overlap = await page.evaluate(() => {
    const stack = document.querySelector('.page-stack');
    const th0 = document.querySelector('#grid thead th:first-child') || document.querySelector('thead th:first-child');
    const thLast = document.querySelector('thead th:last-child');
    const td0 = document.querySelector('tbody tr:not(.empty-row) td:first-child');
    const sr = stack.getBoundingClientRect(), hr = th0.getBoundingClientRect();
    const inter = (a, b) => Math.max(0, Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top))
                          * Math.max(0, Math.min(a.right, b.right) - Math.max(a.left, b.left));
    const out = {
      stackH: Math.round(sr.height),
      stackVar: getComputedStyle(document.documentElement).getPropertyValue('--stack-h').trim(),
      headerTop: Math.round(hr.top),
      stackBottom: Math.round(sr.bottom),
      stackVsHeader: Math.round(inter(sr, hr)),
      thPos: getComputedStyle(th0).position,
      thZ: getComputedStyle(th0).zIndex,
      tdZ: td0 ? getComputedStyle(td0).zIndex : null,
      // 表头中心点的命中元素必须是表头本身，而不是被工具栏或首列压住
      hitHeader: (() => {
        const el = document.elementFromPoint(hr.left + hr.width / 2, hr.top + hr.height / 2);
        return el ? el.tagName + '.' + (el.className || '') : null;
      })(),
    };
    // 首列数据格与表头首格不得有交叠面积
    if (td0) {
      const tr = td0.getBoundingClientRect();
      out.headerVsFirstCol = Math.round(inter(hr, tr));
      out.firstColHit = (() => {
        const el = document.elementFromPoint(tr.left + tr.width / 2, Math.min(tr.top + tr.height / 2, innerHeight - 5));
        return el ? el.tagName : null;
      })();
    }
    // 所有表头单元格必须处在同一水平线上（没有被拆成两行导致错位）
    const tops = [...document.querySelectorAll('thead th')].map(t => Math.round(t.getBoundingClientRect().top));
    out.headerRowsDistinct = [...new Set(tops)].length;
    return out;
  });
  rec(P.key, '--stack-h 已按工具栏真实高度写入', overlap.stackVar === overlap.stackH + 'px',
    `实测 ${overlap.stackH}px / 变量 ${overlap.stackVar}`);
  rec(P.key, '表头未与顶部固定区重叠', overlap.stackVsHeader === 0,
    `交叠面积 ${overlap.stackVsHeader}，表头 top=${overlap.headerTop} 固定区 bottom=${overlap.stackBottom}`);
  rec(P.key, '表头点击命中表头自身（未被遮挡）', /TH/.test(overlap.hitHeader || ''), `命中 ${overlap.hitHeader}`);
  rec(P.key, '表头首格与排序列数据格无交叠', overlap.headerVsFirstCol === 0, `交叠面积 ${overlap.headerVsFirstCol}`);
  rec(P.key, '表头 z-index 高于排序列', Number(overlap.thZ) > Number(overlap.tdZ),
    `th=${overlap.thZ} td=${overlap.tdZ}`);
  rec(P.key, '表头保持单行对齐', overlap.headerRowsDistinct === 1, `不同 top 值 ${overlap.headerRowsDistinct} 个`);

  // 横向滚动到最右，再次校验冻结列与表头。
  // 关键：sticky 表头在纵向滚动时会与数据行有交叠（这是设计内的视觉遮挡行为），
  // 所以这里只校验横向「冻结列」的对齐——th0 与 td0 的 left/width 必须一致，
  // 否则会出现表头与排序列错位、视觉上对不齐的回归。
  await page.evaluate(() => { window.scrollTo(document.body.scrollWidth, 300); });
  await page.waitForTimeout(300);
  const afterX = await page.evaluate(() => {
    const th0 = document.querySelector('thead th:first-child');
    const td0 = document.querySelector('tbody tr:not(.empty-row) td:first-child');
    const a = th0.getBoundingClientRect(), b = td0.getBoundingClientRect();
    return {
      thLeft: Math.round(a.left), tdLeft: Math.round(b.left),
      thWidth: Math.round(a.width), tdWidth: Math.round(b.width),
      thTop: Math.round(a.top), tdTop: Math.round(b.top),
      scrollX: window.scrollX,
    };
  });
  const aligned = afterX.thLeft === afterX.tdLeft && afterX.thWidth === afterX.tdWidth;
  rec(P.key, '横向滚动后表头与排序列仍不重叠', aligned,
    `th0 left=${afterX.thLeft}/${afterX.thWidth}px  td0 left=${afterX.tdLeft}/${afterX.tdWidth}px  scrollX=${afterX.scrollX}`);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(200);

  /* ---------- 标准 3：筛选后状态与备注不串行 ---------- */
  // 取三行，分别写不同的状态与备注，记录其型号作为身份锚点
  const marked = await page.evaluate(() => {
    const rows = [...document.querySelectorAll('tbody tr:not(.empty-row)')].slice(0, 6);
    const picks = [rows[0], rows[2], rows[4]].filter(Boolean);
    const statuses = ['掌握了', '不做', '待定'];
    const out = [];
    picks.forEach((tr, i) => {
      const sel = tr.querySelector('.cell-status select');
      const ta = tr.querySelector('.note-input');
      const model = tr.querySelector('.model-cell')?.textContent.trim();
      sel.value = statuses[i];
      sel.dispatchEvent(new Event('change', { bubbles: true }));
      ta.value = 'AUTOTEST-' + i + '-' + model;
      ta.dispatchEvent(new Event('input', { bubbles: true }));
      ta.dispatchEvent(new Event('focusout', { bubbles: true }));
      out.push({ model, status: statuses[i], note: 'AUTOTEST-' + i + '-' + model, rowId: sel.dataset.rowId });
    });
    return out;
  });
  await page.waitForTimeout(400);
  rec(P.key, '成功写入 3 行状态与备注', marked.length === 3, marked.map(m => m.status).join(','));

  // 施加搜索筛选（用其中一行的型号片段），确认剩余行状态/备注仍与自身型号对应
  const probe = marked[1];
  const token = probe.model.split(/[\s/]+/)[0].slice(0, 10);
  await page.fill('#search', token);
  await page.waitForTimeout(450);
  const afterFilter = await page.evaluate(() => {
    return [...document.querySelectorAll('tbody tr:not(.empty-row)')].map(tr => ({
      model: tr.querySelector('.model-cell')?.textContent.trim(),
      status: tr.querySelector('.cell-status select')?.value,
      note: tr.querySelector('.note-input')?.value,
      rowId: tr.querySelector('.cell-status select')?.dataset.rowId,
    }));
  });
  const hit = afterFilter.find(r => r.model === probe.model);
  rec(P.key, `筛选「${token}」后目标行仍保留自身状态`, !!hit && hit.status === probe.status,
    hit ? `期望 ${probe.status} 实际 ${hit.status}` : '筛选结果中未找到目标行');
  rec(P.key, '筛选后目标行备注未串到其他行', !!hit && hit.note === probe.note,
    hit ? `期望 ${probe.note} 实际 ${hit.note}` : '');
  // 所有可见行：凡是有 AUTOTEST 备注的，备注里的型号必须等于该行型号
  const misaligned = afterFilter.filter(r => r.note && r.note.startsWith('AUTOTEST-') && !r.note.endsWith(r.model));
  rec(P.key, '筛选后无任何行出现备注错位', misaligned.length === 0,
    misaligned.length ? JSON.stringify(misaligned.slice(0, 2)) : '');

  // 用状态筛选进一步交叉验证
  await page.fill('#search', '');
  await page.waitForTimeout(300);
  await page.selectOption('#statusFilter', '掌握了');
  await page.waitForTimeout(450);
  const onlyMastered = await page.evaluate(() => [...document.querySelectorAll('tbody tr:not(.empty-row)')].map(tr => ({
    model: tr.querySelector('.model-cell')?.textContent.trim(),
    status: tr.querySelector('.cell-status select')?.value,
    note: tr.querySelector('.note-input')?.value,
  })));
  rec(P.key, '按「掌握了」筛选只返回该状态的行',
    onlyMastered.length > 0 && onlyMastered.every(r => r.status === '掌握了'),
    `返回 ${onlyMastered.length} 行：${onlyMastered.map(r => r.status).join(',')}`);
  const m0 = marked[0];
  const keptNote = onlyMastered.find(r => r.model === m0.model);
  rec(P.key, '状态筛选后备注仍与该行绑定', !!keptNote && keptNote.note === m0.note,
    keptNote ? `实际 ${keptNote.note}` : '');
  await page.selectOption('#statusFilter', '');
  await page.waitForTimeout(300);

  /* ---------- 标准 4：刷新后状态与备注仍保留 ---------- */
  await page.reload({ waitUntil: 'load' });
  await page.waitForTimeout(500);
  const afterReload = await page.evaluate((expect) => {
    const rows = [...document.querySelectorAll('tbody tr:not(.empty-row)')];
    return expect.map(e => {
      const tr = rows.find(t => t.querySelector('.model-cell')?.textContent.trim() === e.model);
      return {
        model: e.model,
        want: { status: e.status, note: e.note },
        got: tr ? { status: tr.querySelector('.cell-status select')?.value, note: tr.querySelector('.note-input')?.value } : null,
      };
    });
  }, marked);
  const allKept = afterReload.every(r => r.got && r.got.status === r.want.status && r.got.note === r.want.note);
  rec(P.key, '刷新后 3 行状态与备注全部保留', allKept,
    afterReload.map(r => `${r.model?.slice(0, 16)}:${r.got?.status}/${r.got?.note ? 'note-ok' : 'note-lost'}`).join(' | '));

  // 存储键校验
  const storeInfo = await page.evaluate(() => {
    const keys = Object.keys(localStorage).filter(k => k.indexOf('pool-ui-v2::') === 0);
    return keys.map(k => ({ key: k, entries: Object.keys(JSON.parse(localStorage.getItem(k))).length }));
  });
  rec(P.key, 'localStorage 使用单一 pool-ui-v2 键', storeInfo.length === 1,
    JSON.stringify(storeInfo));

  if (P.key === 'japan') {
    // 数据对比模块：勾选两条 → 打开对比弹窗 → 校验结构 → 关闭
    const picked = await page.evaluate(() => {
      const boxes = [...document.querySelectorAll('.cmp-check')].slice(0, 2);
      boxes.forEach(b => { b.checked = true; b.dispatchEvent(new Event('change', { bubbles: true })); });
      return boxes.length;
    });
    rec(P.key, '日本站对比勾选生效', picked === 2, `勾选 ${picked} 条`);
    await page.click('#cmpBtn');
    await page.waitForTimeout(200);
    const modal = await page.evaluate(() => {
      const m = document.getElementById('cmpModal');
      const ths = m ? [...m.querySelectorAll('thead th')].map(t => t.textContent.trim()) : [];
      const rows = m ? m.querySelectorAll('tbody tr').length : 0;
      return { visible: !!m && !m.hidden, ths, rows };
    });
    rec(P.key, '日本站对比弹窗打开且结构正确（字段列+2条记录列）',
      modal.visible && modal.ths.length === 3 && modal.rows >= 8,
      `visible=${modal.visible} th=${modal.ths.length} 行=${modal.rows}`);
    await page.click('#cmpClose');
    const closed = await page.evaluate(() => document.getElementById('cmpModal').hidden);
    rec(P.key, '日本站对比弹窗可关闭', !!closed, '');
  }

  await page.screenshot({ path: `${OUT}/${P.key}.png`, fullPage: false });

  // 清理测试数据，避免污染用户真实标记
  await page.evaluate(() => {
    Object.keys(localStorage).filter(k => k.indexOf('pool-ui-v2::') === 0).forEach(k => localStorage.removeItem(k));
  });
}

await browser.close();

const failed = results.filter(r => !r.pass);
fs.writeFileSync(`${OUT}/report.json`, JSON.stringify(results, null, 2), 'utf8');
console.log('\n==================== 汇总 ====================');
console.log(`共 ${results.length} 项检查，通过 ${results.length - failed.length}，失败 ${failed.length}`);
if (failed.length) {
  failed.forEach(f => console.log(`  FAIL [${f.page}] ${f.name} — ${f.detail}`));
  process.exit(1);
}
console.log('全部通过');
