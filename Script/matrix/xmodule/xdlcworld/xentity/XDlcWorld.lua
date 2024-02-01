---@class XDlcWorld
local XDlcWorld = XClass(nil, "XDlcWorld")

---@param config XTableDlcHuntWorld
function XDlcWorld:Ctor(config)
    self._Config = config
end

function XDlcWorld:GetWorldId()
    return self._Config.WorldId
end

function XDlcWorld:GetName()
    return self._Config.Name
end

function XDlcWorld:GetType()
    return self._Config.WorldType
end

function XDlcWorld:GetPreWorldId()
    return self._Config.PreWorldId
end

function XDlcWorld:GetTeachingCharacterId()
    return self._Config.TeachingCharacterId
end

function XDlcWorld:GetBgmId()
    return self._Config.BgmId
end

function XDlcWorld:GetEventId()
    return self._Config.EventId
end

function XDlcWorld:GetLoadingType()
    return self._Config.LoadingType
end

function XDlcWorld:GetFinishRewardShow()
    return self._Config.FinishRewardShow
end

function XDlcWorld:GetFinishDropId()
    return self._Config.FinishDropId
end

function XDlcWorld:GetFirstRewardId()
    return self._Config.FirstRewardId
end

function XDlcWorld:GetOnlinePlayerLeast()
    return self._Config.OnlinePlayerLeast
end

function XDlcWorld:GetOnlinePlayerLimit()
    return self._Config.OnlinePlayerLimit
end

function XDlcWorld:GetSettleLoseTipId()
    return self._Config.SettleLoseTipId
end

function XDlcWorld:GetMatchPlayerCountThreshold()
    return self._Config.MatchPlayerCountThreshold
end

function XDlcWorld:GetNeedFightPower()
    return self._Config.NeedFightPower
end

function XDlcWorld:IsRank()
    return self._Config.IsRank == 1
end

function XDlcWorld:GetDifficultyId()
    return self._Config.DifficultyId
end 

function XDlcWorld:GetRebootId()
    return self._Config.RebootId
end

function XDlcWorld:IsEmpty()
    return self._Config == nil
end 

---@param world XDlcWorld
function XDlcWorld:Equals(world)
    if self:IsEmpty() and world:IsEmpty() then
        return true
    end
    if self:IsEmpty() or world:IsEmpty() then
        return false
    end

    return self:GetWorldId() == world:GetWorldId()
end

function XDlcWorld:EqualsId(worldId)
    if self:IsEmpty() and not worldId then
        return true
    end
    if self:IsEmpty() or not worldId then
        return false
    end

    return self:GetWorldId() == worldId
end

function XDlcWorld:Release()
    self._Config = nil
end

return XDlcWorld