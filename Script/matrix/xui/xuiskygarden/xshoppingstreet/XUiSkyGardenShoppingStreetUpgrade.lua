local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetBuildGridAttribute = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildGridAttribute")
local XUiSkyGardenShoppingStreetUpgradeGridUpgrade = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetUpgradeGridUpgrade")
---@class XUiSkyGardenShoppingStreetUpgrade : XLuaUi
---@field PanelTop UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field GridUpgrade UnityEngine.RectTransform
---@field GridAttribute UnityEngine.RectTransform
---@field ImgBg UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field TxtConstNumA UnityEngine.UI.Text
---@field TxtConstNumB UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetUpgrade = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetUpgrade")

--region 生命周期
function XUiSkyGardenShoppingStreetUpgrade:OnAwake()
    self._BuildingAttrs = {}
    self._UpgradeInfo = {}
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetUpgrade:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetUpgrade:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH then
        self:_RefreshView()
    end
end

function XUiSkyGardenShoppingStreetUpgrade:OnStart(pos, isInside)
    self._Pos = pos
    self._IsInside = isInside
    self:_RefreshView()
end

function XUiSkyGardenShoppingStreetUpgrade:_RefreshView()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    local upgradeBranch = shopAreaData:GetShopUpgradeBranchIds()
    if #upgradeBranch <= 0 then
        self:_ClosePanel()
        return
    end
    local shopId = shopAreaData:GetShopId()
    local shopLevel = shopAreaData:GetShopLevel()
    self.TxtNum.text = shopLevel

    -- XUiSkyGardenShoppingStreetUpgradeGridUpgrade
    self._AttrDatas = self._Control:GetShopAttributes(shopId, shopLevel, self._IsInside)
    self._UpgradeAttrDatas = self._Control:GetShopAttributes(shopId, shopLevel + 1, self._IsInside, true)
    XTool.UpdateDynamicItem(self._BuildingAttrs, self._AttrDatas, self.GridAttribute, XUiSkyGardenShoppingStreetBuildGridAttribute, self)
    XTool.UpdateDynamicItem(self._UpgradeInfo, upgradeBranch, self.GridUpgrade, XUiSkyGardenShoppingStreetUpgradeGridUpgrade, self)

    if #self._UpgradeInfo > 0 then
        self:SelectUpgradeInfo(1)
    end

    local shopCfg = self._Control:GetShopConfigById(shopId, self._IsInside)
    local upgradeConfig = self._Control:GetShopLevelConfigById(shopId, shopLevel + 1, self._IsInside)
    local cost = upgradeConfig.Cost
    local reduceCost = self._Control:ShopUpgradeCostReduceBySubType(shopCfg.SubType, cost)
    local enoughRes = self._Control:EnoughStageResById(reduceCost)
    self.TxtConstNumA.gameObject:SetActive(enoughRes)
    self.TxtConstNumB.gameObject:SetActive(not enoughRes)
    if enoughRes then
        self.TxtConstNumA.text = reduceCost
    else
        self.TxtConstNumB.text = reduceCost
    end
    local showDiscount = reduceCost ~= cost
    self.TxtDiscount.gameObject:SetActive(showDiscount)
    if showDiscount then
        self.TxtDiscount.text = cost
    end
    if not self._IsInside then
        if self.PanelConsume then self.PanelConsume.gameObject:SetActive(false) end
    end

    local buffId = upgradeConfig.BuffId
    if buffId and buffId > 0 then
        local buffConfig = self._Control:GetBuffConfigById(buffId)
        self.TxtScienceDetail2.text = self._Control:ParseBuffDescById(buffId)
        self.RImgScience:SetRawImage(buffConfig.Icon)
        self.PanelScience.gameObject:SetActive(true)
    else
        self.PanelScience.gameObject:SetActive(false)
    end
end
--endregion

function XUiSkyGardenShoppingStreetUpgrade:GetAttrDatas()
    return self._AttrDatas
end

function XUiSkyGardenShoppingStreetUpgrade:GetUpgradeAttrDatas()
    return self._UpgradeAttrDatas
end

function XUiSkyGardenShoppingStreetUpgrade:SelectUpgradeInfo(index)
    if self._SelectIndex then
        self._UpgradeInfo[self._SelectIndex]:SetSelect(false)
    end
    self._SelectIndex = index
    self._UpgradeInfo[self._SelectIndex]:SetSelect(true)
end

function XUiSkyGardenShoppingStreetUpgrade:GetShopAreaData()
    return self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetUpgrade:OnBtnBackClick()
    self:_ClosePanel()
end

function XUiSkyGardenShoppingStreetUpgrade:OnBtnYesClick()
    self._Control:UpgradeShop(self._Pos, self._IsInside, self._SelectIndex, function()
        self:_ClosePanel()
    end)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetUpgrade:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick, true)
end

function XUiSkyGardenShoppingStreetUpgrade:_ClosePanel()
    if self._isClosePanel then return end
    self._isClosePanel = true
    self:Close()
end
--endregion

return XUiSkyGardenShoppingStreetUpgrade
