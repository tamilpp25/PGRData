local XUiSameColorPanelSkillDetail = require("XUi/XUiSameColorGame/PopTip/XUiSameColorPanelSkillDetail")
---@class XUiSameColorGameEquipSkill:XLuaUi
local XUiSameColorGameEquipSkill = XLuaUiManager.Register(XLuaUi, "UiSameColorGamePopup")

function XUiSameColorGameEquipSkill:OnAwake()
    -- XSCRole
    self.Role = nil
    -- XSCSkill
    self.Skill = nil
    self.Callback = nil
    self.EquipIndex = nil
    self.UiSameColorPanelSkillDetail = XUiSameColorPanelSkillDetail.New(self)
    self:RegisterUiEvents()
end

function XUiSameColorGameEquipSkill:OnStart(boss, role, skill, equipIndex, callback)
    self.Callback = callback
    self.Boss = boss
    self.Role = role
    self.Skill = XTool.Clone(skill)
    self.EquipIndex = equipIndex
    self.PanelWearing.gameObject:SetActiveEx(false)
    local isTimeType = self.Boss:IsTimeType()
    self.UiSameColorPanelSkillDetail:SetData(self.Skill, isTimeType)
end

function XUiSameColorGameEquipSkill:RegisterUiEvents()
    self.BtnClose.CallBack = function() 
        if self.Callback then
            self.Callback(false)
        end
        self:Close() 
    end
    self.BtnActive.CallBack = function() self:OnBtnActiveClicked() end
end

function XUiSameColorGameEquipSkill:OnBtnActiveClicked()
    local result = true
    local maxSkillCount = XEnumConst.SAME_COLOR_GAME.ROLE_MAX_SKILL_COUNT
    -- 操作的是固定技能
    if self.EquipIndex and self.EquipIndex <= 0 then
        result = false
        XUiManager.TipMsg(XUiHelper.GetText("SCRoleMainSkillNotChangeTips"))
    elseif #self.Role:GetUsingSkillGroupIds(true) < maxSkillCount or self.EquipIndex then
        self.Role:AddSkillGroupId(self.Skill:GetSkillGroupId(), self.EquipIndex)
        XUiManager.TipMsg(XUiHelper.GetText("SCRoleSkillUploadSuccess"))
    else
        result = false
        XUiManager.TipMsg(XUiHelper.GetText("SCRoleOverMaxSkillCountTips", maxSkillCount))
    end
    if self.Callback then
        self.Callback(result)
    end
    self:Close()
end

return XUiSameColorGameEquipSkill
