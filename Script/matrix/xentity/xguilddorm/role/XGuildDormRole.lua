local XRLGuildDormRole = require("XEntity/XGuildDorm/Role/XRLGuildDormRole")
local XGDMoveComponent = require("XEntity/XGuildDorm/Components/XGDMoveComponent")
local XGuildDormRoleFSMFactory = require("XEntity/XGuildDorm/Role/FSM/XGuildDormRoleFSMFactory")
local XGDComponentManager = require("XEntity/XGuildDorm/Base/XGDComponentManager")
local XGuildDormBaseRole = require("XEntity/XGuildDorm/Role/XGuildDormBaseRole")
---@class XGuildDormRole : XGuildDormBaseRole
local XGuildDormRole = XClass(XGuildDormBaseRole, "XGuildDormRole")

function XGuildDormRole:Ctor(id)
    self.PlayerId = nil
    -- 服务器数据
    self.ServerData = nil
    self.PlayActionId = -1
    self.SyncState = XGuildDormConfig.SyncState.None
    -- 上一次结束交互的时间
    self.LastEndInteractTime = 0
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
    for _, com in ipairs(self.GDComponentManager:GetComponents()) do
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
    rlRole:UpdateCurrentStepCueId(XDataCenter.GuildDormManager.GetCurrentRoom():GetWalkCueId())
end

function XGuildDormRole:GetPlayerId()
    return self.PlayerId    
end

function XGuildDormRole:GetCurrentMoveDirection()
    return self:GetComponent("XGDInputCompoent"):GetMoveDirection()
end

function XGuildDormRole:GetCurrentMoveDirectionIsZero()
    local x, y = self:GetCurrentMoveDirection()
    return (x == 0 and y == 0) 
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

function XGuildDormRole:BeginNpcInteract(interactInfo)
    local com = self:GetComponent("XGDNpcInteractComponent")
    if com == nil then return end
    com:BeginInteract(interactInfo, false)
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

function XGuildDormRole:GetEntityId()
    return self.PlayerId
end

function XGuildDormRole:GetName()
    return XDataCenter.GuildDormManager.GetPlayerName(self.PlayerId)
end

function XGuildDormRole:GetTriangleType()
    return XGuildDormConfig.TriangleType.Player
end

return XGuildDormRole