
local XUiPanelRegressionBase = XClass(nil, "XUiPanelRegressionBase")

function XUiPanelRegressionBase:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self:InitCb()
    self:InitUi()
end

function XUiPanelRegressionBase:Show()
end

function XUiPanelRegressionBase:Hide()
end

function XUiPanelRegressionBase:InitCb()
end

function XUiPanelRegressionBase:InitUi()
end

function XUiPanelRegressionBase:UpdateTime()
end

return XUiPanelRegressionBase