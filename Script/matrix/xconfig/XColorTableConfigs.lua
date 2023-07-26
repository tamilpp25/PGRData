XColorTableConfigs = XColorTableConfigs or {}

local TABLE_CLIENT = "Client/MiniActivity/ColorTable/"
local TABLE_SHARE = "Share/MiniActivity/ColorTable/"

-- 关卡难度类型
XColorTableConfigs.StageDifficultyType =
{
    Normal = 1, -- 普通
    Difficult = 2, -- 困难
}

-- 关卡结算类型
XColorTableConfigs.WinType = {
    Break = 1, -- 中断挑战
    NormalWin = 2, -- 普通胜利
    SpecialWin = 3, -- 完成特殊条件胜利
}

-- 遭遇图鉴组类型
XColorTableConfigs.DramaType =
{
    Tucao = 1, -- 事件图鉴
    Dialogue = 2, -- 剧情图鉴
}

-- 遭遇图鉴组类型
XColorTableConfigs.HandBookType =
{
    Event = 1, -- 事件图鉴
    Drama = 2, -- 剧情图鉴
    StageEndStory = 3, -- 关卡结束剧情
}

XColorTableConfigs.MapType = {
    Construct = 1,      -- 构造体地图(9个点)
    Commander = 2,      -- 指挥官地图(10个点)
    GuideStage = 3,     -- 新手，只有三个点
}

XColorTableConfigs.TimelineType = {
    Normal = 1,     -- 常规区域，随机病毒涨1
    Explode = 2,    -- 爆发区域，随机病毒涨2
    Epidemic = 3,   -- 大流行，最高病毒涨2，其余涨1
}

XColorTableConfigs.Difficulty = {
    Normal = 1,     -- 普通
    Hard = 2,       -- 困难
}

XColorTableConfigs.StageType = {
    Construct = 1,  -- 构造体章节，固定队长
    Commander = 2,  -- 指挥官章节，任选队长
    FirstGuide = 3, -- 引导关1
    SecondGuide = 4,-- 引导关2
}

XColorTableConfigs.CurStageType = {
    PlayGame = 1,   -- 地图玩法中
    Fight = 2,      -- Boss战环节
}

-- 地块类型
XColorTableConfigs.PointType = {
    Lab = 1,        -- 研究所，支付7点研究数据提高研究等级
    Hospital = 2,   -- 治疗点，支付研究数据减少病毒等级
    Supply = 3,     -- 补给点，roll点获得研究数据
    Tower = 4,      -- 中心塔
    Boss = 101,     -- Boss点，为101因为服务端不需要该类型，大数防止后续版本服务端拓展地图点位类型导致配置大改
    HideBoss = 102, -- 隐藏Boss点
}

XColorTableConfigs.HideBossColor = 0 -- 隐藏boss的颜色
XColorTableConfigs.ColorType = {
    Red = 1,        -- 红
    Green = 2,      -- 绿
    Blue = 3        -- 蓝
}

XColorTableConfigs.EffectLifeType = {
    Persist = 1,            -- 每回合持续
    CurRoundPresist = 2,    -- 本回合持续
    NextRoundPersisit = 3,  -- 下回合持续
    CurRoundNow = 4,        -- 本回合立即
    CurRoundEnd = 5,        -- 本回合结束
    NextRoundNow = 6,       -- 下回合立即
}

