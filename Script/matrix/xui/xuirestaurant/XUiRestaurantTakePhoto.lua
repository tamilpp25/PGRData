---@class XUiPanelJoystick : XUiNode
---@field _Control XRestaurantControl
local XUiPanelJoystick = XClass(XUiNode, "XUiPanelJoystick")

local XGuildDormHelper = CS.XGuildDormHelper

local IsGuideRunning

function XUiPanelJoystick:OnStart()

    self.Range = 120
    self.Origin = self.BackdragTouch.anchoredPosition
    self.ThresholdSqr = 0
    self.Ratio = 4
    self.IsStart = false
    self.Camera = self._Control:GetRoom():GetCameraModel()
    self:InitCb()

    self:StartUpdate()
end

function XUiPanelJoystick:OnDestroy()
    self:StopUpdate()
    self:Restore()
end

function XUiPanelJoystick:StartUpdate()
    if self.Timer then
        return
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0, 0)
end

function XUiPanelJoystick:StopUpdate()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiPanelJoystick:InitCb()
    local uiWeight = self.JoystickScope.gameObject:AddComponent(typeof(CS.XUiWidget))
    uiWeight:AddBeginDragListener(function(eventData)
        self:OnBeginDrag(eventData)
    end)
    uiWeight:AddEndDragListener(function(eventData)
        self:OnEndDrag(eventData)
    end)
    uiWeight:AddDragListener(function(eventData)
        self:OnDrag(eventData)
    end)
    uiWeight:OnPointerDown(function(eventData)
        self:OnPointerDown(eventData)
    end)
    self:Initialize()
end

function XUiPanelJoystick:OnBeginDrag(eventData)
    if IsGuideRunning then
        return
    end
    if XGuildDormHelper.CheckCanDrag(self.BackdragTouch, eventData, self.Ratio, self.ThresholdSqr) then
        local directionIndex = XGuildDormHelper.UpdateTouchButton(self.BackdragTouch, self.TouchButton, eventData, self.Range)
        local x, y = self:Index2Direction(directionIndex)
        self:DoDrag(x, y)
    end
    self.IsStart = true
end

function XUiPanelJoystick:OnEndDrag(eventData)
    if IsGuideRunning then
        return
    end
    XGuildDormHelper.JoystickPointerUp(self.BackdragTouch, self.TouchButton, self.Origin)
    self.IsStart = false
    self:DoDrag(0, 0)
end

function XUiPanelJoystick:OnDrag(eventData)
    if not self.IsStart then
        return
    end
    if IsGuideRunning then
        return
    end
    if XGuildDormHelper.CheckCanDrag(self.BackdragTouch, eventData, self.Ratio, self.ThresholdSqr) then
        local directionIndex = XGuildDormHelper.UpdateTouchButton(self.BackdragTouch, self.TouchButton, eventData, self.Range)
        local x, y = self:Index2Direction(directionIndex)
        self.LastX = x
        self.LastY = y
    end
end

function XUiPanelJoystick:Update()
    if not self.IsStart then
        return
    end
    self:DoDrag(self.LastX, self.LastY)
end

function XUiPanelJoystick:Index2Direction(index)
    local radian = XGuildDormHelper.PI_TIMES2 * index / XGuildDormHelper.DIR_SPLIT_COUNT
    return math.sin(radian), math.cos(radian)
end

function XUiPanelJoystick:Reset()
    if self.IsStart then
        XGuildDormHelper.JoystickPointerUp(self.BackdragTouch, self.TouchButton, self.Origin)
        self:DoDrag(0, 0)
        self.IsStart = false
    end
end

function XUiPanelJoystick:DoDrag(x, y)
    if IsGuideRunning then
        return
    end
    self.Camera:OnMoveInXZ(x, y)
end

function XUiPanelJoystick:OnAlterLeftStick(args)
    local vector3 = args.Vector
    self:DoDrag(vector3.x, vector3.y)
    XGuildDormHelper.SetTouchButton(self.TouchButton, vector3, self.Range)
