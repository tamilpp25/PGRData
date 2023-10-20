---@class XArchiveModel : XModel
local XArchiveModel = XClass(XModel, "XArchiveModel")

local ArchiveClientTableKey={
    MonsterNpcData={DirPath=XConfigUtil.DirectoryType.Client},
    MonsterModelTrans={DirPath=XConfigUtil.DirectoryType.Client},
    MonsterEffect={DirPath=XConfigUtil.DirectoryType.Client},
    ArchiveWeaponGroup={DirPath=XConfigUtil.DirectoryType.Client},
    ArchiveAwarenessGroup={DirPath=XConfigUtil.DirectoryType.Client},
    ArchiveAwarenessGroupType={DirPath=XConfigUtil.DirectoryType.Client,Identifier='GroupId'},
    ArchivePartner={DirPath=XConfigUtil.DirectoryType.Client},
    ArchivePartnerGroup={DirPath=XConfigUtil.DirectoryType.Client},
}

local ArchiveShareTableKey={
    Archive={DirPath=XConfigUtil.DirectoryType.Share},
    MonsterSetting={DirPath=XConfigUtil.DirectoryType.Share},
    SameNpcGroup={DirPath=XConfigUtil.DirectoryType.Share},
    AwarenessSetting={DirPath=XConfigUtil.DirectoryType.Share},
    WeaponSetting={DirPath=XConfigUtil.DirectoryType.Share},
    ArchiveMail={DirPath=XConfigUtil.DirectoryType.Share},
    PartnerSetting={DirPath=XConfigUtil.DirectoryType.Share},
}

local TablePathTable={
    TABLE_TAG = "Share/Archive/Tag.tab",
    TABLE_MONSTER = "Share/Archive/Monster.tab",
    TABLE_MONSTERINFO = "Share/Archive/MonsterInfo.tab",
    TABLE_MONSTERSKILL = "Share/Archive/MonsterSkill.tab",
    TABLE_CGDETAIL = "Share/Archive/CGDetail.tab",
    TABLE_STORYCHAPTER = "Share/Archive/StoryChapter.tab",
    TABLE_STORYNPC = "Share/Archive/StoryNpc.tab",
    TABLE_STORYNPCSETTING = "Share/Archive/StoryNpcSetting.tab",
    TABLE_CGGROUP = "Share/Archive/CGGroup.tab",
    TABLE_COMMUNICATION = "Share/Archive/Communication.tab",
    TABLE_EVENTDATEGROUP = "Share/Archive/EventDateGroup.tab",
    TABLE_PVGROUP = "Client/Archive/PVGroup.tab",
    TABLE_PVDETAIL = "Share/Archive/PVDetail.tab",
    TABLE_STORYDETAIL = "Share/Archive/StoryDetail.tab",
    TABLE_STORYGROUP = "Share/Archive/StoryGroup.tab",
}

local PrivateFuncMap={}
local tableSort = table.sort
local tableInsert=table.insert

function XArchiveModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    --配置表定义
    self._ConfigUtil:InitConfigByTableKey('Archive',ArchiveClientTableKey,XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Archive',ArchiveShareTableKey,XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfig({
        [TablePathTable.TABLE_TAG]={XConfigUtil.ReadType.Int,XTable.XTableArchiveTag,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_MONSTER]={XConfigUtil.ReadType.Int,XTable.XTableArchiveMonster,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_MONSTERINFO]={XConfigUtil.ReadType.Int,XTable.XTableArchiveMonsterInfo,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_MONSTERSKILL]={XConfigUtil.ReadType.Int,XTable.XTableArchiveMonsterSkill,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_CGDETAIL]={XConfigUtil.ReadType.Int,XTable.XTableArchiveCGDetail,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_STORYCHAPTER]={XConfigUtil.ReadType.Int,XTable.XTableArchiveStoryChapter,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_STORYNPC]={XConfigUtil.ReadType.Int,XTable.XTableArchiveStoryNpc,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_STORYNPCSETTING]={XConfigUtil.ReadType.Int,XTable.XTableArchiveStoryNpcSetting,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_CGGROUP]={XConfigUtil.ReadType.Int,XTable.XTableArchiveCGGroup,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_COMMUNICATION]={XConfigUtil.ReadType.Int,XTable.XTableArchiveCommunication,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_EVENTDATEGROUP]={XConfigUtil.ReadType.Int,XTable.XTableArchiveEventDateGroup,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_PVGROUP]={XConfigUtil.ReadType.Int,XTable.XTableArchivePVGroup,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_PVDETAIL]={XConfigUtil.ReadType.Int,XTable.XTableArchivePVDetail,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_STORYDETAIL]={XConfigUtil.ReadType.Int,XTable.XTableArchiveStoryDetail,"Id",XConfigUtil.CacheType.Normal},
        [TablePathTable.TABLE_STORYGROUP]={XConfigUtil.ReadType.Int,XTable.XTableArchiveStoryGroup,"Id",XConfigUtil.CacheType.Private},

    })
    PrivateFuncMap.InitOtherConfig(self)
    --二次配置数据
    PrivateFuncMap.InitSecondaryConfigs(self)
    --
    PrivateFuncMap.InitData(self)
