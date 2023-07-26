local XGuildDormBaseRole = require("XEntity/XGuildDorm/Role/XGuildDormBaseRole")
---@class XGuildDormNpc : XGuildDormBaseRole
local XGuildDormNpc = XClass(XGuildDormBaseRole, "XGuildDormNpc")

function XGuildDormNpc:Ctor(id)
    self.NpcConfig = nil
    self.NpcRefreshConfig = nil
    self.IsTalking = false
    self.IsRemove = false
end

function XGuildDormNpc:SetNpcConfig(value)
    self.NpcConfig = value
end

function XGuildDormNpc:SetNpcRefreshConfig(value)
    self.NpcRefreshConfig = value
end

function XGuildDormNpc:GetRefreshConfig()
    return self.NpcRefreshConfig
end

function XGuildDormNpc:Dispose()
    XGuildDormNpc.Super.Dispose(self)
end

function XGuildDormNpc:SetIsTalking(value)
    self.IsTalking = value
end

function XGuildDormNpc:GetIsTalking()
    return self.IsTalking
end

function XGuildDormNpc:SetIsRemove(value)
    self.IsRemove = value
end

function XGuildDormNpc:GetIsRemove()
    return self.IsRemove
end

-- 若配置为0，则为常驻生效
-- 若配置为-1，则一直不生效
function XGuildDormNpc:CheckInTime()
    local refreshTimeId = self.NpcRefreshConfig.RefreshTimeId
    if refreshTimeId == 0 then
        return true
    end
    if refreshTimeId == -1 then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(refreshTimeId)
end

function XGuildDormNpc:CheckIsEndTime()
    if self:GetIsTalking() then
        return false
    end
    local refreshTimeId = self.NpcRefreshConfig.RefreshTimeId
    if refreshTimeId == 0 or refreshTimeId == -1 then
        return false
    end
    return XTime.GetServerNowTimestamp() >= XFunctionManager.GetEndTimeByTimeId(refreshTimeId)
end

function XGuildDormNpc:GetEntityId()
    return self.NpcConfig.Id .. "_XGuildDormNpc"
end

function XGuildDormNpc:GetName()
    return self.NpcConfig.Name
end

function XGuildDormNpc:GetIdleBehaviorId()
    return self.NpcRefreshConfig.IdleBehaviorId
end

function XGuildDormNpc:GetPatrolBehaviorId()
    return self.NpcRefreshConfig.PatrolBehaviorId
end

function XGuildDormNpc:GetAnimControllerPath()
    return self.NpcRefreshConfig.AnimControllerPath
end

function XGuildDormNpc:UpdateInteractStatus(value,ignoreBehaivorChange)
    self.InteractStatus = value
    if value == XGuildDormConfig.InteractStatus.End then
        if not ignoreBehaivorChange then
            self:PlayBehavior(self:GetIdleBehaviorId())
        end
        XDataCenter.GuildDormManager.ResetNpcInteractGameStatus(self:GetEntityId())
        self:SetIsTalking(false)
    end
end

function XGuildDormNpc:GetTriangleType()
    return XGuildDormConfig.TriangleType.Npc
end

return XGuildDormNpc