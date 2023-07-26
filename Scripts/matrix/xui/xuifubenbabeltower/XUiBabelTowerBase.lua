---@class UiBabelTowerBase : XLuaUi
local XUiBabelTowerBase = XLuaUiManager.Register(XLuaUi, "UiBabelTowerBase")

function XUiBabelTowerBase:OnAwake()
    local itemId = XDataCenter.ItemManager.ItemId
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnNext.CallBack = function() self:OnBtnNextClick() end
    self.BtnLast.CallBack = function() self:OnBtnLastClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnEnvironment.CallBack = function() self:OnBtnEnvironmentClick() end

    self.ActivityType = nil

    -- XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiBabelTowerBase:OnStart(stageId, teamId)
    local cacheTeamData = XDataCenter.FubenBabelTowerManager.GetCacheTeam(stageId, teamId)
    local teamList = cacheTeamData.TeamData
    local captainPos = cacheTeamData.CaptainPos
    local firstFightPos = cacheTeamData.FirstFightPos

    self.StageId = stageId
    local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    self.GuideId = stageTemplate.StageGuideId[1]
    self.TeamId = teamId
    self.TeamList = teamList
    self.CaptainPos = captainPos
    self.FirstFightPos = firstFightPos
    self.ProtectRobotCount = stageTemplate.ProtectRobotCount or 0
    self.ChallengeBuffInfos = {}
    self.SupportBuffInfos = {}
    -- 失效的词条Id
    self.LoseEfficacyBuffIds = {}
    self.IsFirstOpenChildSupport = true
    self.CurrentPhase = XFubenBabelTowerConfigs.ChallengePhase

    self.ActivityType = XDataCenter.FubenBabelTowerManager.GetActivityTypeByStageId(stageId)

    self:SetChallengeBuffLoseEfficacy()
    self:SetBabelTowerPhase()

    -- 显示红点
    self:ShowEnvirementDot()
    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(self.ActivityType)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
        end
    end)
end

function XUiBabelTowerBase:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiBabelTowerBase:OnEnable()
    XUiBabelTowerBase.Super.OnEnable(self)
    self:CheckActivityStatus()

    if not self.FirstOpenDiffcultUi then
        self:FindChildUiObj(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI):OnClickBtnDifficult()
        self.FirstOpenDiffcultUi = true
    end

    if XDataCenter.FubenBabelTowerManager.IsNeedShowUiDifficult() then
        XDataCenter.FubenBabelTowerManager.SetNeedShowUiDifficult(nil)
        self:FindChildUiObj(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI):OnClickBtnDifficult()
    end
end

function XUiBabelTowerBase:OnReleaseInst()
    return self.FirstOpenDiffcultUi
end

function XUiBabelTowerBase:OnResume(value)
    self.FirstOpenDiffcultUi = value
end

function XUiBabelTowerBase:CheckActivityStatus()
    if not XLuaUiManager.IsUiShow("UiBabelTowerBase") then return end
    XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
end

function XUiBabelTowerBase:OnBtnBackClick()
    if self.CurrentPhase and self.CurrentPhase == XFubenBabelTowerConfigs.SupportPhase then
        local supportBuffs = self:GetHandleSupportBuffs()
        XDataCenter.FubenBabelTowerManager.UpdateSupportBuffListCache(self.StageId, supportBuffs, self.TeamId)
        self:Switch2ChallengePhase()
    else
        self:Close()
    end
end

function XUiBabelTowerBase:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBabelTowerBase:OnBtnNextClick()
    self:Switch2SupportPhase()
end

function XUiBabelTowerBase:Switch2SupportPhase()
    self:CheckAffixLevel(function()
        self.CurrentPhase = XFubenBabelTowerConfigs.SupportPhase
        self:SetBabelTowerPhase()
    end)
end

function XUiBabelTowerBase:OnBtnLastClick()
    local supportBuffs = self:GetHandleSupportBuffs()
    XDataCenter.FubenBabelTowerManager.UpdateSupportBuffListCache(self.StageId, supportBuffs, self.TeamId)
    self:Switch2ChallengePhase()
end

