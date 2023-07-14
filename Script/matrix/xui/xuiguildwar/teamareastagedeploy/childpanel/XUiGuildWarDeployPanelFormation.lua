
local XUiGuildWarFormationTeamGrid = require("XUi/XUiGuildWar/TeamAreaStageDeploy/Grid/XUiGuildWarFormationTeamGrid")

---@class XUiGuildWarDeployPanelFormation
local XUiGuildWarDeployPanelFormation = XClass(nil, "XUiGuildWarDeployPanelFormation")

function XUiGuildWarDeployPanelFormation:Ctor(ui, posChangeCallback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.PosChangeCallback = posChangeCallback
    XTool.InitUiObject(self)
    self.GridFormationTeam.gameObject:SetActiveEx(false)
    CsXUiHelper.RegisterClickEvent(self.BtnClose,function() self.Hide() end)
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirm()
    end
end

---@param areaRootNode XTerm3SecretRootGWNode
function XUiGuildWarDeployPanelFormation:Show(areaRootNode)
    self.IsXteamDirty = false --记录是否把当前界面数据 上传到队伍Entity数据
    self.GameObject:SetActiveEx(true)
    self.SelectMember = nil --选中的成员格
    self.XBuild = areaRootNode:GetTeamBuild()
    local xTeams = self.XBuild:GetXTeams()
    self.TeamDatas = {}
    for index, team in pairs(xTeams) do
        self.TeamDatas[index] = {}
        self.TeamDatas[index].Captain = team:GetCaptainPos()
        self.TeamDatas[index].FirstPos = team:GetFirstFightPos()
        self.TeamDatas[index].IsCustom = team:GetTeamIsCustom()
        self.TeamDatas[index].Members = {}
        for mPos, member in pairs(team:GetMembers()) do
            self.TeamDatas[index].Members[mPos] = member
        end
    end
    self.TeamGrid = {}
    XUiHelper.RefreshCustomizedList(self.PanelFormationTeamContent, self.GridFormationTeam, #xTeams, 
        function(index, go)
            self.TeamGrid[index] = XUiGuildWarFormationTeamGrid.New(go, self)
        end
    )
    self:UpdateView()
end

function XUiGuildWarDeployPanelFormation:UpdateView()
    for index,teamGrid in pairs(self.TeamGrid) do
        teamGrid:Refresh(index, self.TeamDatas[index])
    end
end

function XUiGuildWarDeployPanelFormation:OnBtnFirstPos(teamIndex,pos)
    self.TeamDatas[teamIndex].FirstPos = pos
end

function XUiGuildWarDeployPanelFormation:OnBtnCaptain(teamIndex,pos)
    self.TeamDatas[teamIndex].Captain = pos
end



function XUiGuildWarDeployPanelFormation:OnMemberClick(teamIndex, memberIndex)
    if not self.TeamDatas[teamIndex].IsCustom then return end
    --选中
    if self.SelectMember == nil then
        self.SelectMember = {teamIndex, memberIndex}
        self.TeamGrid[teamIndex].MemberGrids[memberIndex]:SetSelect(true)
        return
    end
    --取消选中
    if self.SelectMember[1] == teamIndex and self.SelectMember[2] == memberIndex then
        self.SelectMember = nil
        self.TeamGrid[teamIndex].MemberGrids[memberIndex]:SetSelect(false)
        return
    end
    ---@type XGuildWarMember
    local member1 = self.TeamDatas[teamIndex].Members[memberIndex]
    ---@type XGuildWarMember
    local member2 = self.TeamDatas[self.SelectMember[1]].Members[self.SelectMember[2]]
    --检查重复支援
    if member1:IsAssitant() then
        for index, member in pairs(self.TeamDatas[self.SelectMember[1]].Members) do
            if not index == self.SelectMember[2] and member:IsAssitant() then
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaFormationChangeError"))
                return
            end
        end
    end
    --检查重复支援
    if member2:IsAssitant() then
        for index, member in pairs(self.TeamDatas[teamIndex].Members) do
            if not index == memberIndex and member:IsAssitant() then
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaFormationChangeError"))
                return
            end
        end
    end
    --实行交换
    self.TeamDatas[teamIndex].Members[memberIndex] = member2
    self.TeamDatas[self.SelectMember[1]].Members[self.SelectMember[2]] = member1
    self.SelectMember = nil
    self.TeamGrid[teamIndex].MemberGrids[memberIndex]:SetSelect(false)
    self.IsXteamDirty = true;
    self:UpdateView()
end

function XUiGuildWarDeployPanelFormation:OnBtnConfirm()
    local xTeams = self.XBuild:GetXTeams()
    for index, teamData in pairs(self.TeamDatas) do
        xTeams[index]:UpdateCaptainPosAndFirstFightPos(teamData.Captain, teamData.FirstPos)
    end
    if self.IsXteamDirty then
        local xTeams = self.XBuild:GetXTeams()
        for index, team in pairs(xTeams) do
            team:SetMembers(self.TeamDatas[index].Members)
        end
    end
    self.PosChangeCallback()
    self:Hide()
end

function XUiGuildWarDeployPanelFormation:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiGuildWarDeployPanelFormation
