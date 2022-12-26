XUiPracticeBasicsStage = XClass(nil, "XUiPracticeBasicsStage")

function XUiPracticeBasicsStage:Ctor(rootUi, ui, parent)
    self.RootUi = rootUi
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddBtnsListeners()
end

function XUiPracticeBasicsStage:AddBtnsListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiPracticeBasicsStage:SetNormalStage(isLock, stageId)
    self.PanelStageNormal.gameObject:SetActive(not isLock)
    if not isLock then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        self.TxtFightNameNor.text = stageCfg.Name
        self.RImgFightActiveNor:SetRawImage(stageCfg.Icon)
    end
    if self.PanelActivityTag then
        local inActivity = XDataCenter.PracticeManager.CheckStageInActivity(stageId)
        self.PanelActivityTag.gameObject:SetActiveEx(inActivity)
    end
end

function XUiPracticeBasicsStage:SetLockStage(isLock, stageId, stageMode)
    self.PanelStageLock.gameObject:SetActive(isLock)
    if isLock and stageMode == XPracticeConfigs.PracticeType.Character then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        self.TxtFightNameLock.text = stageCfg.Name
        self.RImgFightActiveLock:SetRawImage(stageCfg.Icon)
    end
end

function XUiPracticeBasicsStage:SetPassStage(isPass)
    self.PanelStagePass.gameObject:SetActive(isPass)
end

function XUiPracticeBasicsStage:UpdateNode(stageId, stageMode)
    self.StageId = stageId
    self.StageMode = stageMode
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if self.StageMode == XPracticeConfigs.PracticeType.Basics then
        self.IsLock = stageInfo.IsOpen ~= true
    else
        local isOpen = XDataCenter.PracticeManager.CheckPracticeStageOpen(stageId)
        self.IsLock = not isOpen
    end

    self:SetNormalStage(self.IsLock, stageId)
    self:SetLockStage(self.IsLock, stageId, stageMode)
    self:SetPassStage(stageInfo.Passed)
end

function XUiPracticeBasicsStage:OnBtnStageClick()
    if not self.StageId then return end
    --local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if self.IsLock then
        local _, description = XDataCenter.PracticeManager.CheckPracticeStageOpen(self.StageId)
        XUiManager.TipMsg(description)
    else
        if self.Parent then
            self.Parent:PlayScrollViewMove(self.Transform.parent)
        end
        self.RootUi:OpenStageDetail(self.StageId)
    end
end

return XUiPracticeBasicsStage