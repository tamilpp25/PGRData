-- 虚像地平线无尽关结算界面羁绊控件
local XUiExpeditionInfinityCombo = XClass(nil, "XUiExpeditionInfinityCombo")

function XUiExpeditionInfinityCombo:Ctor()
    
end

function XUiExpeditionInfinityCombo:Init(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiExpeditionInfinityCombo:RefreshData(eCombo)
    self.RImgActive:SetRawImage(eCombo:GetIconPath())
end

return XUiExpeditionInfinityCombo