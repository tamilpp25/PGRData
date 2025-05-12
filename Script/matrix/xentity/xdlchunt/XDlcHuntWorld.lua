---@class XDlcHuntWorld
local XDlcHuntWorld = XClass(nil, "XDlcHuntWorld")

function XDlcHuntWorld:Ctor(worldId)
    self._WorldId = worldId
end

function XDlcHuntWorld:GetWorldId()
    return self._WorldId
end

function XDlcHuntWorld:GetName()
    return XDlcHuntWorldConfig.GetWorldName(self:GetWorldId())
end

function XDlcHuntWorld:GetDifficultyName()
    return XDlcHuntWorldConfig.GetWorldDifficultyName(self:GetWorldId())
end

function XDlcHuntWorld:GetDifficultyNameEn()
    return XDlcHuntWorldConfig.GetWorldDifficultyNameEn(self:GetWorldId())
end

function XDlcHuntWorld:GetDifficultyLevel()
    return XDlcHuntWorldConfig.GetWorldDifficultyLevel(self:GetWorldId())
end

function XDlcHuntWorld:IsPassed()
    return XDataCenter.DlcHuntManager.IsPassed(self:GetWorldId())
end

function XDlcHuntWorld:GetPreWorld()
    local preWorldId = XDlcHuntWorldConfig.GetPreWorldId(self:GetWorldId())
    if preWorldId <= 0 then
        return false
    end
    local preWorld = XDataCenter.DlcHuntManager.GetWorld(preWorldId)
    return preWorld
end

function XDlcHuntWorld:IsUnlock()
    local preWorld = self:GetPreWorld()
    if not preWorld then
        return true
    end
    return preWorld:IsPassed(), XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_FRONT_WORLD_NOT_PASS
end

function XDlcHuntWorld:IsRank()
    return XDlcHuntWorldConfig.GetIsRank(self:GetWorldId())
end

return XDlcHuntWorld