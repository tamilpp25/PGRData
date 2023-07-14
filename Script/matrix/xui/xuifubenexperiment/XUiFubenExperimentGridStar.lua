local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenExperimentGridStar = XClass(nil, "XUiFubenExperimentGridStar")
function XUiFubenExperimentGridStar:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self:Init()
end

function XUiFubenExperimentGridStar:Init()
    XTool.InitUiObject(self)
end

function XUiFubenExperimentGridStar:SetDesc(desc)
    self.TxtUnActive.text = desc
    self.TxtActive.text = desc
end

function XUiFubenExperimentGridStar:SetActiveEx(active)
    self.PanelActive.gameObject:SetActiveEx(active)
    self.PanelUnActive.gameObject:SetActiveEx(not active)
end

return XUiFubenExperimentGridStar