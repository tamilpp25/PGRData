---@class XArchiveAgency : XAgency
---@field private _Model XArchiveModel
local XArchiveAgency = XClass(XAgency, "XArchiveAgency")
local tableInsert=table.insert
local tableSort = table.sort

function XArchiveAgency:OnInit()
    --初始化一些变量
end

function XArchiveAgency:InitRpc()
    XRpc.NotifyArchiveLoginData = function(data)
        self:SetArchiveShowedMonsterList(data.Monsters)
        self:SetArchiveMonsterSettingUnlockIdsList(data.MonsterSettings)
        self:SetArchiveMonsterUnlockIdsList(data.MonsterUnlockIds)
        self:SetArchiveMonsterInfoUnlockIdsList(data.MonsterInfos)
        self:SetArchiveMonsterSkillUnlockIdsList(data.MonsterSkills)
        self:SetEquipServerData(data.Equips)
        --self:CheckSpecialEquip()

        self:SetArchiveShowedCGList(data.UnlockCgs)
        self:SetArchiveShowedStoryList(data.UnlockStoryDetails)--只保存通关的活动剧情ID，到了解禁事件后会被清除
        self:SetUnlockPvDetails(data.UnlockPvDetails)

        self:UpdateWeaponUnlockServerData(data.WeaponUnlockIds)
        self:UpdateAwarenessSuitUnlockServerData(data.AwarenessUnlockIds)
        self:UpdateWeaponSettingUnlockServerData(data.WeaponSettings)
        self:UpdateAwarenessSettingUnlockServerData(data.AwarenessSettings)
        self:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self:UpdateUnLockArchiveMailDict(data.UnlockMails)

        self:UpdateMonsterData()
        self:UpdateCGAllList()
        self:CreateRedPointCountDic()

        XDataCenter.PartnerManager.UpdateAllPartnerStory()
        self:UpdateArchivePartnerList()
        self:UpdateArchivePartnerSettingList()
    end

    XRpc.NotifyArchiveMonsterRecord = function(data)
        self:AddArchiveShowedMonsterList(data.Monsters)
        self:UpdateMonsterData()
    end

    XRpc.NotifyArchiveCgs = function(data)
        self:SetArchiveShowedCGList(data.UnlockCgs)
        self:UpdateCGAllList()
        self:AddNewCGRedPoint(data.UnlockCgs)
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_CG)
    end

    XRpc.NotifyArchivePvDetails = function(data)
        self:SetUnlockPvDetails(data.UnlockPvDetails) --这的UnlockPvDetails是个int
    end
    -----------------武器、意识相关------------------->>>
    XRpc.NotifyArchiveEquip = function(data)
        self:UpdateEquipServerData(data.Equips)
    end

    -----------------武器、意识相关-------------------<<<
    -----------------剧情相关------------------->>>
    XRpc.NotifyArchiveStoryDetails = function(data)
        self:SetArchiveShowedStoryList(data.UnlockStoryDetails)
    end
    -----------------剧情相关-------------------<<<

    -----------------伙伴相关------------------->>>

    XRpc.NotifyArchivePartners = function(data)
        self:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self:UpdateArchivePartnerList()
    end

    XRpc.NotifyPartnerSettings = function(data)
        self:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self:UpdateArchivePartnerSettingList()
        XDataCenter.PartnerManager.UpdateAllPartnerStory()
    end
    -----------------伙伴相关-------------------<<<

    --region   ------------------邮件相关 start-------------------
    XRpc.NotifyArchiveMail = function(data)
        local id = data.UnlockArchiveMailId
        if XTool.IsNumberValid(id) then
            self:UpdateUnLockArchiveMailDict({ id })
        end
    end
    --endregion------------------邮件相关 finish------------------
end

function XArchiveAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
--region --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>
function XArchiveAgency:GetArchiveMonsterType(monsterId)
    return self._Model:GetArchiveMonsterData()[monsterId] and self._Model:GetArchiveMonsterData()[monsterId]:GetType() or nil
end

function XArchiveAgency:GetArchiveMonsterEntityByNpcId(npcId)
    local monsterId = self:GetMonsterIdByNpcId(npcId)
    if monsterId == nil then
        XLog.Error(string.format("npcId:%s没有在Share/Archive/Monster.tab或SameNpcGroup.tab配置", npcId))
        return nil
    end
    return self._Model:GetArchiveMonsterData()[monsterId]
end

function XArchiveAgency:GetMonsterKillCount(npcId)
    local sameNpcId = self:GetSameNpcId(npcId)
    local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
    if not monsterId then return 0 end
    local killCount = self._Model:GetArchiveMonsterData()[monsterId].Kill[sameNpcId]
    return killCount and killCount or 0
end

function XArchiveAgency:IsMonsterHaveRedPointByAll()
    local IsHaveRedPoint = false
    for type,_ in pairs(self._Model._MonsterRedPointDic or {}) do
        if self:IsMonsterHaveRedPointByType(type) then
            IsHaveRedPoint = true
            break
        end
        if self:IsMonsterHaveNewTagByType(type) then
            IsHaveRedPoint = true
            break
        end
    end
    return IsHaveRedPoint
end

