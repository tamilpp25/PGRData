---V2.13 小岛&宿舍躲猫猫
local XLevelScript1041 = XDlcScriptManager.RegLevelLogicScript(1041, "XLevelLogicScript1041")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

-- 脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript1041:Ctor(proxy)
    self._proxy = proxy
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self._timer = Timer.New()
    self._playerCount = 0                                                     --记录玩家人数
    self._mouseCount = 0                                                      --记录老鼠人数
    self._spawnPoint = {}                                                     --记录出生点(1-9对应编辑器配置点)
    self._spawnRotation = { 0, 0, 0 }
    self._itemPoint = {}                                                      --记录道具生成点
    self._campList = {}                                                       --记录玩家序号对应的阵营（1猫2鼠）
    self._campDictionary = {}                                                 --字典：记录玩家UUID对应的阵营（1猫2鼠）
    self._playerIdDictionary = {}                                             --字典：记录玩家UUID对应的PlayerId
    self._statusDictionary = {}                                               --字典：记录玩家UUID对应的在线状态（1在线2退出3掉线4老鼠提前结算后退出）

    self._spawnPointList = {}                                                 --记录玩家序号对应的出生点位序号
    self._isCaughtDictionary = {}                                             --记录玩家是否被捕（初始填入0，老鼠被捕则改成1）
    self._catchCount = {}                                                     --记录猫的捕鼠数量(UUID对应数量)
    self._levelTime = 0                                                       --关卡时间
    self._timeMemory = 0                                                      --计时用

    self._hitHiddenMouseCount = {}                                            --字典：记录捕获隐身鼠次数
    self._campDict = {}                                                       --**********************记录玩家ID阵营

    self._scanCount = {}                                                      --*****字典：技能-记录使用 “扫描” 次数---原本技能--改buff-1900080--旧传值ID-7
    self._shapeShiftCount = {}                                                --***********字典：记录使用 “变身” 次数--已经弃用
    self._hiddenCount = {}                                                    --***********字典：记录使用 “隐身” 次数--已经弃用--改用新得道具隐身
    self._perspectiveCount = {}                                               --****字典：技能-记录使用 “透视” 次数---原本技能--改buff--1900083--旧传值ID-10
    self._checkPositionCount = {}                                             --******字典：技能-记录使用 “标注位置” 次数---新版技能--1900081-对应传值ID-22
    self._itemBoxCount = {}                                                   --*******字典：技能-记录使用 “道具箱” 次数---新版技能--1900082-对应传值ID-23
    self._improveTeamSpeedCount = {}                                               --******字典：技能-记录使用 “提升全队移速” 次数---新版技能--1900084-对应传值ID-24
    self._transportBeaconCount = {}                                                --******字典：技能-记录使用 “传送信标” 次数---新版技能--1900085-对应传值ID-25

    self._finalBuffForCat = true                                            --用来给猫阵营在最后30秒修改技能冷却BUFF的开关

    self._catNumber = 0                                                          --***********************猫猫出生点位记录
    self._mouseNumber = 0                                                        --***********************鼠鼠出生点位记录

    self._drinkJuiceCount = {}                                                --************************字典：记录使用“饮料”次数--1900060-对应传值ID-15
    self._putCatchMouseCount = {}                                             --************************字典：记录使用“捕鼠夹”次数--1900061-对应传值ID-16
    self._fastSpeedCount = {}                                                 --************************字典：记录使用“冲刺”次数--1900063-对应传值ID-17
    self._launchMissileCount = {}                                             --************************字典：记录使用“导弹”次数--1900064-对应传值ID-18
    self._invisibleBodyCount = {}                                             --************************字典：记录使用“隐身”次数替换老版隐身 --1900021-旧传值ID-9
    self._fixedScanCount = {}                                                 --************************字典：记录使用“固定扫描”次数--1900066-对应传值ID-19
    self._launchHookCount = {}                                                --************************字典：记录使用“钩锁”次数--1900068-对应传值ID-20
    self._launchFishnetCount = {}                                             --************************字典：记录使用“渔网”次数--1900070-对应传值ID-21

    self._reserveOptions1041 = { 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 } --老鼠的变身选项列表小岛场景（不需要了，程序会读配置表）
    self._reserveOptions1051 = { 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 }     --老鼠的变身选项列表宿舍场景（不需要了，程序会读配置表）
    self._reserveOptions1061 = { 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38 } --老鼠的变身选项列表超市场景（不需要了，程序会读配置表）
    self._obj01Bed = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }                       --记录场景物件ID
    self._obj02Umbrella = { 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 }
    self._obj03SwimRing = { 22, 23, 24, 25, 26, 27 }
    self._obj04Chair = { 28, 29, 30, 31, 32 }
    self._obj05Boat = { 33, 34, 35, 36, 37, 38 }
    self._obj06Stereo = { 39, 40 }
    self._obj07Ballon = { 41, 42, 43, 44 }
    self._obj08Grill = { 45, 46, 47, 48 }
    self._obj09Ball = { 49, 50, 51, 52 }
    self._obj10SandCastle = { 53, 54, 55, 56 }
    self._obj11Duck = { 57, 58, 59, 60, 61, 62 }
    self._obj01Sofa = { 100004, 100005, 100006, 100007, 100008, 100009 }
    self._obj02Table = { 100010, 100011, 100012, 100013, 100014, 100015 }
    self._obj03Stool = { 100016, 100017, 100018, 100019, 100020, 100021, 100022, 100023, 100024, 100025, 100026, 100027, 100028, 100029, 100030 }
    self._obj04Macaron = { 100031, 100032, 100033, 100034, 100035, 100036, 100037, 100038, 100039, 100040, 100041, 100042 }
    self._obj05Cabinet = { 100043, 100044, 100045, 100046, 100047, 100048, 100049 }
    self._obj06Fence = { 100050, 100051 }
    self._obj07Trees = { 100052, 100053, 100054, 100055, 100056, 100057, 100058, 100059, 100060, 100061, 100062, 100063, 100064, 100065, 100066, 100067, 100068, 100069, 100070, 100071, 100072, 100073, 100074, 100075 }

    self._obj01Brand = { 19, 20, 21, 22, 23, 24, 25, 26, 27, 28 }                                  --**************商场场景中 广告牌随机隐藏列表 数量*10
    self._obj02Car = { 29, 30, 31, 32, 33, 34, 35 }                                                --**************商场场景中 小货车随机隐藏列表 数量*7
    self._obj03Basket = { 36, 37, 38, 39, 40, 41, 42, 43, 44 }                                     --**************商场场景中 购物篮随机隐藏列表 数量*9
    self._obj04ShoppingCar = { 45, 46, 47, 48, 49, 50, 51, 52, 53 }                                --**************商场场景中 购物车随机隐藏列表 数量*9
    self._obj05PayMachine = { 54, 55, 56, 57, 58 }                                                 --**************商场场景中 自动付款机隐藏列表 数量*5
    self._obj06Bucket = { 59, 60, 61, 62, 63, 64, 65, 66, 67 }                                     --**************商场场景中 水桶随机隐藏列表 数量*9
    self._obj07TrashCan = { 68, 69, 70, 71, 72, 73, 74, 75, }                                      --**************商场场景中 垃圾桶随机隐藏列表 数量*8


    self._catCount = 0          --记录当前在场猫的数量
    self._liveCount = 0         --记录当前存活老鼠数量
    self._totalCount = 0        --记录老鼠总量（死活都算）
    self._scoreMouseCal = 0     --计算活到当前的老鼠分数
    self._scoreList = {}        --存放玩家分数(UUID对应分数)
    self._liveTimeList = {}     --记录各老鼠最终存活时间
    self._isBattleBegin = false --是否对战阶段开始
    self._isEnd = false         --是否已结算
    self._deathZoneId = 0       --死区的triggerID

    self._scorePerSecond1 = 10  --老鼠存活每秒得分，第一阶段
    self._scorePerSecond2 = 25  --老鼠存活每秒得分，第二阶段
    self._scoreCatch1 = 800     --猫抓到第1只老鼠得分
    self._scoreCatch2 = 800     --猫抓到第2只老鼠得分
    self._scoreCatch3 = 800     --猫抓到第3只老鼠得分
    self._scoreCatch4 = 800     --猫抓到第4只老鼠得分
    self._scoreCatch5 = 800     --猫抓到第5只老鼠得分
    self._scoreCatch6 = 800     --猫抓到第6只老鼠得分
    self._scoreCatch7 = 800     --猫抓到第7只老鼠得分
    self._scoreCatCatch = { self._scoreCatch1, self._scoreCatch2, self._scoreCatch3, self._scoreCatch4, self
        ._scoreCatch5, self._scoreCatch6, self._scoreCatch7 }
    self._settleTime = 20                                                  --准备阶段限定时间
    self._phase2Time = 91                                                  --对战阶段限定时间
    self._phase3Time = 90                                              --最终阶段限定时间
    self._missileTime = 0                                                 --*******************开始生成道具时间
    self._missileDelayTime = 25                                            --*******************道具生成延迟时间
    self._isLaunchMissile = false                                          --*******************是否生成道具子弹
    self._isLaunchTipsMissile = false                                      --*******************是否生成道具子弹光柱
    self._tipsMissileLauncher = 0                                          --*******************负责发射道具子弹光柱的玩家UUID
    self._endTime = self._settleTime + self._phase2Time + self._phase3Time --关卡限时
    self._battleTime = 0                                                   --记录对战阶段的时间

    self._fxItemSpring = 200027                                            --弹跳点特效
    self._fxSpringing = 200028                                             --弹跳点触发特效
    self._fxTriangleGreen = 200029                                         --头顶标识特效-蓝
    self._fxTriangleRed = 200030                                           --头顶标识特效-红
    self._fxCatWhiskers = 200031                                           --猫胡须特效
    self._fxMouseWhiskers = 200032                                         --鼠胡须特效
    self._fxCatHat = 200033                                                --猫阵营头套特效
    self._fxMouseHat = 200034                                              --鼠阵营头套特效