end

function XUiPanelJoystick:Initialize()
    if not self.EvtIndex then
        self.EvtIndex = CS.XCommonGenericEventManager.RegisterLuaEvent(CS.XEventId.EVENT_ALTER_LEFT_STICK_EVENT,
                function(evtId, args)
                    self:OnAlterLeftStick(args)
                end)
    end
end

function XUiPanelJoystick:Restore()
    CS.XCommonGenericEventManager.RemoveLuaEvent(CS.XEventId.EVENT_ALTER_LEFT_STICK_EVENT, self.EvtIndex)
    self.EvtIndex = nil
    self:OnEndDrag()
end

---@class XUiRestaurantTakePhoto : XLuaUi
---@field _Control XRestaurantControl
---@field LogoRoot UnityEngine.RectTransform
---@field CameraCapture UnityEngine.Camera
local XUiRestaurantTakePhoto = XLuaUiManager.Register(XLuaUi, "UiRestaurantTakePhoto")

local XUiPhotographCapturePanel = require("XUi/XUiPhotograph/XUiPhotographCapturePanel")

function XUiRestaurantTakePhoto:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantTakePhoto:OnStart()
    self:InitView()
end

function XUiRestaurantTakePhoto:OnEnable()
    self:UpdateLogoSize()
    
    local value = XDataCenter.GuideManager.CheckIsInGuide()
    self:OnHandleStateChange(value)
end

function XUiRestaurantTakePhoto:OnDestroy()
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_START, self.OnGuideEnter)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_END, self.OnGuideExit)
end

function XUiRestaurantTakePhoto:InitUi()
    self.Room = self._Control:GetRoom()
    self.Camera = self.Room:GetCameraModel()
    self.Camera:OnEnterPhoto()

    self.UiJoystick = XUiPanelJoystick.New(self.PanelJoystick, self)
    self.PanelCapture.gameObject:SetActiveEx(false)
    self.UiPanelCapture = XUiPhotographCapturePanel.New(self, self.PanelCapture)

    self.Room:SetForbidDrag(true)

    self.GridTasks = {}

    self.ImgPicture = self.LogoRoot.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Image))

    self.OnGuideEnter = function() 
        self:OnHandleStateChange(true)
    end
    self.OnGuideExit = function() 
        self:OnHandleStateChange(false)
    end
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, self.OnGuideEnter)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_END, self.OnGuideExit)
end

function XUiRestaurantTakePhoto:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn(nil, "UiRestaurantMain")

    local room = self.Room
    self._OnBeginDragCb = handler(self, self.OnBeginDrag)
    room:AddBeginDragCb(self._OnBeginDragCb)
    self._OnEngDragCb = handler(self, self.OnEndDrag)
    room:AddEndDragCb(self._OnEngDragCb)

    self.BtnLeft.CallBack = function()
        self:OnBtnArrowClick(self.Camera:GetLastAreaInfo())
    end

    self.BtnRight.CallBack = function()
        self:OnBtnArrowClick(self.Camera:GetNextAreaInfo())
    end

    self.BtnResetting.CallBack = function()
        self.Camera:ResetPhoto()
    end

    self.BtnPhotograph.CallBack = function()
        self:DoScreenshot()
    end

    self.BtnSave.CallBack = function()
        self:OnBtnSaveClick()
    end
end

function XUiRestaurantTakePhoto:OnRelease()
    local room = self.Room
    room:DelBeginDragCb(self._OnBeginDragCb)
    room:DelEndDragCb(self._OnEngDragCb)

    self.Camera:SetOnCameraViewChangeCb(nil)
    self.Camera:OnExitPhoto()

    self.Room:SetForbidDrag(false)
    
    XLuaUi.OnRelease(self)
end

