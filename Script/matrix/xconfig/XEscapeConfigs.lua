XEscapeConfigs = XEscapeConfigs or {}

local SHARE_TABLE_PATH = "Share/Fuben/Escape/"
local CLIENT_TABLE_PATH = "Client/Fuben/Escape/"

--章节难度
XEscapeConfigs.Difficulty = {
    Normal = 1,
    Hard = 2,
}

--关卡层状态
XEscapeConfigs.LayerState = {
    Lock = 1,   --未开启
    Now = 2,    --当前可挑战
    Pass = 3,   --已通关
}

--结算显示的界面布局
XEscapeConfigs.ShowSettlePanel = {
    SelfWinInfo = 1, --战后结算
    AllWinInfo = 2,  --阶段结算
}

--章节结算显示的参数类型
XEscapeConfigs.ChapterSettleCondType = {
    RemainTime = 1,     --剩余时间
    HitTimes = 2,       --受击
    TrapedTimes = 3,    --陷阱受击
}

--战后结算显示的参数类型
XEscapeConfigs.FightSettleCondType = {
    StageName = 1,  --关卡名
    Score = 2,      --积分
}

XEscapeConfigs.TacticsClearCount = 1

---@type XConfig
local _ConfigTactics = nil
---@type XConfig
local _ConfigTacticsEffect = nil
---@type XConfig
local _ConfigTacticsEffectGroup = nil
---@type XConfig
local _ConfigTacticsNode = nil

local _EscapeChapterDifficultyDir = {}

function XEscapeConfigs.Init()
    XConfigCenter.CreateGetProperties(XEscapeConfigs, {
        "EscapeActivity",
        "EscapeChapter",
        "EscapeLayer",
        "EscapeStage",
        "EscapeTask",
        "EscapeClientConfig",
        "EscapeStageColorPrefab",
    }, { 
        "ReadByIntKey", SHARE_TABLE_PATH .. "EscapeActivity.tab", XTable.XTableEscapeActivity, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "EscapeChapter.tab", XTable.XTableEscapeChapter, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "EscapeLayer.tab", XTable.XTableEscapeLayer, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "EscapeStage.tab", XTable.XTableEscapeStage, "StageId",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "EscapeTask.tab", XTable.XTableEscapeTask, "Id",
        "ReadByStringKey", CLIENT_TABLE_PATH .. "EscapeClientConfig.tab", XTable.XTableEscapeClientConfig, "Key",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "EscapeStageColorPrefab.tab", XTable.XTableEscapeStageColorPrefab, "Id",
    })
    
    _ConfigTactics = XConfig.New(SHARE_TABLE_PATH.."EscapeTactics.tab", XTable.XTableEscapeTactics, "Id")
    _ConfigTacticsEffect = XConfig.New(SHARE_TABLE_PATH.."EscapeTacticsEffect.tab", XTable.XTableEscapeTacticsEffect, "Id")
    _ConfigTacticsEffectGroup = XConfig.New(SHARE_TABLE_PATH.."EscapeTacticsEffectGroup.tab", XTable.XTableEscapeTacticsEffectGroup, "Id")
    _ConfigTacticsNode = XConfig.New(SHARE_TABLE_PATH.."EscapeTacticsNode.tab", XTable.XTableEscapeTacticsNode, "Id")
    
    XEscapeConfigs._InitEscapeChapterDifficultyList()
end

function XEscapeConfigs.GetEscapeStageIdList()
    local configs = XEscapeConfigs.GetEscapeStage()
    local stageIdList = {}
    for stageId in pairs(configs) do
        table.insert(stageIdList, stageId)
    end
    return stageIdList
end

--机器人Id是否在关卡类型表中
function XEscapeConfigs.IsStageTypeRobot(robotId)
    local robotIdList = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.Escape)
    for _, robotIdCfg in ipairs(robotIdList) do
        if robotId == robotIdCfg then
            return true
        end
    end
    return false
end

--------------------------EscapeActivity 活动表 begin------------------------
function XEscapeConfigs.GetActivityTimeId(id)
    local config = XEscapeConfigs.GetEscapeActivity(id, true)
    return config.TimeId
end

function XEscapeConfigs.GetActivityName(id)
    local config = XEscapeConfigs.GetEscapeActivity(id, true)
    return config.Name
end

function XEscapeConfigs.GetActivityBackground(id)
    local config = XEscapeConfigs.GetEscapeActivity(id, true)
    return config.Background
end
--------------------------EscapeActivity 活动表 end------------------------

