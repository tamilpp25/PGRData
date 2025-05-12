local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetInsideBuildStrategy = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildStrategy")
local XUiSkyGardenShoppingStreetInsideBuildBase = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildBase")
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridFeedback")

---@class XUiSkyGardenShoppingStreetInsideBuild : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field PanelTop UnityEngine.RectTransform
---@field PanelStrategy UnityEngine.RectTransform
---@field PanelBase UnityEngine.RectTransform
---@field Select UnityEngine.RectTransform
---@field BtnFeedback XUiComponent.XUiButton
---@field GridFeedback UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetInsideBuild = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetInsideBuild")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuild:OnStart(pos, isInside)
    self._Pos = pos
    self._IsInside = isInside
    self._PlaceId = self._Control:GetAreaIdByUiPos(self._Pos, self._IsInside)
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    ---@type XUiSkyGardenShoppingStreetInsideBuildBase
    self.PanelBaseUi = XUiSkyGardenShoppingStreetInsideBuildBase.New(self.PanelBase, self)
    self:_RegisterButtonClicks()

    self._Control:X3CSetVirtualCamera(self._PlaceId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Left)
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    -- self.PanelBaseUi:SetBuilding(self._Pos, self._IsInside)
    local config = self._Control:GetShopConfigById(shopId, self._IsInside)
    local pType = config.SortType
    local hasInfo = pType == 1
    self.PanelStrategy.gameObject:SetActive(hasInfo)
    if hasInfo then
        self.PanelStrategyUi = XUiSkyGardenShoppingStreetInsideBuildStrategy.New(self.PanelStrategy, self)
        self.PanelStrategyUi:SetBuilding(self._Pos, self._IsInside)
    end

    self._Infos = shopAreaData:GetFeedbackDatas()
    local canShowFeedback = self._Infos and #self._Infos > 0
    if not canShowFeedback then
        self._Infos = {XMVCA.XBigWorldService:GetText("SG_SS_NoFeedback")}
    end
    self.BtnFeedback.gameObject:SetActive(hasInfo)
    if canShowFeedback and hasInfo then
        self:OnBtnFeedbackClick()
    end
end

function XUiSkyGardenShoppingStreetInsideBuild:OnDisable()
    if self._CloseTimerId then
        XScheduleManager.UnSchedule(self._CloseTimerId)
        self._CloseTimerId = nil
    end
end

function XUiSkyGardenShoppingStreetInsideBuild:OnEnable()
    self.PanelBaseUi:SetBuilding(self._Pos, self._IsInside)
end
--endregion

function XUiSkyGardenShoppingStreetInsideBuild:OnDestroyShop(areaId)
    local cfgDt = tonumber(self._Control:GetGlobalConfigByKey("ShopDestroyDelay")) or 1
    local closeDelay = cfgDt * 1000
    self.BtnBack.gameObject:SetActive(false)
    self.BtnFeedback.gameObject:SetActive(false)
    if self.PanelStrategyUi then self.PanelStrategyUi:Close() end
    if self.PanelBaseUi then self.PanelBaseUi:Close() end
    self._CloseTimerId = XScheduleManager.ScheduleOnce(function ()
        self._Control:X3CBuildingDestroy(areaId)
        self:Close()
    end, closeDelay)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuild:OnBtnBackClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetInsideBuild:GetShopId()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    return shopAreaData:GetShopId()
end

function XUiSkyGardenShoppingStreetInsideBuild:OnBtnFeedbackClick()
    self._IsShowFeedback = not self._IsShowFeedback
    self.BtnFeedback:SetButtonState(self._IsShowFeedback and CS.UiButtonState.Select or CS.UiButtonState.Normal)

    if not self._Feedback then self._Feedback = {} end
    if self._IsShowFeedback then
        XTool.UpdateDynamicItem(self._Feedback, self._Infos, self.GridFeedback, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)
    else
        XTool.UpdateDynamicItem(self._Feedback, nil, self.GridFeedback, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)
    end
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnFeedback, self.OnBtnFeedbackClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuild
