---@class XUiGridRogueSimEventOption : XUiNode
---@field private _Control XRogueSimControl
---@field BtnOption XUiComponent.XUiButton
local XUiGridRogueSimEventOption = XClass(XUiNode, "XUiGridRogueSimEventOption")

function XUiGridRogueSimEventOption:OnStart()
    self.GridCost.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridCostList = {}
end

function XUiGridRogueSimEventOption:Refresh(optionId)
    self.OptionId = optionId
    -- 名称
    local name = self._Control.MapSubControl:GetEventOptionName(optionId)
    self.BtnOption:SetNameByGroup(0, name)
    -- 描述
    local desc = self._Control.MapSubControl:GetEventOptionDesc(optionId)
    self.BtnOption:SetNameByGroup(1, desc)
    -- 是否满足条件
    local result, _ = self._Control.MapSubControl:CheckEventOptionCondition(optionId)
    self.BtnOption:SetDisable(not result)
    -- 刷新消耗
    self:RefreshCost()
end

-- 刷新消耗
function XUiGridRogueSimEventOption:RefreshCost()
    local costResourceInfos = self._Control.MapSubControl:GetEventOptionCostResourceInfos(self.OptionId)
    local costCommodityInfos = self._Control.MapSubControl:GetEventOptionCostCommodityInfos(self.OptionId)
    local index = 1
    for _, info in ipairs(costResourceInfos) do
        local grid = self.GridCostList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridCost, self.PanelCost)
            self.GridCostList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("Icon"):SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(info.Id))
        grid:GetObject("TxtCount").text = string.format("-%d", info.Count)
        index = index + 1
    end
    for _, info in ipairs(costCommodityInfos) do
        local grid = self.GridCostList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridCost, self.PanelCost)
            self.GridCostList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("Icon"):SetRawImage(self._Control.ResourceSubControl:GetCommodityIcon(info.Id))
        grid:GetObject("TxtCount").text = string.format("-%d", info.Count)
        index = index + 1
    end
    for i = index, #self.GridCostList do
        self.GridCostList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridRogueSimEventOption:GetBtn()
    return self.BtnOption
end

return XUiGridRogueSimEventOption
