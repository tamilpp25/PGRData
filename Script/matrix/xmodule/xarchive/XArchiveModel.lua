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
    self:ResetMonsterData()
end

--region ----------public start----------
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

function XArchiveModel:ClearMonsterRedPointDic(monsterType,monsterId,type)
    if not self._MonsterRedPointDic[monsterType] then return end
    if not self._MonsterRedPointDic[monsterType][monsterId] then return end
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = false
    end
    if not self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill and
            not self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting then

        self._MonsterRedPointDic[monsterType][monsterId] = nil
    end
end

function XArchiveModel:GetCGRedPointSaveKey(id)
    return string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)
end

function XArchiveModel:GetWeaponsCollectionSaveKey(type)
    return string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type)
end

--------------------怪物图鉴-------------------->>>
--region getter
function XArchiveModel:GetArchiveMonsterEvaluate(npcId)
    return self._ArchiveMonsterEvaluateList[npcId]
end

function XArchiveModel:GetArchiveMonsterMySelfEvaluate(npcId)
    return self._ArchiveMonsterMySelfEvaluateList[npcId]
end

function XArchiveModel:GetArchiveMonsterEvaluateList()
    return self._ArchiveMonsterEvaluateList
end

function XArchiveModel:GetArchiveMonsterMySelfEvaluateList()
    return self._ArchiveMonsterMySelfEvaluateList
end

--批量未解锁怪物id数据获取整体逻辑在Model，减少方法调用次数
function XArchiveModel:GetLockMonsterIdsFromIdList(ids)
    local list={}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
    end
    return list
end

--批量未解锁怪物信息id数据获取整体逻辑在Model，减少方法调用次数
function XArchiveModel:GetLockMonsterInfoIdsFromIdList(ids)
    local list={}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterInfoUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
    end
    return list
end

function XArchiveModel:GetLockMonsterSkillIdsFromIdList(ids)
    local list = {}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterSkillUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
    end
    return list
end

function XArchiveModel:GetLockMonsterSettingIdsFromIdList(ids)
    local list = {}
    if not XTool.IsTableEmpty(ids) then
        for _,id in pairs(ids) do
            if not self._ArchiveMonsterSettingUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
    end
    return list
end

function XArchiveModel:GetShowedMonsterList()
    return self._ArchiveShowedMonsterList
end

function XArchiveModel:GetMonsterRedPointDic()
    return self._MonsterRedPointDic
end

function XArchiveModel:GetMonsterRedPointDicByType(type)
    if self._MonsterRedPointDic[type] then
        return self._MonsterRedPointDic[type]
    end
end

function XArchiveModel:GetMonsterUnlockById(id)
    return self._ArchiveMonsterUnlockIdsList[id]
end

function XArchiveModel:GetLastSyncMonsterEvaluateTimeById(monsterId)
    return self._LastSyncMonsterEvaluateTimes[monsterId]
end
--endregion

--region setter
function XArchiveModel:ResetMonsterData()
    local monsterData = self:GetArchiveMonsterData()
    if not XTool.IsTableEmpty(monsterData) then
        for i, v in pairs(monsterData) do
            v:Reset()
        end
    end
end

function XArchiveModel:SetArchiveMonsterMySelfEvaluateLikeStatus(npcId,likeState)
    if not self._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._ArchiveMonsterMySelfEvaluateList[npcId].LikeStatus = likeState
end

function XArchiveModel:SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
    if not self._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._ArchiveMonsterMySelfEvaluateList[npcId].Score = score
    self._ArchiveMonsterMySelfEvaluateList[npcId].Difficulty = difficulty
    self._ArchiveMonsterMySelfEvaluateList[npcId].Tags = tags
end

function XArchiveModel:SetMonsterRedPointDic(monsterId,type,id)
    local monsterType = self:GetArchiveMonsterData()[monsterId] and self:GetArchiveMonsterData()[monsterId]:GetType() or nil
    if not monsterType then return end
    if not self._MonsterRedPointDic[monsterType] then
        self._MonsterRedPointDic[monsterType] = {}
    end
    if not self._MonsterRedPointDic[monsterType][monsterId] then
        self._MonsterRedPointDic[monsterType][monsterId] = {}
    end
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        if not self._ArchiveMonsterUnlockIdsList[monsterId] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        if not self._ArchiveMonsterInfoUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        if not self._ArchiveMonsterSkillUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        if not self._ArchiveMonsterSettingUnlockIdsList[id] then
            self._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = true
        end
    end

