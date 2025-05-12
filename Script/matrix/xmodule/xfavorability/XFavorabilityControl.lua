---@class XFavorabilityControl : XControl
---@field private _Model XFavorabilityModel
local XFavorabilityControl = XClass(XControl, "XFavorabilityControl")
local ClientConfig = CS.XGame.ClientConfig


function XFavorabilityControl:OnInit()
    --初始化内部变量
end

function XFavorabilityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFavorabilityControl:RemoveAgencyEvent()

end

function XFavorabilityControl:OnRelease()

end

--[剧情是否可解锁]
function XFavorabilityControl:IsStorySatisfyUnlock(characterId, Id)
    return self._Model:IsStorySatisfyUnlock(characterId, Id)
end

--[剧情满足通关的数目]
function XFavorabilityControl:GetStorySatisfyPassCount(characterId)
    local storyCfgs = self._Model:GetCharacterStoryUnlockLvsById(characterId)

    if XTool.IsTableEmpty(storyCfgs) then
        return 0
    end
    
    local count = 0

    ---@param cfg XTableCharacterStory
    for id, cfg in pairs(storyCfgs) do
        if self._Model:IsStorySatisfyPass(characterId, cfg.Id) then
            count = count + 1
        end
    end
    
    return count
end

-- [角色剧情配置是否是关卡类型]
function XFavorabilityControl:CheckCharacterStoryIsStage(characterId)
    local storyCfgs = self._Model:GetCharacterStoryUnlockLvsById(characterId)

    if XTool.IsTableEmpty(storyCfgs) then
        return false
    end

    ---@param cfg XTableCharacterStory
    for id, cfg in pairs(storyCfgs) do
        if XTool.IsNumberValid(cfg.StageId) then
            return true
        end
    end
    
    return false
end

-- [剧情是否有任务奖励]
function XFavorabilityControl:CheckStoryHasRewardTask(characterId)
    local storys = self._Model:GetCharacterStory()[characterId]

    if not XTool.IsTableEmpty(storys) then
        for i, v in pairs(storys) do
            if XTool.IsNumberValid(v.TaskId) then
                return true
            end
        end
    end
    
    return false
end

---@return XTableCharacterTips
function XFavorabilityControl:GetStoryTipsCfg(tipsId)
    return self._Model:GetCharacterStoryTipsCfg(tipsId)
end

-- [资料是否可以解锁]
function XFavorabilityControl:CanInformationUnlock(characterId, infoId)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1

    local characterUnlockLvs = self._Model:GetCharacterInformationUnlockLvById(characterId)
    if characterUnlockLvs and characterUnlockLvs[infoId] then
        return trustLv >= characterUnlockLvs[infoId]
    end
    return false
end

-- [语音是否可以解锁]
function XFavorabilityControl:CanVoiceUnlock(characterId, Id)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1
    local voiceDatas = self._Model:GetCharacterVoiceMapById(characterId)
    if voiceDatas and voiceDatas[Id] then
        return XMVCA.XFavorability:CheckCharacterVoiceUnlock(voiceDatas[Id],trustLv)
    end
    return false
end

-- [动作是否可以解锁]
function XFavorabilityControl:CanActionUnlock(characterId, Id)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1
    -- actionDatas 只含有 UnlockLv 和 UnlockCondition
    local actionDatas = self._Model:GetCharacterActionUnlockLvsById(characterId)
    if actionDatas and actionDatas[Id] then
        return XMVCA.XFavorability:CheckCharacterActionUnlock(actionDatas[Id],trustLv)
    end
    return false
end

-- [资料是否已经解锁]
function XFavorabilityControl:IsInformationUnlock(characterId, infoId)
    local favorabilityDatas = XMVCA.XFavorability:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockInformation == nil then return false end
    return favorabilityDatas.UnlockInformation[infoId]
end

-- [语音是否已经解锁]
function XFavorabilityControl:IsVoiceUnlock(characterId, Id)
    local favorabilityDatas = XMVCA.XFavorability:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockVoice == nil then return false end
    return favorabilityDatas.UnlockVoice[Id]
end

-- [动作是否已经解锁]
function XFavorabilityControl:IsActionUnlock(characterId, Id)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1
    local actionDatas = self._Model:GetCharacterActionUnlockLvsById(characterId)
    if actionDatas and actionDatas[Id] then
        if not XMVCA.XFavorability:CheckCharacterActionUnlock(actionDatas[Id],trustLv) then
            return false
        end
    end

    local favorabilityDatas = XMVCA.XFavorability:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockAction == nil then return false end
    return favorabilityDatas.UnlockAction[Id]
end

-- [剧情是否已经解锁]
function XFavorabilityControl:IsStoryUnlock(characterId, Id)
    local favorabilityDatas = XMVCA.XFavorability:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockStory == nil then return false end
    return favorabilityDatas.UnlockStory[Id]
end

function XFavorabilityControl:GetCharacterInformationById(characterId)
    return self._Model:GetCharacterInformation()[characterId]
end

-- [好感度档案-异闻]
function XFavorabilityControl:GetCharacterRumorsById(characterId)
    local rumors = self._Model:GetCharacterRumors()[characterId]
    return rumors
end

function XFavorabilityControl:GetCharacterRumorsPriority()
    local rumorsPriority = self._Model:GetCharacterRumorsPriority()
    return rumorsPriority
end

function XFavorabilityControl:GetMaxFavorabilityLevel(characterId)
    local characterFavorabilityLevelDatas=self._Model:GetTrustExpById(characterId)
    if characterFavorabilityLevelDatas then
        local maxLevel = 1
        for trustLv, levelDatas in pairs(characterFavorabilityLevelDatas) do
            if levelDatas.Exp == 0 then
                maxLevel = trustLv
                break
            end
        end

        return maxLevel
    end
end

function XFavorabilityControl:IsMaxFavorabilityLevel(characterId)
    local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
    local maxLv = self:GetMaxFavorabilityLevel(characterId)
    return trustLv == maxLv
end

--是不是联动角色
function XFavorabilityControl:GetModelGetCharacterCollaboration(characterId)
    return self._Model:GetCharacterCollaboration()[characterId]
end

function XFavorabilityControl:GetLikeTrustItemCfg(itemId)
    return self._Model:GetLikeTrustItemCfg(itemId)
end

function XFavorabilityControl:GetTrustExpById(characterId)
    return self._Model:GetTrustExpById(characterId)
end

function XFavorabilityControl:GetStoryLayoutCfgById(characterId)
    return self._Model:GetStoryLayoutCfgById(characterId)
end

function XFavorabilityControl:GetStoryLayoutBgTypeCfg(type)
    return self._Model:GetStoryLayoutBgTypeCfg(type)
end

function XFavorabilityControl:GetStageDetailTypeCfg(type)
    return self._Model:GetStageDetailTypeCfg(type)
end

--[剧情进度]
function XFavorabilityControl:GetStoryProgress(characterId)
    local storyCount=#XMVCA.XFavorability:GetCharacterStoryById(characterId)
    local unlockCount
    local favorabilityDatas = XMVCA.XFavorability:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockStory == nil then
        unlockCount=0
    else
        unlockCount=XTool.GetTableCount(favorabilityDatas.UnlockStory)
    end

    return self:GetStorySatisfyPassCount(characterId),storyCount
end

function XFavorabilityControl:GetCharacterBaseDataById(characterId)
    return self._Model:GetCharacterBaseDataById(characterId)
end


-- 获取cv名字
function XFavorabilityControl:GetCharacterCvByIdAndType(characterId, cvType)
    local baseData = self._Model:GetCharacterBaseDataById(characterId)
    if not baseData then return "" end

    if baseData.Cast and baseData.Cast[cvType] then return baseData.Cast[cvType] end
    return ""
end

function XFavorabilityControl:GetFavorabilityLevel(characterId, totalExp, startLevel)
    return self._Model:GetFavorabilityLevel(characterId,totalExp,startLevel)
