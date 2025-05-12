local Parent = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiPanelLinkCraftActivityLink')

local XUiPanelLinkCraftBattleRoleRoomLink = XClass(Parent, 'XUiPanelLinkCraftBattleRoleRoomLink')

function XUiPanelLinkCraftBattleRoleRoomLink:OnStart()
    self.Super.OnStart(self)
    self.BtnLink.CallBack = handler(self,self.OnBtnSwitchClickEvent)
end

function XUiPanelLinkCraftBattleRoleRoomLink:InitSkillGrids()
    local index = 1
    local btnSkill = nil
    local class = self:GetSkillClass()
    repeat
        btnSkill = self['GridSkill'..index]
        if btnSkill then
            local grid = class.New(btnSkill, self, index)
            grid:Open()
            table.insert(self._GridSkills, grid)
        end
        index = index + 1
    until btnSkill == nil or index > 99999 --限定值防卡死
end

return XUiPanelLinkCraftBattleRoleRoomLink