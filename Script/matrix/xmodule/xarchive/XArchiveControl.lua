---@class XArchiveControl : XControl
---@field private _Model XArchiveModel
local XArchiveControl = XClass(XControl, "XArchiveControl")
local tableInsert=table.insert
function XArchiveControl:OnInit()
    --初始化内部变量
end

function XArchiveControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XArchiveControl:RemoveAgencyEvent()

end

function XArchiveControl:OnRelease()

end

--进度大于0小于1时固定返回1，否则返回向下取整的进度
function XArchiveControl:GetPercent(percent)
    return (percent > 0 and percent < 1) and 1 or math.floor(percent)
end

function XArchiveControl:GetCountUnitChange(count)
    local newCount = count
    if count >= 1000 then
        newCount = count / 1000
    else
        return newCount
    end
    local a, b = math.modf(newCount)
    return b >= 0.05 and string.format("%.1fk", newCount) or string.format("%dk", a)
end

--region --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>
function XArchiveControl:GetArchiveMonsterEvaluate(npcId)
    return self._Model._ArchiveMonsterEvaluateList[npcId] or {}
end

function XArchiveControl:GetArchiveMonsterMySelfEvaluate(npcId)
    return self._Model._ArchiveMonsterMySelfEvaluateList[npcId] or {}
end

function XArchiveControl:GetArchiveMonsterEvaluateList()
    return self._Model._ArchiveMonsterEvaluateList
end

function XArchiveControl:GetArchiveMonsterMySelfEvaluateList()
    return self._Model._ArchiveMonsterMySelfEvaluateList
end

function XArchiveControl:GetArchives()------------------------------------修改技能设定等的条件判定
    local list = {}
    for _, v in pairs(self._Model:GetArchive()) do
        local SkipFunctional = XFunctionConfig.GetSkipList(v.SkipId)
        if SkipFunctional and not XFunctionManager.CheckFunctionFitter(SkipFunctional.FunctionalId) then
            table.insert(list, v)
        end
    end
    return list
end

function XArchiveControl:GetMonsterArchiveName(monster)
    if monster:GetName() then
        return monster:GetName()
    end
    if monster:GetNpcId(1) then
        return XMVCA.XArchive:GetMonsterRealName(monster:GetNpcId(1))
    end
    return "NULL"
end

function XArchiveControl:GetArchiveTagList(group)
    return self._Model:GetArchiveTagAllList()[group]
end

