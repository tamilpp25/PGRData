local XUiTRPGBuffDetail = XLuaUiManager.Register(XLuaUi, "UiTRPGBuffDetail")

function XUiTRPGBuffDetail:OnAwake()
    self:AutoAddListener()
end

function XUiTRPGBuffDetail:OnStart(buffId)
    self.BuffId = buffId

    self:InitUi()
end

function XUiTRPGBuffDetail:InitUi()
    local buffId = self.BuffId

    local icon = XTRPGConfigs.GetBuffIcon(buffId)
    self:SetUiSprite(self.ImgIcon, icon)

    local name = XTRPGConfigs.GetBuffName(buffId)
    self.TxtName.text = name

    local desc = XTRPGConfigs.GetBuffDesc(buffId)
    self.TxtWorldDesc.text = desc
end

function XUiTRPGBuffDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnBackClick)
end

function XUiTRPGBuffDetail:OnBtnBackClick()
    self:Close()
end