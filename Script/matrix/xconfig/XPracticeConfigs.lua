XPracticeConfigs = XPracticeConfigs or {}

local CLIENT_PRACTICE_CHAPTERDETAIL = "Client/Fuben/Practice/PracticeChapterDetail.tab"
local CLIENT_PRACTICE_SKILLDETAIL = "Client/Fuben/Practice/PracticeSkillDetails.tab"
local SHARE_PRACTICE_CHAPTER_LOCAL = "Client/Fuben/Practice/PracticeChapterLocal.tab"
local CLIENT_PRACTICE_GROUP_DETAIL = "Client/Fuben/Practice/PracticeGroupDetail.tab"

local SHARE_PRACTICE_CHAPTER = "Share/Fuben/Practice/PracticeChapter.tab"
local SHARE_PRACTICE_ACTIVITY = "Share/Fuben/Practice/PracticeActivity.tab"
local SHARE_PRACTICE_GROUP = "Share/Fuben/Practice/PracticeGroup.tab"
--拟真boss
local SHARE_SIMULATE_TRAIN_ATK = "Share/Fuben/SimulateTrain/SimulateTrainAtk.tab"
local SHARE_SIMULATE_TRAIN_HP = "Share/Fuben/SimulateTrain/SimulateTrainHp.tab"
local SHARE_SIMULATE_TRAIN_MONSTER = "Share/Fuben/SimulateTrain/SimulateTrainMonster.tab"
local CLIENT_SIMULATE_TRAIN_GROUP = "Client/Fuben/SimulateTrain/SimulateTrainGroup.tab"

local PracticeChapterDetails = {}
local PracticeSkillDetails = {}
local PracticeActivityInfo = {}

local SimulateTrainAtk = {}
local SimulateTrainHp = {}
local SimulateTrainMonster = {}
local SimulateTrainGroup = {}

local PracticeChapters = {}
local SimulateTrainStageIdToMonsterIdDic = {}

local PracticeCharacterId2GroupId = {}
local PracticeChapterId2GroupId = {}

local PracticeGroup = {}
local PracticeGroupDetail = {}

XPracticeConfigs.PracticeType = {
    Basics = 1,
    Advanced = 2,
    Character = 3,
    Boss = 4,
}

--角色类型对应按钮页签
XPracticeConfigs.CharacterTabIndex = {
    SLevelNormal    = 4, --S级泛用机体
    ALevelNormal    = 5, --A级泛用机体
    Isomer          = 6, --独域机体（SP角色）
    Ganged          = 7, --联动机体
}

XPracticeConfigs.PanelType = {
    PanelBoss = 6,
    PanelElite = 7,
}

local InitSimulateTrainStageIdToMonsterIdDic = function()
    for id, v in pairs(SimulateTrainMonster) do
        SimulateTrainStageIdToMonsterIdDic[v.StageId] = id
    end
end

local InitPracticeTeachDict = function()
    for groupId, value in pairs(PracticeGroupDetail) do
        if XTool.IsNumberValid(value.CharacterId) then
            PracticeCharacterId2GroupId[value.CharacterId] = groupId
        end
    end

    for id, value in pairs(PracticeChapters) do
        for _, groupId in ipairs(value.Groups or {}) do
            PracticeChapterId2GroupId[groupId] = id
        end
    end
end

function XPracticeConfigs.Init()
    PracticeChapterDetails = XTableManager.ReadByIntKey(CLIENT_PRACTICE_CHAPTERDETAIL, XTable.XTablePracticeChapterDetail, "Id")
    PracticeSkillDetails = XTableManager.ReadByIntKey(CLIENT_PRACTICE_SKILLDETAIL, XTable.XTablePracticeSkillDetails, "StageId")
    local practiceChaptersServer = XTableManager.ReadByIntKey(SHARE_PRACTICE_CHAPTER, XTable.XTablePracticeChapter, "Id")

    local practiceChaptersLocal = XTableManager.ReadByIntKey(SHARE_PRACTICE_CHAPTER_LOCAL, XTable.XTablePracticeChapterLocal, "Id")
    PracticeChapters = XTool.MergeArray(practiceChaptersServer,practiceChaptersLocal)
    PracticeActivityInfo = XTableManager.ReadByIntKey(SHARE_PRACTICE_ACTIVITY, XTable.XTablePracticeActivity, "StageId")
    --拟真boss
    SimulateTrainAtk = XTableManager.ReadByIntKey(SHARE_SIMULATE_TRAIN_ATK, XTable.XTableSimulateTrainAtk, "AtkLevel")
    SimulateTrainHp = XTableManager.ReadByIntKey(SHARE_SIMULATE_TRAIN_HP, XTable.XTableSimulateTrainHp, "HpLevel")
    SimulateTrainMonster = XTableManager.ReadByIntKey(SHARE_SIMULATE_TRAIN_MONSTER, XTable.XTableSimulateTrainMonster, "Id")
    SimulateTrainGroup = XTableManager.ReadByIntKey(CLIENT_SIMULATE_TRAIN_GROUP, XTable.XTableSimulateTrainGroup, "GroupId")

    PracticeGroup = XTableManager.ReadByIntKey(SHARE_PRACTICE_GROUP, XTable.XTablePracticeGroup, "GroupId")
    PracticeGroupDetail = XTableManager.ReadByIntKey(CLIENT_PRACTICE_GROUP_DETAIL, XTable.XTablePracticeGroupDetail, "GroupId")

    InitSimulateTrainStageIdToMonsterIdDic()
    InitPracticeTeachDict()
