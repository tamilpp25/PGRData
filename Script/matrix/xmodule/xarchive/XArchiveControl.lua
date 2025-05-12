---@class XArchiveControl : XControl
---@field private _Model XArchiveModel
local XArchiveControl = XClass(XControl, "XArchiveControl")
local tableInsert=table.insert
function XArchiveControl:OnInit()
    -- 初始化漫画图鉴子控制器
    ---@type XComicArchiveControl
    self.ComicControl = self:AddSubControl(require('XModule/XArchive/SubModule/ComicArchive/XComicArchiveControl'))
    ---@type XCGArchiveControl
    self.CGControl = self:AddSubControl(require('XModule/XArchive/SubModule/CGArchive/XCGArchiveControl'))
    ---@type XAwarenessArchiveControl
    self.AwarenessControl = self:AddSubControl(require('XModule/XArchive/SubModule/AwarenessArchive/XAwarenessArchiveControl'))
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
    return self._Model:GetArchiveMonsterEvaluate(npcId)
end

function XArchiveControl:GetArchiveMonsterMySelfEvaluate(npcId)
    return self._Model:GetArchiveMonsterMySelfEvaluate(npcId)
end

function XArchiveControl:GetArchiveMonsterEvaluateList()
    return self._Model:GetArchiveMonsterEvaluateList()
end

function XArchiveControl:GetArchiveMonsterMySelfEvaluateList()
    return self._Model:GetArchiveMonsterMySelfEvaluateList()
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
    local monsterInfoGroup = self._Model:GetArchiveMonsterInfoList()[groupId]
    if type then
        return monsterInfoGroup and monsterInfoGroup[type] or {}
    end
    local list = {}
    for _,tmpType in pairs(monsterInfoGroup) do
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
    local monsterSettingGroup = self._Model:GetArchiveMonsterSettingList()[groupId]
    if type then
        return monsterSettingGroup and monsterSettingGroup[type] or {}
    end
    local list = {}
    for _,tmpType in pairs(monsterSettingGroup) do
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
    if not XTool.IsTableEmpty(monsterList) then
        for _,v in pairs(monsterList) do
            if not v.IsLockMain then
                unlockCount = unlockCount + 1
            end
        end
    end
    return self:GetPercent((unlockCount / #monsterList) * 100)
end

function XArchiveControl:MonsterGiveEvaluate(npcId ,score ,difficulty ,tags ,cbBeFore ,cbAfter)
    local type = XEnumConst.Archive.SubSystemType.Monster
    local tb = {Id = npcId ,Type = type ,Score = score ,Difficulty = difficulty ,Tags = tags}
    local modelRefTmp = self._Model
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveEvaluateRequest, tb, function(res)
        if cbBeFore then cbBeFore() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        modelRefTmp:SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
        if cbAfter then cbAfter() end
    end)
end

function XArchiveControl:MonsterGiveLike(likeList ,cb)
    local type = XEnumConst.Archive.SubSystemType.Monster
    
    local modelRefTmp = self._Model
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveGiveLikeRequest, {LikeList = likeList ,Type = type}, function(res)
        if cb then cb() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        if XTool.IsTableEmpty(res.SuccessIds) or XTool.IsTableEmpty(likeList) then return end
        
        for _,id in pairs(res.SuccessIds) do
            for _,like in pairs(likeList) do
                if id == like.Id then
                    modelRefTmp:SetArchiveMonsterMySelfEvaluateLikeStatus(id,like.LikeStatus)
                end
            end
        end
    end)
end

