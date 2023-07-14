local XFunctionTime = require("XEntity/XFunctional/XFunctionTime")
local tableInsert = table.insert

local ShieldFuncDic = {}    -- 功能过滤
local ShieldUiNameDic = {}    -- 功能对应的界面过滤
local FunctionTimeData = {} --功能开启时间

XFunctionManager = XFunctionManager or {}

XFunctionManager.SkipOrigin = {
    System = 1, -- 系统来源
    SonSystem = 2, -- 子系统来源
    Section = 3, -- 副本来源
    Main = 4, -- 主界面
    Webpage = 5, -- 网页
    SystemWithArgs = 6, -- 跳转特定标签页的系统
    Custom = 7, -- 跳转自定义系统（大部分副本）
    Dormitory = 8, -- 跳转宿舍
}

--这个枚举由服务端制定
XFunctionManager.FunctionName = {
    Target = 1, --目标
    SkipObligate = 2, --预留
    Deposit = 3, --充值
    Setting = 4, --设置
    SignIn = 5, --签到
    Feedback = 6, --反馈
    Welfare = 7, --福利
    ExchangeCode = 8, --兑换码

    Character = 101, --构造体
    CharacterGrade = 102, --构造体晋升
    CharacterQuality = 103, --构造体进化
    CharacterSkill = 104, --构造体技能
    CharacterEnhanceSkill = 107, --构造体补强技能
    SpCharacterEnhanceSkill = 108, --SP角色补强技能
    CharacterExhibition = 105, --构造体展示厅
    Isomer = 106, --感染体

    Equip = 201, --装备
    EquipStrengthen = 202, --装备强化
    EquipResonance = 203, --装备共鸣
    EquipStrengthenAutoSelect = 204, --装备一键强化
    EquipAwake = 205, --装备觉醒
    EquipQuick = 206, --一键培养
    EquipGuideRecommend = 207, --装备目标-推荐
    EquipGuideSetTarget = 208, --装备目标-设定
    EquipOverrun = 209, --装备超限

    Bag = 301, --背包
    DrawCard = 401, --研发
    DrawCardEquip = 402, --研发装备
    ActivityDrawCard = 403, --活动研发
    Lotto = 10432,--皮肤抽卡

    Task = 501, --任务
    TaskDay = 503, --任务每日
    TaskActivity = 504, --任务活动
    TaskWeekly = 505, --任务每周
    Player = 601, --战队
    PlayerBrand = 602, --战队烙印
    PlayerAchievement = 603, --战斗成就
    ReviewActivity = 604,
    Mail = 701, --邮件
    SocialFriend = 801, --好友
    SocialChat = 802, --聊天
    Domitory = 901, --基建（弃用）
    Dorm = 902, --宿舍
    DormQuest = 903, -- 宿舍委托
    ShopCommon = 1001, --普通商店
    ShopActive = 1002, --活动商店
    ShopPoints = 1003, --积分商店
    Dispatch = 1201, --派遣
    BountyTask = 1301, --赏金
    MaintainerAction = 1302, --维持者行动（大富翁）
    MentorSystem = 1303, --师徒系统
    MainLineTRPG = 1304, --主线跑团玩法（终焉福音）
    NieR = 1305, --尼尔玩法
    Pokemon = 1306, --口袋战双
    ChessPursuitMain = 1307, -- 追击玩法
    SpringFestivalActivity = 1308, --春节集字活动
    WhiteValentineDay = 1309, -- 白色情人节约会活动
    MoeWar = 1310, -- 萌战
    FavorabilityMain = 1400, --好感度
    FavorabilityFile = 1401, --好感度-档案
    FavorabilityStory = 1402, --好感度-剧情
    FavorabilityGift = 1403, --好感度-礼物
    FavorabilityComeAcross = 1404, --好感度-偶遇

    CustomUi = 1501, --自定义控件

    FubenChallengeTrial = 1601, --试炼玩法
    Prequel = 1701, --断章
    Practice = 1800, --教学
    PartnerTeaching = 1801, -- 宠物教学
    Course = 1802,  --考级系统

    Guild = 1901, --指挥部
    GuildBoss = 1904, --工会boss
    OtherHelp = 2001, --助战
    Collection = 2100, --收藏品
    Medal = 2101, --勋章
    Nameplate = 2102, --铭牌
    Archive = 2200, --图鉴系统
    SubMenu = 2300, -- 主界面二级菜单
    Photograph = 2400, -- 拍照模式
    PurchaseAdd = 3000, --累计充值

    PicComposition = 4000, --看图作文
    WindowsInlay = 4001, --外站活动

    Partner = 5001, --伙伴系统

    ActivityCalendar = 6000, --活动日历

    InvitationCodeShare = 8001, -- 邀请码分享

    FubenDifficulty = 10102, --副本困难
    FubenNightmare = 10103, --据点战
    FubenChallenge = 10201, --挑战副本
    FubenChallengeTower = 10202, --挑战爬塔
    FubenChallengeBossSingle = 10203, --挑战单机Boss
    FubenArena = 10204, -- 竞技
    Stronghold = 10205, -- 超级据点

    ActivityBrief = 10300, --活动简介
    FubenActivity = 10301, --活动副本
    FubenActivityOnlineBoss = 10302, --活动联机boss
    FubenActivityBranch = 10303, --活动支线
    FubenActivitySingleBoss = 10304, --活动单挑boss
    FubenActivityTrial = 10305, --试验区
    FestivalActivity = 10306, --节日活动(活动记录)
    FubenActivityFestival = 10306, --节日活动
    BabelTower = 10307, --巴别塔计划
    FubenActivityMainLine = 10308, --活动主线
    RepeatChallenge = 10309, --复刷本
    RogueLike = 10310, --爬塔
    FubenAssign = 10311, --占领玩法
    ArenaOnline = 10312, --区域联机玩法
    FubenUnionKill = 10313, --狙击战
    Extra = 10314, -- 外篇旧闻
    ShortStory = 10352, --浮点纪实
    FubenInfesotorExplore = 10315, --感染体玩法
    SpecialTrain = 10316, -- 特训关
    EliminateGame = 10317, -- 特训关小游戏
    Expedition = 10318, -- 虚像地平线
    ClickClearGame = 10319, -- 中元节点消小游戏
    WorldBoss = 10320, -- 世界boss
    RpgTower = 10321, -- 兵法蓝图
    HonorLevel = 10322, -- 荣耀勋阶
    FubenZhongYuanFestival = 10323, -- 中元节副本
    DragPuzzleGame = 10324, -- 拼图小游戏
    NewCharAct = 10325, -- 新角色教学
    ChristmasTreeGame = 10326, -- 圣诞树装扮小游戏
    CoupletGame = 10328, -- 对联小游戏
    FingerGuessing = 10329, --猜拳小游戏
    FubenSimulatedCombat = 10330, -- 模拟作战
    InvertCardGame = 10331, -- 翻牌小游戏
    PokerGuessing = 10333, --翻牌猜大小
    MovieAssemble = 10334, -- 剧情合集
    MineSweeping = 10335, -- 扫雷
    FubenHack = 10336, -- 骇入玩法
    Reform = 10337, -- 改造玩法
    ScratchTicket = 10338, -- 刮刮卡
    KillZone = 10339, --杀戮空间
    SuperTower = 10340, -- 超级爬塔
    FashionStory = 10341, -- 涂装剧情活动
    Passport = 10342,   --战斗通行证
    FubenCoupleCombat = 10343, -- 双人下场玩法
    RpgMakerActivity = 10345,   --21年端午活动
    LivWarmActivity = 10347,    --超丽芙预热活动
    LivWarmSoundActivity = 10348,    --超丽芙预热音频活动
    AreaWar = 10349, --全服决战
    SuperSmashBros = 10350, --超限乱斗
    MemorySave = 10351, -- 周年意识营救
    FubenDaily = 10401, --日常副本
    FubenDailyYSHTX = 10402, --日常意识海特训
    FubenDailyEMEX = 10403, --日常EMEX行动
    FubenDailyResource = 10404, --日常资源副本
    FubenExplore = 10405, --探索
    FubenDailyGZTX = 10406, --日常構造體特訓
    FubenDailyXYZB = 10407, --日常稀有裝備
    FubenDailyTPCL = 10408, --日常突破材料
    FubenDailyZBJY = 10409, --日常裝備經驗
    FubenDailyLMDZ = 10410, --日常螺母大戰
    FubenDailyJNQH = 10411, --日常技能强化
    FubenDailyFZJQH = 10412, --日常辅助机强化
    FubenDailyShop = 10450, --日常补给商店
    SameColor = 10413,  -- 三消游戏
    RunGame = 10414,    --二周年预热-赛跑小游戏
    DiceGame = 10415, --元旦预热-投骰子小游戏
    Maverick = 10416, -- 射击玩法
    NewYearLuck = 10417, --元旦奖券小游戏
    HitMouse = 10418, --打地鼠小游戏
    BodyCombineGame = 10419, --哈卡玛小游戏
    Theatre = 10420,    --肉鸽舞台剧
    Doomsday = 10421, --末日生存（模拟经营）
    PivotCombat = 10422, --SP枢纽作战
    Escape = 10423, --大逃杀活动
    DoubleTowers = 10424, --动作塔防
    GoldenMiner = 10426, --黄金矿工活动
    WeekChallenge = 10428, --周挑战
    MultiDim = 10427, -- 多维挑战
    TaikoMaster = 10430, --音游
    TwoSideTower = 10431, --正逆塔
    BiancaTheatre = 10433,  --肉鸽2.0
    SummerSignIn = 10434, --夏日签到
    NewbieTask = 10435, -- 新手任务二期
    CharacterTower = 10436, --本我回廊（角色塔）
    Rift = 10437, -- 大秘境
    ColorTable = 10438, -- 调色板战争
    FubenBrilliantWalk = 10439, -- 光辉同行
    FubenAwareness = 10440, -- 意识公约副本
    SkinVote = 10442, -- 皮肤投票
    Restaurant = 10443, -- 餐厅玩法
    Maverick2 = 10444, -- 异构阵线2.0
    MonsterCombat = 10447, -- 战双BVB
    CerberusGame = 10448, -- 三头犬小队
    SlotMachines = 10449, -- 老虎机
    Transfinite = 10451, -- 超限连战
    NewActivityCalendar = 10452, -- 新活动周历
    Theatre3 = 10453, -- 肉鸽3.0
}

