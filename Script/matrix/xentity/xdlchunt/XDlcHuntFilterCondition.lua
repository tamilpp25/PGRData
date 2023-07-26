---@class XDlcHuntFilterCondition
local XDlcHuntFilterCondition = XClass(nil, "XDlcHuntFilterCondition")

function XDlcHuntFilterCondition:Ctor()
    self.Ignore = XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.NONE
    self.ChipGroupId = false
    self.Star = XDlcHuntChipConfigs.STAR.ALL
end

function XDlcHuntFilterCondition:IsMainChip()
    return self.Ignore & XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.MAIN ~= 0
end

function XDlcHuntFilterCondition:IsSubChip()
    return self.Ignore & XDlcHuntChipConfigs.CHIP_FILTER_IGNORE.SUB ~= 0
end

return XDlcHuntFilterCondition