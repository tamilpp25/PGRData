--虚像地平线结算界面头像控件
local XUiExpeditionSettleWinHeadIcon = XClass(nil, "XUiExpeditionSettleWinHeadIcon")
function XUiExpeditionSettleWinHeadIcon:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionSettleWinHeadIcon:RefreshData(baseId)
    local eChara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(baseId)
    self.RImgIcon:SetRawImage(eChara:GetBigHeadIcon())
    self.Rank = eChara and eChara:GetRank() or 1
    self.TxtLevel.text = eChara and eChara:GetRankStr() or 1
end

return XUiExpeditionSettleWinHeadIcon