XMaverick2Configs = XMaverick2Configs or {}

local TABLE_CLIENT = "Client/Fuben/Maverick2/"
local TABLE_SHARE = "Share/Fuben/Maverick2/"

XMaverick2Configs.StageType = 
{
    MainLine = 1, -- 主线
    MainLineBoss = 2, -- 主线Boss
    Character = 3, -- 角色
    Challenge = 4, -- 挑战
    Daily = 5, -- 每日关卡
    Score = 6, -- 积分关卡
}

-- 聚焦章节关卡的优先级
XMaverick2Configs.FocusStageOrder = {
    2, -- MainLine
    1, -- MainLineBoss
    4, -- Character
    5, -- Challenge
    6, -- Daily
    3, -- Score
}

-- 属性效果类型
XMaverick2Configs.AttributeEffectType =
{
    Value = 1, -- 加成值
    Percent = 2, -- 加成百分比
}

-- 镜头
XMaverick2Configs.CAMERA_CNT = 3
XMaverick2Configs.CharacterCamera = 
{
    Lv = 1, -- 天赋界面
    Prepare = 2, -- 角色和技能界面
    EXCHANGE = 3, -- 更换角色
}

-- 自定义字典
local ChapterStagesDic = {} -- 章节id:所有关卡配置表
local TalentGroupConfigsDic = {} -- 天赋组id:所有天赋id配置表
local TalentLvConfigsDic = {} -- 天赋id:所有等级配置表
local TalentInfoDic = {} -- 天赋信息
local AssistTalentList = {} -- 支援技列表

function XMaverick2Configs.Init()
    XConfigCenter.CreateGetProperties(XMaverick2Configs, {
        "Maverick2Attribute",
        "Maverick2Config",
        "Maverick2Movie",
        "Maverick2StageType",
        "Maverick2Attribute",
        "Maverick2SkillDesc",
        "Maverick2Activity",
        "Maverick2Chapter",
        "Maverick2Mental",
        "Maverick2Robot",
        "Maverick2Stage",
        "Maverick2Talent",
        "Maverick2TalentGroup",
        "Maverick2TalentTree",
    }, {
        "ReadByIntKey", TABLE_CLIENT .. "Maverick2Attribute.tab", XTable.XTableMaverick2Attribute, "Id",
        "ReadByStringKey", TABLE_CLIENT .. "Maverick2Config.tab", XTable.XTableMaverick2Config, "Key",
        "ReadByIntKey", TABLE_CLIENT .. "Maverick2Movie.tab", XTable.XTableMaverick2Movie, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "Maverick2StageType.tab", XTable.XTableMaverick2StageType, "TypeId",
        "ReadByIntKey", TABLE_CLIENT .. "Maverick2Attribute.tab", XTable.XTableMaverick2Attribute, "Id",
        "ReadByIntKey", TABLE_CLIENT .. "Maverick2SkillDesc.tab", XTable.XTableMaverick2SkillDesc, "Id",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Activity.tab", XTable.XTableMaverick2Activity, "Id",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Chapter.tab", XTable.XTableMaverick2Chapter, "ChapterId",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Mental.tab", XTable.XTableMaverick2Mental, "Level",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Robot.tab", XTable.XTableMaverick2Robot, "RobotId",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Stage.tab", XTable.XTableMaverick2Stage, "StageId",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2Talent.tab", XTable.XTableMaverick2Talent, "Id",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2TalentGroup.tab", XTable.XTableMaverick2TalentGroup, "Id",
        "ReadByIntKey", TABLE_SHARE .. "Maverick2TalentTree.tab", XTable.XTableMaverick2TalentTree, "Id",
    })

    XMaverick2Configs.CreateChpaterStageDic()
    XMaverick2Configs.CreateTalentGroupIdDic()
    XMaverick2Configs.CreateTalentIdDic()
end



-- Maverick2Config.tab 系统配置
--==================================================================================
function XMaverick2Configs.GetShopIds()
    local config = XMaverick2Configs.GetMaverick2Config("ShopIds", true)
    local shopIds = {}
    for _, shopId in ipairs(config.Params) do
        table.insert(shopIds, tonumber(shopId))
    end
    return shopIds
end

-- 任务组id列表
function XMaverick2Configs.GetTaskGroupIds()
    local config = XMaverick2Configs.GetMaverick2Config("TaskGroupIds", true)
    local taskGroupIds = {}
    for _, groupId in ipairs(config.Params) do
        table.insert(taskGroupIds, tonumber(groupId))
    end
    return taskGroupIds
end

-- 引导key
function XMaverick2Configs.GetHelpKey()
    local config = XMaverick2Configs.GetMaverick2Config("HelpKey", true)
    return config.Params[1]
end

--==================================================================================


