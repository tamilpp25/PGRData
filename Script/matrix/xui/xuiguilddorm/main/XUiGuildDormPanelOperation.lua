local XGuildDormHelper = CS.XGuildDormHelper
local Vector2 = CS.UnityEngine.Vector2
local XUiJoystick = XClass(nil, "XUiJoystick")

function XUiJoystick:Ctor(gameObject)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    XTool.InitUiObject(self)
    -- 遥杆范围
    self.JoystickTouchRange = 120
    -- 原始坐标
    self.OriginalPos = self.BackdragTouch.anchoredPosition
    self.TriggerThresholdSqr = 0
    self.Ratio = 4
    self.IsStart = false
    -- 注册事件
    self:_RegisterUiEvents()
    -- 移动方向更新方法
    self.UpdateMoveDirectionFunc = nil
end

function XUiJoystick:SetData(updateMoveDirectionFunc)
    self.UpdateMoveDirectionFunc = updateMoveDirectionFunc
end

--######################## 私有方法 ########################

function XUiJoystick:_RegisterUiEvents()
    -- 注册遥杆事件
    local uiWeight = self.JoystickScope.gameObject:AddComponent(typeof(CS.XUiWidget))
    uiWeight:AddPointerDownListener(function(eventData)
        self:_OnPointerDown(eventData)
    end)
    uiWeight:AddPointerUpListener(function(eventData)
        self:_OnPointerUp(eventData)
    end)
    uiWeight:AddDragListener(function(eventData)
        self:_OnDrag(eventData)
    end)
    self.EvtIndex = CS.XCommonGenericEventManager.RegisterLuaEvent(XEventId.EVENT_ALTER_LEFT_STICK_EVENT, function(evtId, arg) 
        local vector3 = arg.Vector
        self.UpdateMoveDirectionFunc(vector3.x, vector3.y)
        XGuildDormHelper.SetTouchButton(self.TouchButton, vector3, self.JoystickTouchRange)
    end)
end

function XUiJoystick:_OnPointerDown(eventData)
    if XGuildDormHelper.CheckCanDrag(self.BackdragTouch
        , eventData, self.Ratio, self.TriggerThresholdSqr) then
        local directionIndex = XGuildDormHelper.UpdateTouchButton(self.BackdragTouch, self.TouchButton, eventData, self.JoystickTouchRange)
        local x, y = self:_Index2Direction(directionIndex)
        self.UpdateMoveDirectionFunc(x, y)
    end
    self.IsStart = true
end

function XUiJoystick:_OnPointerUp(eventData)
    XGuildDormHelper.JoystickPointerUp(self.BackdragTouch, self.TouchButton, self.OriginalPos)
    self.IsStart = false
    self.UpdateMoveDirectionFunc(0, 0)
end

function XUiJoystick:_OnDrag(eventData)
    if not self.IsStart then return end
    if XGuildDormHelper.CheckCanDrag(self.BackdragTouch
        , eventData, self.Ratio, self.TriggerThresholdSqr) then
        local directionIndex = XGuildDormHelper.UpdateTouchButton(self.BackdragTouch, self.TouchButton, eventData, self.JoystickTouchRange)
        local x, y = self:_Index2Direction(directionIndex)
        self.UpdateMoveDirectionFunc(x, y)
    end
end

function XUiJoystick:_Index2Direction(index)
    local radian = XGuildDormHelper.PI_TIMES2 * index / XGuildDormHelper.DIR_SPLIT_COUNT
    return math.sin(radian), math.cos(radian)
end

function XUiJoystick:Reset()
    if self.IsStart then
        XGuildDormHelper.JoystickPointerUp(self.BackdragTouch, self.TouchButton, self.OriginalPos)
        self.UpdateMoveDirectionFunc(0, 0)
        self.IsStart = false
    end
end

function XUiJoystick:OnDestroy()
    CS.XCommonGenericEventManager.RemoveLuaEvent(XEventId.EVENT_ALTER_LEFT_STICK_EVENT, self.EvtIndex)
end


-- ###################################### XUiGuildDormPanelOperation ######################################
local UiButtonState = CS.UiButtonState
local XUiCommonJoystick = require("XUi/XUiCommon/XUiCommonJoystick")
local XUiGuildDormPanelOperation = XClass(nil, "XUiGuildDormPanelOperation")

function XUiGuildDormPanelOperation:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.UiJoystick = XUiJoystick.New(self.PanelJoystick.gameObject)
    self.Role = nil
    self.Room = nil
    self:RegisterUiEvents()
end

function XUiGuildDormPanelOperation:SetData() 
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.Role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
    self.Room = currentRoom
    self.InputComponent = self.Role:GetComponent("XGDInputCompoent")
    local interactCheckComponent = self.Role:GetComponent("XGDInteractCheckComponent")
    local signalData = interactCheckComponent:GetSignalData()
    signalData:ConnectSignal("InteractChanged", self, self.OnInteractChanged)
    self.UiJoystick:SetData(handler(self, self.HandleMoveDirection))
end

function XUiGuildDormPanelOperation:HandleMoveDirection(x, y)
    self.InputComponent:UpdateMoveDirection(x, y)
end

function XUiGuildDormPanelOperation:SetIsCanMove(value)
    self.InputComponent:SetIsCanMove(value)
end

function XUiGuildDormPanelOperation:OnStart()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_CANCEL_INTERACT_BTN_SHOW, self.OnCancelInteractBtnShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_BEGIN, self.OnRoleBeginInteract, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_STOP, self.OnRoleStopInteract, self)
end

function XUiGuildDormPanelOperation:OnEnable()
    self:SetData()
    self:SetIsCanMove(true)
end

function XUiGuildDormPanelOperation:OnDisable()
    self:SetIsCanMove(false)
end

function XUiGuildDormPanelOperation:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_CANCEL_INTERACT_BTN_SHOW, self.OnCancelInteractBtnShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_BEGIN, self.OnRoleBeginInteract, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_STOP, self.OnRoleStopInteract, self)
    self.UiJoystick:OnDestroy()
end

function XUiGuildDormPanelOperation:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnInteract, self.OnBtnInteractClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCancelInteract, self.OnBtnCancelInteractClicked)
end

function XUiGuildDormPanelOperation:OnRoleBeginInteract(playerId)
    if playerId ~= XPlayer.Id then return end
    self.PanelJoystick.gameObject:SetActiveEx(false)
    self:OnInteractChanged(false, playerId)
end

function XUiGuildDormPanelOperation:OnRoleStopInteract(playerId)
    if playerId ~= XPlayer.Id then return end
    self.PanelJoystick.gameObject:SetActiveEx(true)
    self:OnInteractChanged(false, playerId)
    self:OnCancelInteractBtnShow(false, playerId)
end

function XUiGuildDormPanelOperation:OnCancelInteractBtnShow(value, playerId)
    if playerId ~= XPlayer.Id then return end
    self.BtnCancelInteract.gameObject:SetActiveEx(value)
end

function XUiGuildDormPanelOperation:OnBtnInteractClicked()
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if currentInteractInfo == nil then return end
    if currentInteractInfo.ButtonType == XGuildDormConfig.FurnitureButtonType.SkipFunction then
        XFunctionManager.SkipInterface(tonumber(currentInteractInfo.ButtonArg))
        return
    end
    -- 该家具已经被占用
    if self.Room:GetRoleByFurnitureId(currentInteractInfo.Id) then
        return
    end
    XDataCenter.GuildDormManager.RequestFurnitureInteract(currentInteractInfo.Id)
end

function XUiGuildDormPanelOperation:OnBtnCancelInteractClicked()
    if self.Role:GetInteractStatus() == XGuildDormConfig.InteractStatus.Playing then
        XDataCenter.GuildDormManager.RequestFurnitureInteract(-1, function()
            self.BtnCancelInteract.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiGuildDormPanelOperation:OnInteractChanged(value, playerId)
    if playerId ~= XPlayer.Id then return end
    if XTool.UObjIsNil(self.GameObject) then return end
    -- 禁止重复设置，避免lua gc
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if self.__LastInteractValue == nil or self.__LastInteractValue ~= value then
        self.__LastInteractValue = value
        self.BtnInteract.gameObject:SetActiveEx(value)
        if currentInteractInfo == nil then
            self.BtnInteract.gameObject:SetActiveEx(false)
            return
        end
    end
    if value and currentInteractInfo then
        self.__CurrentDiableValue = self.Room:GetRoleByFurnitureId(currentInteractInfo.Id) ~= nil
        if self.__LastIsDiableValue == nil or self.__LastIsDiableValue ~= self.__CurrentDiableValue then
            self.__LastIsDiableValue = self.__CurrentDiableValue
            self.BtnInteract:SetDisable(self.__CurrentDiableValue)
        end
        self.__CurrentInteractInfoId = currentInteractInfo.Id
        if self.__LastInteractInfoId == nil or self.__LastInteractInfoId ~= self.__CurrentInteractInfoId then
            self.__LastInteractInfoId = self.__CurrentInteractInfoId
            if string.IsNilOrEmpty(currentInteractInfo.ShowButtonName) then
                self.BtnInteract:SetNameByGroup(0, XUiHelper.GetText("GuildDormDefaultInteractButtonText"))
            else
                self.BtnInteract:SetNameByGroup(0, currentInteractInfo.ShowButtonName)
            end
        end
    end
end

return XUiGuildDormPanelOperation