end

function XArchiveModel:ClearPrivate()
    --这里执行内部数据清理

end

function XArchiveModel:ResetAll()
    --这里执行重登数据清理
    PrivateFuncMap.InitData(self)
end

----------public start----------
function XArchiveModel:SortByOrder(list)
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

function XArchiveModel:GetArchivePartnerSetting(partnerTemplateId,type)
    local settingList = self:GetArchivePartnerSettingList()[partnerTemplateId]
    if not settingList then
        XLog.Error("Id is not exist in Share/Archive/PartnerSetting.tab".." id = " .. partnerTemplateId)
        return
    end
    local setting = settingList[type]
    if not setting then
        return
    end
    return self:SortByOrder(setting)
end
----------public end----------

----------private start----------

---初始化二次处理的配置数据
PrivateFuncMap.InitSecondaryConfigs=function(model)
    model._ArchiveTagAllList={}
    model._ArchiveSameNpc={}
    model._ArchiveMonsterTransDic={}
    model._ArchiveMonsterEffectDatasDic={}
    model._ShowedWeaponTypeList={}
    model._WeaponTemplateIdToSettingListDic={}
    model._WeaponSumCollectNum=0
    model._WeaponTypeToIdsDic={}
    model._AwarenessShowedStatusDic={}
    model._AwarenessSumCollectNum=0
    model._AwarenessTypeToGroupDatasDic={}
    model._AwarenessSuitIdToSettingListDic={}
    model._ArchiveStoryGroupAllList={}

    model._ArchiveMonsterList = {}
    model._ArchiveMonsterInfoList = {}
    model._ArchiveMonsterSkillList = {}
    model._ArchiveMonsterSettingList = {}
    model._ArchiveNpcToMonster = {}
    model._ArchiveMonsterData = {}
    model._ArchiveStoryChapterList = {}
    model._ArchiveStoryDetailList = {}
    model._ArchiveStoryNpcList = {}
    model._ArchiveStoryNpcSettingList = {}
    model._ArchiveCGDetailList = {}
    model._ArchiveCGDetailData = {}
    model._ArchiveMailList = {}
    model._ArchiveCommunicationList = {}
    model._ArchivePartnerList = {}
    model._ArchivePartnerSettingList = {}
    model._ArchiveStoryChapterDic = {}
    
    model._IsInitPVDetail = false
    model._PVGroupIdToDetailIdList = {}
    model._PVDetailIdList = {}
end

