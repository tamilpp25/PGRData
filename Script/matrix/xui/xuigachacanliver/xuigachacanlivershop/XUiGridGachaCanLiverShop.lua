local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridGachaCanLiverShop: XUiNode
---@field RootUi XLuaUi
local XUiGridGachaCanLiverShop = XClass(XUiNode, 'XUiGridGachaCanLiverShop')

local Operate = {
    OpenShop = 1,
    OpenItemTip = 2,
}

function XUiGridGachaCanLiverShop:OnStart(rootUi, shopItemTextColor)
    self.RootUi = rootUi
    self.PanelPrice = {
        self.PanelPrice1,
    }
    self.ShopItemTextColor = shopItemTextColor
    self.Sales = 100 -- 默认不打折
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
    self.BtnBuyOperate = Operate.OpenShop
end

--region 界面更新

function XUiGridGachaCanLiverShop:Refresh(goodsInfo)
    self.GoodsInfo = goodsInfo

    self.BtnBuyOperate = Operate.OpenShop
    
    -- 设置基本信息
    if not self._GridCommon then
        self._GridCommon = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end
    self._GridCommon:Refresh(self.GoodsInfo.RewardGoods)
    
    self:RefreshBuyLimit()
    self:RefreshLockState()
    self:RefreshPrice()
    
    -- 刷新推荐显示
    local isLockOrSellOut = self._IsLock or self._IsSellOut or self._IsHave
    local isShowRecommand = self.GoodsInfo.Tags == XShopManager.ShopTags.Recommend
    local isShowRecommandEffect = not isLockOrSellOut and isShowRecommand
    
    self.RawImgRecommand.gameObject:SetActiveEx(isShowRecommand)
    self.RecommandEffect.gameObject:SetActiveEx(isShowRecommandEffect)
end

function XUiGridGachaCanLiverShop:RefreshBuyLimit()
    -- 判断是否已拥有
    self._IsHave = XRewardManager.CheckRewardGoodsListIsOwnForPackage({ self.GoodsInfo.RewardGoods })
    
    -- 判断是否限购
    if not XTool.IsNumberValid(self.GoodsInfo.BuyTimesLimit) then
        self.PanelLimit.gameObject:SetActiveEx(false)
        self.ImgSellOut.gameObject:SetActiveEx(self._IsHave)

        if self._IsHave then
            self.BtnBuyOperate = Operate.OpenItemTip
        end
    else
        self.PanelLimit.gameObject:SetActiveEx(true)

        -- 显示剩余购买次数(已拥有时，显示可购买数量为0）
        local buyNumber = self._IsHave and 0 or self.GoodsInfo.BuyTimesLimit - self.GoodsInfo.TotalBuyTimes
        local limitLabel = XShopConfigs.GetBuyLimitLabel(self.GoodsInfo.AutoResetClockId)
        local txt = string.format(limitLabel, buyNumber)
        self.TxtLimitLable.text = txt

        -- 判断是否卖完(由于没有专门给出已拥有状态显示，暂定已拥有也视为卖完)
        self._IsSellOut = buyNumber <= 0 or self._IsHave
        self.ImgSellOut.gameObject:SetActiveEx(self._IsSellOut)

        if buyNumber <= 0 or self._IsHave then
            self.BtnBuyOperate = Operate.OpenItemTip
        end
    end
end

function XUiGridGachaCanLiverShop:RefreshLockState()
    -- 判断是否锁定
    local isLock = false
    local lockDesc = ''
    if not XTool.IsTableEmpty(self.GoodsInfo.ConditionIds) then
        for _, v in pairs(self.GoodsInfo.ConditionIds) do
            local ret, desc = XConditionManager.CheckCondition(v)
            if not ret then
                isLock = true
                lockDesc = desc
                self.BtnBuyOperate = Operate.OpenItemTip
                break
            end
        end
    end
    if XTool.IsNumberValid(self.GoodsInfo.OnSaleTime) and self.GoodsInfo.OnSaleTime > XTime.GetServerNowTimestamp() then
        isLock = true
        self.BtnBuyOperate = Operate.OpenItemTip
    end

    self._IsLock = isLock
    -- 如果已拥有，则处于“售罄”状态，则不需要显示未解锁
    self.ImgLock.gameObject:SetActiveEx(isLock and not self._IsHave)
    self.TxtCondition.text = lockDesc
end

function XUiGridGachaCanLiverShop:RefreshPrice()
    local panelCount = #self.PanelPrice
    for i = 1, panelCount do
        self.PanelPrice[i].gameObject:SetActiveEx(false)
    end

    local index = 1
    for _, count in pairs(self.GoodsInfo.ConsumeList) do
        if index > panelCount then
            return
        end

        if self["TxtOldPrice" .. index] then
            if self.Sales == 100 then
                self["TxtOldPrice" .. index].gameObject:SetActiveEx(false)
            else
                self["TxtOldPrice" .. index].text = count.Count
                self["TxtOldPrice" .. index].gameObject:SetActiveEx(true)
            end
        end

        if self["RImgPrice" .. index] and self["RImgPrice" .. index]:Exist() then
            local icon = XDataCenter.ItemManager.GetItemIcon(count.Id)
            if icon ~= nil then
                self["RImgPrice" .. index]:SetRawImage(icon)
            end
        end

        if self["TxtNewPrice" .. index] then
            self._NeedCount = math.floor(count.Count * self.Sales / 100)
            self["TxtNewPrice" .. index].text = self._NeedCount
            local itemCount = XDataCenter.ItemManager.GetCount(count.Id)
            if itemCount < self._NeedCount then
                if not self.ShopItemTextColor then
                    self["TxtNewPrice" .. index].color = CS.UnityEngine.Color(1, 0, 0)
                else
                    self["TxtNewPrice" .. index].color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanNotBuyColor)
                end
            else
                if not self.ShopItemTextColor then
                    self["TxtNewPrice" .. index].color = CS.UnityEngine.Color(0, 0, 0)
                else
                    self["TxtNewPrice" .. index].color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanBuyColor)
                end
            end
        end

        self.PanelPrice[index].gameObject:SetActiveEx(true)
        index = index + 1
    end
