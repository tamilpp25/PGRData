--自走棋关卡详细代理基类
local XUiExpeditionDetailProxy = XClass(nil, "XUiExpeditionDetailProxy")

function XUiExpeditionDetailProxy:Ctor(tierDetailUi)
    self.Ui = tierDetailUi
    self.RootUi = self.Ui.RootUi
    XUiHelper.RegisterClickEvent(self.Ui, self.Ui.BtnClose, function() self:Hide() end)
end

function XUiExpeditionDetailProxy:OnEnable()
    self:InitPanel()
end

function XUiExpeditionDetailProxy:OnDisable()
    
end

function XUiExpeditionDetailProxy:Hide()
    self.Ui:Close()
end

function XUiExpeditionDetailProxy:InitPanel()
    
end

return XUiExpeditionDetailProxy