-- Maverick2Stage.tab 关卡
--==================================================================================
function XMaverick2Configs.CreateChpaterStageDic()
    ChapterStagesDic = {}
    local configs = XMaverick2Configs.GetMaverick2Stage()
    for i, config in pairs(configs) do
        if ChapterStagesDic[config.ChapterId] == nil then
            ChapterStagesDic[config.ChapterId] = {}
        end
        table.insert(ChapterStagesDic[config.ChapterId], config)
    end

    for _, chapterStages in pairs(ChapterStagesDic) do
        table.sort(chapterStages, function(a, b) 
            return a.StageId < b.StageId
        end)
    end
end

-- 获取章节的所有关卡
function XMaverick2Configs.GetChapterStages(chapterId)
    return ChapterStagesDic[chapterId]
end
--==================================================================================



-- Talent 心智天赋
--==================================================================================
function XMaverick2Configs.CreateTalentGroupIdDic()
    TalentGroupConfigsDic = {}
    local configs = XMaverick2Configs.GetMaverick2TalentGroup()
    for i, config in ipairs(configs) do
        local groupId = config.TalentGroupId

        -- 天赋组
        if not TalentGroupConfigsDic[groupId] then
            TalentGroupConfigsDic[groupId] = {}
        end
        table.insert(TalentGroupConfigsDic[groupId], config)

        -- 天赋信息
        TalentInfoDic[config.TalentId] = {
            Name = config.Name,
            AssistFlag = config.AssistFlag,
            SummaryTab = config.SummaryTab,
        }

        -- 支援技能
        if config.AssistFlag == 1 then
            table.insert(AssistTalentList, config)
        end
    end
end

-- 获取天赋组的所有天赋配置
function XMaverick2Configs.GetTalentGroupConfigs(groupId)
    return TalentGroupConfigsDic[groupId]
end

function XMaverick2Configs.CreateTalentIdDic()
    TalentLvConfigsDic = {}
    local configs = XMaverick2Configs.GetMaverick2Talent()
    for i, config in ipairs(configs) do
        local talentId = config.TalentId
        if not TalentLvConfigsDic[talentId] then
            TalentLvConfigsDic[talentId] = {}
        end
        table.insert(TalentLvConfigsDic[talentId], config)
    end
end

-- 获取天赋的所有等级配置
function XMaverick2Configs.GetTalentLvConfigs(talentId)
    return TalentLvConfigsDic[talentId]
end

-- 获取天赋信息
function XMaverick2Configs.GetTalentInfo(talentId)
    return TalentInfoDic[talentId]
end

-- 获取天赋的所有等级配置
function XMaverick2Configs.GetTalentLvConfig(talentId, lv)
    local lvCfgs = TalentLvConfigsDic[talentId]
    return lvCfgs and lvCfgs[lv] or nil
end

-- 获取天赋升级到该等级消耗的心智单元数量
function XMaverick2Configs.GetTalentLvCostUnit(talentId, lv)
    local costCnt = 0
    local lvCfgs = XMaverick2Configs.GetTalentLvConfigs(talentId)
    for i, lvCfg in ipairs(lvCfgs) do
        if lv >= i then
            costCnt = costCnt + lvCfg.NeedUnit
        end
    end
    
    return costCnt
end

-- 获取机器人的天赋树列表
function XMaverick2Configs.GetRobotTalentCfg(robotId)
    local treeCfgs = {}
    local configs = XMaverick2Configs.GetMaverick2TalentTree()
    for _, config in pairs(configs) do
        if config.RobotId == robotId then
            table.insert(treeCfgs, config)
        end
    end
    table.sort(treeCfgs, function(a, b) 
        return a.Order <= b.Order
    end)

    return treeCfgs
end

-- 通过机器人id和天赋组id获取天赋树的配置
function XMaverick2Configs.GetTalentTreeConfig(robotId, groupId)
    local configs = XMaverick2Configs.GetMaverick2TalentTree()
    for _, config in ipairs(configs) do
        if config.RobotId == robotId and config.TalentGroupId == groupId then 
            return config
        end
    end

    return nil
end

-- 获取天赋的解锁配置
function XMaverick2Configs.GetTalentUnlockCfg(talentId)
    local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(talentId)
    return lvConfigs[1]
end
--==================================================================================



-- Maverick2Movie.tab 剧情配置 
--==================================================================================
function XMaverick2Configs.GetChapterOpenMovieId(chapterId)
    local configs = XMaverick2Configs.GetMaverick2Movie()
    for _, config in ipairs(configs) do
        if config.ChapterId == chapterId then
            return config.OpenMovieId
        end
    end
    return nil
end


-- Robot 机器人
--==================================================================================
-- 获取机器人的所有角色技能
function XMaverick2Configs.GetRobotSkillConfigs(robotId)
    local robotCfg = XMaverick2Configs.GetMaverick2Robot(robotId, true)
    local skillCfgs = {}
    for _, skillId in ipairs(robotCfg.SkillIds) do
        local skillCfg = XMaverick2Configs.GetMaverick2SkillDesc(skillId, true)
        table.insert(skillCfgs, skillCfg)
    end

    return skillCfgs
end

-- 获取机器人的所有支援技能
function XMaverick2Configs.GetRobotAssistSkillConfigs()
    return AssistTalentList
end