PrivateFuncMap.InitData=function(model)
    model._ArchiveShowedMonsterList={}


    model._MonsterRedPointDic = {}

    model._ArchiveShowedCGList = {}
    model._ArchiveShowedStoryList = {}--只保存通关的活动关卡ID，到了解禁事件后会被清除


    model._PartnerUnLockDic = {}
    model._PartnerUnLockSettingDic = {}

    model._ArchiveMonsterUnlockIdsList = {}
    model._ArchiveMonsterInfoUnlockIdsList = {}
    model._ArchiveMonsterSkillUnlockIdsList = {}
    model._ArchiveMonsterSettingUnlockIdsList = {}

    model._ArchiveMonsterEvaluateList = {}
    model._ArchiveMonsterMySelfEvaluateList = {}
    model._ArchiveStoryEvaluateList = {}
    model._ArchiveStoryMySelfEvaluateList = {}

    model._LastSyncMonsterEvaluateTimes = {}
    model._LastSyncStoryEvaluateTimes = {}
    -- 记录服务端武器数据，以TemplateId为键
    model._ArchiveWeaponServerData = {}
    -- 记录服务端意识数据，以TemplateId为键
    model._ArchiveAwarenessServerData = {}
    -- 记录suitId对应获得的数量
    model._ArchiveAwarenessSuitToAwarenessCountDic = {}
    -- 记录解锁的武器是否已读（解锁）（已读则无相关红点）
    model._ArchiveWeaponUnlockServerData = {}
    -- 记录解锁的意识套装是否已读（解锁）
    model._ArchiveAwarenessSuitUnlockServerData = {}
    -- 记录服务端武器设定已读（解锁）数据，以SettingId为键
    model._ArchiveWeaponSettingUnlockServerData = {}
    -- 记录服务端意识设定已读（解锁）数据，以SettingId为键
    model._ArchiveAwarenessSettingUnlockServerData = {}
    -- 记录服务端PV解锁Id
    model._UnlockPvDetails = {}
    -- 记录解锁邮件图鉴
    model._UnlockArchiveMails = {}

    model._ArchiveWeaponRedPointCountDic = {}    --每个武器类型拥有的红点数量
    model._ArchiveWeaponTotalRedPointCount = 0   --武器图鉴拥有的红点数量

    model._ArchiveAwarenessSuitRedPointCountDic = {} --每个意识获取类型下对应套装拥有的红点数量
    model._ArchiveAwarenessSuitTotalRedPointCount = 0    --意识图鉴拥有的红点数量

    model._ArchiveWeaponSettingCanUnlockDic = {} --武器设定可以解锁的
    model._ArchiveNewWeaponSettingIdsDic = {}  --武器id对应的新的武器设定ids
    model._ArchiveWeaponSettingRedPointCountDic = {} --每个武器类型下对应设定拥有的红点数量
    model._ArchiveWeaponSettingTotalRedPointCount = 0  --武器设定拥有的总红点数量

    model._ArchiveAwarenessSettingCanUnlockDic = {} --意识设定可以解锁的
    model._ArchiveNewAwarenessSettingIdsDic = {}  --意识suitId对应的新的设定ids
    model._ArchiveAwarenessSettingRedPointCountDic = {} --每个意识获取类型下对应设定拥有的红点数量
    model._ArchiveAwarenessSettingTotalRedPointCount = 0  --意识设定拥有的总红点数量
    --<<<红点相关
end

PrivateFuncMap.InitOtherConfig=function(model)
    model.SiteToBgPath = {
        [XEquipConfig.EquipSite.Awareness.One] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath1"),
        [XEquipConfig.EquipSite.Awareness.Two] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath2"),
        [XEquipConfig.EquipSite.Awareness.Three] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath3"),
        [XEquipConfig.EquipSite.Awareness.Four] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath4"),
        [XEquipConfig.EquipSite.Awareness.Five] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath5"),
        [XEquipConfig.EquipSite.Awareness.Six] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath6"),
    }
    
    model.StarToQualityName = {
        [XEnumConst.Archive.EquipStarType.All] = CS.XTextManager.GetText("ArchiveAwarenessFliterAll"),
        [XEnumConst.Archive.EquipStarType.Two] = CS.XTextManager.GetText("ArchiveAwarenessFliterTwoStar"),
        [XEnumConst.Archive.EquipStarType.Three] = CS.XTextManager.GetText("ArchiveAwarenessFliterThreeStar"),
        [XEnumConst.Archive.EquipStarType.Four] = CS.XTextManager.GetText("ArchiveAwarenessFliterFourStar"),
        [XEnumConst.Archive.EquipStarType.Five] = CS.XTextManager.GetText("ArchiveAwarenessFliterFiveStar"),
        [XEnumConst.Archive.EquipStarType.Six] = CS.XTextManager.GetText("ArchiveAwarenessFliterSixStar"),
    }

    model.EvaluateOnForAll = CS.XGame.ClientConfig:GetInt("ArchiveEvaluateOnForAll")
end 


PrivateFuncMap.InitArchiveMonsterList=function(model)
    local XArchiveMonsterEntity = require("XEntity/XArchive/XArchiveMonsterEntity")
    for _, monster in pairs(model:GetMonster() or {}) do
        if not model._ArchiveMonsterList[monster.Type] then
            model._ArchiveMonsterList[monster.Type] = {}
        end
        local tmp = XArchiveMonsterEntity.New(monster.Id)
        for _,id in pairs(monster.NpcId or {})do
            model._ArchiveNpcToMonster[id] = monster.Id
        end
        tableInsert(model._ArchiveMonsterList[monster.Type], tmp)
    end
    for _,list in pairs(model._ArchiveMonsterList)do
        model:SortByOrder(list)
        for _,monster in pairs(list) do
            model._ArchiveMonsterData[monster:GetId()] = monster
        end
    end
end

PrivateFuncMap.InitArchiveMonsterDetail=function(model,entityType,detailCfg,allList,IsHavetype)
    local XArchiveMonsterDetailEntity = require("XEntity/XArchive/XArchiveMonsterDetailEntity")
    for _, detail in pairs(detailCfg or {}) do
    
        if not allList[detail.GroupId] then
            allList[detail.GroupId] = {}
        end
    
        if IsHavetype and not allList[detail.GroupId][detail.Type] then
            allList[detail.GroupId][detail.Type] = {}
        end
    
        local tmp = XArchiveMonsterDetailEntity.New(entityType,detail.Id)
    
        if IsHavetype then
            table.insert(allList[detail.GroupId][detail.Type], tmp)
        else
            table.insert(allList[detail.GroupId], tmp)
        end
    end
    for _,group in pairs(allList) do
        if IsHavetype then
            for _,type in pairs(group) do
                model:SortByOrder(type)
            end
        else
            model:SortByOrder(group)
        end
    end
end

PrivateFuncMap.InitArchiveStoryChapterList=function(model)
    local XArchiveStoryChapterEntity = require("XEntity/XArchive/XArchiveStoryChapterEntity")
    for _, chapter in pairs(model:GetStoryChapter() or {}) do

        if not model._ArchiveStoryChapterList[chapter.GroupId] then
            model._ArchiveStoryChapterList[chapter.GroupId] = {}
        end

        local tmp = XArchiveStoryChapterEntity.New(chapter.Id)
        table.insert(model._ArchiveStoryChapterList[chapter.GroupId], tmp)

        model._ArchiveStoryChapterDic[chapter.Id] = tmp
    end
    for _,group in pairs(model._ArchiveStoryChapterList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchiveStoryDetailAllList=function(model)
    local XArchiveStoryDetailEntity = require("XEntity/XArchive/XArchiveStoryDetailEntity")
    for _, detail in pairs(model:GetStoryDetail() or {}) do

        if not model._ArchiveStoryDetailList[detail.ChapterId] then
            model._ArchiveStoryDetailList[detail.ChapterId] = {}
        end

        local tmp = XArchiveStoryDetailEntity.New(detail.Id)
        table.insert(model._ArchiveStoryDetailList[detail.ChapterId], tmp)
    end
    for _,group in pairs(model._ArchiveStoryDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴Npc数据
PrivateFuncMap.InitArchiveStoryNpcAllList=function(model)
    local XArchiveNpcEntity = require("XEntity/XArchive/XArchiveNpcEntity")
    for _, npcCfg in pairs(model:GetStoryNpc() or {}) do

        local tmp = XArchiveNpcEntity.New(npcCfg.Id)
        table.insert(model._ArchiveStoryNpcList, tmp)
    end
    model:SortByOrder(model._ArchiveStoryNpcList)
end

--创建图鉴NpcSetting数据
PrivateFuncMap.InitArchiveStoryNpcSettingAllList=function(model)
    local XArchiveNpcDetailEntity = require("XEntity/XArchive/XArchiveNpcDetailEntity")
    for _, settingCfg in pairs(model:GetStoryNpcSetting() or {}) do

        if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId] then
            model._ArchiveStoryNpcSettingList[settingCfg.GroupId] = {}
        end

        if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] then
            model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] = {}
        end

        local tmp = XArchiveNpcDetailEntity.New(settingCfg.Id)
        table.insert(model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type], tmp)
    end
    for _,group in pairs(model._ArchiveStoryNpcSettingList) do
        for _,type in pairs(group) do
            model:SortByOrder(type)
        end
    end
end

