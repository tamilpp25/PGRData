local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")
local XDlcHuntChipGroup = require("XEntity/XDlcHunt/XDlcHuntChipGroup")

---@class XDlcHuntChipGroupOtherPlayer:XDlcHuntChipGroup
local XDlcHuntChipGroupOtherPlayer = XClass(XDlcHuntChipGroup, "XDlcHuntChipGroupOtherPlayer")

function XDlcHuntChipGroupOtherPlayer:SetData(chipDataList)
    if not chipDataList then
        self:Clear()
        return
    end
    for i = 1, #chipDataList do
        local chipData = chipDataList[i]
        local chip = XDlcHuntChip.New()
        chip:SetData(chipData)
        self._Group[i] = chip
    end
end

function XDlcHuntChipGroupOtherPlayer:SetChip(chipUid, pos)
    XLog.Error("[XDlcHuntChipGroupOtherPlayer] 此函数在继承后无效")
end

---@return XDlcHuntChip
function XDlcHuntChipGroupOtherPlayer:GetChip(pos)
    return self._Group[pos]
end

function XDlcHuntChipGroupOtherPlayer:Clear()
    self._Group = {}
end

return XDlcHuntChipGroupOtherPlayer