function XUiRestaurantTakePhoto:InitView()
    self:OnAreaTypeChange()

    self.TxtUserName.text = XPlayer.Name
    self.TxtLevel.text = XPlayer.GetLevelOrHonorLevel()
    self.HonorIcon.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
    self.TxtID.text = string.format("ID: %s", XPlayer.Id)

    self:RefreshArea()

    self.TxtTips.text = self._Control:GetPhotoScrollTip()

    self:UpdateTaskId()
    self.Camera:SetOnCameraViewChangeCb(function()
        self:RefreshTask(false)
        self:RefreshArea()
    end)
end

function XUiRestaurantTakePhoto:UpdateTaskId()
    self.PhotoTaskId = nil
    local perform = self._Control:GetRunningPerform()
    local photoTaskId
    if perform and perform:IsOnGoing() then
        local taskIds = perform:GetPerformTaskIds()
        for _, taskId in ipairs(taskIds) do
            if perform:IsContainPhoto(taskId) and not perform:CheckTaskFinsh(taskId) then
                photoTaskId = taskId
                break
            end
        end
    end

    local showTask = photoTaskId ~= nil
    self.PanelTask.gameObject:SetActiveEx(showTask)
    if showTask then
        self.PhotoTaskId = photoTaskId
        self:RefreshTask(true)
        self.Camera:StartPhotoTimer()
    end
end

function XUiRestaurantTakePhoto:RefreshTask(isRefreshAll)
    if not self.PhotoTaskId then
        return
    end
    for _, grid in pairs(self.GridTasks) do
        grid.GameObject:SetActiveEx(false)
    end
    local perform = self._Control:GetRunningPerform()
    local conditions = perform:GetConditions(self.PhotoTaskId)
    for index, conditionId in ipairs(conditions) do
        local params = perform:GetConditionParams(conditionId)
        local eleId, count = params[1], params[2]
        local grid = self.GridTasks[index]
        if not grid then
            local ui = index == 1 and self.GridTask or XUiHelper.Instantiate(self.GridTask, self.ListTask)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridTasks[index] = grid
        end
        self:RefreshTaskGrid(grid, eleId, count, isRefreshAll)
    end
end

function XUiRestaurantTakePhoto:RefreshArea()
    local area = self.LastArea
    if not area or not self.Camera:CheckInArea(area) then
        for _, areaType in pairs(XMVCA.XRestaurant.AreaType) do
            if areaType == XMVCA.XRestaurant.AreaType.None then
                goto continue
            end
            if self.Camera:CheckInArea(areaType) then
                area = areaType
                break
            end
            :: continue ::
        end
    end

    if area ~= self.LastArea then
        self.ImgNow:SetRawImage(self._Control:GetAreaTypeTitleIcon(area))
        self.Camera:SetAreaType(area)
        self.LastArea = area
        self:OnAreaTypeChange()
    end
end

function XUiRestaurantTakePhoto:RefreshTaskGrid(grid, id, count, isRefreshAll)
    if not grid then
        return
    end
    if isRefreshAll then
        local perform = self._Control:GetRunningPerform()
        grid.TxtTask.text = string.format("%s%s", self._Control:GetPhotoTaskContainTip(count),
                perform:GetPhotoElementName(id))
    end
    local isFinish = self.Room:CheckPhotoElementFinish(id, count)
    grid.ImgRight.gameObject:SetActiveEx(isFinish)
    grid.ImgError.gameObject:SetActiveEx(not isFinish)
    grid.GameObject:SetActiveEx(true)
end

function XUiRestaurantTakePhoto:OnBeginDrag()
    self:SetUiState(false)
end

function XUiRestaurantTakePhoto:OnEndDrag()
    local endCb = function()
        self:SetUiState(true)
        self:OnAreaTypeChange()
    end
    self.Room:OnStopMoveCamera(nil, endCb)
end

