---@class XUiGoldenMinerShopTipPanel : XUiNode
---@field _Control XGoldenMinerControl
---@field _ItemGrid XUiGoldenMinerItemGrid
local XUiGoldenMinerShopTipPanel = XClass(XUiNode, "XUiGoldenMinerShopTipPanel")

function XUiGoldenMinerShopTipPanel:OnStart()
    self._ItemGrid = false
    self.IsShow = false
    self:AddBtnListener()
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShopTipPanel:Refresh(buffId, itemGrid, positionX)
    if not self.BtnSell then
        XLog.Error("当前Ui资源与代码不匹配，请打包资源")
        return
    end
    self.Transform.position = Vector3(positionX, self.Transform.position.y, self.Transform.position.z)
    if buffId then
        self:UpdateBuff(buffId)
    elseif itemGrid then
        self:UpdateItem(itemGrid)
    end
end

function XUiGoldenMinerShopTipPanel:UpdateBuff(buffId)
    local buffName = self._Control:GetCfgBuffName(buffId)
    local buffDesc = self._Control:GetCfgBuffDesc(buffId)
    local buffIcon = self._Control:GetCfgBuffIcon(buffId)

    self.TxtName.text = buffName
    self.TxtTips.text = buffDesc
    self.Txt02.gameObject:SetActiveEx(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    if not string.IsNilOrEmpty(buffIcon) then
        self.RawBuffIcon:SetRawImage(buffIcon)
    end
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShopTipPanel:UpdateItem(itemGrid)
    self._ItemGrid = itemGrid
    local item = itemGrid:GetItemColumn()
    local itemName = self._Control:GetCfgItemName(item:GetItemId())
    local itemDesc = self._Control:GetCfgItemDescribe(item:GetItemId())
    local itemIcon = self._Control:GetCfgItemIcon(item:GetItemId())
    local price = self._Control:GetCfgItemSellPrice(item:GetItemId())

    self.TxtName.text = itemName
    self.TxtTips.text = itemDesc
    self.TxtPrice.text = price
    self.Txt02.gameObject:SetActiveEx(true)
    self.BtnSell.gameObject:SetActiveEx(true)
    if not string.IsNilOrEmpty(itemIcon) then
        self.RawBuffIcon:SetRawImage(itemIcon)
    end
end

--region Ui - BtnListener
function XUiGoldenMinerShopTipPanel:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSell, self.OnBtnSellClick)
end

function XUiGoldenMinerShopTipPanel:OnBtnSellClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_SHOP_SELL_ITEM, self._ItemGrid)
end
--endregion

return XUiGoldenMinerShopTipPanel