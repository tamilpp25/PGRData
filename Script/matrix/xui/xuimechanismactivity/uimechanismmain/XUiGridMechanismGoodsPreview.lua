local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridMechanismGoodsPreview = XClass(XUiGridCommon, 'XUiGridMechanismGoodsPreview')

function XUiGridMechanismGoodsPreview:Ctor(root, ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridMechanismGoodsPreview:SetBuyComplete(active)
    self.PanelComplete.gameObject:SetActiveEx(active)
end

return XUiGridMechanismGoodsPreview