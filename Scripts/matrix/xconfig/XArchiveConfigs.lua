--
-- Author: zhangshuang、wujie
-- Note: 图鉴配置相关
XArchiveConfigs = XArchiveConfigs or {}


XArchiveConfigs.SubSystemType = {
    Monster = 1,
    Weapon = 2,
    Awareness = 3,
    Story = 4,
    CG = 5,
    NPC = 6,
    Email = 7,
    Partner = 8,
    PV = 9,
}

XArchiveConfigs.SettingType = {
    All = 0,
    Setting = 1,
    Story = 2,
}

-- 设定位置
XArchiveConfigs.SettingIndex = {
    First = 1,
}

XArchiveConfigs.WeaponCamera = {
    Main = 1, --  武器详情默认是主镜头
    Setting = 2,
}

XArchiveConfigs.MonsterType = {
    Pawn = 1,
    Elite = 2,
    Boss = 3,
}

XArchiveConfigs.MonsterInfoType = {
    Short = 1,
    Long = 2,
}

XArchiveConfigs.MonsterSettingType = {
    Setting = 1,
    Story = 2,
}

XArchiveConfigs.MonsterDetailType = {
    Synopsis = 1,
    Info = 2,
    Setting = 3,
    Skill = 4,
    Zoom = 5,
    ScreenShot = 6,
}

XArchiveConfigs.EquipStarType = {
    All = 0,
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
}

XArchiveConfigs.EquipLikeType = {
    NULL = 0,
    Dis = 1,
    Like = 2,
}

XArchiveConfigs.StarToQualityName = {
    [XArchiveConfigs.EquipStarType.All] = CS.XTextManager.GetText("ArchiveAwarenessFliterAll"),
    [XArchiveConfigs.EquipStarType.Two] = CS.XTextManager.GetText("ArchiveAwarenessFliterTwoStar"),
    [XArchiveConfigs.EquipStarType.Three] = CS.XTextManager.GetText("ArchiveAwarenessFliterThreeStar"),
    [XArchiveConfigs.EquipStarType.Four] = CS.XTextManager.GetText("ArchiveAwarenessFliterFourStar"),
    [XArchiveConfigs.EquipStarType.Five] = CS.XTextManager.GetText("ArchiveAwarenessFliterFiveStar"),
    [XArchiveConfigs.EquipStarType.Six] = CS.XTextManager.GetText("ArchiveAwarenessFliterSixStar"),
}

XArchiveConfigs.EvaluateOnForAll = CS.XGame.ClientConfig:GetInt("ArchiveEvaluateOnForAll")

XArchiveConfigs.OnForAllState = {
    Off = 0,
    On = 1,
}

XArchiveConfigs.NpcGridState = {
    Open = 0,
    Close = 1,
}

XArchiveConfigs.EmailType = {
    Email = 1,
    Communication = 2,
}

XArchiveConfigs.PartnerSettingType = {
    Setting = 1,
    Story = 2,
}

XArchiveConfigs.MonsterDetailUiType = {
    Default = 1, -- 默认图鉴打开
    Show = 2, -- 只负责显示，屏蔽玩家操作
}

XArchiveConfigs.SpecialData = { --特判数据（仅武器天狼星使用）
    PayRewardId = 5,
    Equip = {--天狼星
        ResonanceCount = 0,
        Level = 1,
        Breakthrough = 0,
        Id = 2026003,
        },
}

local TABLE_TAG = "Share/Archive/Tag.tab"
local TABLE_ARCHIVE = "Share/Archive/Archive.tab"
local TABLE_MONSTER = "Share/Archive/Monster.tab"
local TABLE_MONSTERINFO = "Share/Archive/MonsterInfo.tab"
local TABLE_MONSTERSKILL = "Share/Archive/MonsterSkill.tab"
local TABLE_MONSTERSETTING = "Share/Archive/MonsterSetting.tab"
local TABLE_SAMENPCGROUP = "Share/Archive/SameNpcGroup.tab"
local TABLE_MONSTERNPCDATA = "Client/Archive/MonsterNpcData.tab"
local TABLE_AWARENESSSETTING = "Share/Archive/AwarenessSetting.tab"
local TABLE_WEAPONSETTING = "Share/Archive/WeaponSetting.tab"
local TABLE_MONSTERMODEL_TRANS = "Client/Archive/MonsterModelTrans.tab"
local TABLE_MONSTER_EFFECT = "Client/Archive/MonsterEffect.tab"

