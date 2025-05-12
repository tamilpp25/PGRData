local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRogueLikeIllegalShop = XLuaUiManager.Register(XLuaUi, "UiRogueLikeIllegalShop")
local XUiGridBlackShopItem = require("XUi/XUiFubenRogueLike/XUiGridBlackShopItem")
local XUiBlackShopBuyDetails = require("XUi/XUiFubenRogueLike/XUiBlackShopBuyDetails")
local XUiShopSpecialTool = require("XUi/XUiFubenRogueLike/XUiShopSpecialTool")

function XUiRogueLikeIllegalShop:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnBuy.CallBack = function() self:OnBtnBuyClick() end

    self.BlackShopBuyDetails = XUiBlackShopBuyDetails.New(self.PanelShopItem, self)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList.gameObject)
    self.DynamicTable:SetProxy(XUiGridBlackShopItem)
    self.DynamicTable:SetDelegate(self)

    -- 支援终端发送事件
    self.SpecialToolList = {}
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_ILLEGAL_SHOP_RESET, self.ResetShop, self)
end

function XUiRogueLikeIllegalShop:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_ILLEGAL_SHOP_RESET, self.ResetShop, self)
end

function XUiRogueLikeIllegalShop:ResetShop()
    if XLuaUiManager.IsUiShow("UiRogueLikeIllegalShop") then
        XLuaUiManager.Close("UiRogueLikeIllegalShop")
    end
end

--动态列表事件
function XUiRogueLikeIllegalShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.BlackItemList[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:SetItemData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for i = 1, #self.BlackItemList do
            local data = self.BlackItemList[i]
            data.IsSelect = i == index
            local lastGrid = self.DynamicTable:GetGridByIndex(i)
            if lastGrid then
                lastGrid:SetItemSelect(data.IsSelect)
            end
        end
        self.CurrentSelectIndex = index
        self:UpdateBuyShopItemInfo()
    end
end

function XUiRogueLikeIllegalShop:OnStart()
    self:RefreshShopItems()
    self:StartCountDown()
end

function XUiRogueLikeIllegalShop:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeIllegalShop")
end

function XUiRogueLikeIllegalShop:RefreshShopItems()

    local supportInfos = XDataCenter.FubenRogueLikeManager.GetSupportInfos()
    local allSupports = XFubenRogueLikeConfig.GetAllSupports()
    self.BlackItemList = {}

    for _, v in pairs(allSupports or {}) do
        local totalBuyCount = v.Count
        local canBuyCount = totalBuyCount - (supportInfos[v.Id] or 0)
        canBuyCount = (canBuyCount > 0) and canBuyCount or 0
        table.insert(self.BlackItemList, {
            SupportId = v.Id,
            TotalBuyCount = totalBuyCount,
            BuyCount = canBuyCount,
            IsSelect = false,
        })
    end

    table.sort(self.BlackItemList, function(itemA, itemB)
        if itemA.BuyCount == itemB.BuyCount then
            return itemA.SupportId < itemB.SupportId
        end
        return itemA.BuyCount > itemB.BuyCount
    end)

    self.DynamicTable:SetDataSource(self.BlackItemList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.BlackItemList <= 0)
    self:InitChallengeCoin()
    self.PanelBuy.gameObject:SetActiveEx(false)
end

function XUiRogueLikeIllegalShop:InitChallengeCoin()
    local hasActionPoint
    local noneActionList = {}
    for _, v in pairs(self.BlackItemList) do
        local supportTemplate = XFubenRogueLikeConfig.GetSupportStationTemplateById(v.SupportId)
        if supportTemplate.NeedPoint == 0 then
            local specialEventId = supportTemplate.SpecialEvent
            local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
            if specialEventTemplate then
                local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(specialEventTemplate.Param[1])
                if shopItemTemplate then
                    local itemId = shopItemTemplate.ConsumeId[1]
                    table.insert(noneActionList, {
                        ItemId = itemId,
                        IsActionPoint = false,
                    })
                end
            end
        else
            hasActionPoint = true
        end
    end
    if hasActionPoint then
        table.insert(noneActionList, {
            IsActionPoint = true
        })
    end

    for i = 1, #noneActionList do
        if not self.SpecialToolList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.PanelSpecialTool.gameObject)
            ui.transform:SetParent(self.PanelSpecialToolContent, false)
            self.SpecialToolList[i] = XUiShopSpecialTool.New(ui, self)
        end
        if noneActionList[i].IsActionPoint then
            local ownActionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
            self.SpecialToolList[i]:SetSpecialToolNum(ownActionPoint)
        else
            self.SpecialToolList[i]:SetSpecialTool(noneActionList[i].ItemId)
        end
        self.SpecialToolList[i].GameObject:SetActiveEx(true)
    end

    for i = #noneActionList + 1, #self.SpecialToolList do
        self.SpecialToolList[i].GameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeIllegalShop:OnDestroy()
    self:StopCountDown()
