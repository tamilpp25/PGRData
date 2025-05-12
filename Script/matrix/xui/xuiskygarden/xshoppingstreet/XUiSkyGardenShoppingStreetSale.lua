---@class XUiSkyGardenShoppingStreetSale : XLuaUi
---@field PanelTop UnityEngine.RectTransform
---@field BtnTab1 XUiComponent.XUiButton
---@field BtnTab2 XUiComponent.XUiButton
---@field GridCelebration UnityEngine.RectTransform
---@field BtnPending XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetSale = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetSale")
local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetSaleGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetSaleGrid")
local XUiSkyGardenShoppingStreetSaleGridTab = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetSaleGridTab")

function XUiSkyGardenShoppingStreetSale:Ctor()
    ---@type XUiSkyGardenShoppingStreetSaleGrid
    self.GridCelebrationUi = nil
end

--region 生命周期
function XUiSkyGardenShoppingStreetSale:OnAwake()
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)

    -- ---@type XUiSkyGardenShoppingStreetSaleGrid
    -- self.GridCelebrationUi = XUiSkyGardenShoppingStreetSaleGrid.New(self.GridCelebration, self)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetSale:OnStart()
    self._SaleTabUiList = {}
    self._SaleUiList = {}
    self:RefreshInfo()
end

function XUiSkyGardenShoppingStreetSale:RefreshInfo()
    self._SaleInfos = {}
    local promotionData = self._Control:GetPromotionData()
    for Id, promotion in pairs(promotionData) do
        local promotionId = promotion.PromotionIds[1]
        local shopId = self._Control:GetShopIdByPromotionId(promotionId)
        local shopName = ""
        if shopId then
            local shopCfg = self._Control:GetShopConfigById(shopId)
            shopName = shopCfg.Name
        end
        table.insert(self._SaleInfos, {
            Id = Id,
            PromotionIds = promotion.PromotionIds,
            Type = promotion.Type,
            ShopName = shopName,
        })
    end
    if #self._SaleInfos <= 0 then
        self:Close()
        return
    end
    table.sort(self._SaleInfos, function(a, b)
        if a.Type ~= b.Type then
            return a.Type > b.Type
        end
        return a.Id < b.Id
    end)

    XTool.UpdateDynamicItem(self._SaleTabUiList, self._SaleInfos, self.BtnTab1, XUiSkyGardenShoppingStreetSaleGridTab, self)
    if #self._SaleInfos > 0 then
        self:SelectTagByIndex(1)
    end
end

function XUiSkyGardenShoppingStreetSale:SelectTagByIndex(index)
    if self._SaleTabUiList[self._SelectTagIndex] then
        self._SaleTabUiList[self._SelectTagIndex]:SetSelect(false)
    end
    self._SelectTagIndex = index
    self._SaleTabUiList[self._SelectTagIndex]:SetSelect(true)

    local data = self._SaleInfos[self._SelectTagIndex]
    XTool.UpdateDynamicItem(self._SaleUiList, data.PromotionIds, self.GridCelebration, XUiSkyGardenShoppingStreetSaleGrid, self)

    if #data.PromotionIds > 0 then
        self:OnSelectSale(0)
    end
end

function XUiSkyGardenShoppingStreetSale:OnEnable()
end

function XUiSkyGardenShoppingStreetSale:OnGetLuaEvents()
    -- return {}
end

function XUiSkyGardenShoppingStreetSale:OnNotify(event, ...)
    
end
--endregion

function XUiSkyGardenShoppingStreetSale:OnSelectSale(selectCellIndex)
    if self._SaleUiList[self._SelectCellIndex] then
        self._SaleUiList[self._SelectCellIndex]:SetSelect(false)
    end
    self._SelectCellIndex = selectCellIndex
    if self._SaleUiList[self._SelectCellIndex] then
        self._SaleUiList[self._SelectCellIndex]:SetSelect(true)
    end
    self.BtnYes:SetButtonState(self._SelectCellIndex == 0 and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetSale:OnBtnPendingClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetSale:OnBtnYesClick()
    if self._SelectCellIndex == 0 then
        return
    end
    local data = self._SaleInfos[self._SelectTagIndex]
    self._Control:SgStreetPromotionSelectRequest(data.Id, self._SelectCellIndex, data.PromotionIds[self._SelectCellIndex], function ()
        self:RefreshInfo()
    end)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetSale:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnPending, self.OnBtnPendingClick, true)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetSale
