local CHIP_FILTER_TYPE = XDlcHuntChipConfigs.CHIP_FILTER_TYPE
local CHIP_FILTER_ORDER = XDlcHuntChipConfigs.CHIP_FILTER_ORDER

local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XViewModelDlcHuntChipFilter
local XViewModelDlcHuntChipFilter = XClass(nil, "XViewModelDlcHuntChipFilter")

function XViewModelDlcHuntChipFilter:Ctor()
    self._FilterSort = {
        Type = CHIP_FILTER_TYPE.STAR,
        Order = CHIP_FILTER_ORDER.ASC
    }
    ---@type XDlcHuntFilterCondition
    self._FilterCondition = false
end

function XViewModelDlcHuntChipFilter:SetFilterCondition(condition)
    self._FilterCondition = condition
end

function XViewModelDlcHuntChipFilter:GetAllItem()
    local allChips = XDataCenter.DlcHuntChipManager.GetAllChip()
    local filterType = self._FilterSort.Type
    local orderType = self._FilterSort.Order
    local chips = XUiDlcHuntUtil.GetSortedChip(allChips, filterType, orderType)
    for i = #chips, 1, -1 do
        local chip = chips[i]
        if not chip:IsMatch(self._FilterCondition) then
            table.remove(chips, i)
        end
    end
    return chips
end

function XViewModelDlcHuntChipFilter:SetFilterOrder(order)
    self._FilterSort.Order = order
end

function XViewModelDlcHuntChipFilter:SetFilterType(filterType)
    self._FilterSort.Type = filterType
end

function XViewModelDlcHuntChipFilter:SetFilterTypeByIndex(index)
    -- ui按钮顺序：星级，突破，等级，最近
    if index == 0 then
        self:SetFilterType(CHIP_FILTER_TYPE.STAR)
        return
    end
    if index == 1 then
        self:SetFilterType(CHIP_FILTER_TYPE.BREAKTHROUGH)
        return
    end
    if index == 2 then
        self:SetFilterType(CHIP_FILTER_TYPE.LEVEL)
        return
    end
    if index == 3 then
        self:SetFilterType(CHIP_FILTER_TYPE.RECENTLY)
        return
    end
    XLog.Error("[XViewModelDlcHuntChipFilter] unhandled sort index", index)
end

function XViewModelDlcHuntChipFilter:GetFilterType()
    return self._FilterSort.Type
end

function XViewModelDlcHuntChipFilter:SetFilterOrderInverse()
    if self._FilterSort.Order == CHIP_FILTER_ORDER.DESC then
        self:SetFilterOrder(CHIP_FILTER_ORDER.ASC)
        return
    end
    if self._FilterSort.Order == CHIP_FILTER_ORDER.ASC then
        self:SetFilterOrder(CHIP_FILTER_ORDER.DESC)
        return
    end
end

function XViewModelDlcHuntChipFilter:GetFilterIndex()
    return self._FilterSort.Type
end

function XViewModelDlcHuntChipFilter:GetFilterOrder()
    return self._FilterSort.Order
end

function XViewModelDlcHuntChipFilter:IsAscend()
    return self:GetFilterOrder() == CHIP_FILTER_ORDER.ASC
end

return XViewModelDlcHuntChipFilter