function XArchiveControl:GetArchiveMonsterList(type)--type为空时不作为判断条件，获取相应类型的图鉴怪物列表
    if type then
        return self._Model:GetArchiveMonsterList()[type] or {}
    end
    local list = {}
    for _,tmpType in pairs(self._Model:GetArchiveMonsterList()) do
        for _,monster in pairs(tmpType) do
            tableInsert(list,monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetArchiveMonsterInfoList(groupId,type)--type为空时不作为判断条件，获取相应类型的图鉴怪物信息列表
    if type then
        return self._Model:GetArchiveMonsterInfoList()[groupId] and self._Model:GetArchiveMonsterInfoList()[groupId][type] or {}
    end
    local list = {}
    for _,tmpType in pairs(self._Model:GetArchiveMonsterInfoList()[groupId]) do
        for _,monster in pairs(tmpType) do
            tableInsert(list,monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetArchiveMonsterSkillList(groupId)--groupId为空时不作为判断条件，获取相应类型的图鉴怪物技能列表
    if groupId then
        return self._Model:GetArchiveMonsterSkillList()[groupId] or {}
    end
    local list = {}
    for _,group in pairs(self._Model:GetArchiveMonsterSkillList()) do
        for _,monster in pairs(group) do
            tableInsert(list,monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetArchiveMonsterSettingList(groupId,type)--type为空时不作为判断条件，获取相应类型的图鉴怪物设定列表
    if type then
        return self._Model:GetArchiveMonsterSettingList()[groupId] and self._Model:GetArchiveMonsterSettingList()[groupId][type] or {}
    end
    local list = {}
    for _,tmpType in pairs(self._Model:GetArchiveMonsterSettingList()[groupId]) do
        for _,monster in pairs(tmpType) do
            tableInsert(list,monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetMonsterCompletionRate(type)
    local monsterList = self:GetArchiveMonsterList(type)
    if #monsterList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(monsterList or {}) do
        if not v.IsLockMain then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount / #monsterList) * 100)
end

function XArchiveControl:SetArchiveMonsterMySelfEvaluateLikeStatus(npcId,likeState)
    if not self._Model._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._Model._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._Model._ArchiveMonsterMySelfEvaluateList[npcId].LikeStatus = likeState
end

function XArchiveControl:SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
    if not self._Model._ArchiveMonsterMySelfEvaluateList[npcId] then
        self._Model._ArchiveMonsterMySelfEvaluateList[npcId] ={}
    end
    self._Model._ArchiveMonsterMySelfEvaluateList[npcId].Score = score
    self._Model._ArchiveMonsterMySelfEvaluateList[npcId].Difficulty = difficulty
    self._Model._ArchiveMonsterMySelfEvaluateList[npcId].Tags = tags
end

function XArchiveControl:MonsterGiveEvaluate(npcId ,score ,difficulty ,tags ,cbBeFore ,cbAfter)
    local type = XEnumConst.Archive.SubSystemType.Monster
    local tb = {Id = npcId ,Type = type ,Score = score ,Difficulty = difficulty ,Tags = tags}
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveEvaluateRequest, tb, function(res)
        if cbBeFore then cbBeFore() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
        if cbAfter then cbAfter() end
    end)
end

function XArchiveControl:MonsterGiveLike(likeList ,cb)
    local type = XEnumConst.Archive.SubSystemType.Monster
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveGiveLikeRequest, {LikeList = likeList ,Type = type}, function(res)
        if cb then cb() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        for _,id in pairs(res.SuccessIds or {}) do
            for _,like in pairs(likeList or {}) do
                if id == like.Id then
                    self:SetArchiveMonsterMySelfEvaluateLikeStatus(id,like.LikeStatus)
                end
            end
        end
    end)
end

function XArchiveControl:UnlockArchiveMonster(ids,cb)
    local list = {}
    for _,id in pairs(ids or {}) do
        if not self._Model._ArchiveMonsterUnlockIdsList[id] then
            tableInsert(list,id)
        end
    end
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveMonsterRequest, {Ids = list}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XArchiveControl:UnlockMonsterInfo(ids,cb)
    local list = {}
    for _,id in pairs(ids or {}) do
        if not self._Model._ArchiveMonsterInfoUnlockIdsList[id] then
            tableInsert(list,id)
        end
    end
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterInfoRequest, {Ids = ids}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XArchiveControl:UnlockMonsterSkill(ids,cb)
    local list = {}
    for _,id in pairs(ids or {}) do
        if not self._Model._ArchiveMonsterSkillUnlockIdsList[id] then
            tableInsert(list,id)
        end
    end
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterSkillRequest, {Ids = ids}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XArchiveControl:UnlockMonsterSetting(ids,cb)
    local list = {}
    for _,id in pairs(ids or {}) do
        if not self._Model._ArchiveMonsterSettingUnlockIdsList[id] then
            tableInsert(list,id)
        end
    end
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterSettingRequest, {Ids = ids}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XArchiveControl:ClearMonsterRedPointDic(monsterId,type)
    local monsterType = XMVCA.XArchive:GetArchiveMonsterType(monsterId)
    if not monsterType then return end
    if not self._Model._MonsterRedPointDic[monsterType] then return end
    if not self._Model._MonsterRedPointDic[monsterType][monsterId] then return end
    if type == XEnumConst.Archive.MonsterRedPointType.Monster then
        self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewMonster = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterInfo then
        self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewInfo = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSkill then
        self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSkill = false
    elseif type == XEnumConst.Archive.MonsterRedPointType.MonsterSetting then
        self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSetting = false
    end
    if not self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewMonster and
            not self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewInfo and
            not self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSkill and
            not self._Model._MonsterRedPointDic[monsterType][monsterId].IsNewSetting then

        self._Model._MonsterRedPointDic[monsterType][monsterId] = nil
    end
end

function XArchiveControl:ClearMonsterNewTag(datas)
    local idList = {}

    if not datas then
        return
    end

    local IsHasNew = false
    for _,data in pairs(datas) do
        if XMVCA.XArchive:IsMonsterHaveNewTagById(data.Id) then
            IsHasNew = true
            break
        end
    end
    if not IsHasNew then return end

    for _,data in pairs(datas) do
        if not data.IsLockMain then
            tableInsert(idList,data.Id)
        end
    end

    if #idList < 1 then
        return
    end

    self:UnlockArchiveMonster(idList,function ()
        for _,id in pairs(idList) do
            self:ClearMonsterRedPointDic(id,XEnumConst.Archive.MonsterRedPointType.Monster)
        end
        XMVCA.XArchive:SetArchiveMonsterUnlockIdsList(idList)
        XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER)
    end)
end

function XArchiveControl:ClearDetailRedPoint(type,datas)
    local idList = {}
    if not datas then
        return
    end
    --------------------检测各类型是否有新增记录------------------
    if type == XEnumConst.Archive.MonsterDetailType.Info then
        local IsHasNew = false
        for _,data in pairs(datas) do
            if XMVCA.XArchive:IsHaveNewMonsterInfoByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        local IsHasNew = false
        for _,data in pairs(datas) do
            if XMVCA.XArchive:IsHaveNewMonsterSettingByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        local IsHasNew = false
        for _,data in pairs(datas) do
            if XMVCA.XArchive:IsHaveNewMonsterSkillByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    end
    --------------------将各类型新增记录的ID放入一个List------------------
    for _,data in pairs(datas) do
        for _,npcId in pairs(data:GetNpcId() or {}) do
            if type == XEnumConst.Archive.MonsterDetailType.Info then
                local list = self:GetArchiveMonsterInfoList(npcId,nil)
                for _,info in pairs(list or {}) do
                    if not info:GetIsLock() then
                        tableInsert(idList,info:GetId())
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
                local list = self:GetArchiveMonsterSettingList(npcId,nil)
                for _,setting in pairs(list or {}) do
                    if not setting:GetIsLock() then
                        tableInsert(idList,setting:GetId())
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
                local list = self:GetArchiveMonsterSkillList(npcId)
                for _,skill in pairs(list or {}) do
                    if not skill:GetIsLock() then
                        tableInsert(idList,skill:GetId())
                    end
                end
            end
        end
    end

    if #idList < 1 then
        return
    end
    --------------------将各类型新增记录的红点取消通知服务器------------------
    if type == XEnumConst.Archive.MonsterDetailType.Info then
        self:UnlockMonsterInfo(idList,function ()
            for _,data in pairs(datas) do
                self:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterInfo)
            end
            XMVCA.XArchive:SetArchiveMonsterInfoUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        self:UnlockMonsterSetting(idList,function ()
            for _,data in pairs(datas) do
                self:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterSetting)
            end
            XMVCA.XArchive:SetArchiveMonsterSettingUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        self:UnlockMonsterSkill(idList,function ()
            for _,data in pairs(datas) do
                self:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterSkill)
            end
            XMVCA.XArchive:SetArchiveMonsterSkillUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL)
        end)
    end
end
--endregion

--region -------------------武器、意识部分------------------->>>
function XArchiveControl:GetWeaponCollectRate()
    local sumNum = self._Model:GetWeaponSumCollectNum()
    if sumNum == 0 then
        return 0
    end
    local haveNum = 0
    for _, _ in pairs(self._Model._ArchiveWeaponServerData) do
        haveNum = haveNum + 1
    end
    return self:GetPercent(haveNum * 100 / sumNum)
end

-- 某个武器类型下是否有new标签
function XArchiveControl:IsHaveNewWeaponByWeaponType(type)
    return self._Model._ArchiveWeaponRedPointCountDic[type] > 0
end

function XArchiveControl:IsWeaponSettingOpen(settingId)
    return self._Model._ArchiveWeaponSettingUnlockServerData[settingId] or self._Model._ArchiveWeaponSettingCanUnlockDic[settingId] == true
end

-- 武器设定有红点的列表,列表可能为空
function XArchiveControl:GetNewWeaponSettingIdList(templateId)
    return self._Model._ArchiveNewWeaponSettingIdsDic[templateId]
end

-- 某个武器类型下是否有红点
function XArchiveControl:IsHaveNewWeaponSettingByWeaponType(type)
    return self._Model._ArchiveWeaponSettingRedPointCountDic[type] > 0
end

function XArchiveControl:GetAwarenessCollectRate()
    local sumNum = self._Model:GetAwarenessSumCollectNum()
    if sumNum == 0 then
        return 0
    end
    local haveNum = 0
    for _, _ in pairs(self._Model._ArchiveAwarenessServerData) do
        haveNum = haveNum + 1
    end
    return self:GetPercent(haveNum * 100 / sumNum)
end

-- 某个意识的获得类型下是否有new标签
function XArchiveControl:IsHaveNewAwarenessSuitByGetType(type)
    return self._Model._ArchiveAwarenessSuitRedPointCountDic[type] > 0
end

function XArchiveControl:IsAwarenessSettingOpen(settingId)
    return self._Model._ArchiveAwarenessSettingUnlockServerData[settingId] or self._Model._ArchiveAwarenessSettingCanUnlockDic[settingId] == true
end

-- 有红点的意识列表
function XArchiveControl:GetNewAwarenessSettingIdList(suitId)
    return self._Model._ArchiveNewAwarenessSettingIdsDic[suitId]
end

-- 意识的获得类型下是否有红点
function XArchiveControl:IsHaveNewAwarenessSettingByGetType(type)
    return self._Model._ArchiveAwarenessSettingRedPointCountDic[type] > 0
end

function XArchiveControl:RequestUnlockWeapon(idList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveWeaponRequest, {Ids = idList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local weaponType
            for _, id in ipairs(successIdList) do
                self._Model._ArchiveWeaponUnlockServerData[id] = true
                weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(id)
                self._Model._ArchiveWeaponRedPointCountDic[weaponType] = self._Model._ArchiveWeaponRedPointCountDic[weaponType] - 1
            end
            self._Model._ArchiveWeaponTotalRedPointCount = self._Model._ArchiveWeaponTotalRedPointCount - #successIdList

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON)
        end
    end)
end

function XArchiveControl:RequestUnlockAwarenessSuit(idList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveAwarenessRequest, {Ids = idList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local awarenessGetType
            for _, id in ipairs(successIdList) do
                self._Model._ArchiveAwarenessSuitUnlockServerData[id] = true
                awarenessGetType = self._Model:GetArchiveAwarenessGroup()[id].Type
                self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = self._Model._ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] - 1
            end
            self._Model._ArchiveAwarenessSuitTotalRedPointCount = self._Model._ArchiveAwarenessSuitTotalRedPointCount - #successIdList

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SUIT)
        end
    end)
end

function XArchiveControl:CheckWeaponsCollectionLevelUp(type,curLevel)
    local oldlevel = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type))
    if not oldlevel then
        XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), curLevel)
        return false
    else
        if curLevel > oldlevel then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), curLevel)
            return true, oldlevel
        else
            return false
        end
    end
end

function XArchiveControl:SaveWeaponsCollectionDefaultData(type,level)
    local oldlevel = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type))
    if not oldlevel then
        XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), level)
    end
end

function XArchiveControl:RequestUnlockWeaponSetting(settingIdList)
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
                self._Model._ArchiveWeaponSettingUnlockServerData[id] = true
                self._Model._ArchiveWeaponSettingCanUnlockDic[id] = nil
                templateId = self._Model:GetWeaponSetting()[id].EquipId
                weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(templateId)
                self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] = self._Model._ArchiveWeaponSettingRedPointCountDic[weaponType] - 1
                newWeaponSettingIdList = self._Model._ArchiveNewWeaponSettingIdsDic[templateId]
                if newWeaponSettingIdList then
                    for index, settingId in ipairs(newWeaponSettingIdList) do
                        if id == settingId then
                            table.remove(newWeaponSettingIdList, index)
                            break
                        end
                    end
                    if #newWeaponSettingIdList == 0 then
                        self._Model._ArchiveNewWeaponSettingIdsDic[templateId] = nil
                    end
                end
            end
            self._Model._ArchiveWeaponSettingTotalRedPointCount = self._Model._ArchiveWeaponSettingTotalRedPointCount - #successIdList

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
        end
    end)
end

function XArchiveControl:HandleCanUnlockWeaponSettingByWeaponType(type)
    local isHaveNew = self:IsHaveNewWeaponSettingByWeaponType(type)
    if not isHaveNew then return end
    local idList = {}
    local needCheckIdList = self._Model:GetWeaponTypeToIdsDic()[type]
    for _, templateId in ipairs(needCheckIdList) do
        if self._Model._ArchiveNewWeaponSettingIdsDic[templateId] then
            for _, id in ipairs(self._Model._ArchiveNewWeaponSettingIdsDic[templateId]) do
                tableInsert(idList, id)
            end
        end
    end
    self:RequestUnlockWeaponSetting(idList)
end

function XArchiveControl:RequestUnlockAwarenessSetting(settingIdList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockAwarenessSettingRequest, {Ids = settingIdList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local suitId
            local getType
            local newAwarenessSettingIdList
            for _, id in ipairs(successIdList) do
                self._Model._ArchiveAwarenessSettingUnlockServerData[id] = true
                self._Model._ArchiveAwarenessSettingCanUnlockDic[id] = nil
                suitId = self._Model:GetAwarenessSetting()[id].SuitId
                getType = self._Model:GetArchiveAwarenessGroup()[suitId].Type
                self._Model._ArchiveAwarenessSettingRedPointCountDic[getType] = self._Model._ArchiveAwarenessSettingRedPointCountDic[getType] - 1
                newAwarenessSettingIdList = self._Model._ArchiveNewAwarenessSettingIdsDic[suitId]
                if newAwarenessSettingIdList then
                    for index, settingId in ipairs(newAwarenessSettingIdList) do
                        if id == settingId then
                            table.remove(newAwarenessSettingIdList, index)
                            break
                        end
                    end
                    if #newAwarenessSettingIdList == 0 then
                        self._Model._ArchiveNewAwarenessSettingIdsDic[suitId] = nil
                    end
                end
            end
            self._Model._ArchiveAwarenessSettingTotalRedPointCount = self._Model._ArchiveAwarenessSettingTotalRedPointCount - #successIdList
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
        end
    end)
end

function XArchiveControl:HandleCanUnlockAwarenessSettingByGetType(type)
    local isHaveNew = self:IsHaveNewAwarenessSettingByGetType(type)
    if not isHaveNew then return end
    local typeToGroupDatasDic = self._Model:GetAwarenessTypeToGroupDatasDic()
    local groupDataList = typeToGroupDatasDic[type]
    if groupDataList then
        local newSettingIdList
        local requestIdList = {}
        for _, groupData in ipairs(groupDataList) do
            newSettingIdList = self._Model._ArchiveNewAwarenessSettingIdsDic[groupData.Id]
            if newSettingIdList then
                for _, id in ipairs(newSettingIdList) do
                    tableInsert(requestIdList, id)
                end
            end
        end
        self:RequestUnlockAwarenessSetting(requestIdList)
    end
end

function XArchiveControl:HandleCanUnlockWeapon()
    local isHaveNew = XMVCA.XArchive:IsHaveNewWeapon()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model._ArchiveWeaponServerData) do
            if XMVCA.XArchive:IsNewWeapon(id) then
                table.insert(idList, id)
            end
        end
        self:RequestUnlockWeapon(idList)
    end
end