end

function XFavorabilityControl:GetCharacterTeamIconById(characterId)
    return self._Model:GetCharacterTeamIconById(characterId)
end

function XFavorabilityControl:GetAllCharacterSendGift()
    return self._Model:GetAllCharacterSendGift()
end

-- [好感度-等级名字]
function XFavorabilityControl:GetWordsWithColor(trustLv, name)
    --local color = self._Model:GetFavorabilityLevelCfg(trustLv).WordColor
    --return string.format("<color=%s>%s</color>", color, name)
    return self:GetAgency():GetWordsWithColor(trustLv, name)
end

-- [获得好感度面板信息]
function XFavorabilityControl:GetNameWithTitleById(characterId)
    local currCharacterName = XMVCA.XCharacter:GetCharacterName(characterId)
    return currCharacterName
end

-- [添加ID至已经给过特殊礼物的构造体名单]
function XFavorabilityControl:AddGivenItemCharacterId(characterId)
    local groupId = self._Model:GetCharacterGroupId(characterId)
    if not XTool.IsNumberValid(groupId) then return end
    self._Model:AddGivenItemByCharacterGroupId(groupId)
end

-- [检查目标ID是否存在于一给过特殊礼物的构造体名单中]
function XFavorabilityControl:IsInGivenItemCharacterIdList(characterId)
    --联动角色类型（0则不是联动角色）
    local linkageType = XMVCA.XCharacter:GetCharacterLinkageType(characterId)
    --跳过联动角色判断
    if XTool.IsNumberValid(linkageType) then
        return false
    end
    local groupId = self._Model:GetCharacterGroupId(characterId)
    if not XTool.IsNumberValid(groupId) then return end
    local IsIn = self._Model:GetGivenItemByCharacterGroupId(groupId)
    return IsIn and IsIn or false
end

-- [好感度-等级图标]
function XFavorabilityControl:GetTrustLevelIconByLevel(level)
    return self:GetAgency():GetTrustLevelIconByLevel(level)
end

function XFavorabilityControl:GetCurrCharacterExp(characterId)
    if characterId == nil then
        return 0
    end

    local currCharacterData = XMVCA.XCharacter:GetCharacter(characterId)

    if currCharacterData == nil then
        return 0
    end
    return currCharacterData.TrustExp or 0
end

function XFavorabilityControl:SortTrustItems(itemA, itemB)
    local itemAPriority = XDataCenter.ItemManager.GetItemPriority(itemA.Id) or 0
    local itemBPriority = XDataCenter.ItemManager.GetItemPriority(itemB.Id) or 0

    if itemA.IsFavourWeight == itemB.IsFavourWeight then
        if itemA.TrustItemQuality == itemB.TrustItemQuality then
            if itemAPriority == itemBPriority then
                return itemA.Id > itemB.Id
            end
            return itemAPriority > itemBPriority
        end
        return itemA.TrustItemQuality > itemB.TrustItemQuality
    end
    return itemA.IsFavourWeight > itemB.IsFavourWeight
end

function XFavorabilityControl:IsDuringOfFestivalMail()
    local cfg = self._Model:GetFestival(self._Model:GetFestivalActivityMailId())
    if not cfg or not XTool.IsNumberValid(cfg.TimeId) then
        return false
    end

    local timeId = cfg.TimeId
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
    local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(timeId)

    return timeOfNow >= timeOfBgn and timeOfNow <= timeOfEnd
end

-- [传入一段SignBoardAction数据(XSignBoardConfigs中获取)，输出其中已经解锁的数据]
function XFavorabilityControl:FilterSignBoardActionsByFavorabilityUnlock(signBoardActionDatas)
    local unlockActions = {}
    for _,v in ipairs(signBoardActionDatas) do
        if XMVCA.XFavorability:CheckCharacterActionUnlockBySignBoardActionId(v.Id) then
            table.insert(unlockActions,v)
        end
    end
    return unlockActions
