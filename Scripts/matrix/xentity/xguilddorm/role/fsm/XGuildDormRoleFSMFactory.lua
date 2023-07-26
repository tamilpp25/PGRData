--######################## XBaseFSM ########################
local XBaseFSM = XClass(nil, "XBaseFSM")

function XBaseFSM:Ctor(role)
    self.Role = role
end

function XBaseFSM:Enter()
    self:OnEnter()
end

function XBaseFSM:OnEnter()
end

function XBaseFSM:Execute()
end

function XBaseFSM:Exit()
    self:OnExit()
end

function XBaseFSM:OnExit()
end

--######################## XGuildDormRoleFSMFactory ########################

--状态工厂
local XGuildDormRoleFSMFactory = XGuildDormRoleFSMFactory or {}
--注册表
local Registry = {}
local FSMPoolDic = {}

--注册状态机
function XGuildDormRoleFSMFactory.RegisterFSM(name, state)
    local machine = XClass(XBaseFSM, name)
    Registry[state] = machine
    machine.name = state
    return machine
end

--新建状态
function XGuildDormRoleFSMFactory.New(state, agent)
    if not Registry[state] then
        XLog.Error("状态机未注册！！！StateMachine :" .. tostring(state))
        return nil
    end
    if FSMPoolDic[agent] == nil then
        FSMPoolDic[agent] = {}
    end
    local result = FSMPoolDic[agent][state]
    if result == nil then
        result = Registry[state].New(agent)
        FSMPoolDic[agent][state] = result
    end
    return result
end

--清空注册表
function XGuildDormRoleFSMFactory.ClearRegistry()
    Registry = {}
end

function XGuildDormRoleFSMFactory.Dispose()
    FSMPoolDic = {}
end

function XGuildDormRoleFSMFactory.CheckHasState(state)
    return Registry[state]
end

--######################## 状态机 ########################

local XGDRoleIdleFSM = XGuildDormRoleFSMFactory.RegisterFSM("XGDRoleIdleFSM", XGuildDormConfig.RoleFSMType.IDLE)

function XGDRoleIdleFSM:OnEnter()
    self.Role:GetRLRole():PlayAnimation(XGuildDormConfig.GetRoleIdleAnimName(self.Role:GetId())
        , true, 0.05)
end

function XGDRoleIdleFSM:Execute()
end

function XGDRoleIdleFSM:OnExit()
end

local XGDRoleMoveFSM = XGuildDormRoleFSMFactory.RegisterFSM("XGDRoleMoveFSM", XGuildDormConfig.RoleFSMType.MOVE)

function XGDRoleMoveFSM:OnEnter()
    self.Role:GetRLRole():PlayAnimation(XGuildDormConfig.GetRoleWalkAnimName(self.Role:GetId())
        , true, 0.05)
end

function XGDRoleMoveFSM:Execute()
end

function XGDRoleMoveFSM:OnExit()
end

local XGDRolePlayActionFSM = XGuildDormRoleFSMFactory.RegisterFSM("XGDRolePlayActionFSM", XGuildDormConfig.RoleFSMType.PLAY_ACTION)

function XGDRolePlayActionFSM:OnEnter()
end

function XGDRolePlayActionFSM:Execute()
end

function XGDRolePlayActionFSM:OnExit()
end

local XGDRolePatrolIdleFSM=XGuildDormRoleFSMFactory.RegisterFSM("XGDRolePatrolIdleFSM",XGuildDormConfig.RoleFSMType.PATROL_IDLE)

function XGDRolePatrolIdleFSM:OnEnter()
    local npcData=XDataCenter.GuildDormManager.GetNpcDataFromDormData(self.Role.RefreshId)
    --查表获取动画
    local config=XGuildDormConfig.GetIdleConfigById(npcData.ActionId)
    if config then
        local idleAnimName=config.IdleAnimId
        self.Role:GetRLRole():PlayAnimation(idleAnimName
        , true, 0.05)
    end
    
end

function XGDRolePatrolIdleFSM:Execute()
end

function XGDRolePatrolIdleFSM:OnExit()
end

local XGDRoleInteractFSM=XGuildDormRoleFSMFactory.RegisterFSM("XGDRoleInteractFSM",XGuildDormConfig.RoleFSMType.INTERACT)

function XGDRoleInteractFSM:OnEnter()
end

function XGDRoleInteractFSM:Execute()
end

function XGDRoleInteractFSM:OnExit()
end

return XGuildDormRoleFSMFactory