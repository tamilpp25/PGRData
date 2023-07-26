--二周年预热-赛跑小游戏出战界面代理
local XUiLivWarmRaceNewRoomSingle = {}

function XUiLivWarmRaceNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    newRoomSingle.PanelCharacterLimit.gameObject:SetActiveEx(false)
    newRoomSingle.BtnChar2.gameObject:SetActiveEx(false)
    newRoomSingle.BtnChar3.gameObject:SetActiveEx(false)
end

function XUiLivWarmRaceNewRoomSingle.HandleCharClick(newRoomSingle, charPos, stageId)
    local data = newRoomSingle:GetLivWarRaceData()
    local stageGroupId = data and data.StageGroupId
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = {}
    if stageGroupId then
        local robotId = XLivWarmRaceConfigs.GetGroupRobotId(stageGroupId)
        table.insert(robotIdList, robotId)
    else
        robotIdList = XLivWarmRaceConfigs.GetAllRobotId()
    end
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.LivWarRace, XFubenConfigs.GetStageCharacterLimitType(stageId), {
        -- LimitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId),
        ChallengeId = newRoomSingle.ChallengeId,
        TeamBuffId = newRoomSingle.TeamBuffId,
        IsRobotOnly = true, 
        RobotIdList = robotIdList 
    })
end

function XUiLivWarmRaceNewRoomSingle.GetBattleTeamData(newRoomSingleUi)
    local data = newRoomSingleUi:GetLivWarRaceData()
    local stageGroupId = data and data.StageGroupId
    local team = XTool.Clone(XDataCenter.TeamManager.EmptyTeam)
    if stageGroupId then
        local robotId = XLivWarmRaceConfigs.GetGroupRobotId(stageGroupId)
        team.TeamData[1] = robotId
    end
    XDataCenter.TeamManager.SetPlayerTeam(team, false)
    return team
end

function XUiLivWarmRaceNewRoomSingle.CheckCanCharClick(newRoomSingleUi, stageId)
    local finalStageId = XLivWarmRaceConfigs.GetActivityFinalStageId()
    return finalStageId == stageId
end

function XUiLivWarmRaceNewRoomSingle.CheckCanCharLongClick()
    return false
end

function XUiLivWarmRaceNewRoomSingle.GetIsHideSwitchFirstFightPosBtns()
    return true
end

function XUiLivWarmRaceNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId()
    return false
end

return XUiLivWarmRaceNewRoomSingle