end

function XArchiveModel:SetArchiveShowedMonsterList(list)
    if not XTool.IsTableEmpty(list) then
        for _,monster in pairs(list) do
            self._ArchiveShowedMonsterList[monster.Id] = monster
        end
    end
end

function XArchiveModel:AddArchiveShowedMonsterList(list)
    if not XTool.IsTableEmpty(list) then
        for _,monster in pairs(list) do
            if not self._ArchiveShowedMonsterList[monster] then
                self._ArchiveShowedMonsterList[monster.Id] = monster
            else
                self._ArchiveShowedMonsterList[monster.Id].Killed = monster.Killed
            end
        end
    end
end

function XArchiveModel:SetArchiveMonsterUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterUnlockIdsList[id] = true
    end
end

function XArchiveModel:SetArchiveMonsterInfoUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterInfoUnlockIdsList[id] = true
    end
end

function XArchiveModel:SetArchiveMonsterSkillUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterSkillUnlockIdsList[id] = true
    end
end

function XArchiveModel:SetArchiveMonsterSettingUnlockIdsList(list)
    for _,id in pairs(list) do
        self._ArchiveMonsterSettingUnlockIdsList[id] = true
    end
end

function XArchiveModel:SetMonsterEvaluateInListById(id,entity)
    self._ArchiveMonsterEvaluateList[id] = entity
end

function XArchiveModel:SetMonsterMySelfEvaluateInListById(id,entity)
    self._ArchiveMonsterMySelfEvaluateList[id] = entity
end

function XArchiveModel:SetLastSyncMonsterEvaluateTimeById(monsterId,timestamp)
    self._LastSyncMonsterEvaluateTimes[monsterId] = timestamp
end

function XArchiveModel:ResetMonsterRedPointDic()
    self._MonsterRedPointDic = {}
end
--endregion

---------------------武器、意识------------------>>>
--region getter
function XArchiveModel:GetArchiveWeaponServerData()
    return self._ArchiveWeaponServerData
end

function XArchiveModel:GetArchiveWeaponServerDataById(templateId)
    return self._ArchiveWeaponServerData[templateId]
end

function XArchiveModel:GetWeaponRedPointCountByType(type)
    if self._ArchiveWeaponRedPointCountDic[type] then
        return self._ArchiveWeaponRedPointCountDic[type]
    else
        return 0
    end
end

function XArchiveModel:GetWeaponSettingUnlockServerDataById(settingId)
    return self._ArchiveWeaponSettingUnlockServerData[settingId] or false
end

function XArchiveModel:GetWeaponSettingCanUnlockDic()
    return self._ArchiveWeaponSettingCanUnlockDic
end

function XArchiveModel:GetWeaponSettingCanUnlockById(settingId)
    return self._ArchiveWeaponSettingCanUnlockDic[settingId] or false
end

function XArchiveModel:GetNewWeaponSettingIdListById(templateId)
    if self._ArchiveNewWeaponSettingIdsDic[templateId] then
        return self._ArchiveNewWeaponSettingIdsDic[templateId]
    end
end

function XArchiveModel:GetNewWeaponSettingByWeaponType(type)
    return self._ArchiveWeaponSettingRedPointCountDic[type] or 0
end

function XArchiveModel:GetAwarenessServerData()
    return self._ArchiveAwarenessServerData
end

function XArchiveModel:GetNewAwarenessSuitByGetType(type)
    return self._ArchiveAwarenessSuitRedPointCountDic[type] or 0
end

function XArchiveModel:GetAwarenessSettingUnlockServerDataById(settingId)
    return self._ArchiveAwarenessSettingUnlockServerData[settingId] or false
end

function XArchiveModel:GetAwarenessSettingCanUnlockById(settingId)
    return self._ArchiveAwarenessSettingCanUnlockDic[settingId] or false
end

function XArchiveModel:GetAwarenessSettingCanUnlockDic()
    return self._ArchiveAwarenessSettingCanUnlockDic
end

function XArchiveModel:GetNewAwarenessSettingIdListById(suitId)
    return self._ArchiveNewAwarenessSettingIdsDic[suitId]
end

function XArchiveModel:GetNewAwarenessSettingByGetType(type)
    return self._ArchiveAwarenessSettingRedPointCountDic[type] or 0
end

