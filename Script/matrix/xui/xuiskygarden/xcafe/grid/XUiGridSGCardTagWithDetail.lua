
local XUiGridSGCardTagWithDetail = XClass(nil, "XUiGridSGCardTagWithDetail")

function XUiGridSGCardTagWithDetail:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridSGCardTagWithDetail:Refresh(name, detail)
    self.TxtName.text = name
    self.TxtDetail.text = detail
    self:Open()
end

function XUiGridSGCardTagWithDetail:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiGridSGCardTagWithDetail:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiGridSGCardTagWithDetail