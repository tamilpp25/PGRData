---@class XUiGridAssignGeneralSkill:_XUiPanelGeneralSkill
local XUiGridAssignGeneralSkill = XClass(require('XUi/XUiNewRoomSingle/XUiGridGeneralSkill'), 'XUiGridAssignGeneralSkill')

---@overload
function XUiGridAssignGeneralSkill:OnStart(stageId)
    self._StageId = stageId
    self.BtnGeneralSkill.CallBack = handler(self,self.OnBtnClickEvent)
    self.BtnGeneralSkillNotactive.CallBack = handler(self, self.OnNoGeneralSkillBtnClickEvent)
    self:Refresh()
end

---@param teamData XTeam
function XUiGridAssignGeneralSkill:SetTeamData(teamData)
    self._TeamData = teamData
end

---@overload
function XUiGridAssignGeneralSkill:GetTeamData()
    return self._TeamData
end

---@overload
function XUiGridAssignGeneralSkill:OnBtnClickEvent()
    local teamData = self:GetTeamData()

    if teamData:CheckHasGeneralSkills() then
        XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function()
            self:Refresh(true)
        end, self.Parent.StageId, teamData)
    else
        XUiManager.TipText('BattleRoleRoomNoGeneralSkillTips')
    end
end

function XUiGridAssignGeneralSkill:TryRefresh()
    local teamData = self:GetTeamData()

    if not XTool.IsTableEmpty(teamData) then
        teamData:RefreshGeneralSkills(true)
        self:Refresh(true)
    end
end

return XUiGridAssignGeneralSkill