XFunctionManager.FunctionType = {
    System = 1,
    Stage = 2,
}

XFunctionManager.TimeState = {
    Start = 1,
    End = 2,
}

function XFunctionManager.FilterUi(evt, args, ...)
    local uiName = args[0].UiData.UiName
    if ShieldUiNameDic[uiName] then
        XUiManager.TipText("ShieldFunctionTip", nil, true)
        XLuaUiManager.RunMain()
    end
end

function XFunctionManager.FilterUiFinish()
    ShieldUiNameDic = {}
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, XFunctionManager.FilterUi)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, XFunctionManager.FilterUiFinish)
end

function XFunctionManager.InitShieldFuncData(shieldFuncList, inGameUpdate)
    ShieldFuncDic = {}
    ShieldUiNameDic = {}
    local EnableFilterUi = true
    for _, v in ipairs(shieldFuncList) do
        ShieldFuncDic[v] = true
        if inGameUpdate then
            for _, uiName in ipairs(XFunctionConfig.GetShieldFuncUiName(v)) do
                if CS.XFight.Instance and XLuaUiManager.IsUiShow(uiName) then
                    EnableFilterUi = false
                    XUiManager.TipText("ShieldFunctionTip", nil, true)
                    XLuaUiManager.RunMain()
                    ShieldUiNameDic = {}
            end
                ShieldUiNameDic[uiName] = true
        end
        end
    end

    if inGameUpdate and EnableFilterUi then
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, XFunctionManager.FilterUi)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XFunctionManager.FilterUiFinish)
end
    end

