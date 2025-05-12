---@class XUiTheatre3GridGeneralSkill:_XUiPanelGeneralSkill
---@field _Control XTheatre3Control
local XUiTheatre3GridGeneralSkill = XClass(require('XUi/XUiNewRoomSingle/XUiGridGeneralSkill'), 'XUiTheatre3GridGeneralSkill')

---@overload
function XUiTheatre3GridGeneralSkill:OnStart(stageId)
    self._StageId = stageId
    self.BtnGeneralSkill.CallBack = handler(self,self.OnBtnClickEvent)
    self.BtnGeneralSkillNotactive.CallBack = handler(self, self.OnNoGeneralSkillBtnClickEvent)
    self:TryRefresh(true)
end

---@param teamData XTeam
function XUiTheatre3GridGeneralSkill:SetTeamData(teamData)
    self._TeamData = teamData
end

---@overload
function XUiTheatre3GridGeneralSkill:GetTeamData()
    return self._TeamData
end

---@overload
function XUiTheatre3GridGeneralSkill:OnBtnClickEvent()
    local teamData = self:GetTeamData()

    if teamData:CheckHasGeneralSkills() then
        XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function()
            self:Refresh(true)
            self._Control:SetTeamGeneralSkillId(teamData:GetCurGeneralSkill())
        end, self.Parent.StageId, teamData)
    else
        XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
    end
end

function XUiTheatre3GridGeneralSkill:TryRefresh(force)
    local teamData = self:GetTeamData()

    if not XTool.IsTableEmpty(teamData) then
        teamData:RefreshGeneralSkills(true)
        self:Refresh(not force)
        self._Control:SetTeamGeneralSkillId(teamData:GetCurGeneralSkill())
    end
end

return XUiTheatre3GridGeneralSkill