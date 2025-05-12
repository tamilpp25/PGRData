--- 附带猎锚勾点的塔
local XSObjTower2 = XDlcScriptManager.RegSceneObjScript(0005, "XSObjTower2") --调用使用冒号
local Property = require("Level/Common/SceneObjectsProperty").Tower

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjTower2:Ctor(proxy)
    self._proxy = proxy

    self._raised = false
    self._raising = false

    --延时计时器
    self._timer = {
        tasks = {},
        incId = 0
    }

    self._towerDataInstance = {}

    self._waitToDo = false

    self._initialized = false ---是否执行塔的初始化
end

function XSObjTower2:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()
    --self._sceneObjUUId = self._proxy:GetSceneObjectUUID(self._sceneObjPlaceId)
    --self._proxy:RegisterSceneObjectMoveEvent(self._sceneObjPlaceId, 2)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
end

---本地储存一份数据实例
function XSObjTower2:InitState(data)
    self._towerDataInstance = data
    self._raised = data.defaultRaise
    if data.defaultAnchorEnable ~= nil then
        self:HookableEnable(data.defaultAnchorEnable)
    else
        self:HookableEnable(true)
    end
    self._initialized = true
end

---塔行动
function XSObjTower2:TowerMove(rise)
    --XLog.Debug(tostring(rise)..tostring(self._raised)..tostring(rise == self._raised))
    if self._raising then
        --运动过程中收到指令会令运动结束以后立刻执行相反运动，或者取消这个命令
        if rise == self._raised then
            --指令目标和当前运动目标相同，则取消命令
            self._waitToDo = false
            XLog.Debug("塔" .. tostring(self._sceneObjPlaceId) .. "运行中收到指令，和当前目标一致")
        else
            --指令目标和当前运动目标相反，则记录一个命令
            self._waitToDo = true
            XLog.Debug("塔" .. tostring(self._sceneObjPlaceId) .. "运行中收到指令，和当前目标相反")
        end
        return
    elseif rise == self._raised then
        return
    end

    self._sceneObj.MoveComponent:MoveToNode()
    self:HookableEnable(false)

    if self._towerDataInstance.effectPlayer ~= nil then
        -- 还应该判断此物体是否存在、active
        self._proxy:DoSceneObjectAction(self._towerDataInstance.effectPlayer, Property.Actions[self._towerDataInstance.type].Open)
    end

    self._raised = rise
    self._raising = true

    local towerName = "塔" .. tostring(self._sceneObjPlaceId)
    local actionName = rise == true and "升起" or "降下"
    --print(towerName .. actionName .. tostring(self._raised))
end

---设置塔勾点开关
function XSObjTower2:HookableEnable(enable)
    if self._raised then
        self._proxy:SetHookableSceneObjectEnable(self._sceneObjPlaceId, enable)
        --print("设定塔" .. self._sceneObjPlaceId .. "可勾取状态为" .. tostring(enable))
    else
        self._proxy:SetHookableSceneObjectEnable(self._sceneObjPlaceId, false)
        --print("关闭塔" .. self._sceneObjPlaceId .. "可勾取状态")
    end
end

---@param dt number @ delta time
function XSObjTower2:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XSObjTower2:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.SceneObjectMoveStop then
        if eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.MoveState == 2 then
            self._raising = false

            if self._waitToDo then
                self:TowerMove(not self._raised)
                self._waitToDo = false
            else
                if self._towerDataInstance.effectPlayer ~= nil then
                    -- 还应该判断此物体是否存在、active
                    self._proxy:DoSceneObjectAction(self._towerDataInstance.effectPlayer, Property.Actions[self._towerDataInstance.type].Close)
                end

                if self._raised then
                    self:HookableEnable(true)
                end
            end
        end
    end
end

function XSObjTower2:OnResLoadComplete()
    if not self._initialized then
        self:HookableEnable(true)
    end
end

function XSObjTower2:Terminate()
end

return XSObjTower2