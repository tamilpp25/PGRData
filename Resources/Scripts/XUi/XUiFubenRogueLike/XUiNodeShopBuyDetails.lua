local XUiNodeShopBuyDetails = XClass(nil, "XUiNodeShopBuyDetails")
local XUiGridBuffInfoItem = require("XUi/XUiFubenRogueLike/XUiGridBuffInfoItem")
local XUiGridRoleInfoItem = require("XUi/XUiFubenRogueLike/XUiGridRoleInfoItem")

function XUiNodeShopBuyDetails:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)

    self.BtnTanchuangClose.CallBack = function() self:CloseBlackShopDetails() end
    self.BtnBlock.CallBack = function() self:CloseBlackShopDetails() end

    self.BtnAddSelect.CallBack = function() self:OnBtnAddSelectClick() end
    self.BtnMinusSelect.CallBack = function() self:OnBtnMinusSelectClick() end
    self.BtnUse.CallBack = function() self:OnBtnUseClick() end

    self.RoleItem = XUiGridRoleInfoItem.New(self.GridRole)
    self.BuffItem = XUiGridBuffInfoItem.New(self.UiRoot, self.GridBuff)
    self.ItemInfo = XUiGridCommon.New(self.UiRoot, self.GridBuyCommon)
end

-- table.insert(self.BlackItemList, {
--     ShopItemId = shopItemId,
--     TotalBuyCount = buyCount,
--     BuyCount = buyCount - (self.BlackShopBuyItemInfos[shopItemId] or 0)
-- })
function XUiNodeShopBuyDetails:ShowBlackShopDetails(shopItem, node)
    self.ShopItemDatas = shopItem
    self.Node = node
    self.GameObject:SetActiveEx(true)
    self.ShopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(self.ShopItemDatas.ShopItemId)
    self.TxtOwnCount.text = ""
    if self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
        self.BuffItem:SetBuffInfoById(self.ShopItemTemplate.Param[1])

    elseif self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
        local itemId = self.ShopItemTemplate.Param[1]
        self.ItemInfo:Refresh(itemId)
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        self.TxtOwnCount.text = CS.XTextManager.GetText("CurrentlyHas", itemCount)
    elseif self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot then
        -- local robotId = self.ShopItemTemplate.Param[1]
        --local characterId = XRobotManager.GetCharacterId(robotId)
        self.RoleItem:SetRandomRoleInfo()
    end

    self.BuffItem.GameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff)
    self.ItemInfo.GameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item)
    self.RoleItem.GameObject:SetActiveEx(self.ShopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Robot)

    local item = XDataCenter.ItemManager.GetItem(self.ShopItemTemplate.ConsumeId[1])
    self.RImgCostIcon1:SetRawImage(item.Template.Icon)
    self.TxtCanBuy.text = self.ShopItemDatas.BuyCount
    local defaultNum = (self.ShopItemDatas.BuyCount <= 0) and 0 or 1
    self:UpdateSelectNum(defaultNum)
end

function XUiNodeShopBuyDetails:UpdateSelectNum(num)
    self.CurrentSelectNum = num
    self.TxtSelect.text = self.CurrentSelectNum
    self:UpdateCostCount()
end

function XUiNodeShopBuyDetails:UpdateCostCount()
    self.TxtCostCount1.text = math.ceil(self.ShopItemTemplate.ConsumeNum[1] * self.CurrentSelectNum * (self.ShopItemDatas.Discount / 100))
end

function XUiNodeShopBuyDetails:UpdateCostCountByDiscount(discount)
    if self.ShopItemTemplate and self.CurrentSelectNum then
        self.TxtCostCount1.text = math.ceil(self.ShopItemTemplate.ConsumeNum[1] * self.CurrentSelectNum * (discount / 100))
    end
end

function XUiNodeShopBuyDetails:CloseBlackShopDetails()
    self.GameObject:SetActiveEx(false)
end

function XUiNodeShopBuyDetails:OnBtnAddSelectClick()
    if self.ShopItemDatas and self.CurrentSelectNum + 1 <= self.ShopItemDatas.BuyCount then
        self:UpdateSelectNum(self.CurrentSelectNum + 1)
    end
end

function XUiNodeShopBuyDetails:OnBtnMinusSelectClick()
    if self.CurrentSelectNum - 1 > 0 then
        self:UpdateSelectNum(self.CurrentSelectNum - 1)
    end
end

function XUiNodeShopBuyDetails:OnBtnUseClick()
    if self.Node and self.ShopItemDatas and self.CurrentSelectNum > 0 then
        XDataCenter.FubenRogueLikeManager.NodeBuy(self.Node.Id, self.ShopItemDatas.ShopItemId, self.CurrentSelectNum, function()
            self:CloseBlackShopDetails()
            -- 弹获得东西的页面
            -- 更新商品界面
            self.UiRoot:RefreshShopItems()
        end)
    end
end

return XUiNodeShopBuyDetails