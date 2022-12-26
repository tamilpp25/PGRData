XUiGridShop = XClass(nil, "XUiGridShop")

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiGridShop:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self.PanelPrice = {
        self.PanelPrice1,
        self.PanelPrice2,
        self.PanelPrice3
    }
    self.Timer = nil
end

function XUiGridShop:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
    self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
end

function XUiGridShop:OnRecycle()
    self:RemoveTimer()
    self:RemoveOnSaleTimer()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridShop:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridShop:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiGridShop:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridShop:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridShop:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnCondition, self.OnBtnConditionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end
-- auto
function XUiGridShop:OnBtnConditionClick()
    if self.ConditionDesc then
        XUiManager.TipError(self.ConditionDesc)
    end
end

function XUiGridShop:OnBtnBuyClick()
    if not self.IsShopLock and not self.IsShopOnSaleLock then
        self.Parent:UpdateBuy(self.Data, function()
                self:RefreshSellOut()
                self:RefreshCondition()
                self:RefreshOnSales()
                self:RefreshPrice()
                self:RefreshBuyCount()
            end)
    else
        if self.ShopLockDecs and self.IsShopLock then
            XUiManager.TipError(self.ShopLockDecs)
            return
        end
        if self.ShopOnSaleLockDecs and self.IsShopOnSaleLock then
            XUiManager.TipError(self.ShopOnSaleLockDecs)
            return
        end
    end
end

function XUiGridShop:UpdateData(data,shopItemTextColor)
    self.Data = data
    self.ShopItemTextColor = shopItemTextColor
    self:RefreshSellOut()
    self:RefreshCondition()
    self:RefreshCommon()
    self:RefreshOnSales()
    self:RefreshPrice()
    self:RemoveTimer()
    self:RemoveOnSaleTimer()
    self:RefreshBuyCount()
    self:RefreshTimer(self.Data.SelloutTime)
    self:RefreshOnSaleTime(self.Data.OnSaleTime)
end

function XUiGridShop:RefreshBuyCount()
    if not self.ImgLimitLable then
        return
    end

    if not self.TxtLimitLable then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        self.TxtLimitLable.gameObject:SetActiveEx(false)
        self.ImgLimitLable.gameObject:SetActiveEx(false)
    else
        local buynumber = self.Data.BuyTimesLimit - self.Data.TotalBuyTimes
        local limitLabel =  XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
        local text = string.format(limitLabel, buynumber)

        self.TxtLimitLable.text = text
        self.TxtLimitLable.gameObject:SetActiveEx(true)
        self.ImgLimitLable.gameObject:SetActiveEx(true)
    end
end

function XUiGridShop:RefreshCondition()
    if not self.BtnCondition then return end
    self.BtnCondition.gameObject:SetActiveEx(false)
    self.ConditionDesc = nil
    local conditionIds = self.Data.ConditionIds
    if not conditionIds or #conditionIds <= 0 then return end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id)
        if not ret then
            self.BtnCondition.gameObject:SetActiveEx(true)
            self.ImgSellOut.gameObject:SetActiveEx(false)
            self.ConditionDesc = desc
            return
        end
    end
end

function XUiGridShop:RefreshSellOut()
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


function XUiGridShop:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridShop:RemoveOnSaleTimer()
    if self.OnSaleTimer then
        XScheduleManager.UnSchedule(self.OnSaleTimer)
        self.OnSaleTimer = nil
    end
end

function XUiGridShop:RefreshCommon()
    if self.RImgType then
        self.RImgType.gameObject:SetActiveEx(false)
    end

    self.Grid:Refresh(self.Data.RewardGoods, nil, true)
end

function XUiGridShop:RefreshPrice()
    local panelCount = #self.PanelPrice
    for i = 1, panelCount do
        self.PanelPrice[i].gameObject:SetActiveEx(false)
    end

    local index = 1
    if self.Data.PayKeySuffix then
        if self.PanelCountTxts and self.PanelCountTxts:Exist() then
            self.PanelCountTxts.gameObject:SetActiveEx(false)
        end
        if self.TxtYuan and self.TxtYuan:Exist() then
            self.TxtYuan.gameObject:SetActiveEx(true)
            self.TxtYuan.text = self:GetPayAmount()
        end
    else
        if self.PanelCountTxts and self.PanelCountTxts:Exist() then
            self.PanelCountTxts.gameObject:SetActiveEx(true)
        end
        if self.TxtYuan and self.TxtYuan:Exist() then
            self.TxtYuan.gameObject:SetActiveEx(false)
        end
        for _, count in pairs(self.Data.ConsumeList) do
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
                local needCount = math.floor(count.Count * self.Sales / 100)
                self["TxtNewPrice" .. index].text = needCount
                local itemCount = XDataCenter.ItemManager.GetCount(count.Id)
                if itemCount < needCount then
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
end

