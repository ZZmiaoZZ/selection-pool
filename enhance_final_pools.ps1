$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

<#
  最终装配脚本
  1. 把 assets\pool-ui.css 与 assets\pool-ui.js 内联注入四个子页面，
     使每个 HTML 仍是可单独分享的自包含文件。
  2. 依据四个页面的真实数据统计，生成 index.html 主页面。

  历史缺陷修复说明（务必保留这段注释，避免以后重新踩坑）：
  旧版本把 <style> 直接拼在 </head> 之前，而模板里原始 <style> 的闭合标签
  在其后面，结果注入块落进了原始 <style> 内部。<style> 内是纯文本上下文，
  被注入的 "<style id=...>" 会被 CSS 解析器当成选择器，从而把紧随其后的
  整个 :root{--ink:...;--navy:...} 变量声明块一起丢弃。所有 var(--*) 全部失效，
  .home-link{background:var(--navy);color:#fff} 退化成白字透明底 —— 这就是
  「返回主页按钮看不见」的真正原因。
  现在改为在模板中显式放置 <!--FINAL-UI-ASSETS--> 锚点（位于 </style> 之后），
  并用 BEGIN/END 哨兵实现幂等重注入。
#>

$dir       = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$assetDir  = Join-Path $dir 'assets'
$cssPath   = Join-Path $assetDir 'pool-ui.css'
$jsPath    = Join-Path $assetDir 'pool-ui.js'

foreach ($p in @($cssPath, $jsPath)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "缺少共享资源：$p" }
}

$css = Get-Content -LiteralPath $cssPath -Raw
$js  = Get-Content -LiteralPath $jsPath  -Raw

# 内联注入的硬约束：资源内容里出现 style / script 的结束标签字面量时，
# 浏览器会在该处提前关闭元素，导致其后的样式或脚本全部失效（且不报错，极难排查）。
# 这里直接失败，不允许带病产出。
if ($css -match '</\s*style') { throw "pool-ui.css 内出现 style 结束标签字面量，会导致样式表提前截断，请改写该处文本。" }
if ($js  -match '</\s*script') { throw "pool-ui.js 内出现 script 结束标签字面量，会导致脚本提前截断，请改写该处文本。" }

$MARKER = '<!--FINAL-UI-ASSETS-->'
$BEGIN  = '<!--FINAL-UI-BEGIN-->'
$END    = '<!--FINAL-UI-END-->'

# 内联 favicon，避免用本地服务打开时浏览器请求 /favicon.ico 触发 404
$faviconB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $dir 'favicon.ico')))
$faviconTag = '<link rel="icon" type="image/x-icon" href="data:image/x-icon;base64,' + $faviconB64 + '">'

$block = $BEGIN + "`n" + $faviconTag + "`n<style id=""final-ui"">`n" + $css.Trim() + "`n</style>`n" +
         "<script id=""final-ui-js"">`n" + $js.Trim() + "`n</script>`n" + $END

# 页面清单：文件名 / 标题 / 副标题 / 站点标签 / 主键字段映射
$pages = @(
    [ordered]@{
        file     = 'AMZ美国站选品池.html'
        title    = 'AMZ 美国站选品池'
        site     = 'Amazon US'
        badge    = 'AMZ'
        desc     = '原「中国出口优先主池 + 优先开发池」已合并为单文件。覆盖全行业高客单方向，工具栏按「优先级 P1/P2/P3」即可定位当期优先开发子集。'
        brandKey = '品牌来源'
        cnMatch  = '^中国'
        catKey   = '品类'
    },
    [ordered]@{
        file     = 'MC墨西哥选品池.html'
        title    = 'MC 墨西哥选品池'
        site     = 'Mercado Libre MX'
        badge    = 'MC'
        desc     = '墨西哥站池。使用本地市场逻辑与 MXN 价格，不套用美国站 200 美元门槛；已剔除低价抛货类记录。'
        brandKey = 'source'
        cnMatch  = '^中国'
        catKey   = 'category'
    },
    [ordered]@{
        file     = 'AL波兰站选品池.html'
        title    = 'AL 波兰站选品池'
        site     = 'Allegro.pl'
        badge    = 'AL'
        desc     = '波兰站池。使用 PLN 价格，优先国内外都有保有量、欧洲有真实销售或使用、且能找到型号专用功能件的品牌。'
        brandKey = 'source'
        cnMatch  = '^中国'
        catKey   = 'category'
    },
    [ordered]@{
        file     = 'AMZ日本站选品池.html'
        title    = 'AMZ 日本站选品池'
        site     = 'Amazon JP'
        badge    = 'AMZ'
        desc     = '日本站池。使用 JPY 价格与日语搜索词，覆盖地震备电等本地刚需场景；支持勾选至多 3 条记录并排数据对比。'
        brandKey = 'source'
        cnMatch  = '^中国'
        catKey   = 'category'
    }
)

