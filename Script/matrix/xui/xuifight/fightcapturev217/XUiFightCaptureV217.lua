-- 战斗2.17版本的拍照界面
---@class XUiFightCaptureV217 : XLuaUi
---@field XUiPanelAction XUiPanelAction
---@field XUiPanelSticker XUiPanelSticker
---@field XUiPanelJoystick XUiFightCaptureV217PanelJoystick
---@field _Control XFightCaptureV217Control
local XUiFightCaptureV217 = XLuaUiManager.Register(XLuaUi, "UiFightCaptureV217")
local XUiPanelAction = require("XUi/XUiFight/FightCaptureV217/XUiPanelAction")
local XUiPanelSticker = require("XUi/XUiFight/FightCaptureV217/XUiPanelSticker")
local XUiGridPaster = require("XUi/XUiFight/FightCaptureV217/XUiGridPaster")
local XUiPanelJoystick = require("XUi/XUiFight/FightCaptureV217/XUiPanelJoystick")

local EventSystemCurrent = CS.UnityEngine.EventSystems.EventSystem.current
local Input = CS.UnityEngine.Input
local CSXInputManager = CS.XInputManager
local BtnActionName = CS.XFight.ClientConfig:GetString("Action")
local BtnOtherName = CS.XFight.ClientConfig:GetString("Other")
local BtnPasterName = CS.XFight.ClientConfig:GetString("Paster")
local BtnFilterName = CS.XFight.ClientConfig:GetString("Filter")
local BtnActionEnName = CS.XFight.ClientConfig:GetString("ActionEn")
local BtnOtherEnName = CS.XFight.ClientConfig:GetString("OtherEn")
local BtnPasterEnName = CS.XFight.ClientConfig:GetString("PasterEn")
local BtnFilterEnName = CS.XFight.ClientConfig:GetString("FilterEn")

local PC_OPERATION_KEY = {
    SPACE = 1,
    Q = 2,
    E = 3,
    R = 4,
    Mouse1 = 5, --鼠标右键
    A = 6,
    D = 7,
    W = 8,
    S = 9,
}
local CAMERA_MOVE_NORMALIZED_DIST = 1

function XUiFightCaptureV217:OnAwake()
    self.BtnIndexEnum = {
        Action = 1, --动作
        Other = 2,  --其他
        Paster = 3, --贴纸
        Filter = 4, --滤镜
    }
    
    XUiHelper.RegisterClickEvent(self, self.BtnBlank, self.OnBtnBlankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTab1, self.OnBtnTab1Click)
    XUiHelper.RegisterClickEvent(self, self.BtnTab2, self.OnBtnTab2Click)
    XUiHelper.RegisterClickEvent(self, self.BtnMenu, self.OnBtnMenuClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPaster, self.OnBtnMenuClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPhotograph, self.OnBtnPhotographClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPhotoSave, self.OnBtnPhotoSaveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnBtnAgainClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStop, self.OnBtnStopClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFovAdd, self.OnBtnFovAddClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFovReduce, self.OnBtnFovReduceClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSliderChanged)

    self.GridPasterPool = XObjectPool.New(function()
        return self:OnGridPasterCreate()
    end)
    
    self.XUiPanelJoystick = XUiPanelJoystick.New(self.PanelJoystick, self)
    self.XUiPanelAction = XUiPanelAction.New(self.PanelAction, self)
    self.XUiPanelSticker = XUiPanelSticker.New(self.PanelSticker, self)
    self.XUiPanelAction:OnSelected(false)
    self.XUiPanelSticker:OnSelected(false)

    if XDataCenter.UiPcManager.IsPc() then
        self:AddPCKeyListener()
    end
    -- 关闭导航
    if EventSystemCurrent then
        EventSystemCurrent.sendNavigationEvents = false
    end
end

function XUiFightCaptureV217:OnStart(cameraCfgId, npcAnimCfgGroupId, stickerCfgGroupId, effectCfgId, unlockStickerIdList, unlockActionIdList)
    if CS.XFight.IsRunning then
        CS.XFight.Instance:Pause(false)
    end
    
    self:InitCamera(cameraCfgId)
    self.GridPasterList = {}
    self:SetIsShowMenu(true)
    self:SetIsPhotographed(false)
    self:SetBtnIndex(self.BtnIndexEnum.Action)
    self.XUiPanelAction:SetData(npcAnimCfgGroupId, unlockActionIdList)
    self.XUiPanelSticker:SetData(stickerCfgGroupId, unlockStickerIdList)
    self._Control:SetScreenEffectCallBack(handler(self, self.SetScreenEffect))
    XScheduleManager.ScheduleOnce(function()
        self:OnSliderChanged(0)
    end, 1)
end

function XUiFightCaptureV217:InitCamera(cameraCfgId)
    self.CameraCfgId = cameraCfgId
    
    self.OwnCamera = CS.XFight.Instance.RLManager.OwnCamera
    self.CameraController = self.OwnCamera.VCameraRootTransform.gameObject:AddComponent(typeof(CS.XFightCaptureV217CameraController))
    self.CameraController:SetParam(cameraCfgId)
    local npc = self._Control:GetRLNpc()
    if npc and npc.Transform then
        XCameraHelper.SetCameraTarget(self.CameraController, npc.Transform)
    end
end

function XUiFightCaptureV217:OnEnable()
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.Capture)
    CS.XJoystickLSHelper.ForceResponse = true
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.Update), 0)
    self:Refresh()
end

function XUiFightCaptureV217:OnDisable()
    XDataCenter.InputManagerPc.ResumeCurInputMap()
    CS.XJoystickLSHelper.ForceResponse = false
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiFightCaptureV217:OnDestroy()
    if self.OwnCamera then
        local cameraController = self.OwnCamera.VCameraRootTransform.gameObject:GetComponent(typeof(CS.XFightCaptureV217CameraController))
        CS.UnityEngine.GameObject.Destroy(cameraController)
    end
    self.GridPasterPool:Clear()
    self._Control:SetNpcActive(true)
    self._Control:SetActiveDof(false)
    if XDataCenter.UiPcManager.IsPc() then
        self:RemovePCKeyListener()
    end
    
    if EventSystemCurrent then
        EventSystemCurrent.sendNavigationEvents = true
    end

    if CS.XFight.IsRunning then
        CS.XFight.Instance:Resume()
    end
end

function XUiFightCaptureV217:Refresh()
    self:RefreshMenu()
    self.BtnBlank.gameObject:SetActiveEx(self.IsPhotographed)
    self.PanelCapture.gameObject:SetActiveEx(self.IsPhotographed)
    self.BtnPhotoSave.gameObject:SetActiveEx(self.IsPhotographed)
    self.PanelFov.gameObject:SetActiveEx(not self.IsPhotographed)
    self.BtnAgain.gameObject:SetActiveEx(not self.IsPhotographed)
    self.BtnStop.gameObject:SetActiveEx(not self.IsPhotographed)
    self.BtnPhotograph.gameObject:SetActiveEx(not self.IsPhotographed)
end

