---@class UiPanelLinkSet
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkSet = XClass(XUiNode, 'XUiPanelLinkSet')
local XUiGridLinkSetSkill = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivitySet/XUiGridLinkSetSkill')

function XUiPanelLinkSet:OnStart()
    self:Init()
    self:Refresh()
end

function XUiPanelLinkSet:Init()
    local index = 1
    local btnSkill = nil
    repeat
        btnSkill = self['GridLink'..index]
        if btnSkill then
            local grid = XUiGridLinkSetSkill.New(btnSkill, self, index)
            grid:Open()
            table.insert(self._GridSkills, grid)
        end
        index = index + 1
    until btnSkill == nil or index > 99999 --限定值防卡死
end

function XUiPanelLinkSet:Refresh()
    local curListData = self._Control:GetCurLinkListData()
    
    for i, v in ipairs(self._GridSkills) do
        if curListData._SkillData[i] then
            v:Open()
            v:Refresh(curListData._SkillData[i])
        else
            v:Close()
        end
    end
end

return XUiPanelLinkSet