---@class XUiGridLinkCraftActivitySkill
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkCraftActivitySkill = XClass(XUiNode, 'XUiGridLinkCraftActivitySkill')

function XUiGridLinkCraftActivitySkill:OnStart(index)
    self._Index = index
    
    self.Btn.CallBack = handler(self, self.OnBtnClickEvent)
end

function XUiGridLinkCraftActivitySkill:Refresh(skillId)
    --对无效技能进行额外处理
    local validSkillId = XTool.IsNumberValid(skillId)

    for i=0, self.Btn.RawImageList.Count - 1 do
        self.Btn.RawImageList[i].gameObject:SetActiveEx(validSkillId)
    end
    
    if self.TxtName then
        self.TxtName.gameObject:SetActiveEx(validSkillId)
    end
    
    if not XTool.IsNumberValid(skillId) then
        return
    end
    
    
    self._SkillId = skillId
    if self.TxtName then
        self.TxtName.text = self._Control:GetSkillNameById(self._SkillId)
    end
    self.Btn:SetRawImage(self._Control:GetSkillIconById(self._SkillId))
end

function XUiGridLinkCraftActivitySkill:OnBtnClickEvent()
    XLuaUiManager.Open('UiLinkCraftActivityEdit', self._Index)
end

return XUiGridLinkCraftActivitySkill