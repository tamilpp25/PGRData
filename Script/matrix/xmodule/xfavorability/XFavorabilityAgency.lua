---@class XFavorabilityAgency : XAgency
---@field private _Model XFavorabilityModel
local XFavorabilityAgency = XClass(XAgency, "XFavorabilityAgency")
local SignBoardCondition = {
    --邮件
    [XEnumConst.Favorability.XSignBoardEventType.MAIL] = function()
        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
        return mailAgency:GetHasUnDealMail() > 0
    end,

    --任务
    [XEnumConst.Favorability.XSignBoardEventType.TASK] = function()
        if XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Story) then
            return true
        end

        if XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskDay) and XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Daily) then
            return true
        end

        if XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskActivity) and XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Activity) then
            return true
        end

        return false
    end,

    --日活跃
    [XEnumConst.Favorability.XSignBoardEventType.DAILY_REWARD] = function()
        return XDataCenter.TaskManager.CheckHasDailyActiveTaskReward()
    end,

    --登陆
    [XEnumConst.Favorability.XSignBoardEventType.LOGIN] = function(control,param)
        local loginTime = control._Model._LoginTime
        local offset = XTime.GetServerNowTimestamp() - loginTime

        return offset <= param
    end,

    --n天没登陆
    [XEnumConst.Favorability.XSignBoardEventType.COMEBACK] = function(control,param)
        local lastLoginTime = control._Model._LastLoginTime
        local todayTime = XTime.GetTodayTime()
        local offset = todayTime - lastLoginTime
        local day = math.ceil(offset / 86400)
        return day >= param
    end,

    --收到礼物
    [XEnumConst.Favorability.XSignBoardEventType.RECEIVE_GIFT] = function()
        return false
    end,

    --赠送礼物
    [XEnumConst.Favorability.XSignBoardEventType.GIVE_GIFT] = function(control,param, displayCharacterId, eventParam)
        if eventParam == nil then
            return false
        end

        return eventParam.CharacterId == displayCharacterId
    end,

    --战斗胜利
    [XEnumConst.Favorability.XSignBoardEventType.WIN] = function(control)
        local signBoardEvent = control._Model._SignBoarEvents
        if signBoardEvent[XEnumConst.Favorability.XSignBoardEventType.WIN] then
            return true
        end
    end,

    --战斗胜利
    [XEnumConst.Favorability.XSignBoardEventType.WINBUT] = function(control)
        local signBoardEvent = control._Model._SignBoarEvents
        if signBoardEvent[XEnumConst.Favorability.XSignBoardEventType.WINBUT] then
            return true
        end
    end,

    --战斗失败
    [XEnumConst.Favorability.XSignBoardEventType.LOST] = function(control)
        local signBoardEvent = control._Model._SignBoarEvents
        if signBoardEvent[XEnumConst.Favorability.XSignBoardEventType.LOST] then
            return true
        end
    end,

    --战斗失败
    [XEnumConst.Favorability.XSignBoardEventType.LOSTBUT] = function(control)
        local signBoardEvent = control._Model._SignBoarEvents
        if signBoardEvent[XEnumConst.Favorability.XSignBoardEventType.LOSTBUT] then
            return true
        end
    end,

    --电量
    [XEnumConst.Favorability.XSignBoardEventType.LOW_POWER] = function(control,param)
        return XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint) <= param
    end,


    --游戏时间
    [XEnumConst.Favorability.XSignBoardEventType.PLAY_TIME] = function(control,param)
        local loginTime = control._Model._LoginTime
        local offset = XTime.GetServerNowTimestamp() - loginTime
        return offset >= param
    end,


    --长时间待机
    [XEnumConst.Favorability.XSignBoardEventType.IDLE] = function()
        return true
    end,

    --换人
    [XEnumConst.Favorability.XSignBoardEventType.CHANGE] = function(control,param, displayCharacterId)
        return displayCharacterId == control._Model._ChangeDisplayId
    end,

    --好感度提升
    [XEnumConst.Favorability.XSignBoardEventType.FAVOR_UP] = function()
        return true
    end,
}
--私有方法预定义
local InitCharacterData=nil
local OnCollectCharacterReward=nil
local NotifyFiveTwentyRecord=nil
local OnCharacterTrustInfoUpdate=nil
local PlayCharacterSkillUpOrUnlockCv=nil
local OnLoginSuccessEvent=nil
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
    self._UnlockRewardFunc[XEnumConst.Favorability.RewardUnlockType.FightAbility] = function()
        -- local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        -- local curCharacterAbility = characterData.Ability or 0
        return false
        -- return math.ceil(curCharacterAbility) >= target
    end
    -- [信赖度达到target]
    self._UnlockRewardFunc[XEnumConst.Favorability.RewardUnlockType.TrustLv] = function(characterId, target)
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        local trustLv = characterData.TrustLv or 1
        return trustLv >= target
    end
    -- [角色等级达到target]
    self._UnlockRewardFunc[XEnumConst.Favorability.RewardUnlockType.CharacterLv] = function(characterId, target)
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
        local characterLevel = characterData.Level or 1
        return characterLevel >= target
    end
    -- [进化至target]
    self._UnlockRewardFunc[XEnumConst.Favorability.RewardUnlockType.Quality] = function(characterId, target)
        local characterData = XMVCA.XCharacter:GetCharacter(characterId)
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

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, OnLoginSuccessEvent,self)
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
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_SUCCESS, OnLoginSuccessEvent,self)
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

function XFavorabilityAgency:OpenUiStory(characterId)
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiFavorabilityStory", characterId)
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
    local currLevel = self:GetCurrCharacterFavorabilityLevel(characterId)
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
    if not characterId or characterId == 0 or XRobotManager.CheckIsRobotId(characterId) then return end

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

    if cvData.CvContent.Count < cvType then
        return ""
    end
    
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

--region signboard
function XFavorabilityAgency:CheckCurSceneAnimIsGachaLamiya()
    if not self._Model._sceneAnim then
        return false
    end
    return self._Model._sceneAnim.SignBoardId == 1270314
end

--获取角色所有事件
function XFavorabilityAgency:GetSignBoardConfigByRoldIdAndCondition(roleId, conditionId)
    self._Model:CheckSignBoardDataDone()
    local all = {}

    if self._Model._TableSignBoardRoleIdIndexs and self._Model._TableSignBoardRoleIdIndexs[roleId] then
        local configs = self._Model._TableSignBoardRoleIdIndexs[roleId][conditionId]
        if configs then
            for _, v in ipairs(configs) do
                table.insert(all, v)
            end
        end
    end

    if self._Model._TableSignBoardIndexs and self._Model._TableSignBoardIndexs[conditionId] then
        for _, v in ipairs(self._Model._TableSignBoardIndexs[conditionId]) do
            table.insert(all, v)
        end
    end

    return all
end

--根据操作获取表数据
function XFavorabilityAgency:GetSignBoardConfigByFeedback(roleId, conditionId, param)
    if not self._Model._TableSignBoardRoleIdIndexs then
        return
    end

    local configs = self:GetSignBoardConfigByRoldIdAndCondition(roleId, conditionId)


    if not configs or #configs <= 0 then
        return
    end

    if not param or param < 0 then
        return configs
    end


    local fitterCfg = {}

    if conditionId == XEnumConst.Favorability.XSignBoardEventType.CLICK then

        for _, var in ipairs(configs) do
            if var.ConditionParam < 0 or var.ConditionParam == param then
                table.insert(fitterCfg, var)
            end
        end
    elseif conditionId == XEnumConst.Favorability.XSignBoardEventType.ROCK then

        for _, var in ipairs(configs) do
            if var.ConditionParam == math.ceil(param) then
                table.insert(fitterCfg, var)
            end
        end
    end

    return fitterCfg
end

function XFavorabilityAgency:GetSignBoardConfigById(id)
    local config=self._Model:GetSignBoardConfig()
    if not config then
        return
    end

    return config[id]
end

-- 判断动作是否有镜头动画
function XFavorabilityAgency:CheckIsHaveSceneAnim(signBoardid)
    local signBoard = self:GetSignBoardConfigById(signBoardid)
    if not signBoard then
        return false
    end
    return not string.IsNilOrEmpty(signBoard.SceneCamAnimPrefab)
end

-- 判断动作是否播放Ui隐藏动画
function XFavorabilityAgency:CheckIsShowHideUi(signBoardid)
    local signBoard = self:GetSignBoardConfigById(signBoardid)
    if not signBoard then
        return false
    end
    return signBoard.IsShowHideUi
end

-- 是否使用自己的Ui动画
function XFavorabilityAgency:CheckIsUseSelfUiAnim(signBoardid, uiName)
    local signBoard = self._Model:GetIsUseSelfUiAnim(signBoardid, uiName)
    return signBoard == XEnumConst.Favorability.XSignBoardUiAnimType.Self
end

-- 是否使用通用的Ui动画
function XFavorabilityAgency:CheckIsUseNormalUiAnim(signBoardid, uiName)
    local signBoard = self._Model:GetIsUseSelfUiAnim(signBoardid, uiName)
    return signBoard == XEnumConst.Favorability.XSignBoardUiAnimType.Normal
end

-- 是否使用位置和旋转
function XFavorabilityAgency:CheckIsUseCamPosAndRot(signBoardid)
    local signBoard = self:GetSignBoardConfigById(signBoardid)
    if not signBoard then
        return false
    end
    return signBoard.IsUseCamPosAndRot == 1
end

-- 通过unlockCondition过滤
function XFavorabilityAgency:FitterPlayElementByUnlockCondition(elements)
    if not elements or #elements <= 0 then
        return
    end

    local configs = {}

    for _, v in ipairs(elements) do
        local isElementPass = true
        for k, condId in pairs(v.UnlockCondition) do
            if not XConditionManager.CheckCondition(condId, tonumber(v.RoleId)) then -- 不知道为什么这个角色id在配表初期时使用string，这里将错就错转number
                isElementPass = false
            end
        end
        if isElementPass then
            table.insert(configs, v)
        end
    end

    return configs
end

--通过待机状态过滤
function XFavorabilityAgency:FitterPlayElementByStandType(elements)

    if not elements or #elements <= 0 then
        return
    end

    local configs = {}

    for _, v in ipairs(elements) do
        if v.StandType == self._Model._StandType then
            table.insert(configs, v)
        end
    end

    return configs
end

--通过显示时间过滤
function XFavorabilityAgency:FitterPlayElementByShowTime(elements)
    if not elements or #elements <= 0 then
        return
    end

    local todayTime = XTime.GetTodayTime(0)

    local configs = {}
    local curTime = XTime.GetServerNowTimestamp()
    for _, v in ipairs(elements) do
        if not v.ShowTime then
            table.insert(configs, v)
        else
            local showTime = string.Split(v.ShowTime, "|")
            if #showTime == 2 then
                local start = tonumber(showTime[1])
                local stop = tonumber(showTime[2])
                if curTime >= todayTime + start and curTime <= stop + todayTime then
                    table.insert(configs, v)
                end
            end
        end
    end

    return configs
end

--通过好感度过滤
function XFavorabilityAgency:FitterPlayElementByFavorLimit(elements, displayCharacterId)
    if not elements or #elements <= 0 then
        return
    end
    local configs = {}
    for _, v in ipairs(elements) do
        local isUnlock , conditionDescript = self:CheckCharacterActionUnlockBySignBoardActionId(v.Id)
        if isUnlock then
            table.insert(configs, v)
        end
    end

    return configs
end

function XFavorabilityAgency:FitterCurLoginPlayed(elements)
    if not elements or #elements <= 0 then
        return
    end

    local configs = {}
    for _, v in ipairs(elements) do
        local key = self:GetSignBoardKey(v)
        if not self._Model._PreLoginPlayedList[key] then
            table.insert(configs, v)
        end
    end

    return configs
end

--获取键值
function XFavorabilityAgency:GetSignBoardKey(signboard)
    local key = string.format("%s_%s_%s", signboard.ShowType, signboard.ConditionId, signboard.ConditionParam)
    return key
