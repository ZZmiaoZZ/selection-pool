<#
  亚马逊美国站（Amazon.com）选品池生成器

  数据来源：旧版《全行业高客单型号选品池》HTML，默认从本目录 source\ 下读取。
  换路径的两种方式：
    1) 把旧版 HTML 放到 .\source\全行业高客单型号选品池.html；
    2) 运行时显式指定： .\build_selection_pool.ps1 -Source "D:\你的路径\xxx.html"

  输出：本脚本所在目录下的 AMZ美国站选品池.html
#>
param(
  [string]$Source
)

$ErrorActionPreference = 'Stop'

$dir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

if (-not $Source) { $Source = Join-Path $dir 'source\全行业高客单型号选品池.html' }
if (-not (Test-Path -LiteralPath $Source)) {
  throw "找不到数据源文件：$Source`n请把旧版《全行业高客单型号选品池》HTML 放入 source\ 目录，或用 -Source <路径> 指定。"
}

$output = Join-Path $dir 'AMZ美国站选品池.html'

$oldHtml = Get-Content -LiteralPath $Source -Raw
$dataMatch = [regex]::Match($oldHtml, '(?s)const data=(\[.*?\]);\s*const recommendations=')
$recMatch = [regex]::Match($oldHtml, '(?s)const recommendations=(\[.*?\]);\s*const stateKey=')
if (-not $dataMatch.Success -or -not $recMatch.Success) { throw '未能从旧网页提取数据。' }
$rows = @($dataMatch.Groups[1].Value | ConvertFrom-Json)
$recommendations = @($recMatch.Groups[1].Value | ConvertFrom-Json)

# 纠正已知的出口热卖型号，避免只写泛系列。
foreach ($row in $rows) {
    if ([string]$row.'品牌' -eq 'Zebra' -and [string]$row.'品类' -eq '标签打印机') {
        $row.'推荐型号或型号族' = 'ZD421、ZD621、ZT411、ZT610'
    }
}

# 热度推荐按秋冬窗口重设；型号字段只保留海外页面使用的英文型号名。
$recommendations = @(@'
[
  {"season":"秋季高使用","category":"空气处理","brand":"Midea / Levoit / Dyson / Venta","model":"Midea MAPF Series / Levoit Classic 600S / Dyson PH01 / Venta LW45","reason":"秋季进入室内空气和湿度管理窗口，海外渠道保有量与结构件需求较稳定","direction":"Base, air duct, wall mount, sensor protection, water tank and anti-tip structure"},
  {"season":"秋季高使用","category":"加湿器","brand":"Midea / Deerma / Smartmi / Philips","model":"Midea Overseas Humidifier Series / Deerma DEM-F Series / Smartmi Evaporative Humidifier 2 / Philips HU Series","reason":"干燥季前置开发，国内品牌出口型号多，水箱和底座等非耗材件容易打样","direction":"Water tank shell, base, float, mist chamber protection and anti-tip structure"},
  {"season":"秋冬高使用","category":"除湿机","brand":"Midea / Haier / Frigidaire / hOmeLabs","model":"Midea Cube / Haier Basement Dehumidifier / Frigidaire Gallery / hOmeLabs 4,500 SF","reason":"地下室、洗衣房和沿海家庭在秋冬仍有持续除湿需求，排水改装客单价较好","direction":"Continuous-drain adapter, caster base, air duct and condensate structure"},
  {"season":"秋冬高使用","category":"家庭健身","brand":"WalkingPad / Speediance / Yesoul / Merach","model":"WalkingPad R2 Pro / X25 / Speediance Gym Monster / Yesoul R1 / Merach Rower Series","reason":"天气转冷后室内健身使用率上升，中国出口品牌和配件工厂集中","direction":"Handrail, tablet mount, floor protection, storage and transport structure"},
  {"season":"冬季提前布局","category":"雪地摩托","brand":"Ski-Doo / Polaris / Arctic Cat","model":"Ski-Doo Summit / Polaris RMK / Arctic Cat M Series","reason":"北美入冬前是风挡、脚踏、护板和行李结构的备货窗口","direction":"Windshield, running board, skid plate, luggage rack and handguard"},
  {"season":"秋冬高使用","category":"投影仪","brand":"Nebula / XGIMI / JMGO / Epson / BenQ","model":"Nebula Capsule 3 Laser / X1 / Cosmos 4K SE / XGIMI Horizon Ultra / JMGO N1 Ultra / Epson Home Cinema 5050UB / BenQ HT4550i","reason":"美国站秋冬室内影音需求增加；优先高客单便携、家庭影院和游戏投影，并核查具体型号BSR与竞品数","direction":"Model-specific gimbal lock, ceiling mount, lens cover, cooling duct, service door and transport fixture"},
  {"season":"秋冬高使用","category":"智能宠物设备","brand":"PETKIT / CATLINK","model":"PETKIT Pura Max 2 / CATLINK Scooper Pro","reason":"室内宠物设备全年销售，秋冬居家时间增加，外壳、底座和安装件可做","direction":"Waste-bin structure, base, ramp, sensor protection and cable management"},
  {"season":"秋冬高使用","category":"家庭机器人","brand":"Loona / KEYi Tech","model":"Loona Smart Robot","reason":"美国站高客单家庭机器人，秋冬室内陪伴和互动场景增强；中国品牌，功能结构件有供应链基础","direction":"Charging dock alignment, wheel/steering mechanism, gimbal camera guard, bumper structure and transport fixture"},
  {"season":"秋冬高使用","category":"冰淇淋机","brand":"Spaceman / Donper / Taylor / Carpigiani","model":"Spaceman 6210-C / Donper Commercial Series / Taylor C708 / Carpigiani LB Series","reason":"商用餐饮、酒店和连锁门店全年使用，秋冬室内消费和节庆餐饮仍有设备需求","direction":"Hopper cover, caster base, door assembly, beater guard and service-panel structure"},
  {"season":"冬季提前布局","category":"造雪机","brand":"SMI Snow Makers / HKD Snowmakers / TechnoAlpin / Demaclenko","model":"SMI Super PoleCat / HKD SnowGun / TechnoAlpin TF Series / Demaclenko EOS","reason":"北美和欧洲雪场在冬季前集中采购和检修，非核心结构件可提前开发","direction":"Snow-gun frame, swivel base, hose guide, protective cover and maintenance platform"},
  {"season":"冬季提前布局","category":"雪道压雪机","brand":"Prinoth / PistenBully / Tucker Sno-Cat","model":"Prinoth Bison / Prinoth Leitwolf / PistenBully 600 / Tucker Sno-Cat 2000","reason":"美国滑雪场在开季前集中检修和备件采购，压雪车属于高客单核心设备","direction":"Groomer blade frame, tiller cover, track guard, work lights mount and service platform"},
  {"season":"冬季高使用","category":"冰场刮冰车","brand":"Zamboni / Resurfice Olympia","model":"Zamboni 552 / Zamboni 525 / Olympia Millennium H / Olympia CCT","reason":"冰球馆、大学和城市冰场冬季使用频繁，车体结构和维护件有长期需求","direction":"Blade carrier, water-tank mount, side panel, caster and service access structure"},
  {"season":"秋冬高使用","category":"滑雪板维修设备","brand":"Wintersteiger / Montana Sport / Reichmann","model":"Wintersteiger Mercury / Montana Saphir / Reichmann Profi","reason":"雪场、滑雪店和租赁中心在冬季前集中保养设备，耐用维修结构件客单价较高","direction":"Ski vise, grinding guard, work stand, dust hood and machine enclosure"},
  {"season":"冬季高使用","category":"商用除雪设备","brand":"Bobcat / John Deere / Honda / BOSS Snowplow","model":"Bobcat Toolcat 5600 / John Deere 1025R / Honda HSS1332A / BOSS V-XT","reason":"美国住宅、商业园区和市政道路冬季除雪刚需，主机附件和安装结构供应链成熟","direction":"Snow-blower chute, plow mount, caster, hydraulic hose guide and protective frame"},
  {"season":"冬季提前布局","category":"融雪与冰场设备","brand":"Henderson / Trecan / CIMCO","model":"Henderson V-Box / Trecan 60-PD / CIMCO Ice Rink System","reason":"市政道路融雪、雪场融雪和冰场制冷均为冬季工程设备，项目客单价高","direction":"Spreader hopper frame, snow-melter access panel, refrigeration skid frame and pipe guard"},
  {"season":"全年高客单","category":"咖啡机","brand":"Breville","model":"Barista Express / Barista Pro / Dual Boiler","reason":"美国站高客单咖啡机主流品牌，先验证整机BSR、评论和配件成交，再决定型号","direction":"Model-specific brew-head rail, pump/valve bracket, grinder gearbox repair and drip-tray structure"},
  {"season":"全年高客单","category":"咖啡机","brand":"Breville","model":"Barista Express / Barista Pro / Dual Boiler","reason":"美国站高客单咖啡机主流品牌，先验证整机BSR、评论和配件成交，再决定型号","direction":"Model-specific brew-head rail, pump/valve bracket, grinder gearbox repair and drip-tray structure"},
  {"season":"全年高客单","category":"工具和维修","brand":"Milwaukee / DeWalt / Makita / Festool","model":"Milwaukee M18 FUEL / DeWalt FLEXVOLT / Makita XGT / Festool CT Series","reason":"专业用户购买力强，秋冬室内装修和维修周期稳定","direction":"Guide clamp, dust-extraction adapter, tool box, wall mount and workbench structure"},
  {"season":"全年高客单","category":"网络和安防","brand":"Ubiquiti / Hikvision / Dahua / Reolink","model":"Ubiquiti UniFi Dream Machine Pro / Hikvision ColorVu / Dahua WizSense / Reolink RLC-823A","reason":"企业网络和安防安装不受季节限制，国内机架、壁装和接线件供应成熟","direction":"Rack tray, wall mount, junction box, heat dissipation, sunshade and cable management"}
]
'@ | ConvertFrom-Json)

# source: 品牌属性；supply: 中国替换件/加工供应链可得性；priority: P1 优先，P2 次之，P3 仅作补充
$brandLines = @'
3DMakerpro|三维麦普|3DMakerpro|中国品牌/出口|高|P1
3M|3M|3M|海外品牌/中国供应链|高|P2
九号|九号|Segway-Ninebot|中国品牌/出口|高|P1
雀霸|雀霸|Queba|中国品牌/出口|高|P1
雀康|雀康|Quekang|中国品牌/出口|高|P1
雀王|雀王|Quewang|中国品牌/出口|高|P1
雀友|雀友|Queyou|中国品牌/出口|高|P1
松冈|松冈|Songgang|中国品牌/出口|高|P1
小米|小米/米家|Xiaomi/Mijia|中国品牌/出口|高|P1
小牛|小牛|NIU|中国品牌/出口|高|P1
宣和|宣和|Xuanhe|中国品牌/出口|高|P1
AC Infinity|艾科英菲尼迪|AC Infinity|海外品牌/中国制造供应链|高|P1
Acaia|阿凯亚|Acaia|海外品牌/中国供应链|高|P2
ADO|阿道|ADO|中国品牌/出口|高|P1
Advanced Elements|先进元素|Advanced Elements|海外品牌/中国制造供应链|高|P1
Ankarsrum|安卡苏姆|Ankarsrum|海外品牌/中国兼容供应链|中|P2
Anova|安诺瓦|Anova|海外品牌/中国制造供应链|高|P1
AOKZOE|奥克佐|AOKZOE|中国品牌/出口|高|P1
AOOSTAR|奥硕达|AOOSTAR|中国品牌/出口|高|P1
Aqara|绿米 Aqara|Aqara|中国品牌/出口|高|P1
Aqua Marina|Aqua Marina|Aqua Marina|中国品牌/出口|高|P1
Arctic Cat|北极猫|Arctic Cat|海外品牌/中国兼容供应链|中|P2
Askar|阿斯卡|Askar|中国品牌/出口|高|P1
Atomstack|原子堆|Atomstack|中国品牌/出口|高|P1
AYANEO|艾尼优|AYANEO|中国品牌/出口|高|P1
Beelink|零刻|Beelink|中国品牌/出口|高|P1
Begode|比格德|Begode|中国品牌/出口|高|P1
Bestway|百适乐|Bestway|中国品牌/出口|高|P1
Bissell|必胜|Bissell|海外品牌/中国制造供应链|高|P1
Blackdeer|黑鹿|Blackdeer|中国品牌/出口|高|P1
Blendtec|Blendtec|Blendtec|海外品牌/中国制造供应链|高|P2
Blueair|布鲁雅尔|Blueair|海外品牌/中国制造供应链|高|P1
Bosch Professional|博世专业|Bosch Professional|海外品牌/中国制造供应链|高|P1
Breville|铂富|Breville|海外品牌/中国制造供应链|高|P1
KEYi Tech|可伊科技|KEYi Tech|中国品牌/出口|高|P1
Brother|兄弟|Brother|海外品牌/中国制造供应链|高|P1
Brunswick|布伦瑞克|Brunswick|海外品牌/中国制造供应链|中|P2
Bullfrog Spa|牛蛙水疗|Bullfrog Spa|海外品牌/中国兼容供应链|中|P2
California Air Tools|加州空气工具|California Air Tools|海外品牌/中国制造供应链|高|P1
Carvera|Carvera|Carvera|中国品牌/出口|高|P1
CATLINK|猫链|CATLINK|中国品牌/出口|高|P1
Cayin|凯音|Cayin|中国品牌/出口|高|P1
Colorful iGame|七彩虹 iGame|Colorful iGame|中国品牌/出口|高|P1
Cosori|科西|Cosori|中国品牌/出口|高|P1
Coway|科唯怡|Coway|海外品牌/中国制造供应链|高|P1
Creality Falcon|创想三维 Falcon|Creality Falcon|中国品牌/出口|高|P1
Creality|创想三维|Creality|中国品牌/出口|高|P1
Dahua|大华|Dahua|中国品牌/出口|高|P1
Dangbei|当贝|Dangbei|中国品牌/出口|高|P1
Deerma|德尔玛|Deerma|中国品牌/出口|高|P1
Donlim|东菱|Donlim|中国品牌/出口|高|P1
DeLonghi|德龙|DeLonghi|海外品牌/中国制造供应链|高|P1
Spaceman|斯贝曼|Spaceman|中国品牌/出口|高|P1
Donper|东贝|Donper|中国品牌/出口|高|P1
Oceanpower|海川|Oceanpower|中国品牌/出口|高|P1
Taylor|泰勒|Taylor|海外品牌/中国制造供应链|高|P1
Carpigiani|卡比詹尼|Carpigiani|海外品牌/中国制造供应链|高|P1
Electro Freeze|Electro Freeze|Electro Freeze|海外品牌/中国制造供应链|高|P1
TechnoAlpin|泰克诺阿尔卑|TechnoAlpin|海外品牌/中国兼容供应链|中|P2
SMI Snow Makers|SMI 造雪机|SMI Snow Makers|海外品牌/中国制造供应链|高|P1
HKD Snowmakers|HKD 造雪机|HKD Snowmakers|海外品牌/中国制造供应链|高|P1
Demaclenko|德马克连科|Demaclenko|海外品牌/中国兼容供应链|中|P2
Antari|安特利|Antari|中国品牌/出口|高|P1
Chauvet DJ|Chauvet DJ|Chauvet DJ|海外品牌/中国制造供应链|高|P1
ADJ|美国DJ灯光|ADJ|海外品牌/中国制造供应链|高|P1
Scotsman|斯科茨曼|Scotsman|海外品牌/中国制造供应链|高|P1
Manitowoc Ice|万利多|Manitowoc Ice|海外品牌/中国制造供应链|高|P1
Hoshizaki|星崎|Hoshizaki|海外品牌/中国制造供应链|高|P1
Prinoth|普林诺特|Prinoth|海外品牌/中国兼容供应链|中|P2
PistenBully|皮斯滕布利|PistenBully|海外品牌/中国兼容供应链|中|P2
Tucker Sno-Cat|塔克雪地车|Tucker Sno-Cat|海外品牌/中国兼容供应链|中|P2
Zamboni|赞博尼|Zamboni|海外品牌/中国制造供应链|高|P1
Resurfice Olympia|奥林匹亚冰场车|Resurfice Olympia|海外品牌/中国制造供应链|高|P1
Wintersteiger|温特斯泰格|Wintersteiger|海外品牌/中国制造供应链|高|P1
Montana Sport|蒙大拿滑雪设备|Montana Sport|海外品牌/中国制造供应链|高|P1
Reichmann|莱希曼|Reichmann|海外品牌/中国制造供应链|高|P1
Bobcat|山猫|Bobcat|海外品牌/中国制造供应链|高|P1
John Deere|约翰迪尔|John Deere|海外品牌/中国制造供应链|高|P1
Honda|本田|Honda|海外品牌/中国制造供应链|高|P1
BOSS Snowplow|BOSS 扫雪|BOSS Snowplow|海外品牌/中国制造供应链|高|P1
Fisher|费舍尔扫雪|Fisher|海外品牌/中国制造供应链|高|P1
Western|西部扫雪|Western|海外品牌/中国制造供应链|高|P1
SnowEx|SnowEx|SnowEx|海外品牌/中国制造供应链|高|P1
Henderson|亨德森|Henderson|海外品牌/中国制造供应链|高|P1
Trecan|Trecan 融雪机|Trecan|海外品牌/中国制造供应链|高|P1
Snow Dragon|Snow Dragon 融雪机|Snow Dragon|海外品牌/中国制造供应链|高|P1
Doppelmayr|多贝玛亚|Doppelmayr|海外品牌/中国制造供应链|高|P1
Leitner|莱特纳|Leitner|海外品牌/中国制造供应链|高|P1
Poma|波马|Poma|海外品牌/中国制造供应链|高|P1
CIMCO|CIMCO 冰场制冷|CIMCO|海外品牌/中国制造供应链|高|P1
Industrial Frigo|工业弗里戈|Industrial Frigo|海外品牌/中国制造供应链|高|P1
Toro|托罗|Toro|海外品牌/中国制造供应链|高|P1
Ariens|艾瑞恩斯|Ariens|海外品牌/中国制造供应链|高|P1
DeWalt|得伟|DeWalt|海外品牌/中国制造供应链|高|P1
Dobot|越疆|Dobot|中国品牌/出口|高|P1
Dreame|追觅|Dreame|中国品牌/出口|高|P1
Dyson|戴森|Dyson|海外品牌/中国兼容供应链|高|P1
EGO|EGO|EGO|海外品牌/中国制造供应链|高|P1
EGO Power+|EGO Power+|EGO Power+|海外品牌/中国制造供应链|高|P1
Elephant Robotics|大象机器人|Elephant Robotics|中国品牌/出口|高|P1
ENGWE|英格威|ENGWE|中国品牌/出口|高|P1
Eversolo|艾索洛|Eversolo|中国品牌/出口|高|P1
FeiyuTech|飞宇|FeiyuTech|中国品牌/出口|高|P1
Fellowes|范罗士|Fellowes|海外品牌/中国制造供应链|高|P1
Festool|费斯托|Festool|海外品牌/中国制造供应链|高|P1
Fiido|飞道|Fiido|中国品牌/出口|高|P1
FiiO|飞傲|FiiO|中国品牌/出口|高|P1
Fire-Maple|火枫|Fire-Maple|中国品牌/出口|高|P1
FlexiSpot|乐歌 FlexiSpot|FlexiSpot|中国品牌/出口|高|P1
FLIR|菲力尔|FLIR|海外品牌/中国制造供应链|中|P2
FMS|FMS|FMS|中国品牌/出口|高|P1
Formovie|峰米|Formovie|中国品牌/出口|高|P1
FoxAlien|FoxAlien|FoxAlien|中国品牌/出口|高|P1
Frigidaire|富及第|Frigidaire|海外品牌/中国制造供应链|高|P1
Fujitsu/Ricoh|富士通/理光|Fujitsu/Ricoh|海外品牌/中国制造供应链|高|P1
GE Profile|通用电气 Profile|GE Profile|海外品牌/中国制造供应链|高|P1
Genmitsu|Genmitsu|Genmitsu|中国品牌/出口|高|P1
GPD|GPD 掌机|GPD|中国品牌/出口|高|P1
Great Northern|大北方|Great Northern|海外品牌/中国制造供应链|高|P1
Greenworks|格力博|Greenworks|中国品牌/出口|高|P1
Hayward|海沃德|Hayward|海外品牌/中国制造供应链|高|P1
Heng Long|恒龙|Heng Long|中国品牌/出口|高|P1
Herman Miller|赫曼米勒|Herman Miller|海外品牌/中国兼容供应链|中|P2
HIKMICRO|海康微影|HIKMICRO|中国品牌/出口|高|P1
Hikvision|海康威视|Hikvision|中国品牌/出口|高|P1
Hilti|喜利得|Hilti|海外品牌/中国制造供应链|高|P1
Hobie|霍比|Hobie|海外品牌/中国制造供应链|高|P1
hOmeLabs|hOmeLabs|hOmeLabs|海外品牌/中国制造供应链|高|P1
Hotone|火星|Hotone|中国品牌/出口|高|P1
HSM|HSM|HSM|海外品牌/中国制造供应链|高|P1
Husqvarna|胡斯华纳|Husqvarna|海外品牌/中国制造供应链|高|P1
Hypertherm|海宝|Hypertherm|海外品牌/中国制造供应链|高|P1
InMotion|乐行天下|InMotion|中国品牌/出口|高|P1
INNOCN|联合创新|INNOCN|中国品牌/出口|高|P1
Insta360|影石|Insta360|中国品牌/出口|高|P1
Intex|英特|Intex|海外品牌/中国制造供应链|高|P1
iRocker|iRocker|iRocker|海外品牌/中国制造供应链|高|P1
Jack|杰克|Jack|中国品牌/出口|高|P1
Jacuzzi|雅客奇|Jacuzzi|海外品牌/中国制造供应链|高|P1
Jandy|Jandy|Jandy|海外品牌/中国制造供应链|高|P1
JMGO|坚果|JMGO|中国品牌/出口|高|P1
Junxing|军星|Junxing|中国品牌/出口|高|P1
Kaadas|凯迪仕|Kaadas|中国品牌/出口|高|P1
Kärcher|卡赫|Kärcher|海外品牌/中国制造供应链|高|P1
KastKing|卡斯丁|KastKing|中国品牌/出口|高|P1
Kenwood|凯伍德|Kenwood|海外品牌/中国制造供应链|高|P1
Kinefinity|开尼|Kinefinity|中国品牌/出口|高|P1
King Song|国王歌|King Song|中国品牌/出口|高|P1
KitchenAid|凯膳怡|KitchenAid|海外品牌/中国制造供应链|高|P1
Kress|科瑞斯|Kress|中国品牌/出口|高|P1
KTC|科睿|KTC|中国品牌/出口|高|P1
LaserPecker|激光宝|LaserPecker|中国品牌/出口|高|P1
Leica Geosystems|徕卡测量|Leica Geosystems|海外品牌/中国制造供应链|中|P2
Levoit|莱沃特|Levoit|海外品牌/中国制造供应链|高|P1
LG|乐金|LG|海外品牌/中国制造供应链|高|P1
Longer|龙达|Longer|中国品牌/出口|高|P1
Makeblock|童心制物|Makeblock|中国品牌/出口|高|P1
Makita|牧田|Makita|海外品牌/中国制造供应链|高|P1
Marquis|玛奎斯|Marquis|海外品牌/中国兼容供应链|中|P2
Mars Hydro|火星农场|Mars Hydro|中国品牌/出口|高|P1
Merach|麦瑞克|Merach|中国品牌/出口|高|P1
Midea|美的|Midea|中国品牌/出口|高|P1
Loona|可伊 Loona|Loona|中国品牌/出口|高|P1
KEYi Tech|可伊科技|KEYi Tech|中国品牌/出口|高|P1
Miele|美诺|Miele|海外品牌/中国制造供应链|高|P1
MikroTik|米克罗蒂克|MikroTik|海外品牌/中国制造供应链|高|P1
Milwaukee|米沃奇|Milwaukee|海外品牌/中国制造供应链|高|P1
Minisforum|铭凡|Minisforum|中国品牌/出口|高|P1
MOOER|魔耳|MOOER|中国品牌/出口|高|P1
MSPA|MSPA|MSPA|中国品牌/出口|高|P1
Naturehike|挪客|Naturehike|中国品牌/出口|高|P1
NewAir|NewAir|NewAir|海外品牌/中国制造供应链|高|P1
Nilfisk|力奇|Nilfisk|海外品牌/中国制造供应链|高|P1
Ninja|忍者|Ninja|海外品牌/中国制造供应链|高|P1
NIU|小牛|NIU|中国品牌/出口|高|P1
NUX|纽克斯|NUX|中国品牌/出口|高|P1
Old Town|奥尔德汤|Old Town|海外品牌/中国制造供应链|高|P1
OneXPlayer|壹号掌机|OneXPlayer|中国品牌/出口|高|P1
Panasonic|松下|Panasonic|海外品牌/中国制造供应链|高|P1
Pelican|派力肯|Pelican|海外品牌/中国制造供应链|高|P1
Pentair|滨特尔|Pentair|海外品牌/中国制造供应链|高|P1
PETKIT|小佩|PETKIT|中国品牌/出口|高|P1
Philips DDL|飞利浦 DDL|Philips DDL|海外品牌/中国制造供应链|高|P1
PICO|小鸟看看 PICO|PICO|中国品牌/出口|高|P1
Pimax|小派|Pimax|中国品牌/出口|高|P1
Piscifun|品钓|Piscifun|中国品牌/出口|高|P1
Player One Astronomy|普朗天文|Player One Astronomy|中国品牌/出口|高|P1
Polaris|北极星|Polaris|海外品牌/中国制造供应链|高|P1
QHYCCD|QHYCCD|QHYCCD|中国品牌/出口|高|P1
QNAP|威联通|QNAP|海外品牌/中国制造供应链|高|P1
Rasson|瑞森|Rasson|中国品牌/出口|高|P1
Red Paddle Co|红桨|Red Paddle Co|海外品牌/中国制造供应链|高|P1
Reolink|睿联|Reolink|中国品牌/出口|高|P1
Revopoint|Revopoint|Revopoint|中国品牌/出口|高|P1
ROG Ally|ROG 玩家国度 Ally|ROG Ally|海外品牌/中国制造供应链|高|P1
Rokid|若琪|Rokid|中国品牌/出口|高|P1
Rovan|Rovan|Rovan|中国品牌/出口|高|P1
Ryobi|利优比|Ryobi|海外品牌/中国制造供应链|高|P1
Sanlida|三利达|Sanlida|中国品牌/出口|高|P1
SawStop|SawStop|SawStop|海外品牌/中国制造供应链|高|P1
Sculpfun|雕刻师|Sculpfun|中国品牌/出口|高|P1
Segway-Ninebot|九号|Segway-Ninebot|中国品牌/出口|高|P1
Shanling|山灵|Shanling|中国品牌/出口|高|P1
Shark|鲨客|Shark|海外品牌/中国制造供应链|高|P1
Shining 3D|先临三维|Shining 3D|中国品牌/出口|高|P1
Ski-Doo|Ski-Doo 庞巴迪|Ski-Doo|海外品牌/中国兼容供应链|中|P2
Speediance|速境|Speediance|中国品牌/出口|高|P1
Spider Farmer|蜘蛛农场|Spider Farmer|中国品牌/出口|高|P1
Steam Deck|Steam 掌机|Steam Deck|海外品牌/中国制造供应链|高|P1
Steelcase|世楷|Steelcase|海外品牌/中国制造供应链|中|P2
Sun Joe|Sun Joe|Sun Joe|海外品牌/中国制造供应链|高|P1
Sundance|桑丹斯|Sundance|海外品牌/中国兼容供应链|中|P2
Synology|群晖|Synology|海外品牌/中国制造供应链|高|P1
TerraMaster|铁威马|TerraMaster|中国品牌/出口|高|P1
Teslong|泰斯朗|Teslong|中国品牌/出口|高|P1
Tineco|添可|Tineco|中国品牌/出口|高|P1
Topping|拓品|Topping|中国品牌/出口|高|P1
TP-Link Omada|普联 Omada|TP-Link Omada|中国品牌/出口|高|P1
Two Trees|二树|Two Trees|中国品牌/出口|高|P1
Typical|标准|Typical|中国品牌/出口|高|P1
Ubiquiti|优倍快|Ubiquiti|海外品牌/中国制造供应链|高|P1
UGREEN|绿联|UGREEN|中国品牌/出口|高|P1
Unitree|宇树|Unitree|中国品牌/出口|高|P1
Urtopia|Urtopia|Urtopia|中国品牌/出口|高|P1
Valley|Valley|Valley|海外品牌/中国制造供应链|中|P2
Venta|文塔|Venta|海外品牌/中国兼容供应链|中|P2
Veteran|Veteran|Veteran|中国品牌/出口|高|P1
Vitamix|维他美仕|Vitamix|海外品牌/中国制造供应链|高|P1
WalkingPad|WalkingPad|WalkingPad|中国品牌/出口|高|P1
Whynter|Whynter|Whynter|海外品牌/中国制造供应链|高|P1
XGIMI|极米|XGIMI|中国品牌/出口|高|P1
Xingpai|星牌|Xingpai|中国品牌/出口|高|P1
XREAL|XREAL|XREAL|中国品牌/出口|高|P1
xTool|酷工具|xTool|中国品牌/出口|高|P1
Yesoul|野小兽|Yesoul|中国品牌/出口|高|P1
YESWELDER|YESWELDER|YESWELDER|中国品牌/出口|高|P1
Z CAM|Z CAM|Z CAM|中国品牌/出口|高|P1
Zebra|斑马|Zebra|海外品牌/中国制造供应链|高|P1
SATO|佐藤|SATO|海外品牌/中国制造供应链|高|P1
TSC|台半|TSC|中国品牌/出口|高|P1
GoDEX|科诚|GoDEX|中国品牌/出口|高|P1
Bixolon|百讯|Bixolon|海外品牌/中国制造供应链|高|P1
Honeywell|霍尼韦尔|Honeywell|海外品牌/中国制造供应链|高|P1
Citizen Systems|西铁城打印|Citizen Systems|海外品牌/中国制造供应链|高|P1
Zhiyun|智云|Zhiyun|中国品牌/出口|高|P1
ZimaBoard|ZimaBoard|ZimaBoard|中国品牌/出口|高|P1
Zoje|中捷|Zoje|中国品牌/出口|高|P1
Zojirushi|象印|Zojirushi|海外品牌/中国制造供应链|高|P1
ZWO|振旺|ZWO|中国品牌/出口|高|P1
Angel|安吉尔|Angel|中国品牌/出口|高|P1
AUX|奥克斯|AUX|中国品牌/出口|高|P1
Anker Innovations|安克创新|Anker Innovations|中国品牌/出口|高|P1
Nebula|安克星云（安克创新）|Nebula|中国品牌/出口|高|P1
Epson|爱普生|Epson|海外品牌/中国制造供应链|高|P1
BenQ|明基|BenQ|海外品牌/中国制造供应链|高|P1
ViewSonic|优派|ViewSonic|海外品牌/中国制造供应链|高|P1
Optoma|奥图码|Optoma|海外品牌/中国制造供应链|高|P1
Bambu Lab|拓竹|Bambu Lab|中国品牌/出口|高|P1
Elegoo|爱乐酷|Elegoo|中国品牌/出口|高|P1
Anycubic|纵维立方|Anycubic|中国品牌/出口|高|P1
Prusa Research|普鲁沙|Prusa Research|海外品牌/中国制造供应链|中|P2
DJI|大疆|DJI|中国品牌/出口|高|P1
Antigravity|Antigravity（影石创新）|Antigravity|中国品牌/出口|高|P2
Traxxas|特拉卡斯|Traxxas|海外品牌/中国制造供应链|高|P1
ARRMA|阿玛|ARRMA|海外品牌/中国制造供应链|高|P1
Axial|阿西尔|Axial|海外品牌/中国制造供应链|高|P1
Losi|洛西|Losi|海外品牌/中国制造供应链|高|P1
Redcat Racing|红猫|Redcat Racing|海外品牌/中国制造供应链|高|P2
MJX|迈捷西|MJX|中国品牌/出口|高|P1
GoPro|GoPro|GoPro|海外品牌/中国制造供应链|高|P1
Autel Robotics|道通智能|Autel Robotics|中国品牌/出口|高|P1
Generac|吉耐|Generac|海外品牌/中国制造供应链|高|P1
Champion Power Equipment|冠军|Champion Power Equipment|海外品牌/中国制造供应链|高|P1
Westinghouse|西屋|Westinghouse|海外品牌/中国制造供应链|高|P1
DuroMax|杜罗麦克斯|DuroMax|海外品牌/中国制造供应链|高|P1
Chamberlain|张伯伦|Chamberlain|海外品牌/中国制造供应链|高|P1
LiftMaster|LiftMaster|LiftMaster|海外品牌/中国制造供应链|高|P1
Genie|吉尼|Genie|海外品牌/中国制造供应链|高|P1
Peloton|必烈|Peloton|海外品牌/中国制造供应链|高|P1
NordicTrack|诺迪克|NordicTrack|海外品牌/中国制造供应链|高|P1
Bowflex|宝力豪|Bowflex|海外品牌/中国制造供应链|高|P1
Maytronics|美卓特|Maytronics|海外品牌/中国制造供应链|中|P2
Rad Power Bikes|Rad Power Bikes|Rad Power Bikes|海外品牌/中国制造供应链|中|P2
Lectric|莱特里克|Lectric|海外品牌/中国制造供应链|中|P2
Aventon|Aventon|Aventon|海外品牌/中国制造供应链|中|P2
Schlage|史莱奇|Schlage|海外品牌/中国制造供应链|高|P1
Yale|耶鲁|Yale|海外品牌/中国制造供应链|高|P1
August|August|August|海外品牌/中国制造供应链|高|P1
Rollo|Rollo|Rollo|海外品牌/中国制造供应链|高|P1
MUNBYN|MUNBYN|MUNBYN|海外品牌/中国制造供应链|高|P1
Phomemo|印萌|Phomemo|中国品牌/出口|高|P1
Gaggia|加吉亚|Gaggia|海外品牌/中国制造供应链|高|P1
Jura|优瑞|Jura|海外品牌/中国制造供应链|高|P1
Asustor|华芸|Asustor|海外品牌/中国制造供应链|高|P1
ASUS|华硕|ASUS|海外品牌/中国制造供应链|高|P1
NETGEAR|网件|NETGEAR|海外品牌/中国制造供应链|高|P1
eero|亚马逊 eero|eero|海外品牌/中国制造供应链|高|P1
Winix|维尼克斯|Winix|海外品牌/中国制造供应链|高|P1
Medify Air|Medify Air|Medify Air|海外品牌/中国制造供应链|高|P1
Mitsubishi Electric|三菱电机|Mitsubishi Electric|海外品牌/中国制造供应链|高|P1
MRCOOL|MRCOOL|MRCOOL|海外品牌/中国制造供应链|高|P1
Pioneer|先锋空调|Pioneer|海外品牌/中国制造供应链|高|P1
Senville|森威尔|Senville|海外品牌/中国制造供应链|高|P1
Harman|哈曼壁炉|Harman|海外品牌/中国制造供应链|中|P2
Englander|英格兰德|Englander|海外品牌/中国制造供应链|高|P1
ComfortBilt|康福特比尔特|ComfortBilt|海外品牌/中国制造供应链|高|P1
Cub Cadet|小型骑士|Cub Cadet|海外品牌/中国制造供应链|高|P1
Troy-Bilt|特洛伊比尔特|Troy-Bilt|海外品牌/中国制造供应链|高|P1
Simpson|辛普森清洗设备|Simpson|海外品牌/中国制造供应链|高|P1
Miller Electric|米勒电气|Miller Electric|海外品牌/中国制造供应链|高|P1
Lincoln Electric|林肯电气|Lincoln Electric|海外品牌/中国制造供应链|高|P1
ESAB|伊萨|ESAB|海外品牌/中国制造供应链|高|P1
Bear|小熊|Bear|中国品牌/出口|高|P1
Deerma|德尔玛|Deerma|中国品牌/出口|高|P1
EZVIZ|萤石|EZVIZ|中国品牌/出口|高|P1
Gree|格力|Gree|中国品牌/出口|高|P1
Haier|海尔|Haier|中国品牌/出口|高|P1
Hisense|海信|Hisense|中国品牌/出口|高|P1
IMOU|乐橙|IMOU|中国品牌/出口|高|P1
Joyoung|九阳|Joyoung|中国品牌/出口|高|P1
Philips|飞利浦|Philips|海外品牌/中国制造供应链|高|P1
Roborock|石头科技|Roborock|中国品牌/出口|高|P1
Ruijie/Reyee|锐捷/睿易|Ruijie/Reyee|中国品牌/出口|高|P1
Smartmi|智米|Smartmi|中国品牌/出口|高|P1
TCL|TCL|TCL|中国品牌/出口|高|P1
Tenda|腾达|Tenda|中国品牌/出口|高|P1
TP-Link Tapo|普联 Tapo|TP-Link Tapo|中国品牌/出口|高|P1
Uniview|宇视|Uniview|中国品牌/出口|高|P1
WORX|威克士|WORX|中国品牌/出口|高|P1
Cheyenne|夏延|Cheyenne|海外品牌/中国兼容供应链|中|P2
FK Irons|FK艾恩斯|FK Irons|海外品牌/中国兼容供应链|中|P2
Bishop|Bishop|Bishop|海外品牌/中国兼容供应链|中|P2
Dragonhawk|龙鹰|Dragonhawk|中国品牌/出口|高|P1
Pride Mobility|普莱德移动|Pride Mobility|海外品牌/中国兼容供应链|中|P2
Drive Medical|德迈医疗|Drive Medical|海外品牌/中国兼容供应链|高|P1
Golden Technologies|金色科技|Golden Technologies|海外品牌/中国兼容供应链|中|P2
Shoprider|舒普莱德|Shoprider|海外品牌/中国兼容供应链|中|P2
EV Rider|EV Rider|EV Rider|海外品牌/中国兼容供应链|中|P2
Mitsubishi Electric|三菱电机|Mitsubishi Electric|海外品牌/中国制造供应链|中|P2
Daikin|大金|Daikin|海外品牌/中国制造供应链|中|P2
Scotsman|斯科茨曼|Scotsman|海外品牌/中国兼容供应链|中|P2
Manitowoc Ice|万利多|Manitowoc Ice|海外品牌/中国兼容供应链|中|P2
xTool|智造星|xTool|中国品牌/出口|高|P1
Glowforge|Glowforge|Glowforge|海外品牌/中国兼容供应链|中|P2
Juki|重机|Juki|海外品牌/中国兼容供应链|高|P1
Weber|韦伯|Weber|海外品牌/中国制造供应链|高|P1
Monument Grills|Monument 格栅|Monument Grills|中国出口品牌|高|P1
Royal Gourmet|皇家格美|Royal Gourmet|中国品牌/出口|高|P1
Blackstone|黑石|Blackstone|海外品牌/中国制造供应链|高|P1
Pit Boss|Pit Boss|Pit Boss|海外品牌/中国制造供应链|高|P1
Brisk It|Brisk It|Brisk It|中国出口品牌|高|P1
YARDMAX|亚达马克斯|YARDMAX|海外品牌/中国制造供应链|高|P1
EGO Power+|EGO Power+|EGO Power+|海外品牌/中国制造供应链|高|P1
PowerSmart|宝时得 PowerSmart|PowerSmart|中国出口品牌|高|P1
BILT HARD|BILT HARD|BILT HARD|中国出口/OEM品牌|高|P1
SuperHandy|SuperHandy|SuperHandy|海外品牌/中国制造供应链|高|P1
DeWalt|得伟|DeWalt|海外品牌/中国制造供应链|高|P1
Metabo HPT|麦太保 HPT|Metabo HPT|海外品牌/中国制造供应链|高|P1
VEVOR|威沃|VEVOR|中国品牌/出口|高|P1
Klutch|克拉奇|Klutch|海外品牌/中国制造供应链|高|P1
US Stove|美国炉具|US Stove|海外品牌/中国制造供应链|高|P1
Cleveland Iron Works|克利夫兰铸铁厂|Cleveland Iron Works|海外品牌/中国制造供应链|高|P1
Comfort Glow|舒适之光|Comfort Glow|海外品牌/中国制造供应链|高|P1
HHQ|HHQ|HHQ|中国出口/OEM品牌|高|P1
Bissell Commercial|必胜商用|Bissell Commercial|海外品牌/中国制造供应链|高|P1
Mytee|迈泰|Mytee|海外品牌/中国制造供应链|高|P1
Kärcher|卡赫|Kärcher|海外品牌/中国制造供应链|高|P1
EUHOMY|优巧|EUHOMY|中国品牌/出口|高|P1
FOHERE|福合|FOHERE|中国品牌/出口|高|P1
Mojgar|Mojgar|Mojgar|中国出口/OEM品牌|高|P1
KingSmith|金史密斯|KingSmith|中国品牌/出口|高|P1
UREVO|优瑞沃|UREVO|中国品牌/出口|高|P2
YOSUDA|优速达|YOSUDA|中国品牌/出口|高|P3
Pooboo|普布|Pooboo|中国品牌/出口|高|P3
ANCHEER|安骑尔|ANCHEER|中国品牌/出口|高|P3
WENOKER|温诺克|WENOKER|中国品牌/出口|高|P3
MAJOR FITNESS|迈卓健身|MAJOR FITNESS|中国品牌/出口|高|P2
EcoFlow|正浩|EcoFlow|中国品牌/出口|高|P3
BLUETTI|德兰明海|BLUETTI|中国品牌/出口|高|P3
Mammotion|库犸|Mammotion|中国品牌/出口|高|P3
Heybike|星途创新|Heybike|中国品牌/出口|高|P3
PETLIBRO|PETLIBRO|PETLIBRO|中国品牌/出口|高|P3
AMIRO|觅光|AMIRO|中国品牌/出口|高|P3
70mai|70迈|70mai|中国品牌/出口|高|P3
Eufy|安克Eufy|Eufy|中国品牌/出口|高|P3
KIMO|KIMO|KIMO|中国品牌/出口|高|P3
HiBREW|HiBREW|HiBREW|中国品牌/出口|高|P3
'@

$brandMap = @{}
foreach ($line in ($brandLines -split "`r?`n")) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split '\|', 6
    if ($parts.Count -ge 6) {
        $brandMap[$parts[0]] = [ordered]@{ cn = $parts[1]; en = $parts[2]; source = $parts[3]; supply = $parts[4]; priority = $parts[5] }
    }
}

function Get-BrandInfo([string]$brand) {
    if ($brandMap.ContainsKey($brand)) { return $brandMap[$brand] }
    return [ordered]@{ cn = "$brand（中文名待核）"; en = $brand; source = '海外品牌/需核实中国供应链'; supply = '待核'; priority = 'P3' }
}

function New-Row([object]$r) {
    $b = Get-BrandInfo ([string]$r.'品牌')
    $category = [string]$r.'品类'
    $teardown = switch -Regex ($category) {
        '投影仪' { '主板/逻辑板、DMD/光机组件、激光/灯驱动板、液晶面板、风扇、镜头位移电机、遥控接收板、电源板（仅拆机件）'; break }
        '咖啡机' { '主控板、显示/按键板、泵、流量计、电磁阀、磨豆机电机/齿轮箱、加热块、温度传感器、滴水盘总成'; break }
        '纹身机' { '主控/驱动板、无刷电机、偏心轮/连杆、调压模块、握柄锁止总成、无线通信板（电池不做）'; break }
        '老年代步车|电动轮椅' { '主控器、无刷电机/电机总成、转向/驱动桥、操纵杆控制器、显示板、座椅升降/滑轨、刹车电磁组件、车架折叠锁止'; break }
        '商用制冰机' { '主控板、制冷控制板、压缩机启动模块、风机电机、冰厚探针、进水阀、排水泵、料斗门总成'; break }
        '燃气烤炉|烧烤炉|颗粒烤炉|铁板烧炉|户外煎烤炉' { '点火模块/点火板、燃烧器总成、燃气阀组、温度控制器、螺旋送料电机、风机、RTD温度探针、料斗总成、接油盘总成、主控板/显示板'; break }
        '除雪机|扫雪机' { '发动机点火模块、启动电机、传动箱、蜗轮/螺旋输送总成、导流槽齿轮机构、控制手柄总成、车架'; break }
        '劈木机|木材劈裂机' { '液压泵、液压阀块、液压油缸、发动机控制模块、启动电机、楔块总成、横梁/车架总成'; break }
        '高压清洗机' { '电机/泵总成、卸荷阀、压力开关、主控板、软管卷盘、扳机喷枪总成、热保护传感器'; break }
        '空压机' { '压缩机电机、泵头总成、压力开关、主控板、启动电容、止回阀、调压阀组、压力传感器、冷却风扇'; break }
        '洗地机|地毯抽洗机|商用地毯清洗机' { '真空电机、刷盘电机、水泵、加热器、控制板、浮球传感器、污水箱总成、吸水扒总成、软管接口'; break }
        '颗粒炉/壁炉|木柴炉|冬季采暖炉' { '主控板、鼓风机电机、点火器、温控器、螺旋送料/送料电机、排烟风机、门组件、隔热板'; break }
        '造雪机|雪道压雪机|冰场刮冰车' { '液压泵/阀块、驱动电机、控制器、喷雪/刮冰执行机构、传感器、工作灯控制板、车架总成'; break }
        '空气净化器|加湿器|除湿机|便携空调|分体空调|热泵' { '主控板、显示板、风机电机、风轮、传感器板、压缩机驱动/启动模块、排水泵、风道总成'; break }
        '3D打印机' { '主板、运动控制板、步进电机、挤出机总成、热床控制板、屏幕、导轨/丝杆、自动调平传感器'; break }
        '无人机|运动相机' { '飞控板、云台控制板、相机模组、图传板、无刷电机、电调、GPS/视觉定位板、遥控器主板（电池不做）'; break }
        '发电机|焊机' { '主控板/逆变板、点火模块、调压器、显示控制板、发动机控制模块、启动电机、散热风扇和机架总成'; break }
        '车库门开启器' { '主控板、接收板、驱动电机、齿轮箱、链条/皮带传动总成、光电传感器、墙控板、轨道连接件'; break }
        '家庭健身' { '主控板、显示屏、阻力/驱动电机、滚筒、皮带张紧总成、踏板/曲柄、传感器和屏幕臂总成'; break }
        '智能门锁' { '主控板、无线通信板、指纹/键盘模块、锁体电机、齿轮箱、离合器、锁舌总成和内侧旋钮组件（电池不做）'; break }
        '网络设备' { '主板、交换芯片散热组件、风扇模块、背板、端口板、天线板、机架固定件和状态显示板（电源适配器不做）'; break }
        '标签打印机' { '主板、打印控制板、走纸电机、齿轮箱、压纸滚轮总成、传感器板、切刀/剥离器总成和显示板'; break }
        '泳池设备' { '主控板、驱动电机、泵体总成、齿轮箱、浮力/导航传感器、履带驱动轮和密封壳体（滤网耗材不做）'; break }
        '电动自行车' { '主控器、轮毂/中置电机、显示仪表、扭矩传感器、变速/刹车执行机构、线束总成和折叠锁止（电池和充电器不做）'; break }
        'NAS' { '主板、硬盘背板、SATA/SAS连接板、风扇控制板、风扇总成、硬盘托架、显示/按键板和PCIe转接板（硬盘和电源不做）'; break }
        '家庭机器人' { '主控板、运动控制板、云台/摄像头模组、轮组电机、齿轮箱、传感器板、扬声器和充电触点板（电池不做）'; break }
        '工业缝纫机' { '主控板、伺服电机、脚踏控制器、针杆/送料机构、旋梭组件、机头齿轮、显示/按键板和台板脚架'; break }
        '激光雕刻机' { '主板、激光电源/驱动板、步进电机、运动控制板、限位传感器、排烟风机和门锁联锁板'; break }
        default { '' }
    }
    $parts = @()
    if ($teardown) { $parts += $teardown }
    $upgrade = [string]$r.'适合开发的高客单非耗材替换升级改装件'
    if ($upgrade) { $parts += $upgrade }
    return [ordered]@{
        '热度排序' = [int]$r.'热度排序'
        '热度层级' = [string]$r.'热度层级'
        '品类' = [string]$r.'品类'
        '品牌中文名' = $b.cn
        '品牌英文名' = $b.en
        '推荐型号或型号族' = [string]$r.'推荐型号或型号族'
        '国内用户信号' = [string]$r.'国内用户信号'
        '海外销售类型' = [string]$r.'海外销售类型'
        '拆机/替换升级件' = ($parts -join '；')
        '品牌来源' = $b.source
        '中国替换件可得性' = $b.supply
        '选品优先级' = $b.priority
    }
}

