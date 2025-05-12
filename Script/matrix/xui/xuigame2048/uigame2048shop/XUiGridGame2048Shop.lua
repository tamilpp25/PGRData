local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiGridGame2048Shop = XClass(XUiGridShop, 'XUiGridGame2048Shop')


function XUiGridGame2048Shop:Ctor(ui)
    if not self.CanvasGroup then
        self.CanvasGroup = self.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    
    self:SetAlpha(0)
end

function XUiGridGame2048Shop:SetAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

function XUiGridGame2048Shop:PlayAnimation(animeName, finCb, beginCb)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    local animRoot = self.Transform:Find("Animation")
    if XTool.UObjIsNil(animRoot) then
        return
    end

    local animTrans = animRoot:FindTransform(animeName)
    if not animTrans or not animTrans.gameObject.activeInHierarchy then
        return
    end
    if beginCb then
        beginCb()
    end
    animTrans:PlayTimelineAnimation(finCb)
end

return XUiGridGame2048Shop