function XArchiveAgency:IsMonsterHaveNewTagByType(type)
    local IsHaveNewTag = false
    for monsterId,_ in pairs(self._Model._MonsterRedPointDic[type] or {}) do
        if self:IsMonsterHaveNewTagById(monsterId) then
            IsHaveNewTag = true
            break
        end
    end
    return IsHaveNewTag
end

function XArchiveAgency:IsMonsterHaveRedPointByType(type)
    local IsHaveRedPoint = false
    for monsterId,_ in pairs(self._Model._MonsterRedPointDic[type] or {}) do
        if self:IsMonsterHaveRedPointById(monsterId) then
            IsHaveRedPoint = true
            break
        end
    end
    return IsHaveRedPoint
end

function XArchiveAgency:IsMonsterHaveNewTagById(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    return monsterType and self._Model._MonsterRedPointDic[monsterType] and
            self._Model._MonsterRedPointDic[monsterType][monsterId] and
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewMonster or false
end

function XArchiveAgency:IsMonsterHaveRedPointById(monsterId)
    return self:IsHaveNewMonsterInfoByNpcId(monsterId) or
            self:IsHaveNewMonsterSkillByNpcId(monsterId) or
            self:IsHaveNewMonsterSettingByNpcId(monsterId)
end

function XArchiveAgency:IsHaveNewMonsterInfoByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    return monsterType and self._Model._MonsterRedPointDic[monsterType] and
            self._Model._MonsterRedPointDic[monsterType][monsterId] and
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewInfo or false
end

function XArchiveAgency:IsHaveNewMonsterSkillByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    return monsterType and self._Model._MonsterRedPointDic[monsterType] and
            self._Model._MonsterRedPointDic[monsterType][monsterId] and
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSkill or false
end

function XArchiveAgency:IsHaveNewMonsterSettingByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    return monsterType and self._Model._MonsterRedPointDic[monsterType] and
            self._Model._MonsterRedPointDic[monsterType][monsterId] and
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSetting or false
end

function XArchiveAgency:IsArchiveMonsterUnlockByArchiveId(id)
    if XTool.IsNumberValid(id) then
        return self._Model._ArchiveMonsterUnlockIdsList[id]
    end
    return false
end

function XArchiveAgency:GetMonsterEvaluateFromSever(NpcIds, cb)
    local now = XTime.GetServerNowTimestamp()
    local monsterId = self._Model:GetArchiveNpcToMonster()[NpcIds[1]]
    local syscTime = self._Model._LastSyncMonsterEvaluateTimes[monsterId]

    if syscTime and now - syscTime < XEnumConst.Archive.SYNC_EVALUATE_SECOND then
        if cb then
            cb()
            return
        end
    end

    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.GetEvaluateRequest, {Ids = NpcIds}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetArchiveMonsterEvaluate(res.Evaluates)
        self:SetArchiveMonsterMySelfEvaluate(res.PersonalEvaluates)
        self._Model._LastSyncMonsterEvaluateTimes[monsterId] = XTime.GetServerNowTimestamp()
        if cb then cb() end
    end)
end

function XArchiveAgency:SetArchiveMonsterEvaluate(evaluates)
    for _,evaluate in pairs(evaluates or {}) do
        if evaluate and evaluate.Id then
            self._Model._ArchiveMonsterEvaluateList[evaluate.Id] = evaluate
            for index,tag in pairs(self._Model._ArchiveMonsterEvaluateList[evaluate.Id].Tags) do
                local tagCfg = self._Model:GetTag()[tag.Id]
                if tagCfg and tagCfg.IsNotShow == 1 then
                    self._Model._ArchiveMonsterEvaluateList[evaluate.Id].Tags[index] = nil
                end
            end
        end
    end
end

function XArchiveAgency:SetArchiveMonsterMySelfEvaluate(mySelfEvaluates)
    for _,mySelfEvaluate in pairs(mySelfEvaluates or {}) do
        if mySelfEvaluate and mySelfEvaluate.Id then
            self._Model._ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id] = mySelfEvaluate
            for index,tag in pairs(self._Model._ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id].Tags) do
                local tagCfg = self._Model:GetTag()[tag]
                if tagCfg and tagCfg.IsNotShow == 1 then
                    self._Model._ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id].Tags[index] = nil
                end
            end
        end
    end
end
--endregion

--region --------------------------------怪物图鉴，数据更新相关------------------------------------------>>>

function XArchiveAgency:UpdateMonsterData()
    self._Model._MonsterRedPointDic = {}
    self:UpdateMonsterList()
    self:UpdateMonsterInfoList()
    self:UpdateMonsterSettingList()
    self:UpdateMonsterSkillList()
    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_KILLCOUNTCHANGE)
end

function XArchiveAgency:UpdateMonsterList() --更新图鉴怪物列表数据
    local killCount = {}
    local tmpData = {}
    for _,showedMonster in pairs(self._Model._ArchiveShowedMonsterList or {}) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            tmpData.IsLockMain = false
            if not killCount[sameNpcId] then killCount[sameNpcId] = 0 end
            killCount[sameNpcId] = killCount[sameNpcId] + showedMonster.Killed
            tmpData.Kill = tmpData.Kill or {}
            tmpData.Kill[sameNpcId] = killCount[sameNpcId]
            monsterData:UpdateData(tmpData)
            self:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.Monster,nil)
        end
    end
