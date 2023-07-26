local XUiFubenMaverickStageGrid = XClass(nil, "XUiFubenMaverickStageGrid")

function XUiFubenMaverickStageGrid:Ctor(rootUi, ui, stage)
    self.Stage = stage
    self.RootUi = rootUi
    self.Parent = ui.transform.parent
    self.ParentGo = ui.transform.parent.gameObject

    XTool.InitUiObjectByUi(self, ui)

    if not self.Stage then
        self.ParentGo:SetActiveEx(false)
        return
    end

    self:InitTexts()
    self:InitButtons()
end

function XUiFubenMaverickStageGrid:InitTexts()
   self.NormalText.text = self.Stage.GridName
   self.EndlessText.text = self.Stage.GridName
end

function XUiFubenMaverickStageGrid:InitButtons()
    self:SetSelectActive(false)
    self.Normal.gameObject:SetActiveEx(self.Stage.StageType == XDataCenter.MaverickManager.StageTypes.Normal)
    XUiHelper.RegisterClickEvent(self, self.Normal, function() self:OnClick() end)
    self.Endless.gameObject:SetActiveEx(self.Stage.StageType == XDataCenter.MaverickManager.StageTypes.Endless)
    XUiHelper.RegisterClickEvent(self, self.Endless, function() self:OnClick() end)
end

function XUiFubenMaverickStageGrid:OnClick()
    self.RootUi:SelectGrid(self)
    self.RootUi:PlayScrollViewMove(self.Parent)
    self.RootUi:OpenStageDetail(self.Stage)
end

function XUiFubenMaverickStageGrid:Refresh()
    if not self.Stage then
        return
    end
    
    self.Score = XDataCenter.MaverickManager.GetStageScore(self.Stage.StageId) --非无尽关默认积分为0
    self.TxtScore.text = CsXTextManagerGetText("MaverickStageScore", self.Score)
    self.IsFinished = XDataCenter.MaverickManager.CheckStageFinished(self.Stage.StageId)
    self.Clear.gameObject:SetActiveEx(self.IsFinished and (self.Stage.StageType ~= XDataCenter.MaverickManager.StageTypes.Endless))
    self.IsOpen = XDataCenter.MaverickManager.CheckStageOpen(self.Stage.StageId)
    self.ParentGo:SetActiveEx(self.IsOpen)
end

function XUiFubenMaverickStageGrid:SetSelectActive(active)
    self.Select.gameObject:SetActiveEx(active)
end

return XUiFubenMaverickStageGrid