local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridConsumeActivityShop = XClass(nil,"XUiGridConsumeActivityShop")
local BuyCount = 1
function XUiGridConsumeActivityShop:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:AutoAddListener()
end

function XUiGridConsumeActivityShop:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
    self.Grid = XUiGridCommon.New(self.RootUi, self.Grid256New)
end

function XUiGridConsumeActivityShop:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiGridConsumeActivityShop:OnBtnBuyClick()
    self.Parent:UpdateBuy(
            self.Data,
            function()
                self:RefreshSellOut()
                self:RefreshBuyCount()
                self:RefreshPrice()
            end
    )
end

function XUiGridConsumeActivityShop:Refresh(data)
    self.Data = data
    --名字
    self:RefreshName()
    --已售罄
    self:RefreshSellOut()
    --可购
    self:RefreshBuyCount()
    --价格
    self:RefreshPrice()
    --物品
    self:RefreshCommon()
end

function XUiGridConsumeActivityShop:RefreshCommon()
    local data = self.Data.RewardGoods
    data.ItemIcon = self.ItemIcon
    data.ItemCount = self.ItemCount
    data.GiftRewardId = self.Data.GiftRewardId or 0
    data.BuyCallBack = function()
        for _, consume in pairs(self.Data.ConsumeList) do
            if consume.Id == self.ItemId then
                local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, consume.Count)
                if not result then
                    XUiManager.TipText("BuyNeedItemInsufficient")
                    return
                end
            end
        end

        XShopManager.BuyShop(self.Parent:GetCurShopId(), self.Data.Id, BuyCount, function()
            self:RefreshSellOut()
            self:RefreshBuyCount()
            self:RefreshPrice()

            local text = CS.XTextManager.GetText("BuySuccess")
            XUiManager.TipMsg(text, nil, function()
                if data.GiftRewardId and data.GiftRewardId ~= 0 then
                    local rewardGoodList = XRewardManager.GetRewardList(data.GiftRewardId)
                    XUiManager.OpenUiObtain(rewardGoodList)
                end
            end)
            self.Parent:RefreshBuy()
        end)
    end
    self.Grid:Refresh(data, nil, true)
end

function XUiGridConsumeActivityShop:RefreshName()
    if not self.TxtName then
        return
    end
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.Data.RewardGoods.TemplateId)
    self.TxtName.text = self.GoodsShowParams.Name
end

function XUiGridConsumeActivityShop:RefreshSellOut()
    if not self.ImgSellOut then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        self.ImgSellOut.gameObject:SetActiveEx(false)
    else
        if self.Data.TotalBuyTimes >= self.Data.BuyTimesLimit then
            self.ImgSellOut.gameObject:SetActiveEx(true)
        else
            self.ImgSellOut.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridConsumeActivityShop:RefreshBuyCount()
    if not self.TxtNameDesc then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        self.TxtNameDesc.gameObject:SetActiveEx(false)
    else
        local buynumber = self.Data.BuyTimesLimit - self.Data.TotalBuyTimes
        local limitLabel = XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
        local text = string.format(limitLabel, buynumber)

        self.TxtNameDesc.text = text
        self.TxtNameDesc.gameObject:SetActiveEx(true)
    end
end

function XUiGridConsumeActivityShop:RefreshPrice()
    if not self.TxtCount or not self.ImgIcon then
        return
    end
    
    for _, count in pairs(self.Data.ConsumeList) do
        self.ItemCount = count.Count
        self.ItemId = count.Id
        
        self.TxtCount.text = count.Count
        self.TxtCount.gameObject:SetActiveEx(true)

        self.ItemIcon = XDataCenter.ItemManager.GetItemIcon(count.Id)
        if self.ItemIcon ~= nil then
            self.ImgIcon:SetRawImage(self.ItemIcon)
        end
    end
end

return XUiGridConsumeActivityShop