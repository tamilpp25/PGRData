local XRedPointConditionActivityTaikoMasterCdUnlock = {}

function XRedPointConditionActivityTaikoMasterCdUnlock.Check(songId)
    if not XDataCenter.TaikoMasterManager.IsFunctionOpen() then
        return false
    end
    if not XDataCenter.TaikoMasterManager.IsActivityOpen() then
        return false
    end
    if songId then
        local state = XDataCenter.TaikoMasterManager.GetSongState4RedDot(songId)
        return state == XTaikoMasterConfigs.SongState.JustUnlock
    end
    local songArray = XDataCenter.TaikoMasterManager.GetSongArray()
    for i = 1, #songArray do
        local songId = songArray[i]
        if XRedPointConditionActivityTaikoMasterCdUnlock.Check(songId) then
            return true
        end
    end
    return false
end

return XRedPointConditionActivityTaikoMasterCdUnlock