function XArchiveControl:HandleCanUnlockWeaponByWeaponType(type)
    local isHaveNew = self:IsHaveNewWeaponByWeaponType(type)
    if isHaveNew then
        local idList = {}
        local needCheckIdList = self._Model:GetWeaponTypeToIdsDic()[type]
        if needCheckIdList then
            for _, id in ipairs(needCheckIdList) do
                if XMVCA.XArchive:IsNewWeapon(id) then
                    table.insert(idList, id)
                end
            end
            self:RequestUnlockWeapon(idList)
        end
    end
end

function XArchiveControl:HandleCanUnlockAwarenessSuit()
    local isHaveNew = XMVCA.XArchive:IsHaveNewAwarenessSuit()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model._ArchiveAwarenessSuitToAwarenessCountDic) do
            if XMVCA.XArchive:IsNewAwarenessSuit(id) then
                table.insert(idList, id)
            end
        end
        self:RequestUnlockAwarenessSuit(idList)
    end
end

function XArchiveControl:HandleCanUnlockAwarenessSuitByGetType(type)
    local isHaveNew = self:IsHaveNewAwarenessSuitByGetType(type)
    if isHaveNew then
        local typeToGroupDatasDic = self._Model:GetAwarenessTypeToGroupDatasDic()
        local groupDataList = typeToGroupDatasDic[type]
        if groupDataList then
            local newSettingId
            local requestIdList = {}
            for _, groupData in ipairs(groupDataList) do
                newSettingId = groupData.Id
                if XMVCA.XArchive:IsNewAwarenessSuit(newSettingId) then
                    tableInsert(requestIdList, newSettingId)
                end
            end
            self:RequestUnlockAwarenessSuit(requestIdList)
        end
    end
end

function XArchiveControl:HandleCanUnlockWeaponSetting()
    local isHaveNew = XMVCA.XArchive:IsHaveNewWeaponSetting()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model._ArchiveWeaponSettingCanUnlockDic) do
            tableInsert(idList, id)
        end
        self:RequestUnlockWeaponSetting(idList)
    end
end

function XArchiveControl:HandleCanUnlockAwarenessSetting()
    local isHaveNew = XMVCA.XArchive:IsHaveNewAwarenessSetting()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model._ArchiveAwarenessSettingCanUnlockDic) do
            tableInsert(idList, id)
        end
        self:RequestUnlockAwarenessSetting(idList)
    end
end
--endregion

--region -------------剧情相关------------->>>

function XArchiveControl:GetArchiveStoryGroupList()
    return self._Model:GetArchiveStoryGroupAllList()
end

function XArchiveControl:GetArchiveStoryChapter(chapterId)
    return self._Model:GetArchiveStoryChapterDic()[chapterId]
end


function XArchiveControl:GetArchiveStoryChapterList(groupId)--groupId为空时不作为判断条件
    if groupId then
        return self._Model:GetArchiveStoryChapterList()[groupId] or {}
    end
    local list = {}
    for _,group in pairs(self._Model:GetArchiveStoryChapterList() or {}) do
        for _,chapter in pairs(group) do
            tableInsert(list,chapter)
        end
    end
    return self._Model:SortByOrder(list)
end


function XArchiveControl:UpdateStoryDetailList()--更新图鉴剧情详细列表数据
    for _,detailList in pairs(self._Model:GetArchiveStoryDetailList() or {}) do
        for _,detail in pairs(detailList or {}) do
            local IsUnLock = false
            local lockDes = ""
            local nowTime = XTime.GetServerNowTimestamp()
            local unLockTime = detail:GetUnLockTime() and XTime.ParseToTimestamp(detail:GetUnLockTime()) or 0
            local IsPassCondition = ((unLockTime ~= 0) and (nowTime > unLockTime)) or self._Model._ArchiveShowedStoryList[detail:GetId()]
            if detail:GetCondition()  == 0 or IsPassCondition then
                IsUnLock = true
            else
                IsUnLock, lockDes = XConditionManager.CheckCondition(detail:GetCondition())
            end
            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            tmpData.LockDesc = lockDes
            detail:UpdateData(tmpData)
        end
    end
end

function XArchiveControl:GetStoryCollectRate()
    local storyDetailList = XMVCA.XArchive:GetArchiveStoryDetailList()
    if #storyDetailList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(storyDetailList or {}) do
        if not v:GetIsLock() then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#storyDetailList)*100)
end

function XArchiveControl:UpdateStoryData()
    self:UpdateStoryDetailList()
    self:UpdateStoryChapterList()
end

function XArchiveControl:UpdateStoryChapterList()--更新图鉴剧情关卡列表数据
    for _,chapterList in pairs(self._Model:GetArchiveStoryChapterList() or {}) do
        for _,chapter in pairs(chapterList or {}) do
            local IsUnLock = false
            local lockDes = CS.XTextManager.GetText("StoryArchiveErrorHint")
            local storyDetailList = XMVCA.XArchive:GetArchiveStoryDetailList(chapter:GetId())
            for _,detail in pairs(storyDetailList or {}) do
                IsUnLock = IsUnLock or (not detail:GetIsLock())
                if IsUnLock then
                    break
                end
            end
            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            local FirstIndex = 1
            local storyDetail = storyDetailList[FirstIndex]
            if storyDetail and storyDetail:GetLockDesc() then
                tmpData.LockDesc = storyDetail:GetLockDesc()
            else
                tmpData.LockDesc = lockDes
                XLog.Error("detail is nil or LockDesc is nil by chapterId:" .. chapter:GetId())
            end
            chapter:UpdateData(tmpData)
        end
    end
end
--endregion

--region -------------Npc相关------------->>>

function XArchiveControl:UpdateStoryNpcList()--更新图鉴Npc数据
    for _,npc in pairs(self._Model:GetArchiveStoryNpcList() or {}) do
        local IsUnLock = false
        local lockDes = ""
        local nowTime = XTime.GetServerNowTimestamp()
        local unLockTime = npc:GetUnLockTime() and XTime.ParseToTimestamp(npc:GetUnLockTime()) or 0
        local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)
        if npc:GetCondition() == 0 or IsPassCondition then
            IsUnLock = true
        else
            IsUnLock, lockDes = XConditionManager.CheckCondition(npc:GetCondition())
        end
        local tmpData = {}
        tmpData.IsLock = not IsUnLock
        tmpData.LockDesc = lockDes
        npc:UpdateData(tmpData)
    end
end

function XArchiveControl:UpdateStoryNpcSettingList()--更新图鉴NpcSetting数据
    for _,settingGroupList in pairs(self._Model:GetArchiveStoryNpcSettingList() or {}) do
        for _,settingList in pairs(settingGroupList or {}) do
            for _,setting in pairs(settingList or {}) do
                local IsUnLock
                local lockDes = ""
                local nowTime = XTime.GetServerNowTimestamp()
                local unLockTime = setting:GetUnLockTime() and XTime.ParseToTimestamp(setting:GetUnLockTime()) or 0
                local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)
                if setting:GetCondition() == 0 or IsPassCondition then
                    IsUnLock = true
                else
                    IsUnLock, lockDes = XConditionManager.CheckCondition(setting:GetCondition())
                end
                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                tmpData.LockDesc = lockDes
                setting:UpdateData(tmpData)
            end
        end
    end
end

function XArchiveControl:UpdateStoryNpcData()
    self:UpdateStoryNpcList()
    self:UpdateStoryNpcSettingList()
end

function XArchiveControl:GetArchiveStoryNpcList()
    return self._Model:GetArchiveStoryNpcList() or {}
end

function XArchiveControl:GetArchiveStoryNpcSettingList(group,type)--type为空时不作为判断条件，获取相应类型的图鉴Npc设定列表
    if type then
        return self._Model:GetArchiveStoryNpcSettingList()[group] and self._Model:GetArchiveStoryNpcSettingList()[group][type] or {}
    end
    local list = {}
    for _,settingList in pairs(self._Model:GetArchiveStoryNpcSettingList()[group]) do
        for _,setting in pairs(settingList) do
            tableInsert(list,setting)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetNPCCompletionRate()
    local npcList = self:GetArchiveStoryNpcList()
    if #npcList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(npcList or {}) do
        if not v:GetIsLock() then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#npcList)*100)
end
--endregion

--region -------------CG相关------------->>>

function XArchiveControl:ClearCGRedPointById(id)
    self:ClearCGRedPoint(id)
    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
end

function XArchiveControl:ClearCGRedPoint(id)
    if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
        XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id))
    end
end

function XArchiveControl:GetCGCompletionRate(type)
    local CGList = XMVCA.XArchive:GetArchiveCGDetailList(type)
    if #CGList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(CGList or {}) do
        if not v:GetIsLock() then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#CGList)*100)
end

function XArchiveControl:ClearCGRedPointByGroup(groupId)
    local list = XMVCA.XArchive:GetArchiveCGDetailList(groupId)
    for _,cgDetail in pairs(list) do
        self:ClearCGRedPoint(cgDetail:GetId())
    end
    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
end
--endregion

--region -------------邮件通讯相关------------->>>

function XArchiveControl:UpdateMailList()--更新邮件数据
    for _,group in pairs(self._Model:GetArchiveMailList() or {}) do
        for _,mail in pairs(group) do
            local IsUnLock = false
            local lockDes = ""
            local nowTime = XTime.GetServerNowTimestamp()
            local unLockTime = mail:GetUnLockTime() and XTime.ParseToTimestamp(mail:GetUnLockTime()) or 0
            local condition = mail:GetCondition() or 0

            if unLockTime == 0 and condition == 0 then
                IsUnLock = true
            end
            if condition ~= 0 then
                IsUnLock, lockDes = XConditionManager.CheckCondition(condition)
            end
            if unLockTime ~= 0 and nowTime > unLockTime then
                IsUnLock = true
            end

            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            tmpData.LockDesc = lockDes
            mail:UpdateData(tmpData)
        end
    end
end

