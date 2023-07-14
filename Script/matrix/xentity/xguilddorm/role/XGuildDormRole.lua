local XRLGuildDormRole = require("XEntity/XGuildDorm/Role/XRLGuildDormRole")
local XGDMoveComponent = require("XEntity/XGuildDorm/Components/XGDMoveComponent")
local XGuildDormRoleFSMFactory = require("XEntity/XGuildDorm/Role/FSM/XGuildDormRoleFSMFactory")
local XGuildDormRole = XClass(nil, "XGuildDormRole")

function XGuildDormRole:Ctor(id)
    self.Id = id
    self.PlayerId = nil
    -- 角色表现数据
    self.RLGuildDormRole = nil
    -- 服务器数据
    self.ServerData = nil
    -- 组件 XGDComponet
    self.Componets = nil
    self.ComponetDic = nil
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
    self.PlayActionId = -1
    self.SyncState = XGuildDormConfig.SyncState.None
    -- 上一次结束交互的时间
    self.LastEndInteractTime = 0
    self:_InitDefaultComponets()
end

function XGuildDormRole:Dispose()
    self.ComponetDic = nil
    self.Componets = nil
    self.Agent = nil
    self.MoveAgent = nil
    self.StateMachine = nil
    self.CurrentInteractInfo = nil
    self.RLGuildDormRole:Dispose()
end

function XGuildDormRole:UpdateWithServerData(data) 
    self.ServerData = data
    self.PlayerId = data.PlayerId
    self:GetRLRole():UpdatePlayerId(self.PlayerId)
end

function XGuildDormRole:UpdatePlayActionId(value)
    self.PlayActionId = value
end

function XGuildDormRole:GetPlayActionId()
    return self.PlayActionId
end

function XGuildDormRole:GetIsPlayingAction()
    return self.PlayActionId > 0
end

function XGuildDormRole:UpdateRoleId(roleId)
    if roleId == self.Id then return end
    self.Id = roleId
    self.Agent = nil
    self.MoveAgent = nil
    local rlRole = self:GetRLRole()
    rlRole:UpdateRoleId(roleId)
    -- 更新组件的依赖
    for _, com in ipairs(self.Componets) do
        if com.UpdateRoleDependence then
            com.UpdateRoleDependence(com)
        end
    end
    -- 更新摄像机追随
    if self:CheckIsSelfPlayer() then
        rlRole:UpdateCameraFollow()
    else -- 不是自己玩家要禁用碰撞
        rlRole:DisableColliders()
    end
    rlRole:GetGameObject():LoadPrefab(XGuildDormConfig.GetSwitchRoleEffect())
end

function XGuildDormRole:GetId()
    return self.Id
end

function XGuildDormRole:GetPlayerId()
    return self.PlayerId    
end

function XGuildDormRole:GetRLRole()
    if self.RLGuildDormRole == nil then 
        self.RLGuildDormRole = XRLGuildDormRole.New(self.Id)
    end
    return self.RLGuildDormRole
end

function XGuildDormRole:GetAgent()
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

function XGuildDormRole:GetMoveAgent() 
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

function XGuildDormRole:GetCurrentMoveDirection()
    return self:GetComponent("XGDInputCompoent"):GetMoveDirection()
end

function XGuildDormRole:GetCurrentMoveDirectionIsZero()
    local x, y = self:GetCurrentMoveDirection()
    return (x == 0 and y == 0) 
end

function XGuildDormRole:GetIsInteracting()
    return self.InteractStatus == XGuildDormConfig.InteractStatus.Begin
        or self.InteractStatus == XGuildDormConfig.InteractStatus.Playing
end

function XGuildDormRole:GetInteractStatus()
    return self.InteractStatus
end

function XGuildDormRole:UpdateInteractStatus(value)
    self.InteractStatus = value
    if value == XGuildDormConfig.InteractStatus.End then
        if self:CheckIsSelfPlayer() then
            local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
            if currentRoom and currentRoom:CheckPlayerIsInteract(self.PlayerId) then
                XDataCenter.GuildDormManager.RequestFurnitureInteract(-1)
            end
        else
            local com = self:GetComponent("XGDSyncToClientComponent")
            if com == nil then return end
            -- 交互结束后自己更新一次，避免因为上次快速插值
            local transform = self:GetRLRole():GetTransform()
            com:UpdateCurrentSyncData(transform.position, transform.rotation
                , XGuildDormConfig.SyncState.None)
        end
        -- 记录上一次交互时间
        self.LastEndInteractTime = XTime.GetServerNowTimestamp()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_STOP, self.PlayerId)
    end
