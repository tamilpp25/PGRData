local XUiPartnerStrengthenSkip = XLuaUiManager.Register(XLuaUi, "UiPartnerStrengthenSkip")

function XUiPartnerStrengthenSkip:OnAwake()
    self:InitAutoScript()
    self.PanelGridSkip.gameObject:SetActive(false)
end

function XUiPartnerStrengthenSkip:OnStart(skipIds)
    self.GridPool = {}
    self:Refresh(skipIds)
end

function XUiPartnerStrengthenSkip:Refresh(skipIds)

    XUiHelper.CreateTemplates(self, self.GridPool, skipIds, XUiGridSkip.New, self.PanelGridSkip, self.PanelContent, function(grid, data)
        grid:Refresh(data)
    end)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPartnerStrengthenSkip:InitAutoScript()
    self:AutoAddListener()
end

function XUiPartnerStrengthenSkip:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end
-- auto
function XUiPartnerStrengthenSkip:OnBtnCloseClick()
    self:Close()
end