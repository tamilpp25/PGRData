
local XUidoomsdayWeather = XLuaUiManager.Register(XLuaUi, "UidoomsdayWeather")

local DEFAULT_SELECT_INDEX = 1 --默认选中页签Key

function XUidoomsdayWeather:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUidoomsdayWeather:InitUi()
    self.BtnWarm.gameObject:SetActiveEx(false)
end

function XUidoomsdayWeather:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnCloseBg.CallBack = function() self:Close() end
end

function XUidoomsdayWeather:OnStart(stageId)

    --初始化Tab
    self.WeatherList = XDoomsdayConfigs.GetWeatherSortList(stageId)

    local tabGroup = {}
    self.TabBtnObject = {}
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
    local curWeatherId = self.StageData:GetProperty("_CurWeatherId")
    local defaultIndex
    for i, wId in pairs(self.WeatherList) do
        local cfg = XDoomsdayConfigs.WeatherConfig:GetConfig(wId)
        local btn = CSObjectInstantiate(self.BtnWarm, self.PanelList.transform, false)
        btn:SetSprite(cfg.Icon)
        btn.gameObject:SetActiveEx(true)
        table.insert(tabGroup, btn)
        if not defaultIndex then
            defaultIndex = wId == curWeatherId and i or nil
        end
        local imgGrid = {}
        self.TabBtnObject[cfg.Id] = XTool.InitUiObjectByUi(imgGrid, btn)
    end

    self.PanelList:Init(tabGroup, function(index) self:OnSelect(index) end)
    
    
    self.PanelList:SelectIndex(defaultIndex or DEFAULT_SELECT_INDEX)
    self:InitView()
end

function XUidoomsdayWeather:InitView()
    local curWeatherId = self.StageData:GetProperty("_CurWeatherId")
    for wId, grid in pairs(self.TabBtnObject) do
        grid.ImgNowNormal.gameObject:SetActiveEx(wId == curWeatherId)
        grid.ImgNowPress.gameObject:SetActiveEx(wId == curWeatherId)
        grid.ImgNowSelect.gameObject:SetActiveEx(wId == curWeatherId)
    end
end


function XUidoomsdayWeather:OnSelect(index)
    if index == self.SelectIndex then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:RefreshInfoView()
end

--==============================
---@desc 刷新信息描述界面
--==============================
function XUidoomsdayWeather:RefreshInfoView()
    local wId = self.WeatherList[self.SelectIndex]
    local weatherInfo = XDoomsdayConfigs.WeatherConfig:GetConfig(wId)

    self.TxtWeather.text = weatherInfo.Name
    self.TxtReport.text = weatherInfo.Name
    local desc = string.Split(weatherInfo.Desc, "|")
    self.TxtMessage.text = desc[2] or ""
    self.TxtMessageTwo.text = desc[1] or ""
    self.RImgPhoto:SetRawImage(weatherInfo.BigIcon)
    self.TxtWarm.text = weatherInfo.Temperature
    local attrList = weatherInfo.AttributeId or {}
    local attrType2Data, resourceType2Data = {}, {}
    local unit = XUiHelper.GetText("DoomsdayUnitPeople")
    for _, attrId in  ipairs(attrList) do
        local attr = XDoomsdayConfigs.AttributeConfig:GetConfig(attrId)
        if not attr then
            XLog.Error("未能在[DoomsdayAttribute.tab]找到属性配置 AttributeId = "..attrId)
            goto Continue
        end
        local type = attr.Type
        attrType2Data[type] = XDoomsdayConfigs.GetDoomsdayAttributeWithDaily(attr.DailyChangeValue, XDoomsdayConfigs.AttributeTypeConfig:GetProperty(type, "Name"))
        if XTool.IsNumberValid(attr.ResourceId) then
            resourceType2Data[attr.ResourceId] = XDoomsdayConfigs.GetNumberText(-attr.DailyRequireResourceCount, false, false, false, unit)
        end
        ::Continue::
    end

    self.TxtSpirit.text = attrType2Data[XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN]
    self.Txthealth.text = attrType2Data[XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH]
    self.TxtFull.text = attrType2Data[XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER]

    self.TxtFoodValue.text = resourceType2Data[XDoomsdayConfigs.RESOURCE_TYPE.FOOD]
    self.TxtDrugValue.text = resourceType2Data[XDoomsdayConfigs.RESOURCE_TYPE.MEDICINE]
end 