--创建图鉴NpcSetting数据
PrivateFuncMap.InitArchiveCGAllList=function(model)
    local XArchiveCGEntity = require("XEntity/XArchive/XArchiveCGEntity")
    for _, CGDetailCfg in pairs(model:GetCGDetail() or {}) do

        if not model._ArchiveCGDetailList[CGDetailCfg.GroupId] then
            model._ArchiveCGDetailList[CGDetailCfg.GroupId] = {}
        end

        local tmp = XArchiveCGEntity.New(CGDetailCfg.Id)
        table.insert(model._ArchiveCGDetailList[CGDetailCfg.GroupId], tmp)
        model._ArchiveCGDetailData[CGDetailCfg.Id] = tmp
    end
    for _,group in pairs(model._ArchiveCGDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴邮件数据
PrivateFuncMap.InitArchiveMailList=function(model)
    local XArchiveMailEntity = require("XEntity/XArchive/XArchiveMailEntity")
    for _, mailCfg in pairs(model:GetArchiveMail() or {}) do
        if not model._ArchiveMailList[mailCfg.GroupId] then
            model._ArchiveMailList[mailCfg.GroupId] = {}
        end
        local tmp = XArchiveMailEntity.New(mailCfg.Id)
        table.insert(model._ArchiveMailList[mailCfg.GroupId], tmp)
    end
    for _,group in pairs(model._ArchiveMailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴通讯数据
PrivateFuncMap.InitArchiveCommunicationList=function(model)
    local XArchiveCommunicationEntity = require("XEntity/XArchive/XArchiveCommunicationEntity")
    for _, communicationCfg in pairs(model:GetCommunication() or {}) do

        if not model._ArchiveCommunicationList[communicationCfg.GroupId] then
            model._ArchiveCommunicationList[communicationCfg.GroupId] = {}
        end

        local tmp = XArchiveCommunicationEntity.New(communicationCfg.Id)
        table.insert(model._ArchiveCommunicationList[communicationCfg.GroupId], tmp)
    end
    for _,group in pairs(model._ArchiveCommunicationList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchivePartnerSetting=function(model)
    local XArchivePartnerSettingEntity = require("XEntity/XArchive/XArchivePartnerSettingEntity")
    local detailCfg = model:GetPartnerSetting()
    for _, detail in pairs(detailCfg or {}) do

        if not model._ArchivePartnerSettingList[detail.GroupId] then
            model._ArchivePartnerSettingList[detail.GroupId] = {}
        end

        if not model._ArchivePartnerSettingList[detail.GroupId][detail.Type] then
            model._ArchivePartnerSettingList[detail.GroupId][detail.Type] = {}
        end

        local tmp = XArchivePartnerSettingEntity.New(detail.Id)
        table.insert(model._ArchivePartnerSettingList[detail.GroupId][detail.Type], tmp)
    end
    for _,group in pairs(model._ArchivePartnerSettingList) do
        for _,type in pairs(group) do
            model:SortByOrder(type)
        end
    end
end

--生成图鉴伙伴数据
PrivateFuncMap.InitArchivePartnerList=function(model)
    local XArchivePartnerEntity = require("XEntity/XArchive/XArchivePartnerEntity")
    local templateList = model:GetArchivePartner()
    for _,template in pairs(templateList or {}) do
        if not model._ArchivePartnerList[template.GroupId] then
            model._ArchivePartnerList[template.GroupId] = {}
        end
        local entity = XArchivePartnerEntity.New(template.Id,
                model:GetArchivePartnerSetting(template.Id,XEnumConst.Archive.PartnerSettingType.Story),
                model:GetArchivePartnerSetting(template.Id,XEnumConst.Archive.PartnerSettingType.Setting))
        table.insert(model._ArchivePartnerList[template.GroupId],entity)
    end
    for _,group in pairs(model._ArchivePartnerList) do
        model:SortByOrder(group)
    end
end
----------private end----------

----------config start----------
--region 基础读表
function XArchiveModel:GetMonsterNpcData()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.MonsterNpcData)
end

function XArchiveModel:GetMonsterModelTrans()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.MonsterModelTrans)
end

function XArchiveModel:GetMonsterEffect()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.MonsterEffect)
end

function XArchiveModel:GetArchiveWeaponGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveWeaponGroup)
end

function XArchiveModel:GetArchiveAwarenessGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveAwarenessGroup)
end

function XArchiveModel:GetArchiveAwarenessGroupType()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveAwarenessGroupType)
end

function XArchiveModel:GetArchivePartner()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchivePartner)
end

function XArchiveModel:GetArchivePartnerGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchivePartnerGroup)
end

function XArchiveModel:GetPVGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_PVGROUP)
end

function XArchiveModel:GetTag()
    return self._ConfigUtil:Get(TablePathTable.TABLE_TAG)
end

function XArchiveModel:GetArchive()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.Archive)
end

function XArchiveModel:GetMonster()
    return self._ConfigUtil:Get(TablePathTable.TABLE_MONSTER)
end

function XArchiveModel:GetMonsterInfo()
    return self._ConfigUtil:Get(TablePathTable.TABLE_MONSTERINFO)
end

function XArchiveModel:GetMonsterSkill()
    return self._ConfigUtil:Get(TablePathTable.TABLE_MONSTERSKILL)
end

function XArchiveModel:GetMonsterSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.MonsterSetting)
end

function XArchiveModel:GetSameNpcGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.SameNpcGroup)
end

function XArchiveModel:GetAwarenessSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.AwarenessSetting)
end