function XArchiveControl:UnlockArchiveMonster(ids,cb)
    local list = self._Model:GetLockMonsterIdsFromIdList(ids)
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
    local list =self._Model:GetLockMonsterInfoIdsFromIdList(ids)
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
    local list = self._Model:GetLockMonsterSkillIdsFromIdList(ids)
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
    local list = self._Model:GetLockMonsterSettingIdsFromIdList(ids)
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
    
    -- 回调执行可能发生在Control销毁之后，使用局部变量引用Model
    local modelRef = self._Model
    self:UnlockArchiveMonster(idList,function ()
        for _,id in pairs(idList) do
            XMVCA.XArchive:ClearMonsterRedPointDic(id,XEnumConst.Archive.MonsterRedPointType.Monster)
        end
        modelRef:SetArchiveMonsterUnlockIdsList(idList)
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
        local npcIds = data:GetNpcId()
        if XTool.IsTableEmpty(npcIds) then
            goto continue
        end
        
        for _,npcId in pairs(npcIds) do
            if type == XEnumConst.Archive.MonsterDetailType.Info then
                local list = self:GetArchiveMonsterInfoList(npcId,nil)
                for _,info in pairs(list) do
                    if not info:GetIsLock() then
                        tableInsert(idList,info:GetId())
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
                local list = self:GetArchiveMonsterSettingList(npcId,nil)
                for _,setting in pairs(list) do
                    if not setting:GetIsLock() then
                        tableInsert(idList,setting:GetId())
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
                local list = self:GetArchiveMonsterSkillList(npcId)
                for _,skill in pairs(list) do
                    if not skill:GetIsLock() then
                        tableInsert(idList,skill:GetId())
                    end
                end
            end
        end
        :: continue ::
    end

    if #idList < 1 then
        return
    end
    --------------------将各类型新增记录的红点取消通知服务器-----------------
    local modelRefTmp = self._Model

    if type == XEnumConst.Archive.MonsterDetailType.Info then
        self:UnlockMonsterInfo(idList,function ()
            for _,data in pairs(datas) do
                XMVCA.XArchive:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterInfo)
            end
            modelRefTmp:SetArchiveMonsterInfoUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        self:UnlockMonsterSetting(idList,function ()
            for _,data in pairs(datas) do
                XMVCA.XArchive:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterSetting)
            end
            modelRefTmp:SetArchiveMonsterSettingUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        self:UnlockMonsterSkill(idList,function ()
            for _,data in pairs(datas) do
                XMVCA.XArchive:ClearMonsterRedPointDic(data:GetId(),XEnumConst.Archive.MonsterRedPointType.MonsterSkill)
            end
            modelRefTmp:SetArchiveMonsterSkillUnlockIdsList(idList)
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
    for _, _ in pairs(self._Model:GetArchiveWeaponServerData()) do
        haveNum = haveNum + 1
    end
    return self:GetPercent(haveNum * 100 / sumNum)
end

-- 某个武器类型下是否有new标签
function XArchiveControl:IsHaveNewWeaponByWeaponType(type)
    return self._Model:GetWeaponRedPointCountByType(type) > 0
end

function XArchiveControl:IsWeaponSettingOpen(settingId)
    return self._Model:GetWeaponSettingUnlockServerDataById(settingId) or self._Model:GetWeaponSettingCanUnlockById(settingId) == true
end

-- 武器设定有红点的列表,列表可能为空
function XArchiveControl:GetNewWeaponSettingIdList(templateId)
    return self._Model:GetNewWeaponSettingIdListById(templateId)
end

-- 某个武器类型下是否有红点
function XArchiveControl:IsHaveNewWeaponSettingByWeaponType(type)
    return self._Model:GetNewWeaponSettingByWeaponType(type) > 0
end

function XArchiveControl:CheckWeaponsCollectionLevelUp(type,curLevel)
    local oldlevel = XSaveTool.GetData(self._Model:GetWeaponsCollectionSaveKey(type))
    if not oldlevel then
        XSaveTool.SaveData(self._Model:GetWeaponsCollectionSaveKey(type), curLevel)
        return false
    else
        if curLevel > oldlevel then
            XSaveTool.SaveData(self._Model:GetWeaponsCollectionSaveKey(type), curLevel)
            return true, oldlevel
        else
            return false
        end
    end
end

function XArchiveControl:SaveWeaponsCollectionDefaultData(type,level)
    local oldlevel = XSaveTool.GetData(self._Model:GetWeaponsCollectionSaveKey(type))
    if not oldlevel then
        XSaveTool.SaveData(self._Model:GetWeaponsCollectionSaveKey(type), level)
    end
end

function XArchiveControl:HandleCanUnlockWeaponSettingByWeaponType(type)
    local isHaveNew = self:IsHaveNewWeaponSettingByWeaponType(type)
    if not isHaveNew then return end
    local idList = {}
    local needCheckIdList = self._Model:GetWeaponTypeToIdsDic()[type]
    for _, templateId in ipairs(needCheckIdList) do
        if self._Model:GetNewWeaponSettingIdListById(templateId) then
            for _, id in ipairs(self._Model:GetNewWeaponSettingIdListById(templateId)) do
                tableInsert(idList, id)
            end
        end
    end
    XMVCA.XArchive:RequestUnlockWeaponSetting(idList)
end

function XArchiveControl:HandleCanUnlockWeapon()
    local isHaveNew = XMVCA.XArchive:IsHaveNewWeapon()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model:GetArchiveWeaponServerData()) do
            if XMVCA.XArchive:IsNewWeapon(id) then
                table.insert(idList, id)
            end
        end
        XMVCA.XArchive:RequestUnlockWeapon(idList)
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
            XMVCA.XArchive:RequestUnlockWeapon(idList)
        end
    end
end

function XArchiveControl:HandleCanUnlockWeaponSetting()
    local isHaveNew = XMVCA.XArchive:IsHaveNewWeaponSetting()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model:GetWeaponSettingCanUnlockDic()) do
            tableInsert(idList, id)
        end
        XMVCA.XArchive:RequestUnlockWeaponSetting(idList)
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
    local storyChapterList = self._Model:GetArchiveStoryChapterList()
    if groupId then
        return storyChapterList[groupId] or {}
    end
    local list = {}
    if not XTool.IsTableEmpty(storyChapterList) then
        for _,group in pairs(storyChapterList) do
            for _,chapter in pairs(group) do
                tableInsert(list,chapter)
            end
        end
    end
    return self._Model:SortByOrder(list)
