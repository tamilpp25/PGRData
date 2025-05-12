local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridNodeShopItem = XClass(nil, "XUiGridNodeShopItem")
local XUiGridBuffInfoItem = require("XUi/XUiFubenRogueLike/XUiGridBuffInfoItem")
local XUiGridRoleInfoItem = require("XUi/XUiFubenRogueLike/XUiGridRoleInfoItem")

function XUiGridNodeShopItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)

    self.RoleItem = XUiGridRoleInfoItem.New(self.GridRole)
    self.BuffItem = XUiGridBuffInfoItem.New(self.UiRoot, self.GridBuff)

    -- self.BtnBuy.CallBack = function() self:OnBtnBuyClick() end
end

function XUiGridNodeShopItem:SetItemData(shopItem)
    self.ShopItemDatas = shopItem
    self.ShopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(self.ShopItemDatas.ShopItemId)
    if self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
        self.ShopItemBuffConfig = XFubenRogueLikeConfig.GetBuffConfigById(self.ShopItemTemplate.Param[1])
        self.BuffItem:SetBuffInfoById(self.ShopItemTemplate.Param[1])
        self.TxtDetails.text = self.ShopItemBuffConfig.Description
    elseif self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
        if not self.ItemInfo then
            self.ItemInfo = XUiGridCommon.New(self.RootUi, self.GridCommon)
        end
        local itemId = self.ShopItemTemplate.Param[1]
        self.ItemInfo:Refresh(itemId)
        self.TxtDetails.text = XDataCenter.ItemManager.GetItemDescription(itemId)
    elseif self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot then
        -- local robotId = self.ShopItemTemplate.Param[1]
        --local characterId = XRobotManager.GetCharacterId(robotId)
        self.RoleItem:SetRandomRoleInfo()
        self.TxtDetails.text = CS.XTextManager.GetText("RogueLikeRandomRobotDetails")
    end

    self.GridBuff.gameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff)
    self.GridCommon.gameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item)
    self.GridRole.gameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot)

    self.RImgPrice1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ShopItemTemplate.ConsumeId[1]))
    local cost = math.ceil(self.ShopItemTemplate.ConsumeNum[1] * (self.ShopItemDatas.Discount * 1 / 100))
    self.TxtNewPrice1.text = cost
    self:UpdatePriceColor(self.ShopItemTemplate.ConsumeId[1], cost)

    self:SetItemSellOut(self.ShopItemDatas.BuyCount <= 0)
    self:SetSaleRate(self.ShopItemDatas.Discount)
    self:SetItemSelect(self.ShopItemDatas.IsSelect)
end

function XUiGridNodeShopItem:UpdatePriceByDiscount(discount)
    if not self.ShopItemDatas then return end
    --local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(self.ShopItemDatas.ShopItemId)
    local cost = math.ceil(self.ShopItemTemplate.ConsumeNum[1] * (discount * 1.0 / 100))
    self.TxtNewPrice1.text = cost
    self:UpdatePriceColor(self.ShopItemTemplate.ConsumeId[1], cost)
end

function XUiGridNodeShopItem:UpdatePriceColor(itemId, needCoin)
    local ownCount = XDataCenter.ItemManager.GetCount(itemId)
    if ownCount >= needCoin then
        self.TxtNewPrice1.color = CS.UnityEngine.Color(1, 1, 1)
    else
        self.TxtNewPrice1.color = CS.UnityEngine.Color(1, 0, 0)
    end
end

-- 打折
function XUiGridNodeShopItem:SetSaleRate(saleRate)
    local isShowSaleRate = saleRate ~= nil and saleRate ~= 0 and saleRate ~= 100

    local discount
    if saleRate % 10 == 0 then
        discount = math.floor(saleRate / 10)
    else
        discount = saleRate / 10
    end
    self.Tab.gameObject:SetActiveEx(isShowSaleRate)
    if isShowSaleRate then
        local snap = CS.XTextManager.GetText("Snap")
        self.TxtSaleRate.text = string.format("%s%s", tostring(discount), snap)
    end
end

-- 是否买完了
function XUiGridNodeShopItem:SetItemSellOut(isSellOut)
    self.ImgSellOut.gameObject:SetActiveEx(isSellOut)
end

function XUiGridNodeShopItem:SetItemSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end
end

-- function XUiGridNodeShopItem:OnBtnBuyClick()
--     if self.RootUi and self.ShopItemDatas then
--         if self.ShopItemDatas.BuyCount <= 0 then
--             XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeShopItemSellOut"))
--             return
--         end
--         self.RootUi:OpenBuyDetails(self.ShopItemDatas)
--     end
-- end
return XUiGridNodeShopItem