function XArchiveModel:GetWeaponSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.WeaponSetting)
end

function XArchiveModel:GetStoryGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYGROUP)
end

function XArchiveModel:GetStoryChapter()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYCHAPTER)
end

function XArchiveModel:GetStoryDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYDETAIL)
end

function XArchiveModel:GetStoryNpc()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYNPC)
end

function XArchiveModel:GetStoryNpcSetting()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYNPCSETTING)
end

function XArchiveModel:GetCGDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_CGDETAIL)
end

function XArchiveModel:GetCGGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_CGGROUP)
end

function XArchiveModel:GetArchiveMail()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.ArchiveMail)
end

function XArchiveModel:GetCommunication()
    return self._ConfigUtil:Get(TablePathTable.TABLE_COMMUNICATION)
end

function XArchiveModel:GetEventDateGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_EVENTDATEGROUP)
end

function XArchiveModel:GetPartnerSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.PartnerSetting)
end

function XArchiveModel:GetPVDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_PVDETAIL)
end

--endregion

--region 二次配置
function XArchiveModel:GetArchiveTagAllList()
    if XTool.IsTableEmpty(self._ArchiveTagAllList) then
        for _, tag in pairs(self:GetTag() or {}) do
            for _, groupId in pairs(tag.TagGroupId) do
                if not self._ArchiveTagAllList[groupId] then
                    self._ArchiveTagAllList[groupId] = {}
                end
                if tag.IsNotShow == 0 then
                    table.insert(self._ArchiveTagAllList[groupId], tag)
                end
            end
        end
        for _, v in pairs(self._ArchiveTagAllList) do
            self:SortByOrder(v)
        end
    end
    
    return self._ArchiveTagAllList
end

function XArchiveModel:GetSameNpc()
    if XTool.IsTableEmpty(self._ArchiveSameNpc) then
        for _, group in pairs(self:GetSameNpcGroup() or {}) do
            for _, npcId in pairs(group.NpcId) do
                self._ArchiveSameNpc[npcId] = group.Id
            end
        end
    end
    return self._ArchiveSameNpc
end

function XArchiveModel:GetArchiveMonsterTransDic()
    if XTool.IsTableEmpty(self._ArchiveMonsterTransDic) then
        for _, transData in pairs(self:GetMonsterModelTrans() or {}) do
            local archiveMonsterTransData = self._ArchiveMonsterTransDic[transData.NpcId]
            if not archiveMonsterTransData then
                archiveMonsterTransData = {}
                self._ArchiveMonsterTransDic[transData.NpcId] = archiveMonsterTransData
            end

            archiveMonsterTransData[transData.NpcState] = transData
        end
    end
    
    return self._ArchiveMonsterTransDic
end

function XArchiveModel:GetArchiveMonsterEffectDatasDic()
    if XTool.IsTableEmpty(self._ArchiveMonsterEffectDatasDic) then
        for _, transData in pairs(self:GetMonsterEffect() or {}) do
            local archiveMonsterEffectData = self._ArchiveMonsterEffectDatasDic[transData.NpcId]
            if not archiveMonsterEffectData then
                archiveMonsterEffectData = {}
                self._ArchiveMonsterEffectDatasDic[transData.NpcId] = archiveMonsterEffectData
            end

            local archiveMonsterEffect = archiveMonsterEffectData[transData.NpcState]
            if not archiveMonsterEffect then
                archiveMonsterEffect = {}
                archiveMonsterEffectData[transData.NpcState] = archiveMonsterEffect
            end
            archiveMonsterEffect[transData.EffectNodeName] = transData.EffectPath
        end
    end
    
    return self._ArchiveMonsterEffectDatasDic
end

function XArchiveModel:GetShowedWeaponTypeList()
    if XTool.IsTableEmpty(self._ShowedWeaponTypeList) then
        local weaponGroupData=self:GetArchiveWeaponGroup()
        for _, group in pairs(weaponGroupData) do
            table.insert(self._ShowedWeaponTypeList, group.Id)
        end

        table.sort(self._ShowedWeaponTypeList, function(aType, bType)
            local aData = weaponGroupData[aType]
            local bData = weaponGroupData[bType]
            return aData.Order < bData.Order
        end)
    end
    
    return self._ShowedWeaponTypeList
end

