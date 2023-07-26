local XUiCerberusGameShop = XLuaUiManager.Register(XLuaUi, "UiCerberusGameShop")

function XUiCerberusGameShop:OnAwake()
    self:InitButton()
    self:InitTimes()
    self.CurShopIdList = XDataCenter.CerberusGameManager.GetActivityConfig().ShopId
    self.UiParams = {
        CanBuyColor = "FFFFFFFF",
        CanNotBuyColor = "E53E3EFF",
    }
    self.ItemList = XUiPanelItemList.New(self.PanelItemList, self, nil, self.UiParams, handler(self, self.OnRefreshGrid))
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ XDataCenter.ItemManager.ItemId.CerberusGameCoin1, XDataCenter.ItemManager.ItemId.CerberusGameCoin2 }, self.PanelSpecialTool)

    self.CurSelectIndex = 1
end

function XUiCerberusGameShop:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    
    local tabBtns = { self.BtnTong1, self.BtnTong2 }
    self.BtnTab:Init(tabBtns, function(index) self:OnShopSelect(index) end)
end

function XUiCerberusGameShop:InitTimes()
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
    if not timeId then
        return
    end
    
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiCerberusGameShop:OnEnable()
    self.Super.OnEnable(self)
    XShopManager.GetBaseInfo(function()
        if not self:GetCurShopId() then
            return
        end
        XShopManager.GetShopInfo(self:GetCurShopId(), function()
            self.BtnTab:SelectIndex(1)
        end)
    end)
end

function XUiCerberusGameShop:RefreshUiShow()
    -- 时间
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
    if not XTool.IsNumberValid(timeId) then
        self.TxtLeftTime.gameObject:SetActiveEx(false)
        return
    end

    local shopTimeInfo = XShopManager.GetShopTimeInfo(self:GetCurShopId())
    if not shopTimeInfo then
        return
    end

    local leftTime = shopTimeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtLeftTime.text = timeStr
        self.TxtLeftTime.gameObject:SetActiveEx(true)
    else
        self.TxtLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiCerberusGameShop:OnRefreshGrid(grid, index)
    grid:RefreshCondition()
    grid:RefreshShowLock()
end

function XUiCerberusGameShop:GetCurShopId()
    return self.CurShopIdList[self.CurSelectIndex]
end

function XUiCerberusGameShop:GetShopItemProxy()
    return
    {
        CheckPaidGemTip = function (uiShopItem)
            for k, v in pairs(uiShopItem.Consumes) do
                if v.Id == XDataCenter.ItemManager.ItemId.PaidGem then
                    return true
                end
            end

            return false
        end,
    }
end

function XUiCerberusGameShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff", self:GetShopItemProxy())
end

function XUiCerberusGameShop:RefreshBuy()
    self.ItemList:ShowPanel(self:GetCurShopId())
end

function XUiCerberusGameShop:OnShopSelect(index)
    self.CurSelectIndex = index

    XShopManager.GetShopInfo(self:GetCurShopId(), function()
        self.ItemList:ShowPanel(self:GetCurShopId())
        self:RefreshUiShow()
        self:PlayAnimation("AnimQieHuan")
    end)
end