end

-- [发送礼物]
function XFavorabilityControl:OnSendCharacterGift(args, cb)
    local gitfs = {}

    for k, v in pairs(args.GiftItems) do
        gitfs[k] = v
    end

    XMessagePack.MarkAsTable(gitfs)

    XNetwork.Call("CharacterSendGiftRequest", { TemplateId = args.CharacterId, GiftItems = gitfs }, function(res)
        cb = cb or function() end
        if res.Code == XCode.Success then
            cb(res)
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_GIFT, args.CharacterId)
        else
            XUiManager.TipCode(res.Code)
        end
    end)

end

-- [看板交互]
function XFavorabilityControl:BoardMutualRequest()
    XNetwork.Send("BoardMutualRequest", {})
end

function XFavorabilityControl:GetDontStopCvContent()
    return self._Model._DontStopCvContent
end

function XFavorabilityControl:SetDontStopCvContent(value)
    self._Model._DontStopCvContent=value
end

function XFavorabilityControl:GetFavorabilitySkipIds()
    local skip_size = ClientConfig:GetInt("FavorabilitySkipSize")
    local skipIds = {}
    for i = 1, skip_size do
        table.insert(skipIds, ClientConfig:GetInt(string.format("FavorabilitySkip%d", i)))
    end

    return skipIds
end

function XFavorabilityControl:GetCollaborationCharacterIconScale(characterId)
    if self:GetModelGetCharacterCollaboration(characterId) then
        return self._Model:GetCharacterCollaboration()[characterId].IconScale
    else
        return nil
    end
end

function XFavorabilityControl:GetCollaborationCharacterIconPos(characterId)
    if self:GetModelGetCharacterCollaboration(characterId) then
        local pos = {}
        pos.X = self._Model:GetCharacterCollaboration()[characterId].IconX
        pos.Y = self._Model:GetCharacterCollaboration()[characterId].IconY
        return pos
    else
        return nil
    end
end

function XFavorabilityControl:GetCollaborationCharacterIcon(characterId)
    if self:GetModelGetCharacterCollaboration(characterId) then
        return self._Model:GetCharacterCollaboration()[characterId].IconPath
    else
        return nil
    end
end

function XFavorabilityControl:GetCollaborationCharacterText(characterId)
    if self:GetModelGetCharacterCollaboration(characterId) then
        return self._Model:GetCharacterCollaboration()[characterId].Text
    else
        return nil
    end
end

function XFavorabilityControl:GetCollaborationCharacterCvType(characterId)
    if self:GetModelGetCharacterCollaboration(characterId) then
        local cvType = string.Split(self._Model:GetCharacterCollaboration()[characterId].languageSet, "|")

        for k, v in pairs(cvType) do
            cvType[k] = tonumber(v)
        end

        return cvType
    else
        return nil
    end
end

function XFavorabilityControl:GetQualityIconByQuality(quality)
    return self._Model:GetQualityIconByQuality(quality)
end

--region 好感度语音
function XFavorabilityControl:GetCharacterVoiceMapText(mapCode)
    local id = XMath.ToMinInt(mapCode / 10000)
    local value = XMath.ToMinInt(mapCode % 10000)
    
    local cfg = self:GetCharacterVoiceContentMapCfg(id)

    if cfg then
        if XTool.IsNumberValid(value) then
            return XUiHelper.FormatText(cfg.Text, value)
        else
            return cfg.Text    
        end
    end
    
    return ''
end

function XFavorabilityControl:GetCharacterVoiceContentMapCfg(id)
    local cfg = self._Model:GetCharacterVoiceContentMap()[id]

    if cfg then
        return cfg
    else
        XLog.Error('CharacterVoiceContentMap表找不到Id为 '..tostring(id)..' 的数据')
    end
end
--endregion

--region 好感度动作
function XFavorabilityControl:GetCharacterActionMapText(mapCode)
    return self._Model:GetCharacterActionMapText(mapCode)
end
--endregion

return XFavorabilityControl