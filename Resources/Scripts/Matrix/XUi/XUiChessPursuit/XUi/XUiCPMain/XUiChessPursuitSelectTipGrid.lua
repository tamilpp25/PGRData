local XUiChessPursuitSelectTipGrid = XClass(nil, "XUiChessPursuitSelectTipGrid")
local CSUnityEngineVector3 = CS.UnityEngine.Vector3

function XUiChessPursuitSelectTipGrid:Ctor(ui, uiRoot, cubeIndex, mapId, targetType)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CubeIndex = cubeIndex
    self.MapId = mapId
    self.TargetType = targetType

    XTool.InitUiObject(self)

    self.Transform.localScale = CSUnityEngineVector3(5,5,5)
end

function XUiChessPursuitSelectTipGrid:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    self.GameObject = nil
end

function XUiChessPursuitSelectTipGrid:SetActiveEx(isShow)
    self.GameObject:SetActiveEx(isShow)
end

function XUiChessPursuitSelectTipGrid:RefreshPos()
    if not self.GameObject.activeSelf then
        return
    end

    local ts
    local offzetY
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        ts = self.UiRoot.ChessPursuitBoss.Transform
        offzetY = -1
    elseif self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local chessPursuitCube = XChessPursuitCtrl.GetChessPursuitCubes()
        ts = chessPursuitCube[self.CubeIndex].Transform
        offzetY = 0.2
    end

    self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(ts.position.x, ts.position.y + offzetY, ts.position.z))
end


return XUiChessPursuitSelectTipGrid