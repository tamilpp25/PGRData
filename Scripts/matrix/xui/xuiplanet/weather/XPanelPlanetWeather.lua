---@class XPanelPlanetWeather
local XPanelPlanetWeather = XClass(nil, "XPanelPlanetWeather")

function XPanelPlanetWeather:Ctor(rootUi, ui, isTalent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.IsTalent = isTalent
    XTool.InitUiObject(self)
    self:Refresh()
    self:AddBtnClickListener()
end


--region Ui
function XPanelPlanetWeather:Refresh()
    if self.IsTalent then
        self:RefreshTalentWeather()
        self.BtnWeather:ShowReddot(XDataCenter.PlanetManager.CheckAllWeatherUnlockRedPoint())
    else
        self:RefreshStageWeather()
    end
end

function XPanelPlanetWeather:RefreshTalentWeather()
    local weatherId = XDataCenter.PlanetManager.GetViewModel():GetReformWeather()
    local icon = XPlanetWorldConfigs.GetWeatherIconUrl(weatherId)
    local name = XPlanetWorldConfigs.GetWeatherName(weatherId)
    self:RefreshRedPoint()
    self.BtnWeather:SetNameByGroup(1, name)
    if not string.IsNilOrEmpty(icon) then
        self.BtnWeather.ImageList[0]:SetSprite(icon)
        self.BtnWeather.ImageList[1]:SetSprite(icon)
    end
end

function XPanelPlanetWeather:RefreshStageWeather()
    local weatherGroup = XDataCenter.PlanetManager.GetStageData():GetWeatherGroup()
    local curWeatherId = XDataCenter.PlanetManager.GetStageData():GetWeatherId()
    local curTurn = XDataCenter.PlanetManager.GetStageData():GetCycle()
    local nextWeatherId, nextWeatherRound = weatherGroup:GetNextWeatherAndRoundByCurRound(curTurn)
    local curIcon = XPlanetWorldConfigs.GetWeatherIconUrl(curWeatherId)
    local nextIcon = XPlanetWorldConfigs.GetWeatherIconUrl(nextWeatherId)
    local curName = XPlanetWorldConfigs.GetWeatherName(curWeatherId)

    self.BtnWeather:SetNameByGroup(0, XUiHelper.GetText("PlanetRunningStageCurTurn", curTurn - 1))
    self.BtnWeather:SetNameByGroup(1, curName)
    self.BtnWeather:SetNameByGroup(2, XUiHelper.GetText("PlanetRunningStageNextWeather", nextWeatherRound - curTurn))
    if not string.IsNilOrEmpty(curIcon) then
        self.BtnWeather.ImageList[0]:SetSprite(curIcon)
        self.BtnWeather.ImageList[1]:SetSprite(curIcon)
    end
    if not string.IsNilOrEmpty(nextIcon) then
        self.BtnWeather.ImageList[2]:SetSprite(nextIcon)
        self.BtnWeather.ImageList[3]:SetSprite(nextIcon)
    end
end

function XPanelPlanetWeather:RefreshRedPoint()
    self.BtnWeather:ShowReddot(XDataCenter.PlanetManager.CheckAllWeatherUnlockRedPoint())
end
--endregion


--region 按钮绑定
function XPanelPlanetWeather:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnWeather, self.OnBtnClick)
end

function XPanelPlanetWeather:OnBtnClick()
    if self.IsTalent then
        XLuaUiManager.OpenWithCallback("UiPlanetWeatherSet", function()
            XDataCenter.PlanetManager.ClearAllWeatherUnlockRedPoint()
            self:RefreshRedPoint()
        end)
    else
        XLuaUiManager.Open("UiPlanetPropertyWeather", XDataCenter.PlanetManager.GetStageData():GetCycle())
    end
end

function XPanelPlanetWeather:SetActiveEx(active)
    self.GameObject:SetActiveEx(active)
end
--endregion

return XPanelPlanetWeather