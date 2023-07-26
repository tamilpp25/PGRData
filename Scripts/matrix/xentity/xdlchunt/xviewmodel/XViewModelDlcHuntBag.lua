local XViewModelDlcHuntBagChildChip = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntBagChildChip")
local XViewModelDlcHuntBagChildOthers = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntBagChildOthers")
local XDlcHuntItem = require("XEntity/XDlcHunt/XDlcHuntItem")
local CHIP_FILTER_IGNORE = XDlcHuntChipConfigs.CHIP_FILTER_IGNORE

local XDlcHuntFilterCondition = require("XEntity/XDlcHunt/XDlcHuntFilterCondition")
local TAB = XDlcHuntConfigs.TAB_BAG

---@class XViewModelDlcHuntBag
local XViewModelDlcHuntBag = XClass(nil, "XViewModelDlcHuntBag")

function XViewModelDlcHuntBag:Ctor()
    self._Tab = TAB.MAIN_CHIP

    -- 主芯片
    local conditionMain = XDlcHuntFilterCondition.New()
    conditionMain.Ignore = conditionMain.Ignore | CHIP_FILTER_IGNORE.MAIN
    self._ModelViewChildMain = XViewModelDlcHuntBagChildChip.New(conditionMain)

    -- 从属芯片
    local conditionSub = XDlcHuntFilterCondition.New()
    conditionSub.Ignore = conditionSub.Ignore | CHIP_FILTER_IGNORE.SUB
    self._ModelViewChildSub = XViewModelDlcHuntBagChildChip.New(conditionSub)

    -- 其他（碎片）
    ---@type XViewModelDlcHuntBagChildOthers
    self._ModelViewChildOthers = XViewModelDlcHuntBagChildOthers.New()

    self._IsShowDecompose = false
    self._ChipsSelected4Decompose = {}
    self._StarSelected = {}
end

function XViewModelDlcHuntBag:SetTabIndex(index)
    self._Tab = index
end

function XViewModelDlcHuntBag:GetTabIndex()
    return self._Tab
end

---@return XViewModelDlcHuntBagChildChip
function XViewModelDlcHuntBag:GetViewModelChild()
    if self._Tab == TAB.MAIN_CHIP then
        return self._ModelViewChildMain
    end
    if self._Tab == TAB.SUB_CHIP then
        return self._ModelViewChildSub
    end
    if self._Tab == TAB.OTHERS then
        return self._ModelViewChildOthers
    end
    error("[XViewModelDlcHuntBag] invalid tab:", tostring(self._Tab))
end

function XViewModelDlcHuntBag:GetAmount()
    if self._Tab == TAB.MAIN_CHIP then
        return XDataCenter.DlcHuntChipManager.GetChipAmountMain(), XDlcHuntChipConfigs.CHIP_MAIN_CAPACITY
    end
    if self._Tab == TAB.SUB_CHIP then
        return XDataCenter.DlcHuntChipManager.GetChipAmountSub(), XDlcHuntChipConfigs.CHIP_SUB_CAPACITY
    end
    if self._Tab == TAB.OTHERS then
        return #self._ModelViewChildOthers:GetAllItem(), XDlcHuntChipConfigs.ITEM_CAPACITY
    end
    return 0, 0
end

function XViewModelDlcHuntBag:GetConditionDecompose()
    local condition = XDlcHuntFilterCondition.New()
    if self._Tab == TAB.MAIN_CHIP then
        condition.Ignore = condition.Ignore | CHIP_FILTER_IGNORE.MAIN
    end
    if self._Tab == TAB.SUB_CHIP then
        condition.Ignore = condition.Ignore | CHIP_FILTER_IGNORE.SUB
    end
    return condition
end

function XViewModelDlcHuntBag:IsShowPanelSort()
    return self._Tab == TAB.MAIN_CHIP
            or self._Tab == TAB.SUB_CHIP
end

function XViewModelDlcHuntBag:GetAllItem()
    local allItem = self:GetViewModelChild():GetAllItem()
    -- 分解界面，不显示已佩戴 or 援助中
    if self._IsShowDecompose then
        local result = {}
        for i = 1, #allItem do
            ---@type XDlcHuntChip
            local chip = allItem[i]
            if not chip:HasSetAsAssistantChip2Others()
                    and not chip:IsInUse()
                    and not chip:IsLock()
            then
                result[#result + 1] = chip
            end
        end
        return result
    end
    return allItem
end

function XViewModelDlcHuntBag:SetFilterType(index)
    -- ui按钮顺序：星级，突破，等级，最近
    if index == 1 then
        self:GetViewModelChild():SetFilterType(XDlcHuntChipConfigs.CHIP_FILTER_TYPE.STAR)
        return
    end
    if index == 2 then
        self:GetViewModelChild():SetFilterType(XDlcHuntChipConfigs.CHIP_FILTER_TYPE.BREAKTHROUGH)
        return
    end
    if index == 3 then
        self:GetViewModelChild():SetFilterType(XDlcHuntChipConfigs.CHIP_FILTER_TYPE.LEVEL)
        return
    end
    if index == 4 then
        self:GetViewModelChild():SetFilterType(XDlcHuntChipConfigs.CHIP_FILTER_TYPE.RECENTLY)
        return
    end
    XLog.Error("[XViewModelDlcHuntBag] unhandled sort index", index)
end

function XViewModelDlcHuntBag:GetFilterType()
    local type = self:GetViewModelChild():GetFilterType()
    if type == XDlcHuntChipConfigs.CHIP_FILTER_TYPE.STAR then
        return 1
    end
    if type == XDlcHuntChipConfigs.CHIP_FILTER_TYPE.BREAKTHROUGH then
        return 2
    end
    if type == XDlcHuntChipConfigs.CHIP_FILTER_TYPE.LEVEL then
        return 3
    end
    if type == XDlcHuntChipConfigs.CHIP_FILTER_TYPE.RECENTLY then
        return 4
    end
    return 1
end

function XViewModelDlcHuntBag:IsAscend()
    return self:GetViewModelChild():IsAscend()
end

function XViewModelDlcHuntBag:SetFilterOrderInverse()
    self:GetViewModelChild():SetFilterOrderInverse()
end

function XViewModelDlcHuntBag:SetVisibleDecomposeInverse()
    self._IsShowDecompose = not self._IsShowDecompose
    if self._IsShowDecompose then
        for star, isSelected in pairs(self._StarSelected) do
            self:SetStarSelected(star, isSelected)
        end
    else
        self:ClearDecomposeSelected()
        for star, isSelected in pairs(self._StarSelected) do
            self:SetStarSelected(star, false)
        end
    end
    self:SendEventUpdateChipSelected(true)
end

function XViewModelDlcHuntBag:IsVisibleDecompose()
    return self._IsShowDecompose
end

function XViewModelDlcHuntBag:IsCanSelectGrid()
    return self:IsVisibleDecompose()
end

--region decompose 把分解，合并到背包界面
---@param chip XDlcHuntChip
function XViewModelDlcHuntBag:SetChipSelected(chip)
    if not chip then
        return
    end
    self._ChipsSelected4Decompose[chip:GetUid()] = true
end

function XViewModelDlcHuntBag:SetChipUnselected(chipId)
    self._ChipsSelected4Decompose[chipId] = false
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntBag:SetChipSelectedInverse(chip)
    local uid = chip:GetUid()
    if self._ChipsSelected4Decompose[uid] then
        self._ChipsSelected4Decompose[uid] = nil
    else
        self._ChipsSelected4Decompose[uid] = true
    end
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_UPDATE)
end

---@param chip XDlcHuntChip
function XViewModelDlcHuntBag:IsChipSelected(chip)
    if not self._IsShowDecompose then
        return false
    end
    return self._ChipsSelected4Decompose[chip:GetUid()]
end

