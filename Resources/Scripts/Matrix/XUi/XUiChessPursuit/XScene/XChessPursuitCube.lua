local XChessPursuitModel = require("XUi/XUiChessPursuit/XScene/XChessPursuitModel")
local XChessPursuitCube = XClass(XChessPursuitModel, "XChessPursuitCube")

function XChessPursuitCube:Ctor(gameObject)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    self.CSXChessPursuitModel = gameObject:GetComponent(typeof(CS.XChessPursuitCube))
    self.CSXChessPursuitModel:SetXChessPursuitCtrl(XChessPursuitCtrl.GetCSXChessPursuitCtrlCom())
end

function XChessPursuitCube:Dispose()
    self.Func = nil
    self.CSXChessPursuitModel:Dispose()
end

return XChessPursuitCube