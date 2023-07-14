--######################## XUiReformStageGrid ########################
local XUiReformStageGrid = XClass(nil, "XUiReformStageGrid")

function XUiReformStageGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BaseStage = nil
    self.ClickProxy = nil
    self.ClickCallback = nil
    self.Index = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
    self.IsArriveMaxScore = false
end

function XUiReformStageGrid:SetData(baseStage, index)
    self.BaseStage = baseStage
    self.Index = index
    -- 名字
    self.BtnSelf:SetNameByGroup(0, baseStage:GetName())
    self:RefreshStatus()
    self.Red.gameObject:SetActiveEx(XDataCenter.ReformActivityManager.CheckBaseStageIsShowRedDot(baseStage:GetId()))
    -- 设置分数
    local score = self.BaseStage:GetAccumulativeScore()
    self.BtnSelf:SetNameByGroup(1, score)
    -- 设置分数进度条
    local accumulativeScore = self.BaseStage:GetAccumulativeScore()
    local maxChallengeScore = self.BaseStage:GetMaxChallengeScore(true)
    local progressScore = 0
    if maxChallengeScore > 0 then
        progressScore = accumulativeScore / maxChallengeScore
    end
    local isOverRecommendScore = accumulativeScore >= self.BaseStage:GetRecommendScore()
    for i = 1, 3 do
        self["ImgBlueSlider" .. i].gameObject:SetActiveEx(isOverRecommendScore)
        self["ImgBlueSlider" .. i].fillAmount = progressScore
    end
    for i = 1, 2 do
        self["ImgGreenSlider" .. i].gameObject:SetActiveEx(not isOverRecommendScore)
        self["ImgGreenSlider" .. i].fillAmount = progressScore
    end
    self.ImgMax.gameObject:SetActiveEx(progressScore >= 1)
    self.IsArriveMaxScore = progressScore >= 1
end

function XUiReformStageGrid:RefreshStatus()
    local isUnlock = self.BaseStage:GetIsUnlock()
    local isSelected = self.BaseStage:GetId() == XDataCenter.ReformActivityManager.GetCurrentBaseStageId(self.BaseStage:GetStageType())
    local isShowCurrency = isUnlock
    self.Currency1.gameObject:SetActiveEx(isShowCurrency)
    self.Currency2.gameObject:SetActiveEx(isShowCurrency)
    self.Currency3.gameObject:SetActiveEx(isShowCurrency)
    if not isUnlock then
        -- 解锁时间
        self.TxtUnlockTime.text = XUiHelper.GetText("ReformBaseStageUnlockText", self.BaseStage:GetUnlockTimeStr())
        self.BtnSelf:SetButtonState(CS.UiButtonState.Disable)
        self.Select.gameObject:SetActiveEx(false)
    else
        -- 是否选中
        local isSelected = self.BaseStage:GetId() == XDataCenter.ReformActivityManager.GetCurrentBaseStageId(self.BaseStage:GetStageType())
        self:SetSelectStatus(isSelected)
    end
end

function XUiReformStageGrid:SetClickCallBack(clickProxy, clickCallback)
    self.ClickProxy = clickProxy
    self.ClickCallback = clickCallback
end

function XUiReformStageGrid:SetSelectStatus(value)
    if not self.BaseStage:GetIsUnlock() then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Disable)
        self.Select.gameObject:SetActiveEx(false)
        return
    end
    self.Select.gameObject:SetActiveEx(value)
    if value then
        -- self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
        self.NormalNotMax.gameObject:SetActiveEx(not self.IsArriveMaxScore)
        self.NormalMax.gameObject:SetActiveEx(self.IsArriveMaxScore)
    end
end

function XUiReformStageGrid:OnBtnSelfClicked()
    if self.ClickCallback then
        self.ClickCallback(self.ClickProxy, self.Index)
    end
    if self.BaseStage:GetIsUnlock() then
        XDataCenter.ReformActivityManager.SetBaseStageRedDotHistory(self.BaseStage:GetId())
        self.Red.gameObject:SetActiveEx(XDataCenter.ReformActivityManager.CheckBaseStageIsShowRedDot(self.BaseStage:GetId()))
    end
end

--######################## XUiReformStageGridContainer ########################
local XUiReformStageGridContainer = XClass(nil, "XUiReformStageGridContainer")

function XUiReformStageGridContainer:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.GridNormal = XUiReformStageGrid.New(self.GridStageNormal)
    self.GridHard = XUiReformStageGrid.New(self.GridStageHard)
    self.StageType = XReformConfigs.StageType.Normal
    self.BaseStage = nil
end

function XUiReformStageGridContainer:SetData(baseStage, index)
    self.BaseStage = baseStage
    self.StageType = baseStage:GetStageType()
    self.GridNormal.GameObject:SetActiveEx(self.StageType == XReformConfigs.StageType.Normal)
    self.GridHard.GameObject:SetActiveEx(self.StageType == XReformConfigs.StageType.Challenge)
    if self.StageType == XReformConfigs.StageType.Normal then
        self.GridNormal:SetData(baseStage, index)
    elseif self.StageType == XReformConfigs.StageType.Challenge then
        self.GridHard:SetData(baseStage, index)
    end
end

function XUiReformStageGridContainer:SetClickCallBack(clickProxy, clickCallback)
    if self.StageType == XReformConfigs.StageType.Normal then
        self.GridNormal:SetClickCallBack(clickProxy, clickCallback)
    elseif self.StageType == XReformConfigs.StageType.Challenge then
        self.GridHard:SetClickCallBack(clickProxy, clickCallback)
    end
end

function XUiReformStageGridContainer:RefreshStatus()
    if self.StageType == XReformConfigs.StageType.Normal then
        self.GridNormal:RefreshStatus()
    elseif self.StageType == XReformConfigs.StageType.Challenge then
        self.GridHard:RefreshStatus()
    end
end

function XUiReformStageGridContainer:SetSelectStatus(value)
    if self.StageType == XReformConfigs.StageType.Normal then
        self.GridNormal:SetSelectStatus(value)
    elseif self.StageType == XReformConfigs.StageType.Challenge then
        self.GridHard:SetSelectStatus(value)
    end
end

return XUiReformStageGridContainer