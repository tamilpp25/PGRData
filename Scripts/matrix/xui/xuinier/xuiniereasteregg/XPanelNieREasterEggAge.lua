local XPanelNieREasterEggAge = XClass(nil, "XPanelNieREasterEggAge")

local InitAge = 19
function XPanelNieREasterEggAge:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Btn.CallBack = function() self:OnBtn1Click() end
    self.Btn2.CallBack = function() self:OnBtn2Click() end
end

function XPanelNieREasterEggAge:Init()
    self.MinAge, self.MaxAge = XDataCenter.NieRManager.GetCurNieREasterEggAgeInfo()
    self:UpdateCurAge(InitAge)
end

function XPanelNieREasterEggAge:OnBtn1Click()
    if self.CurAge == self.MinAge then
        return 
    end
    self:UpdateCurAge(self.CurAge - 1)
end

function XPanelNieREasterEggAge:OnBtn2Click()
    if self.CurAge == self.MaxAge then
        return 
    end
    self:UpdateCurAge(self.CurAge + 1)
end

function XPanelNieREasterEggAge:UpdateCurAge(age)
    self.CurAge = age
    self.Text.text = age
    self.RootUi:SetNieREasterEggAge(age)
end

return XPanelNieREasterEggAge