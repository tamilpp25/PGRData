local XUiPartnerPopupTip = XLuaUiManager.Register(XLuaUi, "UiPartnerPopupTip")

function XUiPartnerPopupTip:OnStart(title, closeCb)
    self.Title = title
    self.CloseCb = closeCb
    self:InitView()
end

function XUiPartnerPopupTip:OnEnable()
    self:PlayAnimation("AniUnlockTip", function()
        self:Close()
    end)
end

function XUiPartnerPopupTip:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiPartnerPopupTip:InitView()
    self.TxtTitle.text = self.Title
end