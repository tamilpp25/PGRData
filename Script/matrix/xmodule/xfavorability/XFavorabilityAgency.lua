---@class XFavorabilityAgency : XAgency
---@field private _Model XFavorabilityModel
local XFavorabilityAgency = XClass(XAgency, "XFavorabilityAgency")

--私有方法预定义
local InitCharacterData=nil
local OnCollectCharacterReward=nil
local NotifyFiveTwentyRecord=nil
local OnCharacterTrustInfoUpdate=nil
local PlayCharacterSkillUpOrUnlockCv=nil

local EventFuncMap=nil

function XFavorabilityAgency:OnInit()
    --初始化一些变量
    self._UnlockStrangeNewsFunc={}
    self._UnlockStrangeNewsFunc[XEnumConst.Favorability.StrangeNewsUnlockType.TrustLv] = function(characterId, target)
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        if not characterData then
            return false
        end

        local trustLv = characterData.TrustLv or 1
        return trustLv >= target
    end
    self._UnlockStrangeNewsFunc[XEnumConst.Favorability.StrangeNewsUnlockType.DormEvent] = function()
        return false
    end

    self._UnlockRewardFunc={}
    -- [战斗参数达到target, 后端还不能正确计算出战斗参数，暂时返回false]
    self._UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.FightAbility] = function()
        -- local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        -- local curCharacterAbility = characterData.Ability or 0
        return false
        -- return math.ceil(curCharacterAbility) >= target
    end
    -- [信赖度达到target]
    self._UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.TrustLv] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local trustLv = characterData.TrustLv or 1
        return trustLv >= target
    end
    -- [角色等级达到target]
    self._UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.CharacterLv] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local characterLevel = characterData.Level or 1
        return characterLevel >= target
    end
    -- [进化至target]
    self._UnlockRewardFunc[XFavorabilityConfigs.RewardUnlockType.Quality] = function(characterId, target)
        local characterData = XDataCenter.CharacterManager.GetCharacter(characterId)
        local characterQuality = characterData.Quality or 1
        return characterQuality >= target
    end
    
    self.DEFAULT_CV_TYPE = CS.XGame.Config:GetInt("DefaultCvType")
    self.SkillCvTimeLimit = CS.XGame.ClientConfig:GetFloat("CharacterSkillLevelUpCvTimeLimit")
end

function XFavorabilityAgency:InitRpc()
    --实现服务器事件注册
    -- [更新好感度等级，经验]
    XRpc.NotifyCharacterTrustInfo = OnCharacterTrustInfoUpdate

    XRpc.NotifyCharacterExtraData = Handler(self,OnCollectCharacterReward)

    XRpc.NotifyFiveTwentyRecord = Handler(self,NotifyFiveTwentyRecord)
end

function XFavorabilityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
    EventFuncMap={}
    EventFuncMap[XEventId.EVENT_CHARACTER_FIRST_GET]=function(characterId) self:PlayCvByType(characterId, XEnumConst.Favorability.SoundEventType.FirstTimeObtain) end
    EventFuncMap[XEventId.EVENT_CHARACTER_LEVEL_UP]=function(characterId) self:PlayCvByType(characterId, XEnumConst.Favorability.SoundEventType.LevelUp) end
    EventFuncMap[XEventId.EVENT_CHARACTER_QUALITY_PROMOTE]=function(characterId) self:PlayCvByType(characterId, XEnumConst.Favorability.SoundEventType.Evolve) end
    EventFuncMap[XEventId.EVENT_CHARACTER_GRADE]=function(characterId) self:PlayCvByType(characterId, XEnumConst.Favorability.SoundEventType.GradeUp) end
    EventFuncMap[XEventId.EVENT_EQUIP_PUTON_WEAPON_NOTYFY]=function(characterId) self:PlayCvByType(characterId, XEnumConst.Favorability.SoundEventType.WearWeapon) end
    EventFuncMap[XEventId.EVENT_TEAM_MEMBER_CHANGE]=function(curTeamId, characterId, isCaptain)
        if characterId == 0 then return end
        local soundEventType = isCaptain and XEnumConst.Favorability.SoundEventType.CaptainJoinTeam
                or XEnumConst.Favorability.SoundEventType.MemberJoinTeam
        self:PlayCvByType(characterId, soundEventType)
    end

    for eventId, func in pairs(EventFuncMap) do
        self:AddAgencyEvent(eventId,func)
    end
    
    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UP, PlayCharacterSkillUpOrUnlockCv)

    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, PlayCharacterSkillUpOrUnlockCv)
end

function XFavorabilityAgency:RemoveEvent()
    self:RemoveEventListener(XEventId.EVENT_CHARACTER_SKILL_UP,PlayCharacterSkillUpOrUnlockCv)
    self:RemoveEventListener(XEventId.EVENT_CHARACTER_SKILL_UNLOCK,PlayCharacterSkillUpOrUnlockCv)
    if not EventFuncMap==nil then
        for eventId, func in pairs(EventFuncMap) do
            self:RemoveEventListener(eventId,func)
        end
    end
    EventFuncMap={}
end

----------public start----------
-- 【红点相关】
-- [某个角色是否有资料可以解锁]
function XFavorabilityAgency:HasDataToBeUnlock(characterId)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local characterTrustLv = characterData.TrustLv or 1

    local informationDatas = self._Model:GetCharacterInformationById(characterId)
    if informationDatas == nil then return false end

    local favorabilityDatas = self:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockInformation == nil then return false end

    for _, info in pairs(informationDatas) do
        local isUnlock = favorabilityDatas.UnlockInformation[info.config.Id]
        local canUnlock = characterTrustLv >= info.config.UnlockLv
        if (not isUnlock) and canUnlock then
            return true
        end
    end
    return false
end

-- [某个/当前角色是否有剧情可以解锁]
function XFavorabilityAgency:HasStroyToBeUnlock(characterId)
    local storys = self:GetCharacterStoryById(characterId)
    if storys == nil then return false end

    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local characterTrustLv = characterData.TrustLv or 1

    local favorabilityDatas = self:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockStory == nil then return false end

    for _, story in pairs(storys) do
        local isStoryUnlock = favorabilityDatas.UnlockStory[story.Id]
        local canStoryUnlock = characterTrustLv >= story.UnlockLv
        if (not isStoryUnlock) and canStoryUnlock then
            return true
        end
    end
    return false
end

-- [某个角色是否有异闻可以解锁]
function XFavorabilityAgency:HasRumorsToBeUnlock(characterId)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)

    if characterData == nil then return false end
    local rumors = self._Model:GetCharacterRumors()[characterId]
    if rumors == nil then return false end

    for _, news in pairs(rumors) do
        local isNewsUnlock = self:IsRumorUnlock(characterId, news.Id)
        local canNewsUnlock = self:CanRumorsUnlock(characterId, news.UnlockType, news.UnlockPara)
        if (not isNewsUnlock) and canNewsUnlock then
            return true
        end
    end
    return false
end

-- [某个角色是否有语音可以解锁]
function XFavorabilityAgency:HasAudioToBeUnlock(characterId)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1

    local voices = self:GetCharacterVoiceById(characterId)
    if voices == nil then return false end

    local favorabilityDatas = self:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockVoice == nil then return false end

    for _, voice in pairs(voices) do
        local isVoiceUnlock = favorabilityDatas.UnlockVoice[voice.config.Id]
        local canVoiceUnlock = self:CheckCharacterVoiceUnlock(voice,trustLv)
        if (not isVoiceUnlock) and canVoiceUnlock then
            return true
        end
    end
    return false
end

-- [某个角色是否有动作可以解锁]
function XFavorabilityAgency:HasActionToBeUnlock(characterId)
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    if characterData == nil then return false end
    local trustLv = characterData.TrustLv or 1

    local actions = self._Model:GetCharacterActionById(characterId)
    if actions == nil then return false end

    local favorabilityDatas = self:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockAction == nil then return false end

    for _, action in pairs(actions) do
        local isActionUnlock = favorabilityDatas.UnlockAction[action.config.Id]
        local canVoiceUnlock = self:CheckCharacterActionUnlock(action,trustLv)
        if (not isActionUnlock) and canVoiceUnlock then
            return true
        end
    end
    return false
end

-- [异闻是否解锁]
function XFavorabilityAgency:IsRumorUnlock(characterId, rumorId)
    local favorabilityDatas = self:GetCharacterFavorabilityDatasById(characterId,true)
    if favorabilityDatas == nil or favorabilityDatas.UnlockStrangeNews == nil then return false end
    return favorabilityDatas.UnlockStrangeNews[rumorId]
end

