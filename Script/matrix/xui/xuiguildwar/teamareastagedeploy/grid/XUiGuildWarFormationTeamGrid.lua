local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local MAX_GRID_NUM = 3

local XUiGuildWarFormationMemberGrid = require("XUi/XUiGuildWar/TeamAreaStageDeploy/Grid/XUiGuildWarFormationMemberGrid")
---@class XUiGuildWarFormationTeamGrid
local XUiGuildWarFormationTeamGrid = XClass(nil, "XUiGuildWarFormationTeamGrid")

---@param rootUi XUiGuildWarDeployPanelFormation
function XUiGuildWarFormationTeamGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.TabGroupFirstPos = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabFirst:Init(self.TabGroupFirstPos, function(tabIndex) self:OnClickTabFirstPos(tabIndex) end)

    self.TabGroupCaptain = {
        self.BtnCaptainRed,
        self.BtnCaptainBlue,
        self.BtnCaptainYellow,
    }
    self.PanelTabCaptain:Init(self.TabGroupCaptain, function(tabIndex) self:OnClickTabCaptain(tabIndex) end)

    self.GridTeamMember.gameObject:SetActiveEx(false)
end

function XUiGuildWarFormationTeamGrid:Refresh(index, TeamData)
    self.TeamData = TeamData
    self.teamIndex = index
    self.MemberGrids = {}
    self.TextTitle.text = CS.XTextManager.GetText("GuildWarFormationTeamTitle", index)
    local members = TeamData.Members
    local GridIndexToMemberIndex= {
        [1] = 2,
        [2] = 1,
        [3] = 3,
    }
    XUiHelper.RefreshCustomizedList(self.PanelRole, self.GridTeamMember, #members,
        function(index, go)
            local memberIndex = GridIndexToMemberIndex[index]
            self.MemberGrids[memberIndex] = XUiGuildWarFormationMemberGrid.New(go, self)
            self.MemberGrids[memberIndex]:Refresh(memberIndex, members[memberIndex])
        end
    )
    self.PanelTabFirst:SelectIndex(TeamData.FirstPos)
    self.PanelTabCaptain:SelectIndex(TeamData.Captain)
    self.PanelVictory.gameObject:SetActiveEx(not TeamData.IsCustom)
end

function XUiGuildWarFormationTeamGrid:OnClickTabFirstPos(firstFightPos)
    self.RootUi:OnBtnFirstPos(self.teamIndex, firstFightPos)
    for i, memberGrid in pairs(self.MemberGrids) do
        memberGrid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGuildWarFormationTeamGrid:OnClickTabCaptain(captainPos)
    self.RootUi:OnBtnCaptain(self.teamIndex, captainPos)
    for i, memberGrid in pairs(self.MemberGrids) do
        memberGrid:RefreshCaptainPos((captainPos))
    end
end

function XUiGuildWarFormationTeamGrid:OnMemberClick(memberIndex)
    if not self.TeamData.IsCustom then return end
    self.RootUi:OnMemberClick(self.teamIndex, memberIndex)
end

return XUiGuildWarFormationTeamGrid