end

function XFavorabilityAgency:GetSignBoardPlayerData()
    if not self._Model._PlayerData then
        self._Model._PlayerData = {}
        self._Model._PlayerData.PlayerList = {} --播放列表
        self._Model._PlayerData.PlayingElement = nil --播放对象
        self._Model._PlayerData.PlayedList = {} --播放过的列表
        self._Model._PlayerData.LastPlayTime = -1 --上次播放时间
    end

    return self._Model._PlayerData
end

--通过点击次数获取事件
function XFavorabilityAgency:GetRandomPlayElementsByClick(clickTimes, displayCharacterId)

    local configs = self:GetSignBoardConfigByFeedback(displayCharacterId, XEnumConst.Favorability.XSignBoardEventType.CLICK, clickTimes)
    configs = self:FitterPlayElementByStandType(configs)
    configs = self:FitterCurLoginPlayed(configs)

    configs = self:FitterPlayElementByUnlockCondition(configs)
    configs = self:FitterPlayElementByShowTime(configs)
    configs = self:FitterPlayElementByFavorLimit(configs, displayCharacterId)
    configs = self:FitterPlayed(configs)

    local element = self:WeightRandomSelect(configs)

    if element then
        self._Model._PlayedList[element.Id] = element
    end

    return element
end

--过滤播放过的
function XFavorabilityAgency:FitterPlayed(elements)
    if not elements or #elements <= 0 then
        return
    end

    local configs = {}
    for _, v in ipairs(elements) do
        if not self._Model._PlayedList[v.Id] then
            table.insert(configs, v)
        end
    end

    if #configs <= 0 then
        self._Model._PlayedList = {}
        return elements
    end

    return configs
end

--权重随机算法
function XFavorabilityAgency:WeightRandomSelect(elements)
    if not elements or #elements <= 0 then
        return
    end

    if #elements == 1 then
        return elements[1]
    end

    --获取权重总和
    local sum = 0
    for _, v in ipairs(elements) do
        sum = sum + v.Weight
    end

    --设置随机数种子
    math.randomseed(os.time())

    --随机数加上权重，越大的权重，数值越大
    local weightList = {}
    for i, v in ipairs(elements) do
        local rand = math.random(0, sum)
        local seed = {}
        seed.Index = i
        seed.Weight = rand + v.Weight
        table.insert(weightList, seed)
    end

    --排序
    table.sort(weightList, function(x, y)
        return x.Weight > y.Weight
    end)

    --返回最大的权重值
    local index = weightList[1].Index
    return elements[index]
end

--记录播放过的看板动作
function XFavorabilityAgency:RecordSignBoard(signboard)
    local showType = signboard.ShowType

    if XEnumConst.Favorability.ShowTimesType.PerLogin == showType then
        local key = self:GetSignBoardKey(signboard)
        self._Model._PreLoginPlayedList[key] = signboard

    elseif XEnumConst.Favorability.ShowTimesType.Daily == showType then

        local nowTimeStamp = XTime.GetServerNowTimestamp()
        local nowTime = XTime.TimestampToLocalDateTimeString(nowTimeStamp, "yyyy-MM-dd")
        local key = self:GetSignBoardKey(signboard)
        CS.UnityEngine.PlayerPrefs.SetString(key, nowTime)
    end

end

-- 移除特殊动作Ui播放事件监听
-- Ui:LuaUi对象
function XFavorabilityAgency:RemoveRoleActionUiAnimListener(ui)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, ui.PlayRoleActionUiDisableAnim, ui)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, ui.PlayRoleActionUiEnableAnim, ui)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, ui.PlayRoleActionUiBreakAnim, ui)
end

-- 添加特殊动作Ui播放事件监听
-- Ui:LuaUi对象
function XFavorabilityAgency:AddRoleActionUiAnimListener(ui)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, ui.PlayRoleActionUiDisableAnim, ui)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, ui.PlayRoleActionUiEnableAnim, ui)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, ui.PlayRoleActionUiBreakAnim, ui)
end

