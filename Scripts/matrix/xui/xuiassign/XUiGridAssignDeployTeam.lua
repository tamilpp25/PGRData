
local XUiGridAssignDeployTeam = XClass(nil, "XUiGridAssignDeployTeam")

local XUiGridAssignDeployMember = require("XUi/XUiAssign/XUiGridAssignDeployMember")

function XUiGridAssignDeployTeam:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAssignDeployTeam:InitComponent()
    self.MemberGridList = {}
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnReset.CallBack = function() self:OnBtnResetClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.ImgNotPassCondition.gameObject:SetActiveEx(false)
end

function XUiGridAssignDeployTeam:OnBtnFightClick()
    local allTeamHasMember, teamCharList, captainPosList, firstFightPosList = XDataCenter.FubenAssignManager.TryGetFightTeamCharList(self.GroupId)
    if not allTeamHasMember then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignFightNoMember"))
        return
    end
    -- 设置队伍
    XDataCenter.FubenAssignManager.AssignSetTeamRequest(self.GroupId, teamCharList, captainPosList, firstFightPosList, function()
        local targetIndex = self.TeamOrder
        local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
        local stageIdList = groupData:GetStageId()
        local targetStageId = stageIdList[targetIndex]

        -- 进入战斗
        local chapterId = XFubenAssignConfigs.GetChapterIdByGroupId(self.GroupId)
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        XDataCenter.FubenAssignManager.SetEnterLoadingData(targetIndex, teamCharList[targetIndex], groupData, chapterData)
        XDataCenter.FubenManager.EnterAssignFight(targetStageId, teamCharList[targetIndex], captainPosList[targetStageId], nil, nil, firstFightPosList[targetIndex])
    end)
end

function XUiGridAssignDeployTeam:OnBtnResetClick()
    XDataCenter.FubenAssignManager.AssignResetStageRequest(self.GroupId, self.StageId , function ()
        self:RefreshVictoryState(self.StageId)
    end)
end

function XUiGridAssignDeployTeam:OnBtnLeaderClick()
    local teamData = XDataCenter.FubenAssignManager.GetTeamDataById(self.TeamInfoId)

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

function XUiGridAssignDeployTeam:Refresh(groupId, teamOrder, teamInfoId)
    self.TeamOrder = teamOrder
    self.TeamInfoId = teamInfoId
    self.GroupId = groupId

    local teamData = XDataCenter.FubenAssignManager.GetTeamDataById(teamInfoId)
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
            grid = XUiGridAssignDeployMember.New(self, ui)
            self.MemberGridList[i] = grid
        end
        grid:Refresh(groupId, teamOrder, teamData, i)
    end

    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(groupId)
    local stageId = groupData:GetStageId()[teamOrder]
    self.StageId = stageId
    self:RefreshVictoryState(self.StageId)
    -- self.ImgNotPassCondition.gameObject:SetActiveEx(not teamData:IsEnoughAbility())
end

function XUiGridAssignDeployTeam:RefreshVictoryState(stageId)
    local isFinish = XDataCenter.FubenAssignManager.CheckStageFinish(stageId)
    self.PanelVictory.gameObject:SetActiveEx(isFinish)
end

return XUiGridAssignDeployTeam