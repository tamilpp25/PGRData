local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridInfestorExploreContract = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreContract")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInfestorExploreContract = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreContract")

function XUiInfestorExploreContract:OnAwake()
    self.GridContract.gameObject:SetActiveEx(false)
    self.PanelBuy.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList.gameObject)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreContract)
    self.DynamicTable:SetDelegate(self)

    self:AutoAddListener()
end

function XUiInfestorExploreContract:OnEnable()
    self:UpdateView()
end

function XUiInfestorExploreContract:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExploreDaily)
end

function XUiInfestorExploreContract:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_CONTRACT_DAILY_RESET }
end

function XUiInfestorExploreContract:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_INFESTOREXPLORE_CONTRACT_DAILY_RESET then
        self:UpdateView()
    end
end

function XUiInfestorExploreContract:UpdateView()
    XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExploreDaily, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
        self.TxtResetTime.text = timeText
    end)

    self:UpdateDynamicTable()
    self:UpdateMoney()
end

function XUiInfestorExploreContract:UpdateMoney()
    self.TxtSpecialTool.text = XDataCenter.FubenInfestorExploreManager.GetActionPoint()
end

function XUiInfestorExploreContract:UpdateDynamicTable()
    local shopEventIds = XDataCenter.FubenInfestorExploreManager.GetShopEventIds()
    self.ShopEventIds = shopEventIds

    local isEmpty = not next(shopEventIds)
    if isEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self.PanelItemList.gameObject:SetActiveEx(false)
    else
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.PanelItemList.gameObject:SetActiveEx(true)
        self.DynamicTable:SetDataSource(shopEventIds)
        self.DynamicTable:ReloadDataSync()
    end
end

function XUiInfestorExploreContract:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local shopEventId = self.ShopEventIds[index]
        grid:Refresh(shopEventId)

        local isSelect = self.LastSelectId and self.LastSelectId == shopEventId
        grid:SetSelect(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local shopEventId = self.ShopEventIds[index]

        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelect(true)
        self.LastSelectId = shopEventId

        self:ShowBuyPanel(shopEventId)
    end
end

function XUiInfestorExploreContract:ShowBuyPanel(shopEventId)
    if XDataCenter.FubenInfestorExploreManager.IsShopEventSellOut() then
        return
    end

    self.SelectShopEventId = shopEventId
    self.PanelBuy.gameObject:SetActiveEx(true)

    local cost = XFubenInfestorExploreConfigs.GetEventGoodsCost(shopEventId)
    local goodsName = XFubenInfestorExploreConfigs.GetEventName(shopEventId)
    self.TxtTips.text = CSXTextManagerGetText("InfestorExploreContractBuyTips", cost, goodsName)
end

function XUiInfestorExploreContract:AutoAddListener()
    self.BtnBuy.CallBack = function() self:OnClickBtnBuy() end
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiInfestorExploreContract:OnClickBtnBuy()
    local shopEventId = self.SelectShopEventId

    local cost = XFubenInfestorExploreConfigs.GetEventGoodsCost(shopEventId)
    if not XDataCenter.FubenInfestorExploreManager.CheckActionPointEnough(cost) then
        XUiManager.TipText("InfestorExploreShopNodeActionPointNotEnuogh")
        return
    end

    local callBack = function()
        self.PanelBuy.gameObject:SetActiveEx(false)
        self.LastSelectId = nil
        self:UpdateView()
    end
    XDataCenter.FubenInfestorExploreManager.RequestBuyEventGoods(shopEventId, callBack)
end