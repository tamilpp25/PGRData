-- 双人下场玩法出战界面代理
local XUiCoupleCombatNewRoomSingle = {}
local XUiPanelFeature = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelFeature")

local TeamMemberMaxCount = 2    -- 双人玩法 不允许上超过2个人

local UpdateAddIcon = function(newRoomSingle)
    local isShowAddIcon
    local curTeamMemberCount = 0
    for _, charId in ipairs(newRoomSingle.CurTeam.TeamData) do
        if charId > 0 then
            curTeamMemberCount = curTeamMemberCount + 1
        end
    end
    for i, charId in ipairs(newRoomSingle.CurTeam.TeamData) do
        isShowAddIcon = curTeamMemberCount < TeamMemberMaxCount or XTool.IsNumberValid(charId)
        newRoomSingle["ImageAddIcon" .. i].gameObject:SetActiveEx(isShowAddIcon)
        newRoomSingle["ImgNormal" .. i].gameObject:SetActiveEx(isShowAddIcon)
        newRoomSingle["ImgIconProhibit" .. i].gameObject:SetActiveEx(not isShowAddIcon)
    end
end

function XUiCoupleCombatNewRoomSingle.InitEditBattleUi(newRoomSingle)
    newRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(newRoomSingle.CurrentStageId)

    for _, v in ipairs(stageInterInfo.Intro) do
        local item = CS.UnityEngine.Object.Instantiate(newRoomSingle.GridIntroDesc, newRoomSingle.PanelIntroContent)  -- 复制一个item
        item:Find("Text"):GetComponent("Text").text = v
    end
    newRoomSingle.GridIntroDesc.gameObject:SetActiveEx(false)
    UpdateAddIcon(newRoomSingle)
end

function XUiCoupleCombatNewRoomSingle.InitEditBattleUiCharacterInfo(newRoomSingle)
    newRoomSingle.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    newRoomSingle.IsShowCharacterInfo = 0
    newRoomSingle:RefreshCharacterTypeTips()
end

function XUiCoupleCombatNewRoomSingle.GetBattleTeamData(newRoomSingle)
    local stageId = newRoomSingle.CurrentStageId
    local teamData = XDataCenter.TeamManager.LoadTeamLocal(stageId)
    teamData = XTool.Clone(teamData)
    for i, charId in ipairs(teamData.TeamData or {}) do
        if XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(stageId, charId) or not XFubenCoupleCombatConfig.CheckRobotIsUse(stageId, charId) then
            teamData.TeamData[i] = 0
        end
    end
    return teamData
end

function XUiCoupleCombatNewRoomSingle.GetTeamCaptainId(stageId)
    local teamData = XDataCenter.TeamManager.LoadTeamLocal(stageId)
    return teamData.TeamData[teamData.CaptainPos]
end

function XUiCoupleCombatNewRoomSingle.GetTeamFirstFightId(stageId)
    local teamData = XDataCenter.TeamManager.LoadTeamLocal(stageId)
    return teamData.TeamData[teamData.FirstFightPos]
end

function XUiCoupleCombatNewRoomSingle.HandleCharClick(newRoomSingle, charPos)
    if newRoomSingle.CurTeam.TeamData[charPos] == 0 then
        local curTeamMemberCount = 0
        for _, charId in ipairs(newRoomSingle.CurTeam.TeamData) do
            if charId > 0 then
                curTeamMemberCount = curTeamMemberCount + 1
            end
        end

        if curTeamMemberCount >= TeamMemberMaxCount then
            XUiManager.TipText("CoupleCombatTeamOverDoubleTip", XUiManager.UiTipType.Wrong)
            return
        end
    end

    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local robotIdList = XDataCenter.FubenCoupleCombatManager.GetChapterRobotIdsByStageId(newRoomSingle.CurrentStageId)
    local characterLimitType = newRoomSingle:GetCharacterLimitType()
    local stageId = newRoomSingle.CurrentStageId
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    XLuaUiManager.Open("UiRoomCharacter", teamData, charPos, function(resTeam)
        newRoomSingle:UpdateTeam(resTeam)
    end, XDataCenter.FubenManager.StageType.CoupleCombat, characterLimitType, {RobotIdList = robotIdList, StageId = stageId, LimitBuffId = limitBuffId, NotReset = true})
