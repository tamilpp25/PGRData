local XUiSameColorPanelSkillDetail = require("XUi/XUiSameColorGame/XUiSameColorPanelSkillDetail")
local XUiSameColorGameUnEquipSkill = XLuaUiManager.Register(XLuaUi, "UiSameColorGamePopupTwo")

function XUiSameColorGameUnEquipSkill:OnAwake()
    -- XSCRole
    self.Role = nil
    -- XSCSkill
    self.Skill = nil
    self.Callback = nil
    self.EquipIndex = nil
    self.UiSameColorPanelSkillDetail = XUiSameColorPanelSkillDetail.New(self)
    self:RegisterUiEvents()
end

function XUiSameColorGameUnEquipSkill:OnStart(role, skill, equipIndex, isTimeType, callback)
    self.Callback = callback
    self.Role = role
    self.Skill = XTool.Clone(skill)
    self.EquipIndex = equipIndex
    self.UiSameColorPanelSkillDetail:SetData(self.Skill, isTimeType)
    local containSkill = role:ContainSkillGroupId(skill:GetSkillGroupId())
    local isMainSkill = role:GetMainSkill() == skill
    self.TxtMainSkillTip.gameObject.gameObject:SetActiveEx(isMainSkill)
    self.BtnTakeOffOnly.gameObject:SetActiveEx(containSkill and not isMainSkill)
    self.PanelWearing.gameObject:SetActiveEx(containSkill)
end

function XUiSameColorGameUnEquipSkill:RegisterUiEvents()
    self.BtnClose.CallBack = function() 
        if self.Callback then
            self.Callback(false)
        end
        self:Close() 
    end
    self.BtnTakeOffOnly.CallBack = function() self:OnBtnTakeOffOnlyClicked() end
end

function XUiSameColorGameUnEquipSkill:OnBtnTakeOffOnlyClicked()
    self.Role:RemoveSkillGroupId(self.Skill:GetSkillGroupId())
    if self.Callback then
        self.Callback(true, self.Skill:GetSkillGroupId())
    end
    self:Close()
end

return XUiSameColorGameUnEquipSkill
