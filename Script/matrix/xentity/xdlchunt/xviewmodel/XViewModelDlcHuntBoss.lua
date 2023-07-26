---@class XViewModelDlcHuntBoss
local XViewModelDlcHuntBoss = XClass(nil, "XViewModelDlcHuntBoss")

function XViewModelDlcHuntBoss:Ctor(worldId)
    self._PartIndex = 1
    self._WorldId = worldId
end

function XViewModelDlcHuntBoss:_GetWorldId()
    return self._WorldId
end

function XViewModelDlcHuntBoss:GetBossName()
    local worldId = self:_GetWorldId()
    local chapterId = XDlcHuntWorldConfig.GetChapterId(worldId)
    if not chapterId then
        XLog.Error("[XViewModelDlcHuntBoss] the world is not belong to any chapter:", tostring(worldId))
        return "???"
    end
    return XDlcHuntWorldConfig.GetChapterName(chapterId)
end

-- 可破坏部位
function XViewModelDlcHuntBoss:GetPartsCanBreak()
    local worldId = self:_GetWorldId()
    return XDlcHuntWorldConfig.GetBossPartsCanBreak(worldId)
end

function XViewModelDlcHuntBoss:GetPartSelected()
    return self:GetPartsCanBreak()[self._PartIndex]
end

function XViewModelDlcHuntBoss:GetPartDescSelected()
    return self:GetPartSelected().Desc
end

function XViewModelDlcHuntBoss:GetPartNameSelected()
    return self:GetPartSelected().Name
end

function XViewModelDlcHuntBoss:GetPartIconSelected()
    return self:GetPartSelected().Icon
end

return XViewModelDlcHuntBoss