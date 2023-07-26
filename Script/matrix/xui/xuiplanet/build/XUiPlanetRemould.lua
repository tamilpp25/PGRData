local XUiPlanetRemould = XLuaUiManager.Register(XLuaUi, "UiPlanetRemould")
local XPanelPlanetWeather = require("XUi/XUiPlanet/Weather/XPanelPlanetWeather")
local XPanelPlanetCard = require("XUi/XUiPlanet/Build/XPanelPlanetCard")
local XUiPlanetBuildCardFilter = require("XUi/XUiPlanet/Build/Panel/XUiPlanetBuildCardFilter")
local XPlanelBuildRecycleTog = require("XUi/XUiPlanet/Build/XPlanelBuildRecycleTog")
local XUiPlanetInBuildPanel = require("XUi/XUiPlanet/Build/XUiPlanetInBuildPanel")

function XUiPlanetRemould:OnAwake()
    self:InitObj()
    self:InitTalentItem()
    self:AddBtnClickListener()
end

function XUiPlanetRemould:OnStart()
    XDataCenter.PlanetManager.SetReformQuickBuildMode(false)
end

function XUiPlanetRemould:OnEnable()
    self:Refresh()
    self:UpdateWeather()
    self:CheckTipAndEffect()

    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_WEATHER, self.UpdateWeather, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_IN_BUILD, self.OpenBuildModePanel, self)
end

function XUiPlanetRemould:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_WEATHER, self.UpdateWeather, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_IN_BUILD, self.OpenBuildModePanel, self)
    self.PlanetMainScene:RemoveCurBuilding()
end

function XUiPlanetRemould:OnDestroy()
    XDataCenter.PlanetManager.SetTalentBuildCardFilter(XPlanetTalentConfigs.TalentCardFilter.All)
end

--region Ui刷新
function XUiPlanetRemould:Refresh()
    self:RefreshBuildCardPanel()
    self:RefreshUiActive()
    self:RefreshQuickBuildMode()
end

function XUiPlanetRemould:RefreshUiActive()
    local isInFollow = self.PlanetMainScene:CheckCameraIsFollowMode()
    self.BtnExit.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnPandect.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnRoleSet.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnLocation.gameObject:SetActiveEx(not self.IsHideUi and not self.PlanetMainScene:CheckCameraIsFollowMode())
    self.BtnLocation02.gameObject:SetActiveEx(not self.IsHideUi and self.PlanetMainScene:CheckCameraIsFollowMode())
    self.PanelBottom.gameObject:SetActiveEx(not self.IsHideUi and not isInFollow and not self.PanelInBuildMenu:IsOpen())
    self.PanelBottomBtn.gameObject:SetActiveEx(not self.IsHideUi)
    self.PanelWeather:SetActiveEx(not self.IsHideUi)
    self.BtnHide.gameObject:SetActiveEx(self.IsHideUi)
    self.BtnScreenShot.gameObject:SetActiveEx(not self.IsHideUi)
end

function XUiPlanetRemould:PlayUiActiveAnim()
    self.BtnScreenShot.gameObject:SetActiveEx(not self.IsHideUi)
    self.BtnHide.gameObject:SetActiveEx(self.IsHideUi)
    if self.IsHideUi then
        self:PlayAnimationWithMask("UiHide", handler(self, self.RefreshUiActive))
    else
        self:RefreshUiActive()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiPlanetRemould:RefreshBuildCardPanel()
    self.PanelBuildCardPanel:RefreshGird()
end

function XUiPlanetRemould:InitTalentItem()
    if XTool.UObjIsNil(self.ImgMoney) then
        return
    end
    local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PlanetRunningTalent)
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.PlanetRunningTalent)
    self.ImgMoney:SetSprite(icon)
    self.TxtMoney.text = count
    self.TxtMoneyAdd.gameObject:SetActiveEx(false)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PlanetRunningTalent, function()
        self:RefreshTalentItem()
        self:RefreshBuildCardPanel()
    end, self.TxtMoney)
end

function XUiPlanetRemould:RefreshTalentItem()
    local before = tonumber(self.TxtMoney.text)
    local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PlanetRunningTalent)
    local deltaCount = count - before
    self.TxtMoney.text = count

    if deltaCount ~= 0 then
        self.TxtMoneyAdd.text = deltaCount > 0 and "+" .. deltaCount or deltaCount
        self.TxtMoneyAdd.color = XPlanetConfigs.GetMoneyChangeColor(deltaCount)
        self:PlayAnimationMoneyGain()
    end
end

function XUiPlanetRemould:PlayAnimationMoneyGain()
    self.TxtMoneyAdd.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("TxtMoneyAddEnable", function()
        self.TxtMoneyAdd.gameObject:SetActiveEx(false)
    end)
end

function XUiPlanetRemould:RefreshQuickBuildMode()
    self.Toggle.isOn = XDataCenter.PlanetManager.GetReformQuickBuildMode()
end

function XUiPlanetRemould:UpdateWeather()
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

function XUiPlanetRemould:OpenBuildModePanel()
    self.PanelBottom.gameObject:SetActiveEx(false)
    self.BtnQuick.gameObject:SetActiveEx(false)
    self.BtnDel.gameObject:SetActiveEx(false)
    self.PanelInBuildMenu:Open()
end
--endregion


