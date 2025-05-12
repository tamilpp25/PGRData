 
---@class XRestaurantPerform : XEntity 演出管理
---@field _Model XRestaurantModel
---@field _OwnControl XRestaurantControl
---@field _GameObject UnityEngine.GameObject
---@field _Actors table<number, XRestaurantPerformer>
local XRestaurantPerform = XClass(XEntity, "XRestaurantPerform")

local BehaviorState = {
    None = 0,
    Load = 1,
    FirstTrigger = 2,
    MultipleTrigger = 3,
    Exit = 4,
}

local PerformState2BehaviorState = {
    [XMVCA.XRestaurant.PerformState.NotStart] = BehaviorState.FirstTrigger,
    [XMVCA.XRestaurant.PerformState.OnGoing] = BehaviorState.MultipleTrigger,
    [XMVCA.XRestaurant.PerformState.Finish] = BehaviorState.Exit,
}

function XRestaurantPerform:OnInit()
    --处于演出中
    self._IsInPerform = false
    --舞台的演员
    self._Actors = {}
    --舞台的物品
    self._Furniture = {}
    
    self._FurniturePath = {}
end

function XRestaurantPerform:SetGameObject(obj)
    if XTool.UObjIsNil(obj) then
        XLog.Error("演出舞台为空!!!")
        return
    end
    self._GameObject = obj
    self._Transform = obj.transform
    --添加行为树代理
    local typeStr = typeof(CS.BehaviorTree.XAgent)
    local agent = self._GameObject:GetComponent(typeStr)
    if not agent then
        agent = self._GameObject:AddComponent(typeStr)
        agent.ProxyType = "RestaurantPerform"
        agent:InitProxy()
    end
    agent.Proxy.LuaAgentProxy:SetPerform(self)
    self._Agent = agent
end

--演出开始
function XRestaurantPerform:StartPerformance(performanceId)
    --演出中，不能打断上次的演出
    if self._IsInPerform then
        return
    end
    self._IsInPerform = true
    self._PerformanceId = performanceId
    self:ChangeState(BehaviorState.Load)
end

--演出谢幕
function XRestaurantPerform:StopPerformance()
    --演出未开始
    if not self._IsInPerform then
        return
    end
    local perform = self._OwnControl:GetPerform(self._PerformanceId)
    perform:ClearBind(self._GameObject:GetHashCode())
    self:ChangeState(BehaviorState.Exit)
end

-- 所有道具加载完毕，开始演出
function XRestaurantPerform:DoBegin()
    if not XTool.IsNumberValid(self._PerformanceId) then
        return
    end
    local perform = self._OwnControl:GetPerform(self._PerformanceId)
    perform:BindViewModelPropertyToObj(self._GameObject:GetHashCode(), perform.Property.State, function(state)
        self:OnPerformStateChanged(state)
    end)
end

--- 加载演员
---@param performerId number
---@param position UnityEngine.Vector3 位置
---@param rotation UnityEngine.Vector3 旋转
--------------------------
function XRestaurantPerform:LoadActor(performerId, position, rotation, loadCb)
    local performer = self._Actors[performerId]
    if not performer then
        performer = self._OwnControl:GetRoom():LoadPerformer(performerId)
        self._Actors[performerId] = performer
    end
    performer:SetTransform(position.x, position.y, position.z, rotation.x, rotation.y, rotation.z)
    performer:Born(loadCb)
end

--- 加载演出道具
---@param performerId number
---@param position UnityEngine.Vector3 位置
---@param rotation UnityEngine.Vector3 旋转
--------------------------
function XRestaurantPerform:LoadFurniture(performerId, position, rotation, loadCb)
    local url = self._Model:GetNpcModelUrl(self._Model:GetPerformerNpcId(performerId))
    local loader = self._OwnControl:GetLoader()
    local asset = loader:Load(url)
    if not asset then
        XLog.Error("加载演出道具异常! 路径 = " .. url)
        return
    end
    if not self._FurniturePath[performerId] then
        self._FurniturePath[performerId] = {}
    end
    
    local obj = self._OwnControl:GetRoom():LoadPerformProps(asset)
    if not obj then
        return
    end
    obj.name = string.format("@F-%s", performerId)
    obj.transform.position = position
    obj.transform.rotation = CS.UnityEngine.Quaternion.Euler(rotation)
    if not self._Furniture[performerId] then
        self._Furniture[performerId] = {}
    end
    local insId = obj.gameObject:GetInstanceID()
    self._Furniture[performerId][insId] = obj
    self._FurniturePath[performerId][insId] = url
    if loadCb then loadCb() end
