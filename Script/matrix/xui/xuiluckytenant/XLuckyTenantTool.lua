local XUiLuckyTenantChessBagProp = require("XUi/XUiLuckyTenant/Game/Bag/XUiLuckyTenantChessBagProp")
local XLuckyTenantTool = {}

---@param ui XLuaUi
---@param control XLuckyTenantControl
function XLuckyTenantTool.UpdateProp(ui, control)
    if not ui.Prop2 then
        ui.Prop2 = XUiHelper.Instantiate(ui.Prop1, ui.Prop1.parent)
    end
    control:UpdateProp()
    ui.GridProp1 = ui.GridProp1 or XUiLuckyTenantChessBagProp.New(ui.Prop1, ui)
    ui.GridProp2 = ui.GridProp2 or XUiLuckyTenantChessBagProp.New(ui.Prop2, ui)
    local uiData = control:GetUiData()
    ui.GridProp1:Update(uiData.Prop[1])
    ui.GridProp2:Update(uiData.Prop[2])
end

return XLuckyTenantTool