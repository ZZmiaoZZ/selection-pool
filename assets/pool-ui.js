/* ============================================================
   跨站选品池 · 共享行为层  (window.PoolUI)
   由 enhance_final_pools.ps1 内联注入到各子页面 </body> 之前。
   注入锚点：<!--FINAL-UI-JS-->

   设计要点（对应四条验收标准）：
   1. 表头与排序列不重叠
      顶部「返回主页 + 标题 + 工具栏」合并为单一 sticky 容器 .page-stack，
      其真实高度由 ResizeObserver 写入 --stack-h，thead th 以该值做 top 偏移。
      z-index 严格分层：page-stack 60 > thead 首列 32 > thead 其余 30 > tbody 首列 12。
   2. 返回主页按钮始终可见
      按钮位于 .page-stack 内，随页面滚动常驻；颜色全部为字面量，
      不依赖任何可能失效的 CSS 变量回退。
   3. 筛选后状态与备注不串行
      状态与备注不再由脚本事后追加单元格，而是由各页 render() 依据
      内容派生 ID（品类|品牌英文名|型号）从同一 store 直接渲染，
      与行序、筛选结果、DOM 位置完全解耦。
   4. 刷新后状态与备注仍保留
      单一 localStorage 键 pool-ui-v2::<pageKey> 保存 {s:状态, n:备注}，
      并自动迁移旧版本键（含旧 enhance 指纹键）。
   ============================================================ */

