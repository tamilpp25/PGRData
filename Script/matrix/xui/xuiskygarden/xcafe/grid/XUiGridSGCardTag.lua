
local XUiGridSGCardTag = XClass(nil, "XUiGridSGCardTag")

function XUiGridSGCardTag:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridSGCardTag:Refresh(txt)
    self.TxtName.text = txt
    self:Open()
end

function XUiGridSGCardTag:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiGridSGCardTag:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiGridSGCardTag