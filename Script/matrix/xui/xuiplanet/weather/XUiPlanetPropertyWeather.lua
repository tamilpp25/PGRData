local XUiPlanetPropertyWeather = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyWeather")
local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")

function XUiPlanetPropertyWeather:OnAwake()
    self.GridBuffDir = {}
    self.GridDebuffDir = {}
    self:AddBtnClickListener()
end

function XUiPlanetPropertyWeather:OnStart(curRound)
    self.CurRound = curRound
    self.WeatherGroup = XDataCenter.PlanetManager.GetStageData():GetWeatherGroup()

    self:InitWeatherList()
    self.ImgBuffBg01.gameObject:SetActiveEx(false)
    self.ImgBuffBg02.gameObject:SetActiveEx(false)
end

function XUiPlanetPropertyWeather:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

function XUiPlanetPropertyWeather:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end


--region ui
function XUiPlanetPropertyWeather:InitWeatherList()
    self.TabBtns = {}
    local weatherList = self.WeatherGroup:GetGroupWeatherList()
    for _, weatherId in ipairs(weatherList) do
        local go = XUiHelper.Instantiate(self.GridWeather.gameObject, self.PanelStageList.transform)
        local button = go:GetComponent("XUiButton")
        local name = XPlanetWorldConfigs.GetWeatherName(weatherId)
        local icon = XPlanetWorldConfigs.GetWeatherIconUrl(weatherId)
        button:SetNameByGroup(0, name)
        if not string.IsNilOrEmpty(icon) then
            button:SetSprite(icon)
        end
        table.insert(self.TabBtns, button)
    end

    self.PanelStageList:Init(self.TabBtns, function(index) self:OnSelectWeather(index) end)
    self.SelectIndex = self.WeatherGroup:GetCurWeatherIndex()
    self.GridWeather.gameObject:SetActiveEx(false)
    self.PanelStageList:SelectIndex(self.SelectIndex)
end

function XUiPlanetPropertyWeather:OnSelectWeather(index)
    local weatherId = self.WeatherGroup:GetWeatherByIndex(index)
    self:RefreshWeatherPanel(weatherId)
end

function XUiPlanetPropertyWeather:RefreshWeatherPanel(weatherId)
    local curWeatherId = self.WeatherGroup:GetCurWeather()
    if weatherId == curWeatherId then
        local nextWeatherId, nextWeatherRound = self.WeatherGroup:GetNextWeatherAndRoundByCurRound(self.CurRound)
        self.TxtNr.gameObject:SetActiveEx(true)
        self.TxtNr2.gameObject:SetActiveEx(true)
        self.TxtNr.text = XUiHelper.GetText("PlanetRunningNextWeather", nextWeatherRound - self.CurRound)
        self.TxtNr2.text = XPlanetWorldConfigs.GetWeatherName(nextWeatherId)
    else
        self.TxtNr.gameObject:SetActiveEx(false)
        self.TxtNr2.gameObject:SetActiveEx(false)
    end

    -- Desc
    local name = XPlanetWorldConfigs.GetWeatherName(weatherId)
    local bg = XPlanetWorldConfigs.GetWeatherBgUrl(weatherId)
    local eventList = XPlanetWorldConfigs.GetWeatherEvents(weatherId)
    self.TxtName.text = name
    if not string.IsNilOrEmpty(bg) then
        self.RawImage:SetRawImage(bg)
    end

    -- Buff
    local buffEventIdList = {}
    local debuffEventIdList = {}
    for _, eventId in ipairs(eventList) do
        if XPlanetStageConfigs.GetEventIsIncrease(eventId) then
            table.insert(buffEventIdList, eventId)
        else
            table.insert(debuffEventIdList, eventId)
        end
    end
    
    self:RefreshGridBuffList(buffEventIdList, self.GridBuffDir, true)
    if self.ImgNoBuff then
        self.ImgNoBuff.gameObject:SetActiveEx(XTool.IsTableEmpty(buffEventIdList))
    end
    self:RefreshGridBuffList(debuffEventIdList, self.GridDebuffDir, false)
    if self.ImgNoDeBuff then
        self.ImgNoDeBuff.gameObject:SetActiveEx(XTool.IsTableEmpty(debuffEventIdList))
    end
    self:PlayAnimation("QieHuan")
end

function XUiPlanetPropertyWeather:RefreshGridBuffList(eventIdList, gridBuffDir, isBuff)
    if XTool.IsTableEmpty(eventIdList) then
        for _, grid in pairs(gridBuffDir) do
            grid.GameObject:SetActiveEx(false)
        end
        return
    end
    local buffList = XDataCenter.PlanetExploreManager.GetBuffList(eventIdList)
    for index, buff in ipairs(buffList) do
        if buff:IsShow() then
            if XTool.IsTableEmpty(gridBuffDir[index]) then
                local parent = isBuff and self.ImgNoBuff.transform.parent or self.ImgNoDeBuff.transform.parent
                local go = XUiHelper.Instantiate(self.ImgBuffBg01.gameObject, parent)
                gridBuffDir[index] = XUiPlanetGridBuff.New(go)
            end
            gridBuffDir[index]:Update(buff)
            gridBuffDir[index].GameObject:SetActiveEx(true)
        end
    end
end
--endregion


--region 按钮绑定
function XUiPlanetPropertyWeather:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end
--endregion