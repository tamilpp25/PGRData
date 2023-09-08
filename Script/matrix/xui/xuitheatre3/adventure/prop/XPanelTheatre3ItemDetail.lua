local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XPanelTheatre3ItemDetail : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3ItemDetail = XClass(XUiNode, "XPanelTheatre3ItemDetail")

function XPanelTheatre3ItemDetail:OnStart()
    ---@type XUiGridTheatre3Reward
    self._ItemGrid = XUiGridTheatre3Reward.New(self.GridProp, self)
end

function XPanelTheatre3ItemDetail:CheckCurTypeIsProp()
    return true
end

function XPanelTheatre3ItemDetail:CheckCurTypeIsSet()
    return false
end

function XPanelTheatre3ItemDetail:Refresh(itemId)
    local itemCfg = self._Control:GetItemConfigById(itemId)
    self._ItemGrid:SetData(itemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
    self._ItemGrid:ShowRed(false)
    self.TxtName.text = itemCfg.Name
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(XUiHelper.FormatText(itemCfg.Description, self._Control:GetItemEffectGroupDesc(itemId)))
    self.TxtWorldDesc.text = itemCfg.WorldDesc
    if self.PanelCondition then
        self.PanelCondition.gameObject:SetActiveEx(false)
    end
end

return XPanelTheatre3ItemDetail