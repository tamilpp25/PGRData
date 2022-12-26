-- 教学关出战界面代理
local XUiNewCharNewRoomSingle = {}
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiNewCharNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiNewCharNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local curTeam = XDataCenter.TeamManager.LoadTeamLocal(newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SaveTeamLocal(curTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(curTeam, false)
    return XTool.Clone(curTeam)
end

function XUiNewCharNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.FubenNewCharActivityManager.GetCharacterList(newRoomSingle.CurrentStageId)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.NewCharAct, nil, {RobotIdList = robotIdList, RobotAndCharacter = true})
end

function XUiNewCharNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SaveTeamLocal(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiNewCharNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CSXTextManagerGetText("ActivityMainLineEnd"))
end

function XUiNewCharNewRoomSingle.UpdateFightControl(newRoomSingle, curTeam)
    return XUiFightControlState.Normal
end

return XUiNewCharNewRoomSingle