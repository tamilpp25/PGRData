local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")
local XDlcHuntChipGroupOtherPlayer = require("XEntity/XDlcHunt/XDlcHuntChipGroupOtherPlayer")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XDlcHuntPlayerDetail
local XDlcHuntPlayerDetail = XClass(nil, "DlcHuntPlayerDetail")

function XDlcHuntPlayerDetail:Ctor()
    self._PlayerName = ""
    self._PlayerLevel = 0
    self._HonorLevel = 0
    self._PlayerId = 0
    self._HeadInfo = {
        HeadPortraitId = 0,
        HeadFrameId = 0,
    }
    self._Like = 0
    self._Sign = ""
    self._CharacterId = 0

    ---@type XDlcHuntChipGroupOtherPlayer
    self._ChipGroup = XDlcHuntChipGroupOtherPlayer.New()
    ---@type XDlcHuntChip
    self._ChipAssistant = XDlcHuntChip.New()
    self._FightingPower = 0
    self._AttrTable = {}
end

function XDlcHuntPlayerDetail:SetData(data)
    self._PlayerName = data.Name
    self._PlayerLevel = data.Level
    self._HonorLevel = data.HonorLevel
    self._PlayerId = data.Id
    self._HeadInfo = {
        HeadPortraitId = data.CurrHeadPortraitId,
        HeadFrameId = data.CurrHeadFrameId,
    }
    self._Like = data.Likes
    self._Sign = data.Sign
    self._CharacterId = data.DlcCharacterId

    self._ChipGroup:Clear()
    self._ChipGroup:SetData(data.ChipDataList)

    self._ChipAssistant = XDlcHuntChip.New()
    self._ChipAssistant:SetData(data.DlcAssistChipData)
    self._ChipAssistant:SetPlayerName(self._PlayerName)
    self._ChipAssistant:SetPlayerId(self._PlayerId)

    local characterAttr = XDlcHuntCharacterConfigs.GetCharacterAttrTable(self._CharacterId)
    local chipGroupAttr = self._ChipGroup:GetAttrTable()
    local chipAssistantAttr = self._ChipAssistant:GetAttrTable()
    self._AttrTable = XUiDlcHuntUtil.GetSumAttrTable(characterAttr, chipGroupAttr, chipAssistantAttr)
    self._FightingPower = XDlcHuntAttrConfigs.GetFightingPower(self._AttrTable)
end

function XDlcHuntPlayerDetail:GetPlayerName()
    return self._PlayerName
end

function XDlcHuntPlayerDetail:GetLevel()
    if self._HonorLevel > 0 then
        return self._HonorLevel
    end
    return self._PlayerLevel
end

function XDlcHuntPlayerDetail:GetPlayerId()
    return self._PlayerId
end

function XDlcHuntPlayerDetail:GetSign()
    return self._Sign
end

function XDlcHuntPlayerDetail:GetLike()
    return self._Like
end

function XDlcHuntPlayerDetail:AddLike()
    self._Like = self._Like + 1
end

function XDlcHuntPlayerDetail:GetHeadInfo()
    return self._HeadInfo.HeadPortraitId, self._HeadInfo.HeadFrameId
end

function XDlcHuntPlayerDetail:GetCharacterIcon()
    return XDlcHuntCharacterConfigs.GetCharacterHalfBodyImage(self._CharacterId)
end

function XDlcHuntPlayerDetail:GetCharacterName()
    return XDlcHuntCharacterConfigs.GetCharacterName(self._CharacterId)
end

function XDlcHuntPlayerDetail:GetFightingPower()
    return self._FightingPower
end

function XDlcHuntPlayerDetail:GetMainChip()
    for i = 1, self._ChipGroup:GetAmount() do
        local chip = self._ChipGroup:GetChip(i)
        if chip and chip:IsMainChip() then
            return chip
        end
    end
    return false
end

function XDlcHuntPlayerDetail:GetAssistantChip()
    return self._ChipAssistant
end

function XDlcHuntPlayerDetail:GetAttrTable()
    return self._AttrTable
end

function XDlcHuntPlayerDetail:GetChipGroup()
    return self._ChipGroup
end

return XDlcHuntPlayerDetail