end

-- 打开购买详情
function XUiRogueLikeIllegalShop:OpenBuyDetails(shopItem)
    self.BlackShopBuyDetails:ShowBlackShopDetails(shopItem)
end

-- 购买信息
function XUiRogueLikeIllegalShop:UpdateBuyShopItemInfo()
    if self.CurrentSelectIndex and self.BlackItemList and self.BlackItemList[self.CurrentSelectIndex] then
        self.PanelBuy.gameObject:SetActiveEx(true)
        local shopItem = self.BlackItemList[self.CurrentSelectIndex]
        local supportTemplate = XFubenRogueLikeConfig.GetSupportStationTemplateById(shopItem.SupportId)
        local supportConfig = XFubenRogueLikeConfig.GetSupportStationConfigById(shopItem.SupportId)
        if supportTemplate.NeedPoint == 0 then
            local specialEventId = supportTemplate.SpecialEvent
            local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
            if specialEventTemplate then
                local shopItemId = specialEventTemplate.Param[1]
                local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
                if shopItemTemplate then
                    local itemId = shopItemTemplate.ConsumeId[1]
                    local needCount = shopItemTemplate.ConsumeNum[1]
                    local itemName = XDataCenter.ItemManager.GetItemName(itemId)
                    --local ownCount = XDataCenter.ItemManager.GetCount(itemId)
                    self.TxtTips.text = CS.XTextManager.GetText("RogueLikeShopBuyItemTips", needCount, itemName, supportConfig.Title)
                end
            end
        else
            -- 更新信息
            local itemNum = supportTemplate.NeedPoint
            self.TxtTips.text = CS.XTextManager.GetText("RogueLikeShopBuyTips", itemNum, supportConfig.Title)
        end
    end
end

-- 购买按钮
function XUiRogueLikeIllegalShop:OnBtnBuyClick()
    if self.CurrentSelectIndex and self.BlackItemList and self.BlackItemList[self.CurrentSelectIndex] then
        local shopItem = self.BlackItemList[self.CurrentSelectIndex]
        if shopItem.BuyCount <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeShopItemSellOut"))
            return
        end

        local supportTemplate = XFubenRogueLikeConfig.GetSupportStationTemplateById(shopItem.SupportId)
        if supportTemplate then
            local needPoint = supportTemplate.NeedPoint
            if needPoint == 0 then
                local specialEventId = supportTemplate.SpecialEvent
                local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
                if specialEventTemplate then
                    local shopItemId = specialEventTemplate.Param[1]
                    local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(shopItemId)
                    if shopItemTemplate then
                        local itemId = shopItemTemplate.ConsumeId[1]
                        local needCount = shopItemTemplate.ConsumeNum[1]
                        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
                        local ownCount = XDataCenter.ItemManager.GetCount(itemId)
                        if ownCount < needCount then
                            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeBuySupportNotEnough", itemName))
                            return
                        end
                    end
                end

            else
                local ownPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
                if ownPoint < needPoint then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeSupportStationCost"))
                    return
                end
            end

            -- 购买机器人特殊判断
            local specialEventId = supportTemplate.SpecialEvent
            local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(specialEventId)
            if specialEventTemplate.Type == XFubenRogueLikeConfig.XRLOtherEventType.AddRobot then
                if XDataCenter.FubenRogueLikeManager.IsAssistRobotFull() then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeSupportCharFull"))
                    return
                end
            end
        end

        XDataCenter.FubenRogueLikeManager.RequestSupportCall(shopItem.SupportId, 1, function()
            self:RefreshShopItems()
        end)
    end
end

function XUiRogueLikeIllegalShop:StartCountDown()
    self:StopCountDown()

    local now = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.FubenRogueLikeManager.GetDayRefreshTime()
    if not endTime then return end
    self.TxtResetTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)

    self.CountTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:StopCountDown()
            return
        end
        self.TxtResetTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    end, XScheduleManager.SECOND, 0)
end

function XUiRogueLikeIllegalShop:StopCountDown()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiRogueLikeIllegalShop:OnBtnCloseClick()
    if XLuaUiManager.IsUiShow("UiRogueLikeIllegalShop") then
        XLuaUiManager.Close("UiRogueLikeIllegalShop")
    end
end

function XUiRogueLikeIllegalShop:OnBtnTanchuangClose()
    if XLuaUiManager.IsUiShow("UiRogueLikeIllegalShop") then
        XLuaUiManager.Close("UiRogueLikeIllegalShop")
    end
end