end

-- 初始化
function XLevelScript1041:Init()
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger) --事件注册：触发器
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)   --事件注册：npc加buff
    self._proxy:RegisterEvent(EWorldEvent.MissileDead)  --***************************************************************添加道具拾取事件

    --拿到玩家列表
    self._playerNpcContainer:Init(function(npc, index)
        self:InitialPlayerSet(npc, index)
    end)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID(1041小岛，1051宿舍)
    self._campDict = self._proxy:MouseHunterGetCatCampIndex()    --玩家阵营读取
    self:InitPhase()
    self._playerCount = self._proxy:GetPlayerCount()             --统计进来的玩家人数
    self._campList = self:CampRandomNew(self._playerCount)       --生成随机阵营列表
    self._spawnPointList = self:SpawnPointRandom(self._campList) --分配并记录玩家序号对应的出生点序号

    self._proxy:SetFloatConfig("JumpGravity", -35)                   -- 设置跳跃重力
    self._proxy:SetFloatConfig("FreeFallGravity", -35)    --设置自由落体重力
    self._proxy:SetFloatConfig("JumpSpeed", 10.5)                -- 设置跳跃速度
    self._proxy:SetFloatConfig("IdleJumpSpeed", 1.8)             -- 设置站立时跳跃向前速度
    self._proxy:SetFloatConfig("MoveJumpSpeed", 3.3)             -- 设置移动时跳跃向前速度
    if self._levelId == 1041 then
        for i = 1, 9 do
            self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的出生点，1~3是猫，4~10是鼠
        end
        for i = 1, 5 do                                     --***********************************************新改动 道具点位改为5个
            local index = i + 9
            self._itemPoint[i] = self._proxy:GetSpot(index) --获取配置好的道具生成点，关卡编辑器中点位ID是10~19
        end
        self._deathZoneId = 63
        self._catNumber = 1
        self._mouseNumber = 4
    elseif self._levelId == 1051 then
        for i = 100001, 100010 do
            self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的出生点，1~3是猫，4~10是鼠
        end
        for i = 1, 5 do                                     --******************************************************************新改动道具点位改为5个
            local index = i + 100009
            self._itemPoint[i] = self._proxy:GetSpot(index) --获取配置好的道具生成点，关卡编辑器中点位ID是10~19
        end
        self._deathZoneId = 100003
        self._catNumber = 100001
        self._mouseNumber = 100004
    elseif self._levelId == 1061 then                       --********************新地图商场得出生点和道具点设置
        XLog.Debug("判断成功是新地图")
        for i = 1, 9 do
            self._spawnPoint[i] = self._proxy:GetSpot(i) --获取关卡编辑器中配置好的出生点，1~3是猫，4~9是鼠
        end
        XLog.Debug("新地图出生点设置完毕")
        for i = 1, 5 do
            local index = i + 9
            self._itemPoint[i] = self._proxy:GetSpot(index) --获取配置好的道具生成点，关卡编辑器中点位ID是10~19
        end
        XLog.Debug("新地图道具点设置完毕")
        self._deathZoneId = 77                        --**************************场景下方检测区域（玩家掉入立即将玩家传送回场景）
        self._catNumber = 1
        self._mouseNumber = 4
    end
    if self._levelId == 1041 then
        self:RandomHideObj(self._obj01Bed, 7)
        self:RandomHideObj(self._obj02Umbrella, 6)
        self:RandomHideObj(self._obj03SwimRing, 4)
        self:RandomHideObj(self._obj04Chair, 4)
        self:RandomHideObj(self._obj05Boat, 4)
        self:RandomHideObj(self._obj06Stereo, 1)
        self:RandomHideObj(self._obj07Ballon, 2)
        self:RandomHideObj(self._obj08Grill, 2)
        self:RandomHideObj(self._obj09Ball, 2)
        self:RandomHideObj(self._obj10SandCastle, 2)
        self:RandomHideObj(self._obj11Duck, 4)            
        self._proxy:MouseHunterSetSkillCD(1,10)               --扫描
        self._proxy:MouseHunterSetSkillCD(2,60)               --标注位置
        self._proxy:MouseHunterSetSkillCD(3,10)               --捕兽夹
        self._proxy:MouseHunterSetSkillCD(4,25)               --全体加速  
        self._proxy:MouseHunterSetSkillCD(5,16)               --道具箱
        self._proxy:MouseHunterSetSkillCD(6,0.5)              --传送信标一段
        self._proxy:MouseHunterSetSkillCD(7,30)               --传送信标二段 返回
    elseif self._levelId == 1051 then
        self:RandomHideObj(self._obj01Sofa, 3)
        self:RandomHideObj(self._obj02Table, 3)
        self:RandomHideObj(self._obj03Stool, 8)
        self:RandomHideObj(self._obj04Macaron, 6)
        self:RandomHideObj(self._obj05Cabinet, 3)
        self:RandomHideObj(self._obj06Fence, 1)
        self:RandomHideObj(self._obj07Trees, 12)
        self._proxy:MouseHunterSetSkillCD(1,10)               --扫描
        self._proxy:MouseHunterSetSkillCD(2,50)               --标注位置
        self._proxy:MouseHunterSetSkillCD(3,10)               --捕兽夹
        self._proxy:MouseHunterSetSkillCD(4,25)               --全体加速  
        self._proxy:MouseHunterSetSkillCD(5,16)               --道具箱
        self._proxy:MouseHunterSetSkillCD(6,0.5)              --传送信标一段
        self._proxy:MouseHunterSetSkillCD(7,30)               --传送信标二段 返回
    elseif self._levelId == 1061 then                            --********************新增商场地图物体随机显隐逻辑
        self:RandomHideObj(self._obj01Brand, 5)
        self:RandomHideObj(self._obj02Car, 4)
        self:RandomHideObj(self._obj03Basket, 3)
        self:RandomHideObj(self._obj04ShoppingCar, 4)
        self:RandomHideObj(self._obj05PayMachine, 2)
        self:RandomHideObj(self._obj06Bucket, 3)
        self:RandomHideObj(self._obj07TrashCan, 4)  
        self._proxy:MouseHunterSetSkillCD(1,10)               --扫描
        self._proxy:MouseHunterSetSkillCD(2,50)               --标注位置
        self._proxy:MouseHunterSetSkillCD(3,10)               --捕兽夹
        self._proxy:MouseHunterSetSkillCD(4,25)               --全体加速  
        self._proxy:MouseHunterSetSkillCD(5,16)               --道具箱
        self._proxy:MouseHunterSetSkillCD(6,0.5)              --传送信标一段
        self._proxy:MouseHunterSetSkillCD(7,30)               --传送信标二段 返回         
    end
    XLog.Debug("关卡log_初始化完毕 关卡ID是" .. self._levelId)

