-- 模拟战斗出战界面代理
local XUiSimulatedCombatNewRoomSingle = {}
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiSimulatedCombatNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    newRoomSingle.PanelCharacterLimit.gameObject:SetActiveEx(false)
end

function XUiSimulatedCombatNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    newRoomSingle.IsShowCharacterInfo = 0
end

function XUiSimulatedCombatNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local curTeam = XDataCenter.FubenSimulatedCombatManager.GetTeam()
    XDataCenter.TeamManager.SaveTeamLocal(curTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(curTeam, false)
    return curTeam
end

function XUiSimulatedCombatNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    XLuaUiManager.Open("UiSimulatedCombatRoomCharacter", XTool.Clone(newRoomSingle.CurTeam.TeamData), charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end)
end

function XUiSimulatedCombatNewRoomSingle.HandleBtnMainUiClick()
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("SimulatedCombatBackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XLuaUiManager.RunMain()
    end)
end

function XUiSimulatedCombatNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SaveTeamLocal(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiSimulatedCombatNewRoomSingle.UpdateRoleModel(newRoomSingle, charId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel()
    local callback = function()
        newRoomSingle.LoadModelCount = newRoomSingle.LoadModelCount - 1
        if newRoomSingle.LoadModelCount <= 0 then
            newRoomSingle.BtnEnterFight:SetDisable(false)
        end
    end

    local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(charId)
    if not data then
        XLog.Error("no data ", charId)
        return
    end
    local robotCfg = XRobotManager.GetRobotTemplate(data.RobotId)
    roleModelPanel:UpdateRobotModel(data.RobotId, charId, callback, robotCfg.FashionId, robotCfg.WeaponId)
end

function XUiSimulatedCombatNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
end

function XUiSimulatedCombatNewRoomSingle.GetRealCharData(newRoomSingle)
    local teamData = newRoomSingle.CurTeam.TeamData
    local teamIdData = {}
    for pos, charId in pairs(teamData) do
        if charId and charId > 0 then
            local data = XDataCenter.FubenSimulatedCombatManager.GetCurStageMemberDataByCharId(charId)
            teamIdData[pos] = data and data.RobotId or 0
        else
            teamIdData[pos] = 0
        end
    end
    return teamIdData
end
return XUiSimulatedCombatNewRoomSingle