function XArchiveModel:GetWeaponTemplateIdToSettingListDic()
    if XTool.IsTableEmpty(self._WeaponTemplateIdToSettingListDic) then
        local equipId
        for _, settingData in pairs(self:GetWeaponSetting()) do
            equipId = settingData.EquipId
            self._WeaponTemplateIdToSettingListDic[equipId] = self._WeaponTemplateIdToSettingListDic[equipId] or {}
            table.insert(self._WeaponTemplateIdToSettingListDic[equipId], settingData)
        end
    end
    
    return self._WeaponTemplateIdToSettingListDic
end

function XArchiveModel:GetWeaponSumCollectNum()
    if not XTool.IsNumberValid(self._WeaponSumCollectNum) then
        self._WeaponSumCollectNum=0
        for _, _ in pairs(self:GetWeaponTemplateIdToSettingListDic()) do
            self._WeaponSumCollectNum = self._WeaponSumCollectNum + 1
        end
    end
    
    return self._WeaponSumCollectNum
end

function XArchiveModel:GetWeaponTypeToIdsDic()
    if XTool.IsTableEmpty(self._WeaponTypeToIdsDic) then
        for type, _ in pairs(self:GetArchiveWeaponGroup()) do
            self._WeaponTypeToIdsDic[type] = {}
        end

        local templateData
        local equipType
        for templateId, _ in pairs(self:GetWeaponTemplateIdToSettingListDic()) do 
            templateData = XEquipConfig.GetEquipCfg(templateId)
            equipType = templateData.Type
            if self._WeaponTypeToIdsDic[equipType] then
                table.insert(self._WeaponTypeToIdsDic[equipType], templateId)
            end
        end
    end
    
    return self._WeaponTypeToIdsDic
end

function XArchiveModel:GetAwarenessShowedStatusDic()
    if XTool.IsTableEmpty(self._AwarenessShowedStatusDic) then
        local templateIdList
        for suitId, _ in pairs(self:GetArchiveAwarenessGroup()) do
            templateIdList = XEquipConfig.GetEquipTemplateIdsListBySuitId(suitId)
            for _, templateId in ipairs(templateIdList) do
                self._AwarenessShowedStatusDic[templateId] = true
            end
        end
    end
    
    return self._AwarenessShowedStatusDic
end

function XArchiveModel:GetAwarenessSumCollectNum()
    if not XTool.IsNumberValid(self._AwarenessSumCollectNum) then
        for _, _ in pairs(self:GetAwarenessShowedStatusDic()) do
            self._AwarenessSumCollectNum = self._AwarenessSumCollectNum + 1
        end
    end
    
    return self._AwarenessSumCollectNum
end

function XArchiveModel:GetAwarenessTypeToGroupDatasDic()
    if XTool.IsTableEmpty(self._AwarenessTypeToGroupDatasDic) then
        for _, type in pairs(self:GetArchiveAwarenessGroupType()) do
            self._AwarenessTypeToGroupDatasDic[type.GroupId] = {}
        end

        local groupType
        for _, groupData in pairs(self:GetArchiveAwarenessGroup()) do
            groupType = groupData.Type
            if self._AwarenessTypeToGroupDatasDic[groupType] then
                table.insert(self._AwarenessTypeToGroupDatasDic[groupType], groupData)
            end
        end
    end
    
    return self._AwarenessTypeToGroupDatasDic
end

function XArchiveModel:GetAwarenessSuitIdToSettingListDic()
    if XTool.IsTableEmpty(self._AwarenessSuitIdToSettingListDic) then
        local suitId
        for _, settingData in pairs(self:GetAwarenessSetting()) do
            suitId = settingData.SuitId
            self._AwarenessSuitIdToSettingListDic[suitId] = self._AwarenessSuitIdToSettingListDic[suitId] or {}
            table.insert(self._AwarenessSuitIdToSettingListDic[suitId], settingData)
        end
    end
    
    return self._AwarenessSuitIdToSettingListDic
end

function XArchiveModel:GetArchiveStoryGroupAllList()
    if XTool.IsTableEmpty(self._ArchiveStoryGroupAllList) then
        for _, group in pairs(self:GetStoryGroup() or {}) do
            table.insert(self._ArchiveStoryGroupAllList, group)
        end
        self:SortByOrder(self._ArchiveStoryGroupAllList)
    end
    
    return self._ArchiveStoryGroupAllList
end


function XArchiveModel:GetArchiveMonsterList()
    if XTool.IsTableEmpty(self._ArchiveMonsterList) then
        PrivateFuncMap.InitArchiveMonsterList(self)
    end
    return self._ArchiveMonsterList
end

