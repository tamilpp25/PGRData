local XUiGridTheatre3Prop = require("XUi/XUiTheatre3/Handbook/XUiGridTheatre3Prop")

---@class XUiPanelTheatre3Prop : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3Handbook
local XUiPanelTheatre3Prop = XClass(XUiNode, "XUiPanelTheatre3Prop")

function XUiPanelTheatre3Prop:OnStart(callBack)
    self.CallBack = callBack
    self.PropGrid.gameObject:SetActiveEx(false)
    self.PropGridSet.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre3Prop:GetGridObj()
    local go
    if self.Parent:CheckCurTypeIsProp() then
        go = XUiHelper.Instantiate(self.PropGrid, self.PanelGroup)
    elseif self.Parent:CheckCurTypeIsSet() then
        go = XUiHelper.Instantiate(self.PropGridSet, self.PanelGroup)
    end
    return go
end

---@param typeId number 套装类型id|物品类型id
function XUiPanelTheatre3Prop:Refresh(typeId)
    self.TypeId = typeId
    -- 标题
    self.TxtTitle.text = self.Parent:GetTypeName(typeId)
    -- 列表
    local idList = self.Parent:GetIdListByTypeId(typeId)
    for _, id in pairs(idList) do
        local grid = self.Parent:GetGridProp()
        if not grid then
            local go = self:GetGridObj()
            grid = XUiGridTheatre3Prop.New(go, self.Parent, self.CallBack)
            self.Parent:AddGridProp(grid)
        end
        grid:Open()
        grid:Refresh(id)
    end
end

return XUiPanelTheatre3Prop