local TABLE_STORYGROUP = "Share/Archive/StoryGroup.tab"
local TABLE_STORYCHAPTER = "Share/Archive/StoryChapter.tab"
local TABLE_STORYDETAIL = "Share/Archive/StoryDetail.tab"

local TABLE_STORYNPC = "Share/Archive/StoryNpc.tab"
local TABLE_STORYNPCSETTING = "Share/Archive/StoryNpcSetting.tab"

local TABLE_CGDETAIL = "Share/Archive/CGDetail.tab"
local TABLE_CGGROUP = "Share/Archive/CGGroup.tab"

local TABLE_ARCHIVEMAIL = "Share/Archive/ArchiveMail.tab"
local TABLE_COMMUNICATION = "Share/Archive/Communication.tab"
local TABLE_EVENTDATEGROUP = "Share/Archive/EventDateGroup.tab"

local TABLE_ARCHIVE_WEAPON_GROUP_PATH = "Client/Archive/ArchiveWeaponGroup.tab"
local TABLE_ARCHIVE_AWARENESS_GROUP_PATH = "Client/Archive/ArchiveAwarenessGroup.tab"
local TABLE_ARCHIVE_AWARENESS_GROUPTYPE_PATH = "Client/Archive/ArchiveAwarenessGroupType.tab"

local TABLE_ARCHIVE_PARTNER_SETTING = "Share/Archive/PartnerSetting.tab"
local TABLE_ARCHIVE_PARTNER = "Client/Archive/ArchivePartner.tab"
local TABLE_ARCHIVE_PARTNER_GROUP = "Client/Archive/ArchivePartnerGroup.tab"

local TABLE_PVDETAIL = "Share/Archive/PVDetail.tab"
local TABLE_PVGROUP = "Client/Archive/PVGroup.tab"

local tableSort = table.sort

local Tags = {}
local Archives = {}
local Monsters = {}
local MonsterInfos = {}
local MonsterSkills = {}
local MonsterSettings = {}
local AwarenessSettings = {}
local WeaponSettings = {}
local SameNpcGroups = {}
local MonsterNpcDatas = {}
local MonsterModelTrans = {}
local MonsterEffects = {}

local StoryGroups = {}
local StoryChapters = {}
local StoryDetails = {}

local StoryNpc = {}
local StoryNpcSetting = {}

local CGGroups = {}
local CGDetails = {}

local ArchiveMails = {}
local ArchiveCommunications = {}
local EventDateGroups = {}

local WeaponGroup = {}
local WeaponTemplateIdToSettingListDic = {}
local ShowedWeaponTypeList = {}
local WeaponTypeToIdsDic = {}
local WeaponSumCollectNum = 0

local AwarenessGroup = {}
local AwarenessGroupType = {}
local AwarenessShowedStatusDic = {}
local AwarenessSumCollectNum = 0
local AwarenessTypeToGroupDatasDic = {}
local AwarenessSuitIdToSettingListDic = {}

local ArchiveTagAllList = {}
local ArchiveStoryGroupAllList = {}
local ArchiveSameNpc = {}
local ArchiveMonsterTransDic = {}
local ArchiveMonsterEffectDatasDic = {}

local ArchivePartnerSettings = {}
local ArchivePartners = {}
local ArchivePartnerGroups = {}

local PVGroups = {}
local PVDetails = {}

