local XUiSkyGardenShoppingStreetGameGridInsideBuild = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetGameGridInsideBuild")
local XUiSkyGardenShoppingStreetGameGridOutsideBuild = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetGameGridOutsideBuild")
---@class XUiSkyGardenShoppingStreetGameBuildingArea : XUiNode
---@field GameGridInsideBuild1 UnityEngine.RectTransform
---@field GameGridInsideBuild2 UnityEngine.RectTransform
---@field GameGridInsideBuild3 UnityEngine.RectTransform
---@field GameGridInsideBuild4 UnityEngine.RectTransform
---@field GameGridInsideBuild5 UnityEngine.RectTransform
---@field GameGridInsideBuild6 UnityEngine.RectTransform
---@field GridOutsideBuild1 UnityEngine.RectTransform
---@field GridOutsideBuild2 UnityEngine.RectTransform
---@field GridOutsideBuild3 UnityEngine.RectTransform
---@field GridOutsideBuild4 UnityEngine.RectTransform
---@field Bubbles UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetGameBuildingArea = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameBuildingArea")

--region 生命周期
function XUiSkyGardenShoppingStreetGameBuildingArea:OnStart(...)
    self._InSideBuildings = {}
    self._OutSideBuildings = {}

    local insideBuildings = self._Control:GetShopAreas(true)
    self._insideCount = #insideBuildings
    for i = 1, self._insideCount do
        self._InSideBuildings[i] = XUiSkyGardenShoppingStreetGameGridInsideBuild.New(self["GridInsideBuild" .. i], self, i, true)
        self._InSideBuildings[i]:Open()
    end
    local outsideBuildings = self._Control:GetShopAreas(false)
    self._outsideCount = #outsideBuildings
    for i = 1, self._outsideCount do
        self._OutSideBuildings[i] = XUiSkyGardenShoppingStreetGameGridOutsideBuild.New(self["GridOutsideBuild" .. i], self, i, false)
        self._OutSideBuildings[i]:Open()
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH then
        if self._InSideBuildings then
            for i = 1, #self._InSideBuildings do
                self._InSideBuildings[i]:RefreshBuilding()
            end
        end
        if self._OutSideBuildings then
            for i = 1, #self._OutSideBuildings do
                self._OutSideBuildings[i]:RefreshBuilding()
            end
        end
    end
end

--endregion

--region 公共接口
function XUiSkyGardenShoppingStreetGameBuildingArea:AddShopConflictEvent(areaId, eventData)
    if areaId > self._insideCount then
        self._OutSideBuildings[areaId - self._insideCount]:AddConflictEvent(eventData)
    else
        self._InSideBuildings[areaId]:AddConflictEvent(eventData)
    end
end

function XUiSkyGardenShoppingStreetGameBuildingArea:ResetAllShopConflictEvent()
    for i = 1, self._insideCount do
        self._InSideBuildings[i]:ResetConflictEvent()
    end
    for i = 1, self._outsideCount do
        self._OutSideBuildings[i]:ResetConflictEvent()
    end
end

function XUiSkyGardenShoppingStreetGameBuildingArea:SetEditMode(isEdit)
    for i = 1, self._insideCount do
        self._InSideBuildings[i]:SetEditMode(isEdit)
    end
    for i = 1, self._outsideCount do
        self._OutSideBuildings[i]:SetEditMode(isEdit)
    end
end
--endregion

return XUiSkyGardenShoppingStreetGameBuildingArea