--检测是否可以过滤该功能
function XFunctionManager.CheckFunctionFitter(id)
    return ShieldFuncDic[id]
end

--界面跳转
function XFunctionManager.SkipInterface(id, ...)
    if id == 0 then
        return
    end

    local list = XFunctionConfig.GetSkipFuncCfg(id)
    if list == nil then
        XLog.Error("XFunctionManager.SkipInterface error: can not found list, id = " .. tostring(id))
        return
    end

    if list.FunctionalId ~= nil and list.FunctionalId ~= 0 then
        -- 屏蔽功能
        if XFunctionManager.CheckFunctionFitter(list.FunctionalId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
            return
        end

        if not XFunctionManager.DetectionFunction(list.FunctionalId) then
            return
        end

    end

    -- 提审包屏蔽，跳转到主线页面
    if XUiManager.IsHideFunc and list.IsHideFunc then
        -- XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Mainline, nil, 1)
        XLuaUiManager.Open("UiNewFuben", XFubenConfigs.ChapterType.MainLine)
        return
    end


    if list.Origin == XFunctionManager.SkipOrigin.System then
        if XLuaUiManager.IsUiShow(list.UiName) then
            return
        end
        
        XLuaUiManager.Open(list.UiName)
    end

    if list.Origin == XFunctionManager.SkipOrigin.SonSystem then
        if XLuaUiManager.IsUiShow(list.UiName) then
            return
        end

        if list.UiName == "UiCharacter" then
            XLuaUiManager.Open(list.UiName, list.ParamId, nil, nil, nil, true)
        elseif list.UiName == "UiActivityBase" then
            XLuaUiManager.Open(list.UiName, list.ParamId, list.CustomParams[1], list.CustomParams[2])
        else
            XLuaUiManager.Open(list.UiName, list.ParamId)
        end
    end

    if list.Origin == XFunctionManager.SkipOrigin.Section then
        XDataCenter.FubenManager.GoToFuben(list.ParamId)
    end

    if list.Origin == XFunctionManager.SkipOrigin.Main then
        if XLuaUiManager.IsUiShow("UiMain") then
            return
        end
        
        CS.XResourceRecord.Stop()
        XLuaUiManager.RunMain()
    end

    if list.Origin == XFunctionManager.SkipOrigin.SystemWithArgs then
        CS.XResourceRecord.FunctionEnter(id)
        XDataCenter.FunctionalSkipManager.SkipSystemWidthArgs(list)
        return
    end

    if list.Origin == XFunctionManager.SkipOrigin.Custom then
        CS.XResourceRecord.FunctionEnter(id)
        XDataCenter.FunctionalSkipManager.SkipCustom(list, ...)
        return
    end

    if list.Origin == XFunctionManager.SkipOrigin.Dormitory then
        XDataCenter.FunctionalSkipManager.SkipDormitory(list)
        return
    end

    -- if list.Origin == XFunctionManager.SkipOrigin.Webpage then
    -- end