function XUiGridShop:GetPayAmount()
    local key
    if Platform == RuntimePlatform.Android then
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.Data.PayKeySuffix)
    else
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.Data.PayKeySuffix)
    end

    local payConfig = XPayConfigs.GetPayTemplate(key)
    return payConfig and payConfig.Amount or 0
end

function XUiGridShop:RefreshOnSales()
    self.OnSales = {}
    self.OnSalesLongTest = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
        table.insert(self.OnSalesLongTest, sales)
    end)

    self.Sales = 100

    if #self.OnSalesLongTest ~= 0 then
        local sortedKeys = {}
        for k, _ in pairs(self.OnSales) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys)

        for i = 1, #sortedKeys do
            if self.Data.TotalBuyTimes >= sortedKeys[i] - 1 then
                self.Sales = self.OnSales[sortedKeys[i]]
            end
        end
    end
    self:RefreshPanelSale()
end

function XUiGridShop:RefreshPanelSale()
    local hideSales = false
    if self.TxtSaleRate then
        if self.Data.Tags == XShopManager.ShopTags.DisCount then
            if self.Sales < 100 then
                self.TxtSaleRate.text = CS.XTextManager.GetText("Snap", 100 - self.Sales)
            else
                hideSales = true
            end
        end
        if self.Data.Tags == XShopManager.ShopTags.TimeLimit then
            self.TxtSaleRate.text = CS.XTextManager.GetText("TimeLimit")
        end
        if self.Data.Tags == XShopManager.ShopTags.Recommend then
            self.TxtSaleRate.text = CS.XTextManager.GetText("Recommend")
        end
        if self.Data.Tags == XShopManager.ShopTags.HotSale then
            self.TxtSaleRate.text = CS.XTextManager.GetText("HotSell")
        end
        if self.Data.Tags == XShopManager.ShopTags.Not or hideSales then
            self.TxtSaleRate.gameObject:SetActiveEx(false)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(false)
        else
            self.TxtSaleRate.gameObject:SetActiveEx(true)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(true)

        end
    end
end

function XUiGridShop:RefreshTimer(time)
    if not self.ImgLeftTime then
        return
    end

    if not self.TxtLeftTime then
        return
    end

    if time <= 0 then
        self.TxtLeftTime.gameObject:SetActiveEx(false)
        self.ImgLeftTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtLeftTime.gameObject:SetActiveEx(true)
    self.ImgLeftTime.gameObject:SetActiveEx(true)

    local leftTime = XShopManager.GetLeftTime(time)

    local func = function()
        leftTime = leftTime > 0 and leftTime or 0
        local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.SHOP)
        if self.TxtLeftTime then
            self.TxtLeftTime.text = CS.XTextManager.GetText("TimeSoldOut", dataTime)
        end
        if leftTime <= 0 then
            self:RemoveTimer()
            if self.ImgSellOut then
                self.ImgSellOut.gameObject:SetActiveEx(true)
            end
        end
    end

    func()

    self.Timer = XScheduleManager.ScheduleForever(function()
        leftTime = leftTime - 1
        func()
    end, 1000)
end


function XUiGridShop:RefreshOnSaleTime(time)
    if not self.TxtOnSaleTime then
        return
    end

    if time <= 0 then
        self.TxtOnSaleTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtOnSaleTime.gameObject:SetActiveEx(true)
    self.ShopOnSaleLockDecs = CS.XTextManager.GetText("ActivityBriefShopOnSaleLock")
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(true)
    end

    local SaleTime = XShopManager.GetLeftTime(time)

    local func = function()
        SaleTime = SaleTime > 0 and SaleTime or 0
        local dataTime = XUiHelper.GetTime(SaleTime, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtOnSaleTime then
            self.TxtOnSaleTime.text = CS.XTextManager.GetText("TimeOnSale", dataTime)
        end
        if SaleTime <= 0 then
            self:RemoveOnSaleTimer()
            if self.TxtOnSaleTime then
                self.TxtOnSaleTime.gameObject:SetActiveEx(false)
            end
            if self.ImgLock then
                self.ImgLock.gameObject:SetActiveEx(false)
            end
            self.IsShopOnSaleLock = false
        else
            self.IsShopOnSaleLock = true
        end
    end

    func()

    self.OnSaleTimer = XScheduleManager.ScheduleForever(function()
            SaleTime = SaleTime - 1
            func()
        end, 1000)
end