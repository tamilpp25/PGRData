CsXBehaviorManager = CS.BehaviorTree.XBehaviorTreeManager
CsNodeStatus = CS.BehaviorTree.XNodeStatus
CsBehaviorNodeType = CS.BehaviorTree.XBehaviorNodeType

XLuaBehaviorManager = {}

local NodeClassType = {}
local AgentClassType = {}

--- 注册行为节点
---@param super XLuaBehaviorNode 父节点
---@param classType string 节点类型名
---@param nodeType number 节点类型
---@param isLua boolean 是否为Lua节点
---@param needUpdate boolean 是否需要Update函数
---@return XLuaBehaviorNode
--------------------------
function XLuaBehaviorManager.RegisterNode(super, classType, nodeType, isLua, needUpdate)
    super = XLuaBehaviorNode or super
    CsXBehaviorManager.Instance:RegisterLuaNodeProxy(classType, nodeType, isLua, needUpdate)
    local behaviorNode = XClass(super, classType)
    NodeClassType[classType] = behaviorNode
    return behaviorNode
end

--创建行为节点实例
function XLuaBehaviorManager.NewLuaNodeProxy(className, nodeProxy)
    local baseName = className
    local class = NodeClassType[baseName]
    if not class then
        class = NodeClassType[baseName]
        if not class then
            XLog.Error("XLuaBehaviorManager.NewLuaNodeProxy error, class not exist, name: " .. className)
            return nil
        end
    end
    local obj = class.New(className, nodeProxy)
    return obj
end

--- 注册行为主体
---@param super XLuaBehaviorAgent 父行为
---@param classType string 类名
---@return XLuaBehaviorAgent
--------------------------
function XLuaBehaviorManager.RegisterAgent(super, classType)
    super = XLuaBehaviorAgent or super
    CsXBehaviorManager.Instance:RegisterLuaAgentProxy(classType)
    local behaviorNode = XClass(super, classType)
    AgentClassType[classType] = behaviorNode
    return behaviorNode
end

--创建行为主体实例
function XLuaBehaviorManager.NewLuaAgentProxy(className, agentProxy)
    local baseName = className
    local class = AgentClassType[baseName]
    if not class then
        class = AgentClassType[baseName]
        if not class then
            XLog.Error("XLuaBehaviorManager.NewLuaAgentProxy error, class not exist, name: " .. className)
            return nil
        end
    end
    local obj = class.New(className, agentProxy)
    return obj
end


function XLuaBehaviorManager.PlayId(id, agent)
    agent:PlayBehavior(id)
end