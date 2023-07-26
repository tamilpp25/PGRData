-- 教学关出战界面代理
local XUiGuildBossNewRoomSingle = {}
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiGuildBossNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    --newRoomSingle.BtnTeamPrefab:SetButtonState(XUiButtonState.Disable)
end

--function XUiGuildBossNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
--    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
--    newRoomSingle.IsShowCharacterInfo = 0
--end

function XUiGuildBossNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local typeId
    local type = XDataCenter.GuildBossManager.GetCurSelectStageType()
    if type == GuildBossLevelType.Low then
        typeId = CS.XGame.Config:GetInt("TypeIdGuildBossLow")
    elseif type == GuildBossLevelType.High then
        typeId = CS.XGame.Config:GetInt("TypeIdGuildBossHigh")
    elseif type == GuildBossLevelType.Boss then
        typeId = CS.XGame.Config:GetInt("TypeIdGuildBossBoss")
    end
    local robotList = XDataCenter.GuildBossManager.GetStageRobotTab(newRoomSingle.CurrentStageId)
    --所有合法的角色ID
    local characterList = {}
    for i = 1, #robotList do
        table.insert(characterList, XRobotManager.GetCharacterId(robotList[i]))
        table.insert(characterList, robotList[i])
    end

    local curTeam = XDataCenter.TeamManager.GetPlayerTeam(typeId)
    --清除不符合规则的
    for i = 1, #curTeam.TeamData do
        if curTeam.TeamData[i] > 0 then
            local isOk = false
            for j = 1, #characterList do
                if curTeam.TeamData[i] == characterList[j] then
                    isOk = true
                    break
                end
            end
            if not isOk then
                curTeam.TeamData[i] = 0
            end
        end
    end

    return curTeam
end

function XUiGuildBossNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotList = XDataCenter.GuildBossManager.GetStageRobotTab(newRoomSingle.CurrentStageId)
    XLuaUiManager.Open("UiSelectCharacterWin", function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, UiSelectCharacterType.LimitedByCharacterAndRobot, teamData, charPos, robotList)
end

function XUiGuildBossNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiGuildBossNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId()
    return true
end

function XUiGuildBossNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CSXTextManagerGetText("ArenaOnlineTimeOut"))
end

function XUiGuildBossNewRoomSingle.UpdateFightControl(newRoomSingle, curTeam)
    return XUiFightControlState.Normal
end

return XUiGuildBossNewRoomSingle