end

function XArchiveAgency:UpdateMonsterInfoList()--更新图鉴怪物信息列表数据
    for _,showedMonster in pairs(self._Model._ArchiveShowedMonsterList or {}) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                for _,type in pairs(self._Model:GetArchiveMonsterInfoList()[npcId] or {}) do
                    for _,monsterInfo in pairs(type) do
                        local IsUnLock = false
                        local lockDes = ""
                        if monsterInfo:GetCondition() == 0 then
                            IsUnLock =true
                        else
                            IsUnLock,lockDes = XConditionManager.CheckCondition(monsterInfo:GetCondition(),monsterInfo:GetGroupId())
                        end
                        local tmpData = {}
                        tmpData.IsLock = not IsUnLock
                        tmpData.LockDesc = lockDes
                        monsterInfo:UpdateData(tmpData)
                        if IsUnLock then
                            self:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterInfo,monsterInfo:GetId())
                        end
                    end
                end
            end
        end
    end
end

function XArchiveAgency:UpdateMonsterSkillList()--更新图鉴怪物技能列表数据
    for _,showedMonster in pairs(self._Model._ArchiveShowedMonsterList or {}) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                for _,monsterSkill in pairs(self._Model:GetArchiveMonsterSkillList()[npcId] or {}) do
                    local IsUnLock = false
                    local lockDes = ""
                    if monsterSkill:GetCondition() == 0 then
                        IsUnLock =true
                    else
                        IsUnLock,lockDes = XConditionManager.CheckCondition(monsterSkill:GetCondition(),monsterSkill:GetGroupId())
                    end
                    local tmpData = {}
                    tmpData.IsLock = not IsUnLock
                    tmpData.LockDesc = lockDes
                    monsterSkill:UpdateData(tmpData)
                    if IsUnLock then
                        self:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterSkill,monsterSkill:GetId())
                    end
                end
            end
        end
    end
end

function XArchiveAgency:UpdateMonsterSettingList()--更新图鉴怪物设定列表数据
    for _,showedMonster in pairs(self._Model._ArchiveShowedMonsterList or {}) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                for _,type in pairs(self._Model:GetArchiveMonsterSettingList()[npcId] or {}) do
                    for _,monsterStting in pairs(type) do
                        local IsUnLock = false
                        local lockDes = ""
                        if monsterStting:GetCondition() == 0 then
                            IsUnLock =true
                        else
                            IsUnLock,lockDes = XConditionManager.CheckCondition(monsterStting:GetCondition(),monsterStting:GetGroupId())
                        end
                        local tmpData = {}
                        tmpData.IsLock = not IsUnLock
                        tmpData.LockDesc = lockDes
                        monsterStting:UpdateData(tmpData)
                        if IsUnLock then
                            self:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterSetting,monsterStting:GetId())
                        end
                    end
                end
            end
        end
    end
end

function XArchiveAgency:SetMonsterRedPointDic(monsterId,type,id)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return end
    if not self._Model._MonsterRedPointDic[monsterType] then
        self._Model._MonsterRedPointDic[monsterType] = {}
    end
    if not self._Model._MonsterRedPointDic[monsterType][monsterId] then
        self._Model._MonsterRedPointDic[monsterType][monsterId] = {}
    end
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        if not self._Model._ArchiveMonsterUnlockIdsList[monsterId] then
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        if not self._Model._ArchiveMonsterInfoUnlockIdsList[id] then
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        if not self._Model._ArchiveMonsterSkillUnlockIdsList[id] then
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = true
        end
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        if not self._Model._ArchiveMonsterSettingUnlockIdsList[id] then
            self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = true
        end
    end

end

function XArchiveAgency:SetArchiveShowedMonsterList(list)
    for _,monster in pairs(list or {}) do
        self._Model._ArchiveShowedMonsterList[monster.Id] = monster
    end
end

function XArchiveAgency:AddArchiveShowedMonsterList(list)
    for _,monster in pairs(list or {}) do
        if not self._Model._ArchiveShowedMonsterList[monster] then
            self._Model._ArchiveShowedMonsterList[monster.Id] = monster
        else
            self._Model._ArchiveShowedMonsterList[monster.Id].Killed = monster.Killed
        end
    end
end

function XArchiveAgency:SetArchiveMonsterUnlockIdsList(list)
    for _,id in pairs(list) do
        self._Model._ArchiveMonsterUnlockIdsList[id] = true
    end
end

function XArchiveAgency:SetArchiveMonsterInfoUnlockIdsList(list)
    for _,id in pairs(list) do
        self._Model._ArchiveMonsterInfoUnlockIdsList[id] = true
    end
end

function XArchiveAgency:SetArchiveMonsterSkillUnlockIdsList(list)
    for _,id in pairs(list) do
        self._Model._ArchiveMonsterSkillUnlockIdsList[id] = true
    end
end

function XArchiveAgency:SetArchiveMonsterSettingUnlockIdsList(list)
    for _,id in pairs(list) do
        self._Model._ArchiveMonsterSettingUnlockIdsList[id] = true
    end
end

--endregion

--region --------------------------------伙伴图鉴相关------------------------------------------>>>
-- 根据npcId获取monsterId
-- PS:XArchiveAgency:GetSameNpcId该方法关联配置的Npc的会计入图鉴击杀计算内
-- PS:这里两张表的配置其实是强关联，详细配法最好问图鉴相关负责人
-- PS:以后根据NpcId获取MonsterId时不要直接走ArchiveNpcToMonster变量
function XArchiveAgency:GetMonsterIdByNpcId(npcId)
    local sameNpcId = self:GetSameNpcId(npcId)
    return self._Model:GetArchiveNpcToMonster()[sameNpcId]
end
--endregion 

--region ------------配置表相关-------->>>
function XArchiveAgency:GetSameNpcId(npcId)
    local data=self._Model:GetSameNpc()
    return data[npcId] and data[npcId] or npcId
end

-- 武器设定或故事
function XArchiveAgency:GetWeaponSettingList(id, settingType)
    local list = {}
    local settingDataList = self._Model:GetWeaponTemplateIdToSettingListDic()[id]
    if settingDataList then
        if not settingType or settingType == XEnumConst.Archive.SettingType.All then
            list = settingDataList
        else
            for _, settingData in pairs(settingDataList) do
                if settingData.Type == settingType then
                    table.insert(list, settingData)
                end
            end

        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetAwarenessSuitInfoGetType(suitId)
    return self._Model:GetArchiveAwarenessGroup()[suitId].Type
end

-- 意识设定或故事
function XArchiveAgency:GetAwarenessSettingList(id, settingType)
    local list = {}
    local settingDataList = self._Model:GetAwarenessSuitIdToSettingListDic()[id]
    if settingDataList then
        if not settingType or settingType == XEnumConst.Archive.SettingType.All then
            list = settingDataList
        else
            for _, settingData in pairs(settingDataList) do
                if settingData.Type == settingType then
                    table.insert(list, settingData)
                end
            end
        end
    else
        XLog.ErrorTableDataNotFound("XArchiveAgency:GetAwarenessSettingList", "配置表项", "Share/Archive/AwarenessSetting.tab", "id", tostring(id))
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetAwarenessGroupTypes()
    local list = {}
    for _, type in pairs(self._Model:GetArchiveAwarenessGroupType()) do
        table.insert(list, type)
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetShowedWeaponTypeList()
    return self._Model:GetShowedWeaponTypeList()
end

function XArchiveAgency:GetArchiveMonsterConfigById(id)
    return self._Model:GetMonster()[id]
end

function XArchiveAgency:GetArchiveMonsterInfoConfigById(id)
    return self._Model:GetMonsterInfo()[id]
end

function XArchiveAgency:GetArchiveMonsterSkillConfigById(id)
    return self._Model:GetMonsterSkill()[id]
end

function XArchiveAgency:GetArchiveMonsterSettingConfigById(id)
    return self._Model:GetMonsterSetting()[id]
end

function XArchiveAgency:GetMonsterTransDatas(npcId, npcState)
    local archiveMonsterTransData = self._Model:GetArchiveMonsterTransDic()[npcId]
    return archiveMonsterTransData and archiveMonsterTransData[npcState]
end

function XArchiveAgency:GetMonsterEffectDatas(npcId, npcState)
    local archiveMonsterEffectData = self._Model:GetArchiveMonsterEffectDatasDic()[npcId]
    return archiveMonsterEffectData and archiveMonsterEffectData[npcState]
end

function XArchiveAgency:GetMonsterNpcDataById(Id)
    if not self._Model:GetMonsterNpcData()[Id] then
        XLog.ErrorTableDataNotFound("XArchiveAgency:GetMonsterNpcDataById", "配置表项", 'Client/Archive/MonsterNpcData.tab', "Id", tostring(Id))
    end
    return self._Model:GetMonsterNpcData()[Id] or {}
end

function XArchiveAgency:GetMonsterNpcIdByModelId(modelId)
    for npcId, data in pairs(self._Model:GetMonsterNpcData()) do
        if data.ModelId == modelId then
            return data.Id
        end
    end
    return false
end


function XArchiveAgency:GetMonsterRealName(id)
    local name = self:GetMonsterNpcDataById(id).Name
    if not name then
        XLog.ErrorTableDataNotFound("XArchiveAgency:GetMonsterRealName", "配置表项中的Name字段", 'Client/Archive/MonsterNpcData.tab', "id", tostring(id))
        return ""
    end
    return name
end

function XArchiveAgency:GetMonsterModel(id)
    return self:GetMonsterNpcDataById(id).ModelId
end

function XArchiveAgency:GetWeaponGroupByType(type)
    return self._Model:GetArchiveWeaponGroup()[type]
end

function XArchiveAgency:GetWeaponGroupName(type)
    return self._Model:GetArchiveWeaponGroup()[type].GroupName
end
function XArchiveAgency:GetArchiveStoryChapterConfigById(id)
    return self._Model:GetStoryChapter()[id]
end

function XArchiveAgency:GetArchiveStoryDetailConfigById(id)
    return self._Model:GetStoryDetail()[id]
end
-- NPC相关------------->>>
function XArchiveAgency:GetArchiveStoryNpcConfigById(id)
    return self._Model:GetStoryNpc()[id]
end

function XArchiveAgency:GetArchiveStoryNpcSettingConfigById(id)
    return self._Model:GetStoryNpcSetting()[id]
end
-- CG相关------------->>>
function XArchiveAgency:GetArchiveCGDetailConfigById(id)
    return self._Model:GetCGDetail()[id]
end

-- 邮件通讯相关------------->>>
function XArchiveAgency:GetArchiveMailsConfigById(id)
    return self._Model:GetArchiveMail()[id]
end

function XArchiveAgency:GetArchiveCommunicationsConfigById(id)
    return self._Model:GetCommunication()[id]
end
-- 伙伴相关------------->>>
function XArchiveAgency:GetPartnerSettingConfigById(id)
    if not self._Model:GetPartnerSetting()[id] then
        XLog.Error("Id is not exist in " .. "Share/Archive/PartnerSetting.tab" .. " id = " .. id)
        return
    end
    return self._Model:GetPartnerSetting()[id]
end

function XArchiveAgency:GetPartnerConfigById(id)
    if not self._Model:GetArchivePartner()[id] then
        XLog.Error("Id is not exist in " .. 'Client/Archive/ArchivePartner.tab' .. " id = " .. id)
        return
    end
    return self._Model:GetArchivePartner()[id]
end
--endregion

--region -------------------武器、意识部分------------------->>>
-- 武器相关
function XArchiveAgency:IsWeaponGet(templateId)
    return self._Model._ArchiveWeaponServerData[templateId] ~= nil
end


-- 武器new标签
function XArchiveAgency:IsNewWeapon(templateId)
    local isNew = false
    if not self._Model._ArchiveWeaponUnlockServerData[templateId] and self._Model._ArchiveWeaponServerData[templateId] then
        isNew = true
    end

    return isNew
end


-- 武器图鉴是否有new标签
function XArchiveAgency:IsHaveNewWeapon()
    return self._Model._ArchiveWeaponTotalRedPointCount > 0
end

-- 武器图鉴是否有红点
function XArchiveAgency:IsNewWeaponSetting(templateId)
    local newSettingList = self._Model._ArchiveNewWeaponSettingIdsDic[templateId]
    if newSettingList and #newSettingList > 0 then
        return true
    end
    return false
end


-- 武器图鉴是否有红点
function XArchiveAgency:IsHaveNewWeaponSetting()
    return self._Model._ArchiveWeaponSettingTotalRedPointCount > 0
end

-- 意识相关
function XArchiveAgency:IsAwarenessGet(templateId)
    return self._Model._ArchiveAwarenessServerData[templateId] ~= nil
end


-- 意识new标签
function XArchiveAgency:IsNewAwarenessSuit(suitId)
    local isNew = false
    if not self._Model._ArchiveAwarenessSuitUnlockServerData[suitId] and self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] then
        isNew = true
    end
    return isNew
end


-- 意识图鉴是否有new标签
function XArchiveAgency:IsHaveNewAwarenessSuit()
    return self._Model._ArchiveAwarenessSuitTotalRedPointCount > 0
end

-- 意识设定是否有红点
function XArchiveAgency:IsNewAwarenessSetting(suitId)
    local newSettingList = self._Model._ArchiveNewAwarenessSettingIdsDic[suitId]
    if newSettingList and #newSettingList > 0 then
        return true
    end
    return false
end

-- 意识图鉴是否有红点
function XArchiveAgency:IsHaveNewAwarenessSetting()
    return self._Model._ArchiveAwarenessSettingTotalRedPointCount > 0
end

function XArchiveAgency:GetAwarenessCountBySuitId(suitId)
    return self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
end

function XArchiveAgency:IsEquipGet(templateId)
    return self:IsWeaponGet(templateId) or self:IsAwarenessGet(templateId)
end

function XArchiveAgency:GetEquipLv(templateId)
    local data = self._Model._ArchiveWeaponServerData[templateId] or self._Model._ArchiveAwarenessServerData[templateId]
    return data and data.Level or 0
end

function XArchiveAgency:GetEquipBreakThroughTimes(templateId)
    local data = self._Model._ArchiveWeaponServerData[templateId] or self._Model._ArchiveAwarenessServerData[templateId]
    return data and data.Breakthrough or 0
end


-- 从服务端获取武器和意识相关数据
function XArchiveAgency:SetEquipServerData(equipData)
    self._Model._ArchiveAwarenessSuitToAwarenessCountDic = {}
    local templateId
    local suitId
    --只有在配置表中出现id才会记录在本地的serverData
    for _, data in ipairs(equipData) do
        templateId = data.Id
        if XDataCenter.EquipManager.IsWeaponByTemplateId(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            self._Model._ArchiveWeaponServerData[templateId] = data
        elseif XDataCenter.EquipManager.IsAwarenessByTemplateId(templateId) and self._Model:GetAwarenessShowedStatusDic()[templateId] then
            self._Model._ArchiveAwarenessServerData[templateId] = data
            suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
            self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] = self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
            self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] = self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] + 1
        end
    end