end

function XFunctionManager.CheckSkipInDuration(id)
    local cfg = XFunctionConfig.GetSkipFuncCfg(id)
    if not cfg then
        return false
    end

    local timeId = cfg.TimeId
    local startTimeStr = cfg.StartTime
    local closeTimeStr = cfg.CloseTime
    if timeId and timeId ~= 0 then
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    else
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        if startTimeStr and startTimeStr ~= "" and closeTimeStr and closeTimeStr ~= "" then
            local startTime = XTime.ParseToTimestamp(startTimeStr)
            local closeTime = XTime.ParseToTimestamp(closeTimeStr)
            return (nowTimeStamp >= startTime and nowTimeStamp <= closeTime)
        elseif startTimeStr and startTimeStr ~= "" then
            local startTime = XTime.ParseToTimestamp(startTimeStr)
            return nowTimeStamp >= startTime
        elseif closeTimeStr and closeTimeStr ~= "" then
            local closeTime = XTime.ParseToTimestamp(closeTimeStr)
            return nowTimeStamp < closeTime
        end
    end

    return true
end

function XFunctionManager.IsCanSkip(skipId)
    local list = XFunctionConfig.GetSkipList(skipId)
    if not list then return false end
    return XFunctionManager.JudgeCanOpen(list.FunctionalId)
end

function XFunctionManager.JudgeOpen(id)
    --判断是否开启功能
    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return true
    end

    return XPlayer.IsMark(id)
end

function XFunctionManager.GetFunctionOpenCondition(id)
    --获取开启条件说明
    local isOpen
    local decs = ""

    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return decs
    end

    -- if not XFunctionManager.IsDuringTime(id) then
    --     return CS.XTextManager.GetText("FunctionNotDuringOpening")
    -- end

    for _, v in pairs(XFunctionConfig.GetFuncOpenCfg(id).Condition) do
        if v and v ~= 0 then
            isOpen, decs = XConditionManager.CheckCondition(v)
            if not isOpen then
                break
            end
        end
    end

    return decs
end

function XFunctionManager.JudgeCanOpen(id)
    -- if not XFunctionManager.IsDuringTime(id) then
    --     return false
    -- end

    -- 判断是否能开启
    local isOpen = true

    -- 如果没有配置应该返回true
    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return true
    end

    for _, v in pairs(XFunctionConfig.GetFuncOpenCfg(id).Condition) do
        if v and v ~= 0 then
            isOpen = XConditionManager.CheckCondition(v)
            if not isOpen then
                break
            end
        end
    end

    return isOpen
end
--================
--检测功能是否开放
--@param functionNameId:FunctionManager.FunctionName 功能枚举ID
--@param needMark:是否需要通知后端标记功能开放
--@param noTips:是否要弹出错误提示
--================
function XFunctionManager.DetectionFunction(functionNameId, needMark, noTips)
    --判断能否进入功能按钮
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        if not noTips then
            XUiManager.TipError(XFunctionManager.GetFunctionOpenCondition(functionNameId))
        end
        return false
    end
    --后端需要使用功能开放标记时另外特殊判断并添加标记
    if needMark then
        if not XFunctionManager.JudgeOpen(functionNameId) then
            XPlayer.ChangeMarks(functionNameId)
        end
    end
    return true
end

local CanOpenId = {}

