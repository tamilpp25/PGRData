local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=======================
--超级爬塔分解按钮面板
--=======================
local XUiSTBagDecomposionBtnPanel = XClass(ChildPanel, "XUiSTBagDecomposionBtnPanel")

function XUiSTBagDecomposionBtnPanel:InitPanel()
    self:InitButton()
end

function XUiSTBagDecomposionBtnPanel:InitButton()
    local script = require("XUi/XUiSuperTower/Bag/XUiSTBagButton")
    self.Button = script.New(self.BtnDecomposion, function() self:OnClick() end)
end

function XUiSTBagDecomposionBtnPanel:OnClick()
    self.RootUi:ShowDecomposion()
end

return XUiSTBagDecomposionBtnPanel