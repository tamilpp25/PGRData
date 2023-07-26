local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local next = next
XMultiDimConfig = XMultiDimConfig or {}

local SHARE_MULTI_DIM_ACTIVITY = "Share/Fuben/MultiDim/MultiDimActivity.tab"
local SHARE_MULTI_DIM_DIFFICULTY = "Share/Fuben/MultiDim/MultiDimDifficulty.tab"
local SHARE_MULTI_DIM_RANK_REWARD = "Share/Fuben/MultiDim/MultiDimRankReward.tab"
local SHARE_MULTI_DIM_SINGLE_FUBEN = "Share/Fuben/MultiDim/MultiDimSingleFuben.tab"
local SHARE_MULTI_DIM_TALENT = "Share/Fuben/MultiDim/MultiDimTalent.tab"
local SHARE_MULTI_DIM_THEME = "Share/Fuben/MultiDim/MultiDimTheme.tab"
local SHARE_MULTI_DIM_CONFIG = "Share/Fuben/MultiDim/MultiDimConfig.tab"
local SHARE_MULTI_DIM_CHARACTER_CAREER = "Share/Fuben/MultiDim/MultiDimCharacterCareer.tab"

local CLIENT_MULTI_DIM_ACTIVITY_DETAIL = "Client/Fuben/MultiDim/MultiDimActivityDetail.tab"
local CLIENT_MULTI_DIM_THEME_DETAIL = "Client/Fuben/MultiDim/MultiDimThemeDetail.tab"
local CLIENT_MULTI_DIM_DIFFICULTY_DETAIL = "Client/Fuben/MultiDim/MultiDimDifficultyDetail.tab"
local CLIENT_MULTI_DIM_CAREER = "Client/Fuben/MultiDim/MultiDimCareer.tab"
local CLIENT_MULTI_DIM_BUFF_DETAILS = "Client/Fuben/MultiDim/MultiDimBuffDetails.tab"
local CLIENT_MULTI_DIM_TALENT_DETAIL = "Client/Fuben/MultiDim/MultiDimTalentDetail.tab"

local MultiDimActivity = {}
local MultiDimDifficulty = {}
local MultiDimRankReward = {}
local MultiDimSingleFuben = {}
local MultiDimTalent = {}
local MultiDimTheme = {}
local MultiDimCharacterCareer = {}

local MultiDimActivityDetail = {}
local MultiDimThemeDetail = {}
local MultiDimDifficultyDetail = {}
local MultiDimCareer = {}
local MultiDimBuffDetails = {}
local MultiDimTalentDetail = {}

local DifficultyGroups = {}
local DifficultyGroupsDetail = {}
local MultiSingleStageData = {}
local ThemeSingleStageList = {}
local MultiDifficultyStageData = {}
local TalentLevelGroups = {}
local TalentLevelGroupsDetail = {}
local RankRewardGroups = {}

XMultiDimConfig.TalentType = {
    Talent01 = 1, -- 子天赋1
    Talent02 = 2, -- 子天赋2
    Talent03 = 3, -- 子天赋3
    CoreTalent = 4, -- 核心天赋
}

XMultiDimConfig.MAX_SPECIAL_NUM = 3 -- 前几名特殊处理

XMultiDimConfig.RANK_MODEL = {
    SINGLE_RANK = 1, -- 单人
    TEAM_RANK = 2, -- 多人
}

XMultiDimConfig.MultiDimFirstReward = "MultiDimFirstReward" --首通奖励红点
XMultiDimConfig.MultiDimThemeUnlock = "MultiDimThemeUnlock" --天赋技能是否解锁
XMultiDimConfig.MultiDimDefaultThemeId = "MultiDimDefaultThemeId" --默认主题

local function InitDifficultyGroups()
    DifficultyGroups = {}
    for _, config in pairs(MultiDimDifficulty) do
        if DifficultyGroups[config.ThemeId] == nil then
            DifficultyGroups[config.ThemeId] = {}
        end
        DifficultyGroups[config.ThemeId][config.DifficultyId] = config
    end
end

local function InitDifficultyGroupsDetail()
    DifficultyGroupsDetail = {}
    for _, config in pairs(MultiDimDifficultyDetail) do
        if DifficultyGroupsDetail[config.ThemeId] == nil then
            DifficultyGroupsDetail[config.ThemeId] = {}
        end
        DifficultyGroupsDetail[config.ThemeId][config.DifficultyId] = config
    end
end

local function InitMultiFubenSingleData()
    for key, value in ipairs(MultiDimSingleFuben) do
        if value.StageId and value.StageId > 0 then --配置了StageId
            -- 将MultiDimSingleFuben的数据改成以stageId为key
            MultiSingleStageData[value.StageId] = value

            -- 将MultiDimSingleFuben的Stage按theme排列成List
            if not ThemeSingleStageList[value.ThemeId] or not next(ThemeSingleStageList[value.ThemeId]) then
                ThemeSingleStageList[value.ThemeId] = {}
            end
            tableInsert(ThemeSingleStageList[value.ThemeId], value.StageId)
        end
    end
end
local function InitTalentLevelGroups()
    TalentLevelGroups = {}
    for _, config in pairs(MultiDimTalent) do
        if TalentLevelGroups[config.ClassId] == nil then
            TalentLevelGroups[config.ClassId] = {}
        end
        if TalentLevelGroups[config.ClassId][config.TalentType] == nil then
            TalentLevelGroups[config.ClassId][config.TalentType] = {}
        end
        TalentLevelGroups[config.ClassId][config.TalentType][config.Level] = config
    end
 end

local function InitMultiDimDifficultyStageData()
    for key, value in pairs(MultiDimDifficulty) do
        if value.StageId and value.StageId > 0 then --配置了StageId
            -- 将 MultiDimDifficulty 的数据改成以stageId为key
            MultiDifficultyStageData[value.StageId] = value
        end
    end
end

local function InitTalentLevelGroupsDetail()
    TalentLevelGroupsDetail = {}
    for _, config in pairs(MultiDimTalentDetail) do
        if TalentLevelGroupsDetail[config.ClassId] == nil then
            TalentLevelGroupsDetail[config.ClassId] = {}
        end
        if TalentLevelGroupsDetail[config.ClassId][config.TalentType] == nil then
            TalentLevelGroupsDetail[config.ClassId][config.TalentType] = {}
        end
        TalentLevelGroupsDetail[config.ClassId][config.TalentType][config.Level] = config
    end
end

local function InitRankRewardGroups()
    RankRewardGroups = {}
    for _, config in pairs(MultiDimRankReward) do
        if RankRewardGroups[config.ThemeId] == nil then
            RankRewardGroups[config.ThemeId] = {}
        end
        tableInsert(RankRewardGroups[config.ThemeId], config)
    end
end

