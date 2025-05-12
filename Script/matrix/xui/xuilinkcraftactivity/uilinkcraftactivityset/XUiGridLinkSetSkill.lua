---@class XUiGridLinkSetSkill
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkSetSkill = XClass(XUiNode, 'XUiGridLinkSetSkill')

function XUiGridLinkSetSkill:OnStart(skillId)
    self._SkillId = skillId
    self:Refresh(skillId)
end

function XUiGridLinkSetSkill:Refresh(skillId)
    self._SkillId = skillId or self._SkillId
    
    self.TxtName.text = self._Control:GetSkillNameById(self._SkillId)
    self.TxtDetail.text = self._Control:GetSkillDetailById(self._SkillId)
    self.RImgSkill:SetRawImage(self._Control:GetSkillIconById(self._SkillId))
end

return XUiGridLinkSetSkill