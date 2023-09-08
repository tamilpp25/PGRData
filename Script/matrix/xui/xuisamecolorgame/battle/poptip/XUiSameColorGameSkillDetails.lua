---@class XUiSameColorGameSkillDetails:XLuaUi
local XUiSameColorGameSkillDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSkillDetails")
function XUiSameColorGameSkillDetails:OnStart(entity, itemId, isShowSkillEnergyDesc, isShopItem, shopItem)
    self.Entity = entity
    self.ItemId = itemId
    self.IsShowSkillEnergyDesc = isShowSkillEnergyDesc
    self._IsShopItem = isShopItem
    self._ShopItem = shopItem
    self:SetButtonCallBack()
end

function XUiSameColorGameSkillDetails:OnEnable()
    if self._IsShopItem then
        self:UpdateShopItem()
    else
        self:UpdateSkill()
    end
end

function XUiSameColorGameSkillDetails:UpdateSkill()
    if self.Entity then
        local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
        self.TxtName.text = self.Entity:GetName()
        self.TxtWorldDesc.text = self.Entity:GetDesc(battleManager:IsTimeType())
        self.RImgSkill:SetRawImage(self.Entity:GetIcon())
        self.TitleText.text = XUiHelper.GetText("SCTipBossSkillDetailName")
        self.TxtOwn.text = XUiHelper.GetText("SameColorGameEnergyDescText")
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

function XUiSameColorGameSkillDetails:UpdateShopItem()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self._ShopItem.TemplateId)

    self.TxtName.text = goodsShowParams.Name
    self.RImgSkill:SetRawImage(goodsShowParams.Icon)
    self.TxtOwnCnt.text = XGoodsCommonManager.GetGoodsCurrentCount(self._ShopItem.TemplateId)
    self.TxtDescription.text = XGoodsCommonManager.GetGoodsDescription(self._ShopItem.TemplateId)
    self.TxtWorldDesc.text = XGoodsCommonManager.GetGoodsWorldDesc(self._ShopItem.TemplateId)
end

function XUiSameColorGameSkillDetails:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
    self:RegisterClickEvent(self.BtnBg, self.Close)
end

function XUiSameColorGameSkillDetails:OnClickBtnBack()
    self:Close()
end