-- [好感度剧情]
function XFavorabilityAgency:GetCharacterStoryById(characterId)
    local storys = self._Model:GetCharacterStory()[characterId]
    return storys
end

function XFavorabilityAgency:GetCurrCharacterFavorabilityLevel(characterId)
    if characterId == nil then
        return 1
    end

    local currCharacterData = XMVCA.XCharacter:GetCharacter(characterId)
    if currCharacterData == nil then
        return 1
    end

    return currCharacterData.TrustLv or 1
end

-- [解锁剧情]解锁成功，返回0，重新登陆数据会绑定再character上，不重新登陆也会有最新的数据绑到character
function XFavorabilityAgency:OnUnlockCharacterStory(templateId, storyId,checkInit)
    local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if characterFavorabilityDatas and characterFavorabilityDatas.UnlockStory then
        characterFavorabilityDatas.UnlockStory[storyId] = true
    end
end

-- [解锁异闻]
function XFavorabilityAgency:OnUnlockCharacterRumor(templateId, rumorId,checkInit)
    local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if characterFavorabilityDatas and characterFavorabilityDatas.UnlockStrangeNews then
        characterFavorabilityDatas.UnlockStrangeNews[rumorId] = true
    end
end

-- [解锁数据]
function XFavorabilityAgency:OnUnlockCharacterInfomatin(templateId, infoId,checkInit)
    local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if characterFavorabilityDatas and characterFavorabilityDatas.UnlockInformation then
        characterFavorabilityDatas.UnlockInformation[infoId] = true
    end
end

-- [解锁语音]
function XFavorabilityAgency:OnUnlockCharacterVoice(templateId, cvId,checkInit)
    local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if characterFavorabilityDatas and characterFavorabilityDatas.UnlockVoice then
        characterFavorabilityDatas.UnlockVoice[cvId] = true
    end
end

-- [解锁动作]
function XFavorabilityAgency:OnUnlockCharacterAction(templateId, actionId,checkInit)
    local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if characterFavorabilityDatas and characterFavorabilityDatas.UnlockAction then
        characterFavorabilityDatas.UnlockAction[actionId] = true
    end
end

-- [异闻是否可以解锁]
function XFavorabilityAgency:CanRumorsUnlock(characterId, unlockType, unlockParam)
    if self._UnlockStrangeNewsFunc[unlockType] then
        return self._UnlockStrangeNewsFunc[unlockType](characterId, unlockParam)
    end
    return false
end

function XFavorabilityAgency:GetCharacterFavorabilityDatasById(templateId,checkInit)
    if checkInit and self._Model:IsCharacterFavorabilityDatasEmpty() then
        InitCharacterData(self)
    end
    return self._Model:GetCharacterFavorabilityDatasById(templateId)
end

function XFavorabilityAgency:GetCharacterCvById(characterId)
    local baseData = self._Model:GetCharacterBaseDataById(characterId)
    if not baseData then return "" end

    local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", self.DEFAULT_CV_TYPE)
    if baseData.Cast and baseData.Cast[cvType] then return baseData.Cast[cvType] end
    return ""
end

-- [获取好感度等级经验表数据]
function XFavorabilityAgency:GetFavorabilityTableData(characterId)
    local curTrustExp = self._Model:GetTrustExpById(characterId)
    if curTrustExp == nil then
        return
    end
    local currLevel = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
    return curTrustExp[currLevel]
end

function XFavorabilityAgency:GetTrustExpById(characterId)
    return self._Model:GetTrustExpById(characterId)
end

function XFavorabilityAgency:ResetLastPlaySkillCvTime()
    self._Model:ResetLastPlaySkillCvTime()
end

function XFavorabilityAgency:GetCharacterTrustExpById(characterId)
    local currCharacterData = XMVCA.XCharacter:GetCharacter(characterId)

    if currCharacterData == nil then
        return 0
    end
    return currCharacterData.TrustExp or 0
end

function XFavorabilityAgency:GetHighestTrustExpCharacter()
    local characters = XMVCA.XCharacter:GetOwnCharacterList()
    local char = nil
    local highestExp = -1
    for _, v in pairs(characters) do
        local level = self:GetCurrCharacterFavorabilityLevel(v.Id)
        if char and level == highestExp then
            if char.Level == v.Level then

                if char.CreateTime == v.CreateTime then
                    if char.Id > v.Id then
                        highestExp = level
                        char = v
                    end
                elseif char.CreateTime > v.CreateTime then
                    highestExp = level
                    char = v
                end

            elseif char.Level < v.Level then
                highestExp = level
                char = v
            end

        elseif level > highestExp then
            char = v
            highestExp = level
        end
    end

    return char.Id
