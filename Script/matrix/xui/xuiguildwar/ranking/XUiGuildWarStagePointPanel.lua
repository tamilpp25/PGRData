---@class XUiGuildWarStagePointPanel
local XUiGuildWarStagePointPanel = XClass(nil, "XUiGuildWarStagePointPanel")

function XUiGuildWarStagePointPanel:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiGuildWarStagePointPanel:RefreshData(data)
    self.TxtPlayerName.text = data.Name
    self.TxtPointScore.text = data.Point
    self.TxtActiveScore.text = data.Activation
end

function XUiGuildWarStagePointPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildWarStagePointPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiGuildWarStagePointPanel