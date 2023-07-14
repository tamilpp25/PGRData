local XUiSameColorGameSkillDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSkillDetails")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameSkillDetails:OnStart(entit, IsBossSkill)
    self.Entit = entit
    self.IsBossSkill = IsBossSkill
    self:SetButtonCallBack()
end

function XUiSameColorGameSkillDetails:OnEnable()
    self:UpdateSkill()
end

function XUiSameColorGameSkillDetails:UpdateSkill()
    self.TxtName.text = self.Entit:GetName()

    self.TxtWorldDesc.text = self.Entit:GetDesc()

    self.RImgSkill:SetRawImage(self.Entit:GetIcon())
    
    self.TxtDescription.text = self.IsBossSkill and CSTextManagerGetText("SCTipBossSkillDetailDesc") or CSTextManagerGetText("SCTipBuffDetailDesc")
    
    self.TitleText.text = self.IsBossSkill and CSTextManagerGetText("SCTipBossSkillDetailName") or CSTextManagerGetText("SCTipBuffDetailName")
end

function XUiSameColorGameSkillDetails:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
end

function XUiSameColorGameSkillDetails:OnClickBtnBack()
    self:Close()
end