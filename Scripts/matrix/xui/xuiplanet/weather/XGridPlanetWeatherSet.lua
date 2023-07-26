---@class XGridPlanetWeatherSet
local XGridPlanetWeatherSet = XClass(nil, "XGridPlanetWeatherSet")

function XGridPlanetWeatherSet:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:InitUi()
end

function XGridPlanetWeatherSet:RefreshData(weatherId, isCur, isSelect, selectFunc)
    local iconUrl = XPlanetWorldConfigs.GetWeatherIconUrl(weatherId) 
    local name = XPlanetWorldConfigs.GetWeatherName(weatherId)
    self.WeatherPanelSelect.gameObject:SetActiveEx(isSelect)
    self.WeatherPanel.gameObject:SetActiveEx(not isSelect)
    if isSelect then
        XUiHelper.GetUiSetIcon(self.RImgSelectIcon, iconUrl)
        self.TxtSelectName.text = name
    else
        XUiHelper.GetUiSetIcon(self.RImgIcon, iconUrl)
        self.TxtName.text = name
    end
    self.PanelTag.gameObject:SetActiveEx(isCur)
    self:UpdateRedPoint()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
        self:ClearRedPoint()
        if selectFunc then selectFunc(weatherId) end 
    end)
end

function XGridPlanetWeatherSet:UpdateRedPoint()
    if not self.Red then
        return
    end
    self.Red.gameObject:SetActiveEx(self.IsShowRedPoint)
end

function XGridPlanetWeatherSet:InitRedPoint(weatherId)
    self.IsShowRedPoint = XDataCenter.PlanetManager.CheckOneWeatherUnlockRedPoint(weatherId)
end

function XGridPlanetWeatherSet:ClearRedPoint()
    self.IsShowRedPoint = false
end

function XGridPlanetWeatherSet:InitUi()
    self.WeatherBgNone.gameObject:SetActiveEx(false)
    self.WeatherPanelSelect.gameObject:SetActiveEx(false)
    self.WeatherPanel.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
end

return XGridPlanetWeatherSet