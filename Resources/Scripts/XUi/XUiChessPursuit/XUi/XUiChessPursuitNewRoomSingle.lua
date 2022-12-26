-- 追击玩法出战界面代理
local XUiChessPursuitNewRoomSingle = {}

function XUiChessPursuitNewRoomSingle.LimitCharacter()
end

function XUiChessPursuitNewRoomSingle.SetEditBattleUiTeam(newRoomSingle)
    XDataCenter.ChessPursuitManager.SetPlayerTeamData(newRoomSingle.CurTeam, newRoomSingle.ChessPursuitData.MapId, newRoomSingle.ChessPursuitData.TeamGridIndex)
end

function XUiChessPursuitNewRoomSingle.DestroyNewRoomSingle()
    XDataCenter.ChessPursuitManager.ClearTempTeam()
end

return XUiChessPursuitNewRoomSingle