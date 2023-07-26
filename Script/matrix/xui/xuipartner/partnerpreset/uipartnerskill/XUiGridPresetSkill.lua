
--==============================
 ---@desc 辅助机预设 -- 技能格子
--==============================
local XUiGridPresetSkill = XClass(nil, "XUiGridPresetSkill")

local Type2Func = {
    [XPartnerConfigs.SkillType.MainSkill] = function(partner, partnerPrefab)
        XLuaUiManager.Open("UiPartnerPresetMainSkill", partner, partnerPrefab)
    end,
    [XPartnerConfigs.SkillType.PassiveSkill] = function(partner, partnerPrefab)
        XLuaUiManager.Open("UiPartnerPresetPassiveSkill", partner, partnerPrefab)
    end
}

function XUiGridPresetSkill:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
    self:AddListener()
end

function XUiGridPresetSkill:InitUi()
    self.TxtMainLevel = self.PanelMainSkill:GetObject("TxtLevel")
    self.TxtPassiveLevel = self.PanelPassiveSkill:GetObject("TxtLevel")
    self.RImgMainSkillIcon = self.PanelMainSkill:GetObject("IconSkill")
    self.RImgPassiveSkillIcon = self.PanelPassiveSkill:GetObject("IconSkill")
    self.RawElement = self.Tag:GetObject("RawElement")
    
end

function XUiGridPresetSkill:AddListener()
    self.BtnSkill.CallBack = function() 
        self:OnBtnSkillClick()
    end
end

function XUiGridPresetSkill:OnBtnSkillClick()

    if self.Locked then
        XUiManager.TipMsg(XUiHelper.GetText("PartnerSkillFieldIsLock", XPartnerConfigs.QualityString[self.UnlockQuality]))
        return
    end

    local func = Type2Func[self.Type]
    if func then
        func(self.Partner, self.PartnerPrefab)
    end
end

--==============================
 ---@desc 刷新技能显示状态
 ---@skillGroup @class XPartnerSkillGroupBase
 ---@partner 辅助机 @class XPartner
 ---@lock 锁定 @boolean 
 ---@type -技能类型
 ---@unlockQuality 对应的进化阶段 
--==============================
function XUiGridPresetSkill:Refresh(skillGroup, partner, lock, type, unlockQuality, partnerPrefab)
    self.Partner = partner
    self.Locked = lock
    self.Type = type
    self.UnlockQuality = unlockQuality
    self.PartnerPrefab = partnerPrefab
    local partnerId = partner:GetId()
    
    self.IsCarry = partnerPrefab:GetIsCarry(partnerId)
    
    local hasData = not XTool.IsTableEmpty(skillGroup)
    
    if hasData then
        local chrId = partnerPrefab:GetCharacterId(partnerId)
        local activeSkillId = XDataCenter.PartnerManager.SwitchMainActiveSkillId(skillGroup, chrId)
        local icon = skillGroup:GetSkillIcon(activeSkillId)
        local level = skillGroup:GetLevelStr()
        local txtLevel, skillIcon
        if self:IsMainSkill() then
            txtLevel, skillIcon = self.TxtMainLevel, self.RImgMainSkillIcon
        else
            txtLevel, skillIcon = self.TxtPassiveLevel, self.RImgPassiveSkillIcon
        end 
        txtLevel.text = level
        skillIcon:SetRawImage(icon)

        if partner and self.IsCarry then
            local charElement = XCharacterConfigs.GetCharacterElement(chrId)
            local elementConfig = XCharacterConfigs.GetCharElement(charElement)
            self.RawElement:SetRawImage(elementConfig.Icon2)
            self.RawElement.gameObject:SetActiveEx(true)
        else
            self.RawElement.gameObject:SetActiveEx(false)
        end

        self.PanelNoSkill.gameObject:SetActiveEx(false)
        self.PanelMainSkill.gameObject:SetActiveEx(self:IsMainSkill())
        self.PanelPassiveSkill.gameObject:SetActiveEx(self:IsPassiveSkill())
        self.PanelLock.gameObject:SetActiveEx(false)
        self.Tag.gameObject:SetActiveEx(self:IsMainSkill())
    else
        self.PanelNoSkill.gameObject:SetActiveEx(not lock)
        self.PanelMainSkill.gameObject:SetActiveEx(false)
        self.PanelPassiveSkill.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(lock)
        self.Tag.gameObject:SetActiveEx(false)
    end
end 

function XUiGridPresetSkill:IsMainSkill()
    return self.Type == XPartnerConfigs.SkillType.MainSkill
end

function XUiGridPresetSkill:IsPassiveSkill()
    return self.Type == XPartnerConfigs.SkillType.PassiveSkill
end


return XUiGridPresetSkill