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
    end, newRoomSingle.CurrentStageId)
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
    if not eChara then return end
    local robotId = eChara and eChara:GetRobotId()
    local characterId = eChara and eChara:GetCharacterId()
    local robotConfig = XRobotManager.GetRobotTemplate(robotId)
    roleModelPanel:UpdateRobotModelNew(robotId, characterId, callback, robotConfig.FashionId, robotConfig.WeaponId)
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
    local eStage = XDataCenter.ExpeditionManager.GetEStageByStageId(newRoomSingle.CurrentStageId)
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
    for i = 1, maxCount do
        newRoomSingle["CharacterPets" .. i].gameObject:SetActiveEx(false)
    end
    newRoomSingle.PanelPartner = {}
    for i = 1, maxCount do
        newRoomSingle.PanelPartner[i] = newRoomSingle["CharacterPets" .. i]
    end
    for i = 1, #newRoomSingle.CurTeam.TeamData do
        local baseId = newRoomSingle.CurTeam.TeamData[i]
        if baseId > 0 then
            local eChara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(baseId)
            if not eChara then
                newRoomSingle.PanelPartner[i].gameObject:SetActiveEx(false)
            else
                local robotId = eChara:GetRobotId()
                local robotData = XRobotManager.GetRobotTemplate(robotId)
                local robotPartner = XRobotManager.GetRobotPartner(robotId)
                if robotData == nil then
                    newRoomSingle.PanelPartner[i].gameObject:SetActiveEx(false)
                else
                    newRoomSingle.PanelPartner[i].gameObject:SetActiveEx(true)
                    newRoomSingle:ShowPartner(newRoomSingle.PanelPartner[i], robotPartner, true)
                end
            end
        end
    end
end
return XUiExpeditionNewRoomSingle