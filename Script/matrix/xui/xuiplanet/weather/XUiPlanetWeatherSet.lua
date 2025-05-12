local XGridPlanetWeatherSet = require("XUi/XUiPlanet/Weather/XGridPlanetWeatherSet")
local XUiPlanetWeatherSet = XLuaUiManager.Register(XLuaUi, "UiPlanetWeatherSet")

function XUiPlanetWeatherSet:OnAwake()
    self:Init()
    self:AddBtnClickListener()
end

function XUiPlanetWeatherSet:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

function XUiPlanetWeatherSet:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

--region 数据&对象
function XUiPlanetWeatherSet:Init()
    self.PlanetViewModel = XDataCenter.PlanetManager.GetViewModel()
    self.CurSelectWeatherId = self.PlanetViewModel:GetReformWeather()
    self.WeatherGrid = {}
    self.WeatherGrid[0] = XGridPlanetWeatherSet.New(self, self.GridCharacter)
    for _, weatherId in pairs(self.PlanetViewModel:GetReformWeatherList()) do
        local go = XUiHelper.Instantiate(self.GridCharacter, self.PanelList)
        self.WeatherGrid[weatherId] = XGridPlanetWeatherSet.New(self, go)
        self.WeatherGrid[weatherId]:InitRedPoint(weatherId)
    end
    self:RefreshUi()
end

function XUiPlanetWeatherSet:SelectWeather(weatherId)
    self.CurSelectWeatherId = weatherId
    self:RefreshUi()
end

function XUiPlanetWeatherSet:RefreshUi()
    for weatherId, weatherGrid in pairs(self.WeatherGrid) do
        weatherGrid:RefreshData(weatherId,
            weatherId == self.PlanetViewModel:GetReformWeather(),
            weatherId == self.CurSelectWeatherId,
            handler(self, self.SelectWeather))
    end
end
--endregion


--region 按钮绑定
function XUiPlanetWeatherSet:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.OnBtnOkClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiPlanetWeatherSet:OnBtnOkClick()
    if self.CurSelectWeatherId == self.PlanetViewModel:GetReformWeather() then
        return
    end
    XDataCenter.PlanetManager.RequestTalentUpdateWeather(self.CurSelectWeatherId, function()
        self:RefreshUi()
    end)
end
--endregion