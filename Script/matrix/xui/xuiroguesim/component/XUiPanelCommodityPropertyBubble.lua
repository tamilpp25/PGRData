local XUiPanelRogueSimBaseBubble = require("XUi/XUiRogueSim/Component/XUiPanelRogueSimBaseBubble")
---@class XUiPanelCommodityPropertyBubble : XUiPanelRogueSimBaseBubble
---@field private _Control XRogueSimControl
local XUiPanelCommodityPropertyBubble = XClass(XUiPanelRogueSimBaseBubble, "XUiPanelCommodityPropertyBubble")

function XUiPanelCommodityPropertyBubble:OnStart()
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridBubbleList = {}
end

function XUiPanelCommodityPropertyBubble:SetInfo(info)
    self.IsPrice = info and info.IsPrice or false
    self.CurAlignment = info and info.Alignment or XEnumConst.RogueSim.Alignment.LC
    self:SetAnchorAndPivot()
end

function XUiPanelCommodityPropertyBubble:Refresh(targetTransform, id, info)
    self:SetInfo(info)
    self:SetTransform(targetTransform)
    self.Id = id
    local bubbleGroupId = self._Control.ResourceSubControl:GetCommodityBubbleGroupId(self.Id)
    if not XTool.IsNumberValid(bubbleGroupId) then
        return
    end
    if self.IsPrice then
        local prices = self._Control.ResourceSubControl:GetCommodityPriceBubbleGroup(bubbleGroupId)
        self:RefreshBubble(prices)
    else
        local productions = self._Control.ResourceSubControl:GetCommodityProductionBubbleGroup(bubbleGroupId)
        self:RefreshBubble(productions)
    end
end

function XUiPanelCommodityPropertyBubble:RefreshBubble(ids)
    for index, id in pairs(ids) do
        local grid = self.GridBubbleList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, self.PanelPropertyBubble)
            self.GridBubbleList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtName").text = self._Control.ResourceSubControl:GetCommodityBubbleName(id)
        local methodName = self._Control.ResourceSubControl:GetCommodityBubbleMethodName(id)
        local paramNames = self._Control.ResourceSubControl:GetCommodityBubbleParamNames(id)
        local args = {}
        for _, paramName in pairs(paramNames) do
            table.insert(args, self[paramName])
        end
        grid:GetObject("TxtNum").text = self._Control.ResourceSubControl[methodName](self._Control.ResourceSubControl, table.unpack(args))
    end
    for i = #ids + 1, #self.GridBubbleList do
        self.GridBubbleList[i].gameObject:SetActiveEx(false)
    end
end

return XUiPanelCommodityPropertyBubble
