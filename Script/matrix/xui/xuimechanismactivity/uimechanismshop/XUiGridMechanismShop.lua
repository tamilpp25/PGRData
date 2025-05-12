local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiGridMechanismShop = XClass(XUiGridShop, 'XUiGridMechanismShop')


function XUiGridMechanismShop:Ctor(ui)
    self.CanvasGroup.alpha = 0
end

function XUiGridMechanismShop:PlayAnimation(animeName, finCb, beginCb)
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

return XUiGridMechanismShop