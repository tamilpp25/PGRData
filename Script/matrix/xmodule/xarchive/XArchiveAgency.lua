---@class XArchiveAgency : XAgency
---@field private _Model XArchiveModel
local XArchiveAgency = XClass(XAgency, "XArchiveAgency")
local tableInsert=table.insert

function XArchiveAgency:OnInit()
    ---@type XComicArchiveAgencyCom
    self.ComicArchiveCom = require('XModule/XArchive/SubModule/ComicArchive/XComicArchiveAgencyCom').New(self, self._Model)
    ---@type XCGArchiveAgencyCom
    self.CGArchiveCom = require('XModule/XArchive/SubModule/CGArchive/XCGArchiveAgencyCom').New(self, self._Model)
    ---@type XAwarenessArchiveAgencyCom
    self.AwarenessArchiveCom = require('XModule/XArchive/SubModule/AwarenessArchive/XAwarenessArchiveAgencyCom').New(self, self._Model)
end

function XArchiveAgency:InitRpc()
    XRpc.NotifyArchiveLoginData = function(data)
        self._Model:SetArchiveShowedMonsterList(data.Monsters)
        self._Model:SetArchiveMonsterSettingUnlockIdsList(data.MonsterSettings)
        self._Model:SetArchiveMonsterUnlockIdsList(data.MonsterUnlockIds)
        self._Model:SetArchiveMonsterInfoUnlockIdsList(data.MonsterInfos)
        self._Model:SetArchiveMonsterSkillUnlockIdsList(data.MonsterSkills)
        self:SetEquipServerData(data.Equips)

        self._Model:SetArchiveShowedCGList(data.UnlockCgs)
        self._Model:SetArchiveShowedStoryList(data.UnlockStoryDetails)--只保存通关的活动剧情ID，到了解禁事件后会被清除
        self._Model:SetUnlockPvDetails(data.UnlockPvDetails)

        self._Model:UpdateWeaponUnlockServerData(data.WeaponUnlockIds)
        self._Model:UpdateWeaponSettingUnlockServerData(data.WeaponSettings)
        self._Model:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self._Model:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self._Model:UpdateUnLockArchiveMailDict(data.UnlockMails)
        
        self.AwarenessArchiveCom:UpdateAwarenessDataFromLoginNotify(data)
        self.ComicArchiveCom:UpdateComicDataFromLoginNotify(data)

        self:UpdateMonsterData()
        self:UpdateCGAllList()
        self:CreateRedPointCountDicAll()

        XDataCenter.PartnerManager.UpdateAllPartnerStory()
        self:UpdateArchivePartnerList()
        self:UpdateArchivePartnerSettingList()
    end

    XRpc.NotifyArchiveMonsterRecord = function(data)
        self._Model:AddArchiveShowedMonsterList(data.Monsters)
        self:UpdateMonsterData()
    end

    XRpc.NotifyArchiveCgs = function(data)
        self._Model:SetArchiveShowedCGList(data.UnlockCgs)
        self:UpdateCGAllList()
        self.CGArchiveCom:AddNewCGRedPoint(data.UnlockCgs)
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_CG)
    end

    XRpc.NotifyArchivePvDetails = function(data)
        self._Model:SetUnlockPvDetails(data.UnlockPvDetails) --这的UnlockPvDetails是个int
    end
    -----------------武器、意识相关------------------->>>
    XRpc.NotifyArchiveEquip = function(data)
        self:UpdateEquipServerData(data.Equips)
    end

    -----------------武器、意识相关-------------------<<<
    -----------------剧情相关------------------->>>
    XRpc.NotifyArchiveStoryDetails = function(data)
        self._Model:SetArchiveShowedStoryList(data.UnlockStoryDetails)
    end
    -----------------剧情相关-------------------<<<

    -----------------伙伴相关------------------->>>

    XRpc.NotifyArchivePartners = function(data)
        self._Model:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self:UpdateArchivePartnerList()
    end

    XRpc.NotifyPartnerSettings = function(data)
        self._Model:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self:UpdateArchivePartnerSettingList()
        XDataCenter.PartnerManager.UpdateAllPartnerStory()
    end
    -----------------伙伴相关-------------------<<<

    --region   ------------------邮件相关 start-------------------
    XRpc.NotifyArchiveMail = function(data)
        local id = data.UnlockArchiveMailId
        if XTool.IsNumberValid(id) then
            self._Model:UpdateUnLockArchiveMailDict({ id })
        end
    end
    --endregion------------------邮件相关 finish------------------
    
    XRpc.NotifyArchiveComics = handler(self.ComicArchiveCom, self.ComicArchiveCom.UpdateUnlockComicDataFromNewNotify)
