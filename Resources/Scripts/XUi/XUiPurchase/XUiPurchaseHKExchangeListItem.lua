local XUiPurchaseHKExchangeListItem = XClass(nil, "XUiPurchaseHKExchangeListItem")
local TextManager = CS.XTextManager

function XUiPurchaseHKExchangeListItem:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiPurchaseHKExchangeListItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData

    -- 直接获得的道具
    local rewardGoods = self.ItemData.RewardGoodsList or {}

    -- 额外获得
    local extraRewardGood = self.ItemData.ExtraRewardGoods or {}
    local extraCount = extraRewardGood.Count or 0

    -- 首充获得物品
    local firstRewardGoods = self.ItemData.FirstRewardGoods or {}
    local firstCount = firstRewardGoods.Count or 0

    self.TxtName.text = self.ItemData.Desc
    self.RawImageConsu:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemData.ConsumeId))
    if itemData.Icon then
        local path = XPurchaseConfigs.GetIconPathByIconName(itemData.Icon)
        if path and path.AssetPath then
            self.ImgIconDh:SetRawImage(path.AssetPath)
        end
    end

    self.TxtHk.text = itemData.ConsumeCount

    if extraCount == 0 and firstCount == 0 then
        self.PanelFirstLabel.gameObject:SetActive(false)
        self.PanelNormalLabel.gameObject:SetActive(false)
    else
        local dirCount = 0
        if rewardGoods[1] then
            dirCount = rewardGoods[1].Count or 0
        end

        if self.ItemData.BuyTimes == 0 or firstCount > 0 then
            if firstCount == dirCount then -- 首次购买而且双倍
                self.PanelFirstLabel.gameObject:SetActive(true)
                self.PanelNormalLabel.gameObject:SetActive(true)
                self.TxtFirst.text = TextManager.GetText("PurchasePayFirstGetText")
                if firstRewardGoods.TemplateId then
                    self.TxtNormal.text = TextManager.GetText("PurchaseFirstPayTips",firstCount,XDataCenter.ItemManager.GetItemName(firstRewardGoods.TemplateId))
                end
            else
                self.PanelFirstLabel.gameObject:SetActive(false)
                self.PanelNormalLabel.gameObject:SetActive(true)
                if firstRewardGoods.TemplateId then
                    self.TxtNormal.text = TextManager.GetText("PurchaseFirstPayTips",firstCount,XDataCenter.ItemManager.GetItemName(firstRewardGoods.TemplateId))
                end
            end
        else
            self.PanelNormalLabel.gameObject:SetActive(false)
            self.PanelFirstLabel.gameObject:SetActive(false)
            if extraCount > 0 and extraRewardGood.TemplateId then
                self.PanelNormalLabel.gameObject:SetActive(true)
                self.TxtNormal.text = TextManager.GetText("PurchasePayGetText",extraCount,XDataCenter.ItemManager.GetItemName(extraRewardGood.TemplateId))
            end
        end
    end
end

function XUiPurchaseHKExchangeListItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

return XUiPurchaseHKExchangeListItem