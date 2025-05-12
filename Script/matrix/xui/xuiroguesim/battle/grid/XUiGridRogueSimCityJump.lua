---@class XUiGridRogueSimCityJump : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiPanelRogueSimCityJump
local XUiGridRogueSimCityJump = XClass(XUiNode, "XUiGridRogueSimCityJump")

function XUiGridRogueSimCityJump:OnStart()
    self.Star.gameObject:SetActiveEx(false)
    self.TxtUpgrade.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnCity, self.OnBtnCityClick, nil, true)
    ---@type UiObject[]
    self.GridStarList = {}
end

---@param areaId number 区域Id
function XUiGridRogueSimCityJump:Refresh(areaId)
    self.AreaId = areaId
    self.CityData = self._Control.MapSubControl:GetCityDataByAreaId(areaId)
    self:RefreshAreaView()
end

function XUiGridRogueSimCityJump:RefreshAreaView()
    -- 区域名称
    self.TxtTitle.text = self._Control.MapSubControl:GetRogueSimAreaName(self.AreaId)
    local cityDataEmpty = not self.CityData
    self.TxtUpgrade.gameObject:SetActiveEx(not cityDataEmpty)
    self.PanelStar.gameObject:SetActiveEx(not cityDataEmpty)
    if cityDataEmpty then
        local defaultIcon = self._Control:GetClientConfig("AreaDefaultIcon")
        self.ImgCity:SetSprite(defaultIcon)
        return
    end
    local id = self.CityData:GetId()
    local level = self.CityData:GetLevel()
    -- 图标
    local cityLevelConfigId = self._Control.MapSubControl:GetCityLevelConfigIdById(id, level)
    local icon = self._Control.MapSubControl:GetCityLevelIcon(cityLevelConfigId)
    self.ImgCity:SetSprite(icon)
    -- 星级
    local maxLevel = self._Control.MapSubControl:GetCityMaxLevelById(id)
    for i = 1, maxLevel do
        local grid = self.GridStarList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.Star, self.PanelStar)
            self.GridStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local isOn = level >= i
        grid:GetObject("On").gameObject:SetActiveEx(isOn)
        grid:GetObject("Off").gameObject:SetActiveEx(not isOn)
    end
    for i = maxLevel + 1, #self.GridStarList do
        self.GridStarList[i].gameObject:SetActiveEx(false)
    end
    -- 是否可升级
    local canLevelUp = self._Control.MapSubControl:CheckCityCanLevelUp(id)
    self.TxtUpgrade.gameObject:SetActiveEx(canLevelUp)
end

function XUiGridRogueSimCityJump:OnBtnCityClick()
    self.Parent:PlayDisableAnima(function()
        if self.CityData then
            self._Control:SimulateGridClick(self.CityData:GetGridId())
        else
            local gridId = self._Control.MapSubControl:GetRogueSimAreaFocusGridId(self.AreaId)
            self._Control:CameraFocusGrid(gridId)
        end
    end)
end

return XUiGridRogueSimCityJump