--------------------------EscapeChapter 章节表 begin------------------------
local IsInitEscapeChapterDic = false
local EscapeGroupIdToChapterIdsDic = {} --组Id对应的章节Id列表
local InitTheatreDecorationDic = function()
    if IsInitEscapeChapterDic then
        return
    end

    local configs = XEscapeConfigs.GetEscapeChapter()
    for chapterId, v in pairs(configs) do
        if not EscapeGroupIdToChapterIdsDic[v.GroupId] then
            EscapeGroupIdToChapterIdsDic[v.GroupId] = {}
        end
        table.insert(EscapeGroupIdToChapterIdsDic[v.GroupId], chapterId)
    end
    for _, chapterIdList in pairs(EscapeGroupIdToChapterIdsDic) do
        table.sort(chapterIdList, function(a, b)
            local difficultyA = XEscapeConfigs.GetChapterDifficulty(a)
            local difficultyB = XEscapeConfigs.GetChapterDifficulty(b)
            if difficultyA ~= difficultyB then
                return difficultyA < difficultyB
            end
            return a < b
        end) 
    end

    IsInitEscapeChapterDic = true
end

function XEscapeConfigs.GetEscapeChapterGroupIdList()
    InitTheatreDecorationDic()
    local groupIdList = {}
    for groupId in pairs(EscapeGroupIdToChapterIdsDic) do
        table.insert(groupIdList, groupId)
    end
    table.sort(groupIdList, function(a, b)
        return a < b
    end)
    return groupIdList
end