XColorTableConfigs.EffectType = {
        Type1 = 1,     -- 每回合持续, 每回合前X次移动不消耗行动点
        Type2 = 2,     -- 本回合持续, 特定颜色上移动不消耗行动力（起点判断）
        Type3 = 3,     -- 三色数据储存上限上升至x
        Type4 = 4,     -- 方块等级从X级开始
        Type5 = 5,     -- 方块等级提升时，数值调整为+X
        Type6 = 6,     -- 每次治疗时，需要额外花费X点对应颜色的数据
        Type7 = 7,     -- 禁止使用配置颜色的治疗
        Type8 = 8,     -- 每回合重置, X颜色只能治疗Y次
        Type9 = 9,     -- 全部颜色合计只能治疗X次
        Type10 = 10,   -- 指定颜色数据提升X
        Type11 = 11,   -- 指定颜色病毒增加X级
        Type12 = 12,   -- 全部颜色数据变成X
        Type13 = 13,   -- 指定颜色研究等级提升X
        Type14 = 14,   -- 行动点增加X
        Type15 = 15,   -- 提升研究等级现在只需要消耗X个研究点
        Type16 = 16,   -- 每回合前X次执行地点行动后，获得该区域颜色数据Y
        Type17 = 17,   -- 每回合前X次执行地点行动后，扣除该区域颜色数据Y，先正后负
        Type18 = 18,   -- 本回合前X次获得数据，获得的数据量+Y
        Type19 = 19,   -- 本回合X色可额外获得Y个数据
        Type20 = 20,   -- 无法执行X色地块行动，X色病毒爆发后，其数值调整为Y
        Type21 = 21,   -- 回合结算时，不结算任何病毒增长（进度照常往前走）
        Type22 = 22,   -- 常规&爆发不进行随机，改为提升角色所在颜色的BOSS强度
        Type23 = 23,   -- 经过或站立在中央区域时（也就是点位10），获得X点y色资源，事件触发后仅生效1次
        Type24 = 24,   -- 回合结算时，结算事件执行X次
        Type25 = 25,   -- 角色所在颜色的BOSS，等级下降X
        Type26 = 26,   -- 现在研究只能获得3或4点
        Type27 = 27,   -- 执行研究时，可以重新rollX次骰子
        Type28 = 28,   -- 前X次治疗，效果+Y
        Type29 = 29,   -- 研究时，X色、Y色数据可混合使用（简化操作，优先使用对应颜色）
}

XColorTableConfigs.ActionType = {
    BlockSettle = 1,        -- 时间轴移动后，根据方块位置结算
    BurstSettle = 2,        -- 时间轴移动后，爆发结算
    TimeBlockChange = 3,    -- 时间轴移动或时间方块改变
    RemoveEvent = 4,        -- 删除遭遇事件
    AddEvent = 5,           -- 添加遭遇事件
    EffectTakeEffect = 6,   -- 事件效果触发
    GameLose = 7,           -- 游戏失败
    StudyLevelChange = 8,   -- 研究等级
    GameWin = 9,            -- 游戏地图阶段胜利
    RemoveEffect = 10,      -- 删除效果
    NewRound = 11,          -- 进入新回合
    TriggerDrama = 12,      -- 触发剧情
    StageSettle = 13,       -- 关卡结算
    TimeBlockReset = 14,    -- 时间方块复位
    ActionPointChange = 15, -- 行动力改变
    StudyDataChange = 16,   -- 研究数据改变
    BossLevelChange = 17,   -- boss等级改变
}

XColorTableConfigs.TipsType  = {
    CaptainInfoTip = 1,     -- 队长信息提示
    StudyDataTip = 2,       -- 研究点数提示
    RoundTip = 3,           -- 时间轴提示
    EsayActionModeTip = 4,  -- 便捷模式提示
    EventTip = 5,           -- 遭遇事件提示
}

-- 客户端判断的吐槽类剧情ConditionType
XColorTableConfigs.DramaConditionType = {
    HelpCondition = 4,      -- 累计点击帮助X次
    TipCondition = 5,       -- 累计打开X次操作弹窗但什么都不操作
    IdleTimeAndBoss = 6,    -- 在关卡主界面不操作X秒且存在等级大于Y的Boss
    IdleTimeAndData = 7,    -- 在关卡主界面不操作X秒且存在大于Y的Data
    IdleTimeAndAllData = 8, -- 在关卡主界面不操作X秒且所有Data都不大于X
}

-- 自定义字典
local HandBookDramaIdDic = {} -- 剧情id:遭遇图鉴id

