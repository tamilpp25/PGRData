local XUiPanelCondition = XClass(nil, "XUiPanelCondition")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelCondition:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
end

function XUiPanelCondition:UpdatePanel(curCharterIndex)
    if curCharterIndex then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(curCharterIndex)
        local stageEntity = chapterEntity:GetCurStageEntity()
        self.WinText.text = CSTextManagerGetText("MineSweepingStageWinHint", stageEntity:GetWhiteGridOpenNumber(), stageEntity:GetWhiteGridTotalNumber())
        self.LoseText.text = CSTextManagerGetText("MineSweepingStageLoseHint", stageEntity:GetAllowMineNumber(), stageEntity:GetMineGridOpenNumber(), stageEntity:GetAllowMineNumber())
    end
end

function XUiPanelCondition:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiPanelCondition