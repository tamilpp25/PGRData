local XUiRpgMakerGamePanelWinTip = XClass(nil, "XUiRpgMakerGamePanelWinTip")

function XUiRpgMakerGamePanelWinTip:Ctor(ui, tipOutCb, tipNextCb, tipResetCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TipOutCb = tipOutCb
    self.TipNextCb = tipNextCb
    self.TipResetCb = tipResetCb

    XUiHelper.RegisterClickEvent(self, self.BtnTipOut, self.OnBtnTipOutClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTipNext, self.OnBtnTipNextClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTipReset, self.OnBtnTipResetClick)

    self:InitUi()
end

function XUiRpgMakerGamePanelWinTip:InitUi()
    local panelText
    for i = 1, XRpgMakerGameConfigs.MaxStarCount do
        panelText = self["PanelText" .. i]
        if panelText then
            self["PanelLose" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelLose")
            self["TxtUnActive" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelLose/TextInfo1", "Text")
            self["PanelClear" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelClear")
            self["TxtActive" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelClear/TextInfo1", "Text")
            self["TextNumActive" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelClear/TextNum", "Text")
            self["PanelFinish" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelFinish")
            self["TxtFinish" .. i] = XUiHelper.TryGetComponent(panelText.transform, "PanelFinish/TextInfo1", "Text")
        end
    end

    self.BtnTipReset.gameObject:SetActiveEx(true)
end

function XUiRpgMakerGamePanelWinTip:Show(stageId)
    self.StageId = stageId

    local nextStageId = XRpgMakerGameConfigs.GetRpgMakerGameNextStageId(stageId)
    local isHaveNextStage = XTool.IsNumberValid(nextStageId)
    self.BtnTipNext.gameObject:SetActiveEx(isHaveNextStage)

    self:RefreshTxt(stageId)
    self:RefreshStar(stageId)

    self.GameObject:SetActiveEx(true)
end

function XUiRpgMakerGamePanelWinTip:RefreshStar(stageId)
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local stageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerActivityStageDb(stageId)
    local isClear, isShowReward
    for i, starConditionId in ipairs(starConditionIdList) do
        isClear = XDataCenter.RpgMakerGameManager.IsStarConditionClear(starConditionId)
        isShowReward = stageDb:IsShowFirstStarReward(starConditionId)
        self["PanelClear" .. i].gameObject:SetActiveEx(isShowReward)
        self["PanelLose" .. i].gameObject:SetActiveEx(not isClear)
        self["PanelFinish" .. i].gameObject:SetActiveEx(not isShowReward and isClear)

        stageDb:SetFirstStarReward(starConditionId, false)
    end
end

function XUiRpgMakerGamePanelWinTip:RefreshTxt(stageId)
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local starConditionDesc
    for i, starConditionId in ipairs(starConditionIdList) do
        starConditionDesc = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(starConditionId)
        if self["TxtUnActive" .. i] then
            self["TxtUnActive" .. i].text = starConditionDesc
        end
        if self["TxtActive" .. i] then
            self["TxtActive" .. i].text = starConditionDesc
        end
        if self["TxtFinish" .. i] then
            self["TxtFinish" .. i].text = starConditionDesc
        end
        if self["TextNumActive" .. i] then
            self["TextNumActive" .. i].text = string.format("x%s", XRpgMakerGameConfigs.GetStarConditionReward(starConditionId))
        end
        self["PanelText" .. i].gameObject:SetActiveEx(true)
    end

    for i = #starConditionIdList + 1, XRpgMakerGameConfigs.MaxStarCount do
        self["PanelText" .. i].gameObject:SetActiveEx(false)
    end
    if self.TxtMiaoSu then self.TxtMiaoSu.gameObject:SetActiveEx(false) end
end

function XUiRpgMakerGamePanelWinTip:Hide()
    self.GameObject:SetActiveEx(false)
end

--回到活动主界面
function XUiRpgMakerGamePanelWinTip:OnBtnTipOutClick()
    if self.TipOutCb then
        self:Hide()
        self.TipOutCb()
    end
end

--进入下一关
function XUiRpgMakerGamePanelWinTip:OnBtnTipNextClick()
    if self.TipNextCb then
        self:Hide()
        self.TipNextCb()
    end
end

--重置当前关卡
function XUiRpgMakerGamePanelWinTip:OnBtnTipResetClick()
    if self.TipResetCb and self.TipResetCb() then
        self:Hide()
    end
end

return XUiRpgMakerGamePanelWinTip