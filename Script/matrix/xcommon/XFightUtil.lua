XFightUtil = {}
local XFightUtil = XFightUtil

function XFightUtil.ClearFight()
    if CS.XFight.Instance ~= nil then
        CS.XFight.ClearFight()
    end
    if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
        CS.StatusSyncFight.XFightClient.OnExitFight(true)
    end
end

function XFightUtil.IsFighting()
    return CS.XFight.Instance ~= nil or CS.StatusSyncFight.XFightClient.FightInstance ~= nil
end

function XFightUtil.IsDlcOnline()
    if not CS.StatusSyncFight.XFightClient.FightInstance then
        return false
    end
    return CS.StatusSyncFight.XFightClient.FightInstance.IsOnline
end

function XFightUtil.GetDlcHuntWorldId()
    if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
        return CS.StatusSyncFight.XFightClient.FightInstance:GetWorldId()
    end
    return 0
end

return XFightUtil