function XArchiveConfigs.Init()
    Tags = XTableManager.ReadByIntKey(TABLE_TAG, XTable.XTableArchiveTag, "Id")
    Archives = XTableManager.ReadByIntKey(TABLE_ARCHIVE, XTable.XTableArchive, "Id")
    Monsters = XTableManager.ReadAllByIntKey(TABLE_MONSTER, XTable.XTableArchiveMonster, "Id")
    MonsterInfos = XTableManager.ReadAllByIntKey(TABLE_MONSTERINFO, XTable.XTableArchiveMonsterInfo, "Id")
    MonsterSkills = XTableManager.ReadAllByIntKey(TABLE_MONSTERSKILL, XTable.XTableArchiveMonsterSkill, "Id")
    MonsterSettings = XTableManager.ReadAllByIntKey(TABLE_MONSTERSETTING, XTable.XTableMonsterSetting, "Id")
    SameNpcGroups = XTableManager.ReadByIntKey(TABLE_SAMENPCGROUP, XTable.XTableSameNpcGroup, "Id")

    MonsterNpcDatas = XTableManager.ReadByIntKey(TABLE_MONSTERNPCDATA, XTable.XTableMonsterNpcData, "Id")
    MonsterModelTrans = XTableManager.ReadByIntKey(TABLE_MONSTERMODEL_TRANS, XTable.XTableMonsterModelTrans, "Id")
    MonsterEffects = XTableManager.ReadByIntKey(TABLE_MONSTER_EFFECT, XTable.XTableMonsterEffect, "Id")

    StoryGroups = XTableManager.ReadByIntKey(TABLE_STORYGROUP, XTable.XTableArchiveStoryGroup, "Id")
    StoryChapters = XTableManager.ReadByIntKey(TABLE_STORYCHAPTER, XTable.XTableArchiveStoryChapter, "Id")
    StoryDetails = XTableManager.ReadByIntKey(TABLE_STORYDETAIL, XTable.XTableArchiveStoryDetail, "Id")

    StoryNpc = XTableManager.ReadByIntKey(TABLE_STORYNPC, XTable.XTableArchiveStoryNpc, "Id")
    StoryNpcSetting = XTableManager.ReadByIntKey(TABLE_STORYNPCSETTING, XTable.XTableArchiveStoryNpcSetting, "Id")

    CGGroups = XTableManager.ReadByIntKey(TABLE_CGGROUP, XTable.XTableArchiveCGGroup, "Id")
    CGDetails = XTableManager.ReadByIntKey(TABLE_CGDETAIL, XTable.XTableArchiveCGDetail, "Id")

    ArchiveMails = XTableManager.ReadByIntKey(TABLE_ARCHIVEMAIL, XTable.XTableArchiveMail, "Id")
    ArchiveCommunications = XTableManager.ReadByIntKey(TABLE_COMMUNICATION, XTable.XTableArchiveCommunication, "Id")
    EventDateGroups = XTableManager.ReadByIntKey(TABLE_EVENTDATEGROUP, XTable.XTableArchiveEventDateGroup, "Id")

    WeaponGroup = XTableManager.ReadByIntKey(TABLE_ARCHIVE_WEAPON_GROUP_PATH, XTable.XTableArchiveWeaponGroup, "Id")
    WeaponSettings = XTableManager.ReadByIntKey(TABLE_WEAPONSETTING, XTable.XTableWeaponSetting, "Id")

    AwarenessGroup = XTableManager.ReadByIntKey(TABLE_ARCHIVE_AWARENESS_GROUP_PATH, XTable.XTableArchiveAwarenessGroup, "Id")
    AwarenessGroupType = XTableManager.ReadByIntKey(TABLE_ARCHIVE_AWARENESS_GROUPTYPE_PATH, XTable.XTableArchiveAwarenessGroupType, "GroupId")
    AwarenessSettings = XTableManager.ReadByIntKey(TABLE_AWARENESSSETTING, XTable.XTableAwarenessSetting, "Id")

    ArchivePartnerSettings = XTableManager.ReadByIntKey(TABLE_ARCHIVE_PARTNER_SETTING, XTable.XTablePartnerSetting, "Id")
    ArchivePartners = XTableManager.ReadByIntKey(TABLE_ARCHIVE_PARTNER, XTable.XTableArchivePartner, "Id")
    ArchivePartnerGroups = XTableManager.ReadByIntKey(TABLE_ARCHIVE_PARTNER_GROUP, XTable.XTableArchivePartnerGroup, "Id")

    PVGroups = XTableManager.ReadByIntKey(TABLE_PVGROUP, XTable.XTableArchivePVGroup, "Id")
    PVDetails = XTableManager.ReadByIntKey(TABLE_PVDETAIL, XTable.XTableArchivePVDetail, "Id")

    XArchiveConfigs.SetArchiveTagAllList()
    XArchiveConfigs.SetArchiveSameNpc()
    XArchiveConfigs.SetArchiveMonsterModelTransDic()
    XArchiveConfigs.SetArchiveMonsterEffectsDic()

    XArchiveConfigs.CreateShowedWeaponTypeList()
    XArchiveConfigs.CreateWeaponTemplateIdToSettingDataListDic()
    XArchiveConfigs.SetWeaponSumCollectNum()
    XArchiveConfigs.CreateWeaponTypeToIdsDic()

    XArchiveConfigs.CreateAwarenessShowedStatusDic()
    XArchiveConfigs.SetAwarenessSumCollectNum()
    XArchiveConfigs.CreateAwarenessTypeToGroupDatasDic()
    XArchiveConfigs.CreateAwarenessSiteToBgPathDic()
    XArchiveConfigs.CreateAwarenessSuitIdToSettingDataListDic()

    XArchiveConfigs.SetArchiveStoryGroupAllList()