end

-- 从服务端获取武器和意识相关数据，并判断是否有新的武器或者意识
function XArchiveAgency:UpdateEquipServerData(equipData)
    local templateId
    --只有在配置表中出现id才会记录在本地的serverData
    local isNewWeaponSetting = false
    local isNewAwarenessSetting = false
    local weaponIdList
    local awarenessSuitIdList
    local suitId
    local weaponType
    local awarenessSuitGetType
    local settingDataList
    local settingId
    local conditionId
    local updateSuitIdDic
    for _, data in ipairs(equipData) do
        templateId = data.Id
        if XDataCenter.EquipManager.IsWeaponByTemplateId(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(templateId)
            if not self._Model._ArchiveWeaponUnlockServerData[templateId] then
                weaponIdList = weaponIdList or {}
                tableInsert(weaponIdList, templateId)
                if not self._Model._ArchiveWeaponServerData[templateId] then
                    self._Model._ArchiveWeaponRedPointCountDic[weaponType] =  self._Model._ArchiveWeaponRedPointCountDic[weaponType] + 1
                    self._Model._ArchiveWeaponTotalRedPointCount = self._Model._ArchiveWeaponTotalRedPointCount + 1
                end
            end
            self._Model._ArchiveWeaponServerData[templateId] = data
            settingDataList = self:GetWeaponSettingList(templateId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                conditionId = settingData.Condition
                if not self._Model._ArchiveWeaponSettingUnlockServerData[settingId] then
                    if not self._Model._ArchiveWeaponSettingCanUnlockDic[settingId] and XConditionManager.CheckCondition(conditionId, templateId) then
                        isNewWeaponSetting = true
                        self._Model._ArchiveWeaponSettingCanUnlockDic[settingId] = true
                        self._Model._ArchiveNewWeaponSettingIdsDic[templateId] = self._Model._ArchiveNewWeaponSettingIdsDic[templateId] or {}
                        table.insert(self._Model._ArchiveNewWeaponSettingIdsDic[templateId], settingId)
                        self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] = self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] + 1
                        self._Model._ArchiveWeaponSettingTotalRedPointCount = self._Model._ArchiveWeaponSettingTotalRedPointCount + 1
                    end
                end
            end

        elseif XDataCenter.EquipManager.IsAwarenessByTemplateId(templateId) and self._Model:GetAwarenessShowedStatusDic()[templateId] then
            suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
            updateSuitIdDic = updateSuitIdDic or {}
            updateSuitIdDic[suitId] = true
            if not self._Model._ArchiveAwarenessServerData[templateId] then
                if not self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] then
                    awarenessSuitIdList = awarenessSuitIdList or {}
                    tableInsert(awarenessSuitIdList, suitId)
                    awarenessSuitGetType = self:GetAwarenessSuitInfoGetType(suitId)
                    self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessSuitGetType] = self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessSuitGetType] + 1
                    self._Model._ArchiveAwarenessSuitTotalRedPointCount = self._Model._ArchiveAwarenessSuitTotalRedPointCount + 1
                end
                self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] = self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
                self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] = self._Model._ArchiveAwarenessSuitToAwarenessCountDic[suitId] + 1
            end

            self._Model._ArchiveAwarenessServerData[templateId] = data
        end
    end

    if updateSuitIdDic then
        for tmpSuitId, _ in pairs(updateSuitIdDic) do
            settingDataList = self:GetAwarenessSettingList(tmpSuitId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                conditionId = settingData.Condition

                if not self._Model._ArchiveAwarenessSettingUnlockServerData[settingId] and
                        not self._Model._ArchiveAwarenessSettingCanUnlockDic[settingId] and
                        XConditionManager.CheckCondition(conditionId, tmpSuitId) then

                    isNewAwarenessSetting = true
                    self._Model._ArchiveAwarenessSettingCanUnlockDic[settingId] = true
                    self._Model._ArchiveNewAwarenessSettingIdsDic[tmpSuitId] = self._Model._ArchiveNewAwarenessSettingIdsDic[tmpSuitId] or {}
                    table.insert(self._Model._ArchiveNewAwarenessSettingIdsDic[tmpSuitId], settingId)

                    awarenessSuitGetType = self:GetAwarenessSuitInfoGetType(tmpSuitId)
                    self._Model._ArchiveAwarenessSettingRedPointCountDic[awarenessSuitGetType] = self._Model._ArchiveAwarenessSettingRedPointCountDic[awarenessSuitGetType] + 1
                    self._Model._ArchiveAwarenessSettingTotalRedPointCount = self._Model._ArchiveAwarenessSettingTotalRedPointCount + 1
                end
            end
        end
    end

    if weaponIdList then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_WEAPON, weaponIdList)
    end
    if isNewWeaponSetting then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
    end

    if awarenessSuitIdList then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT, awarenessSuitIdList)
    end
    if isNewAwarenessSetting then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
    end
end

function XArchiveAgency:UpdateWeaponUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._Model._ArchiveWeaponUnlockServerData[id] = true
    end
end

function XArchiveAgency:UpdateAwarenessSuitUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._Model._ArchiveAwarenessSuitUnlockServerData[id] = true
    end