function XColorTableConfigs.Init()
    XConfigCenter.CreateGetProperties(XColorTableConfigs, {
        "ColorTableConfig",
        "ColorTableShop",
        "ColorTablePointDetail",
        "ColorTableEffectPointShow",
        "ColorTableBuffDetail",
        "ColorTableBuffGroup",
        "ColorTableStageEndStory",
        "ColorTableActivity",
        "ColorTableChapter",
        "ColorTableStage",
        "ColorTableStageEffect",
        "ColorTableMap",
        "ColorTableWinCondition",
        "ColorTableCaptain",
        "ColorTableTimeline",
        "ColorTablePoint",
        "ColorTablePointLink",
        "ColorTableDrama",
        "ColorTableEffect",
        "ColorTableEvent",
        "ColorTableEventCondition",
        "ColorTableHandbook",
        "ColorTableDifficultyReward",
        "ColorTableStageRobot",
        "ColorTableSpecialRole",
    }, {
        "ReadByStringKey", TABLE_CLIENT .. "ColorTableConfig.tab", XTable.XTableColorTableConfig, "Key",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTableShop.tab", XTable.XTableColorTableShop, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTablePointDetail.tab", XTable.XTableColorTablePointDetail, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTableEffectPointShow.tab", XTable.XTableColorTableEffectPointShow, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTableBuffDetail.tab", XTable.XTableColorTableBuffDetail, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTableBuffGroup.tab", XTable.XTableColorTableBuffGroup, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "ColorTableStageEndStory.tab", XTable.XTableColorTableStageEndStory, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableActivity.tab", XTable.XTableColorTableActivity, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableChapter.tab", XTable.XTableColorTableChapter, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableStage.tab", XTable.XTableColorTableStage, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableStageEffect.tab", XTable.XTableColorTableStageEffect, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableMap.tab", XTable.XTableColorTableMap, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableWinCondition.tab", XTable.XTableColorTableWinCondition, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableCaptain.tab", XTable.XTableColorTableCaptain, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableTimeline.tab", XTable.XTableColorTableTimeline, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTablePoint.tab", XTable.XTableColorTablePoint, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTablePointLink.tab", XTable.XTableColorTablePointLink, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableDrama.tab", XTable.XTableColorTableDrama, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableEffect.tab", XTable.XTableColorTableEffect, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableEvent.tab", XTable.XTableColorTableEvent, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableEventCondition.tab", XTable.XTableColorTableEventCondition, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableHandbook.tab", XTable.XTableColorTableHandbook, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableDifficultyReward.tab", XTable.XTableColorTableDifficultyReward, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableStageRobot.tab", XTable.XTableColorTableStageRobot, "Id",
        "ReadByIntKey", TABLE_SHARE .. "ColorTableSpecialRole.tab", XTable.XTableColorTableSpecialRole, "Id",
    })

    XColorTableConfigs.InitPointGroups()
    XColorTableConfigs.InitDramaGroupDic()
    XColorTableConfigs.CreateHandBookDramaIdDic()
end


-- ColorTableConfig 必要系统配置
--==================================================================================

-- 主界面帮助key
function XColorTableConfigs.GetUiMainHelpKey()
    local config = XColorTableConfigs.GetColorTableConfig("UiMainHelpKey", true)
    return config.Params[1]
end

-- 主界面帮助key
function XColorTableConfigs.GetUiChooseStageHelpKey()
    local config = XColorTableConfigs.GetColorTableConfig("UiChooseStageHelpKey", true)
    return config.Params[1]
end

-- 地图玩法主面板Key
function XColorTableConfigs.GetUiStageMainHelpKey()
    local config = XColorTableConfigs.GetColorTableConfig("UiStageMainHelpKey", true)
    return config.Params[1]
end

function XColorTableConfigs.GetGuideStageColor()
    local config = XColorTableConfigs.GetColorTableConfig("GuideStageColor", true)
    return tonumber(config.Params[1])
end

-- 时间点图标
function XColorTableConfigs.GetTimeLinePointIcon(timeLineType)
    local config = XColorTableConfigs.GetColorTableConfig("TimeLinePointIcon", true)
    return config.Params[timeLineType]
end

-- 颜色文本
function XColorTableConfigs.GetColorText(colorType)
    local config = XColorTableConfigs.GetColorTableConfig("ColorText", true)
    return config.Params[colorType]
end

-- 研究数据点图标
function XColorTableConfigs.GetStudyDataIcon(colorType)
    local config = XColorTableConfigs.GetColorTableConfig("StudyDataIcon", true)
    return config.Params[colorType]
end

-- 研究数据点图标(消耗用)
function XColorTableConfigs.GetStudyDataCostIcon(colorType)
    local config = XColorTableConfigs.GetColorTableConfig("StudyDataCostIcon", true)
    return config.Params[colorType]
end

function XColorTableConfigs.GetBossPointPrefab()
    local config = XColorTableConfigs.GetColorTableConfig("PointBoss", true)
    return config.Params[1]
end

function XColorTableConfigs.GetMapPointPrefab(pointType)
    if pointType == XColorTableConfigs.PointType.Supply then
        local config = XColorTableConfigs.GetColorTableConfig("PointEnergy", true)
        return config.Params[1]
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        local config = XColorTableConfigs.GetColorTableConfig("PointMedical", true)
        return config.Params[1]
    else
        local config = XColorTableConfigs.GetColorTableConfig("PointStudy", true)
        return config.Params[1]
    end
