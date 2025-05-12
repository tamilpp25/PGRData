---@class XUiSkyGardenShoppingStreetGameGridInsideBuild : XUiNode
---@field PanelLock UnityEngine.RectTransform
---@field PanelUnLock UnityEngine.RectTransform
---@field ImgRed UnityEngine.UI.Image
---@field UiSkyGardenShoppingStreetGameGridInsideBuild XUiComponent.XUiButton
---@field ImgAdd UnityEngine.UI.Image
---@field ImgBg UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field ImgUpgrade UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetGameGridInsideBuild = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameGridInsideBuild")
local XUiSkyGardenShoppingStreetGameGridConflict = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetGameGridConflict")

--region 生命周期
function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnStart(pos, isInside)
    self:_RegisterButtonClicks()
    self._EventUi = {}
    self:ResetConflictEvent()

    self._ShopAreaPos = pos
    self._IsInside = isInside
    self._ShopArea = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnEnable()
    if not self._ShopArea:IsUnlock() then
        self:Close()
        return
    end
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:RefreshBuilding()
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnNotify(event, pos, isInside)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH then
        local position = self._Control:GetAreaIdByUiPos(self._ShopAreaPos, self._IsInside)
        if position == pos then
            self:RefreshBuilding()
        end
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnDestroy()
    
end
--endregion

function XUiSkyGardenShoppingStreetGameGridInsideBuild:RefreshBuilding()
    local isUnlock = self._ShopArea:IsUnlock()
    local hasBuilding = not self._ShopArea:IsEmpty()
    self.PanelLock.gameObject:SetActive(not hasBuilding)
    self.PanelUnLock.gameObject:SetActive(isUnlock and hasBuilding)
    self.ImgLock.gameObject:SetActive(not isUnlock)
    self.ImgAdd.gameObject:SetActive(isUnlock)
    if hasBuilding then
        local shopAreaData = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
        local config = self._Control:GetShopConfigById(shopAreaData:GetShopId(), self._IsInside)
        self.TxtName.text = config.Name
        self.TxtNum.text = shopAreaData:GetShopLevel()

        local isShowScore = config.SortType == 1
        self.PanelBar.gameObject:SetActive(isShowScore)
        if isShowScore then
            local maxShopScore = tonumber(self._Control:GetGlobalConfigByKey("MaxShopScore"))
            local score = shopAreaData:GetShopScore()
            self.ImgBar.fillAmount = score / maxShopScore
        end
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:AddConflictEvent(eventData)
    table.insert(self._EventData, eventData)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:ResetConflictEvent()
    self._EventData = {}
    XTool.UpdateDynamicItem(self._EventUi, nil, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnConflictEventClick(i)
    local taskData = self._EventData[i]
    table.remove(self._EventData, i)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupEvent", taskData)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:SetEditMode(isEditMode)
    self.Edit.gameObject:SetActive(isEditMode)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnUiSkyGardenShoppingStreetGameGridInsideBuildClick()
    if self._Control:IsRunningGame() then return end
    local isUnlock = self._ShopArea:IsUnlock()
    if not isUnlock then
        -- 提示
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_BuildingLock"))
        return
    end
    local hasBuilding = not self._ShopArea:IsEmpty()
    if hasBuilding then
        -- 详情
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetInsideBuild", self._ShopAreaPos, self._IsInside)
    else
        local hasShop2Build = false
        local stageId = self._Control:GetCurrentStageId()
        local shoppingConfig = self._Control:GetStageShopConfigsByStageId(stageId)
        for _, shopId in pairs(shoppingConfig.InsideShopGroup) do
            if not self._Control:GetAreaIdByShopId(shopId) then
                hasShop2Build = true
                break
            end
        end
        if not hasShop2Build then
            XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotShopToBuildTips"))
            return
        end
        -- 解锁
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetBuild", self._ShopAreaPos, self._IsInside)
    end
end

-- 设置阶段状态
function XUiSkyGardenShoppingStreetGameGridInsideBuild:SetGameState(isInGame)
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.UiSkyGardenShoppingStreetGameGridInsideBuild, self.OnUiSkyGardenShoppingStreetGameGridInsideBuildClick, true)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RegisterSchedules()
    --在此处注册定时器
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RemoveSchedules()
    --在此处移除定时器
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RegisterListeners()
    --在此处注册事件监听
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RemoveListeners()
    --在此处移除事件监听
end
--endregion

return XUiSkyGardenShoppingStreetGameGridInsideBuild