end

function XArchiveAgency:UpdateWeaponSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._Model._ArchiveWeaponSettingUnlockServerData[id] = true
    end
end

function XArchiveAgency:UpdateAwarenessSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._Model._ArchiveAwarenessSettingUnlockServerData[id] = true
    end
end

function XArchiveAgency:CreateRedPointCountDic()
    local weaponTypeList = self:GetShowedWeaponTypeList()
    local groupTypeList = self:GetAwarenessGroupTypes()

    for _,type in ipairs(weaponTypeList) do
        self._Model._ArchiveWeaponRedPointCountDic[type] = 0
        self._Model._ArchiveWeaponSettingRedPointCountDic[type] = 0
    end

    for _, type in pairs(groupTypeList) do
        self._Model._ArchiveAwarenessSuitRedPointCountDic[type.GroupId] = 0
        self._Model._ArchiveAwarenessSettingRedPointCountDic[type.GroupId] = 0
    end

    local weaponType
    for id, _ in pairs(self._Model._ArchiveWeaponServerData) do
        if not self._Model._ArchiveWeaponUnlockServerData[id] then
            weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(id)
            if weaponType then
                self._Model._ArchiveWeaponRedPointCountDic[weaponType] = self._Model._ArchiveWeaponRedPointCountDic[weaponType] + 1
                self._Model._ArchiveWeaponTotalRedPointCount = self._Model._ArchiveWeaponTotalRedPointCount + 1
            end
        end
    end

    local awarenessGetType
    for id, _ in pairs(self._Model._ArchiveAwarenessSuitToAwarenessCountDic) do
        if not self._Model._ArchiveAwarenessSuitUnlockServerData[id] then
            awarenessGetType = self:GetAwarenessSuitInfoGetType(id)
            if self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] then
                self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] + 1
                self._Model._ArchiveAwarenessSuitTotalRedPointCount = self._Model._ArchiveAwarenessSuitTotalRedPointCount + 1
            end
        end
    end


    local settingDataList
    local settingId
    for weaponId, _ in pairs(self._Model:GetWeaponTemplateIdToSettingListDic()) do
        settingDataList = self:GetWeaponSettingList(weaponId)
        for _, settingData in ipairs(settingDataList) do
            settingId = settingData.Id
            if not self._Model._ArchiveWeaponSettingUnlockServerData[settingId] and XConditionManager.CheckCondition(settingData.Condition, weaponId) then
                self._Model._ArchiveWeaponSettingCanUnlockDic[settingId] = true
                weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(weaponId)
                self._Model._ArchiveNewWeaponSettingIdsDic[weaponId] = self._Model._ArchiveNewWeaponSettingIdsDic[weaponId] or {}
                table.insert(self._Model._ArchiveNewWeaponSettingIdsDic[weaponId],settingId)
                self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] = self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] + 1
                self._Model._ArchiveWeaponSettingTotalRedPointCount = self._Model._ArchiveWeaponSettingTotalRedPointCount + 1
            end
        end
    end

    local getType
    for suitId, _ in pairs(self._Model:GetArchiveAwarenessGroup()) do
        settingDataList = self:GetAwarenessSettingList(suitId)
        for _, settingData in ipairs(settingDataList) do
            settingId = settingData.Id
            if not self._Model._ArchiveAwarenessSettingUnlockServerData[settingId] and XConditionManager.CheckCondition(settingData.Condition, suitId) then
                self._Model._ArchiveAwarenessSettingCanUnlockDic[settingId] = true
                getType = self:GetAwarenessSuitInfoGetType(suitId)
                self._Model._ArchiveNewAwarenessSettingIdsDic[suitId] = self._Model._ArchiveNewAwarenessSettingIdsDic[suitId] or {}
                table.insert(self._Model._ArchiveNewAwarenessSettingIdsDic[suitId], settingId)
                self._Model._ArchiveAwarenessSettingRedPointCountDic[getType] = self._Model._ArchiveAwarenessSettingRedPointCountDic[getType] + 1
                self._Model._ArchiveAwarenessSettingTotalRedPointCount = self._Model._ArchiveAwarenessSettingTotalRedPointCount + 1
            end
        end
    end
end
--endregion

--region -------------剧情相关------------->>>

function XArchiveAgency:GetArchiveStoryDetailList(chapterId)--chapterId为空时不作为判断条件
    if chapterId then
        return self._Model:GetArchiveStoryDetailList()[chapterId] or {}
    end
    local list = {}
    for _,group in pairs(self._Model:GetArchiveStoryDetailList() or {}) do
        for _,detail in pairs(group) do
            tableInsert(list,detail)
        end
    end
    return self._Model:SortByOrder(list)
end
--endregion

--region -------------CG相关------------->>>

function XArchiveAgency:GetArchiveCgEntity(id)
    return self._Model:GetArchiveCGDetailData()[id]
end

function XArchiveAgency:SetArchiveShowedCGList(idList)
    for _,id in pairs(idList or {}) do
        self._Model._ArchiveShowedCGList[id] = id
    end
end

