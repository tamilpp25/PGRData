
local XUiPivotCombatEnvGrid = XClass(nil, "XUiPivotCombatEnvGrid")

function XUiPivotCombatEnvGrid:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
end 

function XUiPivotCombatEnvGrid:Refresh(text)
    self.TxtDesc.text = text
end 

return XUiPivotCombatEnvGrid