
--region   ------------------商店--工会场景--格子 start-------------------

local ColorEnum = {
    Red   = CS.UnityEngine.Color(1, 0, 0),
    Black = CS.UnityEngine.Color(0, 0, 0)
}

local XUiGridGuildGoodsShop = XClass(nil, "XUiGridGuildGoodsShop")
local XUiGridGuildDormSceneLabel = require("XUi/XUiGuildDorm/ScenePreview/XUiGridGuildDormSceneLabel")

function XUiGridGuildGoodsShop:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PanelPrice = {
        self.PanelPrice1,
    }
    self.TxtNewPrice = {
        self.TxtNewPrice1,
    }
    self.RImgPrice = {
        self.RImgPrice1,
    }

    self:InitCb()
    self.LabelGrid = {}
end

function XUiGridGuildGoodsShop:Init(uiShop)
    self.UiShop = uiShop
end

function XUiGridGuildGoodsShop:InitCb()
    self.BtnBuy.CallBack = function()
        self:OnBtnBuyClick()
    end
    
    self.BtnPreview.CallBack = function() 
        self:OnBtnPreviewClick()
    end
end

function XUiGridGuildGoodsShop:OnBtnBuyClick()
    if self:GetIsCanBuy() then
        self.UiShop:UpdateBuy(self.Data, function()
            self:RefreshBuy()
            self:RefreshSellOut()
            --self:RefreshCondition()
            self:RefreshOnSales()
            self:RefreshPrice()
            self:RefreshBuyCount()
        end, {
            GetCount = function() 
                return XDataCenter.GuildManager.GetShopCoin()
            end,
        })
    end
end

function XUiGridGuildGoodsShop:GetIsCanBuy()
    --只有管理层才能购买
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipText("GuildGoodsShopAuthorityTips")
        return false
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    if timeOfNow >= self.Data.OnSaleTime then
        if self.Data.SelloutTime <= 0 then
            return true
        end
        return timeOfNow <= self.Data.SelloutTime
    end
    return false
end

function XUiGridGuildGoodsShop:RefreshBuy()
    if self.UiShop then
        self.UiShop:RefreshBuy()
    end
end

function XUiGridGuildGoodsShop:OnBtnPreviewClick()
    if not XTool.IsNumberValid(self.TemplateId) or not self.IsScene then
        self.BtnPreview.gameObject:SetActiveEx(false)
        return
    end
    local targetId = XGuildConfig.GetGoodsTargetId(self.TemplateId)
    if not XTool.IsNumberValid(targetId) then
        self.BtnPreview.gameObject:SetActiveEx(false)
        return
    end
    XLuaUiManager.Open("UiGuildRoomTemplate", targetId)
end



function XUiGridGuildGoodsShop:Refresh(data)
    self.Data = data
    self:RefreshGoodsData()
    self:RefreshSellOut()
    --self:RefreshCondition()
    self:RefreshIcon()
    self:RefreshOnSales()
    self:RefreshPrice()
    self:RemoveTimer()
    self:RemoveOnSaleTimer()
    self:RefreshBuyCount()
    self:RefreshTimer(self.Data.SelloutTime)
    self:RefreshTags()
end

function XUiGridGuildGoodsShop:RefreshGoodsData()
    if type(self.Data.RewardGoods) == "number" then
        self.TemplateId = self.Data.RewardGoods
    else
        self.TemplateId = (self.Data.RewardGoods.TemplateId and self.Data.RewardGoods.TemplateId > 0)
                and self.Data.RewardGoods.TemplateId
                or self.Data.RewardGoods.Id
    end
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TemplateId)
    self.IsScene = self.GoodsShowParams.GoodsType == XGuildConfig.GoodsType.Scene
    self.PanelScene.gameObject:SetActiveEx(self.IsScene)
    self.PanelBgm.gameObject:SetActiveEx(not self.IsScene)
    if self.IsScene then
        local previewList = {}
        local targetId = XGuildConfig.GetGoodsTargetId(self.TemplateId)
        if XTool.IsNumberValid(targetId) then
            local cfg = XGuildDormConfig.GetThemeCfgById(targetId)
            previewList = cfg and cfg.PreviewImageList or {}
        end
        self.BtnPreview.gameObject:SetActiveEx(#previewList > 0)
    end
end

function XUiGridGuildGoodsShop:RefreshSellOut()
    local rImg = self:GetSelloutIcon()
    if not rImg then
        return
    end
    local buyTimeLimit = self.Data.BuyTimesLimit
    local totalBuyTime = self.Data.TotalBuyTimes
    rImg.gameObject:SetActiveEx(buyTimeLimit > 0 and totalBuyTime >= buyTimeLimit)
end

function XUiGridGuildGoodsShop:RefreshIcon()
    if self.GoodsShowParams.Name then
        self:GetTxtName().text = self.GoodsShowParams.Name
    end
    local icon = self.GoodsShowParams.Icon
    if icon then
        self:GetRImgIcon():SetRawImage(icon)
    end
    self.ImgTabLb.gameObject:SetActiveEx(false)
end

function XUiGridGuildGoodsShop:RefreshOnSales()
    self.OnSales = {}
    local tmpSales = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
        table.insert(tmpSales, sales)
    end)
    self.Sales = 100
    if #tmpSales ~= 0 then
        local sortedKey = {}
        for k, _ in pairs(self.OnSales) do
            table.insert(sortedKey, k)
        end
        table.sort(sortedKey)

        local totalBuyTime = self.Data.TotalBuyTimes
        for i = 1, #sortedKey do
            if totalBuyTime >= sortedKey[i] - 1 then
                self.Sales = self.OnSales[sortedKey[i]]
            end
        end
    end

    if not self.TxtSaleRate then
        return
    end
    local hideSales = false
    local tag = self.Data.Tags
    if tag == XShopManager.ShopTags.DisCount then
        if self.Sales < 100 then
            self.TxtSaleRate.text = self.Sales / 10 .. CS.XTextManager.GetText("Snap")
        else
            hideSales = true
        end
    elseif tag == XShopManager.ShopTags.TimeLimit then
        self.TxtSaleRate.text = CS.XTextManager.GetText("TimeLimit")
    elseif tag == XShopManager.ShopTags.Recommend then
        self.TxtSaleRate.text = CS.XTextManager.GetText("Recommend")
    elseif tag == XShopManager.ShopTags.HotSale then
        self.TxtSaleRate.text = CS.XTextManager.GetText("HotSell")
    end

    local hideSaleRate = tag == XShopManager.ShopTags.Not or hideSales

    self.TxtSaleRate.gameObject:SetActiveEx(not hideSaleRate)
    self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(not hideSaleRate)

end

function XUiGridGuildGoodsShop:RefreshPrice()
    local priceCount = #self.PanelPrice
    for i = 1, priceCount do
        self.PanelPrice[i].gameObject:SetActiveEx(false)
    end

    local index = 1
    for _, consume in pairs(self.Data.ConsumeList or {}) do
        if index > priceCount then
            break
        end
        local rImgPrice = self.RImgPrice[index]
        if rImgPrice then
            self.ItemIcon = XDataCenter.ItemManager.GetItemIcon(consume.Id)
            if self.ItemIcon ~= nil then
                rImgPrice:SetRawImage(self.ItemIcon)
            end
        end

        local txtPrice = self.TxtNewPrice[index]
        if txtPrice then
            self.NeedCount = math.floor(consume.Count * self.Sales / 100)
            txtPrice.text = self.NeedCount
            local count = XDataCenter.GuildManager.GetShopCoin()
            txtPrice.color = count >= self.NeedCount and ColorEnum.Black or ColorEnum.Red
        end
        self.PanelPrice[index].gameObject:SetActiveEx(true)
        index = index + 1
    end
