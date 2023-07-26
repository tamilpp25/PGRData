local XUiPanelSettlement = XClass(nil, "XUiPanelSettlement")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelSettlement:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelSettlement:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiPanelSettlement:OnBtnClick()
    self.Base:SetSpecialState(XMineSweepingConfigs.SpecialState.None)
end

function XUiPanelSettlement:UpdatePanel()
    local SpecialStateChapterId = self.Base:GetSpecialStateChapterId()
    local SpecialStateStageId = self.Base:GetSpecialStateStageId()
    if SpecialStateChapterId and SpecialStateStageId then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityById(SpecialStateChapterId)
        local stageEntity = chapterEntity:GetStageEntityById(SpecialStateStageId)
        self.PanelWin.gameObject:SetActiveEx(self.Base:IsSpecialStateStageWin())
        self.PanelLose.gameObject:SetActiveEx(self.Base:IsSpecialStateStageLose())
        self.PanelWin:GetObject("TxtLevel").text = stageEntity:GetName()
        self.PanelLose:GetObject("TxtLevel").text = stageEntity:GetName()
        
        local failedCount = stageEntity:GetFailedCounts()
        local canFailedDifference = stageEntity:GetCanFailedCountByIndex(failedCount + 2) - stageEntity:GetCanFailedCountByIndex(failedCount + 1)
        canFailedDifference = math.max(0, canFailedDifference)
        
        self.PanelLose:GetObject("TxtCount").text = CSTextManagerGetText("MineSweepingChallengePlusHint", canFailedDifference)
    end
end

function XUiPanelSettlement:ShowWinPanel()
    self.GameObject:SetActiveEx(true)
    self.Base:PlayAnimationWithMask("PanelWinEnable")

end

function XUiPanelSettlement:ShowPanel(IsShow)
    if IsShow then
        if self.Base:IsSpecialStateStageLose() then
            self.Base:PlayAnimationWithMask("PanelLoseEnable")
            self.GameObject:SetActiveEx(true)
        end
    else
        self.GameObject:SetActiveEx(false)
    end
end

return XUiPanelSettlement