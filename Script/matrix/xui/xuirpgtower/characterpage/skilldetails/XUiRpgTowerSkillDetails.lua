-- 兵法蓝图技能详细界面
local XUiRpgTowerSkillDetails = XLuaUiManager.Register(XLuaUi, "UiRpgTowerSkillDetails")

function XUiRpgTowerSkillDetails:OnAwake()
    XTool.InitUiObject(self)
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiRpgTowerSkillDetails:OnStart(skillInfo)
    self.SkillInfo = skillInfo
    self:RefreshSkill()
end
--================
--刷新面板内容控件
--================
function XUiRpgTowerSkillDetails:RefreshSkill()
    self.RImgSkill:SetRawImage(self.SkillInfo.Icon)
    self.TxtCount.text = self.SkillInfo.Level
    self.TxtName.text = self.SkillInfo.Name
    self.TxtWorldDesc.text = self.SkillInfo.Intro
end