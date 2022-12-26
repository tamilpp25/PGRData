-- 兵器蓝图角色页面角色状态面板技能控件
local XUiRpgTowerCharaInfoSkillGrid = XClass(nil, "XUiRpgTowerCharaInfoSkillGrid")
function XUiRpgTowerCharaInfoSkillGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.BtnSkill.CallBack = function() self:OnSkillClick() end
end
--================
--刷新技能数据
--================
function XUiRpgTowerCharaInfoSkillGrid:RefreshSkill(skillInfo)
    self.SkillInfo = skillInfo
    self.BtnSkill:SetRawImage(skillInfo.Icon)
    self.TxtLevel.text = skillInfo.Level
end
--================
--点击此控件时
--================
function XUiRpgTowerCharaInfoSkillGrid:OnSkillClick()
    if not self.SkillInfo then return end
    XLuaUiManager.Open("UiRpgTowerSkillDetails", self.SkillInfo)
end
return XUiRpgTowerCharaInfoSkillGrid