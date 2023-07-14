local XUiGridQuickDeployMember = require("XUi/XUiStronghold/XUiGridQuickDeployMember")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridQuickDeployTeam = XClass(nil, "XUiGridQuickDeployTeam")

function XUiGridQuickDeployTeam:Ctor(ui, memberClickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGridList = {}
    self.MemberClickCb = memberClickCb

    XTool.InitUiObject(self)
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

    self.GridTeamMember.gameObject:SetActiveEx(false)
end

function XUiGridQuickDeployTeam:Refresh(teamList, teamId, groupId)
    self.TeamList = teamList
    self.TeamId = teamId
    local team = self:GetTeam()

    self.TextTitle.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)

    local gridList = self.MemberGridList
    local requireTeamMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    for memberIndex = 1, requireTeamMemberNum do
        local grid = gridList[memberIndex]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridTeamMember, self.PanelRole)
            local clickCb = function(paramGrid, paramMemberIndex)
                self.MemberClickCb(paramGrid, paramMemberIndex, self.TeamId)
            end

            grid = XUiGridQuickDeployMember.New(go, clickCb)
            gridList[memberIndex] = grid
        end

        grid:Refresh(teamList, teamId, memberIndex)

        local captainPos = team:GetCaptainPos()
        grid:RefreshCaptainPos(captainPos)

        --蓝色放到第一位
        if memberIndex == 2 then
            grid.Transform:SetAsFirstSibling()
        end

        grid.GameObject:SetActiveEx(true)

    end

    for index, tabBtn in pairs(self.TabGroup) do
        tabBtn.gameObject:SetActiveEx(index <= requireTeamMemberNum)
    end
    local firstFightPos = team:GetFirstPos()
    self.PanelTabFirst:SelectIndex(firstFightPos)

    for index, tabBtn in pairs(self.TabGroupCT) do
        tabBtn.gameObject:SetActiveEx(index <= requireTeamMemberNum)
    end
    local captainPos = team:GetCaptainPos()
    self.PanelTabCaptain:SelectIndex(captainPos)

    local isFinished = XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, teamId)
    self.TagDis.gameObject:SetActiveEx(isFinished)
end

function XUiGridQuickDeployTeam:OnClickTabCallBack(firstFightPos)
    if self.SelectedIndex and self.SelectedIndex == firstFightPos then
        return
    end
    self.SelectedIndex = firstFightPos

    local team = self:GetTeam()
    team:SetFirstPos(firstFightPos)

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGridQuickDeployTeam:OnClickTabCallBackCT(captainPos)
    if self.SelectedIndexCT and self.SelectedIndexCT == captainPos then
        return
    end
    self.SelectedIndexCT = captainPos

    local team = self:GetTeam()
    team:SetCaptainPos(captainPos)

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshCaptainPos(captainPos)
    end
end

function XUiGridQuickDeployTeam:GetTeam()
    return self.TeamList[self.TeamId]
end

return XUiGridQuickDeployTeam