function XFunctionManager.CheckOpen()
    --开启功能
    for _, id in ipairs(XFunctionConfig.GetOpenList()) do
        if not XFunctionManager.JudgeOpen(id) then
            if XFunctionManager.JudgeCanOpen(id) then
                XPlayer.ChangeMarks(id)
                if XFunctionConfig.GetOpenHint(id) == 1 then
                    tableInsert(CanOpenId, id)
                end
            end
        end
    end
end


--获取功能开启提醒方式
function XFunctionManager.ShowOpenHint()
    if not CanOpenId or #CanOpenId <= 0 then
        return false
    end

    for i = 1, #CanOpenId do
        if XFunctionConfig.GetOpenHint(CanOpenId[i]) == 1 then
            XLuaUiManager.Open("UiHintFunctional", CanOpenId)
            CanOpenId = {}
            return true
        end
    end

    return false
end

--活动跳转相关 begin
function XFunctionManager.CheckSkipActivityOpen()
    local template = XFunctionConfig.GetMainActSkipCfg(1)
    local stageType = template.StageType
    local stageTypes = XDataCenter.FubenManager.StageType

    if stageType == stageTypes.Mainline then
        return XDataCenter.FubenMainLineManager.IsMainLineActivityOpen()
    elseif stageType == stageTypes.ActivtityBranch then
        return XDataCenter.FubenActivityBranchManager.IsOpen()
    elseif stageType == stageTypes.ActivityBossSingle then
        return XDataCenter.FubenActivityBossSingleManager.IsOpen()
    end

    return false
end

function XFunctionManager.SkipToActivity()
    if not XFunctionManager.CheckSkipActivityOpen() then
        return
    end

    local skipId = XFunctionConfig.GetMainActSkipCfg(1).SkipId
    if not skipId then
        return
    end

    XFunctionManager.SkipInterface(skipId)
end

--活动跳转相关 end
--功能时间相关 begin
local function GetTimeData(timeId)
    return FunctionTimeData[timeId]
end

function XFunctionManager.IsEffectiveTimeId(timeId)
    if not timeId then
        return false
    end
    if FunctionTimeData[timeId] then
        return true
    else
        return false
    end
end

function XFunctionManager.CheckInTimeByTimeId(timeId, defaultOpen)
    --未配置timeId默认未开启
    if not XTool.IsNumberValid(timeId) then
        return defaultOpen and true or false
    end

    --timeId配置错误默认未开启
    local timeData = GetTimeData(timeId)
    if not timeData then
        return defaultOpen and true or false
    end

    --startTime未配置默认无开启时间限制
    --endTime未配置默认无结束时间限制
    return timeData:IsInTime()
end

function XFunctionManager.GetStartTimeByTimeId(timeId)
    if not timeId then return end
    local timeData = GetTimeData(timeId)
    return timeData and timeData:GetStartTime() or 0
end

function XFunctionManager.GetEndTimeByTimeId(timeId)
    if not timeId then return 0 end
    local timeData = GetTimeData(timeId)
    return timeData and timeData:GetEndTime() or 0
end

function XFunctionManager.GetTimeByTimeId(timeId)
    return XFunctionManager.GetStartTimeByTimeId(timeId), XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 已废弃
-- function XFunctionManager.IsDuringTime(functionId)
--     local timeId = XFunctionConfig.GetFuncOpenCfg(functionId) and XFunctionConfig.GetFuncOpenCfg(functionId).TimeId
--     --未配置timeId默认开启(功能开启特殊处理)
--     if not timeId or timeId == 0 then return true end
--     return XFunctionManager.CheckInTimeByTimeId(timeId)
-- end

function XFunctionManager.BindTimeId(timeId)
    if not timeId then return end
    local timeData = GetTimeData(timeId)
    if timeData then
        timeData:CreateTimer()
    end
end

local function UpdateFunctionTimeData(dataList)
    if not dataList then return end
    for _, data in pairs(dataList) do
        local timeId = data.Id

        local timeData = FunctionTimeData[timeId]
        if not timeData then
            timeData = XFunctionTime.New(timeId)
            FunctionTimeData[timeId] = timeData
        end

        timeData:UpdateData(data)
    end
end

function XFunctionManager.InitFuncOpenTime(data)
    UpdateFunctionTimeData(data)
end

XRpc.NotifyTimeLimitCtrlConfigList = function(data)
    UpdateFunctionTimeData(data.TimeLimitCtrlConfigList)
    XEventManager.DispatchEvent(XEventId.EVENT_ETCD_TIME_CHANGE)
end

--功能时间相关 end
XRpc.NotifyClientShieldFunction = function(data)
    XFunctionManager.InitShieldFuncData(data.ShieldFunctionIds, true)
end