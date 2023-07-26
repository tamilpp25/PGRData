
local XUiPivotCombatEfficiencyGrid = XClass(nil, "XUiPivotCombatEfficiencyGrid")

function XUiPivotCombatEfficiencyGrid:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
end 

function XUiPivotCombatEfficiencyGrid:Refresh(text)
    self.TxtEnergy.text = text
end 

return XUiPivotCombatEfficiencyGrid