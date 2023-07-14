local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntChipUpAttr = require("XUi/XUiDlcHunt/ChipLvUp/XUiDlcHuntChipUpAttr")
local XUiDlcHuntChipUpMagic = require("XUi/XUiDlcHunt/ChipLvUp/XUiDlcHuntChipUpMagic")

---@class XUiDlcHuntChipUp:XLuaUi
local XUiDlcHuntChipUp = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipUp")

function XUiDlcHuntChipUp:Ctor()
    self._UiAttr = {}
    self._UiMagic = {}
end

function XUiDlcHuntChipUp:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

---@param chipBefore XDlcHuntChip
---@param chipAfter XDlcHuntChip
function XUiDlcHuntChipUp:OnStart(chipAfter, chipBefore)
    if not chipBefore then
        chipBefore = chipAfter:Clone()
        local breakthroughTimes = chipAfter:GetBreakthroughTimes() - 1
        if breakthroughTimes < 0 then
            XLog.Warning("[XUiDlcHuntChipUp] breakthroughTimes error")
            return
        end
        chipBefore:SetBreakthroughTimes(breakthroughTimes)
        chipBefore:SetLevel(chipBefore:GetMaxLevel())
    end

    -- Attr
    local attrTable = {}
    local attBefore = chipBefore:GetAttrTableLvUp()
    local attrAfter = chipAfter:GetAttrTableLvUp()

    for attrId, valueBefore in pairs(attBefore) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) then
            local valueAfter = attrAfter[attrId] or 0
            if valueAfter > 0 then
                valueBefore = valueBefore or 0
                local attrName = XDlcHuntAttrConfigs.GetAttrName(attrId)
                local priority = XDlcHuntAttrConfigs.GetAttrPriority(attrId)
                local attrData = {
                    Name = XUiHelper.GetText("DlcHuntPopUpAttrPrefix", attrName),
                    ValueBefore = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, valueBefore, true),
                    ValueAfter = XDlcHuntAttrConfigs.GetValueWithPercent(attrId, valueAfter, true),
                    Priority = priority
                }
                attrTable[#attrTable + 1] = attrData
            end
        end
    end
    XUiDlcHuntUtil.SortAttr(attrTable)
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttr, attrTable, self.GridChipReplace, XUiDlcHuntChipUpAttr)

    -- Magic
    local magicTable = {}
    local magicDescBefore = chipBefore:GetMagicDesc()
    local magicDescAfter = chipAfter:GetMagicDesc()
    for i = 1, #magicDescAfter do
        local magicAfter = magicDescAfter[i]
        if magicAfter then
            local isUp = false
            local isNew = true
            for j = 1, #magicDescBefore do
                local magicBefore = magicDescBefore[j]
                if magicBefore.Type == magicAfter.Type then
                    isNew = false
                    local valueAfter = magicAfter.Params[1] or 0
                    local valueBefore = magicBefore.Params[1] or 0
                    if valueAfter > valueBefore then
                        isUp = true
                    end
                end
            end
            if isUp or isNew then
                magicTable[#magicTable + 1] = {
                    Name = magicAfter.Name,
                    IsNew = isNew,
                    IsUp = isUp
                }
            end
        end
    end
    
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiMagic, magicTable, self.GridChipReplaceAdd, XUiDlcHuntChipUpMagic)
end

return XUiDlcHuntChipUp