end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript1041:HandleEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    if (eventType == EWorldEvent.ActorTrigger) then
        XLog.Debug("有trigger被触发了")
        if (eventArgs.HostSceneObjectPlaceId == self._deathZoneId and eventArgs.TriggerState == 1) then
            XLog.Debug("死区被触发")
            if self._levelId == 1041 then
                self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._spawnPoint[math.random(1, 9)],
                    self._spawnRotation, true)
            elseif self._levelId == 1051 then
                self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._spawnPoint[math.random(100001, 100010)],
                    self._spawnRotation,
                    true)
            elseif self._levelId == 1061 then                       --********************值待定新场景玩家掉入死区传回去
                self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._spawnPoint[math.random(1, 9)],
                    self._spawnRotation,
                    true)
            end
        end
    elseif (eventType == EWorldEvent.NpcAddBuff) then
        --XLog.Debug("有buff被添加" .. eventArgs.BuffTableId)
        local npc = eventArgs.NpcUUID
        if (eventArgs.BuffTableId == 1900008 and self._isCaughtDictionary[npc] == 0) then
            XLog.Debug(npc .. "这只老鼠被捕了")
            self._liveCount = self._liveCount - 1
            self._proxy:SetPlayerMouseCount(self._liveCount, self._totalCount) --设置老鼠数量
            self._isCaughtDictionary[npc] = 1                                  --在字典中标注这个UUID被捕
            self._proxy:SetLevelMemoryInt(4002, 2)                             --4002用于区别开战UI还是被捕UI
            self._proxy:ApplyMagic(npc, npc, 200036, 1)                        --专门给鼠的UI设置
            self._proxy:SettlePlayer(npc, false)                               --被捕老鼠的提前结算
            --提前结算老鼠的数据
            local player = self._playerIdDictionary[npc]
            self._proxy:SetFightResultCustomData(player, 3, self._scoreList[npc])         --任意阵营，单局内分数 Score = 3
            self._proxy:SetFightResultCustomData(player, 1, 2)                            --单局内玩家所在的阵营 1猫阵营 2鼠阵营 Camp = 1
            self._proxy:SetFightResultCustomData(player, 8, self._shapeShiftCount[npc])   --鼠阵营，累计使用变身次数  ShapeShiftCount = 8
            self._proxy:SetFightResultCustomData(player, 9, self._invisibleBodyCount[npc])--*********鼠阵营，改动变量累计使用隐身次数  invisibleBodyCount = 9
            self._proxy:SetFightResultCustomData(player, 10, self._perspectiveCount[npc]) --鼠阵营，累计使用透视次数     PerspectiveCount = 10
            self._proxy:SetFightResultCustomData(player, 12, self._liveTimeList[npc])     --鼠阵营，单局内用于结算的存活时间 SettleSurviveTime = 12
            self._proxy:SetFightResultCustomData(player, 11, 0)                           --鼠阵营，单局内是否存活到结束 0否 1是 IsSurvive = 11
            self._proxy:SetFightResultCustomData(player, 14, 0)                           --任意阵营，是否是Mvp 0否 1是 IsMvp = 14
            --**********鼠鼠得新版本技能
            self._proxy:SetFightResultCustomData(player, 24, self._improveTeamSpeedCount[npc]) --************鼠阵营，提升全队速度 improveTeamSpeedCount = 24
            self._proxy:SetFightResultCustomData(player, 25, self._transportBeaconCount[npc])  --*****************鼠阵营，传送信标 transportBeaconCount = 25
            self._proxy:SetFightResultCustomData(player, 23, self._itemBoxCount[npc])         --*****鼠阵营，使用技能-道具箱 itemBoxCount = 23
            --*********鼠鼠得新道具
            self._proxy:SetFightResultCustomData(player, 15, self._drinkJuiceCount[npc])     --*****************鼠阵营，使用饮料 drinkJuiceCount = 15
            self._proxy:SetFightResultCustomData(player, 17, self._fastSpeedCount[npc])  --*****************鼠阵营，使用冲刺 fastSpeedCount = 17
            self._proxy:SetFightResultCustomData(player, 18, self._launchMissileCount[npc])  --*****************鼠阵营，使用炸弹 launchMissileCount = 18
            

            local cat = eventArgs.CasterUUID                                              --拿到抓捕此只老鼠的猫
            XLog.Debug(cat .. "这只猫抓到了老鼠")
            if self._scoreList[cat] == nil then
                XLog.Error(string.format("cat score  not found, [cat:%d]", cat))
                self._scoreList[cat] = 0
            end
            local newCatchCount = self._catchCount[cat] + 1
            local scoreDelta = self._scoreCatCatch[newCatchCount]
            if scoreDelta == nil then
                XLog.Error(string.format("cat score delta not found, [newCatchCount:%d]", newCatchCount))
                scoreDelta = 0
            end
            self._scoreList[cat] = self._scoreList[cat] + scoreDelta --根据抓到第几只老鼠给分
            if self._proxy:CheckBuffByKind(npc, 1900022) then        --如果鼠是隐身，则记录猫对应的成就
                self._hitHiddenMouseCount[cat] = 1
                XLog.Debug(cat .. "这只猫抓到了隐身老鼠")
            end
            self._proxy:SetMouseHunterPlayerScore(cat, self._scoreList[cat]) --设置分数UI显示
            self._catchCount[cat] = self._catchCount[cat] + 1
            self._proxy:SetCatHuntCount(cat, self._catchCount[cat])          --设置捕鼠数量UI显示
            self._proxy:SetLevelMemoryInt(4004, 2)                           --4004用于区别开战UI还是抓捕UI
            self._proxy:ApplyMagic(cat, cat, 200035, 1)                      --专门给猫的UI设置
        elseif (eventArgs.BuffTableId == 1900080) then                       --*****************猫-扫描开始逻辑改buff
            self._scanCount[npc] = self._scanCount[npc] + 1
            XLog.Debug(npc .. "这只猫使用了扫描技能")
        elseif (eventArgs.BuffTableId == 1900023) then --鼠-隐身buff         
            self._hiddenCount[npc] = self._hiddenCount[npc] + 1             
        elseif (eventArgs.BuffTableId == 10086) then        --*****************猫-透视开始逻辑改buff
            self._perspectiveCount[npc] = self._perspectiveCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900051) then --鼠-变身
            self._shapeShiftCount[npc] = self._shapeShiftCount[npc] + 1
        
        elseif (eventArgs.BuffTableId == 1900081) then        --***********技能使用--标注位置
            self._checkPositionCount[npc] = self._checkPositionCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900084) then        --***********技能使用--道具箱
            self._itemBoxCount[npc] = self._itemBoxCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900083) then        --***********技能使用--提升全队速度
            self._improveTeamSpeedCount[npc] = self._improveTeamSpeedCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900085) then        --***********技能使用--传送信标
            self._transportBeaconCount[npc] = self._transportBeaconCount[npc] + 1

        elseif (eventArgs.BuffTableId == 1900060) then        --***********道具使用--饮料
            self._drinkJuiceCount[npc] = self._drinkJuiceCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900082) then        --***********道具使用--捕鼠夹
            self._putCatchMouseCount[npc] = self._putCatchMouseCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900063) then        --***********道具使用--冲刺
            self._fastSpeedCount[npc] = self._fastSpeedCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900064) then        --***********道具使用--炸弹
            self._launchMissileCount[npc] = self._launchMissileCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900021) then        --***********道具使用--隐身
            self._invisibleBodyCount[npc] = self._invisibleBodyCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900066) then        --***********道具使用--固定扫描
            self._fixedScanCount[npc] = self._fixedScanCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900068) then        --***********道具使用--钩锁
            self._launchHookCount[npc] = self._launchHookCount[npc] + 1
        elseif (eventArgs.BuffTableId == 1900070) then        --***********道具使用--渔网
            self._launchFishnetCount[npc] = self._launchFishnetCount[npc] + 1
        end
    elseif (eventType == EWorldEvent.MissileDead) then                      --****************************开始获取到有子弹死亡
        --XLog.Debug("子弹死亡了" .. eventArgs.MissileUUID)
        local key = self._proxy:MouseHunterGetItemKey(eventArgs.MissileUUID) --******************************获取死亡得子弹KEY是多少
        if key >= 1 and key <= 5 then
            local pos = self._itemPoint[key]
            --XLog.Debug("捡到道具了" .. key .. "(" .. pos.x .. pos.y .. pos.z .. ")")
            self._timer:Schedule(self._missileDelayTime, self._proxy, function()
                self._proxy:GenerateMouseHunterItem(key, self._itemPoint[key])
            end)
        end
    end
