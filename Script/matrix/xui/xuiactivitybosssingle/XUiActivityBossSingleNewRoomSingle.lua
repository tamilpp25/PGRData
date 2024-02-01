--单人boss活动出战界面代理
local XUiActivityBossSingleNewRoomSingle = {}

function XUiActivityBossSingleNewRoomSingle.HandleCharClick(newRoomSingle, charPos, stageId)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.FubenActivityBossSingleManager.GetCanUseRobotIds(nil,teamData)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.ActivityBossSingle, XFubenConfigs.GetStageCharacterLimitType(stageId), {
        LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId),
        ChallengeId = newRoomSingle.ChallengeId,
        TeamBuffId = newRoomSingle.TeamBuffId,
        RobotAndCharacter = true, RobotIdList = robotIdList })
end

function XUiActivityBossSingleNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local team = XDataCenter.FubenActivityBossSingleManager.LoadTeamLocal()

    for index, id in pairs(team.TeamData) do
        --清库之后本地缓存角色失效
        if not XMVCA.XCharacter:IsOwnCharacter(id) and not XRobotManager.CheckIsRobotId(id) then
            team.TeamData[index] = 0
        end
    end
    return team
end

function XUiActivityBossSingleNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.FubenActivityBossSingleManager.SaveTeamLocal(newRoomSingle.CurTeam)
end

function XUiActivityBossSingleNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId()
    return false
end

function XUiActivityBossSingleNewRoomSingle.OnResetEvent(newRoomSingle)
    XDataCenter.FubenActivityBossSingleManager.OnActivityEnd()
end

function XUiActivityBossSingleNewRoomSingle.GetIsSaveTeamData()
    return false
end

return XUiActivityBossSingleNewRoomSingle