function XArchiveModel:GetWeaponTotalRedPointCount()
    return self._ArchiveWeaponTotalRedPointCount
end

function XArchiveModel:GetAwarenessSuitTotalRedPointCount()
    return self._ArchiveAwarenessSuitTotalRedPointCount
end

function XArchiveModel:GetWeaponSettingTotalRedPointCount()
    return self._ArchiveWeaponSettingTotalRedPointCount
end

function XArchiveModel:GetAwarenessSettingTotalRedPointCount()
    return self._ArchiveAwarenessSettingTotalRedPointCount
end

function XArchiveModel:GetAwarenessSuitToAwarenessCountDic()
    return self._ArchiveAwarenessSuitToAwarenessCountDic
end

function XArchiveModel:GetAwarenessSuitToAwarenessCountById(suitId)
    return self._ArchiveAwarenessSuitToAwarenessCountDic[suitId]
end

function XArchiveModel:GetAwarenessServerDataById(templateId)
    return self._ArchiveAwarenessServerData[templateId]
end

function XArchiveModel:GetAwarenessSuitUnlockServerDataById(suitId)
    return self._ArchiveAwarenessSuitUnlockServerData[suitId]
end

function XArchiveModel:GetWeaponUnlockServerData(templateId)
    return self._ArchiveWeaponUnlockServerData[templateId]
end
--endregion

--region setter
function XArchiveModel:SetWeaponTotalRedPointCount(count)
    self._ArchiveWeaponTotalRedPointCount = count
end

function XArchiveModel:AddWeaponTotalRedPointCount(adds)
    self._ArchiveWeaponTotalRedPointCount = self._ArchiveWeaponTotalRedPointCount+adds
end

function XArchiveModel:SetWeaponRedPointCountByType(weaponType,count)
    self._ArchiveWeaponRedPointCountDic[weaponType] = count
end

function XArchiveModel:AddWeaponRedPointCountByType(weaponType,adds)
    if type(self._ArchiveWeaponRedPointCountDic[weaponType])~='number' then
        self._ArchiveWeaponRedPointCountDic[weaponType]=0
    end
    self._ArchiveWeaponRedPointCountDic[weaponType] = self._ArchiveWeaponRedPointCountDic[weaponType]+adds
end

function XArchiveModel:SetWeaponUnlockServerDataById(id,data)
    self._ArchiveWeaponUnlockServerData[id] = data
end

function XArchiveModel:SetWeaponSettingTotalRedPointCount(count)
    self._ArchiveWeaponSettingTotalRedPointCount = count
end

function XArchiveModel:AddWeaponSettingTotalRedPointCount(adds)
    self._ArchiveWeaponSettingTotalRedPointCount = self._ArchiveWeaponSettingTotalRedPointCount+adds
end

function XArchiveModel:SetNewWeaponSettingIdsDicById(templateId,data)
    self._ArchiveNewWeaponSettingIdsDic[templateId] = data
end

function XArchiveModel:InsertNewWeaponSettingIdsDicById(templateId,data)
    if not self._ArchiveNewWeaponSettingIdsDic[templateId] then
        self._ArchiveNewWeaponSettingIdsDic[templateId]={}
    end
    table.insert(self._ArchiveNewWeaponSettingIdsDic[templateId],data)
end

function XArchiveModel:InsertNewAwarenessSettingIdById(tmpSuitId,settingId)
    if not self._ArchiveNewAwarenessSettingIdsDic[tmpSuitId] then
        self._ArchiveNewAwarenessSettingIdsDic[tmpSuitId] = {}
    end
    table.insert(self._ArchiveNewAwarenessSettingIdsDic[tmpSuitId], settingId)
end

function XArchiveModel:SetWeaponSettingRedPointCountByType(weaponType,count)
    self._ArchiveWeaponSettingRedPointCountDic[weaponType] = count
end

function XArchiveModel:AddWeaponSettingRedPointCountByType(weaponType,adds)
    if type(self._ArchiveWeaponSettingRedPointCountDic[weaponType])~='number' then
        self._ArchiveWeaponSettingRedPointCountDic[weaponType]=0
    end
    self._ArchiveWeaponSettingRedPointCountDic[weaponType] = self._ArchiveWeaponSettingRedPointCountDic[weaponType]+adds
end

function XArchiveModel:SetWeaponSettingCanUnlockById(id,canUnLock)
    self._ArchiveWeaponSettingCanUnlockDic[id] = canUnLock
