local XUiChessPursuitGuideGrid = XClass(nil, "XUiChessPursuitGuideGrid")
local CSUnityEngineVector2 = CS.UnityEngine.Vector2

function XUiChessPursuitGuideGrid:Ctor(ui, uiRoot, modelTransform)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ModelTransform = modelTransform

    XTool.InitUiObject(self)
end

function XUiChessPursuitGuideGrid:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    self.GameObject = nil
end

function XUiChessPursuitGuideGrid:SetActiveEx(isShow)
    self.GameObject:SetActiveEx(isShow)
end

function XUiChessPursuitGuideGrid:RefreshPos()
    local ts = self.ModelTransform
    local localPosition = XChessPursuitCtrl.WorldToUILocaPosition(ts.position)

    self.Transform.anchoredPosition = CSUnityEngineVector2(localPosition.x, localPosition.y+95)
end

function XUiChessPursuitGuideGrid:AddClick(callBack)
    XUiHelper.RegisterClickEvent(self, self.Transform, callBack)
end

return XUiChessPursuitGuideGrid