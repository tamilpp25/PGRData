local XUiPanelFeature = require("XUi/XUiEscape/XUiPanelFeature")
local XUiTeamMember = require("XUi/XUiEscape/Layer/XUiTeamMember")

--大逃杀关卡弹窗
local XUiEscapeTeamTips = XLuaUiManager.Register(XLuaUi, "UiEscapeTeamTips")

function XUiEscapeTeamTips:OnAwake()
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitButtonCallBack()
    self.FeaturePanel = XUiPanelFeature.New(self.PanelBuffList)
    self.TeamMembers = {}
end

--layerId：EscapeLayer表的Id
function XUiEscapeTeamTips:OnStart(chapterId, layerId, stageId)
    self.ChapterId = chapterId
    self.StageId = stageId
    local layerState, challengeConditionDesc = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)

    self.TxtStageName.text = XFubenConfigs.GetStageName(stageId)

    local stageDesc = XDataCenter.FubenManager.GetStageDes(stageId)
    self.TxtExplain.text = XUiHelper.ConvertLineBreakSymbol(stageDesc)

    local stageFightEvent = XFubenConfigs.GetStageFightEventByStageId(stageId)
    self.FeaturePanel:Refresh(stageFightEvent and stageFightEvent.FightEventIds)
   
    local challengeStateDesc = ""
    local isStageClear = self.EscapeData:IsCurChapterStageClear(stageId)
    if isStageClear then
        challengeStateDesc = XUiHelper.GetText("ClearStage")
    elseif layerState == XEscapeConfigs.LayerState.Lock then
        challengeStateDesc = challengeConditionDesc
    end
    self.TxtTips.text = challengeStateDesc

    local team = XDataCenter.EscapeManager.GetTeam()
    local btnConfirmName = (not team:GetIsEmpty() and XTool.IsNumberValid(self.EscapeData:GetChapterId())) and
        XUiHelper.GetText("EscapeEnterFight") or XUiHelper.GetText("EscapeSelectRole")
    self.BtnConfirm:SetName(btnConfirmName)
    self.BtnConfirm.gameObject:SetActiveEx(not isStageClear and layerState == XEscapeConfigs.LayerState.Now)

    self.PanelTeam.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Now)
end

function XUiEscapeTeamTips:OnEnable()
    self:Refresh()
end

function XUiEscapeTeamTips:Refresh()
    local team = XDataCenter.EscapeManager.GetTeam()
    for i in ipairs(team:GetEntityIds()) do
        local teamMember = self.TeamMembers[i]
        if not teamMember then
            teamMember = XUiTeamMember.New(self["TeamMember" .. i], i, handler(self, self.OpenBattleRoleRoom))
            self.TeamMembers[i] = teamMember
        end
        teamMember:Refresh()
    end
end

function XUiEscapeTeamTips:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiEscapeTeamTips:OpenBattleRoleRoom()
    local team = XDataCenter.EscapeManager.GetTeam()
    if not team:GetIsEmpty() and XTool.IsNumberValid(self.EscapeData:GetChapterId()) then
        XUiManager.TipErrorWithKey("EscapeFightingNotUpdateTeam")
        return
    end
    XDataCenter.EscapeManager.SetCurSelectChapterId(self.ChapterId)
    XLuaUiManager.Open("UiBattleRoleRoom"
        , self.StageId
        , XDataCenter.EscapeManager.GetTeam()
        , require("XUi/XUiEscape/BattleRoom/XUiEscapeBattleRoleRoom")
    )
end

function XUiEscapeTeamTips:OnBtnConfirmClick()
    local team = XDataCenter.EscapeManager.GetTeam()
    if team:GetIsEmpty() or not XTool.IsNumberValid(self.EscapeData:GetChapterId()) then
        self:OpenBattleRoleRoom()
        return
    end

    local teamId = team:GetId()
    --检查队伍列表中所有需要的队伍是否均有队长/首发
    if not XTool.IsNumberValid(team:GetCaptainPosEntityId()) then
        XUiManager.TipText("StrongholdEnterFightTeamListNoCaptain")
        return
    end
    if not XTool.IsNumberValid(team:GetFirstFightPosEntityId()) then
        XUiManager.TipText("StrongholdEnterFightTeamListNoFirstPos")
        return
    end

    local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
end