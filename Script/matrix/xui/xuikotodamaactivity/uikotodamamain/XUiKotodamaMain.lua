local XUiKotodamaMain=XLuaUiManager.Register(XLuaUi,'UiKotodamaMain')

function XUiKotodamaMain:OnAwake()
    self.BtnBack.CallBack=function()
        --[[if self.FirstPanelCtrl:IsNodeShow() then
            self:Close()
        else
            self.ContinuePanelCtrl:Close()
            self.FirstPanelCtrl:Open()
        end--]]
        self:Close()
    end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self:BindHelpBtn(self.BtnHelp,'Kotodama')
    
    self.PanelFirst.gameObject:SetActiveEx(false)
    self.PanelContinue.gameObject:SetActiveEx(false)
    
    --self.FirstPanelCtrl=require('XUi/XUiKotodamaActivity/UiKotodamaMain/XUiPanelKotodamaMainFirst').New(self.PanelFirst,self)
    self.ContinuePanelCtrl=require('XUi/XUiKotodamaActivity/UiKotodamaMain/XUiPanelKotodamaMainContinue').New(self.PanelContinue,self)
end

function XUiKotodamaMain:OnStart()
    if self.IsResume then
        self.IsResume=false
        return
    end
    self.ContinuePanelCtrl:Open()
end

function XUiKotodamaMain:OnResume()
    self.IsResume=true
    self:OpenContinuePanel()
    XMVCA.XKotodamaActivity:CallWinPanel()
end

function XUiKotodamaMain:OpenContinuePanel()
    --self.FirstPanelCtrl:Close()
    self.ContinuePanelCtrl:Open()
end

return XUiKotodamaMain