function XUiBabelTowerBase:Switch2ChallengePhase()
    self.CurrentPhase = XFubenBabelTowerConfigs.ChallengePhase
    self:SetBabelTowerPhase()
end

function XUiBabelTowerBase:GetHandleSupportBuffs()
    local supportBuffs = {}
    for i = 1, #self.SupportBuffInfos do
        local buffItem = self.SupportBuffInfos[i]
        table.insert(supportBuffs, {
            GroupId = buffItem.BuffGroupId,
            BufferId = buffItem.SelectBuffId
        })
    end
    return supportBuffs
end

function XUiBabelTowerBase:OnBtnFightClick()
    local buffStageId = -1
    -- challenge_buff
    local challengeBuffs = {}

    for i = 1, #self.ChallengeBuffInfos do
        local buffItem = self.ChallengeBuffInfos[i]
        table.insert(challengeBuffs, {
            GroupId = buffItem.BuffGroupId,
            BufferId = buffItem.SelectBuffId
        })

        local buffConfig = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffItem.SelectBuffId)
        if buffStageId <= 0 and buffConfig and buffConfig.StageId > 0 then
            buffStageId = buffConfig.StageId
        end
    end


    if buffStageId <= 0 then
        buffStageId = self.StageId
    end

    -- self.StageId = buffStageId
    -- support_buff
    local supportBuffs = self:GetHandleSupportBuffs()


    -- 能否战斗
    local isUnlock, description = XDataCenter.FubenBabelTowerManager.IsBabelStageUnlock(self.StageId)
    if not isUnlock then
        XUiManager.TipMsg(description)
        return
    end

    -- 是否有队长
    local captainPos = self.CaptainPos
    local captainId = self.TeamList[captainPos]
    if captainId == nil or captainId <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerPleaseSelectALeader"))
        return
    end

    -- 是否有首发
    local firstFightPos = self.FirstFightPos
    local firFightId = self.TeamList[firstFightPos]
    if firFightId == nil or firFightId <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerPleaseSelectAFirstFight"))
        return
    end

    local onFight = function()
        local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
        XDataCenter.FubenBabelTowerManager.SelectBabelTowerStage(self.StageId, self.GuideId, self.TeamList, challengeBuffs, supportBuffs, function()
            XDataCenter.FubenBabelTowerManager.SaveCurStageInfo(self.StageId, self.TeamId, self.GuideId, self.TeamList, challengeBuffs, supportBuffs, captainPos, selectDifficult, firstFightPos)

            if XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId) then
                XDataCenter.FubenBabelTowerManager.UpdateBuffListCache(self.StageId, challengeBuffs, self.TeamId)
            end

            XDataCenter.FubenBabelTowerManager.UpdateSupportBuffListCache(self.StageId, supportBuffs, self.TeamId)
            XDataCenter.FubenBabelTowerManager.SetTeamChace(self.StageId, self.TeamId, self.TeamList, captainPos, firstFightPos)

            XDataCenter.FubenManager.EnterBabelTowerFight(buffStageId, self.TeamList, captainPos, firstFightPos)
        end, selectDifficult, self.TeamId)
    end
    
    self:CheckAbility(onFight)
end

function XUiBabelTowerBase:UpdateTeamList(teamList, captainPos, firstFightPos)
    self.TeamList = teamList
    self.CaptainPos = captainPos
    self.FirstFightPos = firstFightPos
    self:SetChallengeBuffLoseEfficacy()
    self:FilterChoosedChallengeList()
end

function XUiBabelTowerBase:UpdateChallengeBuffInfos(choosedChallengeList)
    self.ChallengeBuffInfos = choosedChallengeList

    -- 更新当前可使用的最大成员数量
    local result = 3
    local limitCount
    for _, buffData in ipairs(choosedChallengeList) do
        limitCount = XFubenBabelTowerConfigs.GetBuffTeamLimitCount(buffData.SelectBuffId)
        result = math.min(limitCount, result)
    end
    XDataCenter.FubenBabelTowerManager.SetMaxTeamMemberCount(result)

    -- 通知检查当前角色是否被禁用
    XEventManager.DispatchEvent(XEventId.EVNET_BABEL_CHALLENGE_BUFF_CHANGED)