---@return XDlcHuntChip[]
function XViewModelDlcHuntBag:_GetChipsSelected()
    local result = {}
    for uid, isSelected in pairs(self._ChipsSelected4Decompose) do
        if isSelected then
            local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
            result[#result + 1] = chip
        end
    end
    return result
end

---@return XDlcHuntItem[]
function XViewModelDlcHuntBag:GetDecomposeResult()
    local result = {}
    local itemDict = {}
    local chips = self:_GetChipsSelected()
    for i = 1, #chips do
        local chip = chips[i]
        local decomposeResult = chip:GetDecomposeResult()
        itemDict[decomposeResult.ItemId] = (itemDict[decomposeResult.ItemId] or 0) + decomposeResult.ItemCount
    end
    for itemId, itemCount in pairs(itemDict) do
        ---@type XDlcHuntItem
        local item = XDlcHuntItem.New()
        item:SetAmount(itemCount)
        item:SetItemId(itemId)
        result[#result + 1] = item
    end
    return result
end

function XViewModelDlcHuntBag:GetDecomposeAmount()
    local amount = 0
    for uid, isSelected in pairs(self._ChipsSelected4Decompose) do
        if isSelected then
            amount = amount + 1
        end
    end
    return amount
end

function XViewModelDlcHuntBag:IsCanDecompose()
    return self:GetDecomposeAmount() > 0
end

-- 背包会满
function XViewModelDlcHuntBag:IsBagNotEnoughToHold()
    local decomposeResult = self:GetDecomposeResult()
    for i = 1, #decomposeResult do
        local item = decomposeResult[i]
        local itemId = item:GetItemId()
        local ownItem = XDataCenter.ItemManager.GetItem(itemId)
        local onwAmount = ownItem and ownItem.Count
        if onwAmount + item:GetAmount() > item:GetCapacity() then
            return true
        end
    end
    return false
end

function XViewModelDlcHuntBag:DecomposeChips()
    if not self:IsCanDecompose() then
        return
    end
    if self:IsBagNotEnoughToHold() then
        XUiManager.TipText("DlcHuntChipDecomposeFull")
        return
    end
    XDataCenter.DlcHuntChipManager.DecomposeChips(self:_GetChipsSelected())
end

function XViewModelDlcHuntBag:SetStarSelected(star, isSelected)
    self._StarSelected[star] = isSelected
    if isSelected then
        local allChips = self:GetAllItem()
        for i = 1, #allChips do
            ---@type XDlcHuntChip
            local chip = allChips[i]
            if chip:GetStarAmount() == star and not chip:HasSetAsAssistantChip2Others() then
                self._ChipsSelected4Decompose[chip:GetUid()] = true
            end
        end
    else
        for uid, isHasSelected in pairs(self._ChipsSelected4Decompose) do
            if isHasSelected then
                local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
                if chip and chip:GetStarAmount() == star then
                    self._ChipsSelected4Decompose[uid] = nil
                end
            end
        end
    end
end

function XViewModelDlcHuntBag:SendEventUpdateChipSelected(updateItem)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_SELECT_UPDATE, updateItem)
end

function XViewModelDlcHuntBag:PickOutInvalidChip()
    for uid, isHasSelected in pairs(self._ChipsSelected4Decompose) do
        local chip = XDataCenter.DlcHuntChipManager.GetChip(uid)
        if not chip then
            self._ChipsSelected4Decompose[uid] = nil
        end
    end
end

function XViewModelDlcHuntBag:IsShowBtnDecompose()
    return self._Tab ~= TAB.OTHERS
end

function XViewModelDlcHuntBag:ClearDecomposeSelected()
    for uid, _ in pairs(self._ChipsSelected4Decompose) do
        self._ChipsSelected4Decompose[uid] = nil
    end
end

function XViewModelDlcHuntBag:ClearInvalidSelected()
    for uid, _ in pairs(self._ChipsSelected4Decompose) do
        if not XDataCenter.DlcHuntChipManager.GetChip(uid) then
            self._ChipsSelected4Decompose[uid] = false
        end
    end
end
--endregion decompose

return XViewModelDlcHuntBag