end

function XArchiveAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XArchiveAgency:OnRelease()
    self.ComicArchiveCom:Release()
    self.ComicArchiveCom = nil

    self.CGArchiveCom:Release()
    self.CGArchiveCom = nil

    self.AwarenessArchiveCom:Release()
    self.AwarenessArchiveCom = nil
end

----------public start----------
--region --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>
function XArchiveAgency:GetArchiveMonsterType(monsterId)
    local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
    return monsterData and monsterData:GetType() or nil
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
    for type,_ in pairs(self._Model:GetMonsterRedPointDic()) do
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
    local monsterRedPointDict=self._Model:GetMonsterRedPointDicByType(type)
    if not XTool.IsTableEmpty(monsterRedPointDict) then
        for monsterId,_ in pairs(monsterRedPointDict) do
            if self:IsMonsterHaveNewTagById(monsterId) then
                IsHaveNewTag = true
                break
            end
        end
    end
    return IsHaveNewTag
end

function XArchiveAgency:IsMonsterHaveRedPointByType(type)
    local IsHaveRedPoint = false
    local monsterRedPointDict=self._Model:GetMonsterRedPointDicByType(type)
    if not XTool.IsTableEmpty(monsterRedPointDict) then
        for monsterId,_ in pairs(monsterRedPointDict) do
            if self:IsMonsterHaveRedPointById(monsterId) then
                IsHaveRedPoint = true
                break
            end
        end
    end
    return IsHaveRedPoint
end

function XArchiveAgency:IsMonsterHaveNewTagById(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewMonster
    end
    return false
end

function XArchiveAgency:IsMonsterHaveRedPointById(monsterId)
    return self:IsHaveNewMonsterInfoByNpcId(monsterId) or
            self:IsHaveNewMonsterSkillByNpcId(monsterId) or
            self:IsHaveNewMonsterSettingByNpcId(monsterId)
end

function XArchiveAgency:IsHaveNewMonsterInfoByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewInfo
    end
    return false
end

function XArchiveAgency:IsHaveNewMonsterSkillByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewSkill
    end
    return false
end

function XArchiveAgency:IsHaveNewMonsterSettingByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewSetting
    end
    return false
end

function XArchiveAgency:IsArchiveMonsterUnlockByArchiveId(id)
    if XTool.IsNumberValid(id) then
        return self._Model:GetMonsterUnlockById(id)
    end
    return false
end

--- 怪物在图鉴主界面是否解锁
function XArchiveAgency:GetMonsterUnlockMainById(monsterId)
    return self._Model:GetMonsterUnlockMainById(monsterId)
end

function XArchiveAgency:GetMonsterEvaluateFromSever(NpcIds, cb)
    local now = XTime.GetServerNowTimestamp()
    local monsterId = self._Model:GetArchiveNpcToMonster()[NpcIds[1]]
    local syscTime = self._Model:GetLastSyncMonsterEvaluateTimeById(monsterId)

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
        self._Model:SetLastSyncMonsterEvaluateTimeById(monsterId,XTime.GetServerNowTimestamp())
        if cb then cb() end
    end)
end

