--肉鸽玩法势力好感度详情界面
local XUiFavorPanel = XLuaUiManager.Register(nil, "UiTheatreFavor")

function XUiFavorPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiFavorPanel:Show(powerId)
    self.PowerId = powerId
    self.GameObject:SetActiveEx(true)
end

function XUiFavorPanel:Hide()
    self.GameObject:SetActiveEx(false)
end