function XUiFightCaptureV217:RefreshMenu()
    if self.IsShowMenu then
        self.Bg.gameObject:SetActiveEx(true)
        self.XUiPanelJoystick.GameObject:SetActiveEx(false)
        self.BtnTab1.gameObject:SetActiveEx(true)
        self.BtnTab2.gameObject:SetActiveEx(true)
        self.BtnTab1:SetButtonState((self.BtnIndex == self.BtnIndexEnum.Action or self.BtnIndex == self.BtnIndexEnum.Paster) and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self.BtnTab2:SetButtonState((self.BtnIndex == self.BtnIndexEnum.Other or self.BtnIndex == self.BtnIndexEnum.Filter) and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        if self.IsPhotographed then
            self:RefreshPanelPaster()
        else
            self:RefreshPanelAction()
        end
    else
        self.Bg.gameObject:SetActiveEx(false)
        self.XUiPanelJoystick.GameObject:SetActiveEx(not self.IsPhotographed)
        self.BtnTab1.gameObject:SetActiveEx(false)
        self.BtnTab2.gameObject:SetActiveEx(false)
        self.BtnMenu.gameObject:SetActiveEx(not self.IsPhotographed)
        self.BtnPaster.gameObject:SetActiveEx(self.IsPhotographed)
        self.XUiPanelAction:OnSelected(false)
        self.XUiPanelSticker:OnSelected(false)
    end
end

function XUiFightCaptureV217:RefreshPanelAction()
    self.BtnTab1:SetNameByGroup(0, BtnActionName)
    self.BtnTab2:SetNameByGroup(0, BtnOtherName)
    self.BtnTab1:SetNameByGroup(1, BtnActionEnName)
    self.BtnTab2:SetNameByGroup(1, BtnOtherEnName)
    self.BtnMenu.gameObject:SetActiveEx(true)
    self.BtnPaster.gameObject:SetActiveEx(false)
    self.XUiPanelAction:OnSelected(true)
    self.XUiPanelSticker:OnSelected(false)
end

function XUiFightCaptureV217:RefreshPanelPaster()
    self.BtnTab1:SetNameByGroup(0, BtnPasterName)
    self.BtnTab2:SetNameByGroup(0, BtnFilterName)
    self.BtnTab1:SetNameByGroup(1, BtnPasterEnName)
    self.BtnTab2:SetNameByGroup(1, BtnFilterEnName)
    self.BtnMenu.gameObject:SetActiveEx(false)
    self.BtnPaster.gameObject:SetActiveEx(true)
    self.XUiPanelAction:OnSelected(false)
    self.XUiPanelSticker:OnSelected(true)
end


function XUiFightCaptureV217:OnBtnBlankClick(eventData)
    if eventData and eventData.button ~= CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        return
    end
    
    if self.IsPhotographed and not self.IsShowMenu then
        self:EndLeyPaster()
    end
end

function XUiFightCaptureV217:OnBtnTab1Click()
    self:OnBtnTabClick(self.IsPhotographed and self.BtnIndexEnum.Paster or self.BtnIndexEnum.Action)
end

function XUiFightCaptureV217:OnBtnTab2Click()
    self:OnBtnTabClick(self.IsPhotographed and self.BtnIndexEnum.Filter or self.BtnIndexEnum.Other)
end

function XUiFightCaptureV217:OnBtnTabClick(btnIndexEnum)
    self:EndLeyPaster()
    self:SetBtnIndex(btnIndexEnum)
    self:Refresh()
    self:PlayAnimation("Qiehuan")
end

function XUiFightCaptureV217:OnBtnMenuClick()
    self:SetIsShowMenu(not self.IsShowMenu)
    self:Refresh()
    self:PlayAnimation("BtnMenuSwitch")
end

local PhotographLock
function XUiFightCaptureV217:OnBtnPhotographClick()
    if PhotographLock or self.IsPhotographed then
        return
    end
    PhotographLock = true
    XCameraHelper.ScreenShotNew(self.ImagePhoto, CS.XRLManager.Camera.Camera, function(screenShot)
        -- 把合成后的图片渲染到游戏UI中的照片展示
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CsXUiManager.Instance.UiCamera)
        self.GameObject:SetActiveEx(true)
        self:SetIsPhotographed(true)
        self:SetBtnIndex(self.BtnIndexEnum.Paster)
        self:Refresh()
        PhotographLock = false
    end, function()
        self.GameObject:SetActiveEx(false)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XRLManager.Camera.Camera)
    end)
end