function XArchiveAgency:SetArchiveMonsterEvaluate(evaluates)
    if not XTool.IsTableEmpty(evaluates) then
        for _,evaluate in pairs(evaluates) do
            if evaluate and evaluate.Id then
                self._Model:SetMonsterEvaluateInListById(evaluate.Id, evaluate)
                for index,tag in pairs(evaluate.Tags) do
                    local tagCfg = self._Model:GetTag()[tag.Id]
                    if tagCfg and tagCfg.IsNotShow == 1 then
                        evaluate.Tags[index] = nil
                    end
                end
            end
        end
    end
end

function XArchiveAgency:SetArchiveMonsterMySelfEvaluate(mySelfEvaluates)
    if XTool.IsTableEmpty(mySelfEvaluates) then return end
    
    for _,mySelfEvaluate in pairs(mySelfEvaluates) do
        if mySelfEvaluate and mySelfEvaluate.Id then
            self._Model:SetMonsterMySelfEvaluateInListById(mySelfEvaluate.Id, mySelfEvaluate)
            for index,tag in pairs(mySelfEvaluate.Tags) do
                local tagCfg = self._Model:GetTag()[tag]
                if tagCfg and tagCfg.IsNotShow == 1 then
                    mySelfEvaluate.Tags[index] = nil
                end
            end
        end
    end
end
--endregion

--region --------------------------------怪物图鉴，数据更新相关------------------------------------------>>>

function XArchiveAgency:UpdateMonsterData()
    self._Model:ResetMonsterRedPointDic()
    self:UpdateMonsterList()
    self:UpdateMonsterInfoList()
    self:UpdateMonsterSettingList()
    self:UpdateMonsterSkillList()
    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_KILLCOUNTCHANGE)
end

-- 解锁图鉴怪物
function XArchiveAgency:UnlockArchiveMonster(id)
    -- Id无效
    if not id or id == 0 then return end
    -- 已解锁
    if self._Model:GetMonsterUnlockById(id) then return end
    -- 请求解锁
    local req = { Ids = {id} }
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveMonsterRequest, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:ClearMonsterRedPointDic(id, XEnumConst.Archive.MonsterRedPointType.Monster)
        self._Model:SetArchiveMonsterUnlockIdsList(req.Ids)
        XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER)
    end)
end

function XArchiveAgency:UpdateMonsterList() --更新图鉴怪物列表数据
    local killCount = {}
    local tmpData = {}
    for _,showedMonster in pairs(self._Model:GetShowedMonsterList()) do
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
            self._Model:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.Monster,nil)
        end
    end
end

