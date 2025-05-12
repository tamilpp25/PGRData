---@class XUiSkyGardenShoppingStreetGameGridOutsideBuild : XUiNode
---@field UiSkyGardenShoppingStreetGameGridOutsideBuild XUiComponent.XUiButton
---@field PanelLock UnityEngine.RectTransform
---@field PanelUnLock UnityEngine.RectTransform
---@field PanelRecommend UnityEngine.RectTransform
---@field TxtNameLock UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TxtNum UnityEngine.UI.Text
---@field ImgUpgrade UnityEngine.UI.Image
---@field ImgRed UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetGameGridOutsideBuild = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameGridOutsideBuild")
local XUiSkyGardenShoppingStreetGameGridConflict = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetGameGridConflict")

--region 生命周期
function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnStart(pos, isInside)
    self:_RegisterButtonClicks()
    self._EventUi = {}
    self._EventData = {}

    self._ShopAreaPos = pos
    self._IsInside = isInside

    self:ResetConflictEvent()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnEnable()
    self:RefreshBuilding()
end
--endregion

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:AddConflictEvent(eventData)
    table.insert(self._EventData, eventData)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:ResetConflictEvent()
    self._EventData = {}
    XTool.UpdateDynamicItem(self._EventUi, nil, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnConflictEventClick(i)
    local taskData = self._EventData[i]
    table.remove(self._EventData, i)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupEvent", taskData)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:RefreshBuilding()
    self._ShopArea = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
    local isEmpty = self._ShopArea:IsEmpty()
    if isEmpty or not self._ShopArea:IsUnlock() then
        self:Close()
        return
    end

    self._IsUnlock = self._ShopArea:IsUnlock()
    local notHasShop = self._ShopArea:GetShopLevel() <= 0
    local showLock = not self._IsUnlock or notHasShop
    self.PanelLock.gameObject:SetActive(showLock)
    self.PanelUnLock.gameObject:SetActive(not showLock)

    local shopId = self._ShopArea:GetShopId()
    local config = self._Control:GetShopConfigById(shopId, self._IsInside)
    if not showLock then
        self.TxtName.text = config.Name
        self.TxtNum.text = self._ShopArea:GetShopLevel()
    else
        self.TxtNameLock.text = config.Name
    end
    self.PanelRecommend.gameObject:SetActive(self._Control:GetRecommendShopId() == shopId)
    self.ImgUpgrade.gameObject:SetActive(self._ShopArea:CanShowUpgradeTips() and self._Control:CanBuildShop(self._IsInside))

    local canUnlockOutside = self._Control:CanUnlockOutisdeShop()
    self.ImgRed.gameObject:SetActive(canUnlockOutside and notHasShop)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:SetEditMode(isEditMode)
    self.Edit.gameObject:SetActive(isEditMode)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnUiSkyGardenShoppingStreetGameGridOutsideBuildClick()
    if self._Control:IsRunningGame() then return end
    if not self._IsUnlock then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_BuildingLock"))
        return
    end
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetBuild", self._ShopAreaPos, self._IsInside)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGameGridOutsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.UiSkyGardenShoppingStreetGameGridOutsideBuild, self.OnUiSkyGardenShoppingStreetGameGridOutsideBuildClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetGameGridOutsideBuild
