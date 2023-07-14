local XUiArenaContributeTipsGrid = XClass(nil, "UiArenaContributeTipsGrid")

function XUiArenaContributeTipsGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiArenaContributeTipsGrid:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiArenaContributeTipsGrid:Refresh(index, contributeScore)
    self.TxtRank.text = "No." .. index
    self.TxtNumber.text = "+" .. contributeScore
end

return XUiArenaContributeTipsGrid