$ErrorActionPreference = 'Stop'

<#
  亚马逊日本站（Amazon.co.jp）高客单型号选品池生成器
  与墨西哥/波兰池同一套表格结构与 UI 机制（PoolUI + FINAL-UI-ASSETS 锚点）：
    对比 / 排序 / 品类 / 品牌中文名 / 品牌英文名 / 型号（英文） / JPY在售区间 / RMB工作换算 /
    日语搜索词 / 拆机可搜核心件 / 品牌来源 / 开发判断 / 状态 / 备注
  日本站特有：
    - JPY→RMB 按 1 RMB ≈ 20.8 JPY（0.048）工作换算；
    - 低于 $jpyFloor（约 US$120）的整机按「低价抛货」剔除；
    - 新增「数据对比」模块：勾选至多 3 条记录并排比较核心字段。
#>

$dir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$out = Join-Path $dir 'AMZ日本站选品池.html'

# JPY 工作换算下限：低于此值视为低价抛货，只做市场观察，不进选品池。
$jpyFloor = 18000

# 品类 / 型号命中以下任一关键词即剔除（耗材、电池、电源适配器、纯装饰件）。
$excludeKeyword = @(
  '耗材','滤芯','滤网','滤棉','刀片','喷嘴','墨盒','碳带','打印耗材','清洁剂','咖啡豆',
  '电池','电芯','锂电','battery',
  '电源适配器','充电器','适配器','电源线','数据线','charger','adapter',
  '装饰件','贴纸','贴膜','外观件','灯带','装饰灯','纯装饰'
)

$dataJson = @'
[
 {"category":"便携储能电源","brandCn":"正浩","brandEn":"EcoFlow","model":"DELTA 2 Max / DELTA 2 Max Plus","jpy":"¥89,800–109,800","rmb":"约 ¥4,310–5,270","search":"ポータブル電源 EcoFlow DELTA 2 Max","parts":"逆变器板、BMS 控制板、AC/DC 转换模块、散热风扇与风道、显示面板总成、机架和提手结构（电芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本地震备电+露营双场景刚需；上架前核验 PSE（電気用品安全法）与电池运输合规，先做面板、散热和结构件"},
 {"category":"便携储能电源","brandCn":"安克","brandEn":"Anker SOLIX","model":"SOLIX C1000 / C800","jpy":"¥129,900–169,900","rmb":"约 ¥6,240–8,160","search":"ポータブル電源 Anker SOLIX C1000","parts":"逆变器板、BMS 控制板、散热风道、显示面板总成、机架和提手结构（电芯不做）","source":"中国出口品牌（安克创新）；中国替换件可得性高","fit":"日本家庭备电与露营主流型号；优先显示板、散热、提手和机架件；不做电芯和太阳能板线束"},
 {"category":"便携储能电源","brandCn":"德兰明海","brandEn":"BLUETTI","model":"AC180 / AC200L","jpy":"¥129,800–159,800","rmb":"约 ¥6,230–7,670","search":"ポータブル電源 BLUETTI AC180","parts":"逆变器板、BMS 控制板、散热风道、AC 面板总成、机架和提手结构（电芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本防灾备电清单品类；从 ODM 转品牌的标杆路径可复制；优先面板与散热件"},
 {"category":"便携储能电源","brandCn":"电小二","brandEn":"Jackery","model":"Explorer 1000 v2 / Explorer 300 Plus","jpy":"¥99,000–129,000","rmb":"约 ¥4,750–6,190","search":"ポータブル電源 Jackery Explorer 1000 v2","parts":"逆变器板、BMS 控制板、散热风道、显示面板总成、机架和提手结构（电芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本亚马逊便携储能头部品牌之一；型号保有量大、维修件需求明确；不做电芯"},
 {"category":"便携储能电源","brandCn":"正浩","brandEn":"EcoFlow","model":"DELTA Pro 3","jpy":"¥399,000–459,000","rmb":"约 ¥19,150–22,030","search":"ポータブル電源 EcoFlow DELTA Pro 3 家庭用蓄電","parts":"逆变器板、BMS 控制板、散热风道、AC 面板总成、轮拉杆结构和机架（电芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"超高端家庭备电+太阳能系统入口；客单极高但保有量有限；先观察再定开发深度"},
 {"category":"扫地机器人","brandCn":"石头科技","brandEn":"Roborock","model":"Q Revo S / Q Revo Pro","jpy":"¥89,800–109,800","rmb":"约 ¥4,310–5,270","search":"ロボット掃除機 Roborock Q Revo S","parts":"主控板、激光雷达/视觉模组、轮组电机、风机、泵、污水箱总成、基站控制板、充电触点板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本扫地机渗透率高、型号集中；优先主控、泵阀和基站件；不做滤芯拖布耗材；核验充电座 PSE"},
 {"category":"扫地机器人","brandCn":"追觅","brandEn":"Dreame","model":"X50 Ultra Complete","jpy":"¥129,800–154,800","rmb":"约 ¥6,230–7,430","search":"ロボット掃除機 Dreame X50 Ultra Complete","parts":"主控板、激光雷达、升降/越障机构电机、轮组电机、风机、泵、污水箱总成、基站控制板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本高端机型越障/热水洗功能差异化明显；优先越障机构、泵阀和基站结构"},
 {"category":"扫地机器人","brandCn":"科沃斯","brandEn":"Ecovacs","model":"DEEBOT X9 PRO OMNI","jpy":"¥189,800–219,800","rmb":"约 ¥9,110–10,550","search":"ロボット掃除機 エコバックス DEEBOT X9 PRO OMNI","parts":"主控板、导航/视觉模组、轮组电机、风机、泵、基站控制板、污水箱总成和充电触点板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本市占前列、保有量大意味着维修件市场成熟；优先导航、泵和基站功能件"},
 {"category":"扫地机器人","brandCn":"云鲸","brandEn":"Narwal","model":"Freo Z Ultra","jpy":"¥99,800–119,800","rmb":"约 ¥4,790–5,750","search":"ロボット掃除機 Narwal Freo Z Ultra","parts":"主控板、激光雷达/视觉模组、轮组电机、风机、泵、污水箱总成、基站控制板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本市场存在感上升中；优先基站与泵阀件；不做拖布耗材"},
 {"category":"3D打印机","brandCn":"拓竹","brandEn":"Bambu Lab","model":"P1S Combo with AMS","jpy":"¥99,000–109,800","rmb":"约 ¥4,750–5,270","search":"3Dプリンター Bambu Lab P1S Combo AMS","parts":"主板、运动控制板、步进电机、挤出机总成、热床控制板、导轨/丝杆、AMS 驱动板和传感器","source":"中国出口品牌；中国替换件可得性高","fit":"日本创客与模型制作社群大；优先 AMS、挤出和运动件；不做喷嘴与打印耗材"},
 {"category":"3D打印机","brandCn":"拓竹","brandEn":"Bambu Lab","model":"X1 Carbon","jpy":"¥159,800–179,800","rmb":"约 ¥7,670–8,630","search":"3Dプリンター Bambu Lab X1 Carbon","parts":"主板、运动控制板、步进电机、挤出机总成、热床控制板、屏幕、导轨/丝杆和传感器","source":"中国出口品牌；中国替换件可得性高","fit":"日本专业用户与打印农场使用；优先运动控制、挤出和腔体功能件"},
 {"category":"3D打印机","brandCn":"创想三维","brandEn":"Creality","model":"K1C","jpy":"¥59,800–69,800","rmb":"约 ¥2,870–3,350","search":"3Dプリンター Creality K1C","parts":"主板、运动控制板、步进电机、挤出机、热床控制板、屏幕、导轨/丝杆、摄像头和限位传感器","source":"中国出口品牌；中国替换件可得性高","fit":"日本入门高速机主流价位；创客保有量高；优先主板、挤出机和运动结构"},
 {"category":"3D打印机","brandCn":"创想三维","brandEn":"Creality","model":"K1 Max","jpy":"¥79,800–89,800","rmb":"约 ¥3,830–4,310","search":"3Dプリンター Creality K1 MAX","parts":"主板、运动控制板、步进电机、挤出机、热床控制板、屏幕、导轨/丝杆、摄像头和传感器","source":"中国出口品牌；中国替换件可得性高","fit":"大尺寸机型日本专业用户使用；优先主控、运动和摄像头功能件"},
 {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Mini 5 Pro Fly More Combo","jpy":"¥129,800–175,000","rmb":"约 ¥6,230–8,400","search":"DJI Mini 5 Pro ドローン","parts":"飞控板、云台控制板、相机模组、图传板、无刷电机、电调、遥控器主板、起落架和云台保护架（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本 100g 未满机免机体认证，Mini 系列为主力；优先云台保护与起落架；不做桨叶耗材；核验电波法技适认证"},
 {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Neo 2 Fly More Combo","jpy":"¥49,800–59,800","rmb":"约 ¥2,390–2,870","search":"DJI Neo 2 ドローン","parts":"飞控板、云台/相机模组、图传板、无刷电机、电调、视觉定位板和遥控器主板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"自拍/入门自拍机型日本年轻人市场活跃；优先云台与保护结构"},
 {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Air 3S Fly More Combo","jpy":"¥174,800–219,800","rmb":"约 ¥8,390–10,550","search":"DJI Air 3S ドローン","parts":"飞控板、云台相机模组、图传板、无刷电机、电调、GPS/视觉定位板和遥控器主板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本准专业航拍主力；机体认证与技适合规机型；优先云台、飞控和图传功能件"},
 {"category":"美容仪器","brandCn":"徕芬","brandEn":"Laifen","model":"SE High-Speed Hair Dryer / SE Lite","jpy":"¥24,800–29,800","rmb":"约 ¥1,190–1,430","search":"ドライヤー Laifen SE 高速","parts":"主控板、高速无刷电机总成、加热丝支架、风嘴磁吸结构、滤网支架和手柄总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本高速吹风机市场对国产品牌接受度上升；优先电机与磁吸风嘴结构；注意 PSE 与宣传边界"},
 {"category":"美容仪器","brandCn":"觅光","brandEn":"AMIRO","model":"R1 PRO / S1 Pro","jpy":"¥49,800–59,800","rmb":"约 ¥2,390–2,870","search":"フェイスマシン AMIRO R1 PRO 美容","parts":"主控板、射频/LED 输出模组、温度传感器、探头支架、磁吸充电底座和外壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本美容仪受药机法宣传限制；以家用美容类目核对法规边界；优先探头结构与支架"},
 {"category":"美容仪器","brandCn":"Ulike","brandEn":"Ulike","model":"Air+ / Air 10","jpy":"¥49,800–69,800","rmb":"约 ¥2,390–3,350","search":"脱毛器 Ulike Air10 光美容","parts":"主控板、IPL 输出模组、冷却结构、皮肤接触传感器、灯头支架和外壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本家用光脱毛器市场规模大且中国品牌占位领先；优先冷却与传感结构；药机法合规前置"},
 {"category":"智能宠物设备","brandCn":"小佩","brandEn":"PETKIT","model":"Pura Max 2","jpy":"¥59,800–69,800","rmb":"约 ¥2,870–3,350","search":"自動猫トイレ PETKIT Pura Max 2","parts":"主控板、称重传感器、仓体翻转电机/齿轮箱、集便箱总成、除臭模块支架和防夹传感器（滤砂耗材不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本独居养猫率高、自動猫トイレ搜索量大；优先称重与仓体结构件"},
 {"category":"智能宠物设备","brandCn":"猫链","brandEn":"CATLINK","model":"Scooper Pro / Luxury Pro","jpy":"¥49,800–59,800","rmb":"约 ¥2,390–2,870","search":"自動猫トイレ CATLINK Scooper Pro","parts":"主控板、称重传感器、仓体翻转电机/齿轮箱、集便箱总成和防夹传感器（滤砂耗材不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本多猫家庭需求稳定；优先仓体翻转结构与传感器件"},
 {"category":"智能宠物设备","brandCn":"小佩","brandEn":"PETKIT","model":"YumShare Solo","jpy":"¥24,800–29,800","rmb":"约 ¥1,190–1,430","search":"自動給餌器 PETKIT YumShare Solo","parts":"主控板、称重传感器、出料电机/齿轮箱、仓体总成、摄像头模组支架和防夹结构（干燥剂耗材不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本自动喂食器带摄像头机型增长快；优先出料结构与摄像头支架"},
 {"category":"安防摄像头","brandCn":"睿联","brandEn":"Reolink","model":"RLC-810A + RLN8-410 8CH Kit","jpy":"¥29,800–39,800","rmb":"约 ¥1,430–1,910","search":"防犯カメラ Reolink RLC-810A RLN8-410","parts":"PoE 主板、镜头/IR 补光模组、防水壳体、壁装支架和 NVR 背板（硬盘与电源不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本住宅+店铺防犯カメラ双场景；PoE 套装客单高；优先支架、防水壳和背板件"},
 {"category":"安防摄像头","brandCn":"安克Eufy","brandEn":"Eufy","model":"eufyCam 3 S330 / HomeBase S380","jpy":"¥59,800–69,800","rmb":"约 ¥2,870–3,350","search":"防犯カメラ eufyCam 3 S330","parts":"镜头/IR 补光模组、太阳能充电接口模组、防水壳体、壁装支架和 HomeBase 背板（电池与电源适配器不做）","source":"中国出口品牌（安克创新）；中国替换件可得性高","fit":"日本无线防犯カメラ高端市场；太阳能套装差异化；优先壳体与支架件"},
 {"category":"安防摄像头","brandCn":"绿米Aqara","brandEn":"Aqara","model":"Camera Hub G5 Pro","jpy":"¥29,800–34,800","rmb":"约 ¥1,430–1,670","search":"Aqara G5 Pro 防犯カメラ スマートホーム","parts":"主板、镜头/IR 模组、云台电机、隐私遮蔽结构、壁装支架和 Hub 通信板（电源适配器不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本智能家居生态用户增长；带 Hub 摄像头是入口型产品；优先支架与云台件"},
 {"category":"咖啡机","brandCn":"HiBREW","brandEn":"HiBREW","model":"H10A / H11B","jpy":"¥19,800–24,800","rmb":"约 ¥950–1,190","search":"エスプレッソマシン HiBREW H10A 20 bar","parts":"主控板、泵、电磁阀、加热块、温度传感器、磨豆机齿轮箱和滴水盘总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本家用半自动咖啡机增长；中国出口性价比型号占位加速；优先泵阀和加热件；不做咖啡豆与清洁耗材"},
 {"category":"咖啡机","brandCn":"心想","brandEn":"SCISHARE","model":"S1103 Capsule Machine","jpy":"¥19,800–24,800","rmb":"约 ¥950–1,190","search":"カプセルコーヒーマシン SCISHARE S1103","parts":"主控板、泵、电磁阀、加热块、胶囊穿刺机构、温度传感器和滴水盘总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本胶囊机市场被雀巢主导但价格带有机会；优先穿刺机构与泵阀件"},
 {"category":"咖啡机","brandCn":"Gevi","brandEn":"Gevi","model":"Compact Espresso Machine 20-Bar","jpy":"¥29,800–39,800","rmb":"约 ¥1,430–1,910","search":"エスプレッソマシン Gevi 20bar おうちカフェ","parts":"主控板、泵、电磁阀、加热块、蒸汽阀、温度传感器和滴水盘总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本「おうちカフェ」场景热；优先泵阀与蒸汽结构件"},
 {"category":"投影仪","brandCn":"极米","brandEn":"XGIMI","model":"Horizon Ultra / Elfin","jpy":"¥89,800–129,800","rmb":"约 ¥4,310–6,230","search":"プロジェクター XGIMI Horizon Ultra 4K","parts":"主板、DMD/光机组件、LED 驱动板、风扇、镜头调节机构、遥控接收板和散热风道（电源板仅拆机件）","source":"中国出口品牌；中国替换件可得性高","fit":"日本家庭影院与租房投影需求增长；优先光机散热、镜头调节和安装结构"},
 {"category":"投影仪","brandCn":"安克星云","brandEn":"Nebula","model":"Capsule 3 Laser","jpy":"¥69,800–89,800","rmb":"约 ¥3,350–4,310","search":"ポータブルプロジェクター Anker Nebula Capsule 3 Laser","parts":"主板、DLP 光机、LED 驱动板、风扇、镜头/云台机构、遥控接收板和散热结构（电池不做）","source":"中国出口品牌（安克创新）；中国替换件可得性高","fit":"日本便携投影头部型号；优先光机、云台/镜头和散热结构"},
 {"category":"投影仪","brandCn":"坚果","brandEn":"JMGO","model":"N1 Ultra / N1S Pro","jpy":"¥129,800–149,800","rmb":"约 ¥6,230–7,190","search":"プロジェクター JMGO N1 Ultra","parts":"主板、三色激光光机、驱动板、风扇、云台转轴机构、遥控接收板和散热风道（电源板仅拆机件）","source":"中国出口品牌；中国替换件可得性高","fit":"日本激光云台投影增量型号；优先云台转轴与散热件"},
 {"category":"行车记录仪","brandCn":"70迈","brandEn":"70mai","model":"A810 / A800SE","jpy":"¥24,800–29,800","rmb":"约 ¥1,190–1,430","search":"ドラレコ 70mai A810 4K","parts":"主控板、图像传感器模组、GPS 模块、镜头座、散热结构和吸盘/静电贴支架总成（存储卡不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本ドラレコ普及率极高、前后双录套装需求大；优先支架与散热件；注意电波法技适认证机型"},
 {"category":"行车记录仪","brandCn":"70迈","brandEn":"70mai","model":"Dash Cam Pro Plus+ A500S","jpy":"¥19,800–24,800","rmb":"约 ¥950–1,190","search":"ドラレコ 70mai A500S 後方カメラセット","parts":"主控板、图像传感器模组、GPS 模块、后摄线材接口板、散热结构和支架总成（存储卡不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本前后双录入门主力；优先支架与线材接口固定件"},
 {"category":"行车记录仪","brandCn":"盯盯拍","brandEn":"DDPAI","model":"mini5 / Z50","jpy":"¥24,800–29,800","rmb":"约 ¥1,190–1,430","search":"ドラレコ DDPAI mini5 4K","parts":"主控板、图像传感器模组、4G 通信板（Z50）、镜头座、散热结构和支架总成（存储卡不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本 4K/4G 机型细分市场；优先散热与支架件；4G 机型核验技适认证"},
 {"category":"空气净化器","brandCn":"小米","brandEn":"Xiaomi","model":"Mi Air Purifier 4 Pro","jpy":"¥34,800–39,800","rmb":"约 ¥1,670–1,910","search":"空気清浄機 Xiaomi 4 Pro","parts":"主控板、风机电机、风轮、颗粒物/温湿度传感器板、显示板和机身风道（滤芯不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本花粉季与 PM2.5 需求稳定；优先风机与传感器板；不做滤芯耗材"},
 {"category":"空气净化器","brandCn":"智米","brandEn":"Smartmi","model":"Smartmi Air Purifier 2","jpy":"¥39,800–49,800","rmb":"约 ¥1,910–2,390","search":"空気清浄機 Smartmi 加湿機能","parts":"主控板、风机电机、风轮、传感器板、加湿蒸发结构支架和机身风道（滤芯耗材不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本偏好加湿一体型空清；优先加湿蒸发结构与风机件"},
 {"category":"高压清洗机","brandCn":"卡赫","brandEn":"Kärcher","model":"K5 Power / K3","jpy":"¥39,800–49,800","rmb":"约 ¥1,910–2,390","search":"高圧洗浄機 ケルヒャー K5","parts":"电机/泵总成、卸荷阀、压力开关、控制板、软管卷盘、扳机喷枪总成和热保护传感器","source":"海外品牌/中国制造供应链；替换件可得性高","fit":"日本家庭洗车与外装清洗刚需；优先泵阀、压力控制和卷盘件；不做喷嘴与清洁剂"},
 {"category":"高压清洗机","brandCn":"威沃","brandEn":"VEVOR","model":"High Pressure Washer 1800W","jpy":"¥19,800–29,800","rmb":"约 ¥950–1,430","search":"高圧洗浄機 VEVOR 1800W 家庭用","parts":"泵头总成、电机、压力开关、控制板、止回阀、调压阀组和机架","source":"中国出口品牌；中国替换件可得性高","fit":"日本 DIY 用户性价比选择；优先泵头与压力控制件"},
 {"category":"湿干吸尘器/洗地机","brandCn":"添可","brandEn":"Tineco","model":"Floor ONE S7 Stretch","jpy":"¥79,800–89,800","rmb":"约 ¥3,830–4,310","search":"湿干掃除機 Tineco Floor ONE S7","parts":"主控板、吸水/真空电机、刷盘电机、水泵、污水箱总成、浮球传感器、显示板和充电触点板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本湿干一体机增长快；优先电机、泵、污水箱和停靠底座；不做滚刷滤网耗材"},
 {"category":"湿干吸尘器/洗地机","brandCn":"追觅","brandEn":"Dreame","model":"H14 Pro / H12 Pro","jpy":"¥59,800–69,800","rmb":"约 ¥2,870–3,350","search":"湿干掃除機 Dreame H14 Pro","parts":"主控板、真空电机、刷盘电机、水泵、污水箱总成、浮球传感器和显示板（电池不做）","source":"中国出口品牌；中国替换件可得性高","fit":"日本洗地机渗透早期、空间大；优先泵阀与污水箱结构"},
 {"category":"电动工具","brandCn":"威克士","brandEn":"WORX","model":"20V Brushless Hammer Drill WX358","jpy":"¥19,800–24,800","rmb":"约 ¥950–1,190","search":"充電式ドリルドライバー WORX WX358 20V","parts":"主控板、无刷电机、齿轮箱、钻夹头、电池接口板（电池不做）和机壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本 DIY 用户对 20V 平台接受度上升；优先齿轮箱与夹头结构件；不做电池与充电器"},
 {"category":"电动工具","brandCn":"KIMO","brandEn":"KIMO","model":"20V Brushless Drill Kit","jpy":"¥18,800–21,800","rmb":"约 ¥900–1,050","search":"充電式ドリル KIMO ブラシレス","parts":"主控板、无刷电机、齿轮箱、钻夹头、电池接口板（电池不做）和机壳总成","source":"中国出口品牌；中国替换件可得性高","fit":"日本入门电动工具价格带机会；优先齿轮箱与夹头件"},
 {"category":"除湿机","brandCn":"美的/科慕菲","brandEn":"Comfee","model":"MDDF-16DEN7-WF 16L","jpy":"¥29,800–34,800","rmb":"约 ¥1,430–1,670","search":"除湿機 Comfee 16L コンプレッサー式","parts":"主控板、显示板、风机电机、压缩机启动模块、湿度传感器、排水泵和水箱","source":"中国出口品牌；中国替换件可得性高","fit":"日本梅雨与台风季除湿刚需；压缩机式 16L 以上为主力；优先排水与传感器件"},
 {"category":"除湿机","brandCn":"美的","brandEn":"Midea","model":"MDDF-20DEN7-QA3 20L","jpy":"¥34,800–39,800","rmb":"约 ¥1,670–1,910","search":"除湿機 Midea 20L 衣類乾燥","parts":"主控板、显示板、风机电机、风轮、湿度传感器、压缩机启动模块、排水泵、水箱和脚轮底座","source":"中国出口品牌；中国替换件可得性高","fit":"日本衣物干燥附加功能是关键卖点；优先排水、传感器和风道结构"}
]
'@

$jpFitnessJson = @'
[
 {"category":"家庭健身","brandCn":"金史密斯/WalkingPad","brandEn":"WalkingPad","model":"A1 Pro / R2 Pro / R3","jpy":"¥54,800–99,800","rmb":"约 ¥2,630–4,790","search":"ウォーキングマシン WalkingPad R2 折りたたみ","parts":"折叠铰链/锁止总成、跑台滚筒、无刷电机总成、脚感控速传感器、遥控通信板和减振底座","source":"中国出口品牌；中国替换件可得性高","fit":"小米系走步机在日本认知度高、1㎡ 收纳刚需；优先折叠与传感件；不做跑带耗材；核验 PSE 与在售型号"},
 {"category":"家庭健身","brandCn":"麦瑞克","brandEn":"MERACH","model":"UltraWalk W60 / 椭圆机小型化系列","jpy":"¥29,800–59,800","rmb":"约 ¥1,430–2,870","search":"MERACH ウォーキングマシン エリプティカル","parts":"磁阻控制总成、飞轮轴承、折叠锁止、APP 通信板和减振结构","source":"中国出口品牌；中国替换件可得性高","fit":"官方已针对日本做小型化轻量化产品；小户型有氧器械增量品牌；核验 PSE 与在售型号"}
]
'@
$rows = @(@($dataJson | ConvertFrom-Json) + @($jpFitnessJson | ConvertFrom-Json))

function Test-Excluded {
    param($row)
    # 只在品类和型号上做硬排除；「电芯不做」这类说明性文字不算命中
    $target = @([string]$row.category, [string]$row.model) -join ' '
    foreach ($kw in $script:excludeKeyword) {
        if ($target -match [regex]::Escape($kw)) { return "命中排除关键词：$kw" }
    }
    # jpy 形如「¥89,800–109,800」，取第一个数字做下限判断
    $m = [regex]::Match([string]$row.jpy, '([\d,]+(?:\.\d+)?)')
    if ($m.Success) {
        $v = [double](($m.Groups[1].Value) -replace ',', '')
        if ($v -lt $script:jpyFloor) { return ("低价抛货：{0} JPY 低于下限 {1} JPY" -f $v, $script:jpyFloor) }
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
.export{color:#b91c1c;font-weight:800}
.toolbar{display:flex;gap:9px;flex-wrap:wrap;background:#fff;border:1px solid #d7e0ec;padding:12px}
input,select,button{font:inherit;padding:8px;border:1px solid #b8c6d8;border-radius:5px}
table{border-collapse:collapse;width:100%;background:#fff;font-size:12.5px;margin-top:14px}
th{background:#132238;color:#fff;padding:9px;text-align:left;white-space:nowrap}
td{border:1px solid #d7e0ec;padding:8px;vertical-align:top;line-height:1.45}
.footer{color:#6b778a;font-size:12px;margin-top:16px}
.cmp-col{width:36px;text-align:center}
.cmp-check{width:15px;height:15px;accent-color:#132238;cursor:pointer;padding:0}
.cmp-modal{position:fixed;inset:0;background:rgba(9,17,30,.55);display:flex;align-items:center;justify-content:center;z-index:9999}
.cmp-modal[hidden]{display:none}
.cmp-box{background:#fff;border:1px solid #d7e0ec;border-radius:10px;max-width:96vw;max-height:85vh;overflow:auto;padding:18px 20px}
.cmp-box h3{margin:0 0 10px;font-size:16px}
.cmp-box table{margin-top:0}
.cmp-box th{background:#132238}
.cmp-field{white-space:nowrap;font-weight:700;background:#f4f7fb;width:110px}
.cmp-close{margin-top:12px}
'@

$template = @'
<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AMZ日本站选品池</title>
<style>
__CSS__
</style>
<!--FINAL-UI-ASSETS-->
</head><body>
<h1>AMZ日本站选品池</h1>
<p class="note">更新日期：__DATE__。主表按 Amazon.co.jp 公开搜索页制作，保留页面有在售 / 评分 / 榜单信号，且中国能找到型号专用功能替换件或改装件的方向。JPY→RMB 仅按 1 RMB ≈ 20.8 JPY（约 0.048）的工作汇率折算，发布前按当天汇率复核；低于 ¥__FLOOR__（约 US$120）的整机按低价抛货剔除。日本市场合规提示：电器类目需 PSE（電気用品安全法），ドローン需机体认证与技适认证，美容仪宣传需避开医疗功效表述。已排除耗材、电池、电源适配器、纯装饰件和低价抛货。</p>
<div class="legend"><span class="export">中国品牌 / 出口（红色加粗 + 中国角标）</span></div>
<div class="toolbar">
<input id="search" placeholder="搜索品牌、型号、日语关键词、拆机件…">
<select id="category"><option value="">全部品类</option></select>
<select id="source"><option value="">全部品牌来源</option><option value="中国">中国品牌 / 出口</option><option value="海外">海外品牌</option></select>
<select id="statusFilter"><option value="">全部状态</option><option value="未处理">未处理</option><option value="掌握了">掌握了</option><option value="不做">不做</option><option value="待定">待定</option></select>
<button id="resetStatus" class="ghost" type="button">清空状态与备注</button>
<button id="cmpBtn" class="ghost" type="button" disabled>对比选中（0/3）</button>
<button id="cmpClear" class="ghost" type="button">清除对比</button>
<span id="count"></span>
</div>
<div class="table-wrap"><table id="grid"><thead><tr>
<th class="cmp-col">对比</th><th>排序</th><th>品类</th><th>品牌中文名</th><th>品牌英文名</th><th>型号（英文）</th>
        <th>JPY在售区间</th><th>RMB工作换算</th><th>日语搜索词</th>
        <th>拆机可搜核心件</th><th>品牌来源</th><th>开发判断</th><th>状态</th><th>备注</th>
</tr></thead><tbody></tbody></table></div>
<p class="footer">「对比」列勾选至多 3 条记录，点击工具栏「对比选中」可并排比较核心字段；对比仅基于池内静态数据，不做实时比价。品牌中文名按国内常用叫法或音译展示；正式开发前按具体日本版本、型号代际、PSE/电波法/药机法等认证、商标和平台规则复核。整机含电池的设备只是不开发电池本身。</p>
<div id="cmpModal" class="cmp-modal" hidden><div class="cmp-box" id="cmpBox"></div></div>
<script>
const data=__DATA__;
const PAGE_KEY='jp-amazon-co-jp';
const store=new PoolUI.Store(PAGE_KEY,[]);
const esc=PoolUI.esc;
const el=id=>document.getElementById(id);
const search=el('search'),category=el('category'),source=el('source'),statusFilter=el('statusFilter');
const tbody=document.querySelector('#grid tbody');
function idOf(r){return [r.category,r.brandEn,r.model].join('|')}
const cmpSel=new Set();
const byId={};data.forEach(r=>{byId[idOf(r)]=r});

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
      +'<td class="cmp-col"><input type="checkbox" class="cmp-check" data-id="'+esc(id)+'" aria-label="对比"'+(cmpSel.has(id)?' checked':'')+'></td>'
      +'<td>'+esc(r.rank)+'</td>'
      +'<td>'+esc(r.category)+'</td>'
      +'<td'+bc+'>'+esc(r.brandCn)+badge+'</td>'
      +'<td'+bc+'>'+esc(r.brandEn)+'</td>'
      +'<td class="model-cell">'+esc(r.model)+'</td>'
      +'<td>'+esc(r.jpy)+'</td>'
      +'<td>'+esc(r.rmb)+'</td>'
      +'<td>'+esc(r.search)+'</td>'
      +'<td class="parts-cell">'+esc(r.parts)+'</td>'
      +'<td'+bc+'>'+esc(r.source)+'</td>'
      +'<td>'+esc(r.fit)+'</td>'
      +PoolUI.statusCellHtml(id,st)
      +PoolUI.noteCellHtml(id,store.note(id))
      +'</tr>';
  }).join(''):'<tr class="empty-row"><td colspan="14">没有符合当前筛选条件的记录</td></tr>';
  PoolUI.setCount(out.length,data.length,store.marked());
}
function refilter(){PoolUI.withFocusKept(render)}
function updateCmpBar(){const b=el('cmpBtn');b.textContent='对比选中（'+cmpSel.size+'/3）';b.disabled=cmpSel.size===0;}
tbody.addEventListener('change',e=>{
  const cb=e.target;
  if(!cb.classList||!cb.classList.contains('cmp-check'))return;
  const id=cb.dataset.id;
  if(cb.checked){
    if(cmpSel.size>=3){cb.checked=false;alert('最多同时对比 3 条记录');return;}
    cmpSel.add(id);
  }else{cmpSel.delete(id);}
  updateCmpBar();
});
el('cmpClear').addEventListener('click',()=>{cmpSel.clear();document.querySelectorAll('.cmp-check').forEach(x=>x.checked=false);updateCmpBar();});
el('cmpBtn').addEventListener('click',()=>{
  if(!cmpSel.size)return;
  const recs=[...cmpSel].map(id=>byId[id]).filter(Boolean);
  const fields=[
    ['品类',r=>r.category],
    ['品牌',r=>r.brandCn+' / '+r.brandEn],
    ['型号（英文）',r=>r.model],
    ['JPY在售区间',r=>r.jpy],
    ['RMB工作换算',r=>r.rmb],
    ['日语搜索词',r=>r.search],
    ['拆机可搜核心件',r=>r.parts],
    ['品牌来源',r=>r.source],
    ['开发判断',r=>r.fit]
  ];
  let h='<h3>数据对比（'+recs.length+' 条）</h3><table><thead><tr><th>字段</th>'
    +recs.map(r=>'<th>'+esc(r.brandEn)+'</th>').join('')+'</tr></thead><tbody>';
  fields.forEach(f=>{h+='<tr><td class="cmp-field">'+esc(f[0])+'</td>'+recs.map(r=>'<td>'+esc(f[1](r))+'</td>').join('')+'</tr>';});
  h+='</tbody></table><p class="footer" style="margin-top:10px">对比基于池内静态数据，不做实时比价；价格区间为公开搜索页可见在售价。</p>'
    +'<button class="ghost cmp-close" type="button" id="cmpClose">关闭对比</button>';
  el('cmpBox').innerHTML=h;
  el('cmpModal').hidden=false;
  el('cmpClose').addEventListener('click',()=>{el('cmpModal').hidden=true;});
});
el('cmpModal').addEventListener('click',e=>{if(e.target===el('cmpModal'))el('cmpModal').hidden=true;});
PoolUI.bindTable(tbody,store,{onStatus:()=>{PoolUI.setCount(document.querySelectorAll('#grid tbody tr:not(.empty-row)').length,data.length,store.marked());if(statusFilter.value)refilter()},onNote:()=>PoolUI.setCount(document.querySelectorAll('#grid tbody tr:not(.empty-row)').length,data.length,store.marked())});
[search].forEach(x=>x.addEventListener('input',refilter));
[category,source,statusFilter].forEach(x=>x.addEventListener('change',refilter));
el('resetStatus').addEventListener('click',()=>{if(!confirm('清空本页所有状态与备注？该操作不可撤销。'))return;store.clear([]);search.value='';category.value='';source.value='';statusFilter.value='';render()});
render();
updateCmpBar();
</script>
</body></html>
'@

$html = $template.Replace('__CSS__', $css.Trim()).
                  Replace('__DATA__', $json).
                  Replace('__DATE__', (Get-Date -Format 'yyyy-MM-dd')).
                  Replace('__FLOOR__', [string]$jpyFloor)

Set-Content -LiteralPath $out -Value $html -Encoding utf8
Write-Output "已生成：$out"
Write-Output "记录数：$($kept.Count)"