end

function XUiGridGuildGoodsShop:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridGuildGoodsShop:RemoveOnSaleTimer()
    if self.OnSaleTimer then
        XScheduleManager.UnSchedule(self.OnSaleTimer)
        self.OnSaleTimer = nil
    end
end

function XUiGridGuildGoodsShop:RefreshBuyCount()
    if not self.ImgLimitLable or not self.TxtLimitLable then
        return
    end
    if self.Data.BuyTimesLimit > 0 then
        local buyNumber = self.Data.BuyTimesLimit - self.Data.TotalBuyTimes
        local limitLabel = XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
        local txt = string.format(limitLabel, buyNumber)
        self.TxtLimitLable.text = txt
        self.ImgLimitLable.gameObject:SetActiveEx(true)
        self.TxtLimitLable.gameObject:SetActiveEx(true)
    else
        self.ImgLimitLable.gameObject:SetActiveEx(false)
        self.TxtLimitLable.gameObject:SetActiveEx(false)
    end
end

function XUiGridGuildGoodsShop:RefreshTimer(time)
    if not self.ImgLeftTime or not self.TxtLeftTime then
        return
    end
    if time > 0 then
        local leftTime = XShopManager.GetLeftTime(time)

        local doRefresh = function()
            leftTime = leftTime > 0 and leftTime or 0
            if self.TxtLeftTime then
                local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.SHOP)
                self.TxtLeftTime.text = XUiHelper.GetText("TimeSoldOut", dataTime)
            end
            if leftTime <= 0 then
                self:RemoveTimer()
                local rImg = self:GetSelloutIcon()
                if rImg then
                    rImg.gameObject:SetActiveEx(true)
                end
            end
        end

        doRefresh()

        self.Timer = XScheduleManager.ScheduleForever(function()
            leftTime = leftTime - 1
            doRefresh()
        end, XScheduleManager.SECOND)
        
        self.ImgLeftTime.gameObject:SetActiveEx(true)
        self.TxtLeftTime.gameObject:SetActiveEx(true)
    else
        self.ImgLeftTime.gameObject:SetActiveEx(false)
        self.TxtLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridGuildGoodsShop:RefreshTags()
    self.PanelLabel.gameObject:SetActiveEx(self.IsScene)
    if not self.IsScene then
        return
    end
    local labels = XGuildConfig.GetThemeLabels(self.TemplateId)
    self.PanelLabel.gameObject:SetActiveEx(not XTool.IsTableEmpty(labels))
    self.TargetId = XGuildConfig.GetGoodsTargetId(self.TemplateId)
    for i, label in ipairs(labels or {}) do
        local grid = self.LabelGrid[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.PanelCol, self.PanelLabel)
            grid = XUiGridGuildDormSceneLabel.New(ui, function() 
                XLuaUiManager.Open("UiGuildRoomSceneTips", self.TargetId)
            end)
            self.LabelGrid[i] = grid
        end
        grid:SetText(label)
        grid:SetActive(true)
    end

    for i, grid in pairs(self.LabelGrid or {}) do
        grid:SetActive(i <= #labels)
    end
    self.PanelCol.gameObject:SetActiveEx(false)
end

function XUiGridGuildGoodsShop:GetSelloutIcon()
    if self.IsScene then
        return self.ImgSceneSellOut
    else
        return self.ImgBgmSellOut
    end
end

function XUiGridGuildGoodsShop:GetRImgIcon()
    if self.IsScene then
        return self.RImgSceneIcon
    else
        return self.RImgBgmIcon
    end
end

function XUiGridGuildGoodsShop:GetTxtName()
    if self.IsScene then
        return self.TxtSceneName
    else
        return self.TxtBgmName
    end
end

return XUiGridGuildGoodsShop

--endregion------------------商店--工会场景--格子 finish------------------