end

function XGuildDormRole:GetIsOverLastEndInteractTime()
    return XTime.GetServerNowTimestamp() - self.LastEndInteractTime 
        >= XGuildDormConfig.GetInteractIntervalTime()
end

function XGuildDormRole:EnableCharacterController(value)
    if self:GetRLRole():GetCharacterController() == nil then
        return
    end
    self:GetRLRole():GetCharacterController().enabled = value
end

function XGuildDormRole:GetCurrentInteractInfo()
    return self.CurrentInteractInfo
end

function XGuildDormRole:UpdateCurrentInteractInfo(value)
    self.CurrentInteractInfo = value
end

function XGuildDormRole:AddComponent(compoent, pos)
    if pos == nil then 
        table.insert(self.Componets, compoent)
    else
        table.insert(self.Componets, pos, compoent)
    end
    self.ComponetDic[compoent.__cname] = compoent
    compoent:Init()
end

function XGuildDormRole:GetComponent(className)
    return self.ComponetDic[className]
end

function XGuildDormRole:PlayBehavior(id)
    self:GetAgent():PlayBehavior(id)
end

function XGuildDormRole:PlayBehaviorByType(behaviorType)
    self:PlayBehavior(self:GetBehaviorIdByType(behaviorType))
end

function XGuildDormRole:GetBehaviorIdByType(behaviorType)
    local behaviorId = XGuildDormConfig.GetRoleBehaviorIdByState(self.Id, behaviorType)
    if not behaviorId then
        XLog.Error("获取角色行为树失败，角色id=".. tostring(self.Id) .. ", state=" .. tostring(behaviorType))
        return
    end
    return behaviorId
end

function XGuildDormRole:Update(dt)
    for _, component in ipairs(self.Componets) do
        if component.Update then
            if component:CheckCanUpdate(dt) then
                component:Update(dt)
            end
        end
    end
end

local MoveWallState = {
    BEGIN = 0,
    MOVING = 1,
    END = 2,
}

-- 检查是否需要同步给服务器
function XGuildDormRole:SyncToServer()
    local transform = self:GetRLRole():GetTransform()
    local isZeroDirection = self:GetCurrentMoveDirectionIsZero()
    self.SyncState = XDataCenter.GuildDormManager.GetGuildDormNetwork():GetCsNetwork():SyncToServer(transform, isZeroDirection, self.SyncState)
end

function XGuildDormRole:ChangeStateMachine(state, isForce)
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

function XGuildDormRole:CheckIsInStateMachine(state)
    if self.StateMachine and self.StateMachine.name == state then
        return true
    end
    return false
end

function XGuildDormRole:StopPlayAction()
    self:UpdatePlayActionId(-1)
    self:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
    local com = self:GetComponent("XGDActionPlayComponent")
    if com then
        com:StopPlayAction()
    end
end

function XGuildDormRole:BeginInteract(id, isDirectInteract)
    if isDirectInteract == nil then isDirectInteract = false end
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local currentInteractInfo = currentRoom:GetInteractInfoByFurnitureId(id)
    if currentInteractInfo == nil then return end
    self:UpdateCurrentInteractInfo(currentInteractInfo)
    self:UpdateInteractStatus(XGuildDormConfig.InteractStatus.Begin)
    local com = self:GetComponent("XGDFurnitureInteractComponent")
    if com == nil then return end
    com:BeginInteract(currentInteractInfo, isDirectInteract)
    self:GetAgent():SetVarDicByKey("IsDirectInteract", isDirectInteract)
end

function XGuildDormRole:StopInteract()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_INTERACT_STOP
        , self:GetPlayerId())
    -- 这里是为了特殊处理玩家进入后，其他玩家重复检查停止交互的逻辑
    XScheduleManager.ScheduleOnce(function()
        local agent = self:GetAgent()
        if agent == nil then return end
        local isSuccess = agent:GetVarDicByKey("InteractStopSuccess")
        if not isSuccess and self:GetIsInteracting() then
            self:StopInteract()
        end
        agent:SetVarDicByKey("InteractStopSuccess", nil)
    end, 1)
end

function XGuildDormRole:CheckIsSelfPlayer()
    return self.PlayerId == XPlayer.Id
end

--######################## 私有方法 ########################

-- 初始化默认的components
function XGuildDormRole:_InitDefaultComponets()
    self.Componets = nil
    self.Componets = {}
    self.ComponetDic = nil
    self.ComponetDic = {}
end

return XGuildDormRole