$additionJson = @'
[
  {"热度排序":212,"热度层级":"S","品类":"加湿器","品牌":"Midea","推荐型号或型号族":"智能蒸发/超声波加湿器海外系列","整机常见价位美元":"约80-300","国内用户信号":"国内家庭用户和家电渠道非常多","海外销售类型":"全球渠道和OEM强","适合开发的高客单非耗材替换升级改装件":"水箱外壳、底座、浮球、雾化仓保护、防倾倒结构和墙装架","配件售价潜力":"50-180","符合条件":"直接符合","主要核查点":"海外电压、机型和涉水材料"},
  {"热度排序":213,"热度层级":"S","品类":"加湿器","品牌":"Deerma","推荐型号或型号族":"DEM-F系列、F600/F628海外型号","整机常见价位美元":"约40-160","国内用户信号":"国内销量大，配件和模具供应充足","海外销售类型":"跨境电商和OEM活跃","适合开发的高客单非耗材替换升级改装件":"水箱、底座、雾化片仓、浮球、旋钮和防漏结构","配件售价潜力":"40-150","符合条件":"直接符合","主要核查点":"具体型号、雾化片规格和防漏"},
  {"热度排序":214,"热度层级":"S","品类":"加湿器","品牌":"Bear","推荐型号或型号族":"JSQ系列、加湿器出口系列","整机常见价位美元":"约50-180","国内用户信号":"国内家庭用户多，供应链成熟","海外销售类型":"东南亚、中东和跨境渠道","适合开发的高客单非耗材替换升级改装件":"水箱、底座、旋钮、雾化仓保护和防倾倒结构","配件售价潜力":"40-150","符合条件":"直接符合","主要核查点":"型号命名和海外插头"},
  {"热度排序":215,"热度层级":"S","品类":"加湿器","品牌":"Smartmi","推荐型号或型号族":"Evaporative Humidifier 2、Rainforest系列","整机常见价位美元":"约120-300","国内用户信号":"智能家居用户和小米生态用户多","海外销售类型":"欧美智能家居渠道","适合开发的高客单非耗材替换升级改装件":"水箱结构、底座、风道静音件、传感器保护和墙装结构","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"米家协议、传感器和涉水件"},
  {"热度排序":216,"热度层级":"S","品类":"加湿器","品牌":"小米","推荐型号或型号族":"米家智能加湿器 2、无雾加湿器系列","整机常见价位美元":"约50-220","国内用户信号":"国内覆盖面广，配件和维修生态强","海外销售类型":"海外米家渠道和跨境电商","适合开发的高客单非耗材替换升级改装件":"水箱、底座、浮球、风道、墙装架和防倾倒结构","配件售价潜力":"50-180","符合条件":"直接符合","主要核查点":"米家版本、接口和水路"},
  {"热度排序":217,"热度层级":"A","品类":"加湿器","品牌":"Haier","推荐型号或型号族":"加湿器海外系列、无雾系列","整机常见价位美元":"约80-250","国内用户信号":"国内家电渠道和维修网络广","海外销售类型":"全球家电渠道","适合开发的高客单非耗材替换升级改装件":"水箱、底座、排水结构、风道和控制面板外壳","配件售价潜力":"50-180","符合条件":"直接符合","主要核查点":"地区型号差异"},
  {"热度排序":218,"热度层级":"A","品类":"加湿器","品牌":"Gree","推荐型号或型号族":"加湿器及空气处理海外系列","整机常见价位美元":"约80-250","国内用户信号":"国内空调和空气处理用户多","海外销售类型":"全球空调渠道和OEM","适合开发的高客单非耗材替换升级改装件":"水箱、底座、风道、排水和防倾倒结构","配件售价潜力":"50-180","符合条件":"直接符合","主要核查点":"海外型号和电控安全"},
  {"热度排序":219,"热度层级":"A","品类":"加湿器","品牌":"Joyoung","推荐型号或型号族":"无雾加湿器、智能加湿器出口系列","整机常见价位美元":"约70-220","国内用户信号":"国内小家电用户和供应链多","海外销售类型":"东南亚、中东及OEM","适合开发的高客单非耗材替换升级改装件":"水箱、底座、浮球、雾化仓和控制面板外壳","配件售价潜力":"50-160","符合条件":"直接符合","主要核查点":"具体出口型号"},
  {"热度排序":220,"热度层级":"A","品类":"加湿器","品牌":"AUX","推荐型号或型号族":"加湿器及空气处理出口系列","整机常见价位美元":"约50-180","国内用户信号":"国内家电渠道广，工厂资源多","海外销售类型":"东南亚、中东和OEM","适合开发的高客单非耗材替换升级改装件":"水箱、底座、排水转接、风道和防倾倒结构","配件售价潜力":"40-150","符合条件":"直接符合","主要核查点":"海外型号和插头"},
  {"热度排序":221,"热度层级":"A","品类":"加湿器","品牌":"Donlim","推荐型号或型号族":"小家电出口加湿器系列","整机常见价位美元":"约50-180","国内用户信号":"国内制造和OEM供应链明确","海外销售类型":"欧美小家电OEM和跨境渠道","适合开发的高客单非耗材替换升级改装件":"水箱、底座、浮球、旋钮和雾化仓保护","配件售价潜力":"40-150","符合条件":"直接符合","主要核查点":"OEM机型和配件共用性"},
  {"热度排序":222,"热度层级":"A","品类":"加湿器","品牌":"Philips","推荐型号或型号族":"HU系列、无雾加湿器海外系列","整机常见价位美元":"约100-350","国内用户信号":"国内品牌认知和维修渠道强","海外销售类型":"全球家电渠道","适合开发的高客单非耗材替换升级改装件":"水箱、底座、风道、传感器保护和防倾倒结构","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"地区型号和涉水安全"},
  {"热度排序":223,"热度层级":"S","品类":"空气净化器","品牌":"小米","推荐型号或型号族":"米家空气净化器 4 Pro、Ultra系列","整机常见价位美元":"约150-500","国内用户信号":"国内用户和生态链配件供应强","海外销售类型":"海外米家和跨境电商","适合开发的高客单非耗材替换升级改装件":"底座、风道导流、墙装结构、传感器保护和防倾倒件","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"滤芯不做，核对传感器和外壳"},
  {"热度排序":224,"热度层级":"A","品类":"空气净化器","品牌":"Smartmi","推荐型号或型号族":"P1、P2、Air Purifier系列","整机常见价位美元":"约150-450","国内用户信号":"智能家居用户和供应链明确","海外销售类型":"欧美智能家居渠道","适合开发的高客单非耗材替换升级改装件":"底座、风道、墙装结构、传感器保护和静音改装","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"滤芯不做，核对联网和传感器"},
  {"热度排序":225,"热度层级":"A","品类":"空气净化器","品牌":"Philips","推荐型号或型号族":"AC系列、4000i/5000i系列","整机常见价位美元":"约200-600","国内用户信号":"国内家庭用户和配件市场成熟","海外销售类型":"全球家电渠道","适合开发的高客单非耗材替换升级改装件":"底座、风道、墙装支架、传感器保护和机身结构","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"滤网耗材排除"},
  {"热度排序":226,"热度层级":"S","品类":"除湿机","品牌":"Haier","推荐型号或型号族":"大型除湿机、地下室除湿系列","整机常见价位美元":"约250-700","国内用户信号":"国内家电渠道和维修资源广","海外销售类型":"欧美、东南亚家电渠道","适合开发的高客单非耗材替换升级改装件":"连续排水转接、脚轮底座、风道和水箱结构","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"排水接口和地区型号"},
  {"热度排序":227,"热度层级":"A","品类":"除湿机","品牌":"Gree","推荐型号或型号族":"高容量除湿机海外系列","整机常见价位美元":"约250-700","国内用户信号":"国内空调渠道和供应链强","海外销售类型":"海外家电渠道和OEM","适合开发的高客单非耗材替换升级改装件":"连续排水、脚轮、风道、冷凝水接口和防倾倒结构","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"冷媒和电控不做"},
  {"热度排序":228,"热度层级":"A","品类":"除湿机","品牌":"Hisense","推荐型号或型号族":"除湿机海外系列、50-Pint系列","整机常见价位美元":"约250-650","国内用户信号":"国内家电用户和制造供应链多","海外销售类型":"全球家电渠道和OEM","适合开发的高客单非耗材替换升级改装件":"排水转接、脚轮底座、风道和控制面板外壳","配件售价潜力":"60-200","符合条件":"直接符合","主要核查点":"海外型号和排水口"},
  {"热度排序":229,"热度层级":"A","品类":"除湿机","品牌":"TCL","推荐型号或型号族":"除湿机海外系列","整机常见价位美元":"约220-600","国内用户信号":"国内渠道广、出口供应链明确","海外销售类型":"全球家电渠道和OEM","适合开发的高客单非耗材替换升级改装件":"连续排水、脚轮底座、风道和水箱结构","配件售价潜力":"50-200","符合条件":"直接符合","主要核查点":"地区型号和电压"},
  {"热度排序":230,"热度层级":"S","品类":"吸尘器","品牌":"Roborock","推荐型号或型号族":"Dyad Pro、Flexi Pro、H系列手持/洗地平台","整机常见价位美元":"约300-800","国内用户信号":"国内石头科技用户和维修生态强","海外销售类型":"海外智能清洁渠道强","适合开发的高客单非耗材替换升级改装件":"滚刷仓结构、污水箱、底座、风道和停靠支架","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"电机和电池不做，核对卡扣"},
  {"热度排序":231,"热度层级":"A","品类":"吸尘器","品牌":"小米","推荐型号或型号族":"米家无线吸尘器、手持吸尘器高配系列","整机常见价位美元":"约150-500","国内用户信号":"国内保有量和配件市场大","海外销售类型":"海外米家和跨境电商","适合开发的高客单非耗材替换升级改装件":"尘杯、吸头外壳、墙挂支架、风道和收纳底座","配件售价潜力":"50-180","符合条件":"直接符合","主要核查点":"电池和滤芯不做"},
  {"热度排序":232,"热度层级":"A","品类":"洗地机","品牌":"Roborock","推荐型号或型号族":"Flexi Pro、Flexi Lite、Dyad系列","整机常见价位美元":"约300-800","国内用户信号":"国内用户和维修件供应充足","海外销售类型":"海外智能清洁市场强","适合开发的高客单非耗材替换升级改装件":"滚刷盖、污水箱、底座、风道和停靠支架","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"电池、滚刷耗材排除"},
  {"热度排序":233,"热度层级":"A","品类":"便携空调","品牌":"Hisense","推荐型号或型号族":"便携变频空调、AP系列","整机常见价位美元":"约350-900","国内用户信号":"国内家电渠道和配件工厂多","海外销售类型":"北美、欧洲和澳洲渠道","适合开发的高客单非耗材替换升级改装件":"窗封、排风管转接、冷凝水排放、脚轮底座和隔音结构","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"窗型、管径和冷媒安全"},
  {"热度排序":234,"热度层级":"A","品类":"便携空调","品牌":"TCL","推荐型号或型号族":"便携空调海外系列","整机常见价位美元":"约300-800","国内用户信号":"国内渠道和出口供应链明确","海外销售类型":"北美、欧洲和东南亚渠道","适合开发的高客单非耗材替换升级改装件":"窗封、排风管、排水、脚轮和机身支架","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"地区窗型和管径"},
  {"热度排序":235,"热度层级":"S","品类":"安防摄像机","品牌":"EZVIZ","推荐型号或型号族":"C8W、H8 Pro、NVR套装","整机常见价位美元":"约80-500","国内用户信号":"萤石国内渠道和安装生态成熟","海外销售类型":"全球消费安防渠道","适合开发的高客单非耗材替换升级改装件":"壁装、立杆、遮阳罩、防水接线盒和线缆管理","配件售价潜力":"40-180","符合条件":"直接符合","主要核查点":"防水等级、孔位和供电"},
  {"热度排序":236,"热度层级":"A","品类":"安防摄像机","品牌":"IMOU","推荐型号或型号族":"Cruiser、Ranger、NVR套装","整机常见价位美元":"约60-400","国内用户信号":"乐橙国内安装和供应链明确","海外销售类型":"海外电商和工程渠道","适合开发的高客单非耗材替换升级改装件":"壁装、杆装、防水接线盒、遮阳罩和线缆固定","配件售价潜力":"40-160","符合条件":"直接符合","主要核查点":"孔位、供电和防水"},
  {"热度排序":237,"热度层级":"A","品类":"安防摄像机","品牌":"TP-Link Tapo","推荐型号或型号族":"C425、C520WS、H500套装","整机常见价位美元":"约60-400","国内用户信号":"普联国内用户和配件供应链强","海外销售类型":"海外消费安防渠道","适合开发的高客单非耗材替换升级改装件":"壁装、吸顶、遮阳罩、防水接线盒和线缆管理","配件售价潜力":"40-160","符合条件":"直接符合","主要核查点":"无线版本、孔位和防水"},
  {"热度排序":238,"热度层级":"A","品类":"安防摄像机","品牌":"Uniview","推荐型号或型号族":"ColorHunter、NVR高配套装","整机常见价位美元":"约200-1200","国内用户信号":"宇视工程渠道和配件工厂强","海外销售类型":"海外工程和商用安防渠道","适合开发的高客单非耗材替换升级改装件":"壁装、立杆、遮阳罩、防水接线盒、机架和散热件","配件售价潜力":"80-300","符合条件":"直接符合","主要核查点":"工程型号、承重和防水"},
  {"热度排序":239,"热度层级":"S","品类":"网络设备","品牌":"Ruijie/Reyee","推荐型号或型号族":"RG-EG、RG-AP、RG-Switch高配系列","整机常见价位美元":"约100-1500","国内用户信号":"国内企业网络用户和供应链强","海外销售类型":"海外工程和跨境渠道","适合开发的高客单非耗材替换升级改装件":"机架托盘、壁装支架、散热、光纤理线和防尘结构","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"孔位、散热和机架尺寸"},
  {"热度排序":240,"热度层级":"A","品类":"网络设备","品牌":"Tenda","推荐型号或型号族":"商用交换机、Wi-Fi 7路由和Mesh系列","整机常见价位美元":"约80-500","国内用户信号":"国内用户多，配件制造容易","海外销售类型":"东南亚、欧洲和跨境电商","适合开发的高客单非耗材替换升级改装件":"壁装、机架、散热、理线和防尘结构","配件售价潜力":"40-180","符合条件":"直接符合","主要核查点":"孔位、天线和散热"},
  {"热度排序":241,"热度层级":"A","品类":"电动工具系统","品牌":"WORX","推荐型号或型号族":"20V/40V PowerShare、Landroid系列","整机常见价位美元":"约150-1000","国内用户信号":"威克士国内渠道和制造供应链强","海外销售类型":"欧美园艺和工具市场强","适合开发的高客单非耗材替换升级改装件":"工具箱、墙挂、导轨夹具、集尘转接和机身防护结构","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"电池和电机不做，核对接口"},
  {"热度排序":242,"热度层级":"A","品类":"水处理设备","品牌":"Angel","推荐型号或型号族":"A7、J系列高端净水/商用设备","整机常见价位美元":"约300-2000","国内用户信号":"国内安装、维修和制造供应链强","海外销售类型":"东南亚、中东及工程出口","适合开发的高客单非耗材替换升级改装件":"安装支架、管路转接、旁通结构、压力罐底座和防护箱","配件售价潜力":"80-300","符合条件":"直接符合","主要核查点":"滤芯耗材不做，核对接口和涉水材料"},
  {"热度排序":243,"热度层级":"S","品类":"冰淇淋机","品牌":"Spaceman","推荐型号或型号族":"6210-C、6235-C Commercial Soft Serve Series","整机常见价位美元":"约2500-9000","国内用户信号":"国内商用餐饮、工厂和配件供应链明确","海外销售类型":"北美、欧洲、澳洲和东南亚出口","适合开发的高客单非耗材替换升级改装件":"料斗盖、门组件、搅拌器护罩、脚轮底座、散热风道和维修面板","配件售价潜力":"100-600","符合条件":"直接符合","主要核查点":"食品接触材料、冷媒和型号接口"},
  {"热度排序":244,"热度层级":"S","品类":"冰淇淋机","品牌":"Donper","推荐型号或型号族":"Commercial Soft Serve、Batch Freezer Export Series","整机常见价位美元":"约1800-8000","国内用户信号":"东贝国内制造和商用渠道强","海外销售类型":"全球OEM、餐饮工程和跨境出口","适合开发的高客单非耗材替换升级改装件":"料斗盖、门组件、脚轮、搅拌器护罩、冷凝器风道和外壳结构","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"食品接触、制冷系统和出口电压"},
  {"热度排序":245,"热度层级":"A","品类":"冰淇淋机","品牌":"Oceanpower","推荐型号或型号族":"Soft Serve、Hard Ice Cream and Batch Freezer Series","整机常见价位美元":"约2000-10000","国内用户信号":"国内商用制冷和出口工厂资源明确","海外销售类型":"欧美、中东和东南亚餐饮工程","适合开发的高客单非耗材替换升级改装件":"料斗盖、出料门、脚轮底座、护罩、散热风道和维修面板","配件售价潜力":"100-600","符合条件":"直接符合","主要核查点":"具体出口型号、食品接触和冷媒"},
  {"热度排序":246,"热度层级":"A","品类":"冰淇淋机","品牌":"Taylor","推荐型号或型号族":"C708、C716、152 Series","整机常见价位美元":"约5000-15000","国内用户信号":"国内连锁餐饮、维修和兼容件工厂有基础","海外销售类型":"北美和全球商用餐饮市场强","适合开发的高客单非耗材替换升级改装件":"门组件、料斗盖、脚轮、护罩、维修面板和散热结构","配件售价潜力":"120-800","符合条件":"直接符合","主要核查点":"专用接口、食品安全和商标外观"},
  {"热度排序":247,"热度层级":"A","品类":"冰淇淋机","品牌":"Carpigiani","推荐型号或型号族":"LB 100、191 P、Pastomaster Series","整机常见价位美元":"约6000-20000","国内用户信号":"国内高端烘焙、餐饮和维修渠道有用户","海外销售类型":"欧洲、北美和亚洲商用市场强","适合开发的高客单非耗材替换升级改装件":"门组件、料斗盖、脚轮底座、护罩、散热风道和机架结构","配件售价潜力":"150-1000","符合条件":"直接符合","主要核查点":"食品接触、机型尺寸和专用接口"},
  {"热度排序":248,"热度层级":"S","品类":"造雪机","品牌":"SMI Snow Makers","推荐型号或型号族":"Super PoleCat、SnowBurst、Fan Gun Series","整机常见价位美元":"约10000-60000","国内用户信号":"国内雪场工程和金属结构供应链可配套","海外销售类型":"北美雪场和冬季工程市场强","适合开发的高客单非耗材替换升级改装件":"炮体支架、旋转底座、软管导向、护罩、检修平台和运输架","配件售价潜力":"300-3000","符合条件":"直接符合","主要核查点":"高压水气、承重、防冻和安全距离"},
  {"热度排序":249,"热度层级":"A","品类":"造雪机","品牌":"HKD Snowmakers","推荐型号或型号族":"HKD SnowGun、HKD Fan Gun Series","整机常见价位美元":"约12000-70000","国内用户信号":"国内雪场建设和钣金加工供应链可找","海外销售类型":"北美专业雪场市场强","适合开发的高客单非耗材替换升级改装件":"炮体支架、旋转底座、软管导向、防护罩、维护梯和运输结构","配件售价潜力":"300-3500","符合条件":"直接符合","主要核查点":"高压管路、风机和极寒环境"},
  {"热度排序":250,"热度层级":"A","品类":"造雪机","品牌":"TechnoAlpin","推荐型号或型号族":"TF Series、M Series、Snow Gun Platforms","整机常见价位美元":"约15000-90000","国内用户信号":"国内滑雪场工程商和兼容加工厂有基础","海外销售类型":"欧洲、北美和亚洲雪场工程强","适合开发的高客单非耗材替换升级改装件":"底座、炮体支撑、管线护罩、维护平台、运输架和防冻结构","配件售价潜力":"400-4000","符合条件":"直接符合","主要核查点":"高压水气、防冻和专用接口"},
  {"热度排序":251,"热度层级":"A","品类":"造雪机","品牌":"Demaclenko","推荐型号或型号族":"EOS、Titan、Fan Gun Series","整机常见价位美元":"约15000-90000","国内用户信号":"国内雪场工程和金属结构件供应链可配套","海外销售类型":"欧洲和国际雪场工程市场强","适合开发的高客单非耗材替换升级改装件":"炮体支架、旋转底座、软管导向、护罩、维护平台和运输架","配件售价潜力":"400-4000","符合条件":"直接符合","主要核查点":"极寒、防冻、高压和专用接口"},
  {"热度排序":252,"热度层级":"A","品类":"商用制冰机","品牌":"Scotsman","推荐型号或型号族":"Prodigy、C0322、Hoshizaki-compatible Series","整机常见价位美元":"约2500-12000","国内用户信号":"国内酒店、餐饮和维修供应链有用户","海外销售类型":"全球商用餐饮和酒店渠道强","适合开发的高客单非耗材替换升级改装件":"储冰箱底座、排水转接、机架、散热风道、门板和防护结构","配件售价潜力":"100-800","符合条件":"直接符合","主要核查点":"水路、卫生、冷媒和电压"},
  {"热度排序":253,"热度层级":"A","品类":"商用制冰机","品牌":"Manitowoc Ice","推荐型号或型号族":"Indigo NXT、Sotto、Neo Series","整机常见价位美元":"约3000-15000","国内用户信号":"国内酒店工程和兼容件工厂有基础","海外销售类型":"北美、欧洲和亚洲商用渠道强","适合开发的高客单非耗材替换升级改装件":"储冰箱底座、排水系统、机架、散热和维护面板","配件售价潜力":"120-900","符合条件":"直接符合","主要核查点":"水路卫生、冷媒和接口"},
  {"热度排序":254,"热度层级":"A","品类":"商用制冰机","品牌":"Hoshizaki","推荐型号或型号族":"KM、FM、IM Series","整机常见价位美元":"约3000-16000","国内用户信号":"国内酒店、餐饮和制冷维修供应链有用户","海外销售类型":"日本、北美、欧洲和亚洲商用渠道强","适合开发的高客单非耗材替换升级改装件":"储冰箱底座、排水转接、机架、散热风道、门板和防护结构","配件售价潜力":"120-900","符合条件":"直接符合","主要核查点":"水路卫生、冷媒、电压和接口"},
  {"热度排序":255,"热度层级":"A","品类":"舞台特效造雪机","品牌":"Antari","推荐型号或型号族":"S-500、S-200、Snow Machine Series","整机常见价位美元":"约300-1800","国内用户信号":"中国制造和舞台设备供应链成熟","海外销售类型":"全球演出、主题乐园和活动租赁市场","适合开发的高客单非耗材替换升级改装件":"喷口、风扇罩、泵体支架、机箱、吊挂和运输箱结构","配件售价潜力":"60-350","符合条件":"直接符合","主要核查点":"液路、风扇和舞台安全"},
  {"热度排序":256,"热度层级":"A","品类":"舞台特效造雪机","品牌":"Chauvet DJ","推荐型号或型号族":"Snow Machine、Snow Machine Q6","整机常见价位美元":"约400-2200","国内用户信号":"国内演出设备渠道和兼容加工厂有基础","海外销售类型":"欧美演出和活动市场强","适合开发的高客单非耗材替换升级改装件":"喷口、风扇罩、吊挂、机箱、运输箱和控制面板外壳","配件售价潜力":"60-400","符合条件":"直接符合","主要核查点":"液路、DMX和外壳接口"},
  {"热度排序":257,"热度层级":"A","品类":"舞台特效造雪机","品牌":"ADJ","推荐型号或型号族":"Entour Snow、VF Snow Flurry Series","整机常见价位美元":"约300-1800","国内用户信号":"国内舞台灯光和特效设备供应链可找","海外销售类型":"欧美演出、酒吧和主题活动市场","适合开发的高客单非耗材替换升级改装件":"喷口、泵体支架、风扇罩、吊挂和运输结构","配件售价潜力":"60-350","符合条件":"直接符合","主要核查点":"液路、控制协议和防护"},
  {"热度排序":258,"热度层级":"A","品类":"除雪机","品牌":"Ariens","推荐型号或型号族":"Deluxe 28、Platinum 30、Professional Series","整机常见价位美元":"约1000-3500","国内用户信号":"国内园林机械和金属件供应链明确","海外销售类型":"北美冬季庭院设备市场强","适合开发的高客单非耗材替换升级改装件":"导流槽、把手、轮架、护罩、收纳和运输结构","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"传动、刀片等核心件不做"},
  {"热度排序":259,"热度层级":"A","品类":"除雪机","品牌":"Toro","推荐型号或型号族":"Power Max HD、SnowMaster Series","整机常见价位美元":"约800-3000","国内用户信号":"国内园林机械供应链和兼容加工厂可找","海外销售类型":"北美和欧洲冬季设备市场强","适合开发的高客单非耗材替换升级改装件":"导流槽、把手、轮架、护罩、运输架和收纳结构","配件售价潜力":"80-450","符合条件":"直接符合","主要核查点":"传动和抛雪核心件不做"},
  {"热度排序":279,"热度层级":"A","品类":"标签打印机","品牌":"SATO","推荐型号或型号族":"CL4NX Plus、CT4-LX、FX3-LX","整机常见价位美元":"约500-2500","国内用户信号":"国内仓储、制造业和标签设备供应链有用户","海外销售类型":"欧美、日韩商用标签市场强","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、打印头保护罩、桌面支架、机架和理线结构","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"打印头耗材不做，核对纸路和接口"},
  {"热度排序":280,"热度层级":"A","品类":"标签打印机","品牌":"TSC","推荐型号或型号族":"MH241、MX241P、TE210高配系列","整机常见价位美元":"约250-1800","国内用户信号":"中国品牌和仓储标签设备供应链明确","海外销售类型":"欧美、东南亚和跨境电商渠道","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、桌面支架、机架、理线和防尘结构","配件售价潜力":"60-350","符合条件":"直接符合","主要核查点":"型号接口和纸路"},
  {"热度排序":281,"热度层级":"A","品类":"标签打印机","品牌":"GoDEX","推荐型号或型号族":"RT700i、ZX1200i、HD830i","整机常见价位美元":"约250-1800","国内用户信号":"国内标签打印、仓储和制造业用户多","海外销售类型":"欧洲、东南亚和拉美商用市场","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、打印头保护、机架和线缆管理","配件售价潜力":"60-350","符合条件":"直接符合","主要核查点":"纸路、接口和耐用性"},
  {"热度排序":282,"热度层级":"A","品类":"标签打印机","品牌":"Bixolon","推荐型号或型号族":"XT5-40、SRT-Q300、XD5-40d","整机常见价位美元":"约250-1600","国内用户信号":"国内零售、物流和标签设备配件渠道可找","海外销售类型":"欧美商用市场稳定","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、机架、桌面支架和理线结构","配件售价潜力":"60-300","符合条件":"直接符合","主要核查点":"纸路和接口"},
  {"热度排序":283,"热度层级":"A","品类":"标签打印机","品牌":"Honeywell","推荐型号或型号族":"PM45、PD45、PX45","整机常见价位美元":"约500-3000","国内用户信号":"国内仓储和工业打印机工程渠道强","海外销售类型":"全球商用和工业市场","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、机架、打印头保护和理线结构","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"工业纸路、接口和打印头耗材排除"},
  {"热度排序":260,"热度层级":"S","品类":"雪道压雪机","品牌":"Prinoth","推荐型号或型号族":"Bison、Leitwolf、Husky Snow Groomer Series","整机常见价位美元":"约250000-600000","国内用户信号":"国内滑雪场工程商和钣金、液压结构供应链可配套","海外销售类型":"美国、加拿大和欧洲雪场市场强","适合开发的高客单非耗材替换升级改装件":"雪道铲架、铣雪器护罩、履带护板、检修平台、灯具支架和运输固定件","配件售价潜力":"500-8000","符合条件":"直接符合","主要核查点":"液压、履带承重、低温材料和专用接口"},
  {"热度排序":261,"热度层级":"S","品类":"雪道压雪机","品牌":"PistenBully","推荐型号或型号族":"PistenBully 600、PistenBully 400、PistenBully 100","整机常见价位美元":"约220000-550000","国内用户信号":"国内雪场设备和工程维保渠道有基础","海外销售类型":"美国、加拿大和欧洲雪场市场强","适合开发的高客单非耗材替换升级改装件":"铲架、铣雪器护罩、履带护板、驾驶室附件、检修平台和运输架","配件售价潜力":"500-8000","符合条件":"直接符合","主要核查点":"履带、液压、车体尺寸和专用接口"},
  {"热度排序":262,"热度层级":"A","品类":"雪道压雪机","品牌":"Tucker Sno-Cat","推荐型号或型号族":"Tucker Sno-Cat 2000、1600、1000","整机常见价位美元":"约180000-450000","国内用户信号":"国内极地、雪场和特种车辆结构件供应链可找","海外销售类型":"北美雪场、极地和特种作业市场","适合开发的高客单非耗材替换升级改装件":"履带护板、铲架、车厢结构、检修踏板、灯具支架和运输固定件","配件售价潜力":"400-6000","符合条件":"直接符合","主要核查点":"履带、底盘承重和极寒环境"},
  {"热度排序":263,"热度层级":"S","品类":"冰场刮冰车","品牌":"Zamboni","推荐型号或型号族":"Zamboni 552、525、450","整机常见价位美元":"约80000-180000","国内用户信号":"国内冰场、冰球馆和维修供应链有用户","海外销售类型":"美国冰场和体育场馆市场强","适合开发的高客单非耗材替换升级改装件":"刮冰刀架、水箱支撑、侧板、脚轮、检修门和运输固定件","配件售价潜力":"200-3000","符合条件":"直接符合","主要核查点":"涉水卫生、车体尺寸、刮冰精度和专用接口"},
  {"热度排序":264,"热度层级":"A","品类":"冰场刮冰车","品牌":"Resurfice Olympia","推荐型号或型号族":"Olympia Millennium H、Olympia CCT","整机常见价位美元":"约70000-180000","国内用户信号":"国内冰场工程和金属结构件供应链可找","海外销售类型":"北美、欧洲和亚洲冰场市场","适合开发的高客单非耗材替换升级改装件":"刮冰刀架、水箱支撑、侧板、脚轮、检修门和运输结构","配件售价潜力":"200-3000","符合条件":"直接符合","主要核查点":"刮冰精度、涉水材料和车体接口"},
  {"热度排序":265,"热度层级":"A","品类":"滑雪板维修设备","品牌":"Wintersteiger","推荐型号或型号族":"Mercury、Sigma、Discovery Ski Service","整机常见价位美元":"约30000-180000","国内用户信号":"国内雪场、滑雪店和维修设备渠道有基础","海外销售类型":"欧美雪场和滑雪店市场强","适合开发的高客单非耗材替换升级改装件":"夹具、工作台、砂轮护罩、除尘罩、机架和外壳结构","配件售价潜力":"150-3000","符合条件":"直接符合","主要核查点":"砂轮安全、除尘、精度和机型尺寸"},
  {"热度排序":266,"热度层级":"A","品类":"滑雪板维修设备","品牌":"Montana Sport","推荐型号或型号族":"Montana Saphir、Montana Crystal、Montana Easy Go","整机常见价位美元":"约25000-150000","国内用户信号":"国内滑雪店和金属加工供应链可找","海外销售类型":"欧美专业滑雪维修市场","适合开发的高客单非耗材替换升级改装件":"夹具、工作台、砂轮护罩、除尘结构、机架和检修门","配件售价潜力":"150-2800","符合条件":"直接符合","主要核查点":"磨削安全、精度和专用接口"},
  {"热度排序":267,"热度层级":"A","品类":"滑雪板维修设备","品牌":"Reichmann","推荐型号或型号族":"Profi、Ski Service、Race Service Series","整机常见价位美元":"约25000-150000","国内用户信号":"国内雪场和滑雪店维保渠道有用户","海外销售类型":"欧洲、北美专业市场","适合开发的高客单非耗材替换升级改装件":"夹具、砂轮护罩、除尘罩、机架、外壳和检修结构","配件售价潜力":"150-2800","符合条件":"直接符合","主要核查点":"磨削安全、精度和除尘"},
  {"热度排序":268,"热度层级":"S","品类":"商用除雪设备","品牌":"Bobcat","推荐型号或型号族":"Toolcat 5600、S650、S76 Snow Attachments","整机常见价位美元":"约45000-120000","国内用户信号":"国内工程机械、液压和属具供应链强","海外销售类型":"美国商业地产、市政和雪场市场强","适合开发的高客单非耗材替换升级改装件":"除雪铲连接架、抛雪机导流槽、液压管护罩、轮架和驾驶室防护件","配件售价潜力":"150-2500","符合条件":"直接符合","主要核查点":"液压接口、承重和属具兼容"},
  {"热度排序":269,"热度层级":"A","品类":"商用除雪设备","品牌":"John Deere","推荐型号或型号族":"1025R、2032R、X739 Snow Attachments","整机常见价位美元":"约20000-90000","国内用户信号":"国内农机、工程机械和金属件供应链明确","海外销售类型":"美国住宅、农场和市政冬季维护市场","适合开发的高客单非耗材替换升级改装件":"除雪铲、抛雪机连接架、护罩、轮架、驾驶室附件和运输固定件","配件售价潜力":"100-1800","符合条件":"直接符合","主要核查点":"三点悬挂、液压和机型尺寸"},
  {"热度排序":270,"热度层级":"A","品类":"除雪机","品牌":"Honda","推荐型号或型号族":"HSS1332A、HSS928A、HSS724A","整机常见价位美元":"约1800-4500","国内用户信号":"国内本田动力和园林机械维修供应链成熟","海外销售类型":"北美和日本冬季庭院设备市场强","适合开发的高客单非耗材替换升级改装件":"导流槽、把手、轮架、护罩、运输架和收纳结构","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"传动、抛雪核心件和机型接口"},
  {"热度排序":271,"热度层级":"A","品类":"雪铲与推雪附件","品牌":"BOSS Snowplow","推荐型号或型号族":"V-XT、D XT、TripEdge Series","整机常见价位美元":"约4000-15000","国内用户信号":"国内钣金、液压和挂载结构供应链明确","海外销售类型":"美国皮卡、车队和商业除雪市场强","适合开发的高客单非耗材替换升级改装件":"挂载架、铲体加强件、液压管护罩、灯架、收纳架和运输固定件","配件售价潜力":"100-1500","符合条件":"直接符合","主要核查点":"车辆底盘、液压和承重"},
  {"热度排序":272,"热度层级":"A","品类":"雪铲与推雪附件","品牌":"Fisher","推荐型号或型号族":"XV2、XtremeV、Meyer-compatible Series","整机常见价位美元":"约3500-14000","国内用户信号":"国内车辆附件、钣金和液压加工厂可找","海外销售类型":"美国商业车队和道路除雪市场强","适合开发的高客单非耗材替换升级改装件":"挂载架、铲体加强件、液压护罩、灯架和运输结构","配件售价潜力":"100-1400","符合条件":"直接符合","主要核查点":"挂载孔位、液压和承重"},
  {"热度排序":273,"热度层级":"A","品类":"融雪剂撒布机","品牌":"SnowEx","推荐型号或型号族":"V-Maxx、Tailgate Pro、Helixx Series","整机常见价位美元":"约2000-12000","国内用户信号":"国内钣金、滚筒和车辆附件供应链成熟","海外销售类型":"美国商业车队和市政冬季维护市场强","适合开发的高客单非耗材替换升级改装件":"料斗框架、输送螺杆护罩、挂载架、挡料板、控制箱支架和运输结构","配件售价潜力":"100-1200","符合条件":"直接符合","主要核查点":"防腐材料、车辆挂载和传动安全"},
  {"热度排序":274,"热度层级":"A","品类":"融雪剂撒布机","品牌":"Henderson","推荐型号或型号族":"V-Box、FRH、Tailgate Spreader Series","整机常见价位美元":"约5000-30000","国内用户信号":"国内市政车辆、料斗和金属结构供应链可找","海外销售类型":"美国市政、机场和道路维护市场强","适合开发的高客单非耗材替换升级改装件":"料斗框架、输送结构护罩、挂载架、挡料板、梯架和检修门","配件售价潜力":"150-2000","符合条件":"直接符合","主要核查点":"防腐、承重、车辆接口和传动"},
  {"热度排序":275,"热度层级":"A","品类":"商用融雪机","品牌":"Trecan","推荐型号或型号族":"60-PD、120-PD、Snowmelter Series","整机常见价位美元":"约150000-600000","国内用户信号":"国内市政工程、钢结构和热交换器供应链可配套","海外销售类型":"北美机场、市政和大型商业场地市场","适合开发的高客单非耗材替换升级改装件":"进料斗、检修门、输送结构、护栏、平台和运输固定件","配件售价潜力":"500-8000","符合条件":"直接符合","主要核查点":"高温、融水、防腐和安全防护"},
  {"热度排序":276,"热度层级":"A","品类":"滑雪索道设备","品牌":"Doppelmayr","推荐型号或型号族":"D-Line、Uni-G、Chairlift Systems","整机常见价位美元":"约1000000-15000000","国内用户信号":"国内索道工程、钢结构和机加工供应链强","海外销售类型":"美国、加拿大和欧洲雪场工程市场","适合开发的高客单非耗材替换升级改装件":"座椅支架、检修平台、护罩、钢索导向结构、设备机架和防护栏","配件售价潜力":"500-10000","符合条件":"直接符合","主要核查点":"承重、焊接、钢索安全和工程认证"},
  {"热度排序":277,"热度层级":"A","品类":"滑雪索道设备","品牌":"Leitner","推荐型号或型号族":"LEITNER Ropeway、Premium Chairlift Systems","整机常见价位美元":"约1000000-15000000","国内用户信号":"国内索道工程和金属结构供应链可配套","海外销售类型":"北美、欧洲和亚洲雪场工程市场","适合开发的高客单非耗材替换升级改装件":"座椅支架、检修平台、护罩、钢索导向、机架和防护栏","配件售价潜力":"500-10000","符合条件":"直接符合","主要核查点":"钢索、承重、焊接和工程认证"},
  {"热度排序":278,"热度层级":"A","品类":"冰场制冷设备","品牌":"CIMCO","推荐型号或型号族":"Ice Rink Refrigeration Systems、Direct Refrigeration Packaged Units","整机常见价位美元":"约200000-2000000","国内用户信号":"国内制冷工程、钢结构和管路供应链强","海外销售类型":"北美冰场、体育馆和娱乐综合体市场","适合开发的高客单非耗材替换升级改装件":"机组底座、管路护罩、检修平台、风道、泵组支架和防护栏","配件售价潜力":"300-6000","符合条件":"直接符合","主要核查点":"冷媒、高压、管路和工程安全"},
  {"热度排序":284,"热度层级":"S","品类":"投影仪","品牌":"Nebula","推荐型号或型号族":"Capsule 3 Laser","整机常见价位美元":"约700-1100","国内用户信号":"安克创新消费电子出口品牌，国内研发和结构件供应链成熟","海外销售类型":"Amazon US、Best Buy及海外影音渠道常见","美国站需求信号":"候选待实核（美国站高客单便携投影）","美国站证据等级":"未实核：Amazon US当前无法读取页面/BSR/配件销量","适合开发的高客单非耗材替换升级改装件":"云台齿轮和俯仰锁止组件、吊装/VESA转接、镜头滑盖、散热风道和运输固定结构","差异化开发判断":"仅在确认整机销量与配件需求后开发；不做装饰件、耗材、电源适配器和电池","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"Nebula海外版本、云台孔位、散热和电气认证"},
  {"热度排序":285,"热度层级":"S","品类":"投影仪","品牌":"Nebula","推荐型号或型号族":"X1 / Cosmos 4K SE","整机常见价位美元":"约1300-3500","国内用户信号":"安克创新出口品牌，国内光机、云台和结构供应链可配套","海外销售类型":"Amazon US、Best Buy及家庭影院渠道","美国站需求信号":"高潜候选（美国站家庭影院高客单系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"电动云台齿轮/锁止、吊装板、镜头滑盖、散热风道、运输保护内架和脚垫结构","差异化开发判断":"优先：型号专用云台/安装/散热件；不做装饰外壳、耗材、电源适配器和电池","配件售价潜力":"120-550","符合条件":"直接符合","主要核查点":"X1与Cosmos 4K SE机身、云台、吊装孔位和光机散热"},
  {"热度排序":286,"热度层级":"S","品类":"投影仪","品牌":"Epson","推荐型号或型号族":"Home Cinema 5050UB / 5050UBe","整机常见价位美元":"约2500-3500","国内用户信号":"爱普生在中国有光学、精密制造和维修供应链","海外销售类型":"Amazon US家庭影院和影音安装渠道强","美国站需求信号":"高潜候选（美国站家庭影院主流高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"吊装板、镜头移位锁止件、灯仓门结构、散热风道、机架和运输固定结构","差异化开发判断":"优先：安装/散热/维护结构件；不做灯泡等耗材、装饰件和电源适配器","配件售价潜力":"120-500","符合条件":"直接符合","主要核查点":"5050UB与5050UBe版本、吊装孔位和光学防尘"},
  {"热度排序":287,"热度层级":"A","品类":"投影仪","品牌":"BenQ","推荐型号或型号族":"HT4550i / TK860i","整机常见价位美元":"约1500-3000","国内用户信号":"明基显示产品在中国有制造和维修配套","海外销售类型":"Amazon US家庭影院、游戏投影渠道","美国站需求信号":"高潜候选（美国站游戏/家庭影院高价型号，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"吊装/VESA转接、镜头滑盖、散热风道、机架、运输内架和线缆应力固定结构","差异化开发判断":"优先：型号专用安装和散热件；不做装饰件、耗材和通用线材","配件售价潜力":"100-400","符合条件":"直接符合","主要核查点":"短焦投射距离、吊装孔位和散热出口"},
  {"热度排序":288,"热度层级":"A","品类":"投影仪","品牌":"Optoma","推荐型号或型号族":"UHD38x / UHZ50","整机常见价位美元":"约1200-2800","国内用户信号":"奥图码显示产品有中国制造和光机供应链","海外销售类型":"Amazon US游戏投影和家庭影院渠道","美国站需求信号":"高潜候选（美国站4K投影高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"吊装板、镜头防尘结构、散热风道、机架、运输固定件和线缆管理结构","差异化开发判断":"优先：型号专用安装/散热/运输件；不做装饰外壳和耗材","配件售价潜力":"100-400","符合条件":"直接符合","主要核查点":"UHD38x与UHZ50孔位、散热和地区型号"},
  {"热度排序":289,"热度层级":"A","品类":"投影仪","品牌":"ViewSonic","推荐型号或型号族":"PX748-4K / X2-4K","整机常见价位美元":"约900-2200","国内用户信号":"优派显示器和投影产品有中国制造配套","海外销售类型":"Amazon US游戏投影和商用显示渠道","美国站需求信号":"美国站高潜候选（游戏投影细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"吊装/VESA转接、镜头滑盖、散热风道、底座加强件和运输内架","差异化开发判断":"优先：型号专用安装/散热件；不做装饰件和通用线材","配件售价潜力":"80-320","符合条件":"直接符合","主要核查点":"短焦X2-4K孔位、光机散热和机身尺寸"},
  {"热度排序":290,"热度层级":"S","品类":"3D打印机","品牌":"Bambu Lab","推荐型号或型号族":"P1S / X1 Carbon / X1E","整机常见价位美元":"约700-2500","国内用户信号":"拓竹为中国出口品牌，深圳精密加工和电子供应链强","海外销售类型":"Amazon US、专业创客和教育渠道热度高","美国站需求信号":"高潜候选（美国站桌面3D打印主流高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"腔体门铰链/锁扣、AMS料盘驱动结构、挤出机安装座、导轨张紧件、散热风道和防尘门结构","差异化开发判断":"优先：型号专用机械/功能升级件；不做喷嘴、耗材、装饰外壳和通用线材","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"P1S/X1系列接口、AMS版本和安全联锁"},
  {"热度排序":291,"热度层级":"A","品类":"3D打印机","品牌":"Creality","推荐型号或型号族":"K1 Max / K2 Plus Combo","整机常见价位美元":"约600-1500","国内用户信号":"创想三维中国制造和配件模具供应链成熟","海外销售类型":"Amazon US创客、教育和打印农场渠道","美国站需求信号":"高潜候选（美国站高性价比大尺寸机型，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"腔体门锁、线轨防护、平台调平结构、导风罩、机架加强件和AMS安装结构","差异化开发判断":"优先：型号专用结构升级件；不做喷嘴耗材、装饰件和通用电源件","配件售价潜力":"70-350","符合条件":"直接符合","主要核查点":"K1/K2平台尺寸、门锁和多色系统接口"},
  {"热度排序":292,"热度层级":"A","品类":"3D打印机","品牌":"Elegoo","推荐型号或型号族":"Neptune 4 Max / Saturn 4 Ultra","整机常见价位美元":"约400-1000","国内用户信号":"爱乐酷中国出口品牌，树脂机和机械件供应链强","海外销售类型":"Amazon US创客和教育渠道活跃","美国站需求信号":"高潜候选（美国站大尺寸/高速细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"平台承载结构、Z轴防护、树脂仓盖铰链、排风接口、机架和运输固定结构","差异化开发判断":"优先：型号专用承载/安全/排风件；不做树脂、喷嘴和装饰件","配件售价潜力":"70-300","符合条件":"直接符合","主要核查点":"Neptune与Saturn结构差异、树脂防护和排风"},
  {"热度排序":293,"热度层级":"A","品类":"3D打印机","品牌":"Anycubic","推荐型号或型号族":"Kobra 3 Combo / Photon Mono M7 Pro","整机常见价位美元":"约450-1000","国内用户信号":"纵维立方中国出口品牌，打印机配件模具齐全","海外销售类型":"Amazon US创客和教育渠道","美国站需求信号":"美国站高潜候选（多色/高速细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"多色料盒安装结构、平台承载件、Z轴防护、排风转接、机架和门锁结构","差异化开发判断":"优先：型号专用结构/安全升级件；不做耗材、喷嘴和装饰件","配件售价潜力":"70-300","符合条件":"直接符合","主要核查点":"Kobra与Photon机型接口、平台和防护结构"},
  {"热度排序":294,"热度层级":"A","品类":"3D打印机","品牌":"Prusa Research","推荐型号或型号族":"MK4S / XL","整机常见价位美元":"约1100-4000","国内用户信号":"普鲁沙在中国有兼容加工和精密件供应链","海外销售类型":"Amazon US专业创客、教育和打印农场","美国站需求信号":"专业利基（美国站高客单、用户粘性强，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"多工具头承载结构、机架加强、线缆拖链、腔体门锁、散热和运输固定件","差异化开发判断":"优先：型号专用机械升级件；不做喷嘴耗材、装饰件和通用线材","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"MK4S/XL工具头接口、机架和安全结构"},
  {"热度排序":295,"热度层级":"S","品类":"运动相机","品牌":"DJI","推荐型号或型号族":"Osmo Pocket 3 / Osmo Action 4","整机常见价位美元":"约350-800","国内用户信号":"大疆中国出口品牌，精密结构和相机配件供应链强","海外销售类型":"Amazon US、Best Buy和户外影像渠道热度高","美国站需求信号":"高潜候选（美国站运动影像主流高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"云台保护/锁止结构、相机笼、快拆底座、磁吸安装座、防水壳骨架和线缆应力件","差异化开发判断":"优先：型号专用安装/保护/云台功能件；不做装饰贴纸、通用线材和电池","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"Pocket 3与Action 4接口、云台活动范围和防水等级"},
  {"热度排序":296,"热度层级":"S","品类":"无人机","品牌":"DJI","推荐型号或型号族":"Mavic 3 Pro / Air 3S","整机常见价位美元":"约1000-2500","国内用户信号":"大疆中国出口品牌，航拍和机加工供应链成熟","海外销售类型":"Amazon US、专业航拍和户外渠道强","美国站需求信号":"高潜候选（美国站高价无人机主流系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"云台保护架、起落架结构、桨叶收纳座、遥控器支架、运输内架和快拆安装件","差异化开发判断":"优先：型号专用结构/安装件；不做桨叶等易耗件、装饰件和电池","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"机型尺寸、云台活动空间、航空法规和责任风险"},
  {"热度排序":297,"热度层级":"A","品类":"运动相机","品牌":"GoPro","推荐型号或型号族":"HERO13 Black / MAX","整机常见价位美元":"约400-700","国内用户信号":"GoPro产品在中国有制造和兼容配件供应链","海外销售类型":"Amazon US户外影像长期主流","美国站需求信号":"高潜候选（美国站成熟运动相机品牌，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"相机笼、镜头保护框、快拆底座、头盔/车载安装结构、防水壳骨架和防震连接件","差异化开发判断":"优先：型号专用安装/防护件；不做装饰贴纸、通用线材和电池","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"HERO13/MAX接口、安装强度和防水结构"},
  {"热度排序":298,"热度层级":"A","品类":"无人机","品牌":"Autel Robotics","推荐型号或型号族":"EVO Lite+ / EVO Max 4T","整机常见价位美元":"约900-9000","国内用户信号":"道通智能中国出口品牌，精密机加工和电子供应链强","海外销售类型":"Amazon US、测绘和专业航拍渠道","美国站需求信号":"专业利基（美国站高客单、专业买家，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"云台保护架、起落架、遥控器支架、运输内架、快拆载荷安装结构和防震件","差异化开发判断":"优先：型号专用结构/载荷安装件；不做桨叶、装饰件和电池","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"EVO Lite/Max接口、载荷和合规责任"},
  {"热度排序":299,"热度层级":"S","品类":"发电机","品牌":"Generac","推荐型号或型号族":"GP6500 / GP8000E","整机常见价位美元":"约900-2200","国内用户信号":"吉耐发电机有中国钣金、发动机附件和结构件供应链","海外销售类型":"Amazon US、家用应急和户外电源渠道","美国站需求信号":"高潜候选（美国站应急发电机主流价位，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轮架、折叠手柄、控制面板支架、燃油箱护罩、消音器隔热结构和运输固定件","差异化开发判断":"优先：型号专用承载/隔热/安装件；不做燃油、机油、电池和通用电源适配器","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"发动机型号、轮架孔位、热防护和安全责任"},
  {"热度排序":300,"热度层级":"S","品类":"发电机","品牌":"Champion Power Equipment","推荐型号或型号族":"8750W Dual Fuel / 100302 Tri-Fuel","整机常见价位美元":"约800-1800","国内用户信号":"冠军品牌有中国制造、钣金和发动机配套供应链","海外销售类型":"Amazon US应急、房车和户外渠道常见","美国站需求信号":"高潜候选（美国站双燃料/三燃料主流系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轮架、手柄、控制面板支架、气瓶固定结构、消音器隔热罩和运输架","差异化开发判断":"优先：型号专用结构/安全件；不做燃料、机油、电池和通用电源件","配件售价潜力":"90-400","符合条件":"直接符合","主要核查点":"燃料接口、热防护、轮架和不同功率版本"},
  {"热度排序":301,"热度层级":"A","品类":"发电机","品牌":"Westinghouse","推荐型号或型号族":"WGen9500DF / WGen11500TFc","整机常见价位美元":"约1000-2500","国内用户信号":"西屋发电机有中国钣金、轮架和发动机配件供应链","海外销售类型":"Amazon US家用应急和房车市场","美国站需求信号":"高潜候选（美国站高功率应急系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轮架、折叠手柄、控制面板护罩、气瓶托架、消音器隔热和运输固定结构","差异化开发判断":"优先：型号专用承载/隔热件；不做燃油、机油、电池和通用线材","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"功率版本、燃料转换和高温防护"},
  {"热度排序":302,"热度层级":"A","品类":"发电机","品牌":"DuroMax","推荐型号或型号族":"XP13000EH / XP16000iH","整机常见价位美元":"约1300-3000","国内用户信号":"杜罗麦克斯有中国机加工、钣金和结构件供应链","海外销售类型":"Amazon US高功率双燃料和房车渠道","美国站需求信号":"专业利基（美国站高功率细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轮架、手柄、控制面板安装件、气瓶托架、消音器隔热结构和运输架","差异化开发判断":"优先：型号专用承载/隔热件；不做燃油、机油、电池和通用电源适配器","配件售价潜力":"120-500","符合条件":"直接符合","主要核查点":"功率、热防护、燃料接口和承重"},
  {"热度排序":303,"热度层级":"S","品类":"车库门开启器","品牌":"Chamberlain","推荐型号或型号族":"B6753T / B4613T","整机常见价位美元":"约250-700","国内用户信号":"张伯伦在中国有电机、齿轮箱和钣金配套供应链","海外销售类型":"Amazon US住宅车库门安装渠道强","美国站需求信号":"高潜候选（美国站车库门开启器主流品牌，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轨道吊装加强架、链条/皮带张紧结构、墙控安装底座、光电传感器支架和门臂连接件","差异化开发判断":"优先：型号专用承载/传动/安装件；不做装饰盖和通用电源适配器","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"轨道规格、门重、传感器位置和安全反转"},
  {"热度排序":304,"热度层级":"A","品类":"车库门开启器","品牌":"LiftMaster","推荐型号或型号族":"87504-267 / 84505R","整机常见价位美元":"约400-1000","国内用户信号":"LiftMaster有中国电机、齿轮和钣金供应链可配套","海外销售类型":"美国专业安装商和住宅车库渠道","美国站需求信号":"高潜候选（美国站专业车库门系统，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轨道吊装架、门臂连接件、控制箱安装结构、传感器支架和链条张紧组件","差异化开发判断":"优先：型号专用传动/安装件；不做装饰件、通用线材和电源适配器","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"商用/住宅版本、轨道接口和安全联锁"},
  {"热度排序":305,"热度层级":"A","品类":"车库门开启器","品牌":"Genie","推荐型号或型号族":"StealthDrive Connect 7155-TKV / MachForce 4063","整机常见价位美元":"约250-650","国内用户信号":"吉尼产品有中国电机、齿轮和结构件供应链","海外销售类型":"Amazon US住宅车库门市场","美国站需求信号":"美国站高潜候选（住宅安装量大，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"轨道吊装架、门臂连接件、墙控安装底座、传感器安装件和传动张紧结构","差异化开发判断":"优先：型号专用安装/传动件；不做装饰外壳和通用电源件","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"轨道和门臂尺寸、传感器对位与安全要求"},
  {"热度排序":306,"热度层级":"S","品类":"家庭健身","品牌":"Peloton","推荐型号或型号族":"Bike+ / Tread+","整机常见价位美元":"约1500-6000","国内用户信号":"Peloton有中国金属、塑胶和显示结构兼容供应链","海外销售类型":"美国订阅健身和家用设备市场强","美国站需求信号":"高潜候选（美国站高客单联网健身设备，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"屏幕臂安装结构、脚踏/曲柄护罩、跑带滚筒张紧座、平板支架和运输固定件","差异化开发判断":"优先：型号专用承载/调节件；不做装饰罩、耗材和电池","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"Bike与Tread结构差异、承重、运动安全和联网版本"},
  {"热度排序":307,"热度层级":"A","品类":"家庭健身","品牌":"NordicTrack","推荐型号或型号族":"Commercial 2450 / S22i","整机常见价位美元":"约1500-3000","国内用户信号":"诺迪克健身设备有中国金属、滚筒和结构件供应链","海外销售类型":"Amazon US和美国健身设备渠道","美国站需求信号":"美国站高潜候选（跑步机/单车主流高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"跑带滚筒和张紧座、屏幕臂、折叠锁止、扶手平板支架和运输轮结构","差异化开发判断":"优先：型号专用机械调节/承载件；不做装饰罩、跑带耗材和电池","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"跑步机/单车平台、承重和折叠安全"},
  {"热度排序":308,"热度层级":"A","品类":"家庭健身","品牌":"Bowflex","推荐型号或型号族":"Max Trainer M16 / Treadmill 22","整机常见价位美元":"约1500-3000","国内用户信号":"宝力豪有中国机架、阻力结构和塑胶配套供应链","海外销售类型":"美国健身器械和家庭训练渠道","美国站需求信号":"专业利基（美国站高客单器械，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"阻力臂连接结构、踏板承载件、屏幕臂、底座脚轮和运输固定架","差异化开发判断":"优先：型号专用承载/调节件；不做装饰件、耗材和电池","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"阻力机构、承重、运动安全和机型尺寸"},
  {"热度排序":309,"热度层级":"S","品类":"泳池设备","品牌":"Maytronics","推荐型号或型号族":"Dolphin Nautilus CC Supreme / M600","整机常见价位美元":"约700-1600","国内用户信号":"美卓特泳池机器人有中国电机、驱动和注塑配套供应链","海外销售类型":"Amazon US泳池机器人和专业泳池渠道","美国站需求信号":"高潜候选（美国站泳池机器人高客单系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"驱动轮/履带结构、浮线收纳架、过滤仓结构、上盖锁止、运输底座和电机防护件","差异化开发判断":"优先：型号专用驱动/结构件；不做滤袋等耗材、装饰件和电源适配器","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"水下密封、防水等级、驱动接口和过滤仓尺寸"},
  {"热度排序":310,"热度层级":"A","品类":"电动自行车","品牌":"Rad Power Bikes","推荐型号或型号族":"RadRover 6 Plus / RadCity 5 Plus","整机常见价位美元":"约1500-2500","国内用户信号":"Rad车型在中国有车架、货架和结构件兼容供应链","海外销售类型":"美国电动自行车直营和维修渠道","美国站需求信号":"高潜候选（美国站城市/胖胎电助力主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"货架承载件、车把/显示器安装座、脚撑加强件、泥瓦支架、折叠运输架和车架连接件","差异化开发判断":"优先：车型专用承载/安装件；不做电池、电源适配器、灯珠和装饰件","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"车架接口、承重、刹车安全和美国法规"},
  {"热度排序":311,"热度层级":"A","品类":"电动自行车","品牌":"Lectric","推荐型号或型号族":"XP 3.0 / XPremium","整机常见价位美元":"约1000-1800","国内用户信号":"莱特里克车型有中国车架、货架和折叠结构供应链","海外销售类型":"美国直销和电助力车渠道","美国站需求信号":"高潜候选（美国站折叠电助力热卖价位，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"折叠锁止结构、货架、车把安装座、脚撑加强件、泥瓦支架和运输固定件","差异化开发判断":"优先：车型专用折叠/承载件；不做电池、充电器和装饰件","配件售价潜力":"70-300","符合条件":"直接符合","主要核查点":"折叠节点、车架承重、线缆走向和刹车安全"},
  {"热度排序":312,"热度层级":"A","品类":"电动自行车","品牌":"Aventon","推荐型号或型号族":"Level.2 / Aventure.2","整机常见价位美元":"约1500-2500","国内用户信号":"Aventon有中国车架、货架和机械件兼容供应链","海外销售类型":"美国电助力车直营和经销渠道","美国站需求信号":"美国站高潜候选（城市/胖胎细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"货架承载件、车把/显示器支架、脚撑加强、泥瓦结构、车架保护和运输固定件","差异化开发判断":"优先：车型专用承载/安装件；不做电池、充电器和装饰件","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"车架孔位、承重、刹车和美国道路合规"},
  {"热度排序":313,"热度层级":"S","品类":"智能门锁","品牌":"Schlage","推荐型号或型号族":"Encode Plus / Connect BE489","整机常见价位美元":"约250-500","国内用户信号":"史莱奇锁体、齿轮和面板有中国精密加工配套供应链","海外销售类型":"Amazon US住宅智能门锁主流","美国站需求信号":"高潜候选（美国站智能门锁高价主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"锁体齿轮组件、内外面板安装框、门厚调节结构、键盘模块载架和防撬加强件","差异化开发判断":"优先：型号专用锁体/安装件；不做装饰面板、普通螺丝包和电池","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"ANSI锁体等级、门厚、指纹/联网版本和安全责任"},
  {"热度排序":314,"热度层级":"A","品类":"智能门锁","品牌":"Yale","推荐型号或型号族":"Assure Lock 2 / Assure Lever","整机常见价位美元":"约250-600","国内用户信号":"耶鲁锁具在中国有锁体、齿轮和电子结构供应链","海外销售类型":"Amazon US和住宅安防安装渠道","美国站需求信号":"美国站高潜候选（住宅智能锁主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"锁体/方舌组件、内面板安装框、门厚调节结构、模块仓载架和防撬加强件","差异化开发判断":"优先：型号专用锁体/安装件；不做装饰面板、普通紧固件和电池","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"Assure模块版本、门厚、锁体规格和安全责任"},
  {"热度排序":315,"热度层级":"A","品类":"标签打印机","品牌":"Rollo","推荐型号或型号族":"Wireless Printer / X1040","整机常见价位美元":"约250-500","国内用户信号":"Rollo标签机有中国打印机结构、滚轮和电控供应链","海外销售类型":"Amazon US电商卖家和物流标签渠道常见","美国站需求信号":"高潜候选（美国站电商标签打印主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、滚轮组件、打印机机架、桌面安装座和理线结构","差异化开发判断":"优先：型号专用纸路/安装件；不做标签耗材、打印头和通用线材","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"纸路宽度、无线版本、剥离结构和打印头寿命"},
  {"热度排序":316,"热度层级":"A","品类":"标签打印机","品牌":"MUNBYN","推荐型号或型号族":"ITPP941 / P941","整机常见价位美元":"约220-450","国内用户信号":"MUNBYN有中国打印机整机和结构件制造供应链","海外销售类型":"Amazon US电商卖家、仓储和热敏打印渠道","美国站需求信号":"美国站高潜候选（中小卖家标签设备，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"卷纸架、剥离器、滚轮组件、桌面支架、机架和线缆固定结构","差异化开发判断":"优先：型号专用纸路/安装件；不做标签耗材、打印头和通用线材","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"纸路、驱动兼容、接口和打印头耗材排除"},
  {"热度排序":317,"热度层级":"S","品类":"咖啡机","品牌":"Gaggia","推荐型号或型号族":"Classic Pro / Anima Prestige","整机常见价位美元":"约500-1800","国内用户信号":"加吉亚有中国泵、阀、金属件和兼容维修供应链","海外销售类型":"Amazon US家庭咖啡和咖啡发烧友渠道","美国站需求信号":"高潜候选（美国站半自动/全自动咖啡机主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"冲煮器锁止与导轨、磨豆机齿轮箱壳体、泵/阀安装支架、滴水盘结构和侧板维修件","差异化开发判断":"优先：型号专用机械/维修件；不做咖啡豆、清洁片、装饰件和通用电源线","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"Classic与Anima结构差异、食品接触材料和电气安全"},
  {"热度排序":318,"热度层级":"S","品类":"咖啡机","品牌":"Jura","推荐型号或型号族":"E8 / Z10","整机常见价位美元":"约1500-4000","国内用户信号":"优瑞有中国精密塑胶、泵阀和兼容维修件供应链","海外销售类型":"Amazon US和高端家用咖啡渠道","美国站需求信号":"高潜候选（美国站高端全自动咖啡机，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"冲煮器导轨/锁止、磨豆机安装结构、泵阀支架、托盘结构和维修面板","差异化开发判断":"优先：型号专用机械/维修件；不做咖啡豆、清洁耗材、装饰件和通用电源线","配件售价潜力":"120-600","符合条件":"直接符合","主要核查点":"E8/Z10机型接口、食品接触、压力和电气安全"},
  {"热度排序":319,"热度层级":"A","品类":"NAS","品牌":"Asustor","推荐型号或型号族":"Lockerstor 4 Gen2 / Flashstor 12 Pro","整机常见价位美元":"约500-1800","国内用户信号":"华芸NAS有中国机箱、背板、风道和存储配件供应链","海外销售类型":"Amazon US家庭服务器和创客渠道","美国站需求信号":"专业利基（美国站高客单NAS、卖家相对少，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"硬盘托架、机架托盘、风扇风道、PCIe扩展固定件、背板承载结构和防震底座","差异化开发判断":"优先：型号专用存储/散热/机架件；不做硬盘、内存和通用电源适配器","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"盘位尺寸、背板接口、散热和机架兼容"},
  {"热度排序":320,"热度层级":"S","品类":"网络设备","品牌":"ASUS","推荐型号或型号族":"ROG Rapture GT-BE98 / ZenWiFi Pro ET12","整机常见价位美元":"约400-900","国内用户信号":"华硕网络设备有中国制造、机箱和散热供应链","海外销售类型":"Amazon US Wi-Fi 6E/7高端路由市场","美国站需求信号":"高潜候选（美国站高端Wi-Fi 7主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"壁装/机架托盘、散热风道、天线保护结构、理线底座和防倾倒支架","差异化开发判断":"优先：型号专用散热/安装件；不做装饰外壳、通用线材和电源适配器","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"天线布局、散热、壁装孔位和Wi-Fi版本"},
  {"热度排序":321,"热度层级":"S","品类":"网络设备","品牌":"NETGEAR","推荐型号或型号族":"Nighthawk RS700S / Orbi 970","整机常见价位美元":"约500-1800","国内用户信号":"网件路由有中国机箱、散热和结构件兼容供应链","海外销售类型":"Amazon US高端路由和Mesh渠道","美国站需求信号":"高潜候选（美国站Wi-Fi 7高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"壁装/机架托盘、散热风道、天线保护结构、理线和防倾倒安装件","差异化开发判断":"优先：型号专用安装/散热件；不做装饰件、通用线材和电源适配器","配件售价潜力":"60-300","符合条件":"直接符合","主要核查点":"天线和进风口、壁装孔位、Mesh节点版本"},
  {"热度排序":322,"热度层级":"A","品类":"空气净化器","品牌":"Winix","推荐型号或型号族":"XLC / 9800","整机常见价位美元":"约180-450","国内用户信号":"维尼克斯空气处理有中国风机、传感器和注塑供应链","海外销售类型":"Amazon US家庭空气质量渠道常见","美国站需求信号":"美国站高潜候选（家庭空气净化高价系列，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"风机座、上盖锁止、传感器仓、墙装结构、防倾倒底座和机身维修件","差异化开发判断":"优先：型号专用风道/传感器/安装件；不做滤芯耗材、装饰件和通用电源线","配件售价潜力":"60-250","符合条件":"直接符合","主要核查点":"滤芯耗材排除、传感器位置、风道和机型版本"},
  {"热度排序":323,"热度层级":"A","品类":"空气净化器","品牌":"Medify Air","推荐型号或型号族":"MA-112-UV / MA-125","整机常见价位美元":"约220-500","国内用户信号":"Medify Air有中国风机、钣金和传感器配套供应链","海外销售类型":"Amazon US大空间空气净化渠道","美国站需求信号":"美国站高潜候选（大空间空气净化细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"风机座、传感器仓、上盖锁止、壁装/落地底座和防倾倒结构","差异化开发判断":"优先：型号专用风道/安装件；不做滤芯耗材、装饰件和通用电源线","配件售价潜力":"60-260","符合条件":"直接符合","主要核查点":"滤芯耗材排除、风道尺寸和传感器接口"},
  {"热度排序":324,"热度层级":"S","品类":"分体空调","品牌":"MRCOOL","推荐型号或型号族":"DIY 4th Gen 36K / Olympus 36K","整机常见价位美元":"约1800-4500","国内用户信号":"MRCOOL分体机有中国压缩机、钣金和安装件供应链","海外销售类型":"Amazon US DIY空调和承包商渠道","美国站需求信号":"高潜候选（美国站DIY分体空调主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"室外机底座、线组/管路固定结构、冷凝水排放支架、墙穿护套和防震安装件","差异化开发判断":"优先：型号专用安装/排水/防震件；不做冷媒、压缩机核心件、装饰件和电源适配器","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"冷媒类型、管径、支架承重和安装认证"},
  {"热度排序":325,"热度层级":"A","品类":"分体空调","品牌":"Pioneer","推荐型号或型号族":"Diamante 36K / Quantum 36K","整机常见价位美元":"约1600-4000","国内用户信号":"先锋空调有中国压缩机、钣金和管路配套供应链","海外销售类型":"Amazon US DIY和小型商业空调渠道","美国站需求信号":"专业利基（美国站DIY安装细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"室外机底座、管路固定、冷凝水排放、墙穿护套和防震结构","差异化开发判断":"优先：型号专用安装/排水件；不做冷媒、压缩机核心件、装饰件和电源适配器","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"管径、冷媒、支架承重和地区认证"},
  {"热度排序":326,"热度层级":"A","品类":"分体空调","品牌":"Senville","推荐型号或型号族":"LETO 36K / Aura 36K","整机常见价位美元":"约1500-3800","国内用户信号":"森威尔有中国空调整机和安装件供应链","海外销售类型":"Amazon US DIY分体空调渠道","美国站需求信号":"美国站高潜候选（DIY分体空调细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"室外机底座、管线固定、排水支架、墙穿护套和防震安装件","差异化开发判断":"优先：型号专用安装/排水件；不做冷媒、压缩机核心件、装饰件和电源适配器","配件售价潜力":"90-450","符合条件":"直接符合","主要核查点":"管径、冷媒、安装承重和认证"},
  {"热度排序":327,"热度层级":"A","品类":"颗粒炉/壁炉","品牌":"Harman","推荐型号或型号族":"Absolute43 / P43","整机常见价位美元":"约3500-7000","国内用户信号":"哈曼壁炉有中国钣金、风道和控制结构兼容供应链","海外销售类型":"美国东北部和寒冷地区壁炉渠道","美国站需求信号":"专业利基（美国站冬季高客单设备，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"料斗盖、螺旋输送护罩、检修门、风道护板、脚轮底座和隔热结构","差异化开发判断":"优先：型号专用耐热/检修结构；不做燃料颗粒、密封耗材和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"耐热材料、排烟安全、机型尺寸和责任风险"},
  {"热度排序":328,"热度层级":"A","品类":"颗粒炉/壁炉","品牌":"Englander","推荐型号或型号族":"25-PDVC / 30-NC","整机常见价位美元":"约1800-4000","国内用户信号":"英格兰德壁炉有中国钣金、风道和耐热结构供应链","海外销售类型":"Amazon US和美国冬季采暖渠道","美国站需求信号":"美国站高潜候选（家用采暖设备，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"料斗盖、螺旋输送护罩、检修门、风道护板、底座和隔热安装件","差异化开发判断":"优先：型号专用耐热/检修结构；不做燃料颗粒、密封耗材和装饰件","配件售价潜力":"90-450","符合条件":"直接符合","主要核查点":"排烟、耐热、防火间距和机型接口"},
  {"热度排序":329,"热度层级":"A","品类":"颗粒炉/壁炉","品牌":"ComfortBilt","推荐型号或型号族":"HP22N / HP61","整机常见价位美元":"约1800-4000","国内用户信号":"康福特比尔特有中国钣金、风道和耐热件配套供应链","海外销售类型":"Amazon US家用颗粒炉渠道","美国站需求信号":"专业利基（美国站冬季采暖细分，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"料斗盖、检修门、风道护板、隔热结构、脚轮底座和控制面板安装件","差异化开发判断":"优先：型号专用耐热/检修件；不做燃料颗粒、密封耗材和装饰件","配件售价潜力":"90-450","符合条件":"直接符合","主要核查点":"耐热、排烟、防火间距和型号接口"},
  {"热度排序":330,"热度层级":"S","品类":"除雪机","品牌":"Cub Cadet","推荐型号或型号族":"2X 30 IntelliPower / 3X 30 TRAC","整机常见价位美元":"约1400-3500","国内用户信号":"小型骑士有中国园林机械、钣金和轮架供应链","海外销售类型":"Amazon US、Home Depot和北美庭院设备渠道","美国站需求信号":"高潜候选（美国站双级/三级除雪主流，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"导流槽总成、把手与轮架、操控拉线固定、护罩、运输架和收纳结构","差异化开发判断":"优先：型号专用导流/承载/调节件；不做刮板、皮带等耗材和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"导流槽、传动、低温材料和机型接口"},
  {"热度排序":331,"热度层级":"A","品类":"除雪机","品牌":"Troy-Bilt","推荐型号或型号族":"Storm 3090 / Storm 3024","整机常见价位美元":"约1000-2800","国内用户信号":"特洛伊比尔特有中国园林机械和钣金配套供应链","海外销售类型":"Amazon US、庭院设备和冬季维护渠道","美国站需求信号":"美国站高潜候选（家用除雪机主流价位，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"导流槽、把手/轮架、操控线固定、护罩、运输架和收纳结构","差异化开发判断":"优先：型号专用导流/承载件；不做刮板、皮带等耗材和装饰件","配件售价潜力":"90-400","符合条件":"直接符合","主要核查点":"导流槽、低温材料、传动和机型接口"},
  {"热度排序":332,"热度层级":"S","品类":"高压清洗机","品牌":"Simpson","推荐型号或型号族":"ALH4240 / PS4240","整机常见价位美元":"约700-1500","国内用户信号":"辛普森清洗设备有中国泵架、车架和钣金供应链","海外销售类型":"Amazon US家用/专业清洗设备渠道","美国站需求信号":"高潜候选（美国站高压清洗主流价位，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"推车车架、软管卷盘支架、喷枪挂架、泵体护罩、轮架和运输固定件","差异化开发判断":"优先：型号专用承载/收纳/防护件；不做喷嘴耗材、清洁液和通用电源件","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"泵压、软管接口、承重和安全防护"},
  {"热度排序":333,"热度层级":"A","品类":"焊机","品牌":"Miller Electric","推荐型号或型号族":"Multimatic 220 AC/DC / Trailblazer 330","整机常见价位美元":"约1800-6000","国内用户信号":"米勒电气有中国机箱、推车和焊接附件供应链","海外销售类型":"Amazon US专业焊接和维修渠道","美国站需求信号":"专业利基（美国站高客单专业设备，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"焊机推车、脚踏控制器外壳、送丝机安装座、线缆应力固定、散热护罩和机架","差异化开发判断":"优先：型号专用承载/控制/散热件；不做焊丝、焊条、喷嘴耗材和通用电源线","配件售价潜力":"120-600","符合条件":"直接符合","主要核查点":"焊接安全、电流等级、接口和绝缘认证"},
  {"热度排序":334,"热度层级":"A","品类":"焊机","品牌":"Lincoln Electric","推荐型号或型号族":"Power MIG 210 MP / Ranger 330MPX","整机常见价位美元":"约1000-5000","国内用户信号":"林肯电气有中国机箱、推车和焊接附件供应链","海外销售类型":"Amazon US专业焊接、车库和工程渠道","美国站需求信号":"美国站高潜候选（专业焊机高客单，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"焊机推车、送丝机安装座、脚踏控制器外壳、线缆固定、散热护罩和运输架","差异化开发判断":"优先：型号专用承载/控制/散热件；不做焊丝、焊条、喷嘴耗材和通用电源线","配件售价潜力":"100-550","符合条件":"直接符合","主要核查点":"电流等级、焊接安全、接口和绝缘认证"},
  {"热度排序":335,"热度层级":"A","品类":"焊机","品牌":"ESAB","推荐型号或型号族":"Rebel EMP 215ic / Sentinel A60","整机常见价位美元":"约800-3000","国内用户信号":"伊萨有中国机箱、焊接附件和结构件供应链","海外销售类型":"Amazon US专业焊接和工业渠道","美国站需求信号":"专业利基（美国站多功能焊机，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"焊机推车、送丝机安装座、控制面板护罩、线缆固定、散热护罩和运输结构","差异化开发判断":"优先：型号专用承载/控制/散热件；不做焊材耗材、喷嘴和通用电源线","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"电流等级、绝缘、接口和焊接安全"},
  {"热度排序":336,"热度层级":"S","品类":"家庭机器人","品牌":"Loona","推荐型号或型号族":"Loona Smart Robot","整机常见价位美元":"约450-650","国内用户信号":"KEYi Tech中国机器人出口品牌，国内电机、结构和注塑供应链成熟","海外销售类型":"Amazon US、Kickstarter/Indiegogo和家庭机器人渠道","美国站需求信号":"候选待实核（美国站高客单桌面家庭机器人）","美国站证据等级":"未实核：Amazon US当前无法读取页面/BSR/配件销量","适合开发的高客单非耗材替换升级改装件":"充电底座定位结构、轮组/转向功能件、云台摄像头保护架、底盘防撞结构、宠物互动配件安装座和运输内架","差异化开发判断":"仅在确认整机销量与配件需求后开发；不做装饰外壳、贴纸、通用线材和电池","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"Loona版本、底盘接口、充电触点、摄像头活动范围和隐私合规"},
  {"热度排序":337,"热度层级":"S","品类":"咖啡机","品牌":"Breville","推荐型号或型号族":"Barista Express / Barista Pro / Dual Boiler","整机常见价位美元":"约700-2500","国内用户信号":"铂富在中国有泵、阀、金属件和兼容维修供应链","海外销售类型":"Amazon US、专业咖啡渠道和家用咖啡发烧友市场","美国站需求信号":"重点候选（美国站主流高客单咖啡机，必须实查BSR和配件销量）","美国站证据等级":"待实核：Amazon US当前无法读取页面/BSR/配件销量；仅按市场认知列为校准样本","适合开发的高客单非耗材替换升级改装件":"冲煮头锁止/导轨、磨豆机齿轮箱维修结构、泵阀安装支架、滴水盘结构、侧板维修件和无底手柄功能件","差异化开发判断":"优先核验型号专用维修/功能件；不做咖啡豆、清洁片、装饰件、通用电源线","配件售价潜力":"100-600","符合条件":"直接符合","主要核查点":"Barista Express/Pro/Dual Boiler代际、食品接触材料、压力和电气安全"},
  {"热度排序":338,"热度层级":"S","品类":"纹身机","品牌":"Cheyenne","推荐型号或型号族":"Hawk Pen Unio / Sol Nova Unlimited","整机常见价位美元":"约500-1200","国内用户信号":"美国纹身工作室常见，中国有精密铝件、握柄和支架供应链","海外销售类型":"美国专业纹身渠道和工作室市场","美国站需求信号":"高潜候选（高端笔式机，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"可调握柄、消毒托架、工作台固定座、针仓防护结构和运输盒内架","差异化开发判断":"优先型号专用握柄/固定/防护功能件；不做针具、墨水、电池和装饰件","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"握柄直径、行程调节、灭菌材料和电气安全"},
  {"热度排序":339,"热度层级":"S","品类":"纹身机","品牌":"FK Irons","推荐型号或型号族":"Flux Max / EXO","整机常见价位美元":"约500-1000","国内用户信号":"美国纹身工作室常见，中国有CNC握柄、支架和包装结构供应链","海外销售类型":"美国专业纹身渠道和工作室","美国站需求信号":"专业利基（高端无线纹身机，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"模块化握柄、工作台定位座、机器收纳架、消毒托盘和防跌落保护架","差异化开发判断":"优先功能结构件；不做针具、墨水、充电器、电池和贴纸","配件售价潜力":"80-320","符合条件":"直接符合","主要核查点":"Flux/EXO接口、握柄锁止、消毒和无线版本"},
  {"热度排序":340,"热度层级":"A","品类":"纹身机","品牌":"Bishop","推荐型号或型号族":"Power Wand / Wand Packer","整机常见价位美元":"约500-900","国内用户信号":"美国纹身师常用品牌，中国有金属握柄和机加工兼容供应链","海外销售类型":"美国专业纹身器材渠道","美国站需求信号":"专业利基（高端机型，需实查）","适合开发的高客单非耗材替换升级改装件":"握柄调节环、机器支架、消毒托盘、工作台夹具和运输内架","差异化开发判断":"优先型号专用机械件；不做针具、墨水、电源和电池","配件售价潜力":"80-300","符合条件":"直接符合","主要核查点":"握柄尺寸、行程、灭菌和材料兼容"},
  {"热度排序":341,"热度层级":"S","品类":"纹身机","品牌":"Dragonhawk","推荐型号或型号族":"Mast Tour Y22 / Mast Archer","整机常见价位美元":"约200-450","国内用户信号":"中国出口纹身品牌，跨境销量和配件模具供应链明确","海外销售类型":"Amazon US、纹身电商和工作室渠道","美国站需求信号":"高潜候选（中国出口品牌，需核实具体ASIN）","适合开发的高客单非耗材替换升级改装件":"可调握柄、机器收纳架、消毒托盘、夹具和防跌落支架","差异化开发判断":"优先结构/安装件；不做针具、墨水、充电器、电池和装饰件","配件售价潜力":"60-220","符合条件":"直接符合","主要核查点":"Mast系列接口、握柄锁止和无线版本"},
  {"热度排序":342,"热度层级":"S","品类":"老年代步车","品牌":"Pride Mobility","推荐型号或型号族":"Go-Go Elite Traveller / Victory 10 LX","整机常见价位美元":"约900-3000","国内用户信号":"美国保有量大，中国有车架、座椅、护罩和轮毂兼容供应链","海外销售类型":"美国医疗器械、经销商和家庭护理渠道","美国站需求信号":"高潜候选（美国常见mobility scooter品牌，需实查BSR）","适合开发的高客单非耗材替换升级改装件":"座椅滑轨、扶手支架、拆装结构、后视镜支架、车篮承载架和防倾倒轮架","差异化开发判断":"优先承载/拆装/安全功能件；不做电池、充电器、轮胎耗材和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"车架孔位、承重、制动和医疗器械责任"},
  {"热度排序":343,"热度层级":"S","品类":"老年代步车","品牌":"Drive Medical","推荐型号或型号族":"Scout Compact Travel Scooter / Phoenix HD 4","整机常见价位美元":"约700-1800","国内用户信号":"美国医疗渠道覆盖广，中国兼容车架、座椅和护罩供应链强","海外销售类型":"美国医疗器械、Amazon和家庭护理渠道","美国站需求信号":"高潜候选（美国常见旅行代步车，需实查）","适合开发的高客单非耗材替换升级改装件":"座椅旋转底座、扶手/车篮支架、拆装锁止、后视镜和防倾倒结构","差异化开发判断":"优先型号专用承载/安全件；不做电池、充电器、轮胎和装饰件","配件售价潜力":"90-400","符合条件":"直接符合","主要核查点":"Scout/Phoenix接口、承重、制动和折叠结构"},
  {"热度排序":344,"热度层级":"A","品类":"老年代步车","品牌":"Golden Technologies","推荐型号或型号族":"Buzzaround XL / LiteRider Envy","整机常见价位美元":"约900-2200","国内用户信号":"美国老年护理渠道常见，中国有车架、座椅和护罩兼容加工","海外销售类型":"美国医疗经销商和家庭护理市场","美国站需求信号":"专业利基（医疗代步车高客单，需实查）","适合开发的高客单非耗材替换升级改装件":"座椅滑轨、扶手、车篮支架、拆装快锁、后视镜和运输固定件","差异化开发判断":"优先安全/承载/运输功能件；不做电池、充电器、轮胎和装饰件","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"XL/Envy版本、承重、座椅孔位和制动"},
  {"热度排序":345,"热度层级":"A","品类":"电动轮椅","品牌":"Shoprider","推荐型号或型号族":"Streamer Sport / Sprinter DLX","整机常见价位美元":"约1200-3500","国内用户信号":"美国康复设备渠道常见，中国有铝合金车架、扶手和脚踏兼容供应链","海外销售类型":"美国医疗器械和康复渠道","美国站需求信号":"专业利基（电动轮椅细分，需实查）","适合开发的高客单非耗材替换升级件":"脚踏支架、扶手调节座、座椅滑轨、控制器安装架、折叠锁止和运输固定件","差异化开发判断":"优先承载/调节/运输件；不做电池、充电器、轮胎和装饰件","配件售价潜力":"120-550","符合条件":"直接符合","主要核查点":"座椅宽度、承重、控制器接口和折叠安全"},
  {"热度排序":346,"热度层级":"A","品类":"老年代步车","品牌":"EV Rider","推荐型号或型号族":"Transport AF+ / CityRider","整机常见价位美元":"约900-2500","国内用户信号":"美国折叠代步车渠道常见，中国有折叠车架和座椅结构供应链","海外销售类型":"美国旅行、房车和家庭护理渠道","美国站需求信号":"高潜候选（折叠旅行代步车，需实查）","适合开发的高客单非耗材替换升级件":"折叠锁止、座椅底座、车篮/行李架、后视镜和运输固定件","差异化开发判断":"优先折叠/承载/运输件；不做电池、充电器、轮胎和装饰件","配件售价潜力":"100-450","符合条件":"直接符合","主要核查点":"折叠机构、承重、座椅和运输尺寸"},
  {"热度排序":347,"热度层级":"S","品类":"热泵/分体空调","品牌":"Mitsubishi Electric","推荐型号或型号族":"Hyper-Heat MXZ / MSZ-FS","整机常见价位美元":"约1800-6000","国内用户信号":"美国寒冷地区安装量大，中国有支架、风道和排水结构供应链","海外销售类型":"美国承包商和DIY空调渠道","美国站需求信号":"高潜候选（美国高端热泵常用品牌，需实查）","适合开发的高客单非耗材替换升级件":"室外机底座、防震垫座、管路护套、冷凝水排放和墙穿结构","差异化开发判断":"优先安装/排水/防震件；不做冷媒、压缩机和电源件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"冷媒、管径、支架承重和安装认证"},
  {"热度排序":348,"热度层级":"S","品类":"商用制冰机","品牌":"Scotsman","推荐型号或型号族":"CU50 / Prodigy C0830","整机常见价位美元":"约1800-7000","国内用户信号":"餐饮和酒吧渠道保有量高，中国有钣金、料斗和风道供应链","海外销售类型":"美国餐饮设备和酒店渠道","美国站需求信号":"专业利基（商用制冰机维修需求稳定，需实查）","适合开发的高客单非耗材替换升级件":"料斗门、机架、散热风道、排水结构和维修面板","差异化开发判断":"优先结构/检修件；不做滤水芯、清洁剂和制冷核心件","配件售价潜力":"120-600","符合条件":"直接符合","主要核查点":"冰型、排水、食品接触和机型接口"},
  {"热度排序":349,"热度层级":"S","品类":"商用制冰机","品牌":"Manitowoc Ice","推荐型号或型号族":"UDF0140 / Indigo NXT","整机常见价位美元":"约2500-9000","国内用户信号":"美国餐饮连锁常见，中国有机架、门组件和风道配套","海外销售类型":"美国餐饮、酒店和便利店设备渠道","美国站需求信号":"专业利基（高价商用制冰设备，需实查）","适合开发的高客单非耗材替换升级件":"料斗门、机架、排水转接、散热护罩和检修面板","差异化开发判断":"优先型号专用结构件；不做水滤芯、清洁剂和制冷核心件","配件售价潜力":"150-700","符合条件":"直接符合","主要核查点":"机型代际、冰型、排水和食品安全"},
  {"热度排序":350,"热度层级":"S","品类":"激光雕刻机","品牌":"xTool","推荐型号或型号族":"P2S / S1 40W","整机常见价位美元":"约700-5000","国内用户信号":"中国出口品牌，创客和小型工坊用户多，结构件供应链强","海外销售类型":"Amazon US、独立站和创客渠道","美国站需求信号":"高潜候选（美国桌面激光设备常见品牌，需实查）","适合开发的高客单非耗材替换升级件":"蜂窝工作台、排烟接口、门锁/联锁结构、旋转轴安装座和机架","差异化开发判断":"优先安全联锁/排烟/承载件；不做激光管、镜片耗材和装饰件","配件售价潜力":"80-500","符合条件":"直接符合","主要核查点":"激光等级、联锁、排烟和机型尺寸"},
  {"热度排序":351,"热度层级":"A","品类":"激光雕刻机","品牌":"Glowforge","推荐型号或型号族":"Pro / Performance","整机常见价位美元":"约1000-7000","国内用户信号":"美国创客和教育用户多，中国有排烟、机架和结构件兼容加工","海外销售类型":"美国创客、教育和小企业渠道","美国站需求信号":"专业利基（高客单桌面激光机，需实查）","适合开发的高客单非耗材替换升级件":"排烟转接、工作台、门锁联锁、机架和运输固定件","差异化开发判断":"优先结构/安全升级件；不做镜片、激光管和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"型号尺寸、联锁、排烟和材料防火"},
  {"热度排序":352,"热度层级":"S","品类":"工业缝纫机","品牌":"Juki","推荐型号或型号族":"DDL-8700 / MO-6700","整机常见价位美元":"约700-2500","国内用户信号":"美国服装和改衣店常见，中国有机头、台板和脚架配套供应链","海外销售类型":"美国专业缝纫和工坊渠道","美国站需求信号":"专业利基（耐用工业机保有量高，需实查）","适合开发的高客单非耗材替换升级件":"台板脚架、膝控支架、皮带护罩、压脚机构和线架","差异化开发判断":"优先承载/传动/安装功能件；不做机针、线和通用电机","配件售价潜力":"80-350","符合条件":"直接符合","主要核查点":"机头安装、皮带规格、台板孔位和安全"}
  ,{"热度排序":353,"热度层级":"A","品类":"无人机","品牌":"Antigravity","推荐型号或型号族":"A1 / A1 Fly More Combo","整机常见价位美元":"约800-1800","国内用户信号":"影石创新旗下中国出口品牌，国内航拍与全景影像供应链强","海外销售类型":"Amazon US、Insta360渠道和沉浸式影像市场","美国站需求信号":"新品牌观察（影石体系和高客单定位，需核实Amazon US销量/BSR）","美国站证据等级":"待核：新品牌，需按具体ASIN复核","适合开发的高客单非耗材替换升级件":"飞控板、全景相机模组、图传板、云台/镜头机构、无刷电机、电调、视觉定位板、机臂和机身结构件","差异化开发判断":"优先型号专用相机/飞控/结构功能件；不做电池、桨叶、充电器和装饰件","配件售价潜力":"100-500","符合条件":"观察池","主要核查点":"具体型号上市状态、Amazon US销量、全景相机接口、飞控和法规责任"}
  ,{"热度排序":354,"热度层级":"A","品类":"无人机","品牌":"Antigravity","推荐型号或型号族":"A1 Pro / 全景航拍系列","整机常见价位美元":"约1000-2200","国内用户信号":"中国影像品牌新无人机方向，结构和电子供应链可配套","海外销售类型":"Insta360生态、专业影像和户外航拍渠道","美国站需求信号":"新品牌观察（待验证，不等同于热卖）","美国站证据等级":"待核：需确认正式型号、ASIN和第三方维修/拆机供给","适合开发的高客单非耗材替换升级件":"相机/图传主板、镜头保护结构、机臂、电机座、起落架、遥控器主板和运输内架","差异化开发判断":"仅在型号和销量确认后开发；不做电池、桨叶、充电器和装饰件","配件售价潜力":"100-550","符合条件":"观察池","主要核查点":"正式型号命名、上市地区、飞行法规、相机模组和拆机来源"}
  ,{"热度排序":355,"热度层级":"S","品类":"高性能遥控车","品牌":"Traxxas","推荐型号或型号族":"X-Maxx 8S / Maxx / TRX-4","整机常见价位美元":"约450-1100","国内用户信号":"美国高保有量RC品牌，中国金属加工、齿轮、悬挂和电子兼容供应链成熟","海外销售类型":"Amazon US、RC专业店和改装渠道","美国站需求信号":"高潜候选（美国高性能遥控车主流品牌，需按具体ASIN核验）","美国站证据等级":"待核：需按具体型号复核销量和拆机供给","适合开发的高客单非耗材替换升级件":"ESC电子调速器、接收器、无刷电机、舵机、中央/前后差速器、变速箱齿轮、传动轴、悬挂臂、金属底盘和避震塔","差异化开发判断":"优先型号专用传动、控制和悬挂总成；不做电池、充电器、轮胎耗材和装饰壳","配件售价潜力":"80-450","符合条件":"直接符合","主要核查点":"8S/Maxx/TRX-4代际、接口、齿轮比、ESC和防水等级"}
  ,{"热度排序":356,"热度层级":"S","品类":"高性能遥控车","品牌":"ARRMA","推荐型号或型号族":"Kraton 6S / Outcast 4S / Mojave 6S","整机常见价位美元":"约350-900","国内用户信号":"美国高性能RC保有量大，中国有底盘、齿轮、差速器和电控兼容供应链","海外销售类型":"Amazon US、Horizon Hobby和RC改装市场","美国站需求信号":"高潜候选（高性能越野/短卡系列，需按ASIN核验）","美国站证据等级":"待核：需验证具体Amazon US型号销量","适合开发的高客单非耗材替换升级件":"ESC、无刷电机、舵机、差速器、齿轮箱、传动轴、CVD、悬挂臂、避震塔和车架结构件","差异化开发判断":"优先传动/控制/悬挂件；不做电池、充电器、轮胎和贴花","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"Kraton/Outcast/Mojave版本、6S/4S接口、齿轮和底盘孔位"}
  ,{"热度排序":357,"热度层级":"A","品类":"攀爬遥控车","品牌":"Axial","推荐型号或型号族":"SCX10 III / UMG10 / UT4","整机常见价位美元":"约350-800","国内用户信号":"美国攀爬RC保有量高，中国有车桥、齿轮、车架和金属改装件供应链","海外销售类型":"Amazon US、RC专业店和户外模型渠道","美国站需求信号":"高潜候选（SCX系列维修改装生态成熟，需按ASIN核验）","美国站证据等级":"待核：需按具体版本核验销量","适合开发的高客单非耗材替换升级件":"车桥壳体、差速器、变速箱、传动轴、舵机支架、金属底盘、避震塔、保险杠和防滚架","差异化开发判断":"优先车桥/传动/承载结构件；不做电池、轮胎、灯饰和装饰壳","配件售价潜力":"70-380","符合条件":"直接符合","主要核查点":"SCX10代际、轴距、车桥接口、变速箱和承重"}
  ,{"热度排序":358,"热度层级":"A","品类":"高性能遥控车","品牌":"Losi","推荐型号或型号族":"Super Baja Rey 2.0 / 8IGHT-XE","整机常见价位美元":"约500-1200","国内用户信号":"美国专业RC品牌，中国有金属底盘、齿轮和悬挂加工供应链","海外销售类型":"美国RC专业店、竞赛和越野渠道","美国站需求信号":"专业利基（高客单竞赛/越野车型，需按ASIN核验）","美国站证据等级":"待核：需验证具体型号销量","适合开发的高客单非耗材替换升级件":"ESC、无刷电机、差速器、齿轮箱、传动轴、悬挂臂、避震塔、底盘和防滚架","差异化开发判断":"优先型号专用传动和底盘件；不做电池、充电器、轮胎和外观件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"Super Baja Rey/8IGHT版本、竞赛规格、底盘孔位和齿轮"}
  ,{"热度排序":359,"热度层级":"A","品类":"高性能遥控车","品牌":"Redcat Racing","推荐型号或型号族":"Gen 8 V2 / Kaiju EXT","整机常见价位美元":"约250-650","国内用户信号":"美国RC玩家保有量和改装市场稳定，中国有车架、齿轮和悬挂兼容件供应链","海外销售类型":"Amazon US、RC零售和改装渠道","美国站需求信号":"专业利基（需按ASIN核验，不与Traxxas同等级）","美国站证据等级":"待核：需具体页面验证","适合开发的高客单非耗材替换升级件":"差速器、齿轮箱、传动轴、舵机、悬挂臂、避震塔、底盘和电机座","差异化开发判断":"优先型号专用传动和悬挂功能件；不做电池、轮胎和装饰壳","配件售价潜力":"60-300","符合条件":"观察池","主要核查点":"Gen 8/Kaiju版本、尺寸、传动接口和销量"}
  ,{"热度排序":360,"热度层级":"S","品类":"高性能遥控车","品牌":"MJX","推荐型号或型号族":"Hyper Go 16210 / 14210","整机常见价位美元":"约220-450","国内用户信号":"中国出口RC品牌，国内电子、齿轮和金属加工供应链强","海外销售类型":"Amazon US、欧洲RC渠道和跨境市场","美国站需求信号":"高潜候选（中国出口RC品牌，需核验具体ASIN销量）","美国站证据等级":"待核：需按型号核验销量和拆机件需求","适合开发的高客单非耗材替换升级件":"ESC、无刷电机、接收器、差速器、齿轮箱、传动轴、悬挂臂、避震塔和底盘件","差异化开发判断":"优先型号专用电控/传动/悬挂件；不做电池、充电器、轮胎和装饰件","配件售价潜力":"60-280","符合条件":"直接符合","主要核查点":"16210/14210版本、比例、ESC接口、齿轮和底盘孔位"}
]
'@
$additions = @($additionJson | ConvertFrom-Json)
$verifiedJson = @'
[
  {"热度排序":353,"热度层级":"S","品类":"燃气烤炉","品牌":"Weber","推荐型号或型号族":"Spirit E-325 / Genesis E-335 / S-435","整机常见价位美元":"约499-1299","国内用户信号":"美国庭院烤炉保有量大，中国有燃烧器、阀组、点火和钣金供应链","海外销售类型":"Amazon US、庭院家居和专业烧烤渠道","美国站需求信号":"重点候选（gas grill月搜索量87,521；Spirit E-325约US$499、近30天销量454、销售额约US$226,546、4.5/254，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"点火模块、燃烧器总成、燃气阀组、温度控制器、接油盘总成、控制面板和侧台承载结构","差异化开发判断":"优先型号专用燃烧、点火、阀组和承载件；不做烤网耗材、燃气罐和装饰罩","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"燃气类型、阀组接口、点火安全、耐热材料和型号代际"},
  {"热度排序":354,"热度层级":"S","品类":"燃气烤炉","品牌":"Monument Grills","推荐型号或型号族":"Mesa 410FBZ / Denali 405","整机常见价位美元":"约299-699","国内用户信号":"中国出口庭院烤炉品牌，燃烧器、点火器、阀体和钣金供应链集中","海外销售类型":"Amazon US和美国庭院烧烤渠道","美国站需求信号":"重点候选（Mesa II 410FBZ约US$299，近30天销量591，销售额约US$134,748，4.4/70，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"燃烧器、点火模块、阀组、温度计组件、接油盘、轮架和侧台连接件","差异化开发判断":"优先按型号做燃烧、点火和承载功能件；不做烤网、燃气耗材和装饰盖","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"燃烧器孔位、阀体螺纹、点火电极、耐热和尺寸"},
  {"热度排序":355,"热度层级":"S","品类":"燃气烤炉","品牌":"Royal Gourmet","推荐型号或型号族":"8-Burner B08TWHQ7YT / GA5403B / GA5406TS","整机常见价位美元":"约449-599","国内用户信号":"中国出口品牌，国内烤炉钣金、燃烧器和阀组工厂密集","海外销售类型":"Amazon US、庭院和户外餐饮渠道","美国站需求信号":"重点候选（8-Burner B08TWHQ7YT US$474.99，近30天销量260，销售额约US$123,497，4.2/345，200+ bought，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"点火板、燃烧器总成、燃气阀组、温控器、接油盘、轮架、侧台和控制面板","差异化开发判断":"优先型号专用阀组、点火和承载件；不做烤网、燃气罐、清洁耗材和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"B08TWHQ7YT/GA系列孔位、燃气接口、点火安全和耐热材料"},
  {"热度排序":356,"热度层级":"S","品类":"铁板烧炉/户外煎烤炉","品牌":"Blackstone","推荐型号或型号族":"1883 28-inch / 36-inch 4 Burner / 1813 22-inch","整机常见价位美元":"约219-599","国内用户信号":"美国户外煎烤高保有量，中国有燃烧器、阀组、点火和铁板结构供应链","海外销售类型":"Amazon US、庭院和户外烹饪渠道","美国站需求信号":"重点候选（blackstone griddle月搜索量195,364；1883 28-inch US$339.99、1K+ bought、4.7/约2K；36-inch US$539.99、400+ bought，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"点火模块、燃烧器、燃气阀组、温控器、铁板承托结构、接油槽总成和折叠脚架","差异化开发判断":"优先点火、燃烧、承载和排油功能件；不做煎烤耗材、燃气罐和装饰罩","配件售价潜力":"80-450","符合条件":"直接符合","主要核查点":"机身尺寸、燃烧器间距、阀体接口、耐热和排油路径"},
  {"热度排序":357,"热度层级":"S","品类":"颗粒烤炉","品牌":"Pit Boss","推荐型号或型号族":"700 FB2 / 500 FB2 / 440D2 Mahogany","整机常见价位美元":"约340-699","国内用户信号":"北美颗粒烤炉保有量高，中国有送料电机、风机、控制板和料斗钣金供应链","海外销售类型":"Amazon US、庭院烧烤和户外厨房渠道","美国站需求信号":"重点候选（pellet grill月搜索量63,088；Pit Boss 700 FB2 US$549、近30天销量445、销售额约US$244,305、4.2/163，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"温控板、螺旋送料电机、风机、RTD探针、料斗总成、点火模块和显示板","差异化开发判断":"优先控制、送料、点火和探测功能件；不做木颗粒耗材、烤网和装饰件","配件售价潜力":"100-550","符合条件":"直接符合","主要核查点":"控制板版本、RTD阻值、送料电机扭矩、料斗接口和耐热"},
  {"热度排序":358,"热度层级":"A","品类":"颗粒烤炉","品牌":"Brisk It","推荐型号或型号族":"Zelos-450 / Origin-580","整机常见价位美元":"约305-899","国内用户信号":"智能颗粒烤炉品牌，控制器、料斗和风机有中国制造基础","海外销售类型":"Amazon US、品牌独立站和户外厨房渠道","美国站需求信号":"高潜候选（Zelos-450约US$305.99，近30天销量197，销售额约US$60,280，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"控制板、显示板、送料电机、风机、RTD探针、料斗结构和点火模块","差异化开发判断":"优先型号专用控制、送料和探测件；不做颗粒燃料、烤网和装饰件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"Wi-Fi控制板、探针、送料结构、耐热和型号接口"},
  {"热度排序":359,"热度层级":"S","品类":"除雪机","品牌":"YARDMAX","推荐型号或型号族":"YB6770 26-inch / YB6270 24-inch","整机常见价位美元":"约799-1099","国内用户信号":"中国供应链覆盖除雪机钣金、传动箱、导流槽和控制件","海外销售类型":"Amazon US、庭院设备和冬季维护渠道","美国站需求信号":"重点候选（YB6770 26-inch US$806.99，50+ bought，4.2/194，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"启动电机、传动箱、螺旋输送总成、导流槽齿轮机构、控制手柄、离合结构和车架","差异化开发判断":"优先传动、导流和操控总成；不做刮板、皮带和燃油耗材","配件售价潜力":"120-700","符合条件":"直接符合","主要核查点":"两级传动、导流槽接口、低温润滑、发动机版本和安全联锁"},
  {"热度排序":360,"热度层级":"S","品类":"除雪机","品牌":"EGO Power+","推荐型号或型号族":"SNT2122 / SNT2420 24-inch","整机常见价位美元":"约699-1199","国内用户信号":"中国电机、控制板、齿轮箱和机架供应链成熟","海外销售类型":"Amazon US、园林工具和冬季设备渠道","美国站需求信号":"重点候选（SNT2122 US$699，50+ bought、4.3/1.1K；SNT2420 US$1,199，50+ bought，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"主控板、无刷驱动电机、传动箱、导流槽执行机构、手柄总成、螺旋输送总成和车架","差异化开发判断":"优先控制、传动和导流功能件；不做电池、充电器、刮板和皮带耗材","配件售价潜力":"120-700","符合条件":"直接符合","主要核查点":"电压平台、控制板版本、无刷电机接口、低温材料和安全"},
  {"热度排序":361,"热度层级":"A","品类":"除雪机","品牌":"Westinghouse","推荐型号或型号族":"WSnow22 / WSnow24","整机常见价位美元":"约249-499","国内用户信号":"中国制造的电机、导流槽、机架和控制件供应链明确","海外销售类型":"Amazon US和家用冬季维护渠道","美国站需求信号":"高潜候选（WSnow22 US$249，近30天销量117，销售额约US$29,133，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"电机/泵总成、控制板、导流槽、螺旋输送总成、手柄和轮架","差异化开发判断":"优先导流、传动和承载功能件；不做电池、充电器、刮板和皮带","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"机型电压、导流槽尺寸、螺旋轴、低温冲击和防水"},
  {"热度排序":362,"热度层级":"A","品类":"除雪机","品牌":"PowerSmart","推荐型号或型号族":"DB7621H 24-inch / DB8617 26-inch","整机常见价位美元":"约399-999","国内用户信号":"中国出口园林机械品牌，除雪机整机和钣金供应链强","海外销售类型":"Amazon US、庭院设备和冬季维护渠道","美国站需求信号":"高潜候选（PowerSmart 26-inch系列约US$999，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"发动机控制、启动电机、传动箱、导流槽齿轮、操控手柄和轮架总成","差异化开发判断":"优先型号专用传动、导流和操控件；不做燃油、刮板和皮带耗材","配件售价潜力":"100-550","符合条件":"直接符合","主要核查点":"发动机型号、传动接口、导流槽、低温材料和安全"},
  {"热度排序":363,"热度层级":"S","品类":"劈木机","品牌":"BILT HARD","推荐型号或型号族":"27-Ton Gas Log Splitter / 6.5-Ton Electric","整机常见价位美元":"约299-1399","国内用户信号":"中国出口/OEM品牌，液压泵、阀块、油缸和车架供应链成熟","海外销售类型":"Amazon US、庭院工具和木材处理渠道","美国站需求信号":"重点候选（27-ton约US$1,399.99，近30天销量18、销售额约US$25,200；6.5-ton约US$299.99、100+ bought、4.6/1.3K，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"液压泵、液压阀块、油缸、发动机控制、启动电机、楔块总成和横梁车架","差异化开发判断":"优先液压、控制和承载总成；不做液压油、燃油、电池和低价紧固件","配件售价潜力":"120-800","符合条件":"直接符合","主要核查点":"吨位、油缸行程、阀块接口、发动机/电机版本和安全防护"},
  {"热度排序":364,"热度层级":"A","品类":"劈木机","品牌":"SuperHandy","推荐型号或型号族":"20-Ton Gas Log Splitter / 25-Ton","整机常见价位美元":"约807-1599","国内用户信号":"中国制造的液压泵、阀组、油缸和拖车结构供应链强","海外销售类型":"Amazon US、庭院和专业木材处理渠道","美国站需求信号":"专业利基（20-ton约US$807.43，评分4.3/664，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"液压泵、阀块、油缸、楔块、发动机控制、启动电机、拖车连接和车架","差异化开发判断":"优先型号专用液压和承载总成；不做液压油、燃油、轮胎耗材和装饰件","配件售价潜力":"150-900","符合条件":"直接符合","主要核查点":"液压压力、阀块螺纹、油缸密封接口、牵引结构和安全"},
  {"热度排序":365,"热度层级":"S","品类":"高压清洗机","品牌":"Westinghouse","推荐型号或型号族":"WPX3000e / WPX3200e","整机常见价位美元":"约242-399","国内用户信号":"中国泵体、电机、机架和卷盘供应链成熟","海外销售类型":"Amazon US、家庭维护和专业清洗渠道","美国站需求信号":"重点候选（WPX3000e US$242.49，2K+ bought、4.6/1.2K，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"电机/泵总成、卸荷阀、压力开关、主控板、软管卷盘、扳机喷枪总成和热保护传感器","差异化开发判断":"优先泵、阀、压力控制和卷盘功能件；不做喷嘴、清洁液和通用电源线","配件售价潜力":"80-400","符合条件":"直接符合","主要核查点":"压力等级、泵轴接口、卸荷阀设定、软管规格和防水"},
  {"热度排序":366,"热度层级":"S","品类":"高压清洗机","品牌":"DeWalt","推荐型号或型号族":"DXPW3300-S / DXPW3625","整机常见价位美元":"约359-899","国内用户信号":"中国泵架、发动机辅件、轮架和喷枪结构供应链充足","海外销售类型":"Amazon US、承包商和专业清洗渠道","美国站需求信号":"重点候选（DXPW3300-S US$359，1K+ bought、4.3/939，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"泵总成、卸荷阀、压力开关、发动机控制、软管卷盘、喷枪总成和车架","差异化开发判断":"优先型号专用泵、阀和承载件；不做喷嘴耗材、清洁液和通用电源件","配件售价潜力":"100-550","符合条件":"直接符合","主要核查点":"PSI/GPM、泵体孔位、发动机轴、软管接头和安全"},
  {"热度排序":367,"热度层级":"S","品类":"空压机","品牌":"Metabo HPT","推荐型号或型号族":"EC914S 10-Gallon / EC710S","整机常见价位美元":"约249-499","国内用户信号":"中国电机、泵头、压力开关和钣金机架供应链成熟","海外销售类型":"Amazon US、专业工具和装修渠道","美国站需求信号":"重点候选（EC914S US$249，300+ bought、4.5/1.4K，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"压缩机电机、泵头、压力开关、主控板、启动电容、止回阀、调压阀组和压力传感器","差异化开发判断":"优先泵头、电机、压力控制和阀组；不做气管耗材、润滑油和通用电源线","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"储气罐容积、压力等级、泵头接口、电机功率和安全阀"},
  {"热度排序":368,"热度层级":"S","品类":"空压机","品牌":"VEVOR","推荐型号或型号族":"13-Gallon 2.5HP / 20-Gallon","整机常见价位美元":"约212-399","国内用户信号":"中国出口品牌，空压机泵头、电机、阀组和钣金供应链强","海外销售类型":"Amazon US、车库工坊和DIY工具渠道","美国站需求信号":"重点候选（13-gallon约US$212.31，200+ bought、4.4/200，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"压缩机电机、泵头总成、压力开关、控制板、启动电容、止回阀、调压阀组和压力传感器","差异化开发判断":"优先型号专用泵头、控制和阀组；不做气管、润滑油、通用电源线和低价轮脚","配件售价潜力":"80-450","符合条件":"直接符合","主要核查点":"电压、气罐接口、压力开关、泵头孔位和安全阀"},
  {"热度排序":369,"热度层级":"A","品类":"空压机","品牌":"Klutch","推荐型号或型号族":"20-Gallon Vertical / 30-Gallon","整机常见价位美元":"约299-699","国内用户信号":"中国制造的电机、泵头、压力控制和罐体配套成熟","海外销售类型":"Amazon US、车库和专业工具渠道","美国站需求信号":"高潜候选（20-gallon约US$299.99，400+ bought、4.4/711，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"泵头、电机、压力开关、启动电容、止回阀、调压阀组、压力传感器和机架","差异化开发判断":"优先压力控制、泵头和承载结构；不做气管、润滑油和通用电源件","配件售价潜力":"100-500","符合条件":"直接符合","主要核查点":"罐体容量、压力等级、泵头接口、电机功率和安全阀"},
  {"热度排序":370,"热度层级":"S","品类":"冬季采暖炉","品牌":"US Stove","推荐型号或型号族":"Ashley 2200 / US1100E-BL","整机常见价位美元":"约1027-1499","国内用户信号":"中国耐热钣金、风机、送料和控制件供应链可配套","海外销售类型":"Amazon US、壁炉和乡村住宅采暖渠道","美国站需求信号":"专业利基（Ashley 2200约US$1,300，近30天销量20、销售额约US$26,000，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"主控板、鼓风机电机、点火器、温控器、排烟风机、门组件和隔热护板","差异化开发判断":"优先耐热控制、风机和检修结构；不做燃料颗粒、密封耗材和装饰件","配件售价潜力":"120-700","符合条件":"直接符合","主要核查点":"耐热等级、排烟接口、控制板版本、防火间距和门封结构"},
  {"热度排序":371,"热度层级":"A","品类":"冬季采暖炉","品牌":"ComfortBilt","推荐型号或型号族":"HP22N / HP61","整机常见价位美元":"约1800-4000","国内用户信号":"中国钣金、风道、送料和耐热件供应链明确","海外销售类型":"Amazon US家用颗粒炉渠道","美国站需求信号":"专业利基（HP22N约US$2,299级别，4.4/291，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"主控板、鼓风机电机、点火器、温控器、螺旋送料电机、排烟风机、门组件和隔热板","差异化开发判断":"优先型号专用控制、送料和排烟件；不做燃料、密封耗材和装饰件","配件售价潜力":"150-900","符合条件":"直接符合","主要核查点":"HP22N/HP61代际、送料结构、排烟、防火间距和耐热"},
  {"热度排序":372,"热度层级":"S","品类":"商用洗地机","品牌":"HHQ","推荐型号或型号族":"Orb-6 Commercial Floor Scrubber","整机常见价位美元":"约449-899","国内用户信号":"中国商用清洁设备OEM和电机、泵、机架供应链强","海外销售类型":"Amazon US、商业保洁和物业渠道","美国站需求信号":"重点候选（Orb-6 US$449.97，100+ bought、4.4/115，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"真空电机、刷盘电机、水泵、控制板、浮球传感器、污水箱总成、吸水扒总成和机架","差异化开发判断":"优先电机、泵、控制和污水回收总成；不做刷盘耗材、清洁剂、电池和装饰件","配件售价潜力":"120-650","符合条件":"直接符合","主要核查点":"刷盘尺寸、吸水扒宽度、污水箱接口、电机功率和防水"},
  {"热度排序":373,"热度层级":"S","品类":"地毯抽洗机","品牌":"Bissell Commercial","推荐型号或型号族":"BG10 / BigGreen Commercial","整机常见价位美元":"约519-2499","国内用户信号":"中国泵、电机、吸水扒、机壳和软管供应链成熟","海外销售类型":"Amazon US、酒店保洁和专业清洁渠道","美国站需求信号":"重点候选（BG10 US$519.95，近30天销量777、销售额约US$404,001、4.7/2,003、600+ bought，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"真空电机、水泵、加热器、控制板、浮球传感器、回收箱总成、吸水扒和软管接口","差异化开发判断":"优先泵、真空、加热和回收总成；不做清洁剂、刷子耗材、电池和装饰件","配件售价潜力":"120-700","符合条件":"直接符合","主要核查点":"BG10代际、泵压、真空电机、加热器、箱体接口和防水"},
  {"热度排序":374,"热度层级":"A","品类":"地毯抽洗机","品牌":"Mytee","推荐型号或型号族":"Contractor's Special / Speedster Deluxe","整机常见价位美元":"约799-2366","国内用户信号":"中国真空电机、泵、加热器、软管接口和机壳供应链可配套","海外销售类型":"Amazon US、地毯清洁承包商和酒店渠道","美国站需求信号":"专业利基（Contractor's Special约US$2,366，近30天销量30、销售额约US$70,980，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级改装件":"真空电机、泵、加热器、主控板、浮球传感器、回收箱和吸水扒总成","差异化开发判断":"优先高价型号的泵、真空和控制总成；不做清洁液、刷子和装饰件","配件售价潜力":"150-900","符合条件":"直接符合","主要核查点":"泵压、加热功率、真空电机规格、软管接口和箱体材料"},
  {"热度排序":375,"热度层级":"S","品类":"商用制冰机","品牌":"EUHOMY","推荐型号或型号族":"100 lb Commercial Ice Maker / 400 lb","整机常见价位美元":"约309-1199","国内用户信号":"中国出口品牌，制冰机主控板、阀体、风机和料斗供应链强","海外销售类型":"Amazon US、餐饮、酒吧和酒店渠道","美国站需求信号":"重点候选（100 lb约US$309.99，近30天销量2,159、销售额约US$669,268、4.2/4,150、类目#2，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"主控板、显示板、压缩机启动模块、风机电机、进水阀、排水泵、冰厚探针、水位传感器和料斗门总成","差异化开发判断":"优先型号专用控制、阀体、风机和门组件；不做滤水芯、清洁剂和冷媒耗材","配件售价潜力":"100-650","符合条件":"直接符合","主要核查点":"冰型、产冰量、排水、传感器接口、食品接触和型号代际"},
  {"热度排序":376,"热度层级":"S","品类":"商用制冰机","品牌":"FOHERE","推荐型号或型号族":"400 lb Commercial Ice Maker","整机常见价位美元":"约1009-1299","国内用户信号":"中国出口/OEM品牌，制冷控制、风机、阀体和料斗供应链成熟","海外销售类型":"Amazon US、餐饮和酒店设备渠道","美国站需求信号":"重点候选（400 lb约US$1,009.99，近30天销量231、销售额约US$233,308、4.4/1,125，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"主控板、显示板、压缩机启动模块、风机电机、进水阀、排水泵、冰厚探针、水位传感器和料斗门","差异化开发判断":"优先控制、阀体、风机和门组件；不做滤芯、清洁剂和制冷剂","配件售价潜力":"150-800","符合条件":"直接符合","主要核查点":"400 lb机型、冰型、排水、传感器和食品安全"},
  {"热度排序":377,"热度层级":"A","品类":"商用制冰机","品牌":"Mojgar","推荐型号或型号族":"760 lb Commercial Ice Maker","整机常见价位美元":"约1299-1999","国内用户信号":"中国出口/OEM商用制冰设备，钣金、阀体、控制板和料斗供应链明确","海外销售类型":"Amazon US、餐饮工程和酒店渠道","美国站需求信号":"高潜候选（760 lb约US$1,299.99，100+ bought，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"主控板、显示板、压缩机启动模块、风机电机、进水阀、排水泵、冰厚探针、水位传感器和料斗门总成","差异化开发判断":"优先高容量型号的控制、阀体、风机和结构总成；不做滤芯、清洁剂和冷媒","配件售价潜力":"150-900","符合条件":"直接符合","主要核查点":"产冰量、冰型、排水、压缩机接口、食品接触和机架承重"},
  {"热度排序":378,"热度层级":"S","品类":"地毯抽洗机","品牌":"Kärcher","推荐型号或型号族":"Puzzi 10/1 / Puzzi 30/4","整机常见价位美元":"约1825-3499","国内用户信号":"卡赫在中国有真空电机、泵、机壳、软管和维修渠道供应链","海外销售类型":"Amazon US、酒店保洁和专业地毯清洁渠道","美国站需求信号":"专业利基（Puzzi 10/1约US$1,825，近30天销量49、销售额约US$89,425，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"真空电机、水泵、控制板、浮球传感器、回收箱、软管接口和吸水扒总成","差异化开发判断":"优先高价型号泵、真空和回收总成；不做清洁剂、刷子耗材和装饰件","配件售价潜力":"150-1000","符合条件":"直接符合","主要核查点":"Puzzi代际、泵压、真空电机、软管接口、箱体材料和防水"},
  {"热度排序":379,"热度层级":"A","品类":"冬季采暖炉","品牌":"Cleveland Iron Works","推荐型号或型号族":"Large Pellet Stove / Single Burn Rate Wood Stove","整机常见价位美元":"约486-1499","国内用户信号":"中国耐热钣金、风机、控制板、送料和门组件供应链可配套","海外销售类型":"Amazon US、壁炉和寒冷地区家用采暖渠道","美国站需求信号":"专业利基（Large Pellet Stove约US$1,499.99、4.2/54；Single Burn约US$486.37、4.3/34，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"主控板、鼓风机电机、点火器、温控器、送料电机、排烟风机、门组件和隔热护板","差异化开发判断":"优先控制、送料、排烟和耐热检修件；不做燃料、密封耗材和装饰件","配件售价潜力":"120-750","符合条件":"直接符合","主要核查点":"炉型、控制板、耐热、排烟、防火间距和门封结构"},
  {"热度排序":380,"热度层级":"S","品类":"劈木机","品牌":"YARDMAX","推荐型号或型号族":"YS0650 6.5-Ton / YU3066 30-Ton","整机常见价位美元":"约329-1599","国内用户信号":"中国液压泵、阀块、油缸、电机和车架供应链成熟","海外销售类型":"Amazon US、庭院工具和木材处理渠道","美国站需求信号":"重点候选（YS0650约US$329，100+ bought、4.6/143，当前页面核验）","美国站证据等级":"当前页面核验（SellerSprite/Amazon US）","适合开发的高客单非耗材替换升级件":"液压泵、阀块、油缸、电机/发动机控制、楔块总成、横梁和车架","差异化开发判断":"优先液压、驱动和承载总成；不做液压油、燃油、电池和低价紧固件","配件售价潜力":"120-800","符合条件":"直接符合","主要核查点":"吨位、油缸行程、阀块接口、电机/发动机版本和双手安全控制"}
]
'@
$additions += @($verifiedJson | ConvertFrom-Json)
$candidateJson = @'
[
 {"热度排序":801,"热度层级":"B","品类":"便携储能电源","品牌":"EcoFlow","推荐型号或型号族":"DELTA 2 Max / DELTA 2 Max Plus","国内用户信号":"【候选类目】第二轮评审引入：美国野火/飓风断电与露营备电双场景刚性，便携储能美国站增速约15%，中国逆变器与BMS供应链全球领先","海外销售类型":"Amazon US、户外储能与露营渠道","适合开发的高客单非耗材替换升级改装件":"逆变器板、BMS 控制板、AC/DC 转换模块、散热风扇与风道、显示面板总成、机架和提手结构（电芯不做）"},
 {"热度排序":802,"热度层级":"B","品类":"便携储能电源","品牌":"BLUETTI","推荐型号或型号族":"AC180 / AC200L","国内用户信号":"【候选类目】第二轮评审引入：BLUETTI 从 ODM 转型全球第四的标杆路径可复制；美国房车与家庭备电高客单场景明确","海外销售类型":"Amazon US、品牌独立站和房车渠道","适合开发的高客单非耗材替换升级改装件":"逆变器板、BMS 控制板、散热风道、AC 面板总成、机架和轮拉杆结构（电芯不做）"},
 {"热度排序":803,"热度层级":"B","品类":"割草机器人","品牌":"Mammotion","推荐型号或型号族":"LUBA mini AWD 1000 / YUKA mini","国内用户信号":"【候选类目】第二轮评审引入：户外品类增速12-15%，智能割草机为美国庭院新兴增量；中国供应链集中","海外销售类型":"Amazon US、庭院设备与园艺渠道","适合开发的高客单非耗材替换升级改装件":"主控板、轮组驱动电机、切割盘电机、RTK/GPS 定位模块、超声/视觉传感器、提升机构和底盘结构件（刀片耗材不做）"},
 {"热度排序":804,"热度层级":"B","品类":"电动自行车","品牌":"Heybike","推荐型号或型号族":"Ranger S / Explore S","国内用户信号":"【候选类目】第二轮评审引入：美国 E-bike 中端价位（约1000美元）缺口由 Heybike 类中国品牌填补，北美销量前三梯队","海外销售类型":"Amazon US、品牌独立站和线下车行","适合开发的高客单非耗材替换升级改装件":"扭矩传感器、彩色显示仪表、变速/刹车执行机构、货架和挡泥板结构件（电池和充电器不做）"},
 {"热度排序":805,"热度层级":"B","品类":"智能宠物设备","品牌":"PETLIBRO","推荐型号或型号族":"Granary Wi-Fi Feeder / One RFID Smart Feeder","国内用户信号":"【候选类目】第二轮评审引入：宠物用品美国站增速10-14%，高客单智能宠物产品拉动增长；PETLIBRO 为 Amazon US 热门中国品牌","海外销售类型":"Amazon US、宠物专营渠道","适合开发的高客单非耗材替换升级改装件":"主控板、称重传感器、出料电机/齿轮箱、仓体总成、RFID 识别模块和防夹结构（干燥剂耗材不做）"},
 {"热度排序":806,"热度层级":"B","品类":"美容仪器","品牌":"AMIRO","推荐型号或型号族":"R1 PRO / S1 Pro","国内用户信号":"【候选类目】第二轮评审引入：美国美妆个护增速18%以上，美容仪器客单高利润好；FDA 合规是前置门槛","海外销售类型":"Amazon US、美妆科技和直播渠道","适合开发的高客单非耗材替换升级改装件":"主控板、射频/LED 输出模组、温度传感器、探头支架、磁吸充电底座和外壳总成"},
 {"热度排序":807,"热度层级":"B","品类":"行车记录仪","品牌":"70mai","推荐型号或型号族":"A810 / A800SE","国内用户信号":"【候选类目】第二轮评审引入：美国汽配增速超20%、中国供给优势突出；行车记录仪前后双录套装客单稳定","海外销售类型":"Amazon US、汽配与电子渠道","适合开发的高客单非耗材替换升级改装件":"主控板、图像传感器模组、GPS 模块、镜头座、散热结构和吸盘/静电贴支架总成（存储卡不做）"},
 {"热度排序":808,"热度层级":"B","品类":"安防摄像头","品牌":"Eufy","推荐型号或型号族":"eufyCam 3 S330 / HomeBase S380","国内用户信号":"【候选类目】第二轮评审引入：美国智能家居安防渗透率提升，无线+太阳能充电套装客单高；安克创新供应链成熟","海外销售类型":"Amazon US、智能家居渠道","适合开发的高客单非耗材替换升级改装件":"镜头/IR 补光模组、云台电机、防水壳体、壁装支架和 HomeBase 背板（电池与电源适配器不做）"},
 {"热度排序":809,"热度层级":"B","品类":"电动工具","品牌":"KIMO","推荐型号或型号族":"20V Brushless Hammer Drill Kit","国内用户信号":"【候选类目】第二轮评审引入：工业五金为高利润蓝海，锂电无线化趋势明确；美国 DIY 用户对 20V 平台接受度高","海外销售类型":"Amazon US、DIY 工具渠道","适合开发的高客单非耗材替换升级改装件":"主控板、无刷电机、齿轮箱、钻夹头、电池接口板（电池不做）和机壳总成"},
 {"热度排序":810,"热度层级":"B","品类":"咖啡机","品牌":"HiBREW","推荐型号或型号族":"H10A / H11B","国内用户信号":"【候选类目】第二轮评审引入：美国家居厨房为第一大长青类目，半自动咖啡机高客单中国出口型号占位加速","海外销售类型":"Amazon US、厨房电器渠道","适合开发的高客单非耗材替换升级改装件":"主控板、泵、电磁阀、加热块、温度传感器、磨豆机齿轮箱和滴水盘总成"}
]
'@
$additions += @($candidateJson | ConvertFrom-Json)
$fitnessJson = @'
[
 {"热度排序":811,"热度层级":"A","品类":"家庭健身","品牌":"UREVO","推荐型号或型号族":"CyberPad / 2-in-1 Folding Treadmill Series","国内用户信号":"走步机全球份额约5.8%（2023年1.2%→2025年5.8%），北美/欧洲为其高增市场，美国主体+中国运营，CES2026 发布 CyberPad","海外销售类型":"Amazon US、品牌独立站、欧洲线上渠道","适合开发的高客单非耗材替换升级改装件":"折叠机构、跑台滚筒、无刷电机、脚感/霍尔传感器、控制板和减振底座"},
 {"热度排序":812,"热度层级":"B","品类":"家庭健身","品牌":"YOSUDA","推荐型号或型号族":"Magnetic Spin Bike Series / 2-in-1 Walking Pad","国内用户信号":"亚马逊入门动感单车长期 bestseller（约US$130-300），已扩展走步机线；客单偏低，逐型号核验客单与评论质量","海外销售类型":"Amazon US","适合开发的高客单非耗材替换升级改装件":"磁阻总成、飞轮轴承、皮带传动组件、座管/把手调节锁止和踏板曲柄"},
 {"热度排序":813,"热度层级":"B","品类":"家庭健身","品牌":"Pooboo","推荐型号或型号族":"D525 / D618 / Air Resistance Bike","国内用户信号":"Amazon 风阻单车销量第一，折叠单车月销1800+台（约US$130-435），中端价位带配件机会明确","海外销售类型":"Amazon US","适合开发的高客单非耗材替换升级改装件":"风阻扇叶总成、磁阻系统、折叠铰链、皮带传动和踏板曲柄"},
 {"热度排序":814,"热度层级":"B","品类":"家庭健身","品牌":"ANCHEER","推荐型号或型号族":"Folding Treadmill 3.25HP / 15% Incline Walking Pad","国内用户信号":"SGS CE/ROHS/CB/EN957/IEC 认证+美仓 365 天保；低价走量梯队，仅收大马力/高承重型号，P3 待核","海外销售类型":"Amazon US","适合开发的高客单非耗材替换升级改装件":"无刷电机总成、控制板、跑台滚筒、减振垫结构和折叠锁止"},
 {"热度排序":815,"热度层级":"B","品类":"家庭健身","品牌":"WENOKER","推荐型号或型号族":"Air Resistance Bike / Magnetic Spin Bike","国内用户信号":"Amazon 风阻单车 TOP3（约US$534），中端单车支持 Zwift/Kinomap 生态","海外销售类型":"Amazon US","适合开发的高客单非耗材替换升级改装件":"风阻扇叶、磁阻系统、传动皮带、轴承组和座管锁止"},
 {"热度排序":816,"热度层级":"A","品类":"家庭健身","品牌":"MAJOR FITNESS","推荐型号或型号族":"B17 Smith Machine / Power Cage Series","国内用户信号":"美式车库力量器械（Smith 机/深蹲架，B17 被行业评测列为安全优选），高客单大件，美国车库健身文化主力客群","海外销售类型":"Amazon US、品牌独立站","适合开发的高客单非耗材替换升级改装件":"Smith 机滑轨/滑块总成、深蹲架立柱连接件、钢丝绳/滑轮组、J-Hook 保护架和调节销锁"}
]
'@
$additions += @($fitnessJson | ConvertFrom-Json)
$allRows = @($rows) + @($additions)
# 排除规则（要求 4）：耗材、电池、电源适配器、纯装饰件一律不进池。
# 只匹配「品类」和「型号」两个字段——各行的判断文字里普遍带有「不做电池/不做耗材」
# 这类说明性措辞，如果连带匹配会把正常记录一起误杀。
$excludeKeyword = @(
    '耗材','滤芯','滤网','滤棉','刀片','喷嘴','墨盒','碳带','拖布','尘袋','清洁剂','咖啡豆','打印材料','耗材包',
    '电池','电芯','锂电','battery','power bank','移动电源',
    '电源适配器','充电器','适配器','电源线','数据线','charger','adapter',
    '装饰件','贴纸','贴膜','外观件','灯带','装饰灯','纯装饰','装饰品'
)

function Test-ExcludedRow {
    param($row)
    $target = @([string]$row.'品类', [string]$row.'推荐型号或型号族') -join ' '
    foreach ($kw in $script:excludeKeyword) {
        if ($target -match [regex]::Escape($kw)) { return "命中排除关键词：$kw" }
    }
    return $null
}

$excludedLog = New-Object System.Collections.ArrayList

$newRows = @($allRows | ForEach-Object { New-Row $_ } | Where-Object {
    # 耗材 / 电池 / 电源适配器 / 纯装饰件硬排除
    $(
        $why = Test-ExcludedRow -row $_
        if ($why) { [void]$excludedLog.Add(("{0} {1}｜{2}" -f $_.'品牌英文名', $_.'推荐型号或型号族', $why)) }
        -not $why
    ) -and
    $_.'品类' -ne '搅拌机' -and
    $_.'品类' -ne '车库门开启器' -and
    -not ($_.'品类' -eq '咖啡机' -and $_.'品牌英文名' -in @('Gaggia','Jura')) -and
    # 用户反馈：激光雕刻、CNC/掌机/小主机等方向整机和拆机件销量弱，移出主池。
    $_.'品类' -notin @('激光雕刻机','CNC设备','数控设备','掌机','游戏掌机','小主机','迷你主机') -and
    $_.'品牌英文名' -notin @('AOKZOE','AOOSTAR','AYANEO','Beelink','GPD','OneXPlayer','Steam Deck','xTool','Glowforge')
})

# 最终输出必须按业务优先级稳定排序，并在所有增删完成后重新连续编号。
# 原“热度排序”只作为同条件下的稳定排序依据，避免删除记录后从 11 开始或出现缺号、重复号。
$priorityRank = @{ P1 = 1; P2 = 2; P3 = 3 }
$levelRank = @{ S = 1; A = 2; B = 3 }

$newRows = @($newRows | Sort-Object `
    @{ Expression = { $priorityRank[[string]$_.'选品优先级'] } }, `
    @{ Expression = { $levelRank[[string]$_.'热度层级'] } }, `
    @{ Expression = { [int]$_.'热度排序' } })

for ($i = 0; $i -lt $newRows.Count; $i++) {
    $newRows[$i].'热度排序' = $i + 1
}

function Brand-Set([string]$value, [bool]$english) {
    $parts = $value -split '\s*/\s*'
    $out = foreach ($part in $parts) {
        $b = Get-BrandInfo $part
        if ($english) { $b.en } else { $b.cn }
    }
    return ($out -join ' / ')
}

$newRecs = foreach ($r in $recommendations) {
    [ordered]@{
        season = [string]$r.season
        category = [string]$r.category
        brandCn = Brand-Set ([string]$r.brand) $false
        brandEn = Brand-Set ([string]$r.brand) $true
        model = [string]$r.model
        reason = [string]$r.reason
        direction = [string]$r.direction
    }
}

$dataJsonOut = $newRows | ConvertTo-Json -Depth 8 -Compress
$recJsonOut = @($newRecs) | ConvertTo-Json -Depth 8 -Compress
$dataJsonOut = $dataJsonOut -replace '</', '<\\/'
$recJsonOut = $recJsonOut -replace '</', '<\\/'

$template = @'
<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AMZ美国站选品池</title>
<style>
:root{font-family:"Microsoft YaHei",Arial,sans-serif;color:#172033;background:#f4f7fb}
*{box-sizing:border-box}
body{margin:0;padding:24px}
h1{font-size:26px;margin:0 0 8px}
.note{color:#536176;line-height:1.65;margin:0 0 16px}
.legend{display:flex;gap:8px;flex-wrap:wrap;margin:0 0 14px}
.legend span{padding:5px 9px;border-radius:4px;font-size:12px;font-weight:700}
.p1{background:#dcfce7;color:#166534}
.p2{background:#dbeafe;color:#1d4ed8}
.p3{background:#fef3c7;color:#92400e}
.export-cn{background:#fff1f2;color:#b91c1c;font-weight:800;border-left:3px solid #dc2626;padding-left:6px}
.toolbar{display:flex;gap:9px;flex-wrap:wrap;align-items:center;background:#fff;border:1px solid #d7e0ec;padding:12px;margin-bottom:14px}
input,select,button{font:inherit;border:1px solid #b8c6d8;padding:8px 10px;border-radius:5px;background:#fff;color:#172033}
button{cursor:pointer}
table{border-collapse:collapse;width:100%;background:#fff;font-size:12.5px}
th{background:#132238;color:#fff;padding:9px 8px;text-align:left;white-space:nowrap}
td{border:1px solid #d7e0ec;padding:8px;vertical-align:top;line-height:1.45}

.rec{background:#fff;border:1px solid #d7e0ec;border-left:4px solid #2563eb;padding:13px}
.footer{margin-top:18px;color:#6b778a;font-size:12px}
</style>
<!--FINAL-UI-ASSETS-->
</head><body>
<h1>__PAGE_TITLE__</h1>
<p class="note">更新日期：__DATE__。此版按美国站出口优先逻辑重排：优先中国品牌/出口、或中国供应链强、且能在中国找到型号专用拆机件、替换件或功能改装件的方向。覆盖燃气烤炉、颗粒烤炉、户外煎烤炉、除雪机、劈木机、高压清洗机、空压机、冬季采暖炉、商用洗地机、地毯抽洗机和商用制冰机。已移除车库门开启器、激光雕刻机、CNC、掌机和小主机。生成脚本强制排除耗材、电池、电源适配器、纯装饰件和低价抛货。原「美国站优先池」已并入本页，工具栏「优先级」筛选 P1 即为当期优先开发子集。</p>
<div class="legend"><span class="p1">P1 中国品牌/出口或中国供应链强</span><span class="p2">P2 海外品牌/中国替换件中等</span><span class="p3">P3 需先核实供应链</span><span class="export-cn">中国品牌 / 出口（红色加粗 + 中国角标）</span></div>
<div class="toolbar">
<input id="search" placeholder="搜索中文名、英文名、型号、品类、拆机件…">
<select id="category"><option value="">全部品类</option></select>
<select id="priority"><option value="">全部优先级</option><option value="P1">P1 优先</option><option value="P2">P2 次选</option><option value="P3">P3 待核</option></select>
<select id="brandSource"><option value="">全部品牌来源</option><option value="中国">中国品牌 / 出口</option><option value="海外">海外品牌</option></select>
<select id="supply"><option value="">全部配件可得性</option><option value="高">高</option><option value="中">中</option><option value="待核">待核</option></select>
<select id="level"><option value="">全部热度</option><option value="S">S 级</option><option value="A">A 级</option><option value="B">B 级</option></select>
<select id="statusFilter"><option value="">全部状态</option><option value="未处理">未处理</option><option value="掌握了">掌握了</option><option value="不做">不做</option><option value="待定">待定</option></select>
<button id="resetStatus" class="ghost" type="button">清空状态与备注</button>
<span id="count"></span>
</div>
<div class="table-wrap"><table id="grid"><thead><tr>
<th>排序</th><th>层级</th><th>品类</th><th>品牌中文名</th><th>品牌英文名</th><th>型号（英文）</th>
        <th>国内用户信号</th><th>海外销售类型</th><th class="parts-col">拆机/替换升级件</th><th>品牌来源</th><th>中国替换件可得性</th><th>优先级</th>
        <th>状态</th><th>备注</th>
</tr></thead><tbody></tbody></table></div>
<p class="footer">「状态」与「备注」按内容标识保存在当前浏览器本地存储，不会上传到网络；换浏览器或清除站点数据后需要重新标记。品牌中文译名以常用市场译名为主，正式上架前请按商标、官方型号、专利和认证复核。整机含电池的设备只是不开发电池本身。</p>
<script>
const data=__DATA__;
const PAGE_KEY='__PAGE_KEY__';
const LEGACY=__LEGACY__;
const store=new PoolUI.Store(PAGE_KEY,LEGACY);
const esc=PoolUI.esc;
const el=id=>document.getElementById(id);
const search=el('search'),cat=el('category'),priority=el('priority'),brandSource=el('brandSource'),supply=el('supply'),level=el('level'),statusFilter=el('statusFilter');
const tbody=document.querySelector('#grid tbody');
function idOf(r){return [r['品类'],r['品牌英文名'],r['推荐型号或型号族']].join('|')}
function isCn(r){return /^中国/.test(String(r['品牌来源']||''))}
PoolUI.mountChrome({home:'index.html'});
const categories=[...new Set(data.map(r=>r['品类']))].sort((a,b)=>a.localeCompare(b,'zh-CN'));
cat.innerHTML+=categories.map(c=>'<option value="'+esc(c)+'">'+esc(c)+'</option>').join('');
function shownCount(){return document.querySelectorAll('#grid tbody tr:not(.empty-row)').length}
function render(){
  const q=search.value.trim().toLowerCase(),c=cat.value,p=priority.value,bs=brandSource.value,sp=supply.value,l=level.value,sf=statusFilter.value;
  const out=data.filter(r=>{
    const st=store.status(idOf(r)),cn=isCn(r);
    return (!q||Object.values(r).some(v=>String(v).toLowerCase().includes(q)))
      &&(!c||r['品类']===c)&&(!p||r['选品优先级']===p)
      &&(!bs||(bs==='中国'?cn:!cn))
      &&(!sp||r['中国替换件可得性']===sp)
      &&(!l||r['热度层级']===l)&&(!sf||st===sf);
  }).sort((a,b)=>a['热度排序']-b['热度排序']);
  tbody.innerHTML=out.length?out.map(r=>{
    const id=idOf(r),st=store.status(id);
    const cn=isCn(r),bc=cn?' class="brand-export"':'',badge=cn?PoolUI.cnBadge():'';
    return '<tr class="'+PoolUI.rowClass(st)+'">'
      +'<td>'+esc(r['热度排序'])+'</td>'
      +'<td class="tag">'+esc(r['热度层级'])+'</td>'
      +'<td>'+esc(r['品类'])+'</td>'
      +'<td'+bc+'>'+esc(r['品牌中文名'])+badge+'</td>'
      +'<td'+bc+'>'+esc(r['品牌英文名'])+'</td>'
      +'<td class="model-cell">'+esc(r['推荐型号或型号族'])+'</td>'
      +'<td>'+esc(r['国内用户信号'])+'</td>'
      +'<td>'+esc(r['海外销售类型'])+'</td>'
      +'<td class="parts-cell">'+esc(r['拆机/替换升级件'])+'</td>'
      +'<td'+bc+'>'+esc(r['品牌来源'])+'</td>'
      +'<td>'+esc(r['中国替换件可得性'])+'</td>'
      +'<td class="priority-'+esc(r['选品优先级'])+'">'+esc(r['选品优先级'])+'</td>'
      +PoolUI.statusCellHtml(id,st)
      +PoolUI.noteCellHtml(id,store.note(id))
      +'</tr>';
  }).join(''):'<tr class="empty-row"><td colspan="14">没有符合当前筛选条件的记录</td></tr>';
  PoolUI.setCount(out.length,data.length,store.marked());
}
function refilter(){PoolUI.withFocusKept(render)}
PoolUI.bindTable(tbody,store,{
  onStatus:()=>{PoolUI.setCount(shownCount(),data.length,store.marked());if(statusFilter.value)refilter()},
  onNote:()=>PoolUI.setCount(shownCount(),data.length,store.marked())
});
search.addEventListener('input',refilter);
[cat,priority,brandSource,supply,level,statusFilter].forEach(x=>x.addEventListener('change',refilter));
el('resetStatus').addEventListener('click',()=>{if(!confirm('清空本页所有状态与备注？该操作不可撤销。'))return;store.clear(LEGACY);search.value='';cat.value='';priority.value='';brandSource.value='';supply.value='';level.value='';statusFilter.value='';render()});
render();
</script>
</body></html>
'@

# 主池：占位符一次性替换，不再对成品 HTML 做事后字符串补丁。
# 旧版靠 Replace('<th>中国替换件可得性</th><th>优先级</th>', ...) 插入「拆机可搜核心件」列，
# 表头一变就会静默失效并造成表头与单元格错位，现已直接写进模板。
$finalHtml = $template.
    Replace('__DATA__',      $dataJsonOut).
    Replace('__RECS__',      $recJsonOut).
    Replace('__PAGE_TITLE__','AMZ美国站选品池').
    Replace('__PAGE_KEY__',  'us-main-pool').
    Replace('__LEGACY__',    "['selection-pool-status-v3-20260831','selection-pool-status-v3','selection-pool-status-v2','pool-ui-v2::us-priority-pool']").
    Replace('__DATE__',      (Get-Date -Format 'yyyy-MM-dd'))
Set-Content -LiteralPath $output -Value $finalHtml -Encoding utf8

Write-Output "已生成：$output"
Write-Output "原有记录：$($rows.Count)，新增记录：$($additions.Count)，总记录：$($newRows.Count)"
$p1Count = @($newRows | Where-Object { $_.'选品优先级' -eq 'P1' }).Count
Write-Output "其中 P1 优先开发记录：$p1Count（优先池已并入单页，用「优先级」筛选查看）"
if ($excludedLog.Count -gt 0) {
    Write-Output "按排除规则剔除 $($excludedLog.Count) 条："
    $excludedLog | Sort-Object -Unique | ForEach-Object { Write-Output "  - $_" }
}
