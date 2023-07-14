local XRLGuildDormRole = require("XEntity/XGuildDorm/Role/XRLGuildDormRole")
local XGuildDormRoleFSMFactory = require("XEntity/XGuildDorm/Role/FSM/XGuildDormRoleFSMFactory")
local XGDComponentManager = require("XEntity/XGuildDorm/Base/XGDComponentManager")
---@class XGuildDormBaseRole
local XGuildDormBaseRole = XClass(nil, "XGuildDormBaseRole")

function XGuildDormBaseRole:Ctor(id)
    self.Id = id
    -- 角色表现数据
    self.RLGuildDormRole = nil
    -- 组件 XGDComponet
    self.GDComponentManager = XGDComponentManager.New()
    -- 行为代理
    self.Agent = nil
    -- 移动代理
    self.MoveAgent = nil
    -- 状态机 XHomeCharFSM
    self.StateMachine = nil
    -- 当前交互状态
    self.InteractStatus = XGuildDormConfig.InteractStatus.End
    -- 当前交互信息
    self.CurrentInteractInfo = nil
    
    self.FixAlpha = 1
    self.TargetAlpha = 1
end

function XGuildDormBaseRole:Dispose()
    self.GDComponentManager:Dispose()
    self.Agent = nil
    self.MoveAgent = nil
    self.StateMachine = nil
    self.CurrentInteractInfo = nil
    if self.RLGuildDormRole then
        self.RLGuildDormRole:Dispose()
        self.RLGuildDormRole = nil
    end
end

function XGuildDormBaseRole:UpdateWithServerData(data) 
end

function XGuildDormBaseRole:GetId()
    return self.Id
end

---@return XRLGuildDormRole
function XGuildDormBaseRole:GetRLRole()
    if self.RLGuildDormRole == nil then 
        self.RLGuildDormRole = XRLGuildDormRole.New(self.Id)
    end
    return self.RLGuildDormRole
end

function XGuildDormBaseRole:CheckRLRoleIsCreated()
    return self.RLGuildDormRole ~= nil
end

---@return BehaviorTree.XAgent
function XGuildDormBaseRole:GetAgent()
    if self.Agent == nil then
        local gameObject = self:GetRLRole():GetGameObject()
        if XTool.UObjIsNil(gameObject) then return end
        self.Agent = gameObject:GetComponent(typeof(CS.BehaviorTree.XAgent))
        if XTool.UObjIsNil(self.Agent) then
            self.Agent = gameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
            self.Agent.ProxyType = "XGuildDormCharAgent"
            self.Agent:InitProxy()
            self.Agent.Proxy.LuaAgentProxy:SetRole(self)
        end 
    end   
    return self.Agent
end 

function XGuildDormBaseRole:GetMoveAgent() 
    if self.MoveAgent == nil then
        local gameObject = self:GetRLRole():GetGameObject()
        self.MoveAgent = CS.XNavMeshUtility.AddMoveAgent(gameObject)
        self.MoveAgent.Radius = 0.35
        self.MoveAgent.IsObstacle = false
        self.MoveAgent.IsIgnoreCollide = true
        self.MoveAgent.CeilSize = 0.3
        self.MoveAgent.Speed = XGuildDormConfig.GetRoleMoveSpeed()
    end
    return self.MoveAgent
end

function XGuildDormBaseRole:GetIsInteracting()
    return self.InteractStatus == XGuildDormConfig.InteractStatus.Begin
        or self.InteractStatus == XGuildDormConfig.InteractStatus.Playing
end

function XGuildDormBaseRole:GetInteractStatus()
    return self.InteractStatus
end

function XGuildDormBaseRole:UpdateInteractStatus(value)
    self.InteractStatus = value
end

function XGuildDormBaseRole:EnableCharacterController(value)
    if self:GetRLRole():GetCharacterController() == nil then
        return
    end
    self:GetRLRole():GetCharacterController().enabled = value
end

function XGuildDormBaseRole:GetCurrentInteractInfo()
    return self.CurrentInteractInfo
end

function XGuildDormBaseRole:UpdateCurrentInteractInfo(value)
    self.CurrentInteractInfo = value
end

function XGuildDormBaseRole:AddComponent(compoent, pos)
    self.GDComponentManager:AddComponent(compoent, pos)
end

function XGuildDormBaseRole:GetComponent(className)
    return self.GDComponentManager:GetComponent(className)
end

function XGuildDormBaseRole:PlayBehavior(id)
    local agent=self:GetAgent()
    if agent then
        agent:PlayBehavior(id)
    end
end

function XGuildDormBaseRole:PlayBehaviorByType(behaviorType)
    if behaviorType == nil then
        XLog.Error("获取角色行为树失败，角色id=".. tostring(self.Id) .. ", behaviorType=空")
        return
    end
    self:PlayBehavior(self:GetBehaviorIdByType(behaviorType))
end

function XGuildDormBaseRole:GetBehaviorIdByType(behaviorType)
    local behaviorId = XGuildDormConfig.GetRoleBehaviorIdByState(self.Id, behaviorType)
    if not behaviorId then
        XLog.Error("获取角色行为树失败，角色id=".. tostring(self.Id) .. ", state=" .. tostring(behaviorType))
        return
    end
    return behaviorId
end

function XGuildDormBaseRole:Update(dt)
    self.GDComponentManager:Update(dt)
end

function XGuildDormBaseRole:ChangeStateMachine(state, isForce)
    if not XGuildDormRoleFSMFactory.CheckHasState(state) then
        XLog.Error("guild dorm role 切换不存在的状态", state)
        return
    end
    if self.StateMachine and self.StateMachine.name == state and not isForce then
        return
    end
    if self.StateMachine then
        self.StateMachine:Exit()
    end
    self.StateMachine = XGuildDormRoleFSMFactory.New(state, self)
    self.StateMachine:Enter()
    self.StateMachine:Execute()
end

function XGuildDormBaseRole:CheckIsInStateMachine(state)
    if self.StateMachine and self.StateMachine.name == state then
        return true
    end
    return false
end

function XGuildDormBaseRole:GetEntityId()
end

function XGuildDormBaseRole:GetRLEntity()
    return self:GetRLRole()
end

function XGuildDormBaseRole:GetNameHeightOffset()
    return XGuildDormConfig.GetRoleNameHeightOffset(self:GetId())
end

function XGuildDormBaseRole:GetTalkHeightOffset()
    return XGuildDormConfig.GetRoleTalkHeightOffset(self:GetId())
end

function XGuildDormBaseRole:GetName()
end

function XGuildDormBaseRole:GetTriangleType()
    return XGuildDormConfig.TriangleType.None
end

function XGuildDormBaseRole:CheckIsSelfPlayer()
    return false
end

function XGuildDormBaseRole:GetUiShowDistance()
    return 0
end

return XGuildDormBaseRole