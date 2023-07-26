local XUiGridRiftQuickDeployTeam = XClass(nil, "XUiGridRiftQuickDeployTeam")

local XUiGridRiftQuickDeployMember = require("XUi/XUiRift/Grid/XUiGridRiftQuickDeployMember")
local requireTeamMemberNum = 3

function XUiGridRiftQuickDeployTeam:Ctor(ui, memberClickCb)
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

function XUiGridRiftQuickDeployTeam:Refresh(teamList, index)
    self.TeamList = teamList
    self.XTeam = teamList[index]

    self.TextTitle.text = CsXTextManagerGetText("StrongholdTeamTitle", index)

    for memberIndex = 1, requireTeamMemberNum do
        local grid = self.MemberGridList[memberIndex]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridTeamMember, self.PanelRole)
            local clickCb = function(paramGrid)
                self.MemberClickCb(paramGrid, memberIndex, index)
            end

            grid = XUiGridRiftQuickDeployMember.New(go, memberIndex, clickCb)
            self.MemberGridList[memberIndex] = grid
        end
        grid:Refresh(self.XTeam, memberIndex)

        -- local captainPos = self.XTeam:GetCaptainPos()
        -- grid:RefreshCaptainPos(captainPos)

        --蓝色放到第一位
        if memberIndex == 2 then
            grid.Transform:SetAsFirstSibling()
        end
        grid.GameObject:SetActiveEx(true)
    end

    -- for index, tabBtn in pairs(self.TabGroup) do
    --     tabBtn.gameObject:SetActiveEx(index <= requireTeamMemberNum)
    -- end
    local firstFightPos = self.XTeam:GetFirstFightPos()
    self.PanelTabFirst:SelectIndex(firstFightPos)

    -- for index, tabBtn in pairs(self.TabGroupCT) do
    --     tabBtn.gameObject:SetActiveEx(index <= requireTeamMemberNum)
    -- end
    local captainPos = self.XTeam:GetCaptainPos()
    self.PanelTabCaptain:SelectIndex(captainPos)
    
    -- 压制成功
    -- local isFinished = XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, teamId)
    self.TagDis.gameObject:SetActiveEx(false)
end

function XUiGridRiftQuickDeployTeam:OnClickTabCallBack(firstFightPos)
    if self.SelectedIndex and self.SelectedIndex == firstFightPos then
        return
    end
    self.SelectedIndex = firstFightPos

    local gridNum = #self.MemberGridList
    for index = 1, gridNum do
        local grid = self.MemberGridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGridRiftQuickDeployTeam:OnClickTabCallBackCT(captainPos)
    if self.SelectedIndexCT and self.SelectedIndexCT == captainPos then
        return
    end
    self.SelectedIndexCT = captainPos

    local gridNum = #self.MemberGridList
    for index = 1, gridNum do
        local grid = self.MemberGridList[index]
        grid:RefreshCaptainPos(captainPos)
    end
end

function XUiGridRiftQuickDeployTeam:SaveCb()
    self.XTeam:UpdateFirstFightPos(self.SelectedIndex)
    self.XTeam:UpdateCaptainPos(self.SelectedIndexCT)
end

return XUiGridRiftQuickDeployTeam