local XUiGridCanEatPartner = XClass(nil, "XUiGridCanEatPartner")

function XUiGridCanEatPartner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelect = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridCanEatPartner:SetButtonCallBack()
    self.BtnAddSelect.CallBack = function()
        self:OnBtnAddSelectClick()
    end
end

function XUiGridCanEatPartner:OnBtnAddSelectClick()
    self.Base:SetSelectFood(self.Data, not self.IsSelect)
    self:ShowSelect()
end

function XUiGridCanEatPartner:UpdateGrid(data, base)
    self.Data = data
    self.Base = base

    if data then
        self.RImgHeadIcon:SetRawImage(data:GetIcon())
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(data:GetQuality()))
        self.ImgBreak:SetSprite(data:GetBreakthroughIcon())
        self.TxtLevel.text = data:GetLevel()
        self.Txtname.text = data:GetName()
        self:ShowSelect()
    end

end

function XUiGridCanEatPartner:ShowSelect()
    self.IsSelect = self.Base:CheckIsSelectFood(self.Data:GetId())
    self.ImgSelect.gameObject:SetActiveEx(self.IsSelect)
end

return XUiGridCanEatPartner