end

function XUiBabelTowerBase:UpdateSupportBuffInfos(choosedSupportBuffList)
    self.SupportBuffInfos = choosedSupportBuffList
end

function XUiBabelTowerBase:OnBtnEnvironmentClick()
    local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    local key = string.format(XFubenBabelTowerConfigs.ENVIROMENT_DOT_KEY, tostring(XPlayer.Id), tostring(activityNo), tostring(self.StageId))
    XDataCenter.FubenBabelTowerManager.UpdateBabalPrefsByKey(key, 1)
    self:ShowEnvirementDot()

    XLuaUiManager.Open("UiBabelTowerDetails", XFubenBabelTowerConfigs.TIPSTYPE_ENVIRONMENT, self.StageId)
end

function XUiBabelTowerBase:ShowEnvirementDot()
    local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    local key = string.format(XFubenBabelTowerConfigs.ENVIROMENT_DOT_KEY, tostring(XPlayer.Id), tostring(activityNo), tostring(self.StageId))
    local envir_dot = XDataCenter.FubenBabelTowerManager.GetBabelPrefsByKey(key, 0)
    local hasTouch = envir_dot == 1
    self.BtnEnvironment:ShowReddot(not hasTouch)
end

function XUiBabelTowerBase:SetBabelTowerPhase()
    if not self.CurrentPhase then return end
    if XFubenBabelTowerConfigs.ChallengePhase == self.CurrentPhase then
        self.BtnNext.gameObject:SetActiveEx(true)
        self.BtnLast.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)

        self:OpenOneChildUi(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI, self, self.StageId, self.GuideId, self.TeamId)
        self:FindChildUiObj(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI):PlayAnimation("AnimStartEnable")
        if XLuaUiManager.IsUiShow(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI) then
            self:FindChildUiObj(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI):Close()
        end
    end

    if XFubenBabelTowerConfigs.SupportPhase == self.CurrentPhase then
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLast.gameObject:SetActiveEx(true)
        self.BtnFight.gameObject:SetActiveEx(true)

        self:OpenOneChildUi(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI, self, self.StageId, self.GuideId, self.TeamId, self.TeamList, self.CaptainPos, self.FirstFightPos)
        if not self.IsFirstOpenChildSupport then
            self:FindChildUiObj(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI):RestoreSupportBuff()
        else
            self.IsFirstOpenChildSupport = false
        end
        self:FindChildUiObj(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI):PlayAnimation("AnimStartEnable")
        if XLuaUiManager.IsUiShow(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI) then
            self:FindChildUiObj(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI):Close()
        end
    end
    self:SwitchBg()
end

function XUiBabelTowerBase:SwitchBg()
    local stageConfig = XFubenBabelTowerConfigs.GetBabelStageConfigs(self.StageId)
    if XFubenBabelTowerConfigs.ChallengePhase == self.CurrentPhase then
        self.BgImage:SetRawImage(stageConfig.ChallengeUiBg)
    end

    if XFubenBabelTowerConfigs.SupportPhase == self.CurrentPhase then
        self.BgImage:SetRawImage(stageConfig.SupportUiBg)
    end
end

function XUiBabelTowerBase:GetCurChallengeScore(challengeList)
    local totalChallengeScore = 0
    if self.stageTemplate then
        totalChallengeScore = self.stageTemplate.BaseScore
    end
    for _, v in pairs(challengeList or {}) do
        local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(v.SelectBuffId)
        totalChallengeScore = totalChallengeScore + (buffTemplate.ScoreAdd or 0)
    end

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(self.StageId, selectDifficult)
    return math.floor(totalChallengeScore * ratio)
end