end

function XArchiveConfigs.GetArchiveConfigById(Id)
    return Archives[Id]
end

function XArchiveConfigs.GetArchiveConfigs()
    return Archives
end

function XArchiveConfigs.GetArchiveMonsterConfigs()
    return Monsters
end

function XArchiveConfigs.GetArchiveMonsterConfigById(id)
    return Monsters[id]
end

function XArchiveConfigs.GetArchiveMonsterInfoConfigs()
    return MonsterInfos
end

function XArchiveConfigs.GetArchiveMonsterInfoConfigById(id)
    return MonsterInfos[id]
end

function XArchiveConfigs.GetArchiveMonsterSkillConfigs()
    return MonsterSkills
end

function XArchiveConfigs.GetArchiveMonsterSkillConfigById(id)
    return MonsterSkills[id]
end

function XArchiveConfigs.GetArchiveMonsterSettingConfigs()
    return MonsterSettings
end

function XArchiveConfigs.GetArchiveMonsterSettingConfigById(id)
    return MonsterSettings[id]
end

function XArchiveConfigs.GetArchiveTagCfgById(id)
    return Tags[id]
end

function XArchiveConfigs.GetArchiveTagAllList()
    return ArchiveTagAllList
end

function XArchiveConfigs.GetSameNpcId(npcId)
    return ArchiveSameNpc[npcId] and ArchiveSameNpc[npcId] or npcId
end

function XArchiveConfigs.GetMonsterTransDataGroup(npcId)
    return ArchiveMonsterTransDic[npcId]
end

function XArchiveConfigs.GetMonsterTransDatas(npcId, npcState)
    local archiveMonsterTransData = ArchiveMonsterTransDic[npcId]
    return archiveMonsterTransData and archiveMonsterTransData[npcState]
end

function XArchiveConfigs.GetMonsterEffectDatas(npcId, npcState)
    local archiveMonsterEffectData = ArchiveMonsterEffectDatasDic[npcId]
    return archiveMonsterEffectData and archiveMonsterEffectData[npcState]
end

-------------------------------------------------------------
function XArchiveConfigs.GetAwarenessSettingById(Id)
    return AwarenessSettings[Id]
end

function XArchiveConfigs.GetAwarenessSettings()
    return AwarenessSettings
end

function XArchiveConfigs.GetAwarenessGroupTypes()
    local list = {}
    for _, type in pairs(AwarenessGroupType) do
        table.insert(list, type)
    end
    return XArchiveConfigs.SortByOrder(list)
end

function XArchiveConfigs.GetWeaponSettingById(Id)
    return WeaponSettings[Id]
end

function XArchiveConfigs.GetWeaponSettings()
    return WeaponSettings
end

function XArchiveConfigs.GetMonsterNpcDataById(Id)
    if not MonsterNpcDatas[Id] then
        XLog.ErrorTableDataNotFound("XArchiveConfigs.GetMonsterNpcDataById", "配置表项", TABLE_MONSTERNPCDATA, "Id", tostring(Id))
    end
    return MonsterNpcDatas[Id] or {}
end

function XArchiveConfigs.GetMonsterNpcIdByModelId(modelId)
    for npcId, data in pairs(MonsterNpcDatas) do
        if data.ModelId == modelId then
            return data.Id
        end
    end
    return false
end

