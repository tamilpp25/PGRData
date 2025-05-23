local XUiGridPartnerCarry = XClass(nil, "XUiGridPartnerCarry")

function XUiGridPartnerCarry:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    --v1.28 装备头像
    self.RImgRole = self.ImgIsCarry.transform:Find("RImgRole"):GetComponent("RawImage")
    self:SetButtonCallBack()
end

function XUiGridPartnerCarry:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnSelectClick()
    end
end

function XUiGridPartnerCarry:OnBtnSelectClick()
    self.Base:SelectPartner(self.Data)
    
    local grids = self.Base.DynamicTable:GetGrids()
    for _,grid in pairs(grids) do
        grid:ShowSelect(false)
    end

    self:ShowSelect(true)
end

function XUiGridPartnerCarry:UpdateGrid(data, base)
    self.Data = data
    self.Base = base
    
    if data then
        local selectPartnerId = self.Base.CurPartner:GetId()
        local IsSelect = self.Data:GetId() == selectPartnerId
        if IsSelect then
            self:OnBtnSelectClick()
        else
            self:ShowSelect(IsSelect)
        end
        self:ShowInfo()
    end

end

function XUiGridPartnerCarry:ShowSelect(IsShow)
    self.PanelSelected.gameObject:SetActiveEx(IsShow)
end

function XUiGridPartnerCarry:OnCheckRedPoint(count)
    self.BtnCharacter:ShowReddot(count >= 0)
end

function XUiGridPartnerCarry:ShowInfo()
    self.RImgHeadIcon:SetRawImage(self.Data:GetIcon())
    self.PanelLv:GetObject("TxtLevel").text = self.Data:GetLevel()
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.Data:GetQuality()))
    self.ImgLock.gameObject:SetActiveEx(self.Data:GetIsLock())

    --v1.28 装备头像
    self.ImgIsCarry.gameObject:SetActiveEx(self.Data:GetIsCarry())
    if self.Data:GetIsCarry() and self.RImgRole then
        local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(self.Data:GetCharacterId())
        self.RImgRole:SetRawImage(icon)
    end

    local btImg = self.Data:GetBreakthroughIcon()
    self.ImgBreak:SetSprite(btImg)
end

return XUiGridPartnerCarry