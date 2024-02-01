local XUiPanelQualityUpConfirm = XClass(nil, "XUiPanelQualityUpConfirm")

function XUiPanelQualityUpConfirm:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelQualityUpConfirm:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPanelQualityUpConfirm:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePartnerInfo(data)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelQualityUpConfirm:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelQualityUpConfirm:UpdatePartnerInfo(data)
    self.IconQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(data:GetQuality()))
end

function XUiPanelQualityUpConfirm:OnBtnCloseClick(data)
    self.Base:SetQualityUpFinish(false)
    self.Base:UpdatePanel(self.Data)
end


return XUiPanelQualityUpConfirm