-----------------------------怪物图鉴----------------------------
function XArchiveConfigs.SetArchiveTagAllList()
    ArchiveTagAllList = {}
    for _, tag in pairs(Tags or {}) do
        for _, groupId in pairs(tag.TagGroupId) do
            if not ArchiveTagAllList[groupId] then
                ArchiveTagAllList[groupId] = {}
            end
            if tag.IsNotShow == 0 then
                table.insert(ArchiveTagAllList[groupId], tag)
            end
        end
    end
    for _, v in pairs(ArchiveTagAllList) do
        XArchiveConfigs.SortByOrder(v)
    end
end

function XArchiveConfigs.SetArchiveSameNpc()
    for _, group in pairs(SameNpcGroups or {}) do
        for _, npcId in pairs(group.NpcId) do
            ArchiveSameNpc[npcId] = group.Id
        end
    end
end

function XArchiveConfigs.SetArchiveMonsterModelTransDic()
    for _, transData in pairs(MonsterModelTrans or {}) do
        local archiveMonsterTransData = ArchiveMonsterTransDic[transData.NpcId]
        if not archiveMonsterTransData then
            archiveMonsterTransData = {}
            ArchiveMonsterTransDic[transData.NpcId] = archiveMonsterTransData
        end

        archiveMonsterTransData[transData.NpcState] = transData
    end
end

function XArchiveConfigs.SetArchiveMonsterEffectsDic()
    for _, transData in pairs(MonsterEffects or {}) do
        local archiveMonsterEffectData = ArchiveMonsterEffectDatasDic[transData.NpcId]
        if not archiveMonsterEffectData then
            archiveMonsterEffectData = {}
            ArchiveMonsterEffectDatasDic[transData.NpcId] = archiveMonsterEffectData
        end

        local archiveMonsterEffect = archiveMonsterEffectData[transData.NpcState]
        if not archiveMonsterEffect then
            archiveMonsterEffect = {}
            archiveMonsterEffectData[transData.NpcState] = archiveMonsterEffect
        end
        archiveMonsterEffect[transData.EffectNodeName] = transData.EffectPath
    end
end

function XArchiveConfigs.SortByOrder(list)
    tableSort(list, function(a, b)
        if a.Order then
            if a.Order == b.Order then
                return a.Id > b.Id
            else
                return a.Order < b.Order
            end
        else
            if a:GetOrder() == b:GetOrder() then
                return a:GetId() > b:GetId()
            else
                return a:GetOrder() < b:GetOrder()
            end
        end
    end)
    return list
end

function XArchiveConfigs.GetMonsterRealName(id)
    local name = XArchiveConfigs.GetMonsterNpcDataById(id).Name
    if not name then
        XLog.ErrorTableDataNotFound("XArchiveConfigs.GetMonsterRealName", "配置表项中的Name字段", TABLE_MONSTERNPCDATA, "id", tostring(id))
        return ""
    end
    return name
end

function XArchiveConfigs.GetMonsterModel(id)
    return XArchiveConfigs.GetMonsterNpcDataById(id).ModelId
end

function XArchiveConfigs.GetCountUnitChange(count)
    local newCount = count
    if count >= 1000 then
        newCount = count / 1000
    else
        return newCount
    end
    local a, b = math.modf(newCount)
    return b >= 0.05 and string.format("%.1fk", newCount) or string.format("%dk", a)
end

-- 武器、意识相关------------->>>
function XArchiveConfigs.CreateShowedWeaponTypeList()
    for _, group in pairs(WeaponGroup) do
        table.insert(ShowedWeaponTypeList, group.Id)
    end

    table.sort(ShowedWeaponTypeList, function(aType, bType)
        local aData = XArchiveConfigs.GetWeaponGroupByType(aType)
        local bData = XArchiveConfigs.GetWeaponGroupByType(bType)
        return aData.Order < bData.Order
    end)
end

function XArchiveConfigs.CreateWeaponTemplateIdToSettingDataListDic()
    local equipId
    for _, settingData in pairs(WeaponSettings) do
        equipId = settingData.EquipId
        WeaponTemplateIdToSettingListDic[equipId] = WeaponTemplateIdToSettingListDic[equipId] or {}
        table.insert(WeaponTemplateIdToSettingListDic[equipId], settingData)
    end
end

function XArchiveConfigs.SetWeaponSumCollectNum()
    for _, _ in pairs(WeaponTemplateIdToSettingListDic) do
        WeaponSumCollectNum = WeaponSumCollectNum + 1
    end
end

