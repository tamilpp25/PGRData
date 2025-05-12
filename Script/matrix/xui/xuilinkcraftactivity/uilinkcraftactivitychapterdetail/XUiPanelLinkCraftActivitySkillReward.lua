---@class XUiPanelLinkCraftActivitySkillReward
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkCraftActivitySkillReward = XClass(XUiNode, 'XUiPanelLinkCraftActivitySkillReward')


function XUiPanelLinkCraftActivitySkillReward:Refresh(skillId)
    if not XTool.IsNumberValid(skillId) then
        return
    end
    self._SkillId = skillId
    self.TxtName.text = self._Control:GetSkillNameById(self._SkillId)
    self.TxtDetail.text = self._Control:GetSkillDetailById(self._SkillId)
    self.RImgSkill:SetRawImage(self._Control:GetSkillIconById(self._SkillId))
    self.TxtTips.text = self._Control:GetSkillTypeTextByid(self._SkillId)
end

return XUiPanelLinkCraftActivitySkillReward