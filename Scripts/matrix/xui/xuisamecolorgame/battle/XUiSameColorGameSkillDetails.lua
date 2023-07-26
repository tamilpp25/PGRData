local XUiSameColorGameSkillDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSkillDetails")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameSkillDetails:OnStart(entity, itemId, isShowSkillEnergyDesc)
    self.Entity = entity
    self.ItemId = itemId
    self.IsShowSkillEnergyDesc = isShowSkillEnergyDesc
    self:SetButtonCallBack()
end

function XUiSameColorGameSkillDetails:OnEnable()
    self:UpdateSkill()
end

function XUiSameColorGameSkillDetails:UpdateSkill()
    if self.Entity then
        self.TxtName.text = self.Entity:GetName()
        self.TxtWorldDesc.text = self.Entity:GetDesc()
        self.RImgSkill:SetRawImage(self.Entity:GetIcon())
        self.TitleText.text = CSTextManagerGetText("SCTipBossSkillDetailName")
        self.TxtOwn.text = CSTextManagerGetText("SameColorGameEnergyDescText")
        self.TxtOwn.gameObject:SetActiveEx(self.IsShowSkillEnergyDesc == true)
        self.TxtOwnCnt.gameObject:SetActiveEx(false)
    elseif self.ItemId then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)
        self.TxtName.text = goodsShowParams.Name
        self.TxtWorldDesc.text = XGoodsCommonManager.GetGoodsDescription(self.ItemId)
        self.RImgSkill:SetRawImage(goodsShowParams.Icon)
        self.TxtOwnCnt.text = XGoodsCommonManager.GetGoodsCurrentCount(self.ItemId)
    end
end

function XUiSameColorGameSkillDetails:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
    self:RegisterClickEvent(self.BtnBg, self.Close)
end

function XUiSameColorGameSkillDetails:OnClickBtnBack()
    self:Close()
end