end

function XRestaurantPerform:OnPerformStateChanged(state)
    local behaviorState = PerformState2BehaviorState[state]
    if not behaviorState then
        return
    end

    --推出状态由协议调用
    if behaviorState == BehaviorState.Exit then
        return
    end
    self:ChangeState(behaviorState)
end

function XRestaurantPerform:ChangeState(state)
    if state == BehaviorState.None then
        return
    end
    self._State = state
    local behaviorId = self._Model:GetPerformBehaviourId(self._PerformanceId, state)
    if not string.IsNilOrEmpty(behaviorId) then
        XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
    end
    for _, actor in pairs(self._Actors) do
        actor:ChangeState(state)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
end

function XRestaurantPerform:IsValid()
    return self._State ~= BehaviorState.Exit and self._State ~= BehaviorState.None
end

function XRestaurantPerform:DoBubble(npcId, dialogId, index)
    local performer = self._Actors[npcId]
    if not performer then
        XLog.Error("不存在NpcId = " .. npcId .. "的演出角色")
        return
    end
    performer:SetBubbleTextList(dialogId)
    performer:DoBubble(index)
end

function XRestaurantPerform:DoHideBubble(npcId)
    local performer = self._Actors[npcId]
    if not performer then
        XLog.Error("不存在NpcId = " .. npcId .. "的演出角色")
        return
    end
    performer:DoHideBubble()
end

function XRestaurantPerform:DoDestroyProps(npcId)
    --移除演员
    self:RemoveActor(npcId)
    --移除家具
    local furnitureDict = self._Furniture[npcId] or {}
    for _, furniture in pairs(furnitureDict) do
        if furniture and not XTool.UObjIsNil(furniture.gameObject) then
            CS.UnityEngine.Object.Destroy(furniture.gameObject)
        end
    end
    local urlList = self._FurniturePath[npcId]
    if not XTool.IsTableEmpty(urlList) then
        local loader = self._OwnControl:GetLoader()
        for _, url in pairs(urlList) do
            loader:Unload(url)
        end
    end
end

function XRestaurantPerform:IsEqualState(state)
    if not XTool.IsNumberValid(self._PerformanceId) then
        return false
    end
    
    local perform = self._OwnControl:GetPerform(self._PerformanceId)
    local behaviorState = PerformState2BehaviorState[perform:GetState()]
    return behaviorState == state
end

function XRestaurantPerform:DestroyAllProps(isBehavior)
    for _, actor in pairs(self._Actors) do
        actor:Release()
    end
    for _, furnitureDict in pairs(self._Furniture) do
        for _, furniture in pairs(furnitureDict) do
            if furniture and not XTool.UObjIsNil(furniture.gameObject) then
                CS.UnityEngine.Object.Destroy(furniture.gameObject)
            end
        end
    end
    local loader = self._OwnControl:GetLoader()
    for _, urlList in pairs(self._FurniturePath) do
        for _, url in pairs(urlList) do
            loader:Unload(url)
        end
    end
    self._IsInPerform = false
    self._Actors = {}
    self._Furniture = {}
    self._FurniturePath = {}
    if isBehavior then
        self._OwnControl:GetRoom():PlayPerformance()
    end
end

function XRestaurantPerform:OnRelease()
    self:DestroyAllProps(false)
end

function XRestaurantPerform:Release()
    
end

function XRestaurantPerform:GetTransform()
    return self._Transform
end

function XRestaurantPerform:RemoveActor(performerId)
    local performer = self._Actors[performerId]
    if not performer then
        return
    end
    self._Actors[performerId] = nil
    performer:DisposeImmediately()
end

function XRestaurantPerform:GetRunningNpcDict()
    return self._Actors
end

return XRestaurantPerform