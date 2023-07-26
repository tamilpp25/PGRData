local XUiChessPursuitMain = XLuaUiManager.Register(XLuaUi, "UiChessPursuitMain")
local XUiChessPursuitMainScene = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitMainScene")
local XUiChessPursuitMainStage = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitMainStage")
local XChessPursuitSceneManager = require("XUi/XUiChessPursuit/XScene/XChessPursuitSceneManager")

function XUiChessPursuitMain:OnAwake()
    self.UiChessPursuitMainBase = nil
    self.Switching = false
    self.EndTime = XChessPursuitConfig.GetActivityEndTime()

    self:AutoAddListener()
    self:Init()

    self.UpdateTimer = XScheduleManager.ScheduleForever(function()
        self:IsTimeToFinish()
    end, 1)

    --引导开启
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))
end

function XUiChessPursuitMain:OnStart()
    XDataCenter.ChessPursuitManager.CheckIsAutoPlayStory()
end

function XUiChessPursuitMain:OnDisable()
    if self.UiChessPursuitMainBase and self.UiChessPursuitMainBase.Disable then
        self.UiChessPursuitMainBase:Disable()
    end
end

function XUiChessPursuitMain:OnDestroy()
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))

    if self.UiChessPursuitMainBase then
        self.UiChessPursuitMainBase:Dispose()
        self.UiChessPursuitMainBase = nil
    end

    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end

    --等dispose的完了再清场景
    XChessPursuitCtrl.LeaveScene()
end

--@region 点击事件

function XUiChessPursuitMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHelp, function() XDataCenter.ChessPursuitManager.OpenHelpTip() end)
end

function XUiChessPursuitMain:OnBtnBackClick()
    if self.Switching then
        return
    end
    if self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.SCENE then
        local defaultUiType = self:GetDefaultUiType()
        self:SwtichUI(defaultUiType, {
            MapId = self:GetDefaultMapId()
        })
    else
        self:Close()
    end
end

function XUiChessPursuitMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--@endregion

--@region 主逻辑

function XUiChessPursuitMain:Init()
    local defaultUiType = self:GetDefaultUiType()
    self:SwtichUI(defaultUiType, {
        MapId = self:GetDefaultMapId()
    })
end

--isReset：强制切换场景
function XUiChessPursuitMain:SwtichUI(uiType, params, isReset)
    if self.Switching or self.UiType == uiType and not isReset then
        return
    end

    local disposeMainBase = function ()
        if self.UiChessPursuitMainBase then
            self.UiChessPursuitMainBase:Dispose()
            self.UiChessPursuitMainBase = nil
        end
    end

    self.Switching = true
    self.IsReload = XChessPursuitCtrl.Enter(params.MapId)

    if params.CallBack then
        params.CallBack()
    end

    self.PanelStage.gameObject:SetActiveEx(false)
    self.PanelScene.gameObject:SetActiveEx(false)
    
    if uiType == XChessPursuitCtrl.MAIN_UI_TYPE.SCENE then
        disposeMainBase()
        self.UiChessPursuitMainBase = XUiChessPursuitMainScene.New(self.PanelScene, self, params.MapId)
    else
        if self.UiChessPursuitMainBase then
            if self.UiChessPursuitMainBase:GetUiType() == XChessPursuitCtrl.MAIN_UI_TYPE.SCENE then
                disposeMainBase()
                self.UiChessPursuitMainBase = XUiChessPursuitMainStage.New(self.PanelStage, self)
            end
        else
            self.UiChessPursuitMainBase = XUiChessPursuitMainStage.New(self.PanelStage, self)
        end
    end

    self:PlayAnimationForScene(uiType, function ()
        self.UiType = uiType
        coroutine.wrap(function()
            local co = coroutine.running()
    
            --有可能播动画的时候， 界面被关闭
            if not self.UiChessPursuitMainBase then
                return
            end

            self.UiChessPursuitMainBase:Init({
                UiType = self.UiType,
            }, function ()
                coroutine.resume(co)
                self.Switching = false
            end)
            coroutine.yield()
        end)()
    end)
end

--@endregion

function XUiChessPursuitMain:GetDefaultMapId()
    local groupId = XChessPursuitConfig.GetCurrentGroupId()
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)

    local mapId
    for i, cfg in ipairs(mapsCfg) do
        local isOpen = XChessPursuitConfig.CheckChessPursuitMapIsOpen(cfg.Id)
        
        if isOpen then
            if XSaveTool.GetData(self:GetSaveToolKey()) == cfg.Id then
                return cfg.Id
            else
                mapId = cfg.Id
            end
        end
    end

    return mapId
end

function XUiChessPursuitMain:GetDefaultUiType()
    local groupId = XChessPursuitConfig.GetCurrentGroupId()
    local mapId = self:GetDefaultMapId()
    local mapCfg = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)

    --Stage 对应UiType
    return mapCfg.Stage
end

function XUiChessPursuitMain:GetSaveToolKey()
    local time = XTime.GetServerNowTimestamp()
    local weekBeginDesc = XTime.TimestampToGameDateTimeString(time, "yyyy-MM")

    return string.format("ChessPursuitMapId_%s_", weekBeginDesc)
end

function XUiChessPursuitMain:PlayAnimationForScene(uiType, cbFunc)
    if uiType == XChessPursuitCtrl.MAIN_UI_TYPE.SCENE then
        XChessPursuitCtrl.PlayAnimationForScene("AnimEnable2", function ()
            cbFunc()
        end)
    else
        if self.IsReload then
            XChessPursuitCtrl.PlayAnimationForScene("AnimEnable", cbFunc)
            return
        end

        --之前不是从场景状态切换过来的
        if self.UiType ~= XChessPursuitCtrl.MAIN_UI_TYPE.SCENE then
            if cbFunc then
                cbFunc()
            end
            return
        end

        local csXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
        local chessPursuitDrawCamera = csXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None)
        chessPursuitDrawCamera:SwitchFieldOfViewState(CS.XFieldOfView.Far, function ()
            chessPursuitDrawCamera:SwitchFieldOfViewState(CS.XFieldOfView.None)
            XChessPursuitCtrl.PlayAnimationForScene("AnimEnable3", cbFunc)
        end)
    end
end

function XUiChessPursuitMain:IsTimeToFinish()
    if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()

    if nowTime >= self.EndTime and self.GameObject.activeSelf then
        XUiManager.TipText("ChessPursuitFinishDesc")
        XLuaUiManager.RunMain()
    end
end

function XUiChessPursuitMain:OnGuideStart()
    local csXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
    if csXChessPursuitCtrlCom then
        local chessPursuitDrawCamera = csXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None)
    end
end

function XUiChessPursuitMain:SetBtnHelpIsHide(isHide)
    self.BtnHelp.gameObject:SetActiveEx(isHide)
end