function XArchiveConfigs.CreateWeaponTypeToIdsDic()
    for type, _ in pairs(WeaponGroup) do
        WeaponTypeToIdsDic[type] = {}
    end

    local templateData
    local equipType
    for templateId, _ in pairs(WeaponTemplateIdToSettingListDic) do
        templateData = XEquipConfig.GetEquipCfg(templateId)
        equipType = templateData.Type
        if WeaponTypeToIdsDic[equipType] then
            table.insert(WeaponTypeToIdsDic[equipType], templateId)
        end
    end
end

function XArchiveConfigs.CreateAwarenessShowedStatusDic()
    local templateIdList
    for suitId, _ in pairs(AwarenessGroup) do
        templateIdList = XEquipConfig.GetEquipTemplateIdsListBySuitId(suitId)
        for _, templateId in ipairs(templateIdList) do
            AwarenessShowedStatusDic[templateId] = true
        end
    end
end

function XArchiveConfigs.SetAwarenessSumCollectNum()
    for _, _ in pairs(AwarenessShowedStatusDic) do
        AwarenessSumCollectNum = AwarenessSumCollectNum + 1
    end
end

function XArchiveConfigs.CreateAwarenessTypeToGroupDatasDic()
    for _, type in pairs(AwarenessGroupType) do
        AwarenessTypeToGroupDatasDic[type.GroupId] = {}
    end

    local groupType
    for _, groupData in pairs(AwarenessGroup) do
        groupType = groupData.Type
        if AwarenessTypeToGroupDatasDic[groupType] then
            table.insert(AwarenessTypeToGroupDatasDic[groupType], groupData)
        end
    end
end

function XArchiveConfigs.CreateAwarenessSiteToBgPathDic()
    XArchiveConfigs.SiteToBgPath = {
        [XEquipConfig.EquipSite.Awareness.One] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath1"),
        [XEquipConfig.EquipSite.Awareness.Two] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath2"),
        [XEquipConfig.EquipSite.Awareness.Three] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath3"),
        [XEquipConfig.EquipSite.Awareness.Four] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath4"),
        [XEquipConfig.EquipSite.Awareness.Five] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath5"),
        [XEquipConfig.EquipSite.Awareness.Six] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath6"),
    }
end

function XArchiveConfigs.CreateAwarenessSuitIdToSettingDataListDic()
    local suitId
    for _, settingData in pairs(AwarenessSettings) do
        suitId = settingData.SuitId
        AwarenessSuitIdToSettingListDic[suitId] = AwarenessSuitIdToSettingListDic[suitId] or {}
        table.insert(AwarenessSuitIdToSettingListDic[suitId], settingData)
    end
end

function XArchiveConfigs.GetWeaponSumCollectNum()
    return WeaponSumCollectNum
end

function XArchiveConfigs.GetWeaponGroup()
    return WeaponGroup
end

function XArchiveConfigs.GetWeaponGroupByType(type)
    return WeaponGroup[type]
end

function XArchiveConfigs.GetWeaponGroupName(type)
    return WeaponGroup[type].GroupName
end

function XArchiveConfigs.GetShowedWeaponTypeList()
    return ShowedWeaponTypeList
end

function XArchiveConfigs.GetWeaponTypeToIdsDic()
    return WeaponTypeToIdsDic
end

function XArchiveConfigs.GetWeaponTemplateIdListByType(type)
    return WeaponTypeToIdsDic[type]
end

function XArchiveConfigs.GetAwarenessSumCollectNum()
    return AwarenessSumCollectNum
end

function XArchiveConfigs.GetAwarenessGroup()
    return AwarenessGroup
end

function XArchiveConfigs.GetAwarenessTypeToGroupDatasDic()
    return AwarenessTypeToGroupDatasDic
end

function XArchiveConfigs.GetAwarenessShowedStatusDic()
    return AwarenessShowedStatusDic
end

function XArchiveConfigs.GetAwarenessSuitInfoTemplate(suitId)
    return AwarenessGroup[suitId]
end

function XArchiveConfigs.GetAwarenessSuitInfoGetType(suitId)
    return AwarenessGroup[suitId].Type
end

function XArchiveConfigs.GetAwarenessSuitInfoIconPath(suitId)
    return AwarenessGroup[suitId].IconPath
end