function XFavorabilityAgency:OnBreakClick()
    --垃圾unity
    --安卓模拟器不模拟Input:GetMouseButtonDown(0)
    --安卓不模拟Input:GetTouch(0)，还得加个touchCount判空
    local touchCount = CS.UnityEngine.Input.touchCount
    if CS.UnityEngine.Input:GetMouseButtonDown(0) or (touchCount >= 1 and CS.UnityEngine.Input:GetTouch(0)) then
        self:StopBreakTimer()
        XEventManager.DispatchEvent(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK)
    end
end

-- 监控打断
function XFavorabilityAgency:StartBreakTimer(stopTime)
    self:StopBreakTimer()
    self._Model._StopTime = stopTime
    self._Model._Timer = XScheduleManager.ScheduleForeverEx(function ()
        if self._Model._StopTime < 0 then
            self:StopBreakTimer()
            return
        end
        self._Model._StopTime = self._Model._StopTime - self._Model._Delay / 1000
        self:OnBreakClick()
    end, self._Model._Delay)
end

function XFavorabilityAgency:StopBreakTimer()
    if self._Model._Timer then
        XScheduleManager.UnSchedule(self._Model._Timer)
        self._Model._Timer = nil
    end
    self._Model._StopTime = 0
end

-- 场景动画
----------------------------------------------------------------------------------
function XFavorabilityAgency:LoadSceneAnim(rootNode, farCam, nearCam, sceneId, signBoardId, ui)
    if not self:CheckIsHaveSceneAnim(signBoardId) then
        return
    end
    if not self._Model._sceneAnim:CheckIsSameAnim(sceneId, signBoardId, rootNode) then
        self:UnLoadAnim()
        -- 由于LoadPrefab()加载同url的是相同的gameobject，当不同signBoardId配置相同prefab url时unloadanim会报错
        local prefabName = self._Model:GetSignBoardSceneAnim(signBoardId)
        self._Model._sceneAnimPrefab = CS.XResourceManager.Load(prefabName)
        local animPrefab = XUiHelper.Instantiate(self._Model._sceneAnimPrefab.Asset, rootNode)

        self._Model._sceneAnim:UpdateData(sceneId, signBoardId, ui)
        self._Model._sceneAnim:UpdateAnim(animPrefab, farCam, nearCam)
    end
end

function XFavorabilityAgency:UnLoadAnim()
    if self._Model._sceneAnimPrefab then
        CS.XResourceManager.Unload(self._Model._sceneAnimPrefab)
    end
    if not self._Model._sceneAnim then
        self._Model._sceneAnim = require("XEntity/XSignBoard/XSignBoardCamAnim").New()
    else
        self._Model._sceneAnim:UnloadAnim()
    end
end

function XFavorabilityAgency:SceneAnimPlay()
    if self._Model._sceneAnim then
        self._Model._sceneAnim:Play()
        XEventManager.DispatchEvent(XEventId.EVENT_ACTION_HIDE_UI, self._Model._sceneAnim:GetNodeTransform())
    end
end

function XFavorabilityAgency:SceneAnimPause()
    if self._Model._sceneAnim then
        self._Model._sceneAnim:Pause()
    end
end

function XFavorabilityAgency:SceneAnimResume()
    if self._Model._sceneAnim then
        self._Model._sceneAnim:Resume()
    end
end

function XFavorabilityAgency:SceneAnimStop()
    if self._Model._sceneAnim then
        self._Model._sceneAnim:Close()
    end
end


function XFavorabilityAgency:GetSignBoardConfig()
    return self._Model:GetSignBoardConfig()
end

function XFavorabilityAgency:GetSignBoardConfigByRoldId(roleId)
    return self._Model:GetSignBoardConfigByRoldId(roleId)
end

--获取打断的播放
function XFavorabilityAgency:GetBreakPlayElements()
    return self._Model._TableSignBoardBreak
end

