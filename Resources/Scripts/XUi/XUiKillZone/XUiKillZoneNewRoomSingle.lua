--杀戮无双玩法出战界面代理
local XUiKillZoneNewRoomSingle = {}

function XUiKillZoneNewRoomSingle.HandleCharClick(newRoomSingle, charPos, stageId)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XKillZoneConfigs.GetStageRobotIds(stageId)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.KillZone, nil, { RobotAndCharacter = true, RobotIdList = robotIdList })
end

function XUiKillZoneNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local team = XDataCenter.KillZoneManager.LoadTeamLocal()

    local lookupTable = {}
    local stageId = newRoomSingle.CurrentStageId
    local robotIdList = XKillZoneConfigs.GetStageRobotIds(stageId)
    for _, id in pairs(robotIdList) do
        lookupTable[id] = id
    end

    for index, id in pairs(team.TeamData) do
        if XRobotManager.CheckIsRobotId(id) then
            if not XTool.IsNumberValid(lookupTable[id]) then
                team.TeamData[index] = 0
            end
        else
            --清库之后本地缓存角色失效
            if not XDataCenter.CharacterManager.IsOwnCharacter(id) then
                team.TeamData[index] = 0
            end
        end
    end

    return team
end

function XUiKillZoneNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.KillZoneManager.SaveTeamLocal(newRoomSingle.CurTeam)
end

function XUiKillZoneNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId()
    return false
end

function XUiKillZoneNewRoomSingle.OnResetEvent(newRoomSingle)
    XDataCenter.KillZoneManager.OnActivityEnd()
end

function XUiKillZoneNewRoomSingle.GetIsSaveTeamData()
    return false
end

return XUiKillZoneNewRoomSingle