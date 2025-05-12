local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

--=========================================类分界线=========================================--


local XUiGridMoeWarShop = XClass(nil, "XUiGridMoeWarShop")
local XUiGridMoeWarNameplate = require("XUi/XUiMoeWar/ChildItem/XUiGridMoeWarNameplate")


local COLOR = {
    RED = "ff9691ff",
    WHITE = "ffffffff",
    BLUE = "0f70bcff"
}

function XUiGridMoeWarShop:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitUi()
    self:InitCb()
end

function XUiGridMoeWarShop:InitUi()
    self.TxtSaleRate.transform.parent.gameObject:SetActiveEx(false)
end

function XUiGridMoeWarShop:InitCb()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiGridMoeWarShop:Init(rootUi)
    self.RootUi = rootUi
    self.Grid = XUiGridMoeWarNameplate.New(self.GridCommon, rootUi)
end

function XUiGridMoeWarShop:Refresh(itemId)
    self.ItemId = itemId
    self.Grid:Refresh(itemId)
    self.CostItemId = XMoeWarConfig.GetMoeWarNameplateCostItemId(self.ItemId)
    self.CostItemCount = XMoeWarConfig.GetMoeWarNameplateCostItemCount(self.ItemId)
    self.RImgPrice1:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(self.CostItemId))
    local curPrice = self:GetCurrentPrice(self.ItemId)
    self.TxtNewPrice1.text = curPrice
    local costHaveCount = XDataCenter.ItemManager.GetCount(self.CostItemId)
    self.TxtNewPrice1.color = costHaveCount >= tonumber(curPrice)
            and XUiHelper.Hexcolor2Color(COLOR.WHITE) or XUiHelper.Hexcolor2Color(COLOR.RED)
    
    self.UnLockNameplate = XDataCenter.MoeWarManager.CheckHaveNameplateById(self.ItemId)
    local canBuyCount = self.UnLockNameplate and 0 or XMoeWarConfig.MAX_NAMEPLATE_BUY_COUNT
    self.TxtLimitLable.text = CS.XTextManager.GetText("CanBuy", canBuyCount)
    self.TxtLimitLable.color = self.UnLockNameplate and XUiHelper.Hexcolor2Color(COLOR.RED) or XUiHelper.Hexcolor2Color(COLOR.BLUE)
    self.ImgSellOut.gameObject:SetActiveEx(self.UnLockNameplate)
end

function XUiGridMoeWarShop:GetCurrentPrice(itemId)
    local preNameplateId = XMoeWarConfig.GetPreNameplateId(itemId)
    if XTool.IsNumberValid(preNameplateId) then
        local unlock = XDataCenter.MoeWarManager.CheckHaveNameplateById(preNameplateId)
        if unlock then
            local preCost = XMoeWarConfig.GetMoeWarNameplateCostItemCount(preNameplateId)
            return self.CostItemCount - preCost
        end
        return self:GetCurrentPrice(preNameplateId)
    end
    return self.CostItemCount
end

function XUiGridMoeWarShop:OnBtnBuyClick()
    local data = {
        Id = self.ItemId,
        CostItemId = self.CostItemId,
        CostItemCount = self:GetCurrentPrice(self.ItemId),
    }
    self.RootUi:UpdateBuy(data, function() 
        self:Refresh(self.ItemId)
    end)
end


--=========================================类分界线=========================================--


local XUiMoeWarShop = XLuaUiManager.Register(XLuaUi, "UiMoeWarShop")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XUiMoeWarShop:OnAwake()
    self:InitDynamicTable()
    self:InitCb()
end

function XUiMoeWarShop:OnStart()
    XUiHelper.NewPanelActivityAssetSafe( { XDataCenter.ItemManager.ItemId.MoeWarCommemorativeItemId }, self.PanelActivityAsset, self)

    self:InitDropDown()
    self:OnDropdownValueChange()
    local endTime = XDataCenter.MoeWarManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    self.TxtTime.text = string.format("%s：%s", CS.XTextManager.GetText("Residue"), XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY))
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MoeWarManager.OnActivityEnd()
        end
    end)
end

function XUiMoeWarShop:OnEnable()
    XUiMoeWarShop.Super.OnEnable(self)
end

function XUiMoeWarShop:InitDropDown()
    local list = XMoeWarConfig.GetMoeWarNameplateList()
    self.BtnScreenWords:ClearOptions()
    local allOption = Dropdown.OptionData()
    allOption.text = CSXTextManagerGetText("ScreenAll")
    self.BtnScreenWords.options:Add(allOption)
    for _, config in pairs(list or {}) do
        local option = Dropdown.OptionData()
        option.text = config.Name
        self.BtnScreenWords.options:Add(option)
    end
end

function XUiMoeWarShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridMoeWarShop)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end

--region   ------------------回调事件 start-------------------

function XUiMoeWarShop:InitCb()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnScreenWords.onValueChanged:AddListener(function()
        self:OnDropdownValueChange()
    end)
end

function XUiMoeWarShop:OnDropdownValueChange()
    local value = self.BtnScreenWords.value
    self.ItemList = XDataCenter.MoeWarManager.GetMoeWarItemList(value)
    self.DynamicTable:SetDataSource(self.ItemList)
    self.DynamicTable:ReloadDataASync(-1)
end

function XUiMoeWarShop:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ItemList[index])
    end
end

function XUiMoeWarShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiMoeWarShopItem", data, function()
        self:OnDropdownValueChange()
        if cb then cb() end
    end)
end
--endregion------------------回调事件 finish------------------