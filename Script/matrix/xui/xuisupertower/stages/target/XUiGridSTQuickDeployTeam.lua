local XUiGridSTQuickDeployMember = require("XUi/XUiSuperTower/Stages/Target/XUiGridSTQuickDeployMember")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridSTQuickDeployTeam = XClass(nil, "XUiGridSTQuickDeployTeam")

function XUiGridSTQuickDeployTeam:Ctor(ui, memberClickCb)
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

function XUiGridSTQuickDeployTeam:Refresh(stageIndex, stStage, team)
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local memberEntityIdList = team:GetEntityIds()
    self.Team = team
    
    local memberNum = stStage:GetMemberCountByIndex(stageIndex)
    for memberIndex = 1, memberNum do
        local grid = self.MemberGridList[memberIndex]
        if not grid then
            local go = CSObjectInstantiate(self.GridTeamMember, self.PanelRole)
            local clickCb = function(paramGrid, paramMemberIndex)
                self.MemberClickCb(paramGrid, paramMemberIndex, stageIndex)
            end

            grid = XUiGridSTQuickDeployMember.New(go, clickCb)
            self.MemberGridList[memberIndex] = grid
        end
        
        local memberEntityId = memberEntityIdList[memberIndex] or 0
        local memberRole = roleManager:GetRole(memberEntityId)
        grid:Refresh(memberRole, memberIndex)

        --local captainPos = team:GetCaptainPos()
        --grid:RefreshCaptainPos(captainPos)

        --local captainPos = team:GetFirstFightPos()
        --grid:RefreshFirstFightPos(captainPos)
        --蓝色放到第一位
        if memberIndex == 2 then
            grid.Transform:SetAsFirstSibling()
        end
        grid.GameObject:SetActiveEx(true)
    end

    for index = memberNum + 1, #self.MemberGridList do
        self.MemberGridList[index].GameObject:SetActiveEx(false)
    end
    
    for index, tabBtn in pairs(self.TabGroup) do
        tabBtn.gameObject:SetActiveEx(index <= memberNum)
    end
    local firstFightPos = team:GetFirstFightPos()
    self.PanelTabFirst:SelectIndex(firstFightPos)

    for index, tabBtn in pairs(self.TabGroupCT) do
        tabBtn.gameObject:SetActiveEx(index <= memberNum)
    end
    local captainPos = team:GetCaptainPos()
    self.PanelTabCaptain:SelectIndex(captainPos)
    
    self.TextTitle.text = CSTextManagerGetText("STFightLoadingTeamText", stageIndex)
end

function XUiGridSTQuickDeployTeam:OnClickTabCallBack(firstFightPos)
    if self.SelectedIndex and self.SelectedIndex == firstFightPos then
        return
    end
    self.SelectedIndex = firstFightPos

    self.Team:UpdateFirstFightPos(firstFightPos)
    
    local gridNum = #self.MemberGridList
    for index = 1, gridNum do
        local grid = self.MemberGridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGridSTQuickDeployTeam:OnClickTabCallBackCT(captainPos)
    if self.SelectedIndexCT and self.SelectedIndexCT == captainPos then
        return
    end
    self.SelectedIndexCT = captainPos

    self.Team:UpdateCaptainPos(captainPos)

    local gridNum = #self.MemberGridList
    for index = 1, gridNum do
        local grid = self.MemberGridList[index]
        grid:RefreshCaptainPos(captainPos)
    end
end

return XUiGridSTQuickDeployTeam