function XMultiDimConfig.Init()
    MultiDimActivity = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_ACTIVITY, XTable.XTableMultiDimActivity, "Id")
    MultiDimDifficulty = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_DIFFICULTY, XTable.XTableMultiDimDifficulty, "Id")
    MultiDimRankReward = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_RANK_REWARD, XTable.XTableMultiDimRankReward, "Id")
    MultiDimSingleFuben = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_SINGLE_FUBEN, XTable.XTableMultiDimSingleFuben, "Id")
    MultiDimTalent = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_TALENT, XTable.XTableMultiDimTalent, "Id")
    MultiDimTheme = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_THEME, XTable.XTableMultiDimTheme, "Id")
    MultiDimCharacterCareer = XTableManager.ReadByIntKey(SHARE_MULTI_DIM_CHARACTER_CAREER, XTable.XTableMultiDimCharacterCareer, "Id")
    XConfigCenter.CreateGetPropertyByFunc(XMultiDimConfig, "MultiDimConfig", function()
        return XTableManager.ReadByStringKey(SHARE_MULTI_DIM_CONFIG, XTable.XTableMultiDimConfig, "Key")
    end)
    
    MultiDimActivityDetail = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_ACTIVITY_DETAIL, XTable.XTableMultiDimActivityDetail, "Id")
    MultiDimThemeDetail = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_THEME_DETAIL, XTable.XTableMultiDimThemeDetail, "Id")
    MultiDimDifficultyDetail = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_DIFFICULTY_DETAIL, XTable.XTableMultiDimDifficultyDetail, "Id")
    MultiDimCareer = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_CAREER, XTable.XTableMultiDimCareer, "Career")
    MultiDimBuffDetails = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_BUFF_DETAILS, XTable.XTableMultiDimBuffDetails, "Id")
    MultiDimTalentDetail = XTableManager.ReadByIntKey(CLIENT_MULTI_DIM_TALENT_DETAIL, XTable.XTableMultiDimTalentDetail, "Id")

    InitDifficultyGroups()
    InitDifficultyGroupsDetail()
    InitMultiFubenSingleData()
    InitMultiDimDifficultyStageData()
    InitTalentLevelGroups()
    InitTalentLevelGroupsDetail()
    InitRankRewardGroups()
end

--region 获取配置表