function XUiBabelTowerBase:GetCurAllChallengeScore()
    local challengeBuffGroup = {}
    local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)
    for i = 1, #stageTemplate.ChallengeBuffGroup do
        local groupId = stageTemplate.ChallengeBuffGroup[i]
        local buffGroupTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(groupId)
        local buffId = buffGroupTemplate.BuffId[#buffGroupTemplate.BuffId] --取分数最大的一个
        local isLock = self:IsBuffLock(buffId)
        if not isLock then
            table.insert(challengeBuffGroup, { SelectBuffId = buffId })
        end
    end
    
    return self:GetCurChallengeScore(challengeBuffGroup)
end

function XUiBabelTowerBase:IsBuffLock(buffId, lockCallback, loseCallback)
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local openLevel = XFubenBabelTowerConfigs.GetStageDifficultLockBuffIdOpenLevel(self.StageId, buffId)
    local isLock = openLevel and openLevel ~= 0 and selectDifficult <= openLevel or false
    local isLoseEfficacy = self:CheckBuffIdLoseEfficacy(buffId)
    if isLock and lockCallback then
        lockCallback()
    end
    if isLoseEfficacy and loseCallback then
        loseCallback()
    end
    return isLock or isLoseEfficacy
end

-- @Desc 检查词缀等级
function XUiBabelTowerBase:CheckAffixLevel(callBack)
    --[[
        1.如果玩家当前选择词缀的【总词缀等级=当前所有可选词缀的总等级】，则不进行任何提示
        2.如果玩家当前的已选词缀的【总词缀等级＞先前最高词缀等级】 ，则不进行任何提示
        3.如果玩家当前的选择词缀的【总词缀等级≤先前最高词缀等级】， 则显示提示
    ]]
    local curSelectLevel = self:GetCurChallengeScore(self.ChallengeBuffInfos)
    local allLevel = self:GetCurAllChallengeScore()
    local maxLevel = XDataCenter.FubenBabelTowerManager.GetTeamMaxScore(self.StageId, self.TeamId)
    local value = XDataCenter.FubenBabelTowerManager.GetBabelTowerInfo(XFubenBabelTowerConfigs.AFFIX_LEVEL_INADEQUATE_KEY, false)
    if curSelectLevel == allLevel or curSelectLevel > maxLevel or value then
        callBack()
    else
        local warnInfo = {
            Title = CsXTextManagerGetText("BabelTowerAffixLevelInadequateTitle"),
            Content = CSXTextManagerGetText("BabelTowerAffixLevelInadequateContent"),
            IsWarning = false,
            HintInfo = {
                HintClickName = "BtnNoWarning",
                HintCb = function(isSelect)
                    XDataCenter.FubenBabelTowerManager.SaveBabelTowerInfo(XFubenBabelTowerConfigs.AFFIX_LEVEL_INADEQUATE_KEY, isSelect)
                end,
                Status = false,
            },
        }
        XLuaUiManager.Open("UiBabelTowerMainNewTips", nil, warnInfo, nil, callBack)
    end
end

-- @Desc 检查战力
function XUiBabelTowerBase:CheckAbility(callBack)
    -- 所选 buff 最高战力
    local buffMaxAbility = 0
    for _, v in pairs(self.ChallengeBuffInfos or {}) do
        local buffConfigs = XFubenBabelTowerConfigs.GetBabelBuffConfigs(v.SelectBuffId)
        local buffAbility = buffConfigs.BuffSuggestAbility or 0
        if buffAbility > buffMaxAbility then
            buffMaxAbility = buffAbility
        end
    end
    --队伍里最高战力
    local playerMaxAbility = 0
    for _, characterId in pairs(self.TeamList or {}) do
        if XTool.IsNumberValid(characterId) then
            local playerAbility = XEntityHelper.GetCharacterAbility(characterId) or 0
            if playerAbility > playerMaxAbility then
                playerMaxAbility = playerAbility
            end
        end
    end
    -- 当前难度推荐战力
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local recommendAbility = XFubenBabelTowerConfigs.GetStageDifficultRecommendAblity(self.StageId, selectDifficult)
    -- 是否不在提示
    local activityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    local key = string.format(XFubenBabelTowerConfigs.ABILITY_WARNING_KEY, tostring(XPlayer.Id), tostring(activityNo), tostring(self.StageId))
    local value = XDataCenter.FubenBabelTowerManager.GetBabelPrefsByKey(key, false)
    --[[
    1.当玩家最高战力大于等于所有所选BUFF的战力需求时，视为满足条件
    2.当玩家最高战力大于等于所选难度的战力需求时，视为满足条件
    3.若条件1,2同时满足条件，则不显示提示弹窗，否则显示提示弹窗
    ]]
    if (playerMaxAbility >= buffMaxAbility and playerMaxAbility >= recommendAbility) or value then
        callBack()
    else
        local warnInfo = {
            Title = CsXTextManagerGetText("BabelTowerAbilityWarningTitle"),
            Content = CSXTextManagerGetText("BabelTowerAbilityWarningContent"),
            IsWarning = true,
            HintInfo = {
                HintClickName = "BtnNoWarning2",
                HintCb = function(isSelect)
                    XDataCenter.FubenBabelTowerManager.UpdateBabalPrefsByKey(key, isSelect)
                end,
                Status = false,
            },
        }
        local changeRole = function()
            self:FindChildUiObj(XFubenBabelTowerConfigs.SUPPORT_CHILD_UI):OnBtnGoClick()
        end
        XLuaUiManager.Open("UiBabelTowerMainNewTips", nil, warnInfo, changeRole, callBack)
    end
end

-- 设置失效的词条信息
function XUiBabelTowerBase:SetChallengeBuffLoseEfficacy()
    local isLoseEfficacy = self:CheckProtectChallengeBuffLoseEfficacy()
    if not isLoseEfficacy then
        self.LoseEfficacyBuffIds = {}
        return
    end
    if not XTool.IsTableEmpty(self.LoseEfficacyBuffIds) then
        return
    end
    local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)
    local buffGroup = stageTemplate.ProtectChallengeBuffGroup or {}
    for _, groupId in pairs(buffGroup) do
        local buffGroupTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(groupId)
        local buffIds = buffGroupTemplate.BuffId
        self.LoseEfficacyBuffIds = XTool.MergeArray(self.LoseEfficacyBuffIds, buffIds)
    end