function XUiRestaurantTakePhoto:OnAreaTypeChange()
    local camera = self.Camera
    local last = camera:GetLastAreaInfo()
    local next = camera:GetNextAreaInfo()
    self.BtnLeft.gameObject:SetActiveEx(false)
    self.BtnRight.gameObject:SetActiveEx(false)
    if last then
        self.BtnLeft.gameObject:SetActiveEx(true)
        self.BtnLeft:SetNameByGroup(0, self._Control:GetAreaTypeName(last.Type))
    end
    if next then
        self.BtnRight.gameObject:SetActiveEx(true)
        self.BtnRight:SetNameByGroup(0, self._Control:GetAreaTypeName(next.Type))
    end
end

function XUiRestaurantTakePhoto:ChangeState(state)
    if state == XPhotographConfigs.PhotographViewState.Normal then
        self.UiPanelCapture:Hide()
        self:SetUiState(true)
        self:OnHandleStateChange(false)
    elseif state == XPhotographConfigs.PhotographViewState.Capture then
        self.UiPanelCapture:Show()
        self:SetUiState(false)
        self:OnHandleStateChange(true)
    end
end

function XUiRestaurantTakePhoto:SetUiState(value)
    local animName = value and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)
    self.SafeAreaContentPane.gameObject:SetActiveEx(value)
end

function XUiRestaurantTakePhoto:OnBtnArrowClick(direction)
    if not direction then
        return
    end

    self.Camera:MoveTo(direction.Type, self._OnBeginDragCb, function()
        self:SetUiState(true)
        self:OnAreaTypeChange()
    end)
end

function XUiRestaurantTakePhoto:DoScreenshot()
    local pictureName = string.format("[%s]Restaurant-%s", XPlayer.Id,
            XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp(), "yyyy-MM-dd-HH-mm"))

    XCameraHelper.ScreenShotNew(self.ImgPicture, self.Camera:GetCamera(), function(screen)
        XCameraHelper.ScreenShotNew(self.UiPanelCapture.ImagePhoto, self.CameraCapture, function(shot)
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
            self.ShareShot = shot
            self.PictureName = pictureName

            self:ChangeState(XPhotographConfigs.PhotographViewState.Capture)
        end, function()
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCapture)
        end)
    end)

    local performId = 0
    local finish = false
    if self.PhotoTaskId then
        finish = self.Room:CheckPhotoTaskFinish(self.PhotoTaskId)
        if finish then
            local perform = self._Control:GetRunningPerform()
            performId = perform:GetPerformId()
            perform:SetPhotoName(pictureName)
            XUiManager.TipMsg(perform:GetPhotoTaskFinshTip(self.PhotoTaskId))
        end
    end

    self._Control:RequestDoScreenShot(performId, self.PhotoTaskId, function()
        --如果演出Id > 0， 说明演出任务已经完成
        if performId > 0 then
            self.PhotoTaskId = nil
        end
        if finish then
            self:OnPhotoTaskFinish()
        end
    end)

    XMVCA.XRestaurant:BuryingTakePhoto()
end

function XUiRestaurantTakePhoto:OnBtnSaveClick()
    XDataCenter.PhotographManager.SharePhotoBefore(self.PictureName, self.ShareShot, XPlatformShareConfigs.PlatformType.Local)
    if XMain.IsEditorDebug then
        XLog.Debug("[Unity]保存的本地路径:", CS.XTool.GetPhotoAlbumPath() .. self.PictureName)
    end
    XMVCA.XRestaurant:BuryingSavePhoto()
end

function XUiRestaurantTakePhoto:OnPhotoTaskFinish()
    ----移除回调事件
    --self.Camera:SetOnCameraViewChangeCb(nil)
    self:UpdateTaskId()
end

function XUiRestaurantTakePhoto:UpdateLogoSize()
    self.LogoRoot.sizeDelta = Vector2(CsXUiManager.RealScreenWidth, CsXUiManager.RealScreenHeight)
end

function XUiRestaurantTakePhoto:OnHandleStateChange(value)
    IsGuideRunning = value
    if self.Camera then
        self.Camera:SetTouchHandlerEnable(not value)
    end
end