(function (global) {
  'use strict';

  var STORE_PREFIX = 'pool-ui-v2::';
  var STATUSES = ['未处理', '掌握了', '不做', '待定'];
  var STATUS_CLASS = {
    '掌握了': 'status-mastered',
    '不做': 'status-drop',
    '待定': 'status-pending'
  };

  function esc(v) {
    return String(v == null ? '' : v).replace(/[&<>"']/g, function (m) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m];
    });
  }

  function readJSON(key) {
    try {
      var raw = localStorage.getItem(key);
      if (!raw) return null;
      var v = JSON.parse(raw);
      return (v && typeof v === 'object') ? v : null;
    } catch (e) { return null; }
  }

  /* ---------------- 状态 / 备注 存储 ---------------- */

  function Store(pageKey, legacyKeys) {
    this.key = STORE_PREFIX + pageKey;
    this.data = readJSON(this.key) || {};
    this._migrate(pageKey, legacyKeys || []);
  }

  Store.prototype._migrate = function (pageKey, legacyKeys) {
    var self = this;
    var touched = false;

    function absorb(id, status, note) {
      if (!id) return;
      var cur = self.data[id] || {};
      // 已有的新版数据优先，旧数据只补空缺，避免迁移覆盖用户最新标记
      if (status && STATUSES.indexOf(status) >= 0 && status !== '未处理' && !cur.s) {
        cur.s = status; touched = true;
      }
      if (note && !cur.n) { cur.n = note; touched = true; }
      if (cur.s || cur.n) self.data[id] = cur;
    }

    // 旧版：各页自带的 state，值为状态字符串
    legacyKeys.forEach(function (k) {
      var old = readJSON(k);
      if (!old) return;
      Object.keys(old).forEach(function (id) {
        var v = old[id];
        if (typeof v === 'string') absorb(id, v, '');
        else if (v && typeof v === 'object') absorb(id, v.status || v.s, v.note || v.n);
      });
    });

    // 旧版：enhance_final_pools 注入的指纹键 final-pool-memory-v1-<page>-<hash>
    try {
      var prefix = 'final-pool-memory-v1-' + pageKey + '-';
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (!k || k.indexOf(prefix) !== 0) continue;
        var mem = readJSON(k);
        if (!mem) continue;
        Object.keys(mem).forEach(function (rawId) {
          var v = mem[rawId] || {};
          // 旧指纹键的 ID 可能是 "page|rank|model" 形式，取末段型号做后备匹配
          var parts = String(rawId).split('|');
          var id = parts.length > 2 ? parts[parts.length - 1] : rawId;
          absorb(id, v.status, v.note);
        });
      }
    } catch (e) { /* localStorage 不可用时静默跳过 */ }

    if (touched) this.save();
  };

  Store.prototype.save = function () {
    try { localStorage.setItem(this.key, JSON.stringify(this.data)); return true; }
    catch (e) { return false; }
  };

  Store.prototype.status = function (id) {
    var r = this.data[id];
    return (r && r.s) || '未处理';
  };

  Store.prototype.note = function (id) {
    var r = this.data[id];
    return (r && r.n) || '';
  };

  Store.prototype.setStatus = function (id, value) {
    var r = this.data[id] || (this.data[id] = {});
    if (value && value !== '未处理') r.s = value; else delete r.s;
    if (!r.s && !r.n) delete this.data[id];
    return this.save();
  };

  Store.prototype.setNote = function (id, value) {
    var r = this.data[id] || (this.data[id] = {});
    if (value) r.n = value; else delete r.n;
    if (!r.s && !r.n) delete this.data[id];
    return this.save();
  };

  Store.prototype.clear = function (legacyKeys) {
    this.data = {};
    try {
      localStorage.removeItem(this.key);
      (legacyKeys || []).forEach(function (k) { localStorage.removeItem(k); });
    } catch (e) { /* 忽略 */ }
  };

  Store.prototype.marked = function () {
    var n = 0, d = this.data;
    for (var k in d) if (d[k] && (d[k].s || d[k].n)) n++;
    return n;
  };

  /* ---------------- 单元格 HTML ---------------- */

  function statusCellHtml(id, status) {
    var out = '<td class="cell-status"><select data-row-id="' + esc(id) + '" aria-label="开发状态">';
    for (var i = 0; i < STATUSES.length; i++) {
      var s = STATUSES[i];
      out += '<option value="' + s + '"' + (s === status ? ' selected' : '') + '>' + s + '</option>';
    }
    return out + '</select></td>';
  }

  function noteCellHtml(id, note) {
    return '<td class="cell-note">' +
      '<textarea class="note-input" data-row-id="' + esc(id) + '" rows="2" ' +
      'placeholder="供应商、配件词、核验结果…" aria-label="备注">' + esc(note) + '</textarea>' +
      '<span class="note-hint">自动保存在本机浏览器</span></td>';
  }

  function rowClass(status) { return STATUS_CLASS[status] || ''; }

  /* ---------------- 顶部固定区 ---------------- */

  function mountChrome(opts) {
    opts = opts || {};
    var h1 = document.querySelector('h1');
    var toolbar = document.querySelector('.toolbar');
    if (!h1) return null;

    var stack = document.createElement('div');
    stack.className = 'page-stack';

    var bar = document.createElement('div');
    bar.className = 'page-bar';

    var home = document.createElement('a');
    home.className = 'home-link';
    home.href = opts.home || 'index.html';
    home.innerHTML = '<span class="arrow" aria-hidden="true">←</span><span>返回主页</span>';
    home.title = '返回跨站选品池目录';

    var parent = h1.parentNode;
    parent.insertBefore(stack, h1);
    bar.appendChild(home);
    bar.appendChild(h1);

    var spacer = document.createElement('div');
    spacer.className = 'spacer';
    bar.appendChild(spacer);

    var pill = document.createElement('span');
    pill.className = 'count-pill';
    pill.id = 'countPill';
    bar.appendChild(pill);

    stack.appendChild(bar);
    if (toolbar) stack.appendChild(toolbar);

    // 说明文字折叠，避免长段文字把工具栏推出视口
    var note = document.querySelector('body > .note, .page-stack ~ .note');
    if (!note) note = document.querySelector('p.note');
    if (note && note.parentNode) {
      var details = document.createElement('details');
      details.className = 'page-intro';
      var summary = document.createElement('summary');
      summary.textContent = '选品规则与数据口径说明';
      details.appendChild(summary);
      note.parentNode.insertBefore(details, note);
      details.appendChild(note);

      var machine = document.createElement('p');
      machine.className = 'machine-note';
      machine.textContent = '本机记忆已启用：「状态」与「备注」按内容标识保存在当前浏览器本地存储，'
        + '筛选、排序和刷新都不会串行或丢失；不会上传网络，换浏览器或清除站点数据后需重新标记。';
      note.parentNode.appendChild(machine);
    }

    // 用真实高度驱动表头偏移，工具栏换行时自动跟随
    var root = document.documentElement;
    var apply = function () {
      var h = Math.round(stack.getBoundingClientRect().height);
      if (h > 0) root.style.setProperty('--stack-h', h + 'px');
    };
    apply();
    if (global.ResizeObserver) new ResizeObserver(apply).observe(stack);
    global.addEventListener('resize', apply);
    global.addEventListener('load', apply);
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(apply);

    return { stack: stack, home: home, pill: pill };
  }

  /* ---------------- 表格事件委托 ---------------- */

  /* 关键：状态变更只改当前行的 class，不触发整表 render()。
     否则 innerHTML 重建会销毁正在输入的 textarea，造成「备注串行/丢失」。 */
  function bindTable(tbody, store, hooks) {
    if (!tbody) return;
    hooks = hooks || {};

    tbody.addEventListener('change', function (ev) {
      var sel = ev.target;
      if (!sel || sel.tagName !== 'SELECT' || !sel.dataset.rowId) return;
      var id = sel.dataset.rowId;
      store.setStatus(id, sel.value);
      var tr = sel.closest('tr');
      if (tr) {
        tr.classList.remove('status-mastered', 'status-drop', 'status-pending');
        var cls = rowClass(sel.value);
        if (cls) tr.classList.add(cls);
      }
      if (hooks.onStatus) hooks.onStatus(id, sel.value, tr);
    });

    var timers = {};
    tbody.addEventListener('input', function (ev) {
      var ta = ev.target;
      if (!ta || !ta.classList.contains('note-input') || !ta.dataset.rowId) return;
      var id = ta.dataset.rowId;
      clearTimeout(timers[id]);
      timers[id] = setTimeout(function () {
        store.setNote(id, ta.value);
        ta.classList.add('is-saved');
        setTimeout(function () { ta.classList.remove('is-saved'); }, 700);
        if (hooks.onNote) hooks.onNote(id, ta.value);
      }, 220);
    });

    // 失焦立即落盘，避免防抖窗口内关闭页面
    tbody.addEventListener('focusout', function (ev) {
      var ta = ev.target;
      if (!ta || !ta.classList.contains('note-input') || !ta.dataset.rowId) return;
      clearTimeout(timers[ta.dataset.rowId]);
      store.setNote(ta.dataset.rowId, ta.value);
      if (hooks.onNote) hooks.onNote(ta.dataset.rowId, ta.value);
    });
  }

  /* 筛选造成整表重绘时，保留输入焦点与光标位置 */
  function withFocusKept(fn) {
    var el = document.activeElement;
    var keep = null;
    if (el && el.classList && el.classList.contains('note-input')) {
      keep = { id: el.dataset.rowId, start: el.selectionStart, end: el.selectionEnd };
    }
    fn();
    if (!keep) return;
    var next = document.querySelector('.note-input[data-row-id="' + (global.CSS && CSS.escape ? CSS.escape(keep.id) : keep.id) + '"]');
    if (!next) return;
    try { next.focus({ preventScroll: true }); next.setSelectionRange(keep.start, keep.end); } catch (e) { }
  }

  function setCount(shown, total, marked) {
    var pill = document.getElementById('countPill');
    var txt = '显示 <b>' + shown + '</b> / ' + total + ' 条';
    if (typeof marked === 'number' && marked > 0) txt += ' · 已标记 ' + marked;
    if (pill) pill.innerHTML = txt;
    var legacy = document.getElementById('count');
    if (legacy) legacy.textContent = '显示 ' + shown + ' / ' + total + ' 条';
  }

  function cnBadge() { return '<span class="cn-badge">中国</span>'; }

  global.PoolUI = {
    STATUSES: STATUSES,
    esc: esc,
    Store: Store,
    statusCellHtml: statusCellHtml,
    noteCellHtml: noteCellHtml,
    rowClass: rowClass,
    mountChrome: mountChrome,
    bindTable: bindTable,
    withFocusKept: withFocusKept,
    setCount: setCount,
    cnBadge: cnBadge
  };
})(window);
