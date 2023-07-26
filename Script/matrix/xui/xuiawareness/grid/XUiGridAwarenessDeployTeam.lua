
local XUiGridAwarenessDeployTeam = XClass(nil, "XUiGridAwarenessDeployTeam")
local XUiGridAwarenessDeployMember = require("XUi/XUiAwareness/Grid/XUiGridAwarenessDeployMember")

function XUiGridAwarenessDeployTeam:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAwarenessDeployTeam:InitComponent()
    self.MemberGridList = {}
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnReset.CallBack = function() self:OnBtnResetClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.ImgNotPassCondition.gameObject:SetActiveEx(false)
end

function XUiGridAwarenessDeployTeam:OnBtnFightClick()
    local allTeamHasMember, teamCharList, captainPosList, firstFightPosList = XDataCenter.FubenAwarenessManager.TryGetFightTeamCharList(self.ChapterId)
    if not allTeamHasMember then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignFightNoMember"))
        return
    end
    -- 设置队伍
    XDataCenter.FubenAwarenessManager.AwarenessSetTeamRequest(self.ChapterId, teamCharList, captainPosList, firstFightPosList, function()
        local targetIndex = self.TeamOrder
        local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
        local stageIdList = chapterData:GetStageId()
        local targetStageId = stageIdList[targetIndex]

        -- 进入战斗
        XDataCenter.FubenAwarenessManager.SetEnterLoadingData(targetIndex, teamCharList[targetIndex], chapterData)
        XDataCenter.FubenManager.EnterAwarenessFight(targetStageId, teamCharList[targetIndex], captainPosList[targetStageId], nil, nil, firstFightPosList[targetIndex])
    end)
end

function XUiGridAwarenessDeployTeam:OnBtnResetClick()
    XDataCenter.FubenAwarenessManager.AwarenessResetStageRequest(self.ChapterId, self.StageId , function ()
        self:RefreshVictoryState(self.StageId)
    end)
end

function XUiGridAwarenessDeployTeam:OnBtnLeaderClick()
    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(self.TeamInfoId)

    local team = {}
    local captainPos = teamData:GetLeaderIndex()
    local memberList = teamData:GetMemberList()
    for _, memberData in ipairs(memberList) do
        local characterId = memberData:GetCharacterId() or 0
        team[memberData:GetIndex()] = characterId
    end

    XLuaUiManager.Open("UiNewRoomSingleTip", self, team, captainPos, function(index)
        teamData:SetLeaderIndex(index)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED)
    end)
end

function XUiGridAwarenessDeployTeam:Refresh(chapterId, teamOrder, teamInfoId)
    self.TeamOrder = teamOrder
    self.TeamInfoId = teamInfoId
    self.ChapterId = chapterId

    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(teamInfoId)
    self.TxtTitle.text = CS.XTextManager.GetText("AssignTeamTitle", self.TeamOrder) -- 作战梯队1
    self.TxtRequireAbility.text = teamData:GetRequireAbility()
    self.TxtFightTips.text = teamData:GetDesc()
    self.TxtLeaderSkill.text = teamData:GetLeaderSkillDesc()

    for i = 1, teamData:GetNeedCharacter() do
        local grid = self.MemberGridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridDeployMember)
            ui.transform:SetParent(self.PanelDeployMembers, false)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridAwarenessDeployMember.New(self, ui)
            self.MemberGridList[i] = grid
        end
        grid:Refresh(chapterId, teamOrder, teamData, i)
    end

    local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(chapterId)
    local stageId = chapterData:GetStageId()[teamOrder]
    self.StageId = stageId
    self:RefreshVictoryState(self.StageId)
end

function XUiGridAwarenessDeployTeam:RefreshVictoryState(stageId)
    local isFinish = XDataCenter.FubenAwarenessManager.CheckStageFinish(stageId)
    self.PanelVictory.gameObject:SetActiveEx(isFinish)
end

return XUiGridAwarenessDeployTeam