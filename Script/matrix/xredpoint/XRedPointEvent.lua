--[[--红点事件个体类
RedPointEvent.id 唯一Id
RedPointEvent.conditionGroup  类型 XRedPointConditionGroup
RedPointEvent.listener  类型 XRedPointListener
RedPointEvent.node 持有的节点用于判断释放
]]
--
---@class XRedPointEvent 红点事件个体类
---@field
local XRedPointEvent = XClass(nil, "XRedPointEvent")
---@type XObjectPool
local RedPointConditionGroupPool
---@type XObjectPool
local RedPointListenerPool

local IsWindowsEditor = XMain.IsWindowsEditor

local EventHandler = function(method, eventId)
    return function(obj, ...)
        return method(obj, eventId, ...)
    end
end

--构造
function XRedPointEvent:Ctor()
end

function XRedPointEvent:Init(id, node, conditionGroup, listener, func, args)
    self.EventListener = {}
    self.id = id
    self.condition = RedPointConditionGroupPool:Create(conditionGroup)
    self.listener = RedPointListenerPool:Create(listener, func)
    self.node = node
    self.args = args
    self:AddConditionsChangeEvent()

    self.checkExist = nil

    if node.Exist then
        self.checkExist = function() return node:Exist() end
        self:GetNodeHierarchyPath(node)
    else
        local gameObject = node.GameObject or node.gameObject or node.Transform or node.transform
        if gameObject and gameObject.Exist then
            self.checkExist = function() return gameObject:Exist() end
            self:GetNodeHierarchyPath(gameObject)
        end
    end
end

function XRedPointEvent:GetNodeHierarchyPath(go)
    if IsWindowsEditor then
        if go.transform then
            self.nodePath = CS.XUnityEx.GetPath(go.transform)
        end
    end
end

--检测红点条件
function XRedPointEvent:Check(args)

    if not self:CheckNode() then
        self:Release()
        return
    end

    if self.condition then
        --如果条件参数改变，则替换
        if args then
            self.args = args
        end

        --条件检测
        local result = self.condition:Check(self.args)

        --回调
        if self.listener then
            if self.listener.func then
                self.listener:Call(result, self.args)
            else
                self.node.gameObject:SetActive(result >= 0)
            end
        end
    end
end

--添加事件監聽
function XRedPointEvent:AddConditionsChangeEvent()
    if not self.condition then
        return
    end

    local events = self.condition.Events

    if not events then
        return
    end
    
    for _, var in pairs(events) do
        local func = EventHandler(self.OnConditionChange, var.EventId)
        XEventManager.AddEventListener(var.EventId, func, self)
        self.EventListener[var.EventId] = func
    end
end

--删除事件監聽
function XRedPointEvent:RemoveConditionsChangeEvent()
    if not self.condition then
        return
    end

    local events = self.condition.Events

    if not events then
        return
    end

    for _, var in pairs(events) do
        local func = self.EventListener[var.EventId]
        if func then
            XEventManager.RemoveEventListener(var.EventId, func, self)
        end
        self.EventListener[var.EventId] = nil
    end
end

--条件改变事件回调
function XRedPointEvent:OnConditionChange(eventId, args)

    -- 分析参数
    if self.condition and self.condition.Events and self.condition.Events[eventId] then
        local element = self.condition.Events[eventId]
        if element:Equal(eventId, args) then
            self:Check()
            return
        end
    end

    if self.args == nil or args == nil then
        self:Check(args)
    elseif self.args == args and args ~= nil then
        self:Check(args)
    end
end

--检测是否已经被释放
function XRedPointEvent:CheckNode()
    if self.checkExist == nil then
        return false
    end

    if not self.checkExist() then
        if IsWindowsEditor then
            if self.nodePath then
                XLog.Error("红点检测节点已被销毁, 请检查是否有移除红点事件:" .. self.nodePath)
            end
        end
        return false
    end

    return true
end

--释放
function XRedPointEvent:Release()
    self:RemoveConditionsChangeEvent()
    self.checkExist = nil
    if self.listener then
        self.listener:Release()
        RedPointListenerPool:Recycle(self.listener)
        self.listener = nil
    end
    self.node = nil
    self.nodePath = nil
    if self.condition then
        self.condition:Release()
        RedPointConditionGroupPool:Recycle(self.condition)
        self.condition = nil
    end
    XRedPointManager.RemoveRedPointEventOnly(self.id)

    for eventId, func in pairs(self.EventListener or {}) do
        XEventManager.RemoveEventListener(eventId, func, self)
    end
end

--导入时调用一次
local function OnRequire()
    if not RedPointConditionGroupPool then
        RedPointConditionGroupPool = XObjectPool.New(XRedPointConditionGroup.New)
    end
    if not RedPointListenerPool then
        RedPointListenerPool = XObjectPool.New(XRedPointListener.New)
    end
end
OnRequire()

return XRedPointEvent