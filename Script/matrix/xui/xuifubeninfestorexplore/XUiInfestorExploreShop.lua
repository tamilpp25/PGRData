local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridInfestorExploreShopGoods = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreShopGoods")

local CSXTextManagerGetText = CS.XTextManager.GetText
local DialogTitle = CSXTextManagerGetText("InfestorExploreShopNodeLeaveTitle")
local DialogContent = CSXTextManagerGetText("InfestorExploreShopNodeLeaveContent")
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

local XUiInfestorExploreShop = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreShop")

function XUiInfestorExploreShop:OnAwake()
    self:AutoAddListener()
    self.GridShop.gameObject:SetActiveEx(false)
    self.PanelBuy.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreShop:OnStart(chapterId)
    local icon = XDataCenter.FubenInfestorExploreManager.GetMoneyIcon()
    self.RImgIconCost:SetRawImage(icon)
    self.RImgSpecialTool1:SetRawImage(icon)
    self:InitDynamicTable()
end

function XUiInfestorExploreShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreShopGoods)
end

function XUiInfestorExploreShop:OnEnable()
    self:UpdateView()
end

function XUiInfestorExploreShop:UpdateView()
    self:UpdateDynamicTable()
    self:UpdateMoney()
end

function XUiInfestorExploreShop:UpdateDynamicTable()
    local goodIds = XDataCenter.FubenInfestorExploreManager.GetGoodsIds()
    self.GoodsIds = goodIds

    local isEmpty = not next(goodIds)
    if isEmpty then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self.PanelItemList.gameObject:SetActiveEx(false)
    else
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.PanelItemList.gameObject:SetActiveEx(true)
        self.DynamicTable:SetDataSource(goodIds)
        self.DynamicTable:ReloadDataSync()
    end
end

function XUiInfestorExploreShop:UpdateMoney()
    self.TxtSpecialTool1.text = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()

    local cost = XDataCenter.FubenInfestorExploreManager.GetShopRefreshCost()
    local isMoneyEnough = XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost)
    self.TxtRefreshCost.text = cost
    self.TxtRefreshCost.color = CONDITION_COLOR[isMoneyEnough]
end

function XUiInfestorExploreShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local goodsId = self.GoodsIds[index]
        grid:Refresh(goodsId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid
        grid:SetSelect(true)

        local goodsId = self.GoodsIds[index]
        self:ShowBuyPanel(goodsId)
    end
end

function XUiInfestorExploreShop:ShowBuyPanel(goodsId)
    if self.SelectGoodsId and self.SelectGoodsId == goodsId then
        return
    end

    self.SelectGoodsId = goodsId
    self.PanelBuy.gameObject:SetActiveEx(true)

    local cost = XFubenInfestorExploreConfigs.GetGoodsCost(goodsId)
    local goodsName = XFubenInfestorExploreConfigs.GetGoodsName(goodsId)
    self.TxtTips.text = CSXTextManagerGetText("InfestorExploreShopNodeBuyTips", cost, goodsName)
end

function XUiInfestorExploreShop:HideBuyPanel()
    self.SelectGoodsId = nil
    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
    end
    self.LastSelectGrid = nil
    self.PanelBuy.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreShop:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnRefresh.CallBack = function() self:OnClickBtnRefresh() end
    self.BtnBuy.CallBack = function() self:OnClickBtnBuy() end
    self.BtnSpecialTool1.CallBack = function() self:OnClickRImgCostBack() end
    self.BtnRImgIconCost.CallBack = function() self:OnClickRImgCostBack() end
end

function XUiInfestorExploreShop:OnClickRImgCostBack()
    local data = {
        Id = XDataCenter.ItemManager.ItemId.InfestorMoney,
        Count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    }
    XLuaUiManager.Open("UiTip", data)
end

function XUiInfestorExploreShop:OnClickBtnBuy()
    local goodsId = self.SelectGoodsId

    local cost = XFubenInfestorExploreConfigs.GetGoodsCost(goodsId)
    if not XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost) then
        XUiManager.TipText("InfestorExploreShopNodeMoneyNotEnuogh")
        return
    end

    if XDataCenter.FubenInfestorExploreManager.IsGoodsSellOut(goodsId) then
        XUiManager.TipText("InfestorExploreShopNodeSellOut")
        return
    end

    local callBack = function()
        self:HideBuyPanel()
        self:UpdateView()
    end
    XDataCenter.FubenInfestorExploreManager.RequestBuyGoods(goodsId, callBack)
end

function XUiInfestorExploreShop:OnClickBtnRefresh()
    local cost = XDataCenter.FubenInfestorExploreManager.GetShopRefreshCost()
    local isMoneyEnough = XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost)
    if not isMoneyEnough then
        XUiManager.TipText("InfestorExploreShopNodeMoneyNotEnuoghRefresh")
        return
    end

    local callBack = function()
        self:HideBuyPanel()
        self:UpdateView()
    end
    XDataCenter.FubenInfestorExploreManager.RequestRefreshShop(callBack)
end

function XUiInfestorExploreShop:OnClickBtnClose()
    local sureCallback = function()
        XDataCenter.FubenInfestorExploreManager.RequestFinishAction()
        self:Close()
    end
    XUiManager.DialogTip(DialogTitle, DialogContent, XUiManager.DialogType.Normal, nil, sureCallback)
end