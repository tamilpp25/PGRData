XUiBaseComponent = XClass(nil, "XUiBaseComponent")

function XUiBaseComponent:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

-- for override
function XUiBaseComponent:Refresh()
end

function XUiBaseComponent:GetGameObject()
    return self.GameObject
end

function XUiBaseComponent:GetTransform()
    return self.Transform
end