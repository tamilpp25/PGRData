
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
    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.ImgNotPassCondition.gameObject:SetActiveEx(false)
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

    -- self.ImgNotPassCondition.gameObject:SetActiveEx(not teamData:IsEnoughAbility())
end

return XUiGridAssignDeployTeam