end

-- 过滤失效的词条
function XUiBabelTowerBase:FilterChoosedChallengeList()
    local isHaveLoseBuff = self:ShowBuffLoseEfficacyTip()
    if not isHaveLoseBuff then
        return
    end
    -- 刷新选择的词条
    local childChallenge = self:FindChildUiObj(XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI)
    if childChallenge then
        childChallenge:FilterChoosedChallengeList()
    end
end

-- 检测保护的词条组是否失效（当满足对应的机器人数量时，对应配置的保护词条组失效）
function XUiBabelTowerBase:CheckProtectChallengeBuffLoseEfficacy()
    if XTool.IsTableEmpty(self.TeamList) then
        return false
    end
    local robotCount = 0
    for _, entitiyId in pairs(self.TeamList) do
        if XEntityHelper.GetIsRobot(entitiyId) then
            robotCount = robotCount + 1
        end
    end
    if XTool.IsNumberValid(self.ProtectRobotCount) and robotCount >= self.ProtectRobotCount then
        return true
    end
    return false
end

-- 显示buff失效弹框
function XUiBabelTowerBase:ShowBuffLoseEfficacyTip()
    -- 是否有选择的词条失效
    local isHaveLoseBuff = false
    for _, info in pairs(self.ChallengeBuffInfos or {}) do
        local isContain = self:CheckBuffIdLoseEfficacy(info.SelectBuffId)
        if isContain then
            isHaveLoseBuff = true
            break
        end
    end
    -- 弹出提示
    if isHaveLoseBuff then
        local babelTowerStageCfg = XFubenBabelTowerConfigs.GetBabelStageConfigs(self.StageId)
        local protectTipText = babelTowerStageCfg.ProtectTipText or ""
        if not string.IsNilOrEmpty(protectTipText) then
            XUiManager.TipMsg(protectTipText)
        end
    end
    return isHaveLoseBuff
end

-- 检测词条Id是否失效
function XUiBabelTowerBase:CheckBuffIdLoseEfficacy(buffId)
    if XTool.IsTableEmpty(self.LoseEfficacyBuffIds) then
        return false
    end
    return table.contains(self.LoseEfficacyBuffIds, buffId)
end