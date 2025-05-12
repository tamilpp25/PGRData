--拟真Boss出战界面代理
local XUiPracticeBossNewRoomSingleProxy = {}

function XUiPracticeBossNewRoomSingleProxy.HandleCharClick(newRoomSingle, charPos, stageId)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.PracticeBoss, XFubenConfigs.GetStageCharacterLimitType(stageId), {
        LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId),
        ChallengeId = newRoomSingle.ChallengeId,
        TeamBuffId = newRoomSingle.TeamBuffId, })
end

function XUiPracticeBossNewRoomSingleProxy.GetBattleTeamData(newRoomSingle)
    local team = XDataCenter.PracticeManager.LoadBossTeamLocal()
    for index, id in pairs(team.TeamData) do
        --清库之后本地缓存角色失效
        if not XMVCA.XCharacter:IsOwnCharacter(id) and not XRobotManager.CheckIsRobotId(id) then
            team.TeamData[index] = 0
        end
    end
    return team
end

function XUiPracticeBossNewRoomSingleProxy.UpdateTeam(newRoomSingle)
    XDataCenter.PracticeManager.SaveBossTeamLocal(newRoomSingle.CurTeam)
end

function XUiPracticeBossNewRoomSingleProxy.GetIsSaveTeamData()
    return false
end

function XUiPracticeBossNewRoomSingleProxy.GetIsCheckCaptainIdAndFirstFightId()
    return false
end

return XUiPracticeBossNewRoomSingleProxy