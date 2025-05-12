--- 开关
local XSObjSwitch = XDlcScriptManager.RegSceneObjScript(0007, "XSObjSwitch") --调用使用冒号
local Property = require("Level/Common/SceneObjectsProperty").Switch

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjSwitch:Ctor(proxy)
    self._proxy = proxy
    ---触发事件
    self._triggerHandler = {
        func = nil,
        param = nil,
        executeTimes = 0
    }
    self._options = {}

    self.EnableOnStart = true
    self._enable = nil

    self._type = 22

    self._coolDownCount = 0

    self._latestAction = nil

    self._initialized = false ---是否执行开关的初始化
end

function XSObjSwitch:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()
    --self._proxy:RegisterSceneObjectTriggerEvent(self._sceneObjPlaceId, 1)
    --self._proxy:RegisterSceneObjectEvent(EWorldEvent.SceneObjectActionFinish, self._sceneObjPlaceId)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectActionFinish)
end

---@param dt number @ delta time
function XSObjSwitch:Update(dt)
    if not self._initialized then
        return
    end

    if self._enable == false and self._options.autoReboot and
            not (self._options.triggerTimes > 0
                    and self._triggerHandler.executeTimes >= self._options.triggerTimes
            )
    then
        if self._coolDownCount >= self._options.autoRebootCoolDown then
            -- reboot
            self:SetEnable(true)
            self._coolDownCount = 0
        end
        self._coolDownCount = self._coolDownCount + dt
    end
end

---设置开关是否启用
---@param enable boolean @ 如果不输入，则根据self._enable来切换
function XSObjSwitch:SetEnable(enable)
    if enable == nil then
        return false
    end

    if self._latestAction ~= nil then
        --避免动画中硬切
        return false
    end

    --表现相关
    if enable ~= self._enable then
        XLog.Debug("<color=#082E54>[SceneObject]</color>设置开关" .. self._sceneObjPlaceId .. "状态为：" .. tostring(enable))
        self._enable = enable

        --表现相关
        if enable then
            self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Open)
            self._latestAction = Property.Actions[self._type].Open
        else
            self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Close)
            self._latestAction = Property.Actions[self._type].Close
        end
    end

end

---注册触发事件
---@param object table @ 触发事件的表
---@param func function @ 触发的事件
---@param param @ 传入的参数
function XSObjSwitch:SetTriggerHandler(object, func, param)
    self._triggerHandler.object = object
    self._triggerHandler.func = func
    self._triggerHandler.param = param
    XLog.Debug("<color=#082E54>[SceneObject]</color>注册开关" .. tostring(self._sceneObjPlaceId) .. " 事件成功:"
            .. " eventFunc " .. tostring(func)
            .. " param " .. tostring(param)
    )
end

---注销触发事件
function XSObjSwitch:DeleteTriggerHandler()
    self._triggerHandler.func = nil
end

---被触发
function XSObjSwitch:OnTrigger()
    if self._options.triggerTimes > 0 and self._triggerHandler.executeTimes >= self._options.triggerTimes then
        return
    end

    if self._triggerHandler.func == nil then
        XLog.Debug("<color=#082E54>[SceneObject]</color>触发失败，开关" .. tostring(self._sceneObjPlaceId) .. "未注册事件！")
        return
    end

    self._triggerHandler.func(self._triggerHandler.object, self._triggerHandler.param)
    self._triggerHandler.executeTimes = self._triggerHandler.executeTimes + 1

    XLog.Debug("<color=#082E54>[SceneObject]</color> 开关" .. tostring(self._sceneObjPlaceId)
            .. "注册事件触发成功，剩余触发次数：" .. tostring(self._options.triggerTimes > 0 and (self._options.triggerTimes - self._triggerHandler.executeTimes) or "无限")
    )

    self._latestAction = Property.Actions[self._type].Trigger
    self._enable = false

    self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Trigger)

end

---@param eventType number
---@param eventArgs userdata
function XSObjSwitch:HandleEvent(eventType, eventArgs)
    XSObjSwitch.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerId == 1 then
        --XLog.Debug("<color=#082E54>[SceneObject]</color>XSObjSwitch SceneObjectTriggerEvent:"
        --        .. " TouchType " .. tostring(eventArgs.TouchType)
        --        .. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
        --        .. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
        --        .. " TriggerId " .. tostring(eventArgs.TriggerId)
        --        .. " TriggerState " .. tostring(eventArgs.TriggerState)
        --        .. " Log自开关" .. tostring(self._sceneObjPlaceId)
        --)

        --可能需要加一下是玩家触发的判断
        if self._enable then
            self:OnTrigger()
        end
    elseif eventType == EWorldEvent.SceneObjectActionFinish then
        XLog.Debug("<color=#082E54>[SceneObject]</color>场景物体动作结束：" .. tostring(eventArgs.SceneObjectId) .. " " .. tostring(eventArgs.ActionId))
        if eventArgs.SceneObjectId == self.SceneObjectId then
            self._latestAction = nil
            if eventArgs.ActionId == Property.Actions[self._type].Open then
                XLog.Debug("<color=#082E54>[SceneObject]</color>开关开启动作执行完毕")
                self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].OpenIdle)
            end
        end
    end
end

---初始化状态，设置开关初始状态
function XSObjSwitch:InitState(enable)
    if enable == nil then
        enable = Property.Options.defaultOnEnable
    end
    self._enable = enable
    if enable then
        self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].OpenIdle)
    else
        self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Close)
    end
    self._initialized = true
end

---设置开关配置数据，数据为空则不更改默认配置
function XSObjSwitch:SetOptions(autoReboot, autoRebootCoolDown, triggerTimes)
    if autoReboot ~= nil then
        self._options.autoReboot = autoReboot
    else
        self._options.autoReboot = Property.Options.autoReboot
    end
    if autoRebootCoolDown ~= nil then
        self._options.autoRebootCoolDown = autoRebootCoolDown
    else
        self._options.autoRebootCoolDown = Property.Options.autoRebootCoolDown
    end
    if triggerTimes ~= nil then
        self._options.triggerTimes = triggerTimes
        self._triggerHandler.executeTimes = 0
    else
        self._options.triggerTimes = Property.Options.triggerTimes
    end
end

function XSObjSwitch:Terminate()

end

function XSObjSwitch:OnResLoadComplete()
    if not self._initialized then
        self:InitState(self.EnableOnStart)
        self:SetOptions()
        self._initialized = true
    end
end

return XSObjSwitch
