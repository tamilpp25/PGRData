local XUiGuildShop = XLuaUiManager.Register(XLuaUi, "UiGuildShop")
local XUiGuildGridShop = require("XUi/XUiGuild/XUiChildItem/XUiGuildGridShop")


function XUiGuildShop:OnAwake()
    self:InitChildView()


    XEventManager.AddEventListener(XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED, self.RefreshComsumeCoin, self)
end

function XUiGuildShop:OnDestroy()
    self:StopCountDown()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED, self.RefreshComsumeCoin, self)
end

function XUiGuildShop:OnStart(shopId)
    self.ShopItemList = XShopManager.GetShopGoodsList(shopId)
    self.ShopId = shopId

    self:RefreshShopList()
    self:RefreshComsumeCoin()
    if self.ShopId == XGuildConfig.GuildPurchaseShop then
        self.RImgConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildContributeCoin))
        self.TxtShopName.text = CS.XTextManager.GetText("GuildPurchaseShopTitle")
    else
        self.RImgConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
        self.TxtShopName.text = CS.XTextManager.GetText("GuildNormalShopTitle")
    end
    self:StartCountDown()
end

-- 花费的货币变化
function XUiGuildShop:RefreshComsumeCoin()
    if self.ShopId == XGuildConfig.GuildPurchaseShop then
        self.TxtConsumeCoin.text = XDataCenter.GuildManager.GetGuildContributeLeft()
    else
        self.TxtConsumeCoin.text = XDataCenter.ItemManager.GetCount(XGuildConfig.GuildCoin)
    end
end

function XUiGuildShop:RefreshShopList()
    self.DynamicShopTable:SetDataSource(self.ShopItemList)
    self.DynamicShopTable:ReloadDataASync()
end


function XUiGuildShop:InitChildView()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end

    self.DynamicShopTable = XDynamicTableNormal.New(self.PanelList.gameObject)
    self.DynamicShopTable:SetProxy(XUiGuildGridShop)
    self.DynamicShopTable:SetDelegate(self)

    XDataCenter.ItemManager.AddCountUpdateListener(XGuildConfig.GuildCoin, function()
        self:RefreshComsumeCoin()
    end, self.TxtConsumeCoin)
end

function XUiGuildShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopItemList[index]
        if not data then return end

        grid:UpdateData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then

        local data = self.ShopItemList[index]
        if not data then return end

        self:OnGridItemClick(data)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiGuildShop:OnGridItemClick(data)
    local title = CS.XTextManager.GetText("GuildDialogTitle")

    local goodsParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.RewardGoods.TemplateId)
    local rewardName = goodsParams.Name
    if goodsParams.RewardType == XArrangeConfigs.Types.Character then
        rewardName = goodsParams.TradeName
    end

    local consumeStr = ""
    for _, consume in pairs(data.ConsumeList or {}) do
        local consumeName = XDataCenter.ItemManager.GetItemName(consume.Id)
        local consumeCount = consume.Count
        local perConsume = string.format("%d%s", consumeCount, consumeName)
        if consumeStr == "" then
            consumeStr = perConsume
        else
            consumeStr = string.forma("%s,%s", consumeStr, perConsume)
        end
    end
    local content = CS.XTextManager.GetText("GuildShopIsCostBuy", consumeStr, rewardName)
    -- 次数是否足够
    local totalBuyTimes = data.TotalBuyTimes
    local totalCanBuyTimes = data.RewardGoods.Count
    if totalBuyTimes >= totalCanBuyTimes then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildShopNotEnoughBuyCount"))
        return
    end
    -- 购买材料是否足够
    for _, consume in pairs(data.ConsumeList or {}) do
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(consume.Id, consume.Count, 1, function()
                self:OnGridItemClick(data)
            end, "BuyNeedItemInsufficient") then
            return
        end
    end

    local func = function()
        XUiManager.TipText("BuySuccess")
        XShopManager.GetShopInfo(self.ShopId, function()
            self.ShopItemList = XShopManager.GetShopGoodsList(self.ShopId)
            self:RefreshShopList()
        end)
    end

    local err_func = function()
        XShopManager.GetShopInfo(self.ShopId, function()
            self.ShopItemList = XShopManager.GetShopGoodsList(self.ShopId)
            self:RefreshShopList()
            self:RefreshComsumeCoin()
        end)
    end

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        -- 判断是否具有权限
        if not XDataCenter.GuildManager.CheckShopBuyAccess(self.ShopId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            self:Close()
            return
        end

        XShopManager.BuyShop(self.ShopId, data.Id, 1, func, err_func)
    end)
end

function XUiGuildShop:UpdateBuy()
end

function XUiGuildShop:StartCountDown()
    self:StopCountDown()
    if not self.ShopId then return end

    local timeInfo = XShopManager.GetShopTimeInfo(self.ShopId)
    if not timeInfo or not next(timeInfo) then
        return
    end

    local dataTime = XUiHelper.GetTime(timeInfo.RefreshLeftTime,  XUiHelper.TimeFormatType.SHOP)
    self.TextTime.text = dataTime

    self.CountTimer = XScheduleManager.ScheduleForever(function()
        if timeInfo.RefreshLeftTime <= 0 then
            self:StopCountDown()
            XShopManager.GetShopInfo(self.ShopId, function()
                self.ShopItemList = XShopManager.GetShopGoodsList(self.ShopId)
                self:RefreshShopList()
                self:StartCountDown()
            end)
            return
        end
        timeInfo.RefreshLeftTime = timeInfo.RefreshLeftTime - 1
        local tmpDataTime = XUiHelper.GetTime(timeInfo.RefreshLeftTime,  XUiHelper.TimeFormatType.SHOP)
        self.TextTime.text = tmpDataTime

    end, XScheduleManager.SECOND, 0)
end

function XUiGuildShop:StopCountDown()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiGuildShop:OnBtnTanchuangClose()
    self:Close()
end