--获取被动事件
function XFavorabilityAgency:GetPassiveSignBoardConfig(roleId)
    if not self._Model:GetSignBoardConfig() then
        return nil
    end

    local roleConfigs = self._Model:GetSignBoardConfigByRoldId(roleId)
    if not roleConfigs then
        return
    end

    local configs = {}
    for _, v in ipairs(roleConfigs) do
        if v.ConditionId < 10000 and v.ConditionId >= 100 then --被动事件少于10000 大于=100
            table.insert(configs, v)
        end
    end

    return configs
end

--获取互动的事件
function XFavorabilityAgency:GetPlayElements(displayCharacterId)
    local elements = self:GetPassiveSignBoardConfig(displayCharacterId)
    if not elements then
        return
    end

    elements = self:FitterPlayElementByUnlockCondition(elements)
    elements = self:FitterPlayElementByStandType(elements)
    elements = self:FitterPlayElementByShowTime(elements)
    elements = self:FitterPlayElementByFavorLimit(elements, displayCharacterId)
    elements = self:FitterCurLoginPlayed(elements)
    elements = self:FitterDailyPlayed(elements)

    local all = {}

    if not elements or #elements <= 0 then
        return {}
    end

    for _, tab in ipairs(elements) do

        local param = self._Model._SignBoarEvents[tab.ConditionId]

        local condition = SignBoardCondition[tab.ConditionId]

        if condition and condition(self,tab.ConditionParam, displayCharacterId, param) then
            local element = {}
            element.Id = tab.Id --Id
            element.AddTime = self._Model._SignBoarEvents[tab.ConditionId] and self._Model._SignBoarEvents[tab.ConditionId].Time or XTime.GetServerNowTimestamp()  -- 添加事件
            element.StartTime = -1 --开始播放的时间
            element.EndTime = -1 --结束时间

            -- 获取相应语言的动作持续时间
            local duration
            local defaultCvType = 1
            local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", defaultCvType)

            if tab.Duration[cvType] == nil then
                if tab.Duration[defaultCvType] == nil then
                    XLog.Error(string.format("XSignBoardPlayer:Play函数错误，配置表SignboardFeedback.tab没有配置Id:%s的Duration数据", tostring(element.Id)))
                    return {}
                end
                duration = tab.Duration[defaultCvType]
            else
                duration = tab.Duration[cvType]
            end

            element.Duration = duration  --播放持续时间
            element.Validity = tab.Validity --有效期
            element.CoolTime = tab.CoolTime --冷却时间
            element.Weight = tab.Weight --权重
            element.SignBoardConfig = tab

            table.insert(all, element)
        end
    end

    table.sort(all, function(a, b)
        return a.Weight > b.Weight
    end)

    self._Model._ChangeDisplayId = -1
    return all
end

---====================================
--- 过滤当天播放过的动作,返回当天未播放过的动作
---@param elements table
---@return table
---====================================
function XFavorabilityAgency:FitterDailyPlayed(elements)
    if not elements or #elements <= 0 then
        return
    end

    local configs = {}
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    local nowTime = XTime.TimestampToLocalDateTimeString(nowTimeStamp, "yyyy-MM-dd")
    local nowTimeTable = string.Split(nowTime, "-")

    for _, v in ipairs(elements) do
        local key = self:GetSignBoardKey(v)

        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            local oldPlayedTime = CS.UnityEngine.PlayerPrefs.GetString(key)
            local oldPlayedTimeTable = string.Split(oldPlayedTime, "-")

            if tonumber(oldPlayedTimeTable[1]) ~= tonumber(nowTimeTable[1])
                    or tonumber(oldPlayedTimeTable[2]) ~= tonumber(nowTimeTable[2])
                    or tonumber(oldPlayedTimeTable[3]) ~= tonumber(nowTimeTable[3]) then
                -- 年或月或日不相等，不是同一天
                table.insert(configs, v)
            end

        else
            table.insert(configs, v)
        end
    end

    return configs
end

--通过摇晃获取事件
function XFavorabilityAgency:GetRandomPlayElementsByRoll(time, displayCharacterId)

    local configs = self:GetSignBoardConfigByFeedback(displayCharacterId, XEnumConst.Favorability.XSignBoardEventType.ROCK)
    configs = self:FitterPlayElementByStandType(configs)
    configs = self:FitterCurLoginPlayed(configs)

    configs = self:FitterPlayElementByUnlockCondition(configs)
    configs = self:FitterPlayElementByShowTime(configs)
    configs = self:FitterPlayElementByFavorLimit(configs, displayCharacterId)
    configs = self:FitterPlayed(configs)

    local element = self:WeightRandomSelect(configs)

    if element then
        self._Model._PlayedList[element.Id] = element
    end

    return element
end

function XFavorabilityAgency:ChangeStandType(standType)
    if standType == self._Model._StandType then
        return
    end

    self._Model._StandType=standType
    self._Model._PlayedList = {}

    return true
end

function XFavorabilityAgency:GetStandType()
    return self._Model._StandType
end

--设置待机类型
function XFavorabilityAgency:SetStandType(standType)
    self._Model._StandType = standType
end

function XFavorabilityAgency:RequestTouchBoard(characterId)
    if self._Model._RequestTouchBoardLock then return end
    self._Model._RequestTouchBoardLock = true
    XScheduleManager.ScheduleOnce(function()
        self._Model._RequestTouchBoardLock = false;
    end, XScheduleManager.SECOND)
    XNetwork.Call(XEnumConst.Favorability.REQUEST_NAME.ClickRequest, {
        CharacterId = characterId
    } , function(response) end)
end

--监听
function XFavorabilityAgency:OnNotify(event, ...)
    if event == XEventId.EVENT_FIGHT_RESULT then
        local displayCharacterId = XDataCenter.DisplayManager.GetDisplayChar().Id

        local settle = ...
        local info = settle[0]
        local isExist = false

        local beginData = XDataCenter.FubenManager.GetFightBeginData()
        if beginData then
            for _, v in pairs(beginData.CharList) do
                if v == displayCharacterId then
                    isExist = true
                    break
                end
            end
        end

        if isExist and info.IsWin then
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WIN] = self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WIN] or {}
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WIN].Time = XTime.GetServerNowTimestamp()
        elseif not isExist and info.IsWin then
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WINBUT] = self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WINBUT] or {}
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.WINBUT].Time = XTime.GetServerNowTimestamp()
        elseif isExist and not info.IsWin then
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOST] = self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOST] or {}
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOST].Time = XTime.GetServerNowTimestamp()
        elseif not isExist and not info.IsWin then
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOSTBUT] = self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOSTBUT] or {}
            self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.LOSTBUT].Time = XTime.GetServerNowTimestamp()
        end

    elseif event == XEventId.EVENT_FAVORABILITY_GIFT then
        local characterId = ...
        self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.GIVE_GIFT] = self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.GIVE_GIFT] or {}
        self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.GIVE_GIFT].Time = XTime.GetServerNowTimestamp()
        self._Model._SignBoarEvents[XEnumConst.Favorability.XSignBoardEventType.GIVE_GIFT].CharacterId = characterId

    end
end
--endregion

-- [好感度-等级名字] 复制自control
function XFavorabilityAgency:GetWordsWithColor(trustLv, name)
    local color = self._Model:GetFavorabilityLevelCfg(trustLv).WordColor
    return string.format("<color=%s>%s</color>", color, name)
end

-- [好感度-等级图标]
function XFavorabilityAgency:GetTrustLevelIconByLevel(level)
    return self._Model:GetFavorabilityLevelCfg(level).LevelIcon
end

----------public end----------

--region----------private start----------
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

OnLoginSuccessEvent=function(self)
    local key = tostring(XPlayer.Id) .. "_LastLoginTime"
    self._Model._LastLoginTime = CS.UnityEngine.PlayerPrefs.GetInt(key, -1)
    self._Model._LoginTime = XTime.GetServerNowTimestamp()
    if self._Model._LastLoginTime == -1 then
        self._Model._LastLoginTime = self._Model._LoginTime
    end
    CS.UnityEngine.PlayerPrefs.SetInt(key, self._Model._LoginTime)
end
--endregion----------private end----------

return XFavorabilityAgency