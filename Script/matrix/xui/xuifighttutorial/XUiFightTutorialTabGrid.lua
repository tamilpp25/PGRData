local XUiFightTutorialTabGrid = XClass(nil, "XUiFightTutorialTabGrid")

function XUiFightTutorialTabGrid:Ctor(trans)
    XUiHelper.InitUiClass(self, trans)
    XTool.InitUiObject(self)
    self.Transform = trans
end

function XUiFightTutorialTabGrid:SetState(active)
    if active then
        self.On.gameObject:SetActiveEx(true)
        self.Off.gameObject:SetActiveEx(false)
    else
        self.On.gameObject:SetActiveEx(false)
        self.Off.gameObject:SetActiveEx(true)
    end
end

function XUiFightTutorialTabGrid:Destroy()
    CS.UnityEngine.Object.Destroy(self.Transform.gameObject)
end

return XUiFightTutorialTabGrid