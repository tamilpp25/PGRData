local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔准备当前进度显示面板
--=====================
local XUiStTpTeamPanel = XClass(Base, "XUiStTpTeamPanel")

function XUiStTpTeamPanel:InitPanel()
    self.Member = {}
    local script = require("XUi/XUiSuperTower/Stages/Tier/XUiStTpMemberGrid")
    for i = 1, 3 do
        local member = self["TeamMember" .. i]
        if member then
            self.Member[i] = script.New(member, self.RootUi)
        end
    end
end

function XUiStTpTeamPanel:OnShowPanel()
    local team = XDataCenter.SuperTowerManager.GetTeamByStageType(XDataCenter.SuperTowerManager.StageType.LllimitedTower)
    if team then
        for i = 1, 3 do
            local role = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(team:GetEntityIdByTeamPos(i))
            if role then
                self.Member[i]:RefreshData(role)
                self.Member[i]:SetLeader(i == team:GetCaptainPos())
                self.Member[i]:SetFirst(i == team:GetFirstFightPos())
            else
                self.Member[i]:Reset()
                self.Member[i]:SetLeader(false)
                self.Member[i]:SetFirst(false)
            end
        end
        local leaderPos = team:GetCaptainPos()
        local leaderRole = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(team:GetEntityIdByTeamPos(leaderPos))
        local captainSkillInfo = leaderRole:GetCharacterViewModel():GetCaptainSkillInfo()
        self.RImgIconLeader:SetRawImage(leaderRole:GetCharacterViewModel():GetSmallHeadIcon())
        self.TxtLeaderSkillName.text = captainSkillInfo.Name
        self.TxtLeaderSkillDesc.text = captainSkillInfo.Level > 0 and captainSkillInfo.Intro or CS.XTextManager.GetText("CaptainSkillLock")
    end
end

return XUiStTpTeamPanel