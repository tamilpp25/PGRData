-- 虚像地平线无尽关结算界面头像控件
local XUiExpeditionInfinityHeadIcon = XClass(nil, "XUiExpeditionInfinityHeadIcon")

function XUiExpeditionInfinityHeadIcon:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiExpeditionInfinityHeadIcon:RefreshData(eChara)
    self.RImgIcon:SetRawImage(eChara:GetBigHeadIcon())
    self.TxtLevel.text = eChara:GetRankStr()
    self.TxtRoleName.text = eChara:GetCharaFullName()
end

return XUiExpeditionInfinityHeadIcon