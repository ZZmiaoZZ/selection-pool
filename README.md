# selection-pool

Cross-site product selection pools for cross-border e-commerce — four self-contained HTML
dashboards for sourcing high-ticket models and their teardown-replaceable parts across
Amazon US / Amazon JP / MercadoLibre MX / Allegro PL.

跨境选品池：面向亚马逊美国站、亚马逊日本站、美客多墨西哥站、波兰 Allegro 四个市场的
高客单型号选品与拆机替换件开发清单。全部为**自包含静态页面**，双击即可打开，无需构建、无需服务器。

---

## Pages / 页面

| File | Market | Rows |
|---|---|---|
| `index.html` | Hub — KPI overview + links to the four pools | — |
| `AMZ美国站选品池.html` | Amazon US | 380 |
| `AMZ日本站选品池.html` | Amazon JP (incl. a 3-way comparison module) | 46 |
| `MC墨西哥选品池.html` | MercadoLibre MX | 13 |
| `AL波兰站选品池.html` | Allegro PL | 42 |

Open `index.html` directly, or serve the folder over HTTP:

```bash
python -m http.server 8791
# then visit http://127.0.0.1:8791
```

> Serving over HTTP is recommended. Opening via `file://` works too, but browsers restrict
> `localStorage` for `file://` origins in some configurations, which would stop your
> status marks / notes from persisting.

---

## Notes and status are stored in your browser / 状态与备注存在浏览器里

Marks (状态), notes (备注) and column preferences are saved in `localStorage` under the
`pool-ui-v2::*` keys — they follow **browser + origin**, never the repository. Switching
browsers, devices, or the host you open the pages from means starting fresh.

---

## Repository layout / 目录结构

```
├── index.html                     hub page
├── AMZ美国站选品池.html            Amazon US pool
├── AMZ日本站选品池.html            Amazon JP pool
├── MC墨西哥选品池.html             MercadoLibre MX pool
├── AL波兰站选品池.html             Allegro PL pool
├── build_selection_pool.ps1       regenerates the US pool
├── build_japan_pool.ps1           regenerates the JP pool
├── build_mexico_pool.ps1          regenerates the MX pool
├── build_poland_pool.ps1          regenerates the PL pool
├── enhance_final_pools.ps1        injects shared CSS/JS + rebuilds index.html
├── assets/
│   ├── pool-ui.css                shared table UI
│   └── pool-ui.js                 shared interactions (sort / filter / compare / marks)
├── source/
│   └── 全行业高客单型号选品池.html   data source consumed by build_selection_pool.ps1
├── favicon.ico
└── _test/
    └── verify.mjs                 real-browser acceptance test (Playwright, 87 checks)
```

---

## Editing the data / 改数据

All list data lives inside the `build_*.ps1` scripts as embedded JSON. Edit the script for
the pool you want, then regenerate.

Rebuild one pool:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_japan_pool.ps1
```

Rebuild everything (run all four builders, then the assembler — order of the four does not
matter, but `enhance_final_pools.ps1` must run last):

```powershell
powershell -ExecutionPolicy Bypass -File .\build_mexico_pool.ps1
powershell -ExecutionPolicy Bypass -File .\build_poland_pool.ps1
powershell -ExecutionPolicy Bypass -File .\build_japan_pool.ps1
powershell -ExecutionPolicy Bypass -File .\build_selection_pool.ps1
powershell -ExecutionPolicy Bypass -File .\enhance_final_pools.ps1
```

Each builder writes its HTML next to itself. `enhance_final_pools.ps1` then injects
`assets/pool-ui.css` + `assets/pool-ui.js` into every page and regenerates `index.html`
(including the KPI counters, which are computed from the pages themselves).

Notes:

- `build_selection_pool.ps1` reads the legacy page from `source\`. Point it elsewhere with
  `-Source "<path>"` if needed. If you only care about the four rendered pages and never
  intend to rebuild, the `source/` folder can be deleted.
- Console encoding: scripts contain Chinese text, so if your terminal mangles output, run
  `chcp 65001` first (or just ignore the console text — the generated files are always UTF-8).
- Each builder has an optional `$Mirrors` / `$Mirror` list near the top for copying the
  generated page to additional directories. It is **empty by default** — nothing is written
  outside this folder unless you fill it in.

---

## Acceptance test / 验收

87 assertions over the five pages (record counts, field columns, sorting, category filters,
mark persistence, the JP comparison module, hub links, console/network errors):

```bash
npm i playwright-core
python -m http.server 8791 &        # in one shell
node _test/verify.mjs               # in another
```

Environment overrides: `BASE` (default `http://127.0.0.1:8791`), `PW_CORE` (explicit
playwright-core entry point), `CHROME_PATH` (use a specific Chromium instead of Playwright's
bundled one). Screenshots are written to `_test/out/` (git-ignored).

---

## Data sourcing note / 数据说明

Rows are compiled from publicly visible marketplace search results and brand/model specs at
the dates recorded in each script. Prices are the working conversions noted per pool
(JPY→RMB ≈ 0.048, MXN/USD and PLN floored per pool) and are indicative only — re-verify before
acting on them. Excluded by rule in all pools: consumables, batteries and cells, power
adapters/cables, and purely decorative parts.