end

function XPracticeConfigs.GetPracticeChapters()
    return PracticeChapters
end

function XPracticeConfigs.GetPracticeChapterById(id)
    local currentChapter = PracticeChapters[id]

    if not currentChapter then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeChapterById", "currentChapter", SHARE_PRACTICE_CHAPTER, "id", tostring(id))
        return
    end

    if not XTool.IsTableEmpty(currentChapter.Groups) then
        local res = XTool.Clone(currentChapter)
        res.Groups = {}
        for k, charId in pairs(currentChapter.Groups) do
            if XMVCA.XFavorability:GetModelGetCharacterCollaboration(charId) and not XMVCA.XCharacter:IsOwnCharacter(charId) then
    
            else
                table.insert(res.Groups, charId)
            end
        end
        return res
    end

    return currentChapter
end


function XPracticeConfigs.GetPracticeChapterConditionById(id)
    local currentChapter = XPracticeConfigs.GetPracticeChapterById(id)
    return currentChapter.ConditionId
end

function XPracticeConfigs.GetPracticeChapterStageIdById(id)
    local currentChapter = XPracticeConfigs.GetPracticeChapterById(id)
    return currentChapter.StageId or {}
end

function XPracticeConfigs.GetPracticeChapterIdByStageId(stageId)
    for id, v in ipairs(PracticeChapters) do
        if not XTool.IsTableEmpty(v.StageId) then
            for _, sId in ipairs(v.StageId) do
                if sId == stageId then
                    return id
                end
            end
        end
        for _, groupId in ipairs(v.Groups or {}) do
            local stageIds = XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
            for _, sId in ipairs(stageIds or {}) do
                if sId == stageId then
                    return id
                end
            end
        end
    end
    return 0
end

function XPracticeConfigs.GetPracticeChapterDetails()
    return PracticeChapterDetails
end

function XPracticeConfigs.GetPracticeChapterDetailById(id)
    local currentChapterDetail = PracticeChapterDetails[id]

    if not currentChapterDetail then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeChapterDetailById", "currentChapterDetail", CLIENT_PRACTICE_CHAPTERDETAIL, "id", tostring(id))
        return
    end

    return currentChapterDetail
end

function XPracticeConfigs.GetPracticeDescriptionById(id)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(id)
    if not details then return "" end
    return details.Description or ""
end

function XPracticeConfigs.GetPracticeChapterTypeById(id)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(id)
    if not details then return end
    return details.Type
end

function XPracticeConfigs.GetPracticeSubTagById(id)
    local details = XPracticeConfigs.GetPracticeChapterDetailById(id)
    if not details then return 0 end
    return details.SubTag or 0
end

function XPracticeConfigs.GetPracticeActivityInfo(stageId)
    return PracticeActivityInfo[stageId]
end

function XPracticeConfigs.GetPracticeSkillDetailById(id)
    local currentDetail = PracticeSkillDetails[id]
    if not currentDetail then
        XLog.ErrorTableDataNotFound("XPracticeConfigs.GetPracticeSkillDetailById", "currentDetail", CLIENT_PRACTICE_SKILLDETAIL, "id", tostring(id))
        return
    end
    return currentDetail
end

function XPracticeConfigs.GetPracticeChapterIdListByType(type)
    local config = XPracticeConfigs.GetPracticeChapterDetails()
    local chapterIdList = {}
    for _, v in pairs(config) do
        if v.Type == type then
            table.insert(chapterIdList, v.Id)
        end
    end
    return chapterIdList
end

