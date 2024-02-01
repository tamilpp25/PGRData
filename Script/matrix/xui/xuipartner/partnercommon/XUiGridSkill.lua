local XUiGridSkill = XClass(nil, "XUiGridSkill")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsLock = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridSkill:SetButtonCallBack()
    self.BtnSkill.CallBack = function()
        self:OnBtnSkillClick()
    end
end

function XUiGridSkill:OnBtnSkillClick()
    if self.IsNone then
        return
    end

    if self.IsLock then
        XUiManager.TipMsg(CSTextManagerGetText("PartnerSkillFieldIsLock", XPartnerConfigs.QualityString[self.UnLockQuality]))
        return
    end

    if self:IsMainSkill() then
        XLuaUiManager.Open("UiPartnerActivateMainSkill", self.Partner)

    elseif self:IsPassiveSkill() then
        XLuaUiManager.Open("UiPartnerActivatePassiveSkill", self.Partner)
    end

end

function XUiGridSkill:UpdateGrid(data, partner, IsLock, type, unLockQuality, IsNone)
    self.Data = data
    self.Partner = partner
    self.Type = type
    self.IsLock = IsLock
    self.UnLockQuality = unLockQuality
    self.IsNone = IsNone
    
    if data and not IsNone then
        local level = data:GetLevelStr()
        if self:IsMainSkill() then
            self.PanelMainSkill:GetObject("TxtLevel").text = level
            self.PanelMainSkill:GetObject("IconSkill"):SetRawImage(data:GetSkillIcon())
            if self.Tag then
                if self.Partner:GetIsCarry() then
                    local charId = self.Partner:GetCharacterId()
                    local charElement = XMVCA.XCharacter:GetCharacterElement(charId)
                    local elementConfig = XMVCA.XCharacter:GetCharElement(charElement)
                    self.Tag:GetObject("RawElement"):SetRawImage(elementConfig.Icon2)
                    self.Tag:GetObject("RawElement").gameObject:SetActiveEx(true)
                else
                    self.Tag:GetObject("RawElement").gameObject:SetActiveEx(false)
                end
            end
        elseif self:IsPassiveSkill() then
            self.PanelPassiveSkill:GetObject("TxtLevel").text = level
            self.PanelPassiveSkill:GetObject("IconSkill"):SetRawImage(data:GetSkillIcon())

        end

        self.PanelNoSkill.gameObject:SetActiveEx(false)
        self.PanelMainSkill.gameObject:SetActiveEx(self:IsMainSkill())
        self.PanelPassiveSkill.gameObject:SetActiveEx(self:IsPassiveSkill())
        self.PanelLock.gameObject:SetActiveEx(false)

        if self.Tag then
            self.Tag.gameObject:SetActiveEx(self:IsMainSkill())
        end
    else
        self.PanelNoSkill.gameObject:SetActiveEx(not IsLock and not IsNone)
        self.PanelMainSkill.gameObject:SetActiveEx(false)
        self.PanelPassiveSkill.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(IsLock and not IsNone)
        
        if self.Tag then
            self.Tag.gameObject:SetActiveEx(false)
        end
    end
    
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(IsNone)
    end
    
end

function XUiGridSkill:IsMainSkill()
    return self.Type == XPartnerConfigs.SkillType.MainSkill
end

function XUiGridSkill:IsPassiveSkill()
    return self.Type == XPartnerConfigs.SkillType.PassiveSkill
end

return XUiGridSkill