function XArchiveControl:UpdateCommunicationList()--更新通讯数据
    for _,group in pairs(self._Model:GetArchiveCommunicationList() or {}) do
        for _,communication in pairs(group) do
            local IsUnLock = false
            local lockDes = ""
            local nowTime = XTime.GetServerNowTimestamp()
            local unLockTime = communication:GetUnLockTime() and XTime.ParseToTimestamp(communication:GetUnLockTime()) or 0
            local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)

            if communication:GetCondition() == 0 or IsPassCondition then
                --IsUnLock = XPlayer.IsCommunicationMark(communication:GetCommunicationId())
                -- 需求调整为时间到/未配置Condition则直接解锁
                IsUnLock = true
            else
                IsUnLock, lockDes = XConditionManager.CheckCondition(communication:GetCondition())
            end

            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            tmpData.LockDesc = lockDes
            communication:UpdateData(tmpData)
        end
    end
end

function XArchiveControl:UpdateMailAndCommunicationData()
    self:UpdateMailList()
    self:UpdateCommunicationList()
end

function XArchiveControl:GetArchiveCommunicationList(group)--group为空时不作为判断条件
    local list = {}
    if group then
        if self._Model:GetArchiveCommunicationList() and self._Model:GetArchiveCommunicationList()[group] then
            for _,communication in pairs(self._Model:GetArchiveCommunicationList()[group]) do
                if not communication:GetIsLock() then
                    tableInsert(list,communication)
                end
            end
        end
        return self._Model:SortByOrder(list)
    end

    for _,communicationList in pairs(self._Model:GetArchiveCommunicationList()) do
        for _,communication in pairs(communicationList) do
            if not communication:GetIsLock() then
                tableInsert(list,communication)
            end
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetArchiveMailList(group)--group为空时不作为判断条件
    local list = {}
    if group then
        if self._Model:GetArchiveMailList() and self._Model:GetArchiveMailList()[group] then
            for _,mail in pairs(self._Model:GetArchiveMailList()[group]) do
                if not mail:GetIsLock() then
                    tableInsert(list,mail)
                end
            end
        end
        return self._Model:SortByOrder(list)
    end

    for _,mailList in pairs(self._Model:GetArchiveMailList()) do
        for _,mail in pairs(mailList) do
            if not mail:GetIsLock() then
                tableInsert(list,mail)
            end
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetEventDateGroupList()
    local list = {}
    for _,group in pairs(self._Model:GetEventDateGroup()) do
        local showTime = group.ShowTime
        local nowTime = XTime.GetServerNowTimestamp()
        local unlockTime = XTool.IsNumberValid(showTime) and XTime.ParseToTimestamp(showTime) or nowTime
        if unlockTime <= nowTime then
            list[group.GroupType] = list[group.GroupType] or {}
            tableInsert(list[group.GroupType],group)
        end
    end

    for _,group in pairs(list)do
        self._Model:SortByOrder(group)
    end

    return list
end
--endregion

--region --------------------------------伙伴图鉴相关------------------------------------------>>>

function XArchiveControl:GetPartnerGroupList()
    local list = {}
    local groupConfigs = self._Model:GetArchivePartnerGroup()
    for groupId,_ in pairs(self._Model:GetArchivePartnerList()) do
        if groupConfigs[groupId] then
            table.insert(list,groupConfigs[groupId])
        end
    end
    self._Model:SortByOrder(list)
    return list
end

function XArchiveControl:GetArchivePartnerList(group)
    if group then
        return self._Model._ArchivePartnerList[group] and self._Model._ArchivePartnerList[group] or {}
    end
    local list = {}
    for _,partnerGroup in pairs(self._Model:GetArchivePartnerList()) do
        for _,partner in pairs(partnerGroup) do
            tableInsert(list,partner)
        end
    end
    return self._Model:SortByOrder(list)
end

function XArchiveControl:GetPartnerCompletionRate(type)
    local partnerList = self:GetArchivePartnerList(type)
    if #partnerList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(partnerList or {}) do
        if not v:GetIsArchiveLock() then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#partnerList)*100)
end
--endregion

--region --------------------------------PV相关------------------------------------------>>>

--groupId为空时获得所有PV的解锁进度，否则获得对应组Id的PV解锁进度
function XArchiveControl:GetPVCompletionRate(groupId)
    local pvIdList = self:GetPVDetailIdList(groupId)
    if #pvIdList < 1 then
        return 0
    end
    local unlockCount = 0
    for _, pvDetailId in ipairs(pvIdList) do
        if self:GetPVUnLock(pvDetailId) then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount / #pvIdList) * 100)
end

function XArchiveControl:GetPVUnLock(pvDetailId)
    if self._Model._UnlockPvDetails[pvDetailId] then
        return true
    end

    local isUnLock, lockDes
    local unLockTime = self._Model:GetPVDetail()[pvDetailId].UnLockTime
    unLockTime = unLockTime and XTime.ParseToTimestamp(unLockTime) or 0
    local conditionId = self._Model:GetPVDetail()[pvDetailId].Condition

    if not XTool.IsNumberValid(unLockTime) and not XTool.IsNumberValid(conditionId) then
        isUnLock, lockDes = true, ""
    else
        if XTool.IsNumberValid(unLockTime) then
            local nowTime = XTime.GetServerNowTimestamp()
            isUnLock, lockDes = nowTime >= unLockTime, CS.XTextManager.GetText("ArchiveNotUnLockTime")
        end
        if not isUnLock and XTool.IsNumberValid(conditionId) then
            isUnLock, lockDes = XConditionManager.CheckCondition(conditionId)
        end
    end

    return isUnLock, lockDes
