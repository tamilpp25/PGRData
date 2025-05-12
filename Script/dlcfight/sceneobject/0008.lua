--- 锚点
local XSObjAnchor = XDlcScriptManager.RegSceneObjScript(0008, "XSObjAnchor") --调用使用冒号
local Property = require("Level/Common/SceneObjectsProperty").Anchor

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjAnchor:Ctor(proxy)
    self._proxy = proxy

    self._enable = nil
    self.EnableOnStart = true ---默认设置为开

    self._type = nil ---23凸 24平

    self._initialized = false ---是否执行开关的初始化
end

function XSObjAnchor:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()
end

---@param dt number @ delta time
function XSObjAnchor:Update(dt)

end

---设置猎矛是否启用，在关卡初始化的时候调用InitState
---@param enable boolean
function XSObjAnchor:SetEnable(enable)
    if enable == nil then
        return
    end

    if enable ~= self._enable then
        XLog.Debug("设置猎锚勾点" .. self._sceneObjPlaceId .. "状态为：" .. tostring(enable))
        self._proxy:SetHookableSceneObjectEnable(self._sceneObjPlaceId, enable)
        self._enable = enable

        --表现相关
        if self._type ~= nil then
            if enable then
                self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Open)
            else
                self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, Property.Actions[self._type].Close)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XSObjAnchor:HandleEvent(eventType, eventArgs)
    XSObjAnchor.Super.HandleEvent(self, eventType, eventArgs)
end

---初始化状态，设置猎锚勾点种类，确保播放特效类别正确
function XSObjAnchor:InitState(type, enable)
    self._type = type
    XLog.Debug("注册场景物体勾点 " .. tostring(self._sceneObjPlaceId) .. " 类型为 " .. tostring(type) .. "完成")

    self:SetEnable(enable)
    self._initialized = true
end

function XSObjAnchor:Terminate()

end

---如果关卡脚本没有挂初始化，就自己执行一次
function XSObjAnchor:OnResLoadComplete()
    if not self._initialized then
        self:SetEnable(self.EnableOnStart)
        self._initialized = true
    end
end

return XSObjAnchor