function XUiFightCaptureV217:OnBtnPhotoSaveClick()
    if not self.ImagePhotoCopy then
        local obj = XUiHelper.Instantiate(self.ImagePhoto.gameObject, self.ImagePhoto.transform.parent)
        self.ImagePhotoCopy = obj:GetComponent("Image")
    else
        self.ImagePhotoCopy.sprite = self.ImagePhoto.sprite
    end
    
    XCameraHelper.ScreenShotNew(self.ImagePhotoCopy, CsXUiManager.Instance.UiCamera, function(screenShot)
        -- 二次合成后的图片保存到本地
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CsXUiManager.Instance.UiCamera)
        self.ShareTexture = screenShot
        self.PhotoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
        XDataCenter.PhotographManager.SharePhotoBefore(self.PhotoName, self.ShareTexture, XPlatformShareConfigs.PlatformType.Local)
        self.ImagePhoto.gameObject:SetActiveEx(true)
        self.ImagePhotoCopy.gameObject:SetActiveEx(false)
        self.PanelRoot.gameObject:SetActiveEx(true)
    end, function()
        self:EndLeyPaster()
        self.PanelRoot.gameObject:SetActiveEx(false)
        self.ImagePhoto.gameObject:SetActiveEx(false)
        self.ImagePhotoCopy.gameObject:SetActiveEx(true)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CsXUiManager.Instance.UiCamera)
    end)
end

function XUiFightCaptureV217:OnBtnAgainClick()
    self.XUiPanelAction:PlayNpcAction()
end

function XUiFightCaptureV217:OnBtnStopClick()
    self._Control:StopNpcAnima()
end

-- 设置滤镜
--@params CaptureV217ScreenEffect配置表Id 
function XUiFightCaptureV217:SetScreenEffect(screenEffectId)
    local loader = self._Control:GetLoader()
    loader:UnloadAll()
    
    if screenEffectId == 0 then
        self:SetLutTex(nil)
        return
    end
    
    local path = self._Control._Model:GetScreenEffectPath(screenEffectId)
    self.LutTex = loader:Load(path)
    self:SetLutTex(self.LutTex)
end

function XUiFightCaptureV217:SetLutTex(texture)
    self.ImagePhotoLut:SetLutTex(texture)
    for _, gridPaster in ipairs(self.GridPasterList) do
        gridPaster:SetImageLut(texture)
    end
end

--region FOV
function XUiFightCaptureV217:OnSliderChanged(value)
    local params = self._Control._Model:GetCameraParams(self.CameraCfgId)
    if not params then
        return
    end
    local fovMin, fovMax = params[1], params[2]
    if not fovMin or not fovMax then
        return
    end

    local fov = value * (fovMax - fovMin) + fovMin
    self.OwnCamera:SetCustomFov(fov)
end

function XUiFightCaptureV217:OnBtnFovAddClick()
    self.Slider.value = math.min(1, self.Slider.value + 0.2)
end

function XUiFightCaptureV217:OnBtnFovReduceClick()
    self.Slider.value = math.max(0, self.Slider.value - 0.2)
end
--endregion

--region 放置贴纸
function XUiFightCaptureV217:CreateGridPaster(stickerId)
    table.insert(self.GridPasterList, self.GridPasterPool:Create(stickerId, self.LutTex))
end

---@field gridPaster XUiGridPaster
function XUiFightCaptureV217:RemoveGridPaster(gridPaster)
    for i, v in ipairs(self.GridPasterList) do
        if v == gridPaster then
            table.remove(self.GridPasterList, i)
            break
        end
    end
    self.GridPasterPool:Recycle(gridPaster)
end

function XUiFightCaptureV217:OnGridPasterCreate()
    local cell = XUiHelper.Instantiate(self.GridPaster, self.GridPaster.parent)
    return XUiGridPaster.New(cell, self)
end

-- 开始放置贴纸
function XUiFightCaptureV217:StartLeyPaster()
    self:SetIsShowMenu(false)
    self:RefreshMenu()
end

-- 结束放置贴纸
function XUiFightCaptureV217:EndLeyPaster()
    for _, gridPaster in ipairs(self.GridPasterList) do
        gridPaster:EndLeyPaster()
    end
end
--endregion

--region 变量赋值
function XUiFightCaptureV217:SetIsPhotographed(isPhotographed)
    self.IsPhotographed = isPhotographed
end

function XUiFightCaptureV217:SetBtnIndex(btnIndex)
    self.BtnIndex = btnIndex
end

function XUiFightCaptureV217:SetIsShowMenu(isShowMenu)
    self.IsShowMenu = isShowMenu
