local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitGridFight = XClass(nil, "XUiChessPursuitGridFight")
local CSUnityEngineVector3 = CS.UnityEngine.Vector3

function XUiChessPursuitGridFight:Ctor(ui, uiRoot, mapId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MapId = mapId

    XTool.InitUiObject(self)

    self.Transform.localScale = CSUnityEngineVector3(5,5,5)
end

function XUiChessPursuitGridFight:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    self.GameObject = nil
end

function XUiChessPursuitGridFight:SetActiveEx(isShow)
    self.GameObject:SetActiveEx(isShow)
end

function XUiChessPursuitGridFight:RefreshPos()
    if not self.GameObject.activeSelf then
        return
    end

    local ts= self.UiRoot.ChessPursuitBoss.Transform
    local offzetY = 0.35
    self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(ts.position.x, ts.position.y + offzetY, ts.position.z))
end


return XUiChessPursuitGridFight