local XUiGridQuickDeployMember = require("XUi/XUiTheatre/QuickDeploy/XUiGridQuickDeployMember")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local MemberMaxNum = XEntityHelper.TEAM_MAX_ROLE_COUNT

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
    self.PanelTabFirst:Init(self.TabGroup, function(tabIndex) self:OnClickTabFirstCallBack(tabIndex) end)

    self.TabGroupCT = {
        self.BtnCaptainRed,
        self.BtnCaptainBlue,
        self.BtnCaptainYellow,
    }
    self.PanelTabCaptain:Init(self.TabGroupCT, function(tabIndex) self:OnClickTabCaptainCallBack(tabIndex) end)

    self.GridTeamMember.gameObject:SetActiveEx(false)
    self.CurrentAdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.CurrentAdventureManager:GetAdventureMultiDeploy()
end

function XUiGridQuickDeployTeam:Refresh(teamList, teamId)
    self.TeamList = teamList
    self.TeamId = teamId
    local team = self:GetTeam()

    self.TextTitle.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)

    local gridList = self.MemberGridList
    for memberIndex = 1, MemberMaxNum do
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

    local firstFightPos = team:GetFirstFightPos()
    self.PanelTabFirst:SelectIndex(firstFightPos)

    local captainPos = team:GetCaptainPos()
    self.PanelTabCaptain:SelectIndex(captainPos)

    local isFinished = self.AdventureMultiDeploy:GetMultipleTeamIsWin(teamId)
    self.TagDis.gameObject:SetActiveEx(isFinished)
end

function XUiGridQuickDeployTeam:OnClickTabFirstCallBack(firstFightPos)
    if self.SelectedFirstFightPos and self.SelectedFirstFightPos == firstFightPos then
        return
    end
    self.SelectedFirstFightPos = firstFightPos

    local team = self:GetTeam()
    team:UpdateFirstFightPos(firstFightPos)

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGridQuickDeployTeam:OnClickTabCaptainCallBack(captainPos)
    if self.SelectedCaptainPos and self.SelectedCaptainPos == captainPos then
        return
    end
    self.SelectedCaptainPos = captainPos

    local team = self:GetTeam()
    team:UpdateCaptainPos(captainPos)

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