function XArchiveConfigs.GetWeaponTemplateIdToSettingListDic()
    return WeaponTemplateIdToSettingListDic
end

-- 武器设定或故事
function XArchiveConfigs.GetWeaponSettingList(id, settingType)
    local list = {}
    local settingDataList = WeaponTemplateIdToSettingListDic[id]
    if settingDataList then
        if not settingType or settingType == XArchiveConfigs.SettingType.All then
            list = settingDataList
        else
            for _, settingData in pairs(settingDataList) do
                if settingData.Type == settingType then
                    table.insert(list, settingData)
                end
            end

        end
    end
    return XArchiveConfigs.SortByOrder(list)
end

function XArchiveConfigs.GetWeaponSettingType(id)
    return WeaponSettings[id].Type
end

function XArchiveConfigs.GetWeaponTemplateIdBySettingId(id)
    return WeaponSettings[id].EquipId
end

-- 意识设定或故事
function XArchiveConfigs.GetAwarenessSettingList(id, settingType)
    local list = {}
    local settingDataList = AwarenessSuitIdToSettingListDic[id]
    if settingDataList then
        if not settingType or settingType == XArchiveConfigs.SettingType.All then
            list = settingDataList
        else
            for _, settingData in pairs(settingDataList) do
                if settingData.Type == settingType then
                    table.insert(list, settingData)
                end
            end
        end
    else
        XLog.ErrorTableDataNotFound("XArchiveConfigs.GetAwarenessSettingList", "配置表项", TABLE_AWARENESSSETTING, "id", tostring(id))
    end
    return XArchiveConfigs.SortByOrder(list)
end

function XArchiveConfigs.GetAwarenessSettingType(id)
    return AwarenessSettings[id].Type
end

function XArchiveConfigs.GetAwarenessSuitIdBySettingId(id)
    return AwarenessSettings[id].SuitId
end

-- 武器、意识相关-------------<<<
-- 剧情相关------------->>>
function XArchiveConfigs.GetArchiveStoryGroupAllList()
    return ArchiveStoryGroupAllList
end

function XArchiveConfigs.GetArchiveStoryChapterConfigs()
    return StoryChapters
end

function XArchiveConfigs.GetArchiveStoryChapterConfigById(id)
    return StoryChapters[id]
end

function XArchiveConfigs.GetArchiveStoryDetailConfigs()
    return StoryDetails
end

function XArchiveConfigs.GetArchiveStoryDetailConfigById(id)
    return StoryDetails[id]
end

function XArchiveConfigs.SetArchiveStoryGroupAllList()
    for _, group in pairs(StoryGroups or {}) do
        table.insert(ArchiveStoryGroupAllList, group)
    end
    XArchiveConfigs.SortByOrder(ArchiveStoryGroupAllList)
end
-- 剧情相关-------------<<<
-- NPC相关------------->>>
function XArchiveConfigs.GetArchiveStoryNpcConfigs()
    return StoryNpc
end

function XArchiveConfigs.GetArchiveStoryNpcConfigById(id)
    return StoryNpc[id]
end

function XArchiveConfigs.GetArchiveStoryNpcSettingConfigs()
    return StoryNpcSetting
end

function XArchiveConfigs.GetArchiveStoryNpcSettingConfigById(id)
    return StoryNpcSetting[id]
end
-- NPC相关-------------<<<
-- CG相关------------->>>
function XArchiveConfigs.GetArchiveCGGroupConfigs()
    return CGGroups
end

function XArchiveConfigs.GetArchiveCGDetailConfigs()
    return CGDetails
end

function XArchiveConfigs.GetArchiveCGDetailConfigById(id)
    return CGDetails[id]
end

-- CG相关-------------<<<
-- 邮件通讯相关------------->>>
function XArchiveConfigs.GetArchiveMailsConfigs()
    return ArchiveMails
end

function XArchiveConfigs.GetArchiveMailsConfigById(id)
    return ArchiveMails[id]
end

function XArchiveConfigs.GetArchiveCommunicationsConfigs()
    return ArchiveCommunications
end

function XArchiveConfigs.GetArchiveCommunicationsConfigById(id)
    return ArchiveCommunications[id]
end

function XArchiveConfigs.GetEventDateGroupsConfigs()
    return EventDateGroups
end

