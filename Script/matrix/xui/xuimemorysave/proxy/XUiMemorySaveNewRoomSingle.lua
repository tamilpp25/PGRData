local XUiMemorySaveNewRoomSingle = {}

function XUiMemorySaveNewRoomSingle.OnResetEvent(newRoomSingle)
    XDataCenter.MemorySaveManager.OnActivityEnd()
end

function XUiMemorySaveNewRoomSingle.SetPlayerTeam(team)
    XDataCenter.TeamManager.SetPlayerTeam(team, false)
end

--是否保存队伍数据
function XUiMemorySaveNewRoomSingle.GetIsSaveTeamData()
    return true
end

return XUiMemorySaveNewRoomSingle