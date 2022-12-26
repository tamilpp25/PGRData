-- 虚像地平线出战界面代理
local XUiExpeditionNewRoomSingle = {}

function XUiExpeditionNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    newRoomSingle.PanelCharacterLimit.gameObject:SetActiveEx(false)
end

function XUiExpeditionNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    newRoomSingle.IsShowCharacterInfo = 0
end

function XUiExpeditionNewRoomSingle.GetEditBattleUiCaptainId(newRoomSingle)
    local eChara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(newRoomSingle.CurTeam.TeamData[newRoomSingle.CurTeam.CaptainPos])
    return eChara and eChara:GetRobotId() or 0
end

function XUiExpeditionNewRoomSingle.GetBattleTeamData(newRoomSingle)
    return XDataCenter.ExpeditionManager.GetExpeditionTeam()
end

function XUiExpeditionNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    XLuaUiManager.Open("UiExpeditionRoomCharacter", XTool.Clone(newRoomSingle.CurTeam.TeamData), charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end)
end

function XUiExpeditionNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SetExpeditionTeamData(newRoomSingle.CurTeam)
end

function XUiExpeditionNewRoomSingle.UpdateRoleModel(newRoomSingle, charId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel()
    local callback = function()
        newRoomSingle.LoadModelCount = newRoomSingle.LoadModelCount - 1
        if newRoomSingle.LoadModelCount <= 0 then
            newRoomSingle.BtnEnterFight:SetDisable(false)
        end
    end
    local eChara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(charId)
    local robotId = eChara and eChara:GetRobotId() or 0
    local characterId = eChara and eChara:GetCharacterId()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    roleModelPanel:UpdateRobotModel(robotId, characterId, callback, robotCfg.FashionId, robotCfg.WeaponId)
end

function XUiExpeditionNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
end

function XUiExpeditionNewRoomSingle.SetEditBattleUiTeam(newRoomSingle)
    XDataCenter.TeamManager.SetExpeditionTeamData(newRoomSingle.CurTeam)
end

function XUiExpeditionNewRoomSingle.GetRealCharData(newRoomSingle)
    local teamData = newRoomSingle.CurTeam.TeamData
    local teamIdData = {}
    for pos, eBaseId in pairs(teamData) do
        if eBaseId and eBaseId > 0 then
            local eChara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(eBaseId)
            teamIdData[pos] = eChara and eChara:GetRobotId() or 0
        else
            teamIdData[pos] = 0
        end
    end
    return teamIdData
end

function XUiExpeditionNewRoomSingle.UpdateFightControl(newRoomSingle, curTeam)
    local eStageId = XExpeditionConfig.GetEStageByStageId(newRoomSingle.CurrentStageId).Id
    local eStage = XDataCenter.ExpeditionManager.GetEStageByEStageId(eStageId)
    newRoomSingle.FightControlResult = newRoomSingle.FightControl:UpdateByTextAndWarningLevel(
    eStage:GetStageIsDanger(curTeam),
    CS.XTextManager.GetText("ExpeditionWarningControlName"),
    eStage:GetRecommentStar(),
    CS.XTextManager.GetText("ExpeditionWarningCurNumText", XDataCenter.ExpeditionManager.GetTeamAverageStar())
    )
end

function XUiExpeditionNewRoomSingle.LimitCharacter(newRoomSingle, curTeam)

end

function XUiExpeditionNewRoomSingle.UpdatePartnerInfo(newRoomSingle, maxCount)
    
end
return XUiExpeditionNewRoomSingle