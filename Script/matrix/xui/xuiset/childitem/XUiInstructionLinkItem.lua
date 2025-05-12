---@class XUiInstructionLinkItem
---@field private _Control XLinkCraftActivityControl
local XUiInstructionLinkItem = XClass(XUiNode, 'XUiInstructionLinkItem')

function XUiInstructionLinkItem:OnStart(skillId)
    self._SkillId = skillId
    
    self.TxtName.text = self._Control:GetSkillNameById(self._SkillId)
    self.TxtDetail.text = self._Control:GetSkillDetailById(self._SkillId)
    self.RImgSkill:SetRawImage(self._Control:GetSkillIconById(self._SkillId))
end

return XUiInstructionLinkItem