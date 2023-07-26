local XDlcHuntModel = require("XEntity/XDlcHunt/XDlcHuntModel")
local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")
local XDlcHuntChipGroupOtherPlayer = require("XEntity/XDlcHunt/XDlcHuntChipGroupOtherPlayer")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XDlcHuntMember
local XDlcHuntMember = XClass(nil, "XDlcHuntMember")

function XDlcHuntMember:Ctor()
    self._CharacterId = false
    self._PlayerId = false
    self._IsLeader = false
    self._State = false
    self._PlayerName = false
    self._FightingPower = 0
    ---@type XDlcHuntModel
    self._DataModel = false
    self._Chips = {}
    ---@type XDlcHuntChipGroupOtherPlayer
    self._ChipGroup = XDlcHuntChipGroupOtherPlayer.New()
    self._ChipAssistant = false
end

function XDlcHuntMember:Reset()
    self._CharacterId = false
    self._PlayerId = false
    self._IsLeader = false
    self._State = false
    self._PlayerName = false
    self._FightingPower = 0
    self._ChipGroup:Clear()
    self._ChipAssistant = false
end

function XDlcHuntMember:GetPlayerName()
    return self._PlayerName
end

-- XDlcRoomPlayerData
function XDlcHuntMember:SetRoomData(dlcRoomPlayerData)
    if not dlcRoomPlayerData then
        self:Reset()
        return
    end
    local worldNpcData = dlcRoomPlayerData.WorldNpcData
    local character = worldNpcData.Character
    self._CharacterId = character.Id
    self._PlayerId = dlcRoomPlayerData.Id
    self._IsLeader = dlcRoomPlayerData.Leader
    self._State = dlcRoomPlayerData.State
    self._PlayerName = dlcRoomPlayerData.Name
    if self._PlayerId == XPlayer.Id then
        local assistChipData2MySelf = dlcRoomPlayerData.AssistChipData
        if assistChipData2MySelf then
            XDataCenter.DlcHuntChipManager.SetAssistantChipToMyself(assistChipData2MySelf)
        end
    end
    self._ChipGroup:Clear()
    self._ChipGroup:SetData(worldNpcData.Chips or {})
    --chip:SetPlayerId(self._PlayerId)
    --chip:SetPlayerName(self._PlayerName)

    self._ChipAssistant = false
    local assistantChipData = worldNpcData.SelfAssistChipData
    if assistantChipData then
        ---@type XDlcHuntChip
        self._ChipAssistant = XDlcHuntChip.New()
        self._ChipAssistant:SetData(assistantChipData)
        self._ChipAssistant:SetFromType(XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.TEAMMATE)
        self._ChipAssistant:SetPlayerId(self:GetPlayerId())
        self._ChipAssistant:SetPlayerName(self:GetPlayerName())
    end

    local characterAttr = XDlcHuntCharacterConfigs.GetCharacterAttrTable(self._CharacterId)
    local chipGroupAttr = self._ChipGroup:GetAttrTable()
    local attrTable = XUiDlcHuntUtil.GetSumAttrTable(characterAttr, chipGroupAttr)
    self._FightingPower = XDlcHuntAttrConfigs.GetFightingPower(attrTable)
end

function XDlcHuntMember:IsLeader()
    return self._IsLeader
end

function XDlcHuntMember:IsReady()
    return self:IsLeader() or self._State == XFubenUnionKillConfigs.UnionRoomPlayerState.Ready
end

function XDlcHuntMember:IsSelecting()
    return self._State == XFubenUnionKillConfigs.UnionRoomPlayerState.Select
end

function XDlcHuntMember:GetPlayerId()
    return self._PlayerId
end

function XDlcHuntMember:GetCharacterId()
    return self._CharacterId
end

function XDlcHuntMember:GetNpcId()
    return XDlcHuntCharacterConfigs.GetCharacterNpcId(self:GetCharacterId())
end

function XDlcHuntMember:IsEmpty()
    return not self:GetCharacterId() or self:GetCharacterId() == 0
end

function XDlcHuntMember:GetName()
    return XDlcHuntCharacterConfigs.GetCharacterName(self:GetCharacterId())
end

function XDlcHuntMember:IsMyCharacter()
    return self:GetPlayerId() == XPlayer.Id
end

function XDlcHuntMember:Equals(character)
    return self:GetPlayerId() == character:GetPlayerId()
            and self._CharacterId == character:GetCharacterId()
end

function XDlcHuntMember:_GetModelId()
    return XDlcHuntCharacterConfigs.GetCharacterModelId(self:GetCharacterId())
end

function XDlcHuntMember:GetReadyState()
    return self._State
end

function XDlcHuntMember:GetAbility()
    return self._FightingPower
end

function XDlcHuntMember:GetDataModel()
    if not self._DataModel then
        self._DataModel = XDlcHuntModel.New()
    end
    self._DataModel:SetDataByMember(self)
    return self._DataModel
end

function XDlcHuntMember:GetMainChip()
    return self._ChipGroup:GetMainChip()
end

function XDlcHuntMember:GetAssistantChip()
    return self._ChipAssistant
end

function XDlcHuntMember:IsSelectAssistantChip2Myself()
    if not self:IsMyCharacter() then
        XLog.Error("[XDlcHuntMember] 非自己角色，不能判断支援芯片选择情况")
        return false
    end
    local chip = XDataCenter.DlcHuntChipManager.GetAssistantChip2Myself()
    if chip and not chip:IsEmpty() then
        return true
    end
    return false
end

function XDlcHuntMember:GetMyCharacter()
    if not self:IsMyCharacter() or self:IsEmpty() then
        return false
    end
    return XDataCenter.DlcHuntCharacterManager.GetCharacter(self:GetCharacterId())
end

return XDlcHuntMember