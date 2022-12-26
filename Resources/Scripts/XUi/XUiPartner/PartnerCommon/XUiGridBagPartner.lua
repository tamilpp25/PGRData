local XUiGridBagPartner = XClass(nil, "XUiGridBagPartner")

function XUiGridBagPartner:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelect = false
    self.ClickCb = clickCb
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:SetSelected(false)
end

function XUiGridBagPartner:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClickClick()
    end
end

function XUiGridBagPartner:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.Data, self)
    end
end

function XUiGridBagPartner:UpdateGrid(data)
    self.Data = data
    if data then
        self.RImgIcon:SetRawImage(data:GetIcon())
        self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(data:GetQuality()))
        self.ImgBreak:SetSprite(data:GetBreakthroughIcon())
        self.TxtLevel.text = data:GetLevel()
        self.TxtName.text = data:GetName()
        self.ImageQuality:SetSprite(XPartnerConfigs.GeQualityBgPath(data:GetInitQuality()))
        self.ImgLock.gameObject:SetActiveEx(data:GetIsLock())
        self.PanelUsing.gameObject:SetActiveEx(data:GetIsCarry())
    end
end

function XUiGridBagPartner:SetSelected(status)
    self.ImgSelect.gameObject:SetActiveEx(status)
end

return XUiGridBagPartner