function XArchiveModel:GetArchiveMonsterInfoList()
    if XTool.IsTableEmpty(self._ArchiveMonsterInfoList) then
        PrivateFuncMap.InitArchiveMonsterDetail(self,XEnumConst.Archive.EntityType.Info,self:GetMonsterInfo(),self._ArchiveMonsterInfoList,true)
    end
    return self._ArchiveMonsterInfoList
end

function XArchiveModel:GetArchiveMonsterSkillList()
    if XTool.IsTableEmpty(self._ArchiveMonsterSkillList) then
        PrivateFuncMap.InitArchiveMonsterDetail(self,XEnumConst.Archive.EntityType.Skill,self:GetMonsterSkill(),self._ArchiveMonsterSkillList,false)
    end
    return self._ArchiveMonsterSkillList
end

function XArchiveModel:GetArchiveMonsterSettingList()
    if XTool.IsTableEmpty(self._ArchiveMonsterSettingList) then
        PrivateFuncMap.InitArchiveMonsterDetail(self,XEnumConst.Archive.EntityType.Setting,self:GetMonsterSetting(),self._ArchiveMonsterSettingList,true)
    end
    return self._ArchiveMonsterSettingList
end

function XArchiveModel:GetArchiveNpcToMonster()
    if XTool.IsTableEmpty(self._ArchiveNpcToMonster) then
        PrivateFuncMap.InitArchiveMonsterList(self)
    end
    return self._ArchiveNpcToMonster
end

function XArchiveModel:GetArchiveMonsterData()
    if XTool.IsTableEmpty(self._ArchiveMonsterData) then
        PrivateFuncMap.InitArchiveMonsterList(self)
    end
    return self._ArchiveMonsterData
end

function XArchiveModel:GetArchiveStoryChapterList()
    if XTool.IsTableEmpty(self._ArchiveStoryChapterList) then
        PrivateFuncMap.InitArchiveStoryChapterList(self)
    end
    return self._ArchiveStoryChapterList
end

function XArchiveModel:GetArchiveStoryChapterDic()
    if XTool.IsTableEmpty(self._ArchiveStoryChapterDic) then
        PrivateFuncMap.InitArchiveStoryChapterList(self)
    end
    return self._ArchiveStoryChapterDic
end

function XArchiveModel:GetArchiveStoryDetailList()
    if XTool.IsTableEmpty(self._ArchiveStoryDetailList) then
        PrivateFuncMap.InitArchiveStoryDetailAllList(self)
    end
    return self._ArchiveStoryDetailList
end

function XArchiveModel:GetArchiveStoryNpcList()
    if XTool.IsTableEmpty(self._ArchiveStoryNpcList) then
        PrivateFuncMap.InitArchiveStoryNpcAllList(self)
    end
    return self._ArchiveStoryNpcList
end

function XArchiveModel:GetArchiveStoryNpcSettingList()
    if XTool.IsTableEmpty(self._ArchiveStoryNpcSettingList) then
        PrivateFuncMap.InitArchiveStoryNpcSettingAllList(self)
    end
    return self._ArchiveStoryNpcSettingList
end

function XArchiveModel:GetArchiveCGDetailList()
    if XTool.IsTableEmpty(self._ArchiveCGDetailList) then
        PrivateFuncMap.InitArchiveCGAllList(self)
    end
    return self._ArchiveCGDetailList
end

function XArchiveModel:GetArchiveCGDetailData()
    if XTool.IsTableEmpty(self._ArchiveCGDetailData) then
        PrivateFuncMap.InitArchiveCGAllList(self)
    end
    return self._ArchiveCGDetailData
end

function XArchiveModel:GetArchiveMailList()
    if XTool.IsTableEmpty(self._ArchiveMailList) then
        PrivateFuncMap.InitArchiveMailList(self)
    end
    return self._ArchiveMailList
end

function XArchiveModel:GetArchiveCommunicationList()
    if XTool.IsTableEmpty(self._ArchiveCommunicationList) then
        PrivateFuncMap.InitArchiveCommunicationList(self)
    end
    return self._ArchiveCommunicationList
end

function XArchiveModel:GetArchivePartnerList()
    if XTool.IsTableEmpty(self._ArchivePartnerList) then
        PrivateFuncMap.InitArchivePartnerList(self)
    end
    return self._ArchivePartnerList
end

function XArchiveModel:GetArchivePartnerSettingList()
    if XTool.IsTableEmpty(self._ArchivePartnerSettingList) then
        PrivateFuncMap.InitArchivePartnerSetting(self)
    end
    return self._ArchivePartnerSettingList
end
--endregion
----------config end----------


return XArchiveModel