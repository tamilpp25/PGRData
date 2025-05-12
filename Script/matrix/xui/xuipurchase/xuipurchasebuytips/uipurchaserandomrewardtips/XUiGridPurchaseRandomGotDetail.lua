local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridPurchaseRandomGotDetail: XUiNode
local XUiGridPurchaseRandomGotDetail = XClass(XUiNode, 'XUiGridPurchaseRandomGotDetail')

---@param rootUi XLuaUi
function XUiGridPurchaseRandomGotDetail:SetRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridPurchaseRandomGotDetail:Refresh(rewardGoods, percentContent, isGet, isSelect, hadBuy)
    self.TxtProbability.text = percentContent

    if not self.GridRewardCommon then
        self.GridRewardCommon = XUiGridCommon.New(self.RootUi, self.PanelProCard)
    end
    
    self.GridRewardCommon:Refresh(rewardGoods)

    if isGet then
        self.TxtStatus.text = XUiHelper.GetText('PurchaseRandomDetailGotTips')
        self.ImgBgMask.color = XUiHelper.Hexcolor2Color(string.gsub(CS.XGame.ClientConfig:GetString('PurchaseRandomDetailGotColor'), '#', ''))
    elseif isSelect then
        if hadBuy then
            self.TxtStatus.text = XUiHelper.GetText('PurchaseRandomDetailUnGotTips')
            self.ImgBgMask.color = XUiHelper.Hexcolor2Color(string.gsub(CS.XGame.ClientConfig:GetString('PurchaseRandomDetailUnGotColor'), '#', ''))
        else
            self.TxtStatus.text = XUiHelper.GetText('PurchaseRandomDetailSelectTips')
            self.ImgBgMask.color = XUiHelper.Hexcolor2Color(string.gsub(CS.XGame.ClientConfig:GetString('PurchaseRandomDetailSelectColor'), '#', ''))
        end

    else
        self.TxtStatus.text = XUiHelper.GetText('PurchaseRandomDetailNoSelectTips')
        self.ImgBgMask.color = XUiHelper.Hexcolor2Color(string.gsub(CS.XGame.ClientConfig:GetString('PurchaseRandomDetailUnSelectColor'), '#', ''))
    end
end

return XUiGridPurchaseRandomGotDetail