end

-- 每帧执行
---@param dt number @ delta time
function XLevelScript1041:Update(dt)
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    if self._isBattleBegin == true then
        self._battleTime = self._battleTime + dt --记录对战阶段的时间
    end

    --老鼠存活分计算
    if (self._isBattleBegin == true) and (self._isEnd == false) then
        if (self._battleTime - self._timeMemory) >= 1 then
            if self._currentPhase == 1 then
                self._scoreMouseCal = self._scoreMouseCal + self._scorePerSecond1
            elseif self._currentPhase == 3 then
                self._scoreMouseCal = self._scoreMouseCal + self._scorePerSecond2
            end
            for _, npc in pairs(self._playerNpcList) do
                local camp = self._campDictionary[npc]
                if camp == 2 and self._isCaughtDictionary[npc] == 0 then             --未被捕的老鼠
                    self._scoreList[npc] = self._scoreMouseCal                       --把分数记录到字典内
                    self._proxy:SetMouseHunterPlayerScore(npc, self._scoreMouseCal)  --设置分数
                    self._proxy:SetMouseAliveTime(npc, math.floor(self._battleTime)) --设置老鼠存活时间UI显示
                    self._liveTimeList[npc] = math.floor(self._battleTime)           --更新存活时间存值
                end
            end
            self._timeMemory = self._battleTime
        end
    end

    if self._playerNpcList == nil then
        XLog.Debug("玩家列表为空,再次获取!!!")
        self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    end

    --玩家在线，退出，掉线状态判断
    for npc, camp in pairs(self._campDictionary) do
        if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 and not self._proxy:CheckNpc(npc) then --在线，掉线转为退出
            if camp == 1 then
                self._statusDictionary[npc] = 2
                XLog.Debug(npc .. "这只猫退出了")
                self._catCount = self._catCount - 1 --猫退出，记录一下数量
            elseif camp == 2 then
                if self._isCaughtDictionary[npc] == 1 then
                    self._statusDictionary[npc] = 4
                    XLog.Debug(npc .. "这只已被捕老鼠退出了")
                else
                    self._statusDictionary[npc] = 2
                    XLog.Debug(npc .. "这只老鼠退出了")
                    self._liveCount = self._liveCount - 1
                    self._proxy:SetPlayerMouseCount(self._liveCount, self._totalCount) --设置老鼠数量
                    self._isCaughtDictionary[npc] = 1                                  --在字典中标注这个UUID被捕
                end
            end
        elseif self._statusDictionary[npc] == 1 and self._proxy:CheckNpcIsDisconnect(npc) then
            self._statusDictionary[npc] = 3
            if camp == 1 then
                XLog.Debug(npc .. "这只猫掉线了")
            elseif camp == 2 then
                XLog.Debug(npc .. "这只老鼠掉线了")
            end
        elseif self._statusDictionary[npc] == 3 and not self._proxy:CheckNpcIsDisconnect(npc) then
            self._statusDictionary[npc] = 1
            if camp == 1 then
                XLog.Debug(npc .. "这只猫断线重连了")
            elseif camp == 2 then
                XLog.Debug(npc .. "这只老鼠断线重连了")
            end
        end
    end
    self:OnUpdatePhase(dt)
end

function XLevelScript1041:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    --UI显示（准备阶段）注意记战斗时间断线重连
    self._proxy:SetLevelMemoryInt(4000, 1)
    self._proxy:SetLevelMemoryInt(4001, self._settleTime)
    self._proxy:SetLevelMemoryFloat(4003, self._proxy:GetFightTime())
end

---@param dt number @ delta time
function XLevelScript1041:OnUpdatePhase(dt)         --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == 0 then
        if self._levelTime >= self._settleTime then --准备阶段计时
            XLog.Debug("准备阶段计时到，进入对战阶段")
            self._proxy:SetLevelMemoryInt(4000, 2)
            self._proxy:SetLevelMemoryInt(4001, self._phase2Time) --UI显示（对战阶段）注意记战斗时间断线重连
            self._proxy:SetLevelMemoryFloat(4003, self._proxy:GetFightTime())
            for _, npc in ipairs(self._playerNpcList) do
                self._proxy:ApplyMagic(npc, npc, 200023, 1) --UI设置buff
                --self._proxy:ApplyMagic(npc, npc, 200044, 1) 这个音效buff有问题先待定
                XLog.Debug("玩家" .. npc .. "已添加开始音效")
                if self._campDictionary[npc] == 1 then
                    self._proxy:SetLevelMemoryInt(4004, 1)      --4004用于区别开战UI还是抓捕UI
                    self._proxy:ApplyMagic(npc, npc, 200035, 1) --专门给猫的UI设置
                elseif self._campDictionary[npc] == 2 then
                    self._proxy:SetLevelMemoryInt(4002, 1)      --4002用于区别开战UI还是被捕UI
                    self._proxy:ApplyMagic(npc, npc, 200036, 1) --专门给鼠的UI设置
                end
            end
            XLog.Debug("UI设置完毕")
            if self._levelId == 1041 then
                self._proxy:SetSceneObjectActive(1, false)  --关闭猫猫门
                for i = 1, 5 do
                    self._proxy:SetObstacleActive(i, false) --关闭zone障碍
                end
            elseif self._levelId == 1051 then
                self._proxy:SetSceneObjectActive(100001, false) --关闭堵门的柜子
                self._proxy:SetSceneObjectActive(100002, false) --关闭堵门的柜子
                self._proxy:SetObstacleActive(100093, false)    --关闭zone障碍
            elseif self._levelId == 1061 then
                self._proxy:SetSceneObjectActive(17, false) --**********关闭猫猫房间门
                self._proxy:SetSceneObjectActive(18, false) --**********关闭猫猫房间门
                self._proxy:SetObstacleActive(4, false)    --**********关闭zone障碍
                self._proxy:SetObstacleActive(5, false)    --**********关闭zone障碍
                XLog.Debug("新场景开局出生门删除 障碍隐藏")
            end
            self._isBattleBegin = true                          --标记对战阶段开始
            self._currentPhase = 1
        end
    end
    if self._levelTime >= self._missileTime and self._isLaunchMissile == false then --**************************开始生成道具  
        for k, v in pairs(self._itemPoint) do
            self._proxy:GenerateMouseHunterItem(k, v)
        end
        XLog.Debug("生成道具了")
        self._isLaunchMissile = true 
    end
    if self._levelTime >= self._missileTime and self._isLaunchTipsMissile == false then --**************************开始生成道具提示子弹 
        self._tipsMissileLauncher = 0
        for index, playerNpcUUID in pairs(self._playerNpcList) do 
            if self._proxy:CheckNpc(playerNpcUUID) then 
                self._tipsMissileLauncher = playerNpcUUID
                break
            end
        end
        if self._tipsMissileLauncher > 0 then
            for k, v in pairs(self._itemPoint) do
                self._proxy:LaunchMissileFromPosToPos(self._tipsMissileLauncher, 50430124, v, v, 1)
            end
            self._isLaunchTipsMissile = true
            XLog.Debug("发射道具提示子弹完毕")              
        end
    end
    if self._currentPhase == 1 then
        if self._liveCount == 0 then --老鼠被抓完了，猫胜
            if self._isEnd == false then
                XLog.Debug("老鼠已悉数被捕,开始统一结算")
                self:FinishLevel()
                --self._timer:Schedule(0, self, self.FinishLevel)    --延迟1帧结算，防止猫的抓捕数据没拿到
                self._isEnd = true
            end
            self._currentPhase = 2
        elseif self._levelTime >= (self._settleTime + self._phase2Time) then --对战阶段计时到，进入最终阶段
            if self._isEnd == false then
                XLog.Debug("对战阶段计时到，进入最终阶段")
                self._proxy:SetLevelMemoryInt(4000, 3)
                self._proxy:SetLevelMemoryInt(4001, self._phase3Time) --UI显示（最终阶段）注意记战斗时间断线重连
                self._proxy:SetLevelMemoryFloat(4003, self._proxy:GetFightTime())
                for _, npc in ipairs(self._playerNpcList) do
                    self._proxy:ApplyMagic(npc, npc, 200023, 1)      --UI设置buff
                    if self._campDictionary[npc] == 1 and self._finalBuffForCat == true then
                        if self._proxy:CheckBuffByKind(npc, 1900098) then         --海岛地图标记BUFF         
                            self._proxy:MouseHunterSetSkillCD(1,7)               --扫描
                            self._proxy:MouseHunterSetSkillCD(2,45)               --标注位置
                            self._proxy:MouseHunterSetSkillCD(3,8)               --捕兽夹
                            XLog.Debug("海岛地图猫阵营CD强化生效")
                        elseif self._proxy:CheckBuffByKind(npc, 1900099) then     --宿舍地图标记BUFF 
                            self._proxy:MouseHunterSetSkillCD(1,10)               --扫描
                            self._proxy:MouseHunterSetSkillCD(2,42)               --标注位置
                            self._proxy:MouseHunterSetSkillCD(3,8)               --捕兽夹
                            XLog.Debug("宿舍地图猫阵营CD强化生效")
                        elseif self._proxy:CheckBuffByKind(npc, 1900100) then     --商场地图标记BUFF 
                            self._proxy:MouseHunterSetSkillCD(1,7)               --扫描
                            self._proxy:MouseHunterSetSkillCD(2,42)               --标注位置
                            self._proxy:MouseHunterSetSkillCD(3,8)               --捕兽夹 
                            XLog.Debug("商场地图猫阵营CD强化生效")  
                        end
                        self._finalBuffForCat = false                             --已经加了强化BUFF，开关关闭
                    end
                end
            end
            self._currentPhase = 3
        elseif self._catCount == 0 then
            if self._isEnd == false then
                XLog.Debug("猫已全部退出,开始统一结算")
                self:FinishLevel()
                self._isEnd = true
            end
            self._currentPhase = 2
        end
    end
    if self._currentPhase == 2 then
        if self._levelTime then
            self._currentPhase = 21
        end
    end
    if self._currentPhase == 3 then
        if self._liveCount == 0 then --老鼠被抓完了，猫胜
            if self._isEnd == false then
                XLog.Debug("老鼠已悉数被捕,开始统一结算")
                self:FinishLevel()
                --self._timer:Schedule(0, self, self.FinishLevel)  --延迟1帧结算，防止猫的抓捕数据没拿到
                self._isEnd = true
            end
        elseif self._levelTime >= self._endTime then --对战阶段计时到，老鼠胜
            if self._isEnd == false then
                XLog.Debug("关卡限时已到,开始统一结算")
                self:FinishLevel()
                self._isEnd = true
            end
            self._currentPhase = 31
        elseif self._catCount == 0 then
            if self._isEnd == false then
                XLog.Debug("猫已全部退出,开始统一结算")
                self:FinishLevel()
                self._isEnd = true
            end
            self._currentPhase = 2
        end
    end
    if self._currentPhase == 4 then
        if self._levelTime then
            self._currentPhase = 5
        end
    end
end

-- 初始玩家设置
---@param npc number
---@param index number
function XLevelScript1041:InitialPlayerSet(npc, index)
    -- 防止单机时，在self._playerNpcList未初始化情况下进行访问。
    if self._playerNpcList == nil then
        self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    end
    if self._levelId == 1041 then
        self._proxy:ApplyMagic(npc, npc, 1900098, 1) --图1-沙滩标记
    elseif self._levelId == 1051 then
        self._proxy:ApplyMagic(npc, npc, 1900099, 1) --图2-宿舍标记
    elseif self._levelId == 1061 then  
        self._proxy:ApplyMagic(npc, npc, 1900100, 1) --图3-商场标记
    else
        XLog.Debug("===这tm根本不是躲猫猫关卡!===")
    end
    local isCat = self._campDict[self._proxy:GetPlayerIdByNpc(npc)] 
    if isCat == 1 then --如果是猫，初始化处理
        XLog.Debug("uuid为" .. npc .. "的玩家是猫")
        self._proxy:SetMouseHunterPlayerCamp(npc, true)
        self._proxy:ApplyMagic(npc, npc, 1900001, 1)             --猫行为树
        self._proxy:ApplyMagic(npc, npc, 200042, 1)              --猫的阵营提示
        self._proxy:ApplyMagic(npc, npc, self._fxCatWhiskers, 1) --猫胡须特效
        self._proxy:ApplyMagic(npc, npc, self._fxCatHat, 1)      --猫阵营头套特效
        self._campDictionary[npc] = 1                            --在阵营字典里把UUID和阵营作对应
        self._catchCount[npc] = 0                                --初始化捕鼠数量
        self._proxy:SetCatHuntCount(npc, self._catchCount[npc])  --设置捕鼠数量UI显示
        self._proxy:SetNpcPosAndRot(npc, self._spawnPoint[self._catNumber], self._spawnRotation, true)  --********传送到出生位置
        self._catNumber = self._catNumber + 1
        self._catCount = self._catCount + 1
        for playerNpc, camp in pairs(self._campDictionary) do
            if camp == 2 then
                self._proxy:SetActorIgnoreCollision(npc, playerNpc, true) --玩家是猫，和已进来的鼠之间忽略碰撞
            end
        end
        

        
        XLog.Debug("uuid为" .. npc .. "的猫技能初始化完成") 
    elseif isCat == 2 then --如果是鼠，初始化处理
        XLog.Debug("uuid为" .. npc .. "的玩家是鼠")
        if self._levelId == 1041 then
            self._proxy:CreateMouseTransformOptionList(npc, {}) --变身选项列表
        elseif self._levelId == 1051 then
            self._proxy:CreateMouseTransformOptionList(npc, {}) --变身选项列表
        elseif self._levelId == 1061 then
            self._proxy:CreateMouseTransformOptionList(npc, {}) --变身选项列表  
        else
            XLog.Debug("===这tm根本不是躲猫猫关卡!===")
        end
        self._proxy:SetMouseHunterPlayerCamp(npc, false)
        self._proxy:ApplyMagic(npc, npc, 1900004, 1)               --鼠行为树
        self._proxy:ApplyMagic(npc, npc, 200043, 1)                --鼠的阵营提示
        self._proxy:ApplyMagic(npc, npc, self._fxMouseWhiskers, 1) --鼠胡须特效
        self._proxy:ApplyMagic(npc, npc, self._fxMouseHat, 1)      --鼠阵营头套特效
        self._proxy:SetNpcPosAndRot(npc, self._spawnPoint[self._mouseNumber], self._spawnRotation, true)  --********传送到出生位置
        self._mouseNumber = self._mouseNumber + 1
        self._liveCount = self._liveCount + 1
        self._totalCount = self._totalCount + 1
        self._proxy:SetPlayerMouseCount(self._liveCount, self._totalCount) --设置老鼠数量
        self._campDictionary[npc] = 2                                      --在阵营字典里把UUID和阵营作对应
        for playerNpc, camp in pairs(self._campDictionary) do
            if camp == 1 then
                self._proxy:SetActorIgnoreCollision(npc, playerNpc, true) --玩家是鼠，和已进来的猫之间忽略碰撞
            end
        end
             
    end
    XLog.Debug("玩家序号" .. index .. "出生点位" .. self._spawnPointList[index])
    self._playerIdDictionary[npc] = self._proxy:GetPlayerIdByNpc(npc)                                          --在PlayerId字典里把UUID和Id作对应
    self._isCaughtDictionary[npc] = 0                                                                          --初始化被捕状态
    self._scoreList[npc] = 0                                                                                   --初始化分数
    self._statusDictionary[npc] = 1                                                                            --标记状态为在线
    self._hitHiddenMouseCount[npc] = 0                                                                         --字典：记录捕获隐身鼠次数初始化
    self._scanCount[npc] = 0                                                                                   --字典：记录使用 “扫描” 次数初始化
    self._shapeShiftCount[npc] = 0                                                                             --字典：记录使用 “变身” 次数初始化
    self._hiddenCount[npc] = 0                                                                                 --字典：记录使用 “隐身” 次数初始化
    self._perspectiveCount[npc] = 0                                                                            --字典：记录使用 “透视” 次数初始化
    
    self._checkPositionCount[npc] = 0                                             --******字典：技能-记录使用 “标注位置” 次数---新版技能--1900081-对应传值ID-22
    self._itemBoxCount[npc] = 0                                                   --*******字典：技能-记录使用 “道具箱” 次数---新版技能--1900082-对应传值ID-23
    self._improveTeamSpeedCount[npc] = 0                                               --******字典：技能-记录使用 “提升全队移速” 次数---新版技能--1900084-对应传值ID-24
    self._transportBeaconCount[npc] = 0                                                --******字典：技能-记录使用 “传送信标” 次数---新版技能--1900085-对应传值ID-25

    self._drinkJuiceCount[npc] = 0                                                --************************字典：记录使用“饮料”次数--1900060-对应传值ID-15
    self._putCatchMouseCount[npc] = 0                                             --************************字典：记录使用“捕鼠夹”次数--1900061-对应传值ID-16
    self._fastSpeedCount[npc] = 0                                                 --************************字典：记录使用“冲刺”次数--1900063-对应传值ID-17
    self._launchMissileCount[npc] = 0                                             --************************字典：记录使用“导弹”次数--1900064-对应传值ID-18
    self._invisibleBodyCount[npc] = 0                                             --************************字典：记录使用“隐身”次数替换老版隐身--1900021-旧传值ID-9
    self._fixedScanCount[npc] = 0                                                 --************************字典：记录使用“固定扫描”次数--1900066-对应传值ID-19
    self._launchHookCount[npc] = 0                                                --************************字典：记录使用“钩锁”次数--1900068-对应传值ID-20
    self._launchFishnetCount[npc] = 0                                             --************************字典：记录使用“渔网”次数--1900070-对应传值ID-21

    self._proxy:SetMouseHunterPlayerScore(npc, self._scoreList[npc])                                           --设置分数UI显示
    self._proxy:ApplyMagic(npc, npc, 200023, 1)                                                                --UI显示指令

    --[[if self._levelId == 1041 then --海岛图忽略zone障碍
        for i = 1, 3 do
            self._proxy:SetNpcIgnoreObstacle(npc, i, true)
        end
    end--]]
    if self._levelId == 1051 then --宿舍图忽略zone障碍
        for i = 100001, 100093 do
            self._proxy:SetNpcIgnoreObstacle(npc, i, true)
        end
    elseif self._levelId == 1061 then --**************************&&&&&&&&&&&&&&&&&&&&&&&&&&&&商场图忽略障碍待补充细化
        for i = 17, 72 do
            self._proxy:SetNpcIgnoreObstacle(npc, i, true)
        end
    end
end

