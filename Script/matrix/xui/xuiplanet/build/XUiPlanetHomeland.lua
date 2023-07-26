local XUiPlanetHomeland = XLuaUiManager.Register(XLuaUi, "UiPlanetHomeland")
local XPanelPlanetWeather = require("XUi/XUiPlanet/Weather/XPanelPlanetWeather")

function XUiPlanetHomeland:OnAwake()
    self:InitObj()
    self:AddBtnClickListener()
end

function XUiPlanetHomeland:OnStart()
    self.PlanetMainScene:UpdateCameraInHomeland()
end

function XUiPlanetHomeland:OnEnable()
    self:UpdateWeather()
    self:UpdateRedPoint()
    self.PanelWeather:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_WEATHER, self.UpdateWeather, self)
end

function XUiPlanetHomeland:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_WEATHER, self.UpdateWeather, self)
end

--region Refrsh
function XUiPlanetHomeland:RefreshUiActive()
    self.BtnExit.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnRemould.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnPandect.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnRoleSet.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnLocation.gameObject:SetActiveEx(not self.IsHideUi)
    self.PanelWeather:SetActiveEx(not self.IsHideUi)
end

function XUiPlanetHomeland:PlayUiActiveAnim()
    self.BtnScreenShot.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnHide.gameObject:SetActiveEx(self.IsHideUi)
    if self.IsHideUi then
        self:PlayAnimationWithMask("UiHide", handler(self, self.RefreshUiActive))
    else
        self:RefreshUiActive()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiPlanetHomeland:UpdateWeather()
    if XTool.UObjIsNil(self.Effect) then
        return
    end
    local weatherId = self.PlanetViewModel:GetReformWeather()
    local icon = XTool.IsNumberValid(weatherId) and XPlanetWorldConfigs.GetWeatherEffectUrl(weatherId) or XPlanetConfigs.GetMainMeteorEffect()
    if not string.IsNilOrEmpty(icon) then
        self.Effect:LoadUiEffect(icon)
        self.Effect.gameObject:SetActiveEx(true)
    else
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetHomeland:UpdateRedPoint()
    self.BtnRemould:ShowReddot(XDataCenter.PlanetManager.CheckTalentBuildRedPoint())
end
--endregion


--region 对象初始化
function XUiPlanetHomeland:InitObj()
    self.PanelWeather = XPanelPlanetWeather.New(self, self.BtnWeather, true)
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.PlanetViewModel = XDataCenter.PlanetManager.GetViewModel()

    self.IsHideUi = false
    
    self:BindViewModelPropertyToObj(self.PlanetViewModel, function()
        self.PanelWeather:Refresh()
    end, "_ReformWeather")
end
--endregion


--region 按钮绑定
function XUiPlanetHomeland:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnExit, self.Close)

    XUiHelper.RegisterClickEvent(self, self.BtnRemould, self.OnBtnRemouldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPandect, self.OnBtnPandectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnScreenShot, self.OnBtnScreenShotClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRoleSet, self.OnBtnRoleSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLocation, self.OnBtnLocationClick)
end

function XUiPlanetHomeland:OnBtnRemouldClick()
    XLuaUiManager.Open("UiPlanetRemould")
end

function XUiPlanetHomeland:OnBtnPandectClick()
    XLuaUiManager.Open("UiPlanetBuildView")
end

function XUiPlanetHomeland:OnBtnScreenShotClick()
    self.IsHideUi = true
    self:PlayUiActiveAnim()
end

function XUiPlanetHomeland:OnBtnHideClick()
    self.IsHideUi = false
    self:PlayUiActiveAnim()
end

function XUiPlanetHomeland:OnBtnLocationClick()
    self.PlanetMainScene:UpdateCameraInFollow()
end

function XUiPlanetHomeland:OnBtnRoleSetClick()
    XLuaUiManager.Open("UiPlanetRole", nil, true)
end
--endregion