local function GetMultiDimActivity(id)
    local config = MultiDimActivity[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimActivity", "tab", SHARE_MULTI_DIM_ACTIVITY, "id", tostring(id))
        return
    end
    return config
end

local function GetMultiDimDifficulty(themeId, difficultyId)
    local themeConfig = DifficultyGroups[themeId]
    if not themeConfig then
        XLog.ErrorTableDataNotFound("GetMultiDimDifficulty", "tab", SHARE_MULTI_DIM_DIFFICULTY, "themeId", tostring(themeId))
        return
    end
    local config = themeConfig[difficultyId]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimDifficulty", "tab", SHARE_MULTI_DIM_DIFFICULTY, "difficultyId", tostring(difficultyId))
        return
    end
    return config
end

local function GetRankRewardGroups(themeId)
    local config = RankRewardGroups[themeId]
    if not config then
        XLog.ErrorTableDataNotFound("GetRankRewardGroups", "tab", SHARE_MULTI_DIM_RANK_REWARD, "themeId", tostring(themeId))
        return
    end
    return config
end

local function GetMultiDimSingleFubenCfg()
    return MultiDimSingleFuben
end

local function GetMultiDimTalent(id)
    local config = MultiDimTalent[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimTalent", "tab", SHARE_MULTI_DIM_TALENT, "id", tostring(id))
        return
    end
    return config
end

local function GetMultiDimTheme(id)
    local config = MultiDimTheme[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimTheme", "tab", SHARE_MULTI_DIM_THEME, "id", tostring(id))
        return
    end
    return config
end

 function XMultiDimConfig.GetMultiDimCharacterCareer(id)
    local config = MultiDimCharacterCareer[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimCharacterCareer", "tab", SHARE_MULTI_DIM_CHARACTER_CAREER, "id", tostring(id))
        return
    end
    return config
end

local function GetMultiDimActivityDetail(id)
    local config = MultiDimActivityDetail[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimActivityDetail", "tab", CLIENT_MULTI_DIM_ACTIVITY_DETAIL, "id", tostring(id))
        return
    end
    return config
end

local function GetMultiDimThemeDetail(id)
    local config = MultiDimThemeDetail[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimThemeDetail", "tab", CLIENT_MULTI_DIM_THEME_DETAIL, "id", tostring(id))
        return
    end
    return config
end

local function GetDifficultyGroupsDetail(themeId, difficultyId)
    local themeConfig = DifficultyGroupsDetail[themeId]
    if not themeConfig then
        XLog.ErrorTableDataNotFound("GetDifficultyGroupsDetail", "tab", CLIENT_MULTI_DIM_DIFFICULTY_DETAIL, "themeId", tostring(themeId))
        return
    end
    local config = themeConfig[difficultyId]
    if not config then
        XLog.ErrorTableDataNotFound("GetDifficultyGroupsDetail", "tab", CLIENT_MULTI_DIM_DIFFICULTY_DETAIL, "difficultyId", tostring(difficultyId))
        return
    end
    return config
end

local function GetMultiDimCareer(career)
    local config = MultiDimCareer[career]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimCareer", "tab", CLIENT_MULTI_DIM_CAREER, "career", tostring(career))
        return
    end
    return config
end

local function GetMultiDimBuffDetails(buffId)
    local config = MultiDimBuffDetails[buffId]
    if not config then
        XLog.ErrorTableDataNotFound("GetMultiDimBuffDetails", "tab", CLIENT_MULTI_DIM_BUFF_DETAILS, "buffId", tostring(buffId))
        return
    end
    return config
end

local function GetTalentLevelGroups(classId, talentType, level)
    local classInfo = TalentLevelGroups[classId]
    if not classInfo then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroups", "tab", SHARE_MULTI_DIM_TALENT, "classId", tostring(classId))
        return
    end
    local talentTypeInfo = classInfo[talentType]
    if not talentTypeInfo then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroups", "tab", SHARE_MULTI_DIM_TALENT, "talentType", tostring(talentType))
        return
    end
    local config = talentTypeInfo[level]
    if not config then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroups", "tab", SHARE_MULTI_DIM_TALENT, "level", tostring(level))
        return
    end
    return config
end

local function GetTalentLevelGroupsDetail(classId, talentType, level)
    local classInfo = TalentLevelGroupsDetail[classId]
    if not classInfo then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroupsDetail", "tab", CLIENT_MULTI_DIM_TALENT_DETAIL, "classId", tostring(classId))
        return
    end
    local talentTypeInfo = classInfo[talentType]
    if not talentTypeInfo then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroupsDetail", "tab", CLIENT_MULTI_DIM_TALENT_DETAIL, "talentType", tostring(talentType))
        return
    end
    local config = talentTypeInfo[level]
    if not config then
        XLog.ErrorTableDataNotFound("GetTalentLevelGroupsDetail", "tab", CLIENT_MULTI_DIM_TALENT_DETAIL, "level", tostring(level))
        return
    end
    return config
end

--endregion

--region 活动相关

function XMultiDimConfig.GetActivityTimeId(activityId)
    local config = GetMultiDimActivity(activityId)
    return config.TimeId or 0
end

function XMultiDimConfig.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in pairs(MultiDimActivity) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

function XMultiDimConfig.GetActivityName(activityId)
    local config = GetMultiDimActivity(activityId)
    return config.Name or ""
end

function XMultiDimConfig.GetActivityItemId(activityId)
    local config = GetMultiDimActivityDetail(activityId)
    return config.ItemId or 0
end

function XMultiDimConfig.GetActivityBannerBg(activityId)
    local config = GetMultiDimActivityDetail(activityId)
    return config.BannerBg or ""
end

function XMultiDimConfig.GetActivityTaskGroupId(activityId)
    local config = GetMultiDimActivityDetail(activityId)
    return config.TaskGroupId or nil
end

function XMultiDimConfig.GetActivityTaskGroupName(activityId)
    local config = GetMultiDimActivityDetail(activityId)
    return config.TaskGroupName or nil
end

--endregion

--region 主题相关
function XMultiDimConfig.GetThemeAllId()
    local allId = {}
    for _, config in pairs(MultiDimTheme) do
        tableInsert(allId, config.Id)
    end
    tableSort(allId, function(a, b)
        return a < b
    end)
    return allId
end

function XMultiDimConfig.GetMultiDimThemes()
    return MultiDimTheme
end

function XMultiDimConfig.GetMultiDimThemeDetails()
    return MultiDimThemeDetail
end

function XMultiDimConfig.GetMultiDimTheme(id)
    local config = GetMultiDimTheme(id)
    return config or nil
end

function XMultiDimConfig.GetMultiDimThemeDetail(id)
    local config = GetMultiDimThemeDetail(id)
    return config or nil
end

function XMultiDimConfig.GetThemeTimeIdById(id)
    local config = GetMultiDimTheme(id)
    return config.TimeId or 0
end

function XMultiDimConfig.GetThemeNameById(id)
    local config = GetMultiDimTheme(id)
    return config.Name or ""
end

function XMultiDimConfig.GetThemeFirstPassTimeIdById(id)
    local config = GetMultiDimTheme(id)
    return config.ThemeFirstPassTimeId or 0
end

function XMultiDimConfig.GetThemeDailyFirstPassRewardIdById(id)
    local config = GetMultiDimTheme(id)
    return config.ThemeDailyFirstPassRewardId or 0
end

function XMultiDimConfig.GetThemeMatchConditionIdById(id)
    local config = GetMultiDimTheme(id)
    return config.MatchConditionId or 0
end

function XMultiDimConfig.GetThemeModelId(id)
    local config = GetMultiDimThemeDetail(id)
    return config.ModelId or ""
end

function XMultiDimConfig.GetThemeModelScale(id)
    local config = GetMultiDimThemeDetail(id)
    return config.ModelScale or 1
end

function XMultiDimConfig.GetMultiSingleStageListByThemeId(themeId)
    local config = ThemeSingleStageList[themeId]
    return config or nil
end

--endregion

--region 难度相关
function XMultiDimConfig.GetMultiSingleStageDataById(stageId)
    local config = MultiSingleStageData[stageId]
    return config or nil
end

function XMultiDimConfig.GetMultiDimDifficultyStageData(stageId)
    local config = MultiDifficultyStageData[stageId]
    return config or nil
end

function XMultiDimConfig.GetMultiSingleStageDatas()
    return MultiSingleStageData
end

function XMultiDimConfig.GetMultiDimSingleFubenCfg()
    local config = GetMultiDimSingleFubenCfg()
    return config
end

function XMultiDimConfig.GetMultiDimBuffDetailsConfig(buffId)
    local config = GetMultiDimBuffDetails(buffId)
    return config
end

function XMultiDimConfig.GetMultiDimDifficultyStageId()
    local stageIds = {}
    for _, config in pairs(MultiDimDifficulty) do
        if config then
            tableInsert(stageIds, config.StageId)
            for _, extraStageId in pairs(config.ExtraStageIds) do
                tableInsert(stageIds,extraStageId)
            end
        end
    end
    return stageIds
end

function XMultiDimConfig.GetDifficultyStageId(themeId, difficultyId)
    local config = GetMultiDimDifficulty(themeId, difficultyId)
    return config.StageId or 0
end

function XMultiDimConfig.GetDifficultyFirstPassReward(themeId, difficultyId)
    local config = GetMultiDimDifficulty(themeId, difficultyId)
    return config.DifficultyFirstPassReward or 0
end

function XMultiDimConfig.GetDifficultyInfoByThemeId(themeId)
    local config = DifficultyGroups[themeId]
    if not config then
        XLog.ErrorTableDataNotFound("GetDifficultyInfoByThemeId", "tab", SHARE_MULTI_DIM_DIFFICULTY, "themeId", tostring(themeId))
        return
    end
    return config
end

function XMultiDimConfig.GetDifficultyRecommendClass(themeId, difficultyId)
    local config = GetMultiDimDifficulty(themeId, difficultyId)
    return config.RecommendClass or {}
end

function XMultiDimConfig.GetDifficultyDetailInfo(themeId, difficultyId)
    return GetDifficultyGroupsDetail(themeId, difficultyId)
end

function XMultiDimConfig.GetDifficultyDetailName(themeId, difficultyId)
    local config = GetDifficultyGroupsDetail(themeId, difficultyId)
    return config.Name or ""
end

function XMultiDimConfig.GetDifficultIsOnRank(themeId, difficultyId)
    local config = GetMultiDimDifficulty(themeId, difficultyId)
    return config.IsOnRank or 0
end

--endregion

--region 排行榜相关
--[[
单人排行榜人数          Name SingleRankNum
单人排行榜奖励保底人数    Name SingleRankFloor
多人排行榜人数          Name MultiRankNum
多人排行榜缓存人数       Name MultiRankMax
多人副本凌晨1点到9点关闭  Name MultiFubenCloseStartHour  MultiFubenCloseEndHour
重置天赋CD,单位秒       Name TalentResetCD
]]
function XMultiDimConfig.GetMultiDimConfigValue(name)
    return XMultiDimConfig.GetMultiDimConfig(name).Value
end
--endregion

--region 职业相关

function XMultiDimConfig.GetMultiDimCareerIconTranspose(career)
    local config = GetMultiDimCareer(career)
    return config.IconTranspose or ""
end

function XMultiDimConfig.GetMultiDimCareerName(career)
    local config = GetMultiDimCareer(career)
    return config.Name or ""
end

function XMultiDimConfig.GetMultiDimCareerFilterCareer(career)
    local config = GetMultiDimCareer(career)
    return config.FilterCareer or {}
end

function XMultiDimConfig.GetMultiDimCareerIcon(career)
    local config = GetMultiDimCareer(career)
    return config.Icon or ""
end

function XMultiDimConfig.GetMultiDimCareerDes(career)
    local config = GetMultiDimCareer(career)
    return config.Des or ""
end

function XMultiDimConfig.GetMultiDimCareerInfo()
    return MultiDimCareer
end

function XMultiDimConfig.GetMultiDimRecommendCareerList(stageId)
    for _,cfg in pairs(MultiDimDifficulty) do
        if cfg.StageId == stageId then
            return cfg.RecommendClass or {}
        end
    end
    return {}
end

--endregion

--region 天赋相关

function XMultiDimConfig.GetMultiDimTalentClassId(id)
    local config = GetMultiDimTalent(id)
    return config.ClassId or 0
end

function XMultiDimConfig.GetMultiDimTalentType(id)
    local config = GetMultiDimTalent(id)
    return config.TalentType or 0
end

function XMultiDimConfig.GetMultiDimTalentLevel(id)
    local config = GetMultiDimTalent(id)
    return config.Level or 0
end

function XMultiDimConfig.GetMultiDimTalentName(classId, talentType, level)
    local config = GetTalentLevelGroups(classId, talentType, level)
    return config.Name or ""
end

function XMultiDimConfig.GetMultiDimTalentCostItemId(classId, talentType, level)
    local config = GetTalentLevelGroups(classId, talentType, level)
    return config.CostItemId or ""
end

function XMultiDimConfig.GetMultiDimTalentCostItemCount(classId, talentType, level)
    local config = GetTalentLevelGroups(classId, talentType, level)
    return config.CostItemCount or 0
end

function XMultiDimConfig.GetMultiDimTalentIcon(classId, talentType, level)
    local config = GetTalentLevelGroupsDetail(classId, talentType, level)
    return config.Icon or ""
end

function XMultiDimConfig.GetMultiDimTalentDescription(classId, talentType, level)
    local config = GetTalentLevelGroups(classId, talentType, level)
    return config.Desc or ""
end

function XMultiDimConfig.GetMultiDimTalentIsHighLevel(classId, talentType, level)
    local config = GetTalentLevelGroupsDetail(classId, talentType, level)
    return config.IsHighLevel or 0
end

function XMultiDimConfig.GetMultiDimTalentNextLevel(classId, talentType, level)
    local config = GetTalentLevelGroupsDetail(classId, talentType, level)
    return config.NextLevel or 0
end

function XMultiDimConfig.GetMultiDimTalentId(classId, talentType, level)
    local config = GetTalentLevelGroups(classId, talentType, level)
    return config.Id or 0
end

--endregion

--region 排行奖品相关

function XMultiDimConfig.GetRankRewardInfo(themeId)
    return GetRankRewardGroups(themeId)
end

--endregion