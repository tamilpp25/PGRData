---@class XViewModelDlcHuntBagChildOthers
local XViewModelDlcHuntBagChildOthers = XClass(nil, "XViewModelDlcHuntBagChildOthers")

function XViewModelDlcHuntBagChildOthers:Ctor()
end

function XViewModelDlcHuntBagChildOthers:GetAllItem()
    local items = XDataCenter.ItemManager.GetItemsByType(XItemConfigs.ItemType.DlcItem)
    return items
end

function XViewModelDlcHuntBagChildOthers:IsAscend()
    return true
end

function XViewModelDlcHuntBagChildOthers:GetFilterType()
    return 1
end

return XViewModelDlcHuntBagChildOthers