-- 双人下场玩法出战界面代理
local XUiCoupleCombatNewRoomSingle = {}
local XUiPanelFeature = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelFeature")

function XUiCoupleCombatNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    newRoomSingle.ImgSkillLine.gameObject:SetActiveEx(false)
    newRoomSingle.PanelEnvIntro.gameObject:SetActiveEx(true)
    newRoomSingle.DarkBottom.gameObject:SetActiveEx(true)
    local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(newRoomSingle.CurrentStageId)

    for _, v in ipairs(stageInterInfo.Intro) do
        local item = CS.UnityEngine.Object.Instantiate(newRoomSingle.GridIntroDesc, newRoomSingle.PanelIntroContent)  -- 复制一个item
        item:Find("Text"):GetComponent("Text").text = v
    end
    newRoomSingle.GridIntroDesc.gameObject:SetActiveEx(false)
end

function XUiCoupleCombatNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    newRoomSingle.IsShowCharacterInfo = 0
end

function XUiCoupleCombatNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local curTeam =  XTool.Clone(XDataCenter.TeamManager.EmptyTeam)
    --XDataCenter.TeamManager.SaveTeamLocal(curTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(curTeam, false)
    return curTeam
end

function XUiCoupleCombatNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    if newRoomSingle.CurTeam.TeamData[charPos] == 0 then
        local curTeamMemberCount = 0
        for _, charId in ipairs(newRoomSingle.CurTeam.TeamData) do
            if charId > 0 then
                curTeamMemberCount = curTeamMemberCount + 1
            end
        end
        -- 双人玩法 不允许上超过2个人
        if curTeamMemberCount >= 2 then
            XUiManager.TipText("CoupleCombatTeamOverDoubleTip", XUiManager.UiTipType.Wrong)
            return
        end
    end

    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.FubenCoupleCombatManager.GetRobotByStage(newRoomSingle.CurrentStageId)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.CoupleCombat, nil, {IsRobotOnly = true, RobotIdList = robotIdList, StageId = newRoomSingle.CurrentStageId})
end

function XUiCoupleCombatNewRoomSingle.UpdateFeatureInfo(newRoomSingle, MAX_CHAR_COUNT)
    local matchDic, featureFullList = XDataCenter.FubenCoupleCombatManager.GetFeatureMatch(newRoomSingle.CurrentStageId, newRoomSingle.CurTeam.TeamData)
    if not newRoomSingle.PanelFeature then
        newRoomSingle.PanelFeature = {}
        newRoomSingle.PanelFeature[0] = XUiPanelFeature.New(newRoomSingle, newRoomSingle.PanelStageFeature)
        for i = 1, MAX_CHAR_COUNT do
            newRoomSingle.PanelFeature[i] = XUiPanelFeature.New(newRoomSingle, newRoomSingle["CharacterFeature" .. i])
        end
    end
    for i ,v in pairs(newRoomSingle.PanelFeature) do
        v:Refresh(featureFullList[i], matchDic)
    end
end

function XUiCoupleCombatNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SaveTeamLocal(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)
end

function XUiCoupleCombatNewRoomSingle.CheckEnterFight(newRoomSingle, curTeam)
    local curTeamMemberCount = 0
    for _, charId in ipairs(curTeam.TeamData) do
        if charId > 0 then
            curTeamMemberCount = curTeamMemberCount + 1
        end
    end

    -- 双人玩法 只能上2个人
    if curTeamMemberCount == 2 then
        return true
    else
        XUiManager.TipText("CoupleCombatTeamLessDoubleTip", XUiManager.UiTipType.Wrong)
        return false
    end
end

function XUiCoupleCombatNewRoomSingle.GetRealCharData(newRoomSingle)
    local teamData = newRoomSingle.CurTeam.TeamData
    local teamIdData = {}
    for pos, charId in pairs(teamData) do
        if charId and charId > 0 then
            local data = XFubenCoupleCombatConfig.GetRobotInfo(charId)
            teamIdData[pos] = data and data.RobotId or 0
        else
            teamIdData[pos] = 0
        end
    end
    return teamIdData
end

function XUiCoupleCombatNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
end

return XUiCoupleCombatNewRoomSingle