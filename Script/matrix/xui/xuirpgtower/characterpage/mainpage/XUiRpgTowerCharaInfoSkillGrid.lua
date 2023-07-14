-- 兵器蓝图角色页面角色状态面板技能控件
local XUiRpgTowerCharaInfoSkillGrid = XClass(nil, "XUiRpgTowerCharaInfoSkillGrid")
local NoShowLevel = { --不显示等级的技能编号尾数
    [24] = true, --SS
    [25] = true, --SSS
    [26] = true, --SSS+
    [27] = true  --终解
}
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
    if not NoShowLevel[(skillInfo.SkillId % 100)] then
        self.BtnSkill:SetButtonState(CS.UiButtonState.Normal)
        self.TxtActivated.gameObject:SetActiveEx(false)
        self.TxtInactive.gameObject:SetActiveEx(false)
        self.TxtLevel.gameObject:SetActiveEx(true)
        self.TxtLevel.text = skillInfo.Level
    else
        self.BtnSkill:SetButtonState(self.SkillInfo.Level > 0 and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.TxtActivated.gameObject:SetActiveEx(self.SkillInfo.Level > 0)
        self.TxtInactive.gameObject:SetActiveEx(self.SkillInfo.Level == 0)
        self.TxtLevel.gameObject:SetActiveEx(false)
    end
end
--================
--点击此控件时
--================
function XUiRpgTowerCharaInfoSkillGrid:OnSkillClick()
    if not self.SkillInfo then return end
    XLuaUiManager.Open("UiRpgTowerSkillDetails", self.SkillInfo)
end
return XUiRpgTowerCharaInfoSkillGrid