---------------拟真boss begin------------------------
local GetSimulateTrainAtkById = function(id)
    if not SimulateTrainAtk[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", SHARE_SIMULATE_TRAIN_ATK)
        return {}
    end
    return SimulateTrainAtk[id]
end

local GetSimulateTrainHpById = function(id)
    if not SimulateTrainHp[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", SHARE_SIMULATE_TRAIN_HP)
        return {}
    end
    return SimulateTrainHp[id]
end

local GetSimulateTrainMonsterById = function(id)
    if not SimulateTrainMonster[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", SHARE_SIMULATE_TRAIN_MONSTER)
        return {}
    end
    return SimulateTrainMonster[id]
end

local GetSimulateTrainGroupById = function(id)
    if not SimulateTrainGroup[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", CLIENT_SIMULATE_TRAIN_GROUP)
        return {}
    end
    return SimulateTrainGroup[id]
end
--Atk
function XPracticeConfigs.GetSimulateTrainAtkAtkBuffId(id)
    local cfg = GetSimulateTrainAtkById(id)
    return cfg.AtkBuffId or 0
end

function XPracticeConfigs.GetSimulateTrainAtkAtkAttributeCe(id)
    local cfg = GetSimulateTrainAtkById(id)
    return cfg.AtkAttributeCe or 0
end

function XPracticeConfigs.GetSimulateTrainAtkAtkAddPercent(id)
    local cfg = GetSimulateTrainAtkById(id)
    return cfg.AtkAddPercent or 0
end

function XPracticeConfigs.GetSimulateTrainAtkLength()
    local cfg = SimulateTrainAtk
    return #cfg or 0
end
--atk end

--hp
function XPracticeConfigs.GetSimulateTrainHpHpBuffId(id)
    local cfg = GetSimulateTrainHpById(id)
    return cfg.HpBuffId or 0
end

function XPracticeConfigs.GetSimulateTrainHpHpAttributeCe(id)
    local cfg = GetSimulateTrainHpById(id)
    return cfg.HpAttributeCe or 0
end

function XPracticeConfigs.GetSimulateTrainHpHpAddPercent(id)
    local cfg = GetSimulateTrainHpById(id)
    return cfg.HpAddPercent or 0
end

function XPracticeConfigs.GetSimulateTrainHpLength()
    local cfg = SimulateTrainHp
    return #cfg or 0
end
--hp end


--Monster start
function XPracticeConfigs.CheckSimulateTrainMonsterExist(id)
    if not SimulateTrainMonster[id] then
        return false
    end
    return true
end

-- BOSS开启时间
function XPracticeConfigs.GetSimulateTrainMonsterTimeId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.TimeId
end

-- 难度4(绝境难度)的开启时间
function XPracticeConfigs.GetSimulateTrainMonsterImpasseTimeId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.ImpasseTimeId
end

function XPracticeConfigs.GetSimulateTrainMonsterType(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.Type or 0
end

function XPracticeConfigs.GetSimulateTrainMonsterStageId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.StageId or 0
end

function XPracticeConfigs.GetSimulateTrainMonsterNpcId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg and cfg.NpcId or {}
end

function XPracticeConfigs.GetSimulateTrainMonsterStageName(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.StageName or {}
end

function XPracticeConfigs.GetSimulateTrainMonsterMaxPeriod(id)
    local cfg = GetSimulateTrainMonsterById(id)
    local maxPeriod = 1
    for i, v in pairs(cfg.PeriodBuffId) do
        if i > maxPeriod then
            maxPeriod = i
        end
    end
    return maxPeriod
end

function XPracticeConfigs.GetSimulateTrainMonsterFirstRewardId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.FirstRewardId or 0
end

function XPracticeConfigs.GetSimulateTrainMonsterDefaultAtkLevel(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.DefaultAtkLevel or 0
end

function XPracticeConfigs.GetSimulateTrainMonsterDefaultHpLevel(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.DefaultHpLevel or 1
end

function XPracticeConfigs.GetSimulateTrainMonsterSortId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.SortId or 1
end

function XPracticeConfigs.GetSimulateTrainMonsterGroupId(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.GroupId or 1
end

function XPracticeConfigs.GetSimulateTrainMonsterStageRatioCe(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.StageRatioCe or {}
end

function XPracticeConfigs.GetSimulateTrainMonsterStageBasicCe(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.StageBasicCe or {}
end

function XPracticeConfigs.GetSimulateTrainMonsterSkillIds(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return cfg.SkillIds or {}
end

function XPracticeConfigs.GetSimulateTrainMonsterMaxStageLevel(id)
    local cfg = GetSimulateTrainMonsterById(id)
    return #cfg.NpcId or 0
end

function XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(stageId)
    local id = XPracticeConfigs.GetSimulateTrainMonsterId(stageId)
    return id or 0
end

function XPracticeConfigs.GetSimulateTrainNpcIdIdByStageId(stageId)
    local id = XPracticeConfigs.GetSimulateTrainMonsterId(stageId)
    if not id then
        return
    end

    local npcIdList = XPracticeConfigs.GetSimulateTrainMonsterNpcId(id)
    return npcIdList
end

function XPracticeConfigs.GetSimulateTrainMonsterStageNameByStageId(stageId, index)
    local id = XPracticeConfigs.GetSimulateTrainMonsterId(stageId)
    if not id then
        return
    end

    local stageNameList = XPracticeConfigs.GetSimulateTrainMonsterStageName(id)
    return stageNameList[index] or ""
end

function XPracticeConfigs.GetSimulateTrainMonsterId(stageId)
    return SimulateTrainStageIdToMonsterIdDic[stageId]
end
--monster end

--region 赛利卡教学相关

-- characterId -> groupId
function XPracticeConfigs.GetGroupIdByCharacterId(characterId)
    return PracticeCharacterId2GroupId[characterId]
end

-- groupId -> chapterId
function XPracticeConfigs.GetChapterIdByGroupId(groupId)
    return PracticeChapterId2GroupId[groupId]
end

-- generalSkillId -> groupId
function XPracticeConfigs.GetGroupIdByGeneralSkillId(generalSkillId)
    for i, v in pairs(PracticeGroupDetail) do
        if v.GeneralSkillId == generalSkillId then
            return v.GroupId
        end
    end    
end

-- groupId -> generalSkillId
function XPracticeConfigs.GetGeneralSkillIdByGroupId(groupId)
    ---@type XTablePracticeGroupDetail
    local cfg = PracticeGroupDetail[groupId]
    if cfg then
        return cfg.GeneralSkillId
    end
    return 0
end
--endregion

--group start
function XPracticeConfigs.GetSimulateTrainGroupGroupName(id)
    local cfg = GetSimulateTrainGroupById(id)
    return cfg.GroupName or 0
end

function XPracticeConfigs.GetSimulateTrainGroupIds(chapterId)
    local ids = {}
    local insertIdDic = {}
    local stageIdList = XPracticeConfigs.GetPracticeChapterStageIdById(chapterId)
    local simulateTrainMonsterId
    local groupId
    for _, stageId in ipairs(stageIdList) do
        simulateTrainMonsterId = XPracticeConfigs.GetSimulateTrainMonsterId(stageId)
        groupId = XPracticeConfigs.GetSimulateTrainMonsterGroupId(simulateTrainMonsterId)
        if GetSimulateTrainGroupById(groupId) and not insertIdDic[groupId] then
            table.insert(ids, groupId)
            insertIdDic[groupId] = true
        end
    end
    return ids
end
--group end
---------------拟真boss end------------------------

--region PracticeGroup.tab

local function GetPracticeGroup(groupId)
    local config = PracticeGroup[groupId]
    if not config then
        XLog.Error("XPracticeConfigs GetPracticeGroup error:配置不存在, groupId:" .. groupId .. ",path: " .. SHARE_PRACTICE_GROUP)
        return
    end

    return config
end

function XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
    local config = GetPracticeGroup(groupId)
    if config then
        return config.StageIds
    end
    return nil
end

function XPracticeConfigs.GetPracticeSkipIdByGroupId(groupId)
    local config = GetPracticeGroup(groupId)
    if config then
        return config.SkipId
    end
    return nil
end

--endregion

--region  PracticeGroupDetail.tab

local function GetPracticeGroupDetail(groupId) 
    local config = PracticeGroupDetail[groupId]
    if not config then
        XLog.Error("XPracticeConfigs GetPracticeGroupDetail error:配置不存在, groupId:" .. groupId .. ",path: " .. CLIENT_PRACTICE_GROUP_DETAIL)
        return
    end

    return config
end

function XPracticeConfigs.GetPracticeGroupName(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.Name
    end
    return ""
end

function XPracticeConfigs.GetPracticeGroupIcon(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.Icon
    end
    return ""
end

function XPracticeConfigs.GetPracticeGroupBackGroundImage(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.BackGroundImage
    end
    return ""
end

function XPracticeConfigs.GetPracticeGroupCharacterId(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.CharacterId
    end
    return 0
end

function XPracticeConfigs.GetPracticeGroupPrefabName(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.PrefabName
    end
    return ""
end

function XPracticeConfigs.GetPracticeGroupActivityTimeId(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.ActivityTimeId
    end
    return 0
end

function XPracticeConfigs.GetPracticeGroupActivityCondition(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.ActivityCondition
    end
    return nil
end

function XPracticeConfigs.GetPracticeGroupOpenCondition(groupId)
    local config = GetPracticeGroupDetail(groupId)
    if config then
        return config.OpenCondition
    end
    return nil
end

--endregion