function Inject-Assets {
    param([string]$html, [string]$name)

    if ($html -match [regex]::Escape($BEGIN)) {
        $pattern = [regex]::Escape($BEGIN) + '.*?' + [regex]::Escape($END)
        $rx = New-Object System.Text.RegularExpressions.Regex($pattern, 'Singleline')
        return $rx.Replace($html, { param($m) $script:block }, 1)
    }
    if ($html.Contains($MARKER)) {
        return $html.Replace($MARKER, $block)
    }
    Write-Warning "$name 缺少 $MARKER 锚点，退回到 </head> 前插入（请检查生成脚本模板）。"
    $rx = New-Object System.Text.RegularExpressions.Regex('</head>', 'IgnoreCase')
    return $rx.Replace($html, { param($m) $script:block + '</head>' }, 1)
}

function Get-PageRows {
    param([string]$html)
    $m = [regex]::Match($html, '(?s)const data=(\[.*?\]);')
    if (-not $m.Success) { return @() }
    $json = $m.Groups[1].Value -replace '<\\/', '</'
    try { return @($json | ConvertFrom-Json) } catch { return @() }
}

$stats = @()

foreach ($page in $pages) {
    $path = Join-Path $dir $page.file
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "缺少 $($page.file)"; continue }

    $html = Get-Content -LiteralPath $path -Raw
    $html = Inject-Assets -html $html -name $page.file
    Set-Content -LiteralPath $path -Value $html -Encoding utf8

    $rows  = Get-PageRows -html $html
    $total = @($rows).Count
    $cn = 0; $cats = @{}
    foreach ($r in $rows) {
        $src = ''
        try { $src = [string]$r.$($page.brandKey) } catch { $src = '' }
        if ($src -match $page.cnMatch) { $cn++ }
        $c = ''
        try { $c = [string]$r.$($page.catKey) } catch { $c = '' }
        if ($c) { $cats[$c] = 1 }
    }

    # 必须用 PSCustomObject：Measure-Object -Property 无法读取 OrderedDictionary 的键
    $stats += [pscustomobject]@{
        file    = $page.file
        title   = $page.title
        site    = $page.site
        badge   = $page.badge
        desc    = $page.desc
        total   = $total
        cn      = $cn
        cats    = $cats.Keys.Count
    }
    Write-Output ("已装配：{0}（{1} 条，其中中国品牌/出口 {2} 条，{3} 个品类）" -f $page.file, $total, $cn, $cats.Keys.Count)
}

# ---------------- 生成 index.html ----------------