function XArchiveAgency:SetUnlockPvDetails(idList)
    if type(idList) ~= "table" then
        self._Model._UnlockPvDetails[idList] = idList
        return
    end

    for _, id in pairs(idList or {}) do
        self._Model._UnlockPvDetails[id] = id
    end
end

function XArchiveAgency:SetArchiveShowedStoryList(idList)
    for _,id in pairs(idList or {}) do
        self._Model._ArchiveShowedStoryList[id] = id
    end
end

function XArchiveAgency:UpdateCGAllList()--更新图鉴Npc数据
    for _,group in pairs(self._Model:GetArchiveCGDetailList() or {}) do
        for _,CGDetail in pairs(group) do
            local lockDes = ""
            local IsUnLock = ""
            if self._Model._ArchiveShowedCGList[CGDetail:GetId()] then
                IsUnLock = true
            else
                if CGDetail:GetCondition() ~= 0 then
                    _,lockDes = XConditionManager.CheckCondition(CGDetail:GetCondition())
                end
                IsUnLock = false
            end
            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            tmpData.LockDesc = lockDes
            CGDetail:UpdateData(tmpData)
        end
    end
end

function XArchiveAgency:GetArchiveCGGroupList(isCustomLoading)
    local list = {}
    for _, group in pairs(self._Model:GetCGGroup()) do
        if isCustomLoading and XLoadingConfig.CheckCustomBlockGroup(group.Id) then
            goto CONTINUE
        end
        tableInsert(list, group)
        ::CONTINUE::
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetArchiveCGDetailList(group)--group为空时不作为判断条件，获取相应类型的图鉴CG列表
    if group then
        return self._Model:GetArchiveCGDetailList()[group] and self._Model:GetArchiveCGDetailList()[group] or {}
    end
    local list = {}
    for _,CGDetailGroup in pairs(self._Model:GetArchiveCGDetailList()) do
        for _,CGDetail in pairs(CGDetailGroup) do
            tableInsert(list,CGDetail)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:CheckCGRedPointByGroup(groupId)
    local list = self:GetArchiveCGDetailList(groupId)
    for _,cgDetail in pairs(list) do
        if self:CheckCGRedPoint(cgDetail:GetId()) then
            return true
        end
    end
    return false
end

function XArchiveAgency:CheckCGRedPoint(id)
    if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
        return true
    else
        return false
    end
end

function XArchiveAgency:AddNewCGRedPoint(idList)
    for _,id in pairs(idList) do
        if self._Model:GetArchiveCGDetailData()[id] and self._Model:GetArchiveCGDetailData()[id]:GetIsShowRedPoint() == 1 then

            if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
                XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id), id)
            end
        end
    end
end
--endregion

--region --------------------------------伙伴图鉴相关------------------------------------------>>>

function XArchiveAgency:UpdateArchivePartnerList()--更新图鉴伙伴数据
    for _,group in pairs(self._Model:GetArchivePartnerList() or {}) do
        for _,partner in pairs(group) do
            local IsUnLock = false
            if self._Model._PartnerUnLockDic[partner:GetTemplateId()] then
                IsUnLock = true
            end
            partner:UpdateData({IsArchiveLock = not IsUnLock})
        end
    end
end

function XArchiveAgency:UpdateArchivePartnerSettingList()--更新图鉴伙伴设定数据
    for _,group in pairs(self._Model:GetArchivePartnerList() or {}) do
        for _,partner in pairs(group) do
            partner:UpdateStoryAndSettingEntity(self._Model._PartnerUnLockSettingDic)
        end
    end
end

function XArchiveAgency:UpdateUnLockPartnerDic(dataList)
    for _,data in pairs(dataList) do
        if not self._Model._PartnerUnLockDic[data] then
            self._Model._PartnerUnLockDic[data] = data
        end
    end
end

function XArchiveAgency:UpdateUnLockArchiveMailDict(dataList)
    for _, archiveMailId in pairs(dataList or {}) do
        self._Model._UnlockArchiveMails[archiveMailId] = true
    end
end

function XArchiveAgency:CheckArchiveMailUnlock(archiveMailId)
    return self._Model._UnlockArchiveMails[archiveMailId] and true or false
end

function XArchiveAgency:UpdateUnLockPartnerSettingDic(dataList)
    for _,data in pairs(dataList) do
        if not self._Model._PartnerUnLockSettingDic[data] then
            self._Model._PartnerUnLockSettingDic[data] = data
        end
    end
end

function XArchiveAgency:GetPartnerUnLockById(templateId)
    return self._Model._PartnerUnLockDic[templateId]
end

function XArchiveAgency:GetPartnerSettingUnLockDic()
    return self._Model._PartnerUnLockSettingDic
end

function XArchiveAgency:GetArchivePartnerSetting(partnerTemplateId,type)
    return self._Model:GetArchivePartnerSetting(partnerTemplateId,type)
end
--endregion

-- 打开图鉴接口，统一入口
function XArchiveAgency:OpenUiArchiveMain()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) then
        return
    end
    --资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end

    XLuaUiManager.Open("UiArchiveMain")
end

function XArchiveAgency:SortByOrder(list)
    return self._Model:SortByOrder(list)
end
----------public end----------

----------private start----------


----------private end----------

return XArchiveAgency