end

function XFavorabilityAgency:CheckCharacterActionUnlock(actionData, trustLv)
    local isUnlock = true
    for k, conditionId in pairs(actionData.config.UnlockCondition) do
        if not XConditionManager.CheckCondition(conditionId, actionData.config.CharacterId) then
            isUnlock = false
            break
        end
    end
    return actionData.config.UnlockLv <= trustLv and isUnlock
end

-- [试穿][检查动作是否满足解锁条件]
--- func desc
---@param fashionId 试穿的时装id
function XFavorabilityAgency:CheckTryCharacterActionUnlock(actionData, trustLv, tryFashionId, trySceneId)
    if not tryFashionId then
        return false
    end

    local isUnlock = true
    for k, conditionId in pairs(actionData.config.UnlockCondition) do
        if not XConditionManager.CheckCondition(conditionId, actionData.config.CharacterId, tryFashionId, trySceneId) then
            isUnlock = false
            break
        end
    end
    return actionData.config.UnlockLv <= trustLv and isUnlock
end

function XFavorabilityAgency:CheckCharacterActionUnlockBySignBoardActionId(signBoardActionId)
    local actionData = self._Model:GetCharacterActionBySignBoardActionId(signBoardActionId)
    --若动作本身跟好感度系统没有关联 则直接播放
    if actionData == nil then return true end
    local characterId = actionData.config.CharacterId
    local characterData = XMVCA.XCharacter:GetCharacter(characterId)
    local trustLv = 1
    if characterData then
        trustLv = characterData.TrustLv or 1
    end
    return self:CheckCharacterActionUnlock(actionData, trustLv) , actionData.config.ConditionDescript

end

function XFavorabilityAgency:PlayCvByType(characterId, soundType)
    if not characterId or characterId == 0 then return end

    local voices = self._Model:GetCharacterVoiceUnlockLvsById(characterId)
    if not voices then
        XLog.Error("角色Id为"..characterId.."的好感语音找不到")
        return
    end
    for _, voice in pairs(voices) do
        if voice.config.SoundType == soundType then
            local cvId = voice.config.CvId

            if self._Model._PlayingCvId and self._Model._PlayingCvId == cvId then return end
            self._Model._PlayingCvId = cvId

            self._Model._PlayingCvInfo = CS.XAudioManager.PlayCv(voice.config.CvId, function()
                self._Model._PlayingCvId = nil
            end)

            return
        end
    end
end

function XFavorabilityAgency:StopCv()
    if not self._Model._PlayingCvInfo or not self._Model._PlayingCvInfo.Playing then return end
    self._Model._PlayingCvInfo:Stop()
    self._Model._PlayingCvId = nil
    self._Model._PlayingCvInfo = nil
end

function XFavorabilityAgency:GetCvSplit(cvId, cvType)
    return self._Model:GetCvSplit(cvId, cvType)
end

function XFavorabilityAgency:GetCvContentByIdAndType(cvId, cvType)
    local cvData = nil

    if CS.XAudioManager.CvTemplates:ContainsKey(cvId) then
        cvData = CS.XAudioManager.CvTemplates[cvId]
    end

    if not cvData then return "" end
    return cvData.CvContent[cvType - 1] or ""
end

