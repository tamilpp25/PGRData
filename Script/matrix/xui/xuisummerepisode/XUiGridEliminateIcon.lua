local XUiGridEliminateIcon = XClass(nil, "XUiGridEliminateIcon")

function XUiGridEliminateIcon:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.Effect.gameObject:SetActiveEx(false)
end

function XUiGridEliminateIcon:SetIcon(path)
    self.ImgIcon:SetSprite(path)
end

function XUiGridEliminateIcon:PlayTime(callback)
    self.Timeline:PlayTimelineAnimation(callback)
    self.Effect.gameObject:SetActiveEx(true)
end


function XUiGridEliminateIcon:PlayTimelineEnd()
    self.Timeline.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)

    self.Transform.localScale = CS.UnityEngine.Vector3.one
    self.GameObject:SetActiveEx(false)
end

return XUiGridEliminateIcon