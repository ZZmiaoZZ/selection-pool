$ErrorActionPreference = 'Stop'

$dir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$out = Join-Path $dir 'AL波兰站选品池.html'
# 可选：生成后再把同一份页面复制到其他目录（留空 = 不复制）。
# 例如：$Mirrors = @('D:\mirror\AL波兰站选品池.html')
$Mirrors = @()

# 排除规则（要求 4）：耗材、电池、电源适配器、纯装饰件不进池。
# 波兰站使用 PLN 且不套用美国站 200 美元门槛，低价抛货下限单独按 PLN 设定。
$plnFloor = 200
$excludeKeyword = @(
  '耗材','滤芯','滤网','滤棉','刀片','喷嘴','墨盒','碳带','拖布','尘袋','清洁剂',
  '电池','电芯','锂电','battery',
  '电源适配器','充电器','适配器','电源线','数据线','charger','adapter',
  '装饰件','贴纸','贴膜','外观件','灯带','装饰灯','纯装饰'
)

# 价格、近期购买人数和评价来自 2026-09-02 Allegro.pl 可见搜索结果；“近期购买”不是后台完整销量。
$dataJson = @'
[
  {"category":"扫地机器人","brandCn":"追觅","brandEn":"Dreame","model":"L40 Ultra AE","price":"1549 PLN","search":"Dreame L40 Ultra AE robot sprzątający","parts":"主控板、激光雷达/视觉模组、轮组电机、齿轮箱、风机、泵、污水箱总成、充电触点板（电池不做）","domestic":"中国国内保有量高；波兰官方店和多报价","source":"中国品牌/出口","supply":"高","fit":"优先型号专用运动、泵阀、充电和底座功能件；不做滤芯、拖布、尘袋和装饰件"},
  {"category":"扫地机器人","brandCn":"追觅","brandEn":"Dreame","model":"X50 Ultra Complete","price":"2749 PLN","search":"Dreame X50 Ultra Complete robot sprzątający","parts":"主控板、激光雷达、升降/越障机构电机、轮组电机、风机、泵、污水箱总成、基站控制板（电池不做）","domestic":"中国高端扫地机保有量高；波兰高价多报价","source":"中国品牌/出口","supply":"高","fit":"优先越障机构、泵阀、控制板和基站结构；不做滤芯、拖布、尘袋和装饰件"},
  {"category":"扫地机器人","brandCn":"石头科技","brandEn":"Roborock","model":"Qrevo 5AE","price":"1149 PLN","search":"Roborock Qrevo 5AE robot sprzątający","parts":"主控板、激光雷达、轮组电机、泵、风机、基站控制板、污水箱总成、充电触点板（电池不做）","domestic":"中国国内用户和维修生态强；波兰官方店销量信号强","source":"中国品牌/出口","supply":"高","fit":"优先主控、泵阀、轮组和基站功能总成；不做滤芯、拖布、尘袋和装饰件"},
  {"category":"扫地机器人","brandCn":"石头科技","brandEn":"Roborock","model":"Qrevo Edge 5V1","price":"1599 PLN","search":"Roborock Qrevo Edge 5V1","parts":"主控板、边刷/轮组电机、齿轮箱、泵、风机、基站控制板、污水箱总成和充电触点板（电池不做）","domestic":"中国高端扫地机用户多；波兰多报价和近期购买","source":"中国品牌/出口","supply":"高","fit":"优先运动、泵阀、基站和控制板；不做滤芯、拖布、尘袋和装饰件"},
  {"category":"扫地机器人","brandCn":"科沃斯","brandEn":"Ecovacs","model":"DEEBOT X9 PRO OMNI","price":"1761 PLN","search":"Ecovacs DEEBOT X9 PRO OMNI","parts":"主控板、导航/视觉模组、轮组电机、风机、泵、基站控制板、污水箱总成和充电触点板（电池不做）","domestic":"中国智能清洁用户和供应链成熟；波兰有官方/企业卖家","source":"中国品牌/出口","supply":"高","fit":"优先导航、轮组、泵和基站功能件；不做滤芯、拖布、尘袋和装饰件"},
  {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Neo 2 Fly More Combo","price":"1598 PLN","search":"DJI Neo 2 Fly More Combo dron","parts":"飞控板、云台/相机模组、图传板、无刷电机、电调、GPS/视觉定位板、遥控器主板（电池不做）","domestic":"中国航拍用户和维修生态强；波兰户外影像渠道活跃","source":"中国品牌/出口","supply":"高","fit":"优先云台、相机、飞控和起落架功能件；不做桨叶、电池、充电器和装饰件"},
  {"category":"无人机","brandCn":"大疆","brandEn":"DJI","model":"Neo Motion Fly More Combo","price":"1739 PLN","search":"DJI Neo Motion Fly More Combo","parts":"飞控板、云台相机模组、图传板、无刷电机、电调、视觉定位板和遥控器主板（电池不做）","domestic":"中国出口主流航拍品牌；波兰 FPV/户外用户使用","source":"中国品牌/出口","supply":"高","fit":"优先云台、飞控、图传和保护结构；不做桨叶、电池、充电器和装饰件"},
  {"category":"3D打印机","brandCn":"拓竹","brandEn":"Bambu Lab","model":"P1S Combo with AMS","price":"2559.50 PLN","search":"Bambu Lab P1S Combo AMS drukarka 3D","parts":"主板、运动控制板、步进电机、挤出机总成、热床控制板、屏幕、导轨/丝杆、AMS驱动板和传感器","domestic":"中国创客和打印农场用户多；波兰打印店和教育渠道使用","source":"中国品牌/出口","supply":"高","fit":"优先主板、AMS驱动、挤出机、导轨和腔体锁止；不做喷嘴、耗材、打印片和装饰件"},
  {"category":"3D打印机","brandCn":"拓竹","brandEn":"Bambu Lab","model":"P1S","price":"1899 PLN","search":"Bambu Lab P1S drukarka 3D","parts":"主板、运动控制板、步进电机、挤出机总成、热床控制板、屏幕、导轨/丝杆和传感器","domestic":"中国出口品牌，国内维修件供应链密集；波兰多企业卖家","source":"中国品牌/出口","supply":"高","fit":"优先运动控制、挤出和腔体功能件；不做喷嘴、耗材、打印片和装饰件"},
  {"category":"3D打印机","brandCn":"创想三维","brandEn":"Creality","model":"K1C","price":"1499 PLN","search":"Creality K1C drukarka 3D","parts":"主板、运动控制板、步进电机、挤出机、热床控制板、屏幕、导轨/丝杆、摄像头和限位传感器","domestic":"中国用户和维修配件市场大；波兰创客用户保有量高","source":"中国品牌/出口","supply":"高","fit":"优先主板、挤出机、运动和腔体结构；不做喷嘴、耗材、打印片和装饰件"},
  {"category":"3D打印机","brandCn":"创想三维","brandEn":"Creality","model":"K1 MAX","price":"2149 PLN","search":"Creality K1 MAX drukarka 3D","parts":"主板、运动控制板、步进电机、挤出机、热床控制板、屏幕、导轨/丝杆、摄像头和传感器","domestic":"中国大尺寸打印机用户和供应链强；波兰专业用户使用","source":"中国品牌/出口","supply":"高","fit":"优先主控、运动、挤出和摄像头功能件；不做喷嘴、耗材、打印片和装饰件"},
  {"category":"电动滑板车","brandCn":"九号","brandEn":"Segway-Ninebot","model":"F3 Pro","price":"2685 PLN","search":"Segway Ninebot F3 Pro hulajnoga","parts":"主控器、轮毂电机、仪表显示板、转向柱折叠机构、刹车执行器、加速度/霍尔传感器和车架组件（电池不做）","domestic":"中国城市用户和维修生态强；波兰通勤和户外用户使用","source":"中国品牌/出口","supply":"高","fit":"优先控制器、仪表、折叠锁止和制动功能件；不做电池、充电器、轮胎耗材和装饰件"},
  {"category":"电动滑板车","brandCn":"九号","brandEn":"Segway-Ninebot","model":"ZT3 Pro D","price":"2839.99 PLN","search":"Segway Ninebot ZT3 Pro D","parts":"主控器、轮毂电机、仪表板、转向/折叠机构、刹车执行器、传感器和车架总成（电池不做）","domestic":"中国高性能电动滑板车用户多；波兰高价通勤和越野渠道","source":"中国品牌/出口","supply":"高","fit":"优先控制、转向、制动和车架功能件；不做电池、充电器、轮胎和装饰件"},
  {"category":"投影仪","brandCn":"小米","brandEn":"Xiaomi","model":"Smart Projector L1 Pro","price":"1059.49 PLN","search":"Xiaomi Smart Projector L1 Pro","parts":"主板/逻辑板、DMD/光机组件、LED驱动板、风扇、镜头调节机构、遥控接收板和散热风道（电源板仅拆机件）","domestic":"中国家庭影音用户多；波兰智能家居和投影渠道有售","source":"中国品牌/出口","supply":"高","fit":"优先光机散热、镜头调节、安装和控制板功能件；不做灯泡、装饰件和通用适配器"},
  {"category":"投影仪","brandCn":"安克星云（安克创新）","brandEn":"Nebula","model":"Capsule 3 D2425","price":"1698.99 PLN","search":"Anker Nebula Capsule 3 D2425 projektor","parts":"主板、DLP光机、LED驱动板、风扇、镜头/云台机构、遥控接收板和散热结构（电池不做）","domestic":"安克创新中国出口品牌；波兰便携投影用户使用","source":"中国品牌/出口","supply":"高","fit":"优先光机、云台/镜头、散热和安装结构；不做电池、灯泡、适配器和装饰件"},
  {"category":"投影仪","brandCn":"安克星云（安克创新）","brandEn":"Nebula","model":"Capsule 3 300 ANSI","price":"2390 PLN","search":"Anker Nebula Capsule 3 300 ANSI","parts":"主板、DLP/光机组件、LED驱动板、风扇、镜头机构、遥控接收板和散热风道（电池不做）","domestic":"中国出口品牌，国内影音用户熟悉；波兰企业卖家多报价","source":"中国品牌/出口","supply":"高","fit":"优先型号专用光机、散热和安装结构；不做电池、适配器、灯泡和装饰件"},
  {"category":"除湿机","brandCn":"美的","brandEn":"Midea","model":"MDDF-20DEN7-QA3","price":"359.99 PLN","search":"Midea MDDF-20DEN7-QA3 osuszacz","parts":"主控板、显示板、风机电机、风轮、温湿度传感器、压缩机启动模块、排水泵、水箱和脚轮底座","domestic":"中国国内家电保有量极高；波兰有Midea/Comfee同平台机型","source":"中国品牌/出口","supply":"高","fit":"优先主控、风机、传感器、排水和结构件；不做冷媒、滤网耗材、适配器和装饰件"},
  {"category":"除湿机","brandCn":"美的/科慕菲","brandEn":"Comfee","model":"MDDF-16DEN7-WF 16L","price":"249.99 PLN","search":"Comfee MDDF-16DEN7-WF osuszacz","parts":"主控板、显示板、风机电机、温湿度传感器、压缩机启动模块、排水泵、水箱和脚轮底座","domestic":"美的系中国供应链；波兰家用除湿机有多报价","source":"中国品牌/出口","supply":"高","fit":"优先排水、风机、控制和水箱结构；不做冷媒、滤网耗材和装饰件"},
  {"category":"空气净化器","brandCn":"小米","brandEn":"Xiaomi","model":"Mi Air Purifier 4 Pro","price":"869 PLN","search":"Xiaomi Mi Air Purifier 4 Pro oczyszczacz","parts":"主控板、风机电机、风轮、颗粒物/温湿度传感器板、显示板、上盖锁止和机身风道（滤芯不做）","domestic":"中国智能家居保有量高；波兰官方店和143个报价","source":"中国品牌/出口","supply":"高","fit":"优先风机、传感器、显示板、风道和底座；不做滤芯、适配器和装饰件"},
  {"category":"高压清洗机","brandCn":"卡赫","brandEn":"Kärcher","model":"K5 Power","price":"1424.94 PLN","search":"Kärcher K5 Power myjka ciśnieniowa","parts":"电机/泵总成、卸荷阀、压力开关、控制板、软管卷盘、扳机喷枪总成、热保护传感器和车架","domestic":"中国家庭和清洁设备渠道常见；波兰专业清洁保有量高","source":"海外品牌/中国制造供应链","supply":"高","fit":"优先泵、阀、压力控制、卷盘和承载件；不做喷嘴、清洁液、通用电源线和装饰件"},
  {"category":"高压清洗机","brandCn":"卡赫","brandEn":"Kärcher","model":"K7 Comfort Premium","price":"1999 PLN","search":"Kärcher K7 Comfort Premium myjka","parts":"电机/泵总成、卸荷阀、压力开关、控制板、软管卷盘、喷枪总成、热保护传感器和车架","domestic":"中国维修和OEM供应链强；波兰高端清洗设备保有量大","source":"海外品牌/中国制造供应链","supply":"高","fit":"优先高压泵、阀组、卷盘、控制和车架功能件；不做喷嘴、清洁剂和电源线"},
  {"category":"高压清洗机","brandCn":"卡赫","brandEn":"Kärcher","model":"K3 1.601-888.0","price":"393.22 PLN","search":"Kärcher K3 1.601-888.0","parts":"泵总成、卸荷阀、压力开关、控制板、软管接口、喷枪总成、热保护传感器和轮架","domestic":"中国家用清洁渠道覆盖广；波兰评价量和近期购买强","source":"海外品牌/中国制造供应链","supply":"高","fit":"优先泵阀、压力控制、喷枪和承载件；不做喷嘴、清洁液和通用电源线"},
  {"category":"湿干吸尘器/洗地机","brandCn":"添可","brandEn":"Tineco","model":"Floor ONE S7 Stretch Ultra","price":"1586.72 PLN","search":"Tineco Floor ONE S7 Stretch Ultra","parts":"主控板、吸水/真空电机、刷盘电机、水泵、污水箱总成、浮球传感器、显示板和充电触点板（电池不做）","domestic":"中国洗地机用户和维修生态成熟；波兰家用清洁渠道在售","source":"中国品牌/出口","supply":"高","fit":"优先电机、泵、污水箱、控制板和停靠底座；不做滚刷、滤网、清洁液和电池"},
  {"category":"湿干吸尘器/洗地机","brandCn":"添可","brandEn":"Tineco","model":"Floor ONE S7 Stretch Steam Plus","price":"2249.90 PLN","search":"Tineco Floor ONE S7 Stretch Steam Plus","parts":"主控板、真空电机、刷盘电机、水泵、加热器、污水箱、浮球传感器和显示板（电池不做）","domestic":"中国高端洗地机供应链强；波兰高客单型号有近期购买","source":"中国品牌/出口","supply":"高","fit":"优先蒸汽加热、泵、真空和控制总成；不做滚刷、滤网、清洁液和电池"},
  {"category":"商用安防录像机","brandCn":"海康威视","brandEn":"Hikvision","model":"DS-7608NXI-K1 8-channel","price":"552.99 PLN","search":"Hikvision DS-7608NXI-K1 rejestrator NVR","parts":"主板、PoE/端口板、硬盘背板、风扇模块、散热组件、前面板/显示板、机架固定件和接口板（硬盘/电源不做）","domestic":"中国工程安防保有量大；波兰安装商和企业卖家使用","source":"中国品牌/出口","supply":"高","fit":"优先主板、背板、端口、风扇和机架功能件；不做硬盘、电源适配器和装饰件"},
  {"category":"商用安防录像机","brandCn":"海康威视","brandEn":"Hikvision","model":"DS-7616NXI-K1 16-channel","price":"637.97 PLN","search":"Hikvision DS-7616NXI-K1 16 kanal NVR","parts":"主板、PoE/端口板、硬盘背板、风扇、散热组件、前面板、机架固定件和接口板（硬盘/电源不做）","domestic":"中国工程安防用户和维修件供应链强；波兰专业安装渠道","source":"中国品牌/出口","supply":"高","fit":"优先主板、背板、风扇、端口板和机架件；不做硬盘、电源适配器和装饰件"},
  {"category":"咖啡机","brandCn":"赛吉/铂富欧洲品牌","brandEn":"Sage (Breville)","model":"SES875BSS Barista Express","price":"2259 PLN","search":"Sage SES875BSS Barista Express ekspres","parts":"主控板、显示/按键板、泵、流量计、电磁阀、磨豆机电机/齿轮箱、加热块、温度传感器和滴水盘总成","domestic":"中国咖啡机维修和精密件供应链成熟；波兰家用咖啡用户保有量高","source":"海外品牌/中国制造供应链","supply":"高","fit":"优先泵阀、磨豆机齿轮箱、加热和控制板；不做咖啡豆、清洁片、滤芯和装饰件"},
  {"category":"高压设备/空压机","brandCn":"威沃","brandEn":"VEVOR","model":"1800W 6.8L 300 bar compressor","price":"659.60 PLN","search":"VEVOR 1800W 6.8L 300 bar compressor","parts":"压缩机电机、泵头总成、压力开关、控制板、启动电容、止回阀、调压阀组、压力传感器和散热风扇","domestic":"中国工具和工业品用户多；波兰Vevor官方店在售","source":"中国品牌/出口","supply":"高","fit":"优先泵头、电机、压力控制、阀组和机架；不做润滑油、气管耗材和通用电源线"}
]
'@

$plExtraJson = @'
[
 {"category":"割草机器人","brandCn":"库犸","brandEn":"Mammotion","model":"LUBA mini AWD 1000","price":"4,299 PLN","search":"Mammotion LUBA mini AWD kosiarka automatyczna","parts":"主控板、轮组驱动电机、切割盘电机、RTK/GPS 定位模块、超声/视觉传感器、提升机构和底盘结构件（刀片耗材不做）","domestic":"【候选类目】中国机器人割草机供应链集中；波兰独栋住宅草坪保有量大且 Home&Garden 为强势类目","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】欧洲割草机器人增速高；先核验 Allegro 在售报价与配件需求，再定型号专用件"},
 {"category":"电动自行车","brandCn":"英格威","brandEn":"ENGWE","model":"X26 / Engine X","price":"4,599 PLN","search":"ENGWE X26 rower elektryczny e-bike","parts":"主控器、轮毂/中置电机、显示仪表、扭矩传感器、变速/刹车执行机构、折叠锁止和货架（电池和充电器不做）","domestic":"【候选类目】欧洲骑行文化深厚、E-bike 销量长期领先电动汽车；波兰通勤与休闲双场景","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】EU 25km/h 合规机型才能上架；优先显示仪表、传感器和折叠结构；不做电池充电器"},
 {"category":"智能宠物设备","brandCn":"PETLIBRO","brandEn":"PETLIBRO","model":"Granary Wi-Fi Feeder / One RFID Smart Feeder","price":"449 PLN","search":"PETLIBRO karmnik automatyczny dla zwierzat Wi-Fi","parts":"主控板、称重传感器、出料电机/齿轮箱、仓体总成、RFID 识别模块和防夹结构（干燥剂耗材不做）","domestic":"【候选类目】Allegro 宠物用品为购物起点增速前列（+8）；智能喂食器客单稳定","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】波兰养宠家庭比例高；优先称重与出料结构；不做耗材"},
 {"category":"美容仪器","brandCn":"觅光","brandEn":"AMIRO","model":"R1 PRO / S1 Pro","price":"1,299 PLN","search":"AMIRO R1 PRO urzadzenie do pielegnacji twarzy RF","parts":"主控板、射频/LED 输出模组、温度传感器、探头支架、磁吸充电底座和外壳总成","domestic":"【候选类目】Allegro Health & Beauty 增速为大盘两倍；美容仪器客单高；注意 EU 医疗器械宣传边界","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】波兰面部护理设备搜索增长；优先探头结构与支架；合规前置"},
 {"category":"行车记录仪","brandCn":"70迈","brandEn":"70mai","model":"A810 / A800SE","price":"599 PLN","search":"70mai A810 rejestrator samochodowy 4K","parts":"主控板、图像传感器模组、GPS 模块、镜头座、散热结构和吸盘/静电贴支架总成（存储卡不做）","domestic":"【候选类目】Allegro 汽车用品为购物起点增长类目（+6）；记录仪前后双录套装为主力","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】波兰车险与安全驾驶需求推动；优先支架与散热件"},
 {"category":"电动工具","brandCn":"威克士","brandEn":"WORX","model":"20V Brushless Hammer Drill WX358","price":"899 PLN","search":"WORX WX358 wiertarko-wkretarka 20V bezszczotkowa","parts":"主控板、无刷电机、齿轮箱、钻夹头、电池接口板（电池不做）和机壳总成","domestic":"【候选类目】波兰 Home&Garden 强势、DIY 文化成熟；20V 无绳平台为主流","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】优先齿轮箱与夹头结构件；不做电池充电器"},
 {"category":"空气源热泵","brandCn":"美的","brandEn":"Midea","model":"M-Thermal Arctic 8 kW","price":"18,999 PLN","search":"Midea M-Thermal Arctic pompa ciepla 8kW","parts":"主控板、压缩机驱动模块、风机电机、膨胀阀/水路阀组、水温传感器、显示板和底座减振结构","domestic":"【候选类目】波兰严寒气候+能源转型补贴，热泵为政策驱动型高客单类目；中国热泵供应链全球领先","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】需安装服务商体系支撑；优先水路阀组、传感器和电控件；EU F-gas/Ecodesign 合规前置"},
 {"category":"安防摄像套装","brandCn":"睿联","brandEn":"Reolink","model":"RLC-810A + RLN8-410 8CH Kit","price":"1,399 PLN","search":"Reolink RLC-810A zestaw kamer RLN8-410 8 kanalow","parts":"PoE 主板、镜头/IR 补光模组、防水壳体、壁装支架和 NVR 背板（硬盘与电源不做）","domestic":"【候选类目】波兰住宅与中小商户安防需求稳定；PoE 套装在 Allegro 多报价","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】优先支架、防水壳和背板件；不做硬盘电源"},
 {"category":"阳台光伏/微逆变器","brandCn":"正浩","brandEn":"EcoFlow","model":"PowerStream 600W + 400W panel","price":"3,499 PLN","search":"EcoFlow PowerStream mikroinstalacja balkonowa 600W","parts":"微逆变器主板、MPPT 控制板、并网通信模块、散热壳体、壁挂支架和防水接插件（组件线缆不做）","domestic":"【候选类目】波兰电价高企推动阳台/庭院即插即用光伏；EU 净计量政策逐步放开","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】NC RfG 并网认证与安装规范前置；优先散热、支架和通信件"},
 {"category":"睡眠健康设备","brandCn":"SnoreCircle","brandEn":"SnoreCircle","model":"BA10 / YA4300","price":"599 PLN","search":"SnoreCircle urzadzenie antychrap inteligentne","parts":"主控板、骨传导/压电传感模组、EMS 微电流模块、充电触点和亲肤头带结构（凝胶贴耗材不做）","domestic":"【候选类目】美欧睡眠经济高增（止鼾面罩/呼吸训练器增速快）；中国代工供应链成熟","source":"中国品牌/出口","supply":"待核","fit":"【候选类目】波兰与欧洲中老年人群渗透率低、空间大；优先传感与佩戴结构；不做耗材"}
]
'@

$plFitnessJson = @'
[
 {"category":"家庭健身","brandCn":"速境","brandEn":"Speediance","model":"Gym Monster 2 / Gym Monster 3","price":"8,999–10,999 PLN","search":"Speediance Gym Monster siłownia domowa","parts":"PMSM 电机总成、线缆滑轮系统、数字阻力控制板、触屏总成（拆机件）、导轨/滑块结构和配件接口件","domestic":"官方 EU 独立站明确覆盖波兰，智能数字力量头部品牌，IFA2026 全欧主推","source":"中国品牌/出口","supply":"高","fit":"免订阅智能力量训练，客单极高；优先触屏、线缆滑轮与配件接口件；大件需 EU 仓履约核验"},
 {"category":"家庭健身","brandCn":"金史密斯/WalkingPad","brandEn":"KingSmith","model":"A1 Pro / R2 Pro / R3","price":"1,899–3,499 PLN","search":"WalkingPad R2 Pro bieżnia spacerowa składana","parts":"折叠铰链/锁止总成、跑台滚筒、无刷电机总成、脚感控速传感器、遥控通信板和减振底座","domestic":"折叠走步机欧洲线上渗透快，波兰居家健身搜索上行","source":"中国品牌/出口","supply":"待核","fit":"走步机品类定义者；优先折叠铰链与滚筒件；需核 Allegro 在售报价与 EU 仓"},
 {"category":"家庭健身","brandCn":"优瑞沃","brandEn":"UREVO","model":"CyberPad / 2-in-1 Folding Treadmill","price":"1,499–2,899 PLN","search":"UREVO CyberPad bieżnia pod biurko","parts":"折叠机构、跑台滚筒、无刷电机、脚感/霍尔传感器、控制板和减振底座","domestic":"欧洲为 UREVO 高增市场，办公场景走步机适配居家办公人群","source":"中国品牌/出口","supply":"待核","fit":"Under-desk 场景差异化；优先折叠与传感件；需核 Allegro 在售"},
 {"category":"家庭健身","brandCn":"野小兽","brandEn":"Yesoul","model":"S3 Bike / R1 Rower","price":"1,299–2,499 PLN","search":"Yesoul S3 rower treningowy","parts":"磁控阻力总成、飞轮轴承、皮带传动组件、触屏通信板（仅拆机件）、车架调节锁止和踏板曲柄","domestic":"Yesoul 设欧洲直播中心，德英澳重点盘，波兰属 EU 覆盖半径","source":"中国品牌/出口","supply":"待核","fit":"车+课智能单车；优先磁阻与传动件；需核 Allegro 在售与内容本地化"}
]
'@
$raw = @(@($dataJson | ConvertFrom-Json) + @($plExtraJson | ConvertFrom-Json) + @($plFitnessJson | ConvertFrom-Json))

function Test-Excluded {
    param($row)
    # 只在品类和型号上做硬排除；「不做电池」这类说明性文字不算命中
    $target = @([string]$row.category, [string]$row.model) -join ' '
    foreach ($kw in $script:excludeKeyword) {
        if ($target -match [regex]::Escape($kw)) { return "命中排除关键词：$kw" }
    }
    $m = [regex]::Match([string]$row.price, '([\d,]+(?:\.\d+)?)')
    if ($m.Success) {
        $v = [double](($m.Groups[1].Value) -replace ',', '')
        if ($v -lt $script:plnFloor) { return ("低价抛货：{0} PLN 低于下限 {1} PLN" -f $v, $script:plnFloor) }
    }
    return $null
}

$data = New-Object System.Collections.ArrayList
foreach ($r in $raw) {
    $why = Test-Excluded -row $r
    if ($why) { Write-Output ("已剔除 {0} {1}｜{2}" -f $r.brandEn, $r.model, $why); continue }
    [void]$data.Add($r)
}

for ($i = 0; $i -lt $data.Count; $i++) { $data[$i] | Add-Member -NotePropertyName rank -NotePropertyValue ($i + 1) -Force }
$json = @($data) | ConvertTo-Json -Depth 8 -Compress
$json = $json -replace '</', '<\/'

$template = @'
<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AL波兰站选品池</title>
<style>
:root{font-family:"Microsoft YaHei",Arial,sans-serif;color:#172033;background:#f4f7fb}
*{box-sizing:border-box}
body{margin:0;padding:24px}
h1{font-size:26px;margin:0 0 8px}
.note{color:#536176;line-height:1.65;margin:0 0 16px}
.legend{display:flex;gap:8px;flex-wrap:wrap;margin:0 0 14px}
.legend span{padding:5px 9px;border-radius:4px;font-size:12px;font-weight:700}
.ok{background:#dcfce7;color:#166534}
.wait{background:#fef3c7;color:#92400e}
.export{background:#fff1f2;color:#b91c1c;border-left:3px solid #dc2626}
.toolbar{display:flex;gap:9px;flex-wrap:wrap;align-items:center;background:#fff;border:1px solid #d7e0ec;padding:12px;margin-bottom:14px}
input,select,button{font:inherit;border:1px solid #b8c6d8;padding:8px 10px;border-radius:5px;background:#fff;color:#172033}
button{cursor:pointer}
table{border-collapse:collapse;width:100%;background:#fff;font-size:12.5px}
th{background:#132238;color:#fff;padding:9px 8px;text-align:left;white-space:nowrap}
td{border:1px solid #d7e0ec;padding:8px;vertical-align:top;line-height:1.45}
.footer{margin-top:18px;color:#6b778a;font-size:12px}
</style>
<!--FINAL-UI-ASSETS-->
</head><body>
<h1>AL波兰站选品池</h1>
<p class="note">更新日期：__DATE__。筛选原则是“国内有保有量、波兰/欧洲也有真实使用或销售、且中国能找到型号专用拆机件/功能件”。优先中国品牌和中国制造供应链；价格使用 PLN，不设美国站 200 美元门槛，但低于 __FLOOR__ PLN 的整机按低价抛货剔除。Allegro 页面数据来自当前可见搜索结果中的报价、评价和“osób kupiło ostatnio”（近期购买）提示，不等同于后台完整销量。已排除耗材、电池、电源适配器、纯装饰件和低价抛货。</p>
<div class="legend"><span class="export">中国品牌 / 出口（红色加粗 + 中国角标）</span></div>
<div class="toolbar">
<input id="search" placeholder="搜索品牌、英文型号、品类、波兰语词、拆机件…">
<select id="category"><option value="">全部品类</option></select>
<select id="source"><option value="">全部品牌来源</option><option value="中国品牌/出口">中国品牌 / 出口</option><option value="海外品牌/中国制造供应链">海外品牌 / 中国制造供应链</option></select>
<select id="supply"><option value="">全部配件可得性</option><option value="高">高</option><option value="中">中</option><option value="待核">待核</option></select>
<select id="statusFilter"><option value="">全部状态</option><option value="未处理">未处理</option><option value="掌握了">掌握了</option><option value="不做">不做</option><option value="待定">待定</option></select>
<button id="resetStatus" class="ghost" type="button">清空状态与备注</button>
<span id="count"></span>
</div>
<div class="table-wrap"><table id="grid"><thead><tr>
<th>排序</th><th>品类</th><th>品牌中文名</th><th>品牌英文名</th><th>型号（英文）</th>
        <th>Allegro在售价</th><th>Allegro搜索词</th>
        <th>拆机/替换升级件</th><th>国内外使用判断</th><th>品牌来源</th><th>替换件可得性</th>
        <th>状态</th><th>备注</th>
</tr></thead><tbody></tbody></table></div>
<p class="footer">品牌中文名按国内常用叫法或音译展示；正式开发前按具体 EU 版本、型号代际、专利、认证、商标和平台规则复核。整机含电池的设备只是不开发电池本身。</p>
<script>
const data=__DATA__;
const PAGE_KEY='poland-allegro';
const store=new PoolUI.Store(PAGE_KEY,[]);
const esc=PoolUI.esc;
const el=id=>document.getElementById(id);
const search=el('search'),category=el('category'),source=el('source'),supply=el('supply'),statusFilter=el('statusFilter');
const tbody=document.querySelector('#grid tbody');
function idOf(r){return [r.category,r.brandEn,r.model].join('|')}
function isCn(r){return /^中国/.test(String(r.source))}
PoolUI.mountChrome({home:'index.html'});
const cats=[...new Set(data.map(r=>r.category))].sort((a,b)=>a.localeCompare(b,'zh-CN'));
category.innerHTML+=cats.map(c=>'<option value="'+esc(c)+'">'+esc(c)+'</option>').join('');
function shownCount(){return document.querySelectorAll('#grid tbody tr:not(.empty-row)').length}
function render(){
  const q=search.value.trim().toLowerCase(),c=category.value,src=source.value,sp=supply.value,sf=statusFilter.value;
  const out=data.filter(r=>{
    const st=store.status(idOf(r));
    return (!q||Object.values(r).some(v=>String(v).toLowerCase().includes(q)))
      &&(!c||r.category===c)&&(!src||r.source===src)
      &&(!sp||r.supply===sp)&&(!sf||st===sf);
  });
  tbody.innerHTML=out.length?out.map(r=>{
    const id=idOf(r),st=store.status(id),cn=isCn(r),bc=cn?' class="brand-export"':'',badge=cn?PoolUI.cnBadge():'';
    return '<tr class="'+PoolUI.rowClass(st)+'">'
      +'<td>'+esc(r.rank)+'</td>'
      +'<td>'+esc(r.category)+'</td>'
      +'<td'+bc+'>'+esc(r.brandCn)+badge+'</td>'
      +'<td'+bc+'>'+esc(r.brandEn)+'</td>'
      +'<td class="model-cell">'+esc(r.model)+'</td>'
      +'<td>'+esc(r.price)+'</td>'
      +'<td>'+esc(r.search)+'</td>'
      +'<td class="parts-cell">'+esc(r.parts)+' ｜ '+esc(r.fit)+'</td>'
      +'<td>'+esc(r.domestic)+'</td>'
      +'<td'+bc+'>'+esc(r.source)+'</td>'
      +'<td>'+esc(r.supply)+'</td>'
      +PoolUI.statusCellHtml(id,st)
      +PoolUI.noteCellHtml(id,store.note(id))
      +'</tr>';
  }).join(''):'<tr class="empty-row"><td colspan="13">没有符合当前筛选条件的记录</td></tr>';
  PoolUI.setCount(out.length,data.length,store.marked());
}
function refilter(){PoolUI.withFocusKept(render)}
PoolUI.bindTable(tbody,store,{
  onStatus:()=>{PoolUI.setCount(shownCount(),data.length,store.marked());if(statusFilter.value)refilter()},
  onNote:()=>PoolUI.setCount(shownCount(),data.length,store.marked())
});
search.addEventListener('input',refilter);
[category,source,supply,statusFilter].forEach(x=>x.addEventListener('change',refilter));
el('resetStatus').addEventListener('click',()=>{if(!confirm('清空本页所有状态与备注？该操作不可撤销。'))return;store.clear([]);search.value='';category.value='';source.value='';supply.value='';statusFilter.value='';render()});
render();
</script>
</body></html>
'@
$html = $template.Replace('__DATA__', $json).
                  Replace('__DATE__', (Get-Date -Format 'yyyy-MM-dd')).
                  Replace('__FLOOR__', [string]$plnFloor)

Set-Content -LiteralPath $out -Value $html -Encoding utf8
Write-Output "已生成：$out"
Write-Output "记录数：$($data.Count)"

foreach ($m in $mirrors) {
    $md = Split-Path -Parent $m
    if (Test-Path -LiteralPath $md) {
        Set-Content -LiteralPath $m -Value $html -Encoding utf8
        Write-Output "已同步：$m"
    }
}
