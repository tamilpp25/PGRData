-- 骇入玩法出战界面代理
local XUiHackNewRoomSingle = {}

function XUiHackNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiHackNewRoomSingle.GetCharAbility(charId)
    if XRobotManager.CheckIsRobotId(charId) then
        -- 骇入玩法战力计算特殊处理
        return XRobotManager.GetRobotAbility(charId) + XDataCenter.FubenHackManager.GetBuffAbilityBonus()
    else
        return 0
    end
end

function XUiHackNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local curTeam = XDataCenter.FubenHackManager.LoadTeamLocal()
    XDataCenter.FubenHackManager.SaveTeamLocal(curTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(curTeam, false)
    return XTool.Clone(curTeam)
end

function XUiHackNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.FubenHackManager.GetCurChapterTemplate().RobotId
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.Hack, nil, {IsRobotOnly = true, RobotIdList = robotIdList})
end

function XUiHackNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.FubenHackManager.SaveTeamLocal(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiHackNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XDataCenter.FubenHackManager.OnActivityEnd()
end

return XUiHackNewRoomSingle