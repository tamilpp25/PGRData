---@class XGoldenMinerShopTipPanel
---@field _ItemGrid XUiGoldenMinerItemGrid
local XUiShopShopTipPanel = XClass(nil, "XUiShopShopTipPanel")

function XUiShopShopTipPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self._ItemGrid = false
    self.IsShow = false
    self:SetActive(false)
    self:AddBtnListener()
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiShopShopTipPanel:Refresh(buffId, itemGrid, positionX)
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

function XUiShopShopTipPanel:UpdateBuff(buffId)
    local buffName = XGoldenMinerConfigs.GetBuffName(buffId)
    local buffDesc = XGoldenMinerConfigs.GetBuffDesc(buffId)
    local buffIcon = XGoldenMinerConfigs.GetBuffIcon(buffId)

    self.TxtName.text = buffName
    self.TxtTips.text = buffDesc
    self.Txt02.gameObject:SetActiveEx(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    if not string.IsNilOrEmpty(buffIcon) then
        self.RawBuffIcon:SetRawImage(buffIcon)
    end
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiShopShopTipPanel:UpdateItem(itemGrid)
    self._ItemGrid = itemGrid
    local item = itemGrid:GetItemColumn()
    local itemName = XGoldenMinerConfigs.GetItemName(item:GetItemId())
    local itemDesc = XGoldenMinerConfigs.GetItemDescribe(item:GetItemId())
    local itemIcon = XGoldenMinerConfigs.GetItemIcon(item:GetItemId())
    local price = XGoldenMinerConfigs.GetItemSellPrice(item:GetItemId())

    self.TxtName.text = itemName
    self.TxtTips.text = itemDesc
    self.TxtPrice.text = price
    self.Txt02.gameObject:SetActiveEx(true)
    self.BtnSell.gameObject:SetActiveEx(true)
    if not string.IsNilOrEmpty(itemIcon) then
        self.RawBuffIcon:SetRawImage(itemIcon)
    end
end

function XUiShopShopTipPanel:SetActive(active)
    self.IsShow = active
    self.GameObject:SetActiveEx(active)
end

--region Ui - BtnListener
function XUiShopShopTipPanel:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSell, self.OnBtnSellClick)
end

function XUiShopShopTipPanel:OnBtnSellClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_SHOP_SELL_ITEM, self._ItemGrid)
end
--endregion

return XUiShopShopTipPanel