end


function XArchiveControl:UpdateStoryDetailList()--更新图鉴剧情详细列表数据
    local storyDetailList = self._Model:GetArchiveStoryDetailList()
    if XTool.IsTableEmpty(storyDetailList) then
        return
    end
    
    for _,detailList in pairs(storyDetailList) do
        if not XTool.IsTableEmpty(detailList) then
            ---@param detail XArchiveStoryDetailEntity
            for _,detail in pairs(detailList) do
                local IsUnLock = false
                local lockDes = ""
                local nowTime = XTime.GetServerNowTimestamp()
                local unLockTime = detail:GetUnLockTime() and XTime.ParseToTimestamp(detail:GetUnLockTime()) or 0
                local IsPassCondition = ((unLockTime ~= 0) and (nowTime > unLockTime)) or self._Model:GetShowedStoryListById(detail:GetId())
                if detail:GetCondition()  == 0 or IsPassCondition then
                    IsUnLock = true
                else
                    IsUnLock, lockDes = XConditionManager.CheckCondition(detail:GetCondition())
                end
                detail:SetIsLock(not IsUnLock)
                detail:SetLockDesc(lockDes)
            end
        end
    end
end

function XArchiveControl:GetStoryCollectRate()
    local storyDetailList = XMVCA.XArchive:GetArchiveStoryDetailList()
    if #storyDetailList < 1 then
        return 0
    end
    local unlockCount = 0
    if not XTool.IsTableEmpty(storyDetailList) then
        for _,v in pairs(storyDetailList) do
            if not v:GetIsLock() then
                unlockCount = unlockCount + 1
            end
        end
    end
    return self:GetPercent((unlockCount/#storyDetailList)*100)
end

function XArchiveControl:UpdateStoryData()
    self:UpdateStoryDetailList()
    self:UpdateStoryChapterList()
end

function XArchiveControl:UpdateStoryChapterList()--更新图鉴剧情关卡列表数据
    local storyChapterList = self._Model:GetArchiveStoryChapterList()
    if XTool.IsTableEmpty(storyChapterList) then
        return
    end
    
    for _,chapterList in pairs(storyChapterList) do
        if XTool.IsTableEmpty(chapterList) then
            goto continue
        end
        ---@param chapter XArchiveStoryChapterEntity
        for _,chapter in pairs(chapterList) do
            local IsUnLock = false
            local lockDes = CS.XTextManager.GetText("StoryArchiveErrorHint")
            local storyDetailList = XMVCA.XArchive:GetArchiveStoryDetailList(chapter:GetId())
            for _,detail in pairs(storyDetailList) do
                IsUnLock = IsUnLock or (not detail:GetIsLock())
                if IsUnLock then
                    break
                end
            end
            chapter:SetIsLock(not IsUnLock)
            local FirstIndex = 1
            local storyDetail = storyDetailList[FirstIndex]
            if storyDetail and storyDetail:GetLockDesc() then
                chapter:SetLockDesc(storyDetail:GetLockDesc())
            else
                chapter:SetLockDesc(lockDes)
                XLog.Error("detail is nil or LockDesc is nil by chapterId:" .. chapter:GetId())
            end
        end
        :: continue ::
    end
end
--endregion

--region -------------Npc相关------------->>>

function XArchiveControl:UpdateStoryNpcList()--更新图鉴Npc数据
    local storyNpcList = self._Model:GetArchiveStoryNpcList()
    if XTool.IsTableEmpty(storyNpcList) then
        return    
    end
    
    ---@param npc XArchiveNpcEntity
    for _,npc in pairs(storyNpcList) do
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
        npc:SetIsLock(not IsUnLock)
        npc:SetLockDesc(lockDes)
    end
end

function XArchiveControl:UpdateStoryNpcSettingList()--更新图鉴NpcSetting数据
    local storyNpcSettingList = self._Model:GetArchiveStoryNpcSettingList()
    if XTool.IsTableEmpty(storyNpcSettingList) then
        return
    end
    
    for _,settingGroupList in pairs(storyNpcSettingList) do
        if XTool.IsTableEmpty(settingGroupList) then
            goto continue1
        end
        
        for _,settingList in pairs(settingGroupList) do
            if XTool.IsTableEmpty(settingList) then
                goto continue2
            end
            
            ---@param setting XArchiveNpcDetailEntity
            for _,setting in pairs(settingList) do
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
                
                setting:SetIsLock(not IsUnLock)
                setting:SetLockDesc(lockDes)
            end
            :: continue2 ::
        end
        :: continue1 ::
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
    local storyNpcSettingList = self._Model:GetArchiveStoryNpcSettingList()[group]
    if type then
        return storyNpcSettingList and storyNpcSettingList[type] or {}
    end
    local list = {}
    for _,settingList in pairs(storyNpcSettingList) do
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
    for _,v in pairs(npcList) do
        if not v:GetIsLock() then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#npcList)*100)
end
--endregion

--region -------------CG相关------------->>>

function XArchiveControl:GetCGCompletionRate(type)
    local CGList = self:GetGCDetailShowList(type)
    if #CGList < 1 then
        return 0
    end
    local unlockCount = 0
    for _,v in pairs(CGList) do
        if self:GetCGUnLock(v:GetId()) then
            unlockCount = unlockCount + 1
        end
    end
    return self:GetPercent((unlockCount/#CGList)*100)
end

function XArchiveControl:GetCGUnLock(CGId)
    if self._Model:GetShowedCGListById(CGId) then
        return true
    end
    
    local CGDetail=self._Model:GetCGDetail()[CGId]
    if not CGDetail then return false end
    local IsUnLock, lockDes = false, ""
    --客户端判定
    local unLockTime = CGDetail.UnLockTime
    unLockTime = unLockTime and XTime.ParseToTimestamp(unLockTime) or 0
    local conditionId = CGDetail.Condition

    if not XTool.IsNumberValid(unLockTime) and not XTool.IsNumberValid(conditionId) then
        IsUnLock, lockDes = true, ""
    else
        if XTool.IsNumberValid(unLockTime) then
            local nowTime = XTime.GetServerNowTimestamp()
            IsUnLock, lockDes = nowTime >= unLockTime, CS.XTextManager.GetText("ArchiveNotUnLockTime")
        end
        if not IsUnLock and XTool.IsNumberValid(conditionId) then
            IsUnLock, lockDes = XConditionManager.CheckCondition(conditionId)
        end
    end

    return IsUnLock, lockDes
end

--- 获取在显示时间内的CGDetail列表
function XArchiveControl:GetGCDetailShowList(type)
    local cgDetailList = XMVCA.XArchive:GetArchiveCGDetailList(type)
    local showList = {}
    for i, cgDetail in ipairs(cgDetailList) do
        local showTimeStr = cgDetail:GetShowTimeStr()
        if string.IsNilOrEmpty(showTimeStr) then
            table.insert(showList, cgDetail)
        else
            local timeStamp = XTime.GetServerNowTimestamp()
            if timeStamp >= XTime.ParseToTimestamp(showTimeStr) then
                table.insert(showList, cgDetail)
            end
        end
    end
    
    return showList
end
--endregion

--region -------------邮件通讯相关------------->>>

function XArchiveControl:UpdateMailList()--更新邮件数据
    local mailList = self._Model:GetArchiveMailList()
    if XTool.IsTableEmpty(mailList) then
        return
    end
    
    for _,group in pairs(mailList) do
        ---@param mail XArchiveMailEntity
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
            
            mail:SetIsLock(not IsUnLock)
            mail:SetLockDesc(lockDes)
        end
    end
end

function XArchiveControl:UpdateCommunicationList()--更新通讯数据
    local communicationList = self._Model:GetArchiveCommunicationList()
    if XTool.IsTableEmpty(communicationList) then
        return
    end
    
    for _,group in pairs(communicationList) do
        ---@param communication XArchiveCommunicationEntity
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
            
            communication:SetIsLock(not IsUnLock)
            communication:SetLockDesc(lockDes)
        end
    end
end

function XArchiveControl:UpdateMailAndCommunicationData()
    self:UpdateMailList()
    self:UpdateCommunicationList()
end

function XArchiveControl:GetArchiveCommunicationList(group)--group为空时不作为判断条件
    local list = {}
    local communicationListTotal = self._Model:GetArchiveCommunicationList()
    if group then
        local communicationList = nil
        if not XTool.IsTableEmpty(communicationListTotal) then
            communicationList = communicationListTotal[group]
        end
        if not XTool.IsTableEmpty(communicationList) then
            for _,communication in pairs(communicationList) do
                if not communication:GetIsLock() then
                    tableInsert(list,communication)
                end
            end
        end
        return self._Model:SortByOrder(list)
    end

    for _,communicationList in pairs(communicationListTotal) do
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
    local mailListTotal = self._Model:GetArchiveMailList()
    if group then
        local mailListGroup = nil
        if not XTool.IsTableEmpty(mailListTotal) then
            mailListGroup = mailListTotal[group]
        end
        if not XTool.IsTableEmpty(mailListGroup) then
            for _,mail in pairs(mailListGroup) do
                if not mail:GetIsLock() then
                    tableInsert(list,mail)
                end
            end
        end
        return self._Model:SortByOrder(list)
    end

    for _,mailList in pairs(mailListTotal) do
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
        return self._Model:GetPartnerListByGroup(group)
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
    if not XTool.IsTableEmpty(partnerList) then
        for _,v in pairs(partnerList) do
            if not v:GetIsArchiveLock() then
                unlockCount = unlockCount + 1
            end
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
    if self._Model:GetUnlockPvDetailsById(pvDetailId) then
        return true
    end

    local isUnLock, lockDes
    local pvDetailCfg=self._Model:GetPVDetail()[pvDetailId]
    local unLockTime = pvDetailCfg.UnLockTime
    unLockTime = unLockTime and XTime.ParseToTimestamp(unLockTime) or 0
    local conditionId = pvDetailCfg.Condition

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

function XArchiveControl:GetWeaponTemplateIdListByType(type)
    return self._Model:GetWeaponTypeToIdsDic()[type]
end

function XArchiveControl:GetWeaponSettingType(id)
    return self._Model:GetWeaponSetting()[id].Type
end

function XArchiveControl:GetWeaponTemplateIdBySettingId(id)
    return self._Model:GetWeaponSetting()[id].EquipId
end

function XArchiveControl:GetPVDetailIdList(groupId)
    return self._Model:GetPVDetailIdList(groupId)
end

function XArchiveControl:GetPVDetailName(id)
    local config = self._Model:GetPVDetailById(id)
    return config.Name
end

function XArchiveControl:GetPVDetailBg(id)
    local config = self._Model:GetPVDetailById(id)
    return config.Bg
end

function XArchiveControl:GetPVDetailLockBg(id)
    local config = self._Model:GetPVDetailById(id)
    return config.LockBg
end

function XArchiveControl:GetPVDetailUnLockTime(id)
    local config = self._Model:GetPVDetailById(id)
    return config.UnLockTime
end

function XArchiveControl:GetPVDetailCondition(id)
    local config = self._Model:GetPVDetailById(id)
    return config.Condition
end

function XArchiveControl:GetPVDetailPv(id)
    local config = self._Model:GetPVDetailById(id)
    return config.Pv
end

function XArchiveControl:GetPVDetailBgWidth(id)
    local config = self._Model:GetPVDetailById(id)
    return config.BgWidth
end

function XArchiveControl:GetPVDetailBgHigh(id)
    local config = self._Model:GetPVDetailById(id)
    return config.BgHigh
end

function XArchiveControl:GetPVDetailBgOffSetX(id)
    local config = self._Model:GetPVDetailById(id)
    return config.BgOffSetX
end

function XArchiveControl:GetPVDetailBgOffSetY(id)
    local config = self._Model:GetPVDetailById(id)
    return config.BgOffSetY
end

function XArchiveControl:GetWeaponTypeToIdsDic()
    return self._Model:GetWeaponTypeToIdsDic()
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