function XArchiveAgency:UpdateMonsterInfoList()--更新图鉴怪物信息列表数据
    for _,showedMonster in pairs(self._Model:GetShowedMonsterList()) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            local npcIds = monsterData:GetNpcId()
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            
            for _,npcId in pairs(npcIds) do
                local list = self._Model:GetArchiveMonsterInfoList()[npcId]
                if XTool.IsTableEmpty(list) then
                    goto continue2
                end
                for _,type in pairs(list) do
                    ---@param monsterInfo XArchiveMonsterDetailEntity
                    for _,monsterInfo in pairs(type) do
                        local IsUnLock = false
                        local lockDes = ""
                        if monsterInfo:GetCondition() == 0 then
                            IsUnLock =true
                        else
                            IsUnLock,lockDes = XConditionManager.CheckCondition(monsterInfo:GetCondition(),monsterInfo:GetGroupId())
                        end
                        
                        monsterInfo:SetIsLock(not IsUnLock)
                        monsterInfo:SetLockDesc(lockDes)
                        
                        if IsUnLock then
                            self._Model:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterInfo,monsterInfo:GetId())
                        end
                    end
                end
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XArchiveAgency:UpdateMonsterSkillList()--更新图鉴怪物技能列表数据
    for _,showedMonster in pairs(self._Model:GetShowedMonsterList()) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            local npcIds = monsterData:GetNpcId()
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            for _,npcId in pairs(npcIds) do
                local skillList = self._Model:GetArchiveMonsterSkillList()[npcId]
                if XTool.IsTableEmpty(skillList) then
                    goto continue2
                end
                
                ---@param monsterSkill XArchiveMonsterDetailEntity
                for _,monsterSkill in pairs(skillList) do
                    local IsUnLock = false
                    local lockDes = ""
                    if monsterSkill:GetCondition() == 0 then
                        IsUnLock =true
                    else
                        IsUnLock,lockDes = XConditionManager.CheckCondition(monsterSkill:GetCondition(),monsterSkill:GetGroupId())
                    end

                    monsterSkill:SetIsLock(not IsUnLock)
                    monsterSkill:SetLockDesc(lockDes)
                    
                    if IsUnLock then
                        self._Model:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterSkill,monsterSkill:GetId())
                    end
                end
                
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XArchiveAgency:UpdateMonsterSettingList()--更新图鉴怪物设定列表数据
    for _,showedMonster in pairs(self._Model:GetShowedMonsterList()) do
        local sameNpcId = self:GetSameNpcId(showedMonster.Id)
        local monsterId = self._Model:GetArchiveNpcToMonster()[sameNpcId]
        local monsterData = self._Model:GetArchiveMonsterData()[monsterId]
        if monsterId and monsterData then
            local npcIds = monsterData:GetNpcId()
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            for _,npcId in pairs(npcIds) do
                local settingList = self._Model:GetArchiveMonsterSettingList()[npcId]
                if XTool.IsTableEmpty(settingList) then
                    goto continue2
                end
                
                for _,type in pairs(settingList) do
                    ---@param monsterSetting XArchiveMonsterDetailEntity
                    for _, monsterSetting in pairs(type) do
                        local IsUnLock = false
                        local lockDes = ""
                        if monsterSetting:GetCondition() == 0 then
                            IsUnLock =true
                        else
                            IsUnLock,lockDes = XConditionManager.CheckCondition(monsterSetting:GetCondition(),monsterSetting:GetGroupId())
                        end

                        monsterSetting:SetIsLock(not IsUnLock)
                        monsterSetting:SetLockDesc(lockDes)
                        
                        if IsUnLock then
                            self._Model:SetMonsterRedPointDic(monsterId,XEnumConst.Archive.MonsterRedPointType.MonsterSetting,monsterSetting:GetId())
                        end
                    end
                end
                
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XArchiveAgency:ClearMonsterRedPointDic(monsterId,type)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return end
    self._Model:ClearMonsterRedPointDic(monsterType,monsterId,type)
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

function XArchiveAgency:GetMonsterEffectDatas(npcId, npcState)
    local archiveMonsterEffectData = self._Model:GetArchiveMonsterEffectDatasDic()[npcId]
    return archiveMonsterEffectData and archiveMonsterEffectData[npcState]
end

function XArchiveAgency:GetMonsterNpcDataById(Id)
    local npcData = self._Model:GetMonsterNpcData()[Id]
    if not npcData then
        XLog.ErrorTableDataNotFound("XArchiveAgency:GetMonsterNpcDataById", "配置表项", 'Client/Archive/MonsterNpcData.tab', "Id", tostring(Id))
        return {}
    end
    return npcData
end

function XArchiveAgency:GetMonsterNpcIdByModelId(targetModelId)
    for npcId, data in pairs(self._Model:GetMonsterNpcData()) do
        local modelIds = data.ModelId

        for _, modelId in pairs(modelIds) do
            if modelId == targetModelId then
                return data.Id
            end
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

function XArchiveAgency:GetMonsterModel(id, index)
    return self:GetMonsterNpcDataById(id).ModelId[index or 1]
end

function XArchiveAgency:GetMonsterModelIds(id)
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
    return self._Model:GetArchiveWeaponServerDataById(templateId) ~= nil
end


-- 武器new标签
function XArchiveAgency:IsNewWeapon(templateId)
    local isNew = false
    if not self._Model:GetWeaponUnlockServerData(templateId) and self._Model:GetArchiveWeaponServerDataById(templateId) then
        isNew = true
    end

    return isNew
end


-- 武器图鉴是否有new标签
function XArchiveAgency:IsHaveNewWeapon()
    return self._Model:GetWeaponTotalRedPointCount() > 0
end

-- 武器图鉴是否有红点
function XArchiveAgency:IsNewWeaponSetting(templateId)
    local newSettingList = self._Model:GetNewWeaponSettingIdListById(templateId)
    if newSettingList and #newSettingList > 0 then
        return true
    end
    return false
end


-- 武器图鉴是否有红点
function XArchiveAgency:IsHaveNewWeaponSetting()
    return self._Model:GetWeaponSettingTotalRedPointCount() > 0
end

function XArchiveAgency:IsEquipGet(templateId)
    return self:IsWeaponGet(templateId) or self.AwarenessArchiveCom:IsAwarenessGet(templateId)
end

function XArchiveAgency:GetEquipLv(templateId)
    local data = self._Model:GetArchiveWeaponServerDataById(templateId) or self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId)
    return data and data.Level or 0
end

function XArchiveAgency:GetEquipBreakThroughTimes(templateId)
    local data = self._Model:GetArchiveWeaponServerDataById(templateId) or self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId)
    return data and data.Breakthrough or 0
end


-- 从服务端获取武器和意识相关数据
function XArchiveAgency:SetEquipServerData(equipData)
    self._Model.ArchiveAwarenessData:ClearAwarenessSuitToAwarenessCountDic()
    local templateId
    local suitId
    --只有在配置表中出现id才会记录在本地的serverData
    for _, data in ipairs(equipData) do
        templateId = data.Id
        if XMVCA.XEquip:IsEquipWeapon(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            self._Model:SetWeaponServerDataById(templateId,data)
        elseif XMVCA.XEquip:IsEquipAwareness(templateId) and self._Model.ArchiveAwarenessData:GetAwarenessShowedStatusDic()[templateId] then
            self._Model.ArchiveAwarenessData:SetAwarenessServerDataById(templateId,data)
            suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
            self._Model.ArchiveAwarenessData:AddAwarenessSuitToAwarenessCountById(suitId,1)
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
        if XMVCA.XEquip:IsEquipWeapon(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            weaponType = XMVCA.XEquip:GetEquipType(templateId)
            if not self._Model:GetWeaponUnlockServerData(templateId) then
                weaponIdList = weaponIdList or {}
                tableInsert(weaponIdList, templateId)
                if not self._Model:GetArchiveWeaponServerDataById(templateId) then
                    self._Model:AddWeaponRedPointCountByType(weaponType,1)
                    self._Model:AddWeaponTotalRedPointCount(1)
                end
            end
            self._Model:SetWeaponServerDataById(templateId,data)
            settingDataList = self:GetWeaponSettingList(templateId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                conditionId = settingData.Condition
                if not self._Model:GetWeaponSettingUnlockServerDataById(settingId) then
                    if not self._Model:GetWeaponSettingCanUnlockById(settingId) and self:CheckConditions(conditionId, templateId) then
                        isNewWeaponSetting = true
                        self._Model:SetWeaponSettingCanUnlockById(settingId, true)
                        self._Model:InsertNewWeaponSettingIdsDicById(templateId,settingId)
                        self._Model:AddWeaponSettingRedPointCountByType(weaponType, 1)
                        self._Model:AddWeaponSettingTotalRedPointCount(1)
                    end
                end
            end

        elseif XMVCA.XEquip:IsEquipAwareness(templateId) and self._Model.ArchiveAwarenessData:GetAwarenessShowedStatusDic()[templateId] then
            suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
            updateSuitIdDic = updateSuitIdDic or {}
            updateSuitIdDic[suitId] = true
            if not self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId) then
                if not self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountById(suitId) and self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(suitId) then
                    awarenessSuitIdList = awarenessSuitIdList or {}
                    tableInsert(awarenessSuitIdList, suitId)
                    self._Model.ArchiveAwarenessData:SetAwarenessSuitNewGetReddot(suitId)
                end
                self._Model.ArchiveAwarenessData:AddAwarenessSuitToAwarenessCountById(suitId,1)
            end

            self._Model.ArchiveAwarenessData:SetAwarenessServerDataById(templateId,data)
        end
    end

    if updateSuitIdDic then
        for tmpSuitId, _ in pairs(updateSuitIdDic) do
            if self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(tmpSuitId) then
                settingDataList = self.AwarenessArchiveCom:GetAwarenessSettingList(tmpSuitId)
                for _, settingData in ipairs(settingDataList) do
                    settingId = settingData.Id
                    conditionId = settingData.Condition

                    if not self._Model.ArchiveAwarenessData:GetAwarenessSettingUnlockServerDataById(settingId) and
                            not self._Model.ArchiveAwarenessData:GetAwarenessSettingCanUnlockById(settingId) and
                            XConditionManager.CheckCondition(conditionId, tmpSuitId) then

                        isNewAwarenessSetting = true
                        self._Model.ArchiveAwarenessData:SetAwarenessSettingNewGetReddot(settingId)

                    end
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

function XArchiveAgency:CreateRedPointCountDicAll()
    local weaponType
    for id, _ in pairs(self._Model:GetArchiveWeaponServerData()) do
        if not self._Model:GetWeaponUnlockServerData(id) then
            weaponType = XMVCA.XEquip:GetEquipType(id)
            if weaponType then
                self._Model:AddWeaponRedPointCountByType(weaponType, 1)
                self._Model:AddWeaponTotalRedPointCount(1)
            end
        end
    end

    local settingDataList
    local settingId
    for weaponId, _ in pairs(self._Model:GetWeaponTemplateIdToSettingListDic()) do
        settingDataList = self:GetWeaponSettingList(weaponId)
        for _, settingData in ipairs(settingDataList) do
            settingId = settingData.Id
            if not self._Model:GetWeaponSettingUnlockServerDataById(settingId) and self:CheckConditions(settingData.Condition, weaponId) then
                self._Model:SetWeaponSettingCanUnlockById(settingId, true)
                weaponType = XMVCA.XEquip:GetEquipType(weaponId)
                self._Model:InsertNewWeaponSettingIdsDicById(weaponId,settingId)
                self._Model:AddWeaponSettingRedPointCountByType(weaponType, 1)
                self._Model:AddWeaponSettingTotalRedPointCount(1)
            end
        end
    end

    self.AwarenessArchiveCom:CreateRedPointCountDic()
end

function XArchiveAgency:RequestUnlockWeapon(idList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveWeaponRequest, {Ids = idList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local weaponType
            for _, id in ipairs(successIdList) do
                self._Model:SetWeaponUnlockServerDataById(id, true)
                weaponType = XMVCA.XEquip:GetEquipType(id)
                self._Model:SetWeaponRedPointCountByType(weaponType, self._Model:GetWeaponRedPointCountByType(weaponType) - 1)
            end
            self._Model:SetWeaponTotalRedPointCount(self._Model:GetWeaponTotalRedPointCount() - #successIdList)

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON)
        end
    end)
end

function XArchiveAgency:RequestUnlockWeaponSetting(settingIdList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockWeaponSettingRequest, {Ids = settingIdList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local templateId
            local weaponType
            local newWeaponSettingIdList
            for _, id in ipairs(successIdList) do
                self._Model:SetWeaponSettingUnlockServerDataById(id, true)
                self._Model:SetWeaponSettingCanUnlockById(id, nil)
                templateId = self._Model:GetWeaponSetting()[id].EquipId
                weaponType = XMVCA.XEquip:GetEquipType(templateId)
                self._Model:SetWeaponSettingRedPointCountByType(weaponType, self._Model:GetNewWeaponSettingByWeaponType(weaponType) - 1)
                newWeaponSettingIdList = self._Model:GetNewWeaponSettingIdListById(templateId)
                if newWeaponSettingIdList then
                    for index, settingId in ipairs(newWeaponSettingIdList) do
                        if id == settingId then
                            table.remove(newWeaponSettingIdList, index)
                            break
                        end
                    end
                    if #newWeaponSettingIdList == 0 then
                        self._Model:SetNewWeaponSettingIdsDicById(templateId, nil)
                    end
                end
            end
            self._Model:SetWeaponSettingTotalRedPointCount(self._Model:GetWeaponSettingTotalRedPointCount() - #successIdList)

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
        end
    end)
end

--endregion

--region -------------剧情相关------------->>>

function XArchiveAgency:GetArchiveStoryDetailList(chapterId)--chapterId为空时不作为判断条件
    if chapterId then
        return self._Model:GetArchiveStoryDetailList()[chapterId] or {}
    end
    local list = {}
    local pairList = self._Model:GetArchiveStoryDetailList()
    if not XTool.IsTableEmpty(pairList) then
        for _,group in pairs(pairList) do
            for _,detail in pairs(group) do
                tableInsert(list,detail)
            end
        end
    end
    return self._Model:SortByOrder(list)
end
--endregion

--region -------------CG相关------------->>>

function XArchiveAgency:GetArchiveCgEntity(id)
    return self._Model:GetArchiveCGDetailData()[id]
end

function XArchiveAgency:UpdateCGAllList()--更新图鉴Npc数据
    local detailList = self._Model:GetArchiveCGDetailList()
    if not XTool.IsTableEmpty(detailList) then
        for _,group in pairs(detailList) do
            ---@param CGDetail XArchiveCGEntity
            for _,CGDetail in pairs(group) do
                local lockDes = ""
                local IsUnLock = ""
                if self._Model:GetShowedCGListById(CGDetail:GetId()) then
                    IsUnLock = true
                else
                    if CGDetail:GetCondition() ~= 0 then
                        _,lockDes = XConditionManager.CheckCondition(CGDetail:GetCondition())
                    end
                    IsUnLock = false
                end

                CGDetail:SetIsLock(not IsUnLock)
                CGDetail:SetLockDesc(lockDes)
            end
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
--endregion

--region --------------------------------伙伴图鉴相关------------------------------------------>>>

function XArchiveAgency:UpdateArchivePartnerList()--更新图鉴伙伴数据
    local partenrList = self._Model:GetArchivePartnerList()
    if not XTool.IsTableEmpty(partenrList) then
        for _,group in pairs(partenrList) do
            ---@param partner XArchivePartnerEntity
            for _,partner in pairs(group) do
                local IsUnLock = false
                if self._Model:GetPartnerUnLockById(partner:GetTemplateId()) then
                    IsUnLock = true
                end
                partner:SetIsLock(not IsUnLock)
            end
        end
    end
end

function XArchiveAgency:UpdateArchivePartnerSettingList()--更新图鉴伙伴设定数据
    local data=self._Model:GetPartnerUnLockSettingDic()
    local partnerList = self._Model:GetArchivePartnerList()
    if not XTool.IsTableEmpty(partnerList) then
        for _,group in pairs(partnerList) do
            for _,partner in pairs(group) do
                partner:UpdateStoryAndSettingEntity(data)
            end
        end
    end
end

function XArchiveAgency:CheckArchiveMailUnlock(archiveMailId)
    return self._Model:GetUnlockArchiveMailById(archiveMailId)
end

function XArchiveAgency:GetPartnerUnLockById(templateId)
    return self._Model:GetPartnerUnLockById(templateId)
end

function XArchiveAgency:GetPartnerSettingUnLockDic()
    return self._Model:GetPartnerUnLockSettingDic()
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

function XArchiveAgency:CheckConditions(conditionIds,...)
    if not XTool.IsTableEmpty(conditionIds) then
        for i, v in pairs(conditionIds) do
            if XConditionManager.CheckCondition(v, ...) then
                return true
            end
        end
    end
    return false
end

----------private end----------

return XArchiveAgency