end

function XColorTableConfigs.GetMovePointPrefab()
    local config = XColorTableConfigs.GetColorTableConfig("PointMovie", true)
    return config.Params[1]
end

-- 地图点选择图标
function XColorTableConfigs.GetPointSelectIcon(pointType, colorType)
    if pointType == XColorTableConfigs.PointType.Lab then
        return XColorTableConfigs.GetColorTableConfig("PointStudySelectIcon", true).Params[colorType]
    elseif pointType == XColorTableConfigs.PointType.Supply then
        return XColorTableConfigs.GetColorTableConfig("PointEnergySelectIcon", true).Params[colorType]
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        return XColorTableConfigs.GetColorTableConfig("PointMedicalSelectIcon", true).Params[colorType]
    end
end

-- 地图点禁用图标
function XColorTableConfigs.GetPointDisableIcon(pointType, colorType)
    if pointType == XColorTableConfigs.PointType.Lab then
        return XColorTableConfigs.GetColorTableConfig("PointStudyDisableIcon", true).Params[colorType]
    elseif pointType == XColorTableConfigs.PointType.Supply then
        return XColorTableConfigs.GetColorTableConfig("PointEnergyDisableIcon", true).Params[colorType]
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        return XColorTableConfigs.GetColorTableConfig("PointMedicalDisableIcon", true).Params[colorType]
    end
end

function XColorTableConfigs.GetBossPointBgIcon(colorType, isHide)
    if isHide then
        local config = XColorTableConfigs.GetColorTableConfig("PointHideBossBgIcon", true)
        if config then
            return config.Params[1]
        end
    end
    return XColorTableConfigs.GetColorTableConfig("PointBossBgIcon", true).Params[colorType]
end

function XColorTableConfigs.GetBossPointSelectIcon(colorType, isHide)
    if isHide then
        local config = XColorTableConfigs.GetColorTableConfig("PointHideBossSelectIcon", true)
        if config then
            return config.Params[1]
        end
    end
    return XColorTableConfigs.GetColorTableConfig("PointBossSelectIcon", true).Params[colorType]
end

function XColorTableConfigs.GetHideBossPointBgMaskIcon()
    local config = XColorTableConfigs.GetColorTableConfig("PointHideBossBgMaskIcon", true)
    if config then
        return config.Params[1]
    end
end

function XColorTableConfigs.GetBossPointTipPrefab()
    local config = XColorTableConfigs.GetColorTableConfig("TipBoss", true)
    return config.Params[1]
end

function XColorTableConfigs.GetMapPointTipPrefab(pointType)
    if pointType == XColorTableConfigs.PointType.Lab then
        local config = XColorTableConfigs.GetColorTableConfig("TipStudy", true)
        return config.Params[1]
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        local config = XColorTableConfigs.GetColorTableConfig("TipMedical", true)
        return config.Params[1]
    elseif pointType == XColorTableConfigs.PointType.Supply then
        local config = XColorTableConfigs.GetColorTableConfig("TipEnergy", true)
        return config.Params[1]
    else    -- 中心塔用研究台的
        local config = XColorTableConfigs.GetColorTableConfig("TipStudy", true)
        return config.Params[1]
    end
end

-- 结算界面背景图
function XColorTableConfigs.GetHaflSettleBgIcon(isSpecialWin, isLose)
    local config = XColorTableConfigs.GetColorTableConfig("HalfSettleBgIcon", true)
    if isLose then
        return config.Params[3]
    end
    if isSpecialWin then
        return config.Params[2]
    else
        return config.Params[1]
    end
end

-- 结算界面标题图标
function XColorTableConfigs.GetHalfSettleTitleIcon(isSpecialWin, isLose)
    local config = XColorTableConfigs.GetColorTableConfig("HalfSettleTitleIcon", true)
    if isLose then
        return config.Params[3]
    end
    if isSpecialWin then
        return config.Params[2]
    else
        return config.Params[1]
    end
end

-- 结算界面文本色号
function XColorTableConfigs.GetHaflSettleTxtColor(isSpecialWin)
    local config = XColorTableConfigs.GetColorTableConfig("HalfSettleTxtColor", true)
    if isSpecialWin then
        return config.Params[2]
    else
        return config.Params[1]
    end
end