--region RedPoint
function XUiPlanetRemould:CheckTipAndEffect()
    self:_CheckLimitUnlock(function()
        self:_CheckBuildUnlock()
    end)
end

function XUiPlanetRemould:_CheckLimitUnlock(cb)
    local isTip, _ = XDataCenter.PlanetManager.CheckTalentBuildLimitUnlockRedPoint()
    if isTip then
        XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
            XDataCenter.PlanetManager.ClearTalentBuildLimitUnlockRedPoint()
            if cb then
                cb()
            end
        end, XPlanetConfigs.TipType.NewTalentBuildLimit)
    else
        if cb then
            cb()
        end
    end
end

function XUiPlanetRemould:_CheckBuildUnlock(cb)
    local isTip, playEffectDir = XDataCenter.PlanetManager.CheckTalentBuildUnlockRedPoint()
    if not isTip then
        if cb then
            cb()
        end
        return
    end
    XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
        if self.PanelBuildCardPanel then
            for _, grid in pairs(self.PanelBuildCardPanel.DynamicTable:GetGrids()) do
                if playEffectDir[grid.BuildingId] then
                    grid:PlayUnlockEffect()
                end
            end
        end
        XDataCenter.PlanetManager.ClearTalentBuildUnlockRedPoint()
        if cb then
            cb()
        end
    end, XPlanetConfigs.TipType.NewBuild)
end
--endregion


--region 对象初始化
function XUiPlanetRemould:InitObj()
    self.PanelWeather = XPanelPlanetWeather.New(self, self.BtnWeather, true)
    self.PanelBuildCardPanel = XPanelPlanetCard.New(self, self.PanelCard, true)
    self.PanelBuildQuickRecycle = XPlanelBuildRecycleTog.New(self, self.BtnQuick)
    self.PlanetBuildCardFiter = XUiPlanetBuildCardFilter.New(self, self.BtnScreen)
    self.PlanetBuildCardFiter:RegisterOnValueChanged(function()
        self.PanelBuildCardPanel:UpdateDynamicTable()
    end)
    self.PanelInBuildMenu = XUiPlanetInBuildPanel.New(self, self.PanelMenu, true)
    self.PanelInBuildMenu:SetCallBack(nil, function()
        if self.IsHideUi then
            return
        end
        self.PanelBottom.gameObject:SetActiveEx(true)
        self.BtnQuick.gameObject:SetActiveEx(true)
        self.BtnDel.gameObject:SetActiveEx(true)
    end)
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.PlanetViewModel = XDataCenter.PlanetManager.GetViewModel()
    self.Toggle = XUiHelper.TryGetComponent(self.Quick.transform, "Toggle", "Toggle")
    self.IsHideUi = false

    self:BindViewModelPropertiesToObj(self.PlanetViewModel, function()
        self.PanelBuildCardPanel:RefreshGird()
    end, "_ReformIncId", "_ReformBuildBuyCount", "_ReformBuildingData")
    self:BindViewModelPropertyToObj(self.PlanetViewModel, function()
        self.PanelWeather:Refresh()
    end, "_ReformWeather")
end
--endregion


--region 按钮绑定
function XUiPlanetRemould:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnExit, self.Close)

    XUiHelper.RegisterClickEvent(self, XUiHelper.TryGetComponent(self.Quick.transform, "Toggle/Background"), self.OnToggleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDel, self.OnBtnDelClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPandect, self.OnBtnPandectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnScreenShot, self.OnBtnScreenShotClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRoleSet, self.OnBtnRoleSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLocation, self.OnBtnLocationClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLocation02, self.OnBtnLocationClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnMoneyClick)
end

function XUiPlanetRemould:OnBtnDelClick()
    local title = XUiHelper.GetText("PlanetRunningClearBuildTitle")
    local content = XUiHelper.GetText("PlanetRunningClearBuildContest")
    XLuaUiManager.Open("UiPlanetPropertyPopover", true, title, content, function()
        XDataCenter.PlanetManager.RequestTalentBuildClear()
    end)
end

function XUiPlanetRemould:OnBtnMoneyClick()
    XLuaUiManager.Open("UiPlanetPropertyResources", {
        XDataCenter.ItemManager.ItemId.PlanetRunningTalent,
    })
end

function XUiPlanetRemould:OnBtnPandectClick()
    XLuaUiManager.Open("UiPlanetBuildView")
end

function XUiPlanetRemould:OnBtnScreenShotClick()
    self.IsHideUi = true
    self:PlayUiActiveAnim()
end

function XUiPlanetRemould:OnBtnHideClick()
    self.IsHideUi = false
    self:PlayUiActiveAnim()
end

function XUiPlanetRemould:OnBtnRoleSetClick()
    XLuaUiManager.Open("UiPlanetRole", nil, true)
end

function XUiPlanetRemould:OnBtnLocationClick()
    local isPause = self.PlanetMainScene and self.PlanetMainScene._Explore:IsPause(XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    if isPause or self.PanelInBuildMenu:IsOpen() then
        return
    end
    self.PlanetMainScene:UpdateCameraInFollow()
    self:RefreshUiActive()
end

function XUiPlanetRemould:OnToggleClick()
    local isQuickMode = not XDataCenter.PlanetManager.GetReformQuickBuildMode()
    XDataCenter.PlanetManager.SetReformQuickBuildMode(isQuickMode)
    self:RefreshQuickBuildMode()
end
--endregion