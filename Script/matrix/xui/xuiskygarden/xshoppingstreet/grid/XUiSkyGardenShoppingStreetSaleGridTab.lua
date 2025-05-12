---@class XUiSkyGardenShoppingStreetSaleGridTab : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetSaleGridTab = XClass(XUiNode, "XUiSkyGardenShoppingStreetSaleGridTab")

--region 生命周期
function XUiSkyGardenShoppingStreetSaleGridTab:OnStart(...)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetSaleGridTab:Update(data, i)
    self._Index = i
    local nameKey = data.Type == XMVCA.XSkyGardenShoppingStreet.XSgStreetPromotionType.ShopBuild and "SG_SS_SaleGridTab2" or "SG_SS_SaleGridTab1"
    self.BtnTab1:SetName(XMVCA.XBigWorldService:GetText(nameKey))
    -- if self.TxtShop then
    --     self.TxtShop.text = data.ShopName
    -- end
end
--endregion

function XUiSkyGardenShoppingStreetSaleGridTab:SetSelect(isSelect)
    self.Normal.gameObject:SetActive(not isSelect)
    self.Select.gameObject:SetActive(isSelect)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetSaleGridTab:OnBtnTab1Click()
    self.Parent:SelectTagByIndex(self._Index)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetSaleGridTab:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTab1.CallBack = function() self:OnBtnTab1Click() end
end
--endregion

return XUiSkyGardenShoppingStreetSaleGridTab