end

function XArchiveModel:SetWeaponSettingUnlockServerDataById(id,unLock)
    self._ArchiveWeaponSettingUnlockServerData[id] = unLock
end

function XArchiveModel:SetAwarenessSettingTotalRedPointCount(count)
    self._ArchiveAwarenessSettingTotalRedPointCount = count
end

function XArchiveModel:AddAwarenessSettingTotalRedPointCount(adds)
    self._ArchiveAwarenessSettingTotalRedPointCount = self._ArchiveAwarenessSettingTotalRedPointCount+adds
end

function XArchiveModel:SetAwarenessSettingRedPointCountDicByType(type,count)
    self._ArchiveAwarenessSettingRedPointCountDic[type] = count
end

function XArchiveModel:AddAwarenessSettingRedPointCountDicByType(_type,adds)
    if type(self._ArchiveAwarenessSettingRedPointCountDic[_type])~='number' then
        self._ArchiveAwarenessSettingRedPointCountDic[_type]=0
    end
    self._ArchiveAwarenessSettingRedPointCountDic[_type] = self._ArchiveAwarenessSettingRedPointCountDic[_type]+adds
end

function XArchiveModel:SetAwarenessSettingUnlockServerData(id,unLock)
    self._ArchiveAwarenessSettingUnlockServerData[id] = unLock
end

function XArchiveModel:SetAwarenessSettingCanUnlockDicById(id,canUnLock)
    self._ArchiveAwarenessSettingCanUnlockDic[id] = canUnLock
end

function XArchiveModel:SetNewAwarenessSettingIdsDicBySuitId(suitId,data)
    self._ArchiveNewAwarenessSettingIdsDic[suitId] = data
end

function XArchiveModel:SetAwarenessSuitTotalRedPointCount(count)
    self._ArchiveAwarenessSuitTotalRedPointCount = count
end

function XArchiveModel:AddAwarenessSuitTotalRedPointCount(adds)
    self._ArchiveAwarenessSuitTotalRedPointCount = self._ArchiveAwarenessSuitTotalRedPointCount+adds
end

function XArchiveModel:SetAwarenessSuitRedPointCountByType(awarenessGetType,count)
    self._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = count
end

function XArchiveModel:AddAwarenessSuitRedPointCountByType(awarenessGetType,adds)
    if type(self._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType])~='number' then
        self._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType]=0
    end
    self._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = self._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType]+adds
end

function XArchiveModel:SetAwarenessSuitUnlockServerDataById(id,data)
    self._ArchiveAwarenessSuitUnlockServerData[id] = data
end

function XArchiveModel:SetWeaponServerDataById(templateId,data)
    self._ArchiveWeaponServerData[templateId] = data
end

function XArchiveModel:UpdateWeaponUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveWeaponUnlockServerData[id] = true
    end
end

function XArchiveModel:UpdateAwarenessSuitUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveAwarenessSuitUnlockServerData[id] = true
    end
end

function XArchiveModel:UpdateWeaponSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveWeaponSettingUnlockServerData[id] = true
    end
end

function XArchiveModel:UpdateAwarenessSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveAwarenessSettingUnlockServerData[id] = true
    end
end

function XArchiveModel:ClearAwarenessSuitToAwarenessCountDic()
    self._ArchiveAwarenessSuitToAwarenessCountDic = {}
end

function XArchiveModel:SetAwarenessServerDataById(templateId,data)
    self._ArchiveAwarenessServerData[templateId] = data
end

function XArchiveModel:AddAwarenessSuitToAwarenessCountById(suitId,adds)
    if type(self._ArchiveAwarenessSuitToAwarenessCountDic[suitId])~='number' then
        self._ArchiveAwarenessSuitToAwarenessCountDic[suitId]=0
    end
    self._ArchiveAwarenessSuitToAwarenessCountDic[suitId] = self._ArchiveAwarenessSuitToAwarenessCountDic[suitId] + adds
end
--endregion
---------------------伙伴图鉴------------------>>>
--region getter
function XArchiveModel:GetPartnerListByGroup(group)
    if self._ArchivePartnerList[group] then
        return self._ArchivePartnerList[group]
    end
    return {}
end

function XArchiveModel:GetPartnerUnLockById(id)
    return self._PartnerUnLockDic[id]
end

function XArchiveModel:GetPartnerUnLockSettingDic()
    return self._PartnerUnLockSettingDic
end
--endregion

--region setter
function XArchiveModel:UpdateUnLockPartnerDic(dataList)
    for _,data in pairs(dataList) do
        if not self._PartnerUnLockDic[data] then
            self._PartnerUnLockDic[data] = data
        end
    end
end

function XArchiveModel:UpdateUnLockPartnerSettingDic(dataList)
    for _,data in pairs(dataList) do
        if not self._PartnerUnLockSettingDic[data] then
            self._PartnerUnLockSettingDic[data] = data
        end
    end
end
--endregion
---------------------剧情相关------------------>>>
--region getter
function XArchiveModel:GetShowedStoryListById(id)
    if self._ArchiveShowedStoryList[id] then
        return self._ArchiveShowedStoryList[id]
    end
end
--endregion

--region setter
function XArchiveModel:SetArchiveShowedStoryList(idList)
    if not XTool.IsTableEmpty(idList) then
        for _,id in pairs(idList) do
            self._ArchiveShowedStoryList[id] = id
        end
    end
end
--endregion
---------------------PV相关------------------>>>
--region getter
function XArchiveModel:GetUnlockPvDetailsById(pvDetailId)
    return self._UnlockPvDetails[pvDetailId]
end
--endregion

--region setter
function XArchiveModel:SetUnlockPvDetails(idList)
    if type(idList) ~= "table" then
        self._UnlockPvDetails[idList] = idList
        return
    end

    for _, id in pairs(idList) do
        self._UnlockPvDetails[id] = id
    end
end
--endregion
---------------------CG相关------------------>>>
--region getter
function XArchiveModel:GetShowedCGListById(CGId)
    return self._ArchiveShowedCGList[CGId]
end
--endregion

--region setter
function XArchiveModel:SetArchiveShowedCGList(idList)
    if not XTool.IsTableEmpty(idList) then
        for _,id in pairs(idList) do
            self._ArchiveShowedCGList[id] = id
        end
    end
end
--endregion
---------------------邮件相关----------------->>>
--region getter
function XArchiveModel:GetUnlockArchiveMailById(archiveMailId)
    return self._UnlockArchiveMails[archiveMailId] and true or false
end
--endregion

--region setter
function XArchiveModel:UpdateUnLockArchiveMailDict(dataList)
    if not XTool.IsTableEmpty(dataList) then
        for _, archiveMailId in pairs(dataList) do
            self._UnlockArchiveMails[archiveMailId] = true
        end
    end
end
--endregion

--endregion ----------public end----------

--region ----------private start----------

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
    local monsterList=model:GetMonster()

    if not XTool.IsTableEmpty(monsterList) then
        for _, monster in pairs(monsterList) do
            if not model._ArchiveMonsterList[monster.Type] then
                model._ArchiveMonsterList[monster.Type] = {}
            end
            local tmp = XArchiveMonsterEntity.New(monster.Id)

            if not XTool.IsTableEmpty(monster.NpcId) then
                for _,id in pairs(monster.NpcId)do
                    model._ArchiveNpcToMonster[id] = monster.Id
                end
            end
            tableInsert(model._ArchiveMonsterList[monster.Type], tmp)
        end
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

    if not XTool.IsTableEmpty(detailCfg) then
        for _, detail in pairs(detailCfg) do

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
    local storyChapters = model:GetStoryChapter()
    if not XTool.IsTableEmpty(storyChapters) then
        for _, chapter in pairs(storyChapters) do

            if not model._ArchiveStoryChapterList[chapter.GroupId] then
                model._ArchiveStoryChapterList[chapter.GroupId] = {}
            end

            local tmp = XArchiveStoryChapterEntity.New(chapter.Id)
            table.insert(model._ArchiveStoryChapterList[chapter.GroupId], tmp)

            model._ArchiveStoryChapterDic[chapter.Id] = tmp
        end
    end
    for _,group in pairs(model._ArchiveStoryChapterList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchiveStoryDetailAllList=function(model)
    local XArchiveStoryDetailEntity = require("XEntity/XArchive/XArchiveStoryDetailEntity")
    local storyDetails = model:GetStoryDetail()
    if not XTool.IsTableEmpty(storyDetails) then
        for _, detail in pairs(storyDetails) do

            if not model._ArchiveStoryDetailList[detail.ChapterId] then
                model._ArchiveStoryDetailList[detail.ChapterId] = {}
            end

            local tmp = XArchiveStoryDetailEntity.New(detail.Id)
            table.insert(model._ArchiveStoryDetailList[detail.ChapterId], tmp)
        end
    end
    for _,group in pairs(model._ArchiveStoryDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴Npc数据
PrivateFuncMap.InitArchiveStoryNpcAllList=function(model)
    local XArchiveNpcEntity = require("XEntity/XArchive/XArchiveNpcEntity")
    local storyNpcs = model:GetStoryNpc()
    if not XTool.IsTableEmpty(storyNpcs) then
        for _, npcCfg in pairs(storyNpcs) do

            local tmp = XArchiveNpcEntity.New(npcCfg.Id)
            table.insert(model._ArchiveStoryNpcList, tmp)
        end
    end
    model:SortByOrder(model._ArchiveStoryNpcList)
end

--创建图鉴NpcSetting数据
PrivateFuncMap.InitArchiveStoryNpcSettingAllList=function(model)
    local XArchiveNpcDetailEntity = require("XEntity/XArchive/XArchiveNpcDetailEntity")
    local storyNpcSettings = model:GetStoryNpcSetting()
    if not XTool.IsTableEmpty(storyNpcSettings) then
        for _, settingCfg in pairs(storyNpcSettings) do

            if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId] then
                model._ArchiveStoryNpcSettingList[settingCfg.GroupId] = {}
            end

            if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] then
                model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] = {}
            end

            local tmp = XArchiveNpcDetailEntity.New(settingCfg.Id)
            table.insert(model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type], tmp)
        end
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
    local cgDetails = model:GetCGDetail()
    if not XTool.IsTableEmpty(cgDetails) then
        for _, CGDetailCfg in pairs(cgDetails) do

            if not model._ArchiveCGDetailList[CGDetailCfg.GroupId] then
                model._ArchiveCGDetailList[CGDetailCfg.GroupId] = {}
            end

            local tmp = XArchiveCGEntity.New(CGDetailCfg.Id)
            table.insert(model._ArchiveCGDetailList[CGDetailCfg.GroupId], tmp)
            model._ArchiveCGDetailData[CGDetailCfg.Id] = tmp
        end
    end
    for _,group in pairs(model._ArchiveCGDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴邮件数据
PrivateFuncMap.InitArchiveMailList=function(model)
    local XArchiveMailEntity = require("XEntity/XArchive/XArchiveMailEntity")
    local archiveMails = model:GetArchiveMail()
    if not XTool.IsTableEmpty(archiveMails) then
        for _, mailCfg in pairs(archiveMails) do
            if not model._ArchiveMailList[mailCfg.GroupId] then
                model._ArchiveMailList[mailCfg.GroupId] = {}
            end
            local tmp = XArchiveMailEntity.New(mailCfg.Id)
            table.insert(model._ArchiveMailList[mailCfg.GroupId], tmp)
        end
    end
    for _,group in pairs(model._ArchiveMailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴通讯数据
PrivateFuncMap.InitArchiveCommunicationList=function(model)
    local XArchiveCommunicationEntity = require("XEntity/XArchive/XArchiveCommunicationEntity")
    local communications = model:GetCommunication()
    if not XTool.IsTableEmpty(communications) then
        for _, communicationCfg in pairs(communications) do

            if not model._ArchiveCommunicationList[communicationCfg.GroupId] then
                model._ArchiveCommunicationList[communicationCfg.GroupId] = {}
            end

            local tmp = XArchiveCommunicationEntity.New(communicationCfg.Id)
            table.insert(model._ArchiveCommunicationList[communicationCfg.GroupId], tmp)
        end
    end
    for _,group in pairs(model._ArchiveCommunicationList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchivePartnerSetting=function(model)
    local XArchivePartnerSettingEntity = require("XEntity/XArchive/XArchivePartnerSettingEntity")
    local detailCfg = model:GetPartnerSetting()
    if not XTool.IsTableEmpty(detailCfg) then
        for _, detail in pairs(detailCfg) do

            if not model._ArchivePartnerSettingList[detail.GroupId] then
                model._ArchivePartnerSettingList[detail.GroupId] = {}
            end

            if not model._ArchivePartnerSettingList[detail.GroupId][detail.Type] then
                model._ArchivePartnerSettingList[detail.GroupId][detail.Type] = {}
            end

            local tmp = XArchivePartnerSettingEntity.New(detail.Id)
            table.insert(model._ArchivePartnerSettingList[detail.GroupId][detail.Type], tmp)
        end
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
    if not XTool.IsTableEmpty(templateList) then
        for _,template in pairs(templateList) do
            if not model._ArchivePartnerList[template.GroupId] then
                model._ArchivePartnerList[template.GroupId] = {}
            end
            local entity = XArchivePartnerEntity.New(template.Id,
                    model:GetArchivePartnerSetting(template.Id,XEnumConst.Archive.PartnerSettingType.Story),
                    model:GetArchivePartnerSetting(template.Id,XEnumConst.Archive.PartnerSettingType.Setting))
            table.insert(model._ArchivePartnerList[template.GroupId],entity)
        end
    end
    for _,group in pairs(model._ArchivePartnerList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitPVDetail = function(model)
    if model._IsInitPVDetail then
        return
    end

    for id, v in pairs(model:GetPVDetail()) do
        if not model._PVGroupIdToDetailIdList[v.GroupId] then
            model._PVGroupIdToDetailIdList[v.GroupId] = {}
        end
        table.insert(model._PVGroupIdToDetailIdList[v.GroupId], id)
        table.insert(model._PVDetailIdList, id)
    end
    for _, idList in pairs(model._PVGroupIdToDetailIdList) do
        table.sort(idList, function(a, b)
            return a < b
        end)
    end

    model._IsInitPVDetail = true
end
--endregion ----------private end----------

--region ----------config start----------
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

function XArchiveModel:GetPVDetailById(id)
    if not self:GetPVDetail()[id] then
        XLog.Error("Id is not exist in Share/Archive/PVDetail.tab id = " .. id)
        return
    end
    return self:GetPVDetail()[id]
end

--endregion

--region 二次配置
function XArchiveModel:GetArchiveTagAllList()
    if XTool.IsTableEmpty(self._ArchiveTagAllList) then
        local tags = self:GetTag()
        if not XTool.IsTableEmpty(tags) then
            for _, tag in pairs(tags) do
                for _, groupId in pairs(tag.TagGroupId) do
                    if not self._ArchiveTagAllList[groupId] then
                        self._ArchiveTagAllList[groupId] = {}
                    end
                    if tag.IsNotShow == 0 then
                        table.insert(self._ArchiveTagAllList[groupId], tag)
                    end
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
        local sameNpcGroup = self:GetSameNpcGroup()
        if not XTool.IsTableEmpty(sameNpcGroup) then
            for _, group in pairs(sameNpcGroup) do
                for _, npcId in pairs(group.NpcId) do
                    self._ArchiveSameNpc[npcId] = group.Id
                end
            end
        end
    end
    return self._ArchiveSameNpc
end

function XArchiveModel:GetArchiveMonsterTransDic()
    if XTool.IsTableEmpty(self._ArchiveMonsterTransDic) then
        local monsterModelTrans = self:GetMonsterModelTrans()
        if not XTool.IsTableEmpty(monsterModelTrans) then
            for _, transData in pairs(monsterModelTrans) do
                local archiveMonsterTransData = self._ArchiveMonsterTransDic[transData.NpcId]
                if not archiveMonsterTransData then
                    archiveMonsterTransData = {}
                    self._ArchiveMonsterTransDic[transData.NpcId] = archiveMonsterTransData
                end

                archiveMonsterTransData[transData.NpcState] = transData
            end
        end
    end
    
    return self._ArchiveMonsterTransDic
end

function XArchiveModel:GetArchiveMonsterEffectDatasDic()
    if XTool.IsTableEmpty(self._ArchiveMonsterEffectDatasDic) then
        local monsterEffects = self:GetMonsterEffect()
        if not XTool.IsTableEmpty(monsterEffects) then
            for _, transData in pairs(monsterEffects) do
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
        local storyGroup = self:GetStoryGroup()
        if not XTool.IsTableEmpty(storyGroup) then
            for _, group in pairs(storyGroup) do
                table.insert(self._ArchiveStoryGroupAllList, group)
            end
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

function XArchiveModel:GetPVDetailIdList(groupId)
    PrivateFuncMap.InitPVDetail(self)
    return groupId and self._PVGroupIdToDetailIdList[groupId] or self._PVDetailIdList
end
--endregion
--endregion ----------config end----------


return XArchiveModel