end

function XUiCoupleCombatNewRoomSingle.HandlePartnerClick(newRoomSingle, charPos)
    local teamData = XTool.Clone(newRoomSingle.CurTeam.TeamData)
    local entityId = teamData[charPos]
    if XEntityHelper.GetIsRobot(entityId) then
        XUiManager.TipErrorWithKey("RobotParnerTips")
        return
    end
    XDataCenter.PartnerManager.GoPartnerCarry(entityId, false)
end

function XUiCoupleCombatNewRoomSingle.UpdateFeatureInfo(newRoomSingle, MAX_CHAR_COUNT)
    local teamData = newRoomSingle.CurTeam.TeamData
    local matchDic, featureFullList = XDataCenter.FubenCoupleCombatManager.GetFeatureMatch(newRoomSingle.CurrentStageId, teamData)
    if not newRoomSingle.PanelFeature then
        newRoomSingle.PanelFeature = {}
        newRoomSingle.PanelFeature[0] = XUiPanelFeature.New(newRoomSingle, newRoomSingle.PanelStageFeature)
        for i = 1, MAX_CHAR_COUNT do
            newRoomSingle.PanelFeature[i] = XUiPanelFeature.New(newRoomSingle, newRoomSingle["CharacterFeature" .. i])
        end
    end

    for i ,v in pairs(newRoomSingle.PanelFeature) do
        v:Refresh(featureFullList[i], matchDic, XRobotManager.GetCharacterId(teamData[i]))
    end
end

function XUiCoupleCombatNewRoomSingle.UpdateTeam(newRoomSingle)
    XDataCenter.TeamManager.SaveTeamLocal(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
    XDataCenter.TeamManager.SetPlayerTeam(newRoomSingle.CurTeam, false)

    UpdateAddIcon(newRoomSingle)
end

function XUiCoupleCombatNewRoomSingle.CheckEnterFight(newRoomSingle, curTeam)
    local curTeamMemberCount = 0
    for _, charId in ipairs(curTeam.TeamData) do
        if charId > 0 then
            curTeamMemberCount = curTeamMemberCount + 1
        end
    end

    -- 双人玩法 只能上2个人
    if curTeamMemberCount == TeamMemberMaxCount then
        return true
    else
        XUiManager.TipText("CoupleCombatTeamLessDoubleTip", XUiManager.UiTipType.Wrong)
        return false
    end
end

function XUiCoupleCombatNewRoomSingle.OnResetEvent(newRoomSingle)
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ActivityMainLineEnd"))
end

function XUiCoupleCombatNewRoomSingle.SetPanelRogueLike(newRoomSingleUi)
    newRoomSingleUi.PanelRogueLike.gameObject:SetActiveEx(true)
    newRoomSingleUi:SetRogueLikeCharacterTips()
end

function XUiCoupleCombatNewRoomSingle.SetRogueLikeCharacterTips(newRoomSingleUi)
    newRoomSingleUi.PanelEnduranceRogueLike.gameObject:SetActiveEx(false)
    newRoomSingleUi.TxtTeamMemberCount.text = CS.XTextManager.GetText("CoupleCombatTeamNeedCount")
end

-- 设置提示文本
function XUiCoupleCombatNewRoomSingle.RefreshCharacterTypeTips(newRoomSingleUi)
    local characterLimitType = newRoomSingleUi:GetCharacterLimitType()
    local characterTypeList = newRoomSingleUi:GetCurTeamCharacterTypeList()
    local text = XFubenConfigs.GetStageMixCharacterLimitTips(characterLimitType, characterTypeList)
    newRoomSingleUi.TxtCharacterLimit.text = text
    newRoomSingleUi.PanelCharacterLimit.gameObject:SetActiveEx(true)
end

return XUiCoupleCombatNewRoomSingle