function XEscapeConfigs._InitEscapeChapterDifficultyList()
    _EscapeChapterDifficultyDir = {}
    local configs = XEscapeConfigs.GetEscapeChapter()
    for chapterId, v in pairs(configs) do
        if not _EscapeChapterDifficultyDir[v.Difficulty] then
            _EscapeChapterDifficultyDir[v.Difficulty] = {}
        end
        _EscapeChapterDifficultyDir[v.Difficulty][#_EscapeChapterDifficultyDir[v.Difficulty] + 1] =  chapterId
    end
    for _, chapterIdList in pairs(_EscapeChapterDifficultyDir) do
        table.sort(chapterIdList, function(a, b)
            return a < b
        end)
    end
end

function XEscapeConfigs.GetEscapeChapterIdListByDifficulty(difficulty)
    return _EscapeChapterDifficultyDir[difficulty]
end

function XEscapeConfigs.GetEscapeChapterIdListByGroupId(groupId)
    InitTheatreDecorationDic()
    return EscapeGroupIdToChapterIdsDic[groupId]
end

function XEscapeConfigs.GetChapterName(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.Name
end

function XEscapeConfigs.GetChapterEnName(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.EnName
end

function XEscapeConfigs.GetChapterMaxTime(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.MaxTime
end

function XEscapeConfigs.GetChapterEnvironmentDesc(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.EnvironmentDesc
end

function XEscapeConfigs.GetChapterOpenCondition(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.OpenCondition
end

function XEscapeConfigs.GetChapterTimeId(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.TimeId
end

function XEscapeConfigs.GetChapterDifficulty(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.Difficulty
end

function XEscapeConfigs.GetChapterGroupId(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.GroupId
end

function XEscapeConfigs.GetChapterLayerIds(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.LayerIds
end

function XEscapeConfigs.GetChapterBuffDesc(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.BuffDesc
end

function XEscapeConfigs.GetChapterShowFightEventIds(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.ShowFightEventIds
end

function XEscapeConfigs.GetChapterInitialTime(id)
    local config = XEscapeConfigs.GetEscapeChapter(id, true)
    return config.InitialTime
end
--------------------------EscapeChapter 章节表 end--------------------------

--------------------------EscapeLayer 区域表 begin--------------------------
function XEscapeConfigs.GetLayerClearStageCount(id)
    local config = XEscapeConfigs.GetEscapeLayer(id, true)
    return config.ClearStageCount
end

function XEscapeConfigs.GetLayerClearTacticsCount(id)
    if XTool.IsNumberValid(XEscapeConfigs.GetLayerClearStageCount(id)) then
        return 0
    end
    return XEscapeConfigs.TacticsClearCount
end

function XEscapeConfigs.GetLayerNodeCount(id)
    return XEscapeConfigs.GetLayerClearStageCount(id) + XEscapeConfigs.GetLayerClearTacticsCount(id)
end

function XEscapeConfigs.GetLayerStageIds(id)
    local config = XEscapeConfigs.GetEscapeLayer(id, true)
    return config.StageIds
end

function XEscapeConfigs.GetLayerTacticsNodeIds(id)
    local config = XEscapeConfigs.GetEscapeLayer(id, true)
    return config.TacticsNodeIds
end
--------------------------EscapeLayer 区域表 end----------------------------

--------------------------EscapeStage 关卡表 begin--------------------------
function XEscapeConfigs.GetStageColor(id)
    local config = XEscapeConfigs.GetEscapeStage(id, true)
    return config.Color
end

function XEscapeConfigs.GetStageAwardTime(id)
    local config = XEscapeConfigs.GetEscapeStage(id, true)
    return config.AwardTime
end

function XEscapeConfigs.GetStageGridDesc(id)
    local config = XEscapeConfigs.GetEscapeStage(id, true)
    return config.GridDesc
end
--------------------------EscapeStage 关卡表 end----------------------------

--------------------------EscapeTask 任务表 begin------------------------
function XEscapeConfigs.GetTaskGroupIdList()
    local configs = XEscapeConfigs.GetEscapeTask()
    local taskGroupIdList = {}
    for id in pairs(configs) do
        table.insert(taskGroupIdList, id)
    end
    return taskGroupIdList
end

function XEscapeConfigs.GetTaskIdList(id)
    local config = XEscapeConfigs.GetEscapeTask(id, true)
    return config.TaskId
end

function XEscapeConfigs.GetTaskName(id)
    local config = XEscapeConfigs.GetEscapeTask(id, true)
    return config.Name
end
--------------------------EscapeTask 任务表 end---------------------------

--------------------------EscapeClientConfig begin------------------------
function XEscapeConfigs.GetHelpKey()
    local config = XEscapeConfigs.GetEscapeClientConfig("HelpKey", true)
    return config.Values[1]
end

function XEscapeConfigs.GetRemainTimeColor()
    local config = XEscapeConfigs.GetEscapeClientConfig("RemainTimeColor", true)
    return config.Values
end

function XEscapeConfigs.GetRemainTimeShowColor()
    local config = XEscapeConfigs.GetEscapeClientConfig("RemainTimeShowColor", true)
    return config.Values
end

function XEscapeConfigs.GetChapterSettleCondDesc()
    local config = XEscapeConfigs.GetEscapeClientConfig("ChapterSettleCondDesc", true)
    return config.Values
end

function XEscapeConfigs.GetChapterSettleRemainTimeGradeImgPath(score)
    local gradeIndex = XEscapeConfigs.GetGradeIndexByScore(score)
    local gradeConfig = XEscapeConfigs.GetEscapeClientConfig("ChapterSettleRemainTimeGradeImgPath", true)
    return gradeConfig.Values[gradeIndex or #gradeConfig.Values]
end

function XEscapeConfigs.GetChapterSettleRemainTimeGrade(score)
    local gradeIndex = XEscapeConfigs.GetGradeIndexByScore(score)
    local config = XEscapeConfigs.GetEscapeClientConfig("ChapterSettleRemainTimeGrade", true)
    return config.Values[gradeIndex or #config.Values]
end

function XEscapeConfigs.GetGradeIndexByScore(score)
    local scoreConfig = XEscapeConfigs.GetEscapeClientConfig("ChapterSettleRemainTimeScore", true)
    for i, value in ipairs(scoreConfig.Values) do
        local scoreCfg = tonumber(value)
        if scoreCfg and score >= scoreCfg then
            return i
        end
    end
end

function XEscapeConfigs.GetDifficultyName(difficulty)
    local config = XEscapeConfigs.GetEscapeClientConfig("DifficultyName", true)
    return config.Values[difficulty] or ""
end

function XEscapeConfigs.GetMainBg(index)
    local config = XEscapeConfigs.GetEscapeClientConfig("MainBg", true)
    return config.Values[index]
end

function XEscapeConfigs.GetFightSettleCondDesc(index)
    local config = XEscapeConfigs.GetEscapeClientConfig("FightSettleCondDesc", true)
    return config.Values[index] or config.Values
end

function XEscapeConfigs.GetMainShowRewardId()
    local config = XEscapeConfigs.GetEscapeClientConfig("MainShowRewardId", true)
    return config.Values[1] or config.Values
end

function XEscapeConfigs.GetMainDifficultyBgUrl(difficulty)
    local config = XEscapeConfigs.GetEscapeClientConfig("MainDifficultyBgUrl", true)
    return config.Values[difficulty] or config.Values
end

function XEscapeConfigs.GetChapterNumIconUrl(index)
    local config = XEscapeConfigs.GetEscapeClientConfig("ChapterNumIconUrl", true)
    return config.Values[index] or config.Values
end

function XEscapeConfigs.GetChapterDifficultyBgUrl(difficulty)
    local config = XEscapeConfigs.GetEscapeClientConfig("ChapterDifficultyBgUrl", true)
    return config.Values[difficulty] or config.Values
end

function XEscapeConfigs.GetChapterDifficultyLockUrl(difficulty)
    local config = XEscapeConfigs.GetEscapeClientConfig("ChapterDifficultyLockUrl", true)
    return config.Values[difficulty] or config.Values
end

function XEscapeConfigs.GetStageTitleColor(color)
    local config = XEscapeConfigs.GetEscapeClientConfig("StageTitleColor", true)
    return config.Values[color] or config.Values
end

function XEscapeConfigs.GetStageTitleBg(color)
    local config = XEscapeConfigs.GetEscapeClientConfig("StageTitleBg", true)
    return config.Values[color] or config.Values
end

---@return string
function XEscapeConfigs.GetSettleTitleIcon(isWin)
    local config = XEscapeConfigs.GetEscapeClientConfig("SettleTitleIcon", true)
    return config.Values[isWin and 1 or 2] or config.Values
end

---@return string
function XEscapeConfigs.GetSettleTitleText(isWin)
    local config = XEscapeConfigs.GetEscapeClientConfig("SettleTitleText", true)
    return config.Values[isWin and 1 or 2] or config.Values
end
--------------------------EscapeClientConfig end--------------------------

--------------------------EscapeStageColorPrefab 关卡颜色对应的预制 begin------------------------
function XEscapeConfigs.GetEscapeStageColorPrefabById(id)
    local config = XEscapeConfigs.GetEscapeStageColorPrefab(id, true)
    return config.Prefab
end
--------------------------EscapeStageColorPrefab end--------------------------


--region Tactics 策略
function XEscapeConfigs.GetAllTactics()
    return _ConfigTactics:GetConfigs()
end

---@return string
function XEscapeConfigs.GetTacticsName(id)
    return _ConfigTactics:GetProperty(id, "Name")
end

---@return number
function XEscapeConfigs.GetTacticsType(id)
    return _ConfigTactics:GetProperty(id, "Type")
end

---@return string
function XEscapeConfigs.GetTacticsDesc(id)
    return _ConfigTactics:GetProperty(id, "Desc")
end

---@return string
function XEscapeConfigs.GetTacticsIcon(id)
    return _ConfigTactics:GetProperty(id, "Icon")
end

---@return number
function XEscapeConfigs.GetTacticsQuality(id)
    return _ConfigTactics:GetProperty(id, "Quality")
end

---@return number
function XEscapeConfigs.GetTacticsUnlockConditionId(id)
    return _ConfigTactics:GetProperty(id, "UnlockConditionId")
end

---@return number
function XEscapeConfigs.GetTacticsEffectGroupId(id)
    return _ConfigTactics:GetProperty(id, "EffectGroupId")
end
--endregion

--region TacticsEffect
---@return number
function XEscapeConfigs.GetTacticsEffectType(id)
    return _ConfigTacticsEffect:GetProperty(id, "Type")
end

---@return string
function XEscapeConfigs.GetTacticsEffectDesc(id)
    return _ConfigTacticsEffect:GetProperty(id, "Desc")
end

---@return number[]
function XEscapeConfigs.GetTacticsEffectParams(id)
    return _ConfigTacticsEffect:GetProperty(id, "Params")
end
--endregion

--region TacticsEffectGroup
---@return number[]
function XEscapeConfigs.GetTacticsEffectGroupFightEventIds(tacticsEffectGroupId)
    return _ConfigTacticsEffectGroup:GetProperty(tacticsEffectGroupId, "FightEventIds")
end

---@return number[]
function XEscapeConfigs.GetTacticsEffectGroupTacticsEffectIds(tacticsEffectGroupId)
    return _ConfigTacticsEffectGroup:GetProperty(tacticsEffectGroupId, "TacticsEffectIds")
end
--endregion

--region TacticsNode
function XEscapeConfigs.GetTacticsNodeName(id)
    return _ConfigTacticsNode:GetProperty(id, "Name")
end

---@return string
function XEscapeConfigs.GetTacticsNodeBriefDesc(id)
    return _ConfigTacticsNode:GetProperty(id, "BrifeDesc")
end

---@return string
function XEscapeConfigs.GetTacticsNodeDesc(id)
    return _ConfigTacticsNode:GetProperty(id, "Desc")
end

---@return string
function XEscapeConfigs.GetTacticsNodeShowIcon(id)
    return _ConfigTacticsNode:GetProperty(id, "ShowIcon")
end
--endregion