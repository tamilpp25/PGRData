local XUiPurchasePayListItem = XClass(nil, "XUiPurchasePayListItem")
-- local TextManager = CS.XTextManager

function XUiPurchasePayListItem:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.PanelLabel.gameObject:SetActive(false)
end

function XUiPurchasePayListItem:Init(uiRoot,parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

-- 更新数据
function XUiPurchasePayListItem:OnRefresh(itemData)
    if not itemData then
        return
    end
    self.ItemData = itemData
    self.CurState = false
    self:SetSelectState(false)
    self:SetData()
end

function XUiPurchasePayListItem:SetData()
    self.TxtCzsl.text = self.ItemData.Name
    self.TxtContent.text = self.ItemData.Desc
    if self.TxtContentNormal then
        self.TxtContentNormal.text = self.ItemData.Desc
    end
    if self.ItemData.Icon then
        local path = XPurchaseConfigs.GetIconPathByIconName(self.ItemData.Icon)
        if path and path.AssetPath then
            self.ImgCz:SetRawImage(path.AssetPath,function()self.ImgCz:SetNativeSize()end)
        end
    end

    self.TxtYuan.text = self.ItemData.Amount

    -- -- 直接获得的道具
    -- local rewardGoods = self.ItemData.RewardGoodsList or {}

    -- -- 额外获得
    -- local extraRewardGood = self.ItemData.ExtraRewardGood or {}
    -- local extraCount = extraRewardGood.Count or 0

    -- -- 首充获得物品
    -- local firstRewardGoods = self.ItemData.FirstRewardGoods or {}
    -- local firstCount = firstRewardGoods.Count or 0

    -- if extraCount == 0 and firstCount == 0 then
    --     self.PanelLabel.gameObject:SetActive(false)
    -- else
    --     self.PanelLabel.gameObject:SetActive(true)
    --     local dirCount = #rewardGoods or 0
    --     if self.ItemData.BuyTimes == 0 and firstCount == dirCount then -- 首次购买而且双倍
    --         self.TxtGet.text = TextManager.GetText("PurchasePayFirstGetText")
    --     else
    --         self.TxtGet.text = TextManager.GetText("PurchasePayGetText",extraCount,XDataCenter.ItemManager.GetItemName(extraRewardGood.TemplateId))
    --     end
    -- end
    
    local normalIcon, selectIcon = XPurchaseConfigs.GetPayNormalAndSelectIcon(self.ItemData.Key)
    self.ImgIcon:SetRawImage(normalIcon)
    self.ImgSelectCz:SetRawImage(selectIcon)
end

function XUiPurchasePayListItem:OnSelectState(state)
    if self.CurState == state then
        return
    end

    self.CurState = state
    self:SetSelectState(state)
end

function XUiPurchasePayListItem:SetSelectState(state)
    self.ImgSelectCz.gameObject:SetActive(state)
end

function XUiPurchasePayListItem:OnClick()
    self.CurState = not self.CurState
    self:SetSelectState(self.CurState)
end

return XUiPurchasePayListItem