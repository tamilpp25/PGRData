local BaseButton = require("XUi/XUiSuperTower/Common/XUiSTFunctionButton")
--===========================
--超级爬塔按钮
--===========================
local XUiSTBagButton = XClass(BaseButton, "XUiSTBagButton")
--==============
--显示(用于统一背包控件接口)
--==============
function XUiSTBagButton:ShowPanel()
    self:Show()
end
--==============
--隐藏(用于统一背包控件接口)
--==============
function XUiSTBagButton:HidePanel()
    self:Hide()
end

return XUiSTBagButton