function HtmlEscape([string]$s) {
    if ($null -eq $s) { return '' }
    return $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

$today     = Get-Date -Format 'yyyy-MM-dd'
$grandTotal = ($stats | Measure-Object -Property total -Sum).Sum
$grandCn    = ($stats | Measure-Object -Property cn -Sum).Sum
if (-not $grandTotal) { $grandTotal = 0 }
if (-not $grandCn) { $grandCn = 0 }
$cnShare = if ($grandTotal -gt 0) { [math]::Round(100.0 * $grandCn / $grandTotal) } else { 0 }

$cards = ''
foreach ($s in $stats) {
    $cards += @"
<a class="card" href="$(HtmlEscape $s.file)">
  <div class="card-top">
    <span class="badge">$(HtmlEscape $s.badge)</span>
    <span class="site">$(HtmlEscape $s.site)</span>
  </div>
  <h2>$(HtmlEscape $s.title)</h2>
  <p class="card-desc">$(HtmlEscape $s.desc)</p>
  <div class="card-stats">
    <span><b>$($s.total)</b> 条记录</span>
    <span><b>$($s.cn)</b> 条中国品牌/供应链</span>
    <span><b>$($s.cats)</b> 个品类</span>
  </div>
  <span class="card-go">打开选品池 <em>&rarr;</em></span>
</a>
"@
}

$readmeCss = @'
:root{--ink:#141c2b;--ink-soft:#3c4a60;--muted:#66748c;--faint:#8c9ab0;--line:#dbe3ee;--navy:#14243c;--accent:#2563eb;--cn:#c0243c;--surface:#fff;--radius:14px}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;color:var(--ink);font-family:"Microsoft YaHei","PingFang SC",-apple-system,"Segoe UI",Arial,sans-serif;-webkit-font-smoothing:antialiased;background:#eef3f9;background-image:radial-gradient(1100px 520px at 12% -8%,#e2ecff 0,rgba(226,236,255,0) 62%),radial-gradient(900px 480px at 92% 4%,#e6f6f1 0,rgba(230,246,241,0) 58%),linear-gradient(180deg,#f7fafe 0,#eef3f9 100%)}
main{max-width:1200px;margin:0 auto;padding:clamp(30px,5.5vw,68px) clamp(16px,4vw,44px) 64px}
header{margin-bottom:clamp(26px,4vw,40px)}
.eyebrow{display:inline-flex;align-items:center;gap:9px;color:var(--accent);font-size:11.5px;font-weight:800;letter-spacing:.13em;text-transform:uppercase}
.eyebrow:before{content:"";width:26px;height:3px;background:var(--accent);border-radius:2px}
h1{font-size:clamp(27px,4.2vw,46px);line-height:1.14;margin:15px 0 14px;letter-spacing:-.025em;font-weight:800}
.lede{max-width:780px;color:var(--ink-soft);line-height:1.85;font-size:15px;margin:0}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin:26px 0 0}
.kpi{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:15px 17px;box-shadow:0 1px 2px rgba(16,32,56,.05),0 8px 22px -14px rgba(16,32,56,.22)}
.kpi b{display:block;font-size:27px;line-height:1.15;letter-spacing:-.02em;color:var(--navy);font-variant-numeric:tabular-nums}
.kpi span{display:block;margin-top:4px;color:var(--muted);font-size:12px}
.kpi.cn b{color:var(--cn)}
.section-title{display:flex;align-items:baseline;gap:11px;margin:clamp(30px,4.5vw,46px) 0 15px}
.section-title h2{font-size:19px;margin:0;letter-spacing:-.01em}
.section-title span{color:var(--faint);font-size:12.5px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:15px}
.card{position:relative;display:flex;flex-direction:column;background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:20px;text-decoration:none;color:inherit;box-shadow:0 1px 2px rgba(16,32,56,.05),0 10px 26px -18px rgba(16,32,56,.28);transition:transform .18s ease,box-shadow .18s ease,border-color .18s ease}
.card:hover{transform:translateY(-3px);border-color:#b9cdeb;box-shadow:0 4px 10px rgba(16,32,56,.07),0 20px 40px -20px rgba(16,32,56,.32)}
.card:focus-visible{outline:3px solid rgba(37,99,235,.35);outline-offset:3px}
.card-top{display:flex;align-items:center;gap:8px;margin-bottom:11px}
.badge{background:var(--navy);color:#fff;font-size:10.5px;font-weight:800;letter-spacing:.05em;padding:3px 9px;border-radius:999px}
.site{color:var(--faint);font-size:11.5px;font-weight:600;letter-spacing:.02em}
.card h2{font-size:17px;margin:0 0 8px;letter-spacing:-.01em}
.card-desc{flex:1 1 auto;margin:0 0 14px;color:var(--ink-soft);font-size:13px;line-height:1.72}
.card-stats{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:15px}
.card-stats span{background:#f4f7fc;border:1px solid #e4ebf5;border-radius:999px;padding:4px 10px;color:var(--muted);font-size:11.5px}
.card-stats b{color:var(--navy);font-weight:800;font-variant-numeric:tabular-nums}
.card-go{display:inline-flex;align-items:center;gap:7px;align-self:flex-start;background:var(--navy);color:#fff;padding:9px 15px;border-radius:9px;font-size:12.5px;font-weight:700}
.card:hover .card-go{background:#1e3a5f}
.card-go em{font-style:normal;font-size:15px;line-height:1;transition:transform .18s ease}
.card:hover .card-go em{transform:translateX(3px)}
.panels{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:15px}
.panel{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:18px 20px;box-shadow:0 1px 2px rgba(16,32,56,.05)}
.panel h3{margin:0 0 11px;font-size:14.5px;display:flex;align-items:center;gap:7px}
.panel h3:before{content:"";width:3px;height:15px;background:var(--accent);border-radius:2px}
.panel.keep h3:before{background:#0f7b52}
.panel.drop h3:before{background:var(--cn)}
.panel ul{margin:0;padding-left:18px;color:var(--ink-soft);font-size:13px;line-height:1.85}
.panel li{margin:3px 0}
.panel code{background:#f2f6fb;border:1px solid #e2e9f3;border-radius:4px;padding:1px 5px;font-size:11.5px;color:var(--navy);font-family:ui-monospace,Consolas,monospace}
.flow{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:18px 20px;box-shadow:0 1px 2px rgba(16,32,56,.05)}
.flow ol{margin:0;padding-left:20px;color:var(--ink-soft);font-size:13px;line-height:1.9}
.flow b{color:var(--ink)}
.flow code{background:#f2f6fb;border:1px solid #e2e9f3;border-radius:4px;padding:1px 5px;font-size:11.5px;color:var(--navy);font-family:ui-monospace,Consolas,monospace}
footer{margin-top:clamp(30px,4.5vw,44px);padding-top:17px;border-top:1px solid var(--line);color:var(--faint);font-size:12px;line-height:1.8}
@media (max-width:640px){.kpi b{font-size:23px}h1{font-size:26px}}
'@

$readme = @"
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>最终版｜跨站选品池目录</title>
<link rel="icon" type="image/x-icon" href="data:image/x-icon;base64,$faviconB64">
<style>
$readmeCss
</style>
</head>
<body>
<main>
<header>
  <div class="eyebrow">Cross-Marketplace Selection Pool</div>
  <h1>最终版｜跨站选品池</h1>
  <p class="lede">统一入口。四个站点池共用一套表格结构与本机记忆机制：每条记录都保留品牌中英文名、英文型号、拆机/替换升级件、状态与备注；「状态」和「备注」按内容标识保存在本机浏览器，筛选、排序、刷新都不会串行或丢失。标有「【候选类目】」的记录为第二轮评审引入的方向性候选（型号与 listing 待核验）；日本站支持勾选至多 3 条记录并排数据对比。</p>
  <div class="kpis">
    <div class="kpi"><b>$grandTotal</b><span>全站记录合计</span></div>
    <div class="kpi cn"><b>$grandCn</b><span>中国品牌 / 供应链（占 $cnShare%）</span></div>
    <div class="kpi"><b>$($stats.Count)</b><span>站点选品池</span></div>
    <div class="kpi"><b>$today</b><span>最近装配日期</span></div>
  </div>
</header>

<div class="section-title"><h2>站点选品池</h2><span>点击卡片进入，页面内可搜索、多维筛选并逐条标记</span></div>
<div class="grid">
$cards
</div>

<div class="section-title"><h2>纳入与排除标准</h2><span>由生成脚本强制执行，不靠人工记忆</span></div>
<div class="panels">
  <div class="panel keep">
    <h3>必须保留的字段</h3>
    <ul>
      <li>品牌中文名 + 品牌英文名</li>
      <li>型号（英文，海外页面实际在用的写法）</li>
      <li>拆机/替换升级件（可搜核心件 + 高价值非耗材替换/升级件）</li>
      <li>状态（未处理 / 掌握了 / 不做 / 待定）</li>
      <li>备注（自由文本，本机保存）</li>
    </ul>
  </div>
  <div class="panel drop">
    <h3>明确排除的方向</h3>
    <ul>
      <li>耗材（滤芯、滤网、刀片、喷嘴、打印材料等）</li>
      <li>电池与电芯</li>
      <li>电源适配器、充电器、线缆</li>
      <li>低价抛货（按各站低价区间剔除，不进入主池）</li>
      <li>纯装饰件（贴纸、外观壳、灯效等无功能件）</li>
    </ul>
  </div>
  <div class="panel">
    <h3>中国品牌标识</h3>
    <ul>
      <li>品牌来源含「中国」的记录，中英文品牌名均以<strong style="color:var(--cn)">红色加粗</strong>显示</li>
      <li>单元格附左侧红色标线与「中国」角标</li>
      <li>各池工具栏可按品牌来源直接筛选</li>
    </ul>
  </div>
</div>

<div class="section-title"><h2>数据流转与重新生成</h2><span>改数据或改结构都要动脚本，不要只改最终 HTML</span></div>
<div class="flow">
<ol>
  <li><b><code>build_selection_pool.ps1</code></b>：读取旧版美国站网页提取基础记录，做品牌中英文归一、拆机件补全、排除规则过滤、优先级排序与连续重编号，输出<b>AMZ美国站选品池</b>单页（原主池与优先池已合并，工具栏「优先级」可筛 P1/P2/P3）。</li>
  <li><b><code>build_mexico_pool.ps1</code></b>：内置 Mercado Libre México 记录，按 18 MXN = 1 USD 工作汇率折算并过滤低价抛货，输出<b>MC墨西哥选品池</b>。</li>
  <li><b><code>build_poland_pool.ps1</code></b>：内置 Allegro.pl 记录，使用 PLN 价格与近期购买信号，输出<b>AL波兰站选品池</b>。</li>
  <li><b><code>build_japan_pool.ps1</code></b>：内置 Amazon.co.jp 记录，使用 JPY 价格与日语搜索词，按 1 RMB ≈ 20.8 JPY 工作换算并过滤低价抛货，输出<b>AMZ日本站选品池</b>。</li>
  <li><b><code>enhance_final_pools.ps1</code></b>：把 <code>assets\pool-ui.css</code> 与 <code>assets\pool-ui.js</code> 内联注入五个页面的 <code>&lt;!--FINAL-UI-ASSETS--&gt;</code> 锚点，并按真实数据重新生成本页。</li>
</ol>
<p style="margin:13px 0 0;color:var(--muted);font-size:12.5px">完整重建顺序：先跑四个 <code>build_*.ps1</code>，再跑 <code>enhance_final_pools.ps1</code>。共享样式与交互只改 <code>assets\</code> 下的两个文件，改完重跑装配脚本即可同步到全部页面。</p>
</div>

<footer>
装配日期：$today｜共 $($stats.Count) 个子页面、$grandTotal 条记录。<br>
页面数据来自各站公开搜索页当日可见的在售、评价与榜单标签，不等同于后台真实成交量；品牌中文名按国内常用叫法或音译展示，正式开发前请按具体型号代际、商标、专利、认证和平台规则复核。
</footer>
</main>
</body>
</html>
"@

$readmePath = Join-Path $dir 'index.html'
Set-Content -LiteralPath $readmePath -Value $readme -Encoding utf8
Write-Output ("已生成主页面：index.html（合计 {0} 条，中国品牌/供应链 {1} 条，占 {2}%）" -f $grandTotal, $grandCn, $cnShare)
