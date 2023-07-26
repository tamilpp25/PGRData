-- 兵法蓝图出战界面代理
local XUiRpgTowerNewRoomSingle = {}

function XUiRpgTowerNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    newRoomSingle.PanelCharacterLimit.gameObject:SetActiveEx(false)
end

function XUiRpgTowerNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    newRoomSingle.IsShowCharacterInfo = 0
end

function XUiRpgTowerNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local team = XDataCenter.TeamManager.GetPlayerTeam(newRoomSingle.TypeIdRpgTower)
    for i in pairs(team.TeamData) do
        if team.TeamData[i] > 0 and not XDataCenter.RpgTowerManager.GetTeamMemberExist(team.TeamData[i]) then
            team.TeamData[i] = 0
        end
    end
    return team
end

function XUiRpgTowerNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    XLuaUiManager.Open("UiRpgTowerRoomCharacter", XTool.Clone(newRoomSingle.CurTeam.TeamData), charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end)
end

function XUiRpgTowerNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiRpgTowerNewRoomSingle.UpdateRoleModel(newRoomSingle, charId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel()
    local callback = function()
        newRoomSingle.LoadModelCount = newRoomSingle.LoadModelCount - 1
        if newRoomSingle.LoadModelCount <= 0 then
            newRoomSingle.BtnEnterFight:SetDisable(false)
        end
    end
    local rChara = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(charId)
    local robotId = rChara:GetRobotId()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    roleModelPanel:UpdateRobotModel(robotId, charId, callback, robotCfg.FashionId, robotCfg.WeaponId)
end

function XUiRpgTowerNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end

function XUiRpgTowerNewRoomSingle.SetEditBattleUiTeam(newRoomSingle)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiRpgTowerNewRoomSingle.GetRealCharData(newRoomSingle)
    local teamData = newRoomSingle.CurTeam.TeamData
    local teamIdData = {}
    for pos, charaId in pairs(teamData) do
        if charaId and charaId > 0 then
            teamIdData[pos] = XDataCenter.RpgTowerManager.GetTeamMemberByCharacterId(charaId):GetRobotId()
        else
            teamIdData[pos] = 0
        end
    end
    return teamIdData
end

function XUiRpgTowerNewRoomSingle.UpdateFightControl(newRoomSingle, curTeam)
    local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(newRoomSingle.CurrentStageId)
    newRoomSingle.FightControlResult = newRoomSingle.FightControl:UpdateByTextAndWarningLevel(
        rStage:GetStageWarningType(),
        CS.XTextManager.GetText("RpgTowerWarningControlName"),
        rStage:GetRecommendLevel(),
        CS.XTextManager.GetText("RpgTowerCurNumText", XDataCenter.RpgTowerManager.GetCurrentLevel())
    )
end

function XUiRpgTowerNewRoomSingle.UpdatePartnerInfo(newRoomSingleUi, maxCharaCount)
    for i = 1, maxCharaCount do
        local panel = newRoomSingleUi["CharacterPets" .. i]
        if panel then panel.gameObject:SetActiveEx(false) end
    end
end

return XUiRpgTowerNewRoomSingle