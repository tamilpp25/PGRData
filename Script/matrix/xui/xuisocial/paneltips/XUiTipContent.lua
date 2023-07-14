local XUiTipContent = XClass(nil, "XUiTipContent")

function XUiTipContent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiTipContent:Refresh(desc)
    self.Txt.text = desc
end

function XUiTipContent:SetAlpha(alpha)
    self.CanvasGroup.alpha = alpha
end

function XUiTipContent:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

function XUiTipContent:SetAsLastSibling()
    self.Transform:SetAsLastSibling()
end

function XUiTipContent:GetDesc()
    return self.Txt.text
end

function XUiTipContent:GetGameObject()
    return self.GameObject
end

function XUiTipContent:PlayEnableAnimation(cb)
    if self.GridTipsEnable.gameObject.activeInHierarchy then
        self.GridTipsEnable:PlayTimelineAnimation(cb)
    end
end

function XUiTipContent:PlayDisableAnimation(cb)
    if self.GridTipsDisable.gameObject.activeInHierarchy then
        self.GridTipsDisable:PlayTimelineAnimation(cb)
    end
end

return XUiTipContent