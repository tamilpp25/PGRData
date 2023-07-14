local XUiAutoFightTip = XLuaUiManager.Register(XLuaUi, "UiAutoFightTip")

local AnimBegin = "UiAutoFightTipBegin"

function XUiAutoFightTip:OnStart()
    self:PlayAnimation(AnimBegin, function()
        self:Close()
    end)
end