end

--- 当商品是时装时，在时装详情里显示购买按钮，并且屏蔽外面的购买界面
function XUiGridGachaCanLiverShop:BugOnFashionDetail()
    self.BtnBuyOperate = Operate.OpenItemTip
    self.GoodsInfo.RewardGoods.ItemIcon = XDataCenter.ItemManager.GetItemIcon(self.GoodsInfo.ConsumeList[1].Id)
    self.GoodsInfo.RewardGoods.ItemCount = self._NeedCount
    self.GoodsInfo.RewardGoods.BuyCallBack = handler(self, self.OnBuyGoods)
    -- 可肝商店和采购商店有特殊联动，采购商店进入涂装详情引导到可肝商店，而可肝商店进入涂装详情正常流程，需要追加标记
    self._GridCommon:SetBuyDataCustomParams({ FromGachaShop = true, HideBuyBtn = self._IsLock })
end
--endregion

--region 事件回调
function XUiGridGachaCanLiverShop:OnBtnBuyClick()
    if self.BtnBuyOperate == Operate.OpenItemTip then
        self._GridCommon:OnBtnClickClick()
        return
    end
    self:OnBuyGoods()
end

function XUiGridGachaCanLiverShop:OnBuyGoods()
    local isCanBuy = self:GetIsCanBuy()
    if not self.IsShopLock and isCanBuy then
        self.Parent:UpdateBuy(
                self.GoodsInfo,
                function()
                    self:RefreshBuyLimit()
                    self:RefreshLockState()
                    self:RefreshPrice()
                end
        )
    else
        if self.ShopLockDecs and self.IsShopLock then
            XUiManager.TipError(self.ShopLockDecs)
            return
        end
        if self.ShopOnSaleLockDecs and not isCanBuy then
            XUiManager.TipError(self.ShopOnSaleLockDecs)
            return
        end
    end
end
--endregion

function XUiGridGachaCanLiverShop:GetIsCanBuy()
    local currentTime = XTime.GetServerNowTimestamp()
    if currentTime >= self.GoodsInfo.OnSaleTime then
        if self.GoodsInfo.SelloutTime <= 0 then
            return true
        end
        return currentTime <= self.GoodsInfo.SelloutTime
    end
    return false
end

return XUiGridGachaCanLiverShop