end
--endregion

--region PC操作
function XUiFightCaptureV217:AddPCKeyListener()
    self.OnPcClickCb = handler(self, self.OnPcClick)
    CSXInputManager.RegisterOnClick(CS.XInputManager.XOperationType.Capture, self.OnPcClickCb)

    self.CameraDirection = Vector2.zero
    self.KeyDownMap = {
        [PC_OPERATION_KEY.SPACE] = function(clickType)
            if clickType == CS.XOperationClickType.KeyDown then
                self:OnBtnPhotographClick()
            end
        end,
        [PC_OPERATION_KEY.W] = function(clickType)
            self:OnPcCameraClick(0, 1, clickType)
        end,
        [PC_OPERATION_KEY.S] = function(clickType)
            self:OnPcCameraClick(0, -1, clickType)
        end,
        [PC_OPERATION_KEY.A] = function(clickType)
            self:OnPcCameraClick(-1, 0, clickType)
        end,
        [PC_OPERATION_KEY.D] = function(clickType)
            self:OnPcCameraClick(1, 0, clickType)
        end,
        [PC_OPERATION_KEY.R] = function(clickType)
            if clickType == CS.XOperationClickType.KeyDown then
                self.CameraController:ResetCamera()
            end
        end,
        [PC_OPERATION_KEY.Mouse1] = function(clickType)
            if clickType == CS.XOperationClickType.KeyDown then
                self:OnBtnMenuClick()
            end
        end,
    }

    self.OnPcPressCb = handler(self, self.OnPcPress)
    self.KeyPressMap = {
        [PC_OPERATION_KEY.Q] = function()
            self.CameraController:SetTartAngle(Vector2(self.CameraController.TargetAngleX + 1, self.CameraController.TargetAngleY))
        end,
        [PC_OPERATION_KEY.E] = function()
            self.CameraController:SetTartAngle(Vector2(self.CameraController.TargetAngleX - 1, self.CameraController.TargetAngleY))
        end,
    }
    CSXInputManager.RegisterOnPress(CS.XInputManager.XOperationType.Capture, self.OnPcPressCb)
end

function XUiFightCaptureV217:RemovePCKeyListener()
    CSXInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.Capture, self.OnPcClickCb)
    CSXInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.Capture, self.OnPcPressCb)
end

function XUiFightCaptureV217:OnPcPress(inputDeviceType, operationKey, operationType)
    if operationType ~= CS.XInputManager.XOperationType.Capture then
        return
    end
    
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    
    local func = self.KeyPressMap[operationKey]
    if func then func() end
end

function XUiFightCaptureV217:OnPcCameraClick(x, y, clickType)
    if self.IsShowMenu then
        return
    end
    
    if clickType == CS.XOperationClickType.KeyDown then
        self.CameraDirection = self.CameraDirection + Vector2(x, y)
    elseif clickType == CS.XOperationClickType.KeyUp then
        self.CameraDirection = self.CameraDirection - Vector2(x, y)
    end

    self.CameraDirection.x = XMath.Clamp(self.CameraDirection.x, -1, 1)
    self.CameraDirection.y = XMath.Clamp(self.CameraDirection.y, -1, 1)
    self.CameraController:SetMoveVec(self.CameraDirection, CAMERA_MOVE_NORMALIZED_DIST)
    self.XUiPanelJoystick:RefreshArrowState(self.CameraDirection)
end

function XUiFightCaptureV217:OnPcClick(inputDeviceType, operationKey, clickType, operationType)
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local func = self.KeyDownMap[operationKey]
    if func then func(clickType) end
end

local Scroll
function XUiFightCaptureV217:Update()
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end

    Scroll = Input.GetAxis("Mouse ScrollWheel")
    if Scroll > 0 then
        self:OnBtnFovAddClick()
    elseif Scroll < 0 then
        self:OnBtnFovReduceClick()
    end
end
--endregion

function XUiFightCaptureV217:Close()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self.Super.Close(self)
end

return XUiFightCaptureV217