end

function XArchiveControl:GetPVGroups()
    local list = {}
    for _, group in pairs(self._Model:GetPVGroup()) do
        table.insert(list, group)
    end
    return self._Model:SortByOrder(list)
end
--endregion



--region -------------------------------配置表相关------------------------->>>

function XArchiveControl:GetArchiveTagCfgById(id)
    return self._Model:GetTag()[id]
end

function XArchiveControl:GetMonsterTransDataGroup(npcId)
    return self._Model:GetArchiveMonsterTransDic()[npcId]
end

function XArchiveControl:GetWeaponTemplateIdListByType(type)
    return self._Model:GetWeaponTypeToIdsDic()[type]
end

function XArchiveControl:GetAwarenessSuitInfoIconPath(suitId)
    return self._Model:GetArchiveAwarenessGroup()[suitId].IconPath
end

function XArchiveControl:GetWeaponSettingType(id)
    return self._Model:GetWeaponSetting()[id].Type
end

function XArchiveControl:GetWeaponTemplateIdBySettingId(id)
    return self._Model:GetWeaponSetting()[id].EquipId
end

function XArchiveControl:GetAwarenessSettingType(id)
    return self._Model:GetAwarenessSetting()[id].Type
end

function XArchiveControl:GetAwarenessSuitIdBySettingId(id)
    return self._Model:GetAwarenessSetting()[id].SuitId
end

local InitPVDetail = function(control)
    if control._Model._IsInitPVDetail then
        return
    end

    for id, v in pairs(control._Model:GetPVDetail()) do
        if not control._Model._PVGroupIdToDetailIdList[v.GroupId] then
            control._Model._PVGroupIdToDetailIdList[v.GroupId] = {}
        end
        table.insert(control._Model._PVGroupIdToDetailIdList[v.GroupId], id)
        table.insert(control._Model._PVDetailIdList, id)
    end
    for _, idList in pairs(control._Model._PVGroupIdToDetailIdList) do
        table.sort(idList, function(a, b)
            return a < b
        end)
    end

    control._Model._IsInitPVDetail = true
end

local GetPVDetailConfig = function(control,id)
    if not control._Model:GetPVDetail()[id] then
        XLog.Error("Id is not exist in Share/Archive/PVDetail.tab id = " .. id)
        return
    end
    return control._Model:GetPVDetail()[id]
end


function XArchiveControl:GetPVDetailIdList(groupId)
    InitPVDetail(self)
    return groupId and self._Model._PVGroupIdToDetailIdList[groupId] or self._Model._PVDetailIdList
end

function XArchiveControl:GetPVDetailName(id)
    local config = GetPVDetailConfig(self,id)
    return config.Name
end

function XArchiveControl:GetPVDetailBg(id)
    local config = GetPVDetailConfig(self,id)
    return config.Bg
end

function XArchiveControl:GetPVDetailLockBg(id)
    local config = GetPVDetailConfig(self,id)
    return config.LockBg
end

function XArchiveControl:GetPVDetailUnLockTime(id)
    local config = GetPVDetailConfig(self,id)
    return config.UnLockTime
end

function XArchiveControl:GetPVDetailCondition(id)
    local config = GetPVDetailConfig(self,id)
    return config.Condition
end

function XArchiveControl:GetPVDetailPv(id)
    local config = GetPVDetailConfig(self,id)
    return config.Pv
end

function XArchiveControl:GetPVDetailBgWidth(id)
    local config = GetPVDetailConfig(self,id)
    return config.BgWidth
end

function XArchiveControl:GetPVDetailBgHigh(id)
    local config = GetPVDetailConfig(self,id)
    return config.BgHigh
end

function XArchiveControl:GetPVDetailBgOffSetX(id)
    local config = GetPVDetailConfig(self,id)
    return config.BgOffSetX
end

function XArchiveControl:GetPVDetailBgOffSetY(id)
    local config = GetPVDetailConfig(self,id)
    return config.BgOffSetY
end

function XArchiveControl:GetWeaponTypeToIdsDic()
    return self._Model:GetWeaponTypeToIdsDic()
end

function XArchiveControl:GetAwarenessTypeToGroupDatasDic()
    return self._Model:GetAwarenessTypeToGroupDatasDic()
end

function XArchiveControl:GetStarToQualityName(site)
    return self._Model.SiteToBgPath[site]
end

function XArchiveControl:GetWeaponSettingPath()
    return self._Model:GetWeaponSetting()
end

function XArchiveControl:GetStarToQualityNameEnum()
    return self._Model.StarToQualityName
end

function XArchiveControl:GetEvaluateOnForAll()
    return self._Model.EvaluateOnForAll
end
--endregion
return XArchiveControl