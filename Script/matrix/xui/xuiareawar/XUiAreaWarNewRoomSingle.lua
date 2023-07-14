--全服决战法出战界面代理
local XUiAreaWarNewRoomSingle = {}

function XUiAreaWarNewRoomSingle.HandleCharClick(newRoomSingle, charPos, stageId)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.AreaWarManager.GetCanUseRobotIds()
    XLuaUiManager.Open(
        "UiRoomCharacter",
        teamData,
        charPos,
        function(resTeam)
            newRoomSingle:UpdateTeam(resTeam)
        end,
        XDataCenter.FubenManager.StageType.AreaWar,
        nil,
        {RobotAndCharacter = true, RobotIdList = robotIdList}
    )
end

function XUiAreaWarNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local team = XDataCenter.AreaWarManager.LoadTeamLocal()

    local lookupTable = {}
    local stageId = newRoomSingle.CurrentStageId
    local robotIdList = XDataCenter.AreaWarManager.GetCanUseRobotIds()
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

function XUiAreaWarNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.AreaWarManager.SaveTeamLocal(newRoomSingle.CurTeam)
end

function XUiAreaWarNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId()
    return false
end

function XUiAreaWarNewRoomSingle.OnResetEvent(newRoomSingle)
    XDataCenter.AreaWarManager.OnActivityEnd()
end

function XUiAreaWarNewRoomSingle.GetIsSaveTeamData()
    return false
end

return XUiAreaWarNewRoomSingle