-- 结算界面提示文本色号
function XColorTableConfigs.GetHaflSettleTipTxtColor(isSpecialWin)
    local config = XColorTableConfigs.GetColorTableConfig("HalfSettleTipTxtColor", true)
    if isSpecialWin then
        return config.Params[2]
    else
        return config.Params[1]
    end
end

function XColorTableConfigs.GetRImgStageRollPanel(color)
    local config = XColorTableConfigs.GetColorTableConfig("RImgStageRollPanel", true)
    return config.Params[color]
end

function XColorTableConfigs.GetImgStageRollPoint(value)
    local config = XColorTableConfigs.GetColorTableConfig("ImgStageRollPoint", true)
    return not string.IsNilOrEmpty(config.Params[value - 2]) and config.Params[value - 2] or nil
end

function XColorTableConfigs.GetColorStageRollPoint(color, value)
    local config
    if color == XColorTableConfigs.ColorType.Red then
        config = XColorTableConfigs.GetColorTableConfig("ColorStageRollPointRed", true)
    elseif color == XColorTableConfigs.ColorType.Green then
        config = XColorTableConfigs.GetColorTableConfig("ColorStageRollPointGreen", true)
    elseif color == XColorTableConfigs.ColorType.Blue then
        config = XColorTableConfigs.GetColorTableConfig("ColorStageRollPointBlue", true)
    end
    return config.Params[value - 2]
end

--==================================================================================



-- ColorTableActivity 活动
--==================================================================================

function XColorTableConfigs.GetActivityTimeId(activityId)
    local config = XColorTableConfigs.GetColorTableActivity(activityId, true)
    return config.TimeId
end

function XColorTableConfigs.GetActivityName(activityId)
    local config = XColorTableConfigs.GetColorTableActivity(activityId, true)
    return config.Name
end

function XColorTableConfigs.GetActivityMovieId(activityId)
    local config = XColorTableConfigs.GetColorTableActivity(activityId, true)
    return config.MovieId
end

--==================================================================================



-- ColorTableChapter 章节
--==================================================================================

function XColorTableConfigs.GetChapterTimeId(chapterId)
    local config = XColorTableConfigs.GetColorTableChapter(chapterId, true)
    return config.TimeId
end

function XColorTableConfigs.GetChapterName(chapterId)
    local config = XColorTableConfigs.GetColorTableChapter(chapterId, true)
    return config.Name
end

function XColorTableConfigs.GetChapterConditionId(chapterId)
    local config = XColorTableConfigs.GetColorTableChapter(chapterId, true)
    return config.ConditionId
end

function XColorTableConfigs.GetChapterShowRewardId(chapterId)
    local config = XColorTableConfigs.GetColorTableChapter(chapterId, true)
    return config.ShowRewardId
end

--==================================================================================



-- ColorTableStage 关卡表
--==================================================================================

function XColorTableConfigs.GetStageChapterId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.ChapterId
end

function XColorTableConfigs.GetStageDifficultyId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.DifficultyId
end