--根据人数随机阵营
---@param playerCount number
function XLevelScript1041:CampRandom(playerCount)
    local randomNum = {}       --放随机数
    local num = 0              --存随机数
    local campList = {}        --输出的阵营列表
    math.randomseed(os.time()) --随机种子

    --制造一个和人数一样长度的table，先都标记为2（鼠）
    repeat
        table.insert(campList, 2)
    until #campList == playerCount

    --如果是8-9人，则roll出3个猫，5~7出2,3~4出1
    if playerCount == 9 or playerCount == 8 then
        XLog.Debug("人数是" .. playerCount)
        for i = 1, 3 do
            repeat
                num = math.random(playerCount)
            until not self:IsTableContained(num, randomNum) --不重复
            table.insert(randomNum, i, num)                 --写入randomNum
        end
        self._mouseCount = playerCount - 3                  --记录老鼠数
    elseif playerCount == 7 or playerCount == 6 or playerCount == 5 then
        XLog.Debug("人数是" .. playerCount)
        for i = 1, 2 do
            repeat
                num = math.random(playerCount)
            until not self:IsTableContained(num, randomNum) --不重复
            table.insert(randomNum, i, num)                 --写入randomNum
        end
        self._mouseCount = playerCount - 2                  --记录老鼠数
    elseif playerCount == 4 or playerCount == 3 then
        XLog.Debug("人数是" .. playerCount)
        repeat
            num = math.random(playerCount)
        until not self:IsTableContained(num, randomNum) --不重复
        table.insert(randomNum, 1, num)                 --写入randomNum
        self._mouseCount = playerCount - 1              --记录老鼠数
    else
        XLog.Debug("人数不是3~9,就1号当猫吧")
        table.insert(randomNum, 1, 1)      --写入randomNum
        self._mouseCount = playerCount - 1 --记录老鼠数
    end
    for _, value in ipairs(randomNum) do
        campList[value] = 1 --序号为value的玩家标记为1（猫）
    end
    for index, value in ipairs(campList) do
        XLog.Debug(index .. "号玩家的阵营是" .. value)
    end
    return campList
end

--根据人数随机阵营（新）
---@param playerCount number
function XLevelScript1041:CampRandomNew(playerCount)
    local campList = {} --输出的阵营列表
    --制造一个和人数一样长度的table，先都标记为2（鼠）
    repeat
        table.insert(campList, 2)
    until #campList == playerCount
    --如果是8-9人，则roll出3个猫，5~7出2,3~4出1
    if playerCount == 9 or playerCount == 8 then
        if self._levelId == 1041 or self._levelId == 1061 then
            for i = 1, 3 do
                campList[i] = 1
            end
            self._mouseCount = playerCount - 3 --记录老鼠数
        elseif self._levelId == 1051 then
            for i = 1, 2 do
                campList[i] = 1
            end
            self._mouseCount = playerCount - 2 --记录老鼠数
        end
    elseif playerCount == 7 or playerCount == 6 or playerCount == 5 then
        for i = 1, 2 do
            campList[i] = 1
        end
        self._mouseCount = playerCount - 2 --记录老鼠数
    elseif playerCount == 4 or playerCount == 3 then
        campList[1] = 1
        self._mouseCount = playerCount - 1 --记录老鼠数
    else
        XLog.Debug("人数不是3~9,就1号当猫吧")
        campList[1] = 1
        self._mouseCount = playerCount - 1 --记录老鼠数
    end
    for index, value in ipairs(campList) do
        XLog.Debug(index .. "号玩家阵营是" .. value)
    end
    return campList
end

--根据阵营列表随机分配出生点
function XLevelScript1041:SpawnPointRandom(campList)
    local spawnPointList = {}                               --输出的点位表
    local catNo = (self._levelId == 1041 or self._levelId == 1061) and 1 or 100001   --用于点位分配(编辑器配置中1-3点位给猫)
    local mouseNo = (self._levelId == 1041 or self._levelId == 1061) and 4 or 100004 --用于点位分配(编辑器配置中4-9点位给鼠)
    for index, value in ipairs(campList) do
        if value == 1 then
            table.insert(spawnPointList, index, catNo) --记录玩家index对应点位index
            catNo = catNo + 1
        elseif value == 2 then
            table.insert(spawnPointList, index, mouseNo) --记录玩家index对应点位index
            mouseNo = mouseNo + 1
        else
            XLog.Debug("出现不明生物" .. index)
        end
    end
    return spawnPointList
end

--检查table数组中是否包含某值
---@param x number
---@param table table
function XLevelScript1041:IsTableContained(x, table)
    for _, value in ipairs(table) do
        if value == x then
            return true
        end
    end
    return false
end

