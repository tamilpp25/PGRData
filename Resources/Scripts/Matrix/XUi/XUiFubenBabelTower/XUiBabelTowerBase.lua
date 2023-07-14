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

    XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiBabelTowerBase:OnStart(stageId, teamId, enterFightCb)
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
    self.ChallengeBuffInfos = {}
    self.SupportBuffInfos = {}
    self.IsFirstOpenChildSupport = true
    self.EnterFightCb = enterFightCb

    self.CurrentPhase = XFubenBabelTowerConfigs.ChallengePhase

    self:SetBabelTowerPhase()

    -- 显示红点
    self:ShowEnvirementDot()
end

function XUiBabelTowerBase:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiBabelTowerBase:OnEnable()
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
    local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not curActivityNo or not XDataCenter.FubenBabelTowerManager.IsInActivityTime(curActivityNo) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
        XLuaUiManager.RunMain()
    end
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
    self.CurrentPhase = XFubenBabelTowerConfigs.SupportPhase
    self:SetBabelTowerPhase()
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

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    XDataCenter.FubenBabelTowerManager.SelectBabelTowerStage(self.StageId, self.GuideId, self.TeamList, challengeBuffs, supportBuffs, function()
        XDataCenter.FubenBabelTowerManager.SaveCurStageInfo(self.StageId, self.TeamId, self.GuideId, self.TeamList, challengeBuffs, supportBuffs, captainPos, selectDifficult, firstFightPos)

        if XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId) then
            XDataCenter.FubenBabelTowerManager.UpdateBuffListCache(self.StageId, challengeBuffs, self.TeamId)
        end

        XDataCenter.FubenBabelTowerManager.UpdateSupportBuffListCache(self.StageId, supportBuffs, self.TeamId)
        XDataCenter.FubenBabelTowerManager.SetTeamChace(self.StageId, self.TeamId, self.TeamList, captainPos, firstFightPos)

        XDataCenter.FubenManager.EnterBabelTowerFight(buffStageId, self.TeamList, function()
            if self.EnterFightCb then self:EnterFightCb() end
        end, captainPos, firstFightPos)
    end, selectDifficult, self.TeamId)
end

function XUiBabelTowerBase:UpdateTeamList(teamList, captainPos, firstFightPos)
    self.TeamList = teamList
    self.CaptainPos = captainPos
    self.FirstFightPos = firstFightPos
end

function XUiBabelTowerBase:UpdateChallengeBuffInfos(choosedChallengeList)
    self.ChallengeBuffInfos = choosedChallengeList

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
        self.BtnLast.gameObject:SetActiveEx(false)
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