-- 邮件通讯相关-------------<<<
-- 伙伴相关------------->>>
function XArchiveConfigs.GetPartnerSettingConfigs()
    return ArchivePartnerSettings
end

function XArchiveConfigs.GetPartnerSettingConfigById(id)
    if not ArchivePartnerSettings[id] then
        XLog.Error("Id is not exist in " .. TABLE_ARCHIVE_PARTNER_SETTING .. " id = " .. id)
        return
    end
    return ArchivePartnerSettings[id]
end

function XArchiveConfigs.GetPartnerConfigs()
    return ArchivePartners
end

function XArchiveConfigs.GetPartnerConfigById(id)
    if not ArchivePartners[id] then
        XLog.Error("Id is not exist in " .. TABLE_ARCHIVE_PARTNER .. " id = " .. id)
        return
    end
    return ArchivePartners[id]
end

function XArchiveConfigs.GetPartnerGroupConfigs()
    return ArchivePartnerGroups
end

function XArchiveConfigs.GetPartnerGroupConfigById(id)
    if not ArchivePartnerGroups[id] then
        XLog.Error("Id is not exist in " .. TABLE_ARCHIVE_PARTNER_GROUP .. " id = " .. id)
        return
    end
    return ArchivePartnerGroups[id]
end

-- 伙伴相关-------------<<<
function XArchiveConfigs.GetWeaponSettingPath()
    return TABLE_WEAPONSETTING
end

-- PV相关------------->>>
function XArchiveConfigs.GetPVGroups()
    local list = {}
    for _, group in pairs(PVGroups) do
        table.insert(list, group)
    end
    return XArchiveConfigs.SortByOrder(list)
end

local IsInitPVDetail = false
local PVGroupIdToDetailIdList = {}
local PVDetailIdList = {}
local InitPVDetail = function()
    if IsInitPVDetail then
        return
    end

    for id, v in pairs(PVDetails) do
        if not PVGroupIdToDetailIdList[v.GroupId] then
            PVGroupIdToDetailIdList[v.GroupId] = {}
        end
        table.insert(PVGroupIdToDetailIdList[v.GroupId], id)
        table.insert(PVDetailIdList, id)
    end
    for _, idList in pairs(PVGroupIdToDetailIdList) do
        tableSort(idList, function(a, b)
            return a < b
        end)
    end

    IsInitPVDetail = true
end

local GetPVDetailConfig = function(id)
    if not PVDetails[id] then
        XLog.Error("Id is not exist in " .. TABLE_PVDETAIL .. " id = " .. id)
        return
    end
    return PVDetails[id]
end

function XArchiveConfigs.GetPVDetailIdList(groupId)
    InitPVDetail()
    return groupId and PVGroupIdToDetailIdList[groupId] or PVDetailIdList
end

function XArchiveConfigs.GetPVDetailName(id)
    local config = GetPVDetailConfig(id)
    return config.Name
end

function XArchiveConfigs.GetPVDetailBg(id)
    local config = GetPVDetailConfig(id)
    return config.Bg
end

function XArchiveConfigs.GetPVDetailLockBg(id)
    local config = GetPVDetailConfig(id)
    return config.LockBg
end

function XArchiveConfigs.GetPVDetailUnLockTime(id)
    local config = GetPVDetailConfig(id)
    return config.UnLockTime
end

function XArchiveConfigs.GetPVDetailCondition(id)
    local config = GetPVDetailConfig(id)
    return config.Condition
end

function XArchiveConfigs.GetPVDetailPv(id)
    local config = GetPVDetailConfig(id)
    return config.Pv
end

function XArchiveConfigs.GetPVDetailIsShowRedPoint(id)
    local config = GetPVDetailConfig(id)
    return config.IsShowRed
end

function XArchiveConfigs.GetPVDetailBgWidth(id)
    local config = GetPVDetailConfig(id)
    return config.BgWidth
end

function XArchiveConfigs.GetPVDetailBgHigh(id)
    local config = GetPVDetailConfig(id)
    return config.BgHigh
end

function XArchiveConfigs.GetPVDetailBgOffSetX(id)
    local config = GetPVDetailConfig(id)
    return config.BgOffSetX
end

function XArchiveConfigs.GetPVDetailBgOffSetY(id)
    local config = GetPVDetailConfig(id)
    return config.BgOffSetY
end
-- PV相关-------------<<<