--把分数数组排序并转成排名字典
---@param scoreList table
---@param scoreDictionary table
function XLevelScript1041:Sort(scoreList, scoreDictionary)
    local rankList = {}
    for i = 1, #scoreList do
        for j = 1, (#scoreList - i) do
            if scoreList[j + 1] > scoreList[j] then
                local temp = scoreList[j]
                scoreList[j] = scoreList[j + 1]
                scoreList[j + 1] = temp
            end
        end
    end
    for key, value in ipairs(scoreList) do
        XLog.Debug("排名第" .. key .. "的分数是" .. value)
    end
    for npc, score in pairs(scoreDictionary) do
        for rank, score_2 in ipairs(scoreList) do
            if score == score_2 then
                rankList[npc] = rank --npcID对应名次，同分者同名次
                break
            end
        end
    end
    for key, value in pairs(rankList) do
        XLog.Debug("玩家:" .. key .. "排名:" .. value)
    end
    return rankList
end

--检查表中是否有多个第n名
---@param table table
---@param num number
function XLevelScript1041:HasDuplicates(table, num)
    local seen = 0
    for _, value in pairs(table) do
        if value == num then
            if seen > 0 then
                XLog.Debug("存在并列第" .. num)
                return true
            else
                seen = seen + 1
            end
        end
    end
    return false
end

--随机隐藏场景物件
---@param list table
---@param num number
function XLevelScript1041:RandomHideObj(list, num)
    math.randomseed(os.time()) --随机种子
    if num == 1 then
        self._proxy:SetSceneObjectActive(list[math.random(#list)], false)
    else
        for i = 1, num do
            self._proxy:SetSceneObjectActive(list[math.random(#list)], false)
        end
    end
end

-- 关卡结束
function XLevelScript1041:FinishLevel()
    --把猫鼠分数分开算排名
    local listCat = {}                          --用于存数组
    local listMouse = {}
    local scoreDictionaryCat = {}               --猫鼠的分数字典分开
    local scoreDictionaryMouse = {}
    for npc, score in pairs(self._scoreList) do --把分数塞到数组里
        if (self._statusDictionary[npc] == 2) or (self._statusDictionary[npc] == 3) then
            score = 0                           --如果掉线或退出，则分数为0
        end
        if self._campDictionary[npc] == 1 then
            table.insert(listCat, score)
            scoreDictionaryCat[npc] = score
        elseif self._campDictionary[npc] == 2 then
            table.insert(listMouse, score)
            scoreDictionaryMouse[npc] = score
        end
    end
    local rankCat = self:Sort(listCat, scoreDictionaryCat)       --猫阵营排名字典
    local rankMouse = self:Sort(listMouse, scoreDictionaryMouse) --鼠阵营排名字典
    local hasDuplicatesCat = self:HasDuplicates(rankCat, 1)      --猫阵营是否有并列第1
    local hasDuplicatesMouse = self:HasDuplicates(rankMouse, 1)  --鼠阵营是否有并列第1

    for npc, player in pairs(self._playerIdDictionary) do
        --通用传值
        if (self._statusDictionary[npc] == 2) or (self._statusDictionary[npc] == 3) then
            self._proxy:SetFightResultCustomData(player, 3, 0)                    --如果掉线或退出，则分数为0
        else
            self._proxy:SetFightResultCustomData(player, 3, self._scoreList[npc]) --任意阵营，单局内分数 Score = 3
        end
        --猫阵营传值
        if self._campDictionary[npc] == 1 then
            if self._liveCount == 0 then
                self._proxy:SetFightResultCustomData(player, 2, 1) --单局内胜利的阵营 1猫阵营 2鼠阵营 WinCamp = 2 这里是将阵营传值给2 确定哪个阵营为获胜方
                if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 and self._proxy:CheckNpc(npc) then
                    self._proxy:SettlePlayer(npc, true)
                end
            else
                self._proxy:SetFightResultCustomData(player, 2, 2) --单局内胜利的阵营 1猫阵营 2鼠阵营 WinCamp = 2 这里是将阵营传值给2 确定哪个阵营为获胜方
                if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 and self._proxy:CheckNpc(npc) then
                    self._proxy:SettlePlayer(npc, false)
                end
            end
            self._proxy:SetFightResultCustomData(player, 1, 1)                                --单局内玩家所在的阵营 1猫阵营 2鼠阵营 Camp = 1
            self._proxy:SetFightResultCustomData(player, 13, rankCat[npc])                    --任意阵营，结算的排名 Rank = 13
            self._proxy:SetFightResultCustomData(player, 6, self._hitHiddenMouseCount[npc])   --猫阵营，单局内击中隐身状态的敌对阵营的次数 HitHiddenMouseCount = 6
            self._proxy:SetFightResultCustomData(player, 7, self._scanCount[npc])             --猫阵营，累计使用扫描n次 ScanCount = 7
            --********此次猫猫新增技能传值--标注位置和道具箱
            self._proxy:SetFightResultCustomData(player, 22, self._checkPositionCount[npc])   --*****猫阵营，使用技能-标记位置 HitHiddenMouseCount = 22
            self._proxy:SetFightResultCustomData(player, 16, self._putCatchMouseCount[npc])   --*****************猫阵营，使用捕鼠夹 putCatchMouseCount = 16
            --********此次猫猫新增道具传值--饮料 捕鼠夹 冲刺 固定扫描 钩锁 渔网
            self._proxy:SetFightResultCustomData(player, 15, self._drinkJuiceCount[npc])      --*****************猫阵营，使用饮料 drinkJuiceCount = 15
            self._proxy:SetFightResultCustomData(player, 17, self._fastSpeedCount[npc])       --*****************猫阵营，使用冲刺 fastSpeedCount = 17
            self._proxy:SetFightResultCustomData(player, 20, self._launchHookCount[npc])      --*****猫阵营，使用钩锁 HitHiddenMouseCount = 20
            self._proxy:SetFightResultCustomData(player, 21, self._launchFishnetCount[npc])   --*****猫阵营，使用渔网 launchFishnetCount = 21


            XLog.Debug(npc .. "这只猫使用了" .. self._scanCount[npc] .. "次扫描技能")
            local isMvp = 0
            if rankCat[npc] == 1 and not hasDuplicatesCat then
                if self._scoreList[npc] ~= 0 and self._statusDictionary[npc] == 1 then
                    isMvp = 1
                    XLog.Debug("这只猫的分数是:", self._scoreList[npc], "获得了MVP")
                end
            end
            if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 then
                self._proxy:ApplyMagic(npc, npc, 200046, 1)         --“游戏结束”UI
                self._proxy:ApplyMagic(npc, npc, 200045, 1)         --游戏结束音效
            end
            self._proxy:SetFightResultCustomData(player, 14, isMvp) --任意阵营，是否是Mvp 0否 1是 IsMvp = 14

            if self._catchCount[npc] == self._mouseCount then
                self._proxy:SetFightResultCustomData(player, 4, 1) --猫阵营，单局内是否抓捕所有敌对阵营 0否 1是 IsCatchAllMouse = 4
            else
                self._proxy:SetFightResultCustomData(player, 4, 0)
            end
            self._proxy:SetFightResultCustomData(player, 5, self._catchCount[npc]) --猫阵营，单局内抓捕老鼠玩家的次数(淘汰玩家次数) CatchMouseCount = 5
            --鼠阵营传值
        elseif self._campDictionary[npc] == 2 then
            if self._liveCount == 0 then
                self._proxy:SetFightResultCustomData(player, 2, 1) --单局内胜利的阵营 1猫阵营 2鼠阵营 WinCamp = 2
                if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 then
                    self._proxy:SettlePlayer(npc, false)
                end
            else
                self._proxy:SetFightResultCustomData(player, 2, 2) --单局内胜利的阵营 1猫阵营 2鼠阵营 WinCamp = 2
                if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 then
                    self._proxy:SettlePlayer(npc, true)
                end
            end
            self._proxy:SetFightResultCustomData(player, 1, 2)                            --单局内玩家所在的阵营 1猫阵营 2鼠阵营 Camp = 1
            self._proxy:SetFightResultCustomData(player, 8, self._shapeShiftCount[npc])   --鼠阵营，累计使用变身次数  ShapeShiftCount = 8
            self._proxy:SetFightResultCustomData(player, 9, self._invisibleBodyCount[npc])--******已修改为最新得隐身变量---鼠阵营，累计使用隐身次数  HiddenCount = 9
            self._proxy:SetFightResultCustomData(player, 13, rankMouse[npc])              --任意阵营，结算的排名 Rank = 13
            self._proxy:SetFightResultCustomData(player, 10, self._perspectiveCount[npc]) --鼠阵营，累计使用透视次数     PerspectiveCount = 10
            self._proxy:SetFightResultCustomData(player, 12, self._liveTimeList[npc])     --鼠阵营，单局内用于结算的存活时间 SettleSurviveTime = 12
            --*************此次鼠鼠新增技能传值
            self._proxy:SetFightResultCustomData(player, 24, self._improveTeamSpeedCount[npc]) --************鼠阵营，提升全队速度 improveTeamSpeedCount = 24
            self._proxy:SetFightResultCustomData(player, 25, self._transportBeaconCount[npc])  --*****************鼠阵营，传送信标 transportBeaconCount = 25
            self._proxy:SetFightResultCustomData(player, 23, self._itemBoxCount[npc])         --*****鼠阵营，使用技能-道具箱 itemBoxCount = 23
            --*********鼠鼠得新道具
            self._proxy:SetFightResultCustomData(player, 15, self._drinkJuiceCount[npc])     --*****************鼠阵营，使用饮料 drinkJuiceCount = 15
            self._proxy:SetFightResultCustomData(player, 17, self._fastSpeedCount[npc])      --*****************鼠阵营，使用冲刺 fastSpeedCount = 17
            self._proxy:SetFightResultCustomData(player, 18, self._launchMissileCount[npc])  --*****************鼠阵营，使用炸弹 launchMissileCount = 18
            local isAlive = 0
            if self._isCaughtDictionary[npc] == 1 then
                isAlive = 0
            else
                isAlive = 1
            end
            if self._statusDictionary[npc] ~= 2 and self._statusDictionary[npc] ~= 4 then
                self._proxy:ApplyMagic(npc, npc, 200046, 1)           --“游戏结束”UI
                self._proxy:ApplyMagic(npc, npc, 200045, 1)           --游戏结束音效
            end
            self._proxy:SetFightResultCustomData(player, 11, isAlive) --鼠阵营，单局内是否存活到结束 0否 1是 IsSurvive = 11

            local isMvp = 0
            if rankMouse[npc] == 1 and not hasDuplicatesMouse then
                if self._scoreList[npc] ~= 0 and self._liveCount ~= 0 and self._statusDictionary[npc] == 1 then
                    isMvp = 1
                end
            end
            self._proxy:SetFightResultCustomData(player, 14, isMvp) --任意阵营，是否是Mvp 0否 1是 IsMvp = 14
        else
            XLog.Debug("结算时出现不明生物" .. npc)
        end
    end
    self._timer:Schedule(2, self._proxy, self._proxy.FinishFight, nil) --通知所有客户端开始结算表演
end

-- 脚本终止
function XLevelScript1041:Terminate()

end

return XLevelScript1041
