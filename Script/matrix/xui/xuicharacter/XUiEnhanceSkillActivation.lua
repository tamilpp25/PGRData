local XUiEnhanceSkillActivation = XLuaUiManager.Register(XLuaUi, "UiEnhanceSkillActivation")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiEnhanceSkillActivation:OnStart(type, skillGroup, characterId)
    self.Type = type
    self.SkillGroup = skillGroup
    self.CharacterId = characterId
    self:SetButtonCallBack()
end

function XUiEnhanceSkillActivation:OnEnable()
    self:UpdatePanel()
end

function XUiEnhanceSkillActivation:SetButtonCallBack()
    self.BtnDetermine.CallBack = function()
        self:OnBtnDetermineClick()
    end
end

function XUiEnhanceSkillActivation:UpdatePanel()
    if self:IsEnhance() then
        self:PlayAnimationWithMask("AnimEnhanceEnable")
    elseif self:IsSp() then
        self:PlayAnimationWithMask("AnimSpEnable")
    end

    local fullBodyImage = XMVCA.XCharacter:GetCharFullBodyImg(self.CharacterId)
    local resource = CS.XResourceManager.Load(fullBodyImage)
    local texture = resource.Asset
    self.MeshImg.sharedMaterial:SetTexture("_MainTex", texture)
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
    end
    self.Resource = resource
    self.FxUiChuxian.gameObject:SetActiveEx(false)
    XScheduleManager.ScheduleOnce(function()
            self.FxUiChuxian.gameObject:SetActiveEx(true)
        end,  500)
    
    
    self.SkillIcon:SetRawImage(self.SkillGroup:GetIcon())
    self.TxtSkillName.text = self.SkillGroup:GetName()
    
    self.ImgEnhanceTitle.gameObject:SetActiveEx(self:IsEnhance())
    self.ImgSpTitle.gameObject:SetActiveEx(self:IsSp())
end

function XUiEnhanceSkillActivation:IsEnhance()
    return self.Type == XEnumConst.CHARACTER.SkillUnLockType.Enhance
end

function XUiEnhanceSkillActivation:IsSp()
    return self.Type == XEnumConst.CHARACTER.SkillUnLockType.Sp
end

function XUiEnhanceSkillActivation:OnBtnDetermineClick()
    self:Close()
end

function XUiEnhanceSkillActivation:OnDestroy()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
    end
end