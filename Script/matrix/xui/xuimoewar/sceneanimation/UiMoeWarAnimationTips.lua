local XUiMoeWarAnimationTips = XLuaUiManager.Register(XLuaUi, "UiMoeWarAnimationTips")

function XUiMoeWarAnimationTips:OnStart()
    self:PlayAnimationWithMask("AnimStart",function ()
        self:Close()
    end)
end