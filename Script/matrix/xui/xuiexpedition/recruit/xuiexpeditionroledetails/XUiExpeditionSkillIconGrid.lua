--虚像地平线招募界面子页面角色详细：技能显示控件
local XUiExpeditionSkillIconGrid = XClass(nil, "XUiExpeditionSkillIconGrid")
function XUiExpeditionSkillIconGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionSkillIconGrid:RefreshData(skillInfo)
    self.Data = skillInfo
    self.RImgSkillIcon:SetRawImage(skillInfo.IconPath)
    self.TxtSkillLevel.text = string.format("等级:%d", skillInfo.Level)
    if self.TxtStarLevel then self.TxtStarLevel.text = string.format(skillInfo.LockLevel) end
    self:SetLock(skillInfo.IsLock)
end

function XUiExpeditionSkillIconGrid:SetLock(isLock)
    self.Lock.gameObject:SetActiveEx(isLock)
end
return XUiExpeditionSkillIconGrid