-- [好感度档案-语音]
function XFavorabilityAgency:GetCharacterVoiceById(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
    end
    local voice = self._Model:GetCharacterVoice()[characterId]
    return voice
end

-- [检查语音是否满足解锁条件]
function XFavorabilityAgency:CheckCharacterVoiceUnlock(voiceData, trustLv)
    return voiceData.config.UnlockLv <= trustLv and (voiceData.config.UnlockCondition == 0 or XConditionManager.CheckCondition(voiceData.config.UnlockCondition,voiceData.config.CharacterId))
end

function XFavorabilityAgency:GetCharacterActionBySignBoardActionId(id)
    return self._Model:GetCharacterActionBySignBoardActionId(id)
end

function XFavorabilityAgency:GetCharacterActionById(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
    end
    local action = self._Model:GetCharacterAction()[characterId]
    return action
end

-- [奖励是否可以解锁]
function XFavorabilityAgency:CanRewardUnlock(characterId, unlockType, unlockParam)
    if self._UnlockRewardFunc[unlockType] then
        return self._UnlockRewardFunc[unlockType](characterId, unlockParam)
    end
    return false
end
----------public end----------

----------private start----------
InitCharacterData= function(self)
    --信息
    local allInfo = self._Model:GetCharacterInformation()
    for id, v in pairs(allInfo) do
        local trustLv = self:GetCurrCharacterFavorabilityLevel(id)
        for _, var in ipairs(v) do
            if var.config.UnlockLv <= trustLv then
                self:OnUnlockCharacterInfomatin(id, var.config.Id)
            end
        end

    end

    --异闻
    local allRumors = self._Model:GetCharacterRumors()
    for id, v in pairs(allRumors) do
        for _, var in ipairs(v) do
            local canUnlock = self:CanRumorsUnlock(id, var.UnlockType, var.UnlockPara)
            if canUnlock then
                self:OnUnlockCharacterRumor(id, var.Id)
            end
        end
    end
    
    --剧情
    local allStory = self._Model:GetCharacterStory()
    for id, v in pairs(allStory) do
        local trustLv = self:GetCurrCharacterFavorabilityLevel(id)
        for _, var in ipairs(v) do
            if var.UnlockLv <= trustLv then
                self:OnUnlockCharacterStory(id, var.Id)
            end
        end
    end

    local allVoice = self._Model:GetCharacterVoice()
    for characterId, characterVoice in pairs(allVoice) do
        local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
        for _, voice in ipairs(characterVoice) do
            if self:CheckCharacterVoiceUnlock(voice,trustLv) then
                self:OnUnlockCharacterVoice(characterId, voice.config.Id)
            end
        end
    end

    --动作
    local allAction = self._Model:GetCharacterAction()
    for characterId, characterAction in pairs(allAction) do
        local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
        for _, action in ipairs(characterAction) do
            if self:CheckCharacterActionUnlock(action,trustLv) then
                self:OnUnlockCharacterAction(characterId, action.config.Id)
            end
        end
    end
end

-- 【礼物begin】
-- 【Rpc相关】
-- [领取角色奖励]
OnCollectCharacterReward=function(self,templateId, rewardId, cb)
    XNetwork.Call("CharacterUnlockRewardRequest", { TemplateId = templateId, Id = rewardId }, function(res)
        cb = cb or function() end
        if res.Code == XCode.Success then
            local characterFavorabilityDatas = self:GetCharacterFavorabilityDatasById(templateId)
            if characterFavorabilityDatas and characterFavorabilityDatas.UnlockReward then
                characterFavorabilityDatas.UnlockReward[rewardId] = true
            end

            cb()
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_COLLECTGIFT)
            local rewards = self._Model:GetLikeRewardById(rewardId)
            if rewards then
                local list = {}
                table.insert(list, XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = rewards.ItemId, Count = rewards.ItemCount }))
                XUiManager.OpenUiObtain(list)
            end

        else
            XUiManager.TipCode(res.Code)
        end
    end)
end

-- [初始化520活动数据]
NotifyFiveTwentyRecord=function(self,data)
    self._Model:SetFestivalActivityMailId(data.ActivityNo)
    for _, groupId in ipairs(data.GroupRecord or {}) do
        self._Model:AddGivenItemByCharacterGroupId(groupId)
    end
end

-- [通知更新角色信赖度等级和经验]
OnCharacterTrustInfoUpdate=function(response)
    local characterData = XMVCA.XCharacter:GetCharacter(response.TemplateId)
    if characterData then
        -- 等级变化
        local trustLvHasChanged = characterData.TrustLv ~= response.TrustLv
        characterData.TrustLv = response.TrustLv
        characterData.TrustExp = response.TrustExp
        if trustLvHasChanged then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_LEVELCHANGED, response.TrustLv)
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_LEVELCHANGED)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_MAIN_REFRESH)
    end
end

PlayCharacterSkillUpOrUnlockCv=function(characterId)
    local now = XTime.GetServerNowTimestamp()
    if now - XMVCA.XFavorability._Model._LastPlaySkillCvTime < XMVCA.XFavorability.SkillCvTimeLimit then
        return
    end
    XMVCA.XFavorability._Model._LastPlaySkillCvTime = now
    XMVCA.XFavorability:PlayCvByType(characterId,XEnumConst.Favorability.SoundEventType.SkillUp)
end
----------private end----------

return XFavorabilityAgency