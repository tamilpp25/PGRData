---@class XUiSameColorGameGridSkillSelect
local XUiSameColorGameGridSkillSelect = XClass(nil, "XUiSameColorGameGridSkillSelect")

function XUiSameColorGameGridSkillSelect:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Index = nil
end

---@param skill XSCRoleSkill
function XUiSameColorGameGridSkillSelect:SetData(skill, index, isForbid)
    self.Index = index
    self.RImgIcon:SetRawImage(skill:GetIcon())
    self.TxtName.text = skill:GetName()
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.PanelDisable.gameObject:SetActiveEx(isForbid)
end

function XUiSameColorGameGridSkillSelect:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiSameColorGameGridSkillSelect:GetIndex()
    return self.Index
end

function XUiSameColorGameGridSkillSelect:PlayEnableAnim()
    self.AnimEnable:Play()
end

function XUiSameColorGameGridSkillSelect:PlayUnloadAnim()
    self.AnimUnload:Play()
end

return XUiSameColorGameGridSkillSelect