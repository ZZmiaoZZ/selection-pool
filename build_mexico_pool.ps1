$ErrorActionPreference = 'Stop'

<#
  墨西哥 Mercado Libre 高客单型号选品池生成器

  统一表格结构（与其他三个池保持一致）：
    排序 / 品类 / 品牌中文名 / 品牌英文名 / 型号（英文） / MXN在售区间 / USD工作换算 /
    西语搜索词 / 拆机可搜核心件 / 品牌来源 / 开发判断 / 状态 / 备注

  排除规则（要求 4）由 $excludeKeyword / $usdFloor 强制执行：
    耗材、电池、电源适配器、纯装饰件一律不进池；
    墨西哥站不设美国站 200 美元门槛，但低于 $usdFloor 美元的整机按「低价抛货」剔除。
#>

$dir     = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$out     = Join-Path $dir 'MC墨西哥选品池.html'

# 可选：生成后再把同一份页面复制到其他目录（留空 = 不复制）。
# 例如：$Mirror = @('D:\mirror\MC墨西哥选品池.html')
$Mirror = @()

# usd 字段的工作换算下限：低于此值视为低价抛货，只做市场观察，不进选品池。
$usdFloor = 150

# 品类 / 型号 / 拆机件命中以下任一关键词即剔除（耗材、电池、电源适配器、纯装饰件）。
$excludeKeyword = @(
  '耗材','滤芯','滤网','滤棉','刀片','喷嘴','墨盒','碳带','打印耗材','清洁剂','咖啡豆',
  '电池','电芯','锂电','battery',
  '电源适配器','充电器','适配器','电源线','数据线','charger','adapter',
  '装饰件','贴纸','贴膜','外观件','灯带','装饰灯','纯装饰'
)

$dataJson = @'
[
 {"category":"咖啡机","brandCn":"铂富","brandEn":"Breville","model":"Barista Express BES870 / Barista Touch BES880","mxn":"$12,249–25,999","usd":"约 US$681–1,444","search":"cafetera Breville Barista Express BES870","parts":"冲煮头导轨、泵阀支架、磨豆机维修结构、滴水盘总成、无底手柄","source":"海外品牌；中国兼容维修供应链中等","fit":"高客单、型号专用功能件；不做咖啡豆和清洁耗材"},
 {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Mini 5 Pro Fly More Combo / Mini 4 Pro","mxn":"$19,647–23,599","usd":"约 US$1,092–1,311","search":"DJI Mini 5 Pro Combo","parts":"云台保护架、起落架、遥控器支架、运输内架、快拆安装件","source":"中国出口品牌；中国替换件可得性高","fit":"优先结构/保护/安装件；不做电池和桨叶耗材"},
 {"category":"3D打印机","brandCn":"拓竹","brandEn":"Bambu Lab","model":"P1S Combo AMS / X1 Carbon","mxn":"$15,388–20,200","usd":"约 US$855–1,122","search":"impresora 3D Bambu Lab P1S Combo AMS","parts":"腔体门铰链/锁扣、AMS 驱动结构、挤出机安装座、导轨张紧件","source":"中国出口品牌；中国替换件可得性高","fit":"型号专用机械升级件；不做喷嘴和打印耗材"},
 {"category":"扫地机器人","brandCn":"石头","brandEn":"Roborock","model":"QR798 / Q7 L5+ / Q10 S5","mxn":"$6,499–19,999","usd":"约 US$361–1,111","search":"robot aspirador Roborock QR798 Q7 L5","parts":"污水箱、滚刷仓结构、底座、风道、停靠支架","source":"中国出口品牌；中国替换件可得性高","fit":"优先结构/底座/停靠件；不做滤芯滚刷等耗材"},
 {"category":"投影仪","brandCn":"爱普生","brandEn":"Epson","model":"Home Cinema 4010 / PowerLite 980W","mxn":"$20,791–34,998","usd":"约 US$1,155–1,944","search":"proyector Epson Home Cinema 4010 PowerLite 980W","parts":"吊装/VESA 转接、镜头滑盖、散热风道、运输内架、线缆应力固定","source":"海外品牌；中国显示配套和结构件中等","fit":"优先型号专用安装/散热件；不做灯泡耗材"},
 {"category":"商用制冰/碎冰设备","brandCn":"瓦特迈克斯","brandEn":"Wattmax","model":"50 kg/24 h Commercial Ice Crusher","mxn":"$3,799–3,999","usd":"约 US$211–222","search":"trituradora de hielo comercial 50kg 24hrs","parts":"料斗盖、刀盘护罩、机架、脚轮底座、排料导流结构","source":"海外/中国供应链待核；需先确认品牌与型号","fit":"仅做功能结构件；不做刀片耗材和电机"},
 {"category":"商用制冰/碎冰设备","brandCn":"齿轮IX","brandEn":"GEARIX","model":"500 lb/h Commercial Ice Crusher","mxn":"$3,464–6,266","usd":"约 US$192–348","search":"trituradora hielo comercial industrial 500 lb/h","parts":"机架、料斗盖、护罩、排料结构、运输固定件","source":"品牌/中国供应链待核","fit":"仅当具体 listing ≥ US$200 时进入开发；不做刀片耗材"},
 {"category":"家用/商用制雪","brandCn":"诺斯特尔吉亚","brandEn":"Nostalgia","model":"NSCM525WH Snow Cone Machine","mxn":"$1,999","usd":"约 US$111（工作换算）","search":"máquina raspados Nostalgia NSCM525WH","parts":"料斗盖、刀盘护罩、机架、收纳结构","source":"海外品牌；中国替换件可得性待核","fit":"低价设备仅作市场观察，不作为高客单优先开发"}
]
'@

$mxExtraJson = @'
[
 {"category":"便携储能电源","brandCn":"正浩","brandEn":"EcoFlow","model":"DELTA 2 Max / DELTA Pro 3","mxn":"$45,999–59,999","usd":"约 US$2,555–3,333","search":"estación de energía portátil EcoFlow DELTA 2 Max","parts":"逆变器板、BMS 控制板、散热风道、AC 面板总成、机架和提手结构（电芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥电网波动与停电频繁，备电+户外露营双刚需；先核验 Mercado Libre 在售与保修，再定型号专用件"},
 {"category":"美容仪器","brandCn":"觅光","brandEn":"AMIRO","model":"R1 PRO / S1 Pro","mxn":"$6,499–7,999","usd":"约 US$361–444","search":"AMIRO R1 PRO mascara LED facial dispositivo","parts":"主控板、射频/LED 输出模组、温度传感器、探头支架、磁吸充电底座和外壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥护肤品类销量领先（大促数据）；高客单美容仪为增量方向，注意 COFEPRIS 合规边界"},
 {"category":"行车记录仪","brandCn":"70迈","brandEn":"70mai","model":"A810 / A800SE","mxn":"$3,299–4,199","usd":"约 US$183–233","search":"70mai A810 camara para carro 4K","parts":"主控板、图像传感器模组、GPS 模块、镜头座、散热结构和吸盘/静电贴支架总成（存储卡不做）","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥汽车保有量大且车险安装记录仪需求增长；优先支架与散热件"},
 {"category":"电动工具","brandCn":"威克士","brandEn":"WORX","model":"20V Brushless Hammer Drill WX358","mxn":"$4,999–6,499","usd":"约 US$278–361","search":"WORX WX358 taladro percutor inalámbrico 20V","parts":"主控板、无刷电机、齿轮箱、钻夹头、电池接口板（电池不做）和机壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥大促家居工业类增速84%；DIY 用户对 20V 平台接受度上升；不做电池与充电器"},
 {"category":"咖啡机","brandCn":"HiBREW","brandEn":"HiBREW","model":"H10A / H11B","mxn":"$3,999–5,499","usd":"约 US$222–305","search":"cafetera espresso HiBREW H10A 20 bar","parts":"主控板、泵、电磁阀、加热块、温度传感器、磨豆机齿轮箱和滴水盘总成","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥咖啡文化深厚（咖啡类目搜索量巨大）；家用半自动咖啡机为中国出口增量方向；不做咖啡豆与清洁耗材"},
 {"category":"安防摄像套装","brandCn":"睿联","brandEn":"Reolink","model":"RLC-810A + RLN8-410 8CH Kit","mxn":"$6,999–8,999","usd":"约 US$389–500","search":"Reolink RLC-810A kit camaras seguridad 8 canales","parts":"PoE 主板、镜头/IR 补光模组、防水壳体、壁装支架和 NVR 背板（硬盘与电源不做）","source":"中国出口品牌；中国替换件可得性高","fit":"【候选类目】墨西哥住宅与商铺安防需求刚性；PoE 套装客单高；优先支架、防水壳和背板件"}
]
'@

$rows = @(@($dataJson | ConvertFrom-Json) + @($mxExtraJson | ConvertFrom-Json))

function Test-Excluded {
    param($row)
    $hay = @([string]$row.category, [string]$row.model, [string]$row.parts, [string]$row.fit) -join ' '
    foreach ($kw in $script:excludeKeyword) {
        # 「不做电池」这类说明性文字不算命中：只在品类和型号上做硬排除
        $target = @([string]$row.category, [string]$row.model) -join ' '
        if ($target -match [regex]::Escape($kw)) { return "命中排除关键词：$kw" }
    }
    # usd 形如「约 US$681–1,444」「约 US$111（工作换算）」，取第一个数字做下限判断
    $m = [regex]::Match([string]$row.usd, '([\d,]+(?:\.\d+)?)')
    if ($m.Success) {
        $v = [double](($m.Groups[1].Value) -replace ',', '')
        if ($v -lt $script:usdFloor) { return ("低价抛货：工作换算 {0} USD 低于下限 {1} USD" -f $v, $script:usdFloor) }
    }
    return $null
}

$kept = New-Object System.Collections.ArrayList
foreach ($r in $rows) {
    $why = Test-Excluded -row $r
    if ($why) { Write-Output ("已剔除 {0} {1}｜{2}" -f $r.brandEn, $r.model, $why); continue }
    [void]$kept.Add($r)
}

for ($i = 0; $i -lt $kept.Count; $i++) {
    $kept[$i] | Add-Member -NotePropertyName rank -NotePropertyValue ($i + 1) -Force
}

$json = @($kept) | ConvertTo-Json -Depth 8 -Compress
$json = $json -replace '</', '<\/'

$css = @'
:root{font-family:"Microsoft YaHei",Arial,sans-serif;color:#172033;background:#f4f7fb}
*{box-sizing:border-box}
body{margin:0;padding:24px}
h1{font-size:26px;margin:0 0 8px}
.note{color:#536176;line-height:1.65}
.legend{display:flex;gap:8px;flex-wrap:wrap;margin:14px 0}
.legend span{padding:5px 9px;border-radius:4px;font-size:12px;font-weight:700}
.ok{background:#dcfce7;color:#166534}
.wait{background:#fef3c7;color:#92400e}
.export{color:#b91c1c;font-weight:800}
.toolbar{display:flex;gap:9px;flex-wrap:wrap;background:#fff;border:1px solid #d7e0ec;padding:12px}
input,select,button{font:inherit;padding:8px;border:1px solid #b8c6d8;border-radius:5px}
table{border-collapse:collapse;width:100%;background:#fff;font-size:12.5px;margin-top:14px}
th{background:#132238;color:#fff;padding:9px;text-align:left;white-space:nowrap}
td{border:1px solid #d7e0ec;padding:8px;vertical-align:top;line-height:1.45}
.footer{color:#6b778a;font-size:12px;margin-top:16px}
'@

$template = @'
<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MC墨西哥选品池</title>
<style>
__CSS__
</style>
<!--FINAL-UI-ASSETS-->
</head><body>
<h1>MC墨西哥选品池</h1>
<p class="note">更新日期：__DATE__。主表按 Mercado Libre México 公开搜索页制作，保留页面有在售 / 评分 / “MÁS VENDIDO” 信号，且中国能找到型号专用功能替换件或改装件的方向。MXN→USD 仅按 18 MXN = US$1 的工作汇率折算，发布前按当天汇率复核。墨西哥站不设置美国站 200 美元门槛，但工作换算低于 US$__FLOOR__ 的整机按低价抛货剔除。已排除耗材、电池、电源适配器、纯装饰件和低价抛货。</p>
<div class="legend"><span class="export">中国品牌 / 出口（红色加粗 + 中国角标）</span></div>
<div class="toolbar">
<input id="search" placeholder="搜索品牌、型号、西语关键词、拆机件…">
<select id="category"><option value="">全部品类</option></select>
<select id="source"><option value="">全部品牌来源</option><option value="中国">中国品牌 / 出口</option><option value="海外">海外品牌</option></select>
<select id="statusFilter"><option value="">全部状态</option><option value="未处理">未处理</option><option value="掌握了">掌握了</option><option value="不做">不做</option><option value="待定">待定</option></select>
<button id="resetStatus" class="ghost" type="button">清空状态与备注</button>
<span id="count"></span>
</div>
<div class="table-wrap"><table id="grid"><thead><tr>
<th>排序</th><th>品类</th><th>品牌中文名</th><th>品牌英文名</th><th>型号（英文）</th>
        <th>MXN在售区间</th><th>USD工作换算</th><th>西语/英文搜索词</th>
        <th>拆机可搜核心件</th><th>品牌来源</th><th>开发判断</th><th>状态</th><th>备注</th>
</tr></thead><tbody></tbody></table></div>
<p class="footer">“已核验”指公开搜索页当日可见的在售、评分或 MÁS VENDIDO 标签，不等同于后台真实成交量；美客多页面会随地区、库存和登录状态变化。整机含电池的设备只是不开发电池本身。</p>
<script>
const data=__DATA__;
const PAGE_KEY='mexico-mercadolibre';
const store=new PoolUI.Store(PAGE_KEY,[]);
const esc=PoolUI.esc;
const el=id=>document.getElementById(id);
const search=el('search'),category=el('category'),source=el('source'),statusFilter=el('statusFilter');
const tbody=document.querySelector('#grid tbody');
function idOf(r){return [r.category,r.brandEn,r.model].join('|')}

function isCn(r){return /^中国/.test(String(r.source))}
PoolUI.mountChrome({home:'index.html'});
const cats=[...new Set(data.map(r=>r.category))].sort((a,b)=>a.localeCompare(b,'zh-CN'));
category.innerHTML+=cats.map(c=>'<option value="'+esc(c)+'">'+esc(c)+'</option>').join('');
function render(){
  const q=search.value.trim().toLowerCase(),c=category.value,src=source.value,sf=statusFilter.value;
  const out=data.filter(r=>{
    const st=store.status(idOf(r));
    const cn=isCn(r);
    return (!q||Object.values(r).some(v=>String(v).toLowerCase().includes(q)))
      &&(!c||r.category===c)
      &&(!src||(src==='中国'?cn:!cn))&&(!sf||st===sf);
  });
  tbody.innerHTML=out.length?out.map(r=>{
    const id=idOf(r),st=store.status(id),cn=isCn(r),bc=cn?' class="brand-export"':'',badge=cn?PoolUI.cnBadge():'';
    return '<tr class="'+PoolUI.rowClass(st)+'">'
      +'<td>'+esc(r.rank)+'</td>'
      +'<td>'+esc(r.category)+'</td>'
      +'<td'+bc+'>'+esc(r.brandCn)+badge+'</td>'
      +'<td'+bc+'>'+esc(r.brandEn)+'</td>'
      +'<td class="model-cell">'+esc(r.model)+'</td>'
      +'<td>'+esc(r.mxn)+'</td>'
      +'<td>'+esc(r.usd)+'</td>'
      +'<td>'+esc(r.search)+'</td>'
      +'<td class="parts-cell">'+esc(r.parts)+'</td>'
      +'<td'+bc+'>'+esc(r.source)+'</td>'
      +'<td>'+esc(r.fit)+'</td>'
      +PoolUI.statusCellHtml(id,st)
      +PoolUI.noteCellHtml(id,store.note(id))
      +'</tr>';
  }).join(''):'<tr class="empty-row"><td colspan="13">没有符合当前筛选条件的记录</td></tr>';
  PoolUI.setCount(out.length,data.length,store.marked());
}
function refilter(){PoolUI.withFocusKept(render)}
PoolUI.bindTable(tbody,store,{onStatus:()=>{PoolUI.setCount(document.querySelectorAll('#grid tbody tr:not(.empty-row)').length,data.length,store.marked());if(statusFilter.value)refilter()},onNote:()=>PoolUI.setCount(document.querySelectorAll('#grid tbody tr:not(.empty-row)').length,data.length,store.marked())});
[search].forEach(x=>x.addEventListener('input',refilter));
[category,source,statusFilter].forEach(x=>x.addEventListener('change',refilter));
el('resetStatus').addEventListener('click',()=>{if(!confirm('清空本页所有状态与备注？该操作不可撤销。'))return;store.clear([]);search.value='';category.value='';source.value='';statusFilter.value='';render()});
render();
</script>
</body></html>
'@

$html = $template.Replace('__CSS__', $css.Trim()).
                  Replace('__DATA__', $json).
                  Replace('__DATE__', (Get-Date -Format 'yyyy-MM-dd')).
                  Replace('__FLOOR__', [string]$usdFloor)

Set-Content -LiteralPath $out -Value $html -Encoding utf8
Write-Output "已生成：$out"
Write-Output "记录数：$($kept.Count)"

foreach ($m in $Mirror) {
    $md = Split-Path -Parent $m
    if (Test-Path -LiteralPath $md) {
        Set-Content -LiteralPath $m -Value $html -Encoding utf8
        Write-Output "已同步：$m"
    }
}
