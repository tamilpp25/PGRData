local XUiGridAwarenessFormationTeam = XClass(nil, "XUiGridAwarenessFormationTeam")

local XUiGridAwarenessFormationMember = require("XUi/XUiAwareness/Grid/XUiGridAwarenessFormationMember")

XUiGridAwarenessFormationTeam.BtnTabIndex = {
    Blue = 2,
    Red = 1, -- 注意：队伍位置为1，但显示位置在中间
    Yellow = 3,
}

function XUiGridAwarenessFormationTeam:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
    self:InitButtonGroup()
end

function XUiGridAwarenessFormationTeam:InitComponent()
    self.MemberGridList = {}
    self.GridTeamMember.gameObject:SetActiveEx(false)
end

function XUiGridAwarenessFormationTeam:GetMemberGrid(index)
    local grid = self.MemberGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridTeamMember)
        obj.transform:SetParent(self.PanelRole, false)
        grid = XUiGridAwarenessFormationMember.New(self, obj)
        self.MemberGridList[index] = grid
    end
    return grid
end

function XUiGridAwarenessFormationTeam:ResetMemberGridList(len)
    if #self.MemberGridList > len then
        for _ = len + 1, #self.MemberGridList do
            self.MemberGridList.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridAwarenessFormationTeam:InitButtonGroup()
    self.TabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabFirst:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    self.TabGroupCT = {
        self.BtnCaptainRed,
        self.BtnCaptainBlue,
        self.BtnCaptainYellow,
    }
    self.PanelTabCaptain:Init(self.TabGroupCT, function(tabIndex) self:OnClickTabCallBackCT(tabIndex) end)
end

function XUiGridAwarenessFormationTeam:Refresh(chapterId, teamOrder, teamInfoId)
    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(teamInfoId)
    local lastMemberNum = self.MemberNum

    self.TeamOrder = teamOrder
    self.TeamInfoId = teamInfoId
    self.MemberNum = teamData:GetNeedCharacter()

    self.TextTitle.text = CS.XTextManager.GetText("AssignTeamTitle", self.TeamOrder) -- 作战梯队1

    self:ResetMemberGridList(self.MemberNum)
    for i = 1, self.MemberNum do
        local grid = self:GetMemberGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(chapterId, teamOrder, teamData, i)
    end

    local stageId = teamInfoId
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamInfoId)
    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
    else
        local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
        self.ImgRequireCharacter:SetSprite(icon)

        local name = XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
        self.TxtRequireCharacter.text = name

        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    --队长/首发
    for i = 1, #self.TabGroup do
        self.TabGroup[i].gameObject:SetActiveEx(i <= self.MemberNum)
    end
    local firstFightPos = teamData:GetFirstFightIndex()
    self.PanelTabFirst:SelectIndex(firstFightPos)

    for i = 1, #self.TabGroupCT do
        self.TabGroupCT[i].gameObject:SetActiveEx(i <= self.MemberNum)
    end
    local captainPos = teamData:GetLeaderIndex()
    self.PanelTabCaptain:SelectIndex(captainPos)
end

function XUiGridAwarenessFormationTeam:RefreshMemberEffect(state)
    for i = 1, self.MemberNum do
        local grid = self:GetMemberGrid(i)
        grid:RefreshEffect(state)
    end
end

function XUiGridAwarenessFormationTeam:OnClickTabCallBack(index)
    if self.SelectedIndex and self.SelectedIndex == index then
        return
    end
    self.SelectedIndex = index

    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(self.TeamInfoId)
    teamData:SetFirstFightIndex(index)

    for i = 1, self.MemberNum do
        local grid = self:GetMemberGrid(i)
        grid:RefreshLeaderIndex()
    end
end

function XUiGridAwarenessFormationTeam:OnClickTabCallBackCT(index)
    if self.SelectedIndexCT and self.SelectedIndexCT == index then
        return
    end
    self.SelectedIndexCT = index

    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(self.TeamInfoId)
    teamData:SetLeaderIndex(index)

    for i = 1, self.MemberNum do
        local grid = self:GetMemberGrid(i)
        grid:RefreshLeaderIndex()
    end
end

return XUiGridAwarenessFormationTeam