function XColorTableConfigs.GetStageName(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.Name
end

function XColorTableConfigs.GetStageType(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.StageType
end

function XColorTableConfigs.GetStagePreStageId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.PreStageId
end

function XColorTableConfigs.GetStageTimeId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.TimeId
end

function XColorTableConfigs.GetStageCaptainId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.CaptainId
end

function XColorTableConfigs.GetStageMapId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.MapId
end

function XColorTableConfigs.GetStageNormalWinConditionId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.NormalWinConditionId
end

function XColorTableConfigs.GetStageSpecialWinConditionId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.SpecialWinConditionId
end

function XColorTableConfigs.GetStageNormalStageId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.NormalStageId
end

function XColorTableConfigs.GetStageSpecialStageId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.SpecialStageId
end

function XColorTableConfigs.GetStageStageEffectId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.StageEffectId
end

function XColorTableConfigs.GetStageFirstRewardId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.FirstRewardId
end

function XColorTableConfigs.GetStagePassRewardId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.PassRewardId
end

function XColorTableConfigs.GetStageRebootPassRewardId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.RebootPassRewardId
end

function XColorTableConfigs.GetStageClearNodeCount(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.ClearNodeCount
end

function XColorTableConfigs.GetStageClearNodeRewardId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.ClearNodeRewardId
end

function XColorTableConfigs.GetStageMovieId(CTStageId)
    local config = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    return config.MovieId
end

function XColorTableConfigs.GetStageRobotIds(CTStageId)
    local stageConfig = XColorTableConfigs.GetColorTableStage(CTStageId, true)
    local robotConfig = XColorTableConfigs.GetColorTableStageRobot(stageConfig.RobotGroupId, true)
    return robotConfig.RobotIds
end

function XColorTableConfigs.GetStageList(chapterId, difficultyId)
    local stageList = {}
    local stageConfig = XColorTableConfigs.GetColorTableStage()
    for _, stage in ipairs(stageConfig) do
        if stage.ChapterId == chapterId and stage.DifficultyId == difficultyId then
            table.insert(stageList, stage)
        end
    end

    table.sort(stageList, function(a, b)
        return a.Order <= b.Order
    end)

    return stageList
end

function XColorTableConfigs.GetDifficultStageList()
    local stageList = {}
    local stageConfig = XColorTableConfigs.GetColorTableStage()
    for _, stage in ipairs(stageConfig) do
        if stage.DifficultyId == XColorTableConfigs.StageDifficultyType.Difficult then
            table.insert(stageList, stage)
        end
    end
    return stageList
end
--==================================================================================

--==================================================================================



-- ColorTableStageEffect 关卡效果
--==================================================================================

function XColorTableConfigs.GetStageEffectName(id)
    local config = XColorTableConfigs.GetColorTableStageEffect(id, true)
    return config.Name
end

function XColorTableConfigs.GetStageEffectDesc(id)
    local config = XColorTableConfigs.GetColorTableStageEffect(id, true)
    return config.Desc
end

function XColorTableConfigs.GetStageEffectIcon(id)
    local config = XColorTableConfigs.GetColorTableStageEffect(id, true)
    return config.Icon
end

function XColorTableConfigs.GetStageEffectId(id)
    local config = XColorTableConfigs.GetColorTableStageEffect(id, true)
    return config.EffectId
end

--==================================================================================



-- ColorTableMap 地图
--==================================================================================

function XColorTableConfigs.GetMapName(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.Name
end

function XColorTableConfigs.GetMapType(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.MapType
end

function XColorTableConfigs.GetMapClearable(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.Clearable
end

function XColorTableConfigs.GetMapRebootable(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.Rebootable
end

function XColorTableConfigs.GetMapBossExplodeLevel(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.BossExplodeLevel
end

function XColorTableConfigs.GetMapStudyLevelLimit(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.StudyLevelLimit
end

function XColorTableConfigs.GetMapStudyDataLimit(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.StudyDataLimit
end

function XColorTableConfigs.GetMapBossLevels(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.BossLevels
end

function XColorTableConfigs.GetMapStudyDatas(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.StudyDatas
end

function XColorTableConfigs.GetMapStudyLevels(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.StudyLevels
end

function XColorTableConfigs.GetMapBornPosition(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.BornPosition
end

function XColorTableConfigs.GetMapInitActionPoint(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.InitActionPoint
end

function XColorTableConfigs.GetMapMaxActionPoint(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.MaxActionPoint
end

function XColorTableConfigs.GetMapInitTimeBlock(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.InitTimeBlock
end

function XColorTableConfigs.GetMapEventGroupId(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.EventGroupId
end

function XColorTableConfigs.GetMapDramaGroupId(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.DramaGroupId
end

function XColorTableConfigs.GetMapPointGroupId(id)
    local config = XColorTableConfigs.GetColorTableMap(id, true)
    return config.PointGroupId
end

--==================================================================================



-- ColorTableWinCondition 效果
--==================================================================================

function XColorTableConfigs.GetWinConditionName(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.Name
end

function XColorTableConfigs.GetWinConditionIcon(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.Icon
end

function XColorTableConfigs.GetWinConditionType(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.Type
end

function XColorTableConfigs.GetWinConditionStudyLevel(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.StudyLevel
end

function XColorTableConfigs.GetWinConditionColors(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.Colors
end

function XColorTableConfigs.GetWinConditionTriggerCount(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.TriggerCount
end

function XColorTableConfigs.GetWinConditionKillBossCount(id)
    local config = XColorTableConfigs.GetColorTableWinCondition(id, true)
    return config.KillBossCount
end

--==================================================================================



-- ColorTableCaptain 队长角色
--==================================================================================

function XColorTableConfigs.GetCaptainName(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.Name
end

function XColorTableConfigs.GetCaptainIcon(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.Icon
end

function XColorTableConfigs.GetCaptainSettleIcon(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.SettleIcon
end

function XColorTableConfigs.GetCaptainSkillIcon(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.SkillIcon
end

function XColorTableConfigs.GetCaptainSkillName(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.SkillName
end

function XColorTableConfigs.GetCaptainSkillDesc(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.SkillDesc
end

function XColorTableConfigs.GetCaptainFaceIcon(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.FaceIcon
end

function XColorTableConfigs.GetCaptainEffectId(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.EffectId
end

function XColorTableConfigs.GetCaptainCharacterIds(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.CharacterIds
end

function XColorTableConfigs.GetCaptainFightEventDesc(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.FightEventDesc
end

function XColorTableConfigs.GetCaptainCharacterDesc(captainId)
    local config = XColorTableConfigs.GetColorTableCaptain(captainId, true)
    return config.CharacterDesc
end

--==================================================================================



-- ColorTableTimeLine 时间线
--==================================================================================

function XColorTableConfigs.GetTimeLineType(id)
    local config = XColorTableConfigs.GetColorTableTimeline(id, true)
    return config.Type
end

function XColorTableConfigs.GetTimeLineIsEdge(id)
    local config = XColorTableConfigs.GetColorTableTimeline(id, true)
    return config.IsEdge
end

--==================================================================================



-- ColorTablePoint 地图点
--==================================================================================

function XColorTableConfigs.GetPointGroupId(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.GroupId
end

function XColorTableConfigs.GetPointPositionId(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.PositionId
end

function XColorTableConfigs.GetPointColor(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.Color
end

function XColorTableConfigs.GetPointName(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.Name
end

function XColorTableConfigs.GetPointIcon(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.Icon
end

function XColorTableConfigs.GetPointTipIcon(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.TipIcon
end

function XColorTableConfigs.GetPointPointDesc(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.PointDesc
end

function XColorTableConfigs.GetPointEffectDesc(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.EffectDesc
end

function XColorTableConfigs.GetPointType(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.Type
end

function XColorTableConfigs.GetPointParams(id)
    local config = XColorTableConfigs.GetColorTablePoint(id, true)
    return config.Params
end

-- 地图点位组字典
local PointGroups = {}
-- 初始化地图点位组
function XColorTableConfigs.InitPointGroups()
    local configs = XColorTableConfigs.GetColorTablePoint()
    for _, config in ipairs(configs) do
        local groupId = config.GroupId
        if XTool.IsTableEmpty(PointGroups[groupId]) then
            PointGroups[groupId] = {}
        end
        table.insert(PointGroups[groupId], config.Id)
    end
end

function XColorTableConfigs.GetPointsByGroupId(groupId)
    return PointGroups[groupId]
end

function XColorTableConfigs.GetPointConfig(groupId, pos, color)
    local configs = XColorTableConfigs.GetColorTablePoint()
    for _, config in ipairs(configs) do
        if config.GroupId == groupId and config.PositionId == pos and config.Color == color then 
            return config
        end
    end
end

--==================================================================================



-- ColorTablePointLink 地图点连线
--==================================================================================

function XColorTableConfigs.GetPointLinkMapType(id)
    local config = XColorTableConfigs.GetColorTablePointLink(id, true)
    return config.MapType
end

function XColorTableConfigs.GetPointLinkPosition(id)
    local config = XColorTableConfigs.GetColorTablePointLink(id, true)
    return config.Position
end

function XColorTableConfigs.GetPointLinkPositions(id)
    local config = XColorTableConfigs.GetColorTablePointLink(id, true)
    return config.LinkPositions
end

--==================================================================================



-- ColorTableEffect 各种效果
--==================================================================================

function XColorTableConfigs.GetEffectName(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.Name
end

function XColorTableConfigs.GetEffectType(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.Type
end

function XColorTableConfigs.GetEffectLifeType(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.LifeType
end

function XColorTableConfigs.GetEffectShowType(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.ShowType
end

function XColorTableConfigs.GetEffectShowDesc(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.ShowDesc
end

function XColorTableConfigs.GetEffectParams(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.Params
end

function XColorTableConfigs.GetEffectIcon(id)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    return config.Icon
end

function XColorTableConfigs.IsShowOnPointType(id, pointType)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    local showOnPointTypes = config.ShowOnPointTypes
    if XTool.IsTableEmpty(showOnPointTypes) then
        return false
    end
    for _, value in ipairs(showOnPointTypes) do
        if value == pointType then
            return true
        end
    end
    return false
end

function XColorTableConfigs.IsShowOnColor(id, color)
    local config = XColorTableConfigs.GetColorTableEffect(id, true)
    local showOnColors = config.ShowOnColors
    if XTool.IsTableEmpty(showOnColors) then
        return false
    end
    for _, value in ipairs(showOnColors) do
        if value == color then
            return true
        end
    end
    return false
end

--==================================================================================



-- ColorTableEvent 事件
--==================================================================================

function XColorTableConfigs.GetEventShowType(eventId)
    local config = XColorTableConfigs.GetColorTableEvent(eventId, true)
    return config.ShowType
end

function XColorTableConfigs.GetEventName(eventId)
    local config = XColorTableConfigs.GetColorTableEvent(eventId, true)
    return config.Name
end

function XColorTableConfigs.GetEventDesc(eventId)
    local config = XColorTableConfigs.GetColorTableEvent(eventId, true)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XColorTableConfigs.GetEventIcon(eventId)
    local config = XColorTableConfigs.GetColorTableEvent(eventId, true)
    return config.Icon
end

function XColorTableConfigs.GetEventSmallIcon(eventId)
    local config = XColorTableConfigs.GetColorTableEvent(eventId, true)
    return config.SmallIcon
end

--==================================================================================



-- ColorTableDrama
--==================================================================================

function XColorTableConfigs.GetDramaParams(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.Params
end

function XColorTableConfigs.GetDramaType(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.Type
end

function XColorTableConfigs.GetDramaConditionType(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.ConditionType
end

function XColorTableConfigs.GetDramaStoryId(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.StoryId
end

function XColorTableConfigs.GetDramaName(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.Name
end

function XColorTableConfigs.GetDramaDesc(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.Desc
end

function XColorTableConfigs.GetDramaIcon(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return config.Icon
end

function XColorTableConfigs.GetDramaRepeatable(dramaId)
    local config = XColorTableConfigs.GetColorTableDrama(dramaId, true)
    return XTool.IsNumberValid(config.Repeatable)
end

local DramaGroupDic = {}
function XColorTableConfigs.InitDramaGroupDic()
    local configs = XColorTableConfigs.GetColorTableDrama()
    for _, config in ipairs(configs) do
        if XTool.IsTableEmpty(DramaGroupDic[config.GroupId]) then
            DramaGroupDic[config.GroupId] = {}
        end
        table.insert(DramaGroupDic[config.GroupId], config.Id)
    end
end

function XColorTableConfigs.GetDramaByGroup(groupId)
    return DramaGroupDic[groupId]
end

--==================================================================================



-- ColorTableHandbook 遭遇图鉴
--==================================================================================
function XColorTableConfigs.CreateHandBookDramaIdDic()
    local handBookConfig = XColorTableConfigs.GetColorTableHandbook()
    for _, config in ipairs(handBookConfig) do
        if config.Type == XColorTableConfigs.HandBookType.Drama then
            HandBookDramaIdDic[config.DramaId] = config.Id
        end
    end
end

function XColorTableConfigs.GetHandBookIdByDramaId(dramaId)
    local handBookId = HandBookDramaIdDic[dramaId]
    return handBookId
end
--==================================================================================



-- ColorTableDifficultyReward 难度进度奖励
--==================================================================================
function XColorTableConfigs.GetDifficultyRewardConfig(chapterId, difficultyType)
    local configs = XColorTableConfigs.GetColorTableDifficultyReward()
    for _, config in ipairs(configs) do
        if config.ChapterId == chapterId and config.DifficultyId == difficultyType then
            return config
        end
    end
    return nil
end

--==================================================================================



-- ColorTableSpecialRole 特殊角色加成
--==================================================================================
    
function XColorTableConfigs.GetSpecialRoleDesc(roleId)
    local configs = XColorTableConfigs.GetColorTableSpecialRole()
    for _, config in pairs(configs) do
        if config.Id == roleId then 
            return config.Desc
        end
    end

    return ""
end
--==================================================================================



-- ColorTableBuffGroup 关卡buff组
--==================================================================================

function XColorTableConfigs.GetStageBuffConfigList(stageId)
    local buffIdList = {}
    local configs = XColorTableConfigs.GetColorTableBuffGroup()
    for _, config in ipairs(configs) do
        if config.StageId == stageId then
            buffIdList = config.BuffIds
            break
        end
    end

    local buffCfgList = {}
    for _, buffId in ipairs(buffIdList) do
        local buffCfg = XColorTableConfigs.GetColorTableBuffDetail(buffId)
        table.insert(buffCfgList, buffCfg)
    end
    return buffCfgList
end


--==================================================================================
