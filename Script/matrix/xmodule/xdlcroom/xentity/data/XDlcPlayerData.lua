---@class XDlcPlayerData
local XDlcPlayerData = XClass(nil, "XDlcPlayerData")
local XDlcCharacterData = require("XModule/XDlcRoom/XEntity/Data/XDlcCharacterData")

function XDlcPlayerData:Ctor(roomData, worldData)
    self._PlayerId = nil
    ---@type XDlcCharacterData[]
    self._CharacterDataList = {}
    self._Level = nil
    self._State = XEnumConst.DlcRoom.PlayerState.None
    self._Name = nil
    self._NickName = nil
    self._IsLeader = false
    self._IsClear = true
    self:SetDataWithRoomData(roomData)
    self:SetDataWithWorldData(worldData)
end

function XDlcPlayerData:IsEmpty()
    return self:GetPlayerId() == nil
end

function XDlcPlayerData:SetDataWithRoomData(data)
    self:_InitWithRoomData(data)
end

function XDlcPlayerData:SetDataWithWorldData(data)
    self:_InitWithWorldData(data)
end

function XDlcPlayerData:GetLevel()
    return self._Level
end

function XDlcPlayerData:GetState()
    return self._State
end

function XDlcPlayerData:IsLeader()
    return self._IsLeader
end

function XDlcPlayerData:GetPlayerId()
    return self._PlayerId
end

function XDlcPlayerData:GetCharacterId(pos)
    local character = self._CharacterDataList[pos or 1]

    if character then
        return character:GetCharacterId()
    end

    return nil
end

function XDlcPlayerData:GetName()
    return self._Name or "???"
end

function XDlcPlayerData:GetNickname()
    return self._NickName or "???"
end

function XDlcPlayerData:SetIsLeader(value)
    self._IsLeader = value
end

function XDlcPlayerData:SetState(value)
    self._State = value
end

function XDlcPlayerData:SetCharacterListBySource(characterList)
    if not XTool.IsTableEmpty(characterList) then
        self._CharacterDataList = {}

        for i = 1, #characterList do
            self._CharacterDataList[i] = XDlcCharacterData.New(characterList[i])
        end
    end
end 

---@param other XDlcPlayerData
function XDlcPlayerData:Clone(other)
    self:Clear()

    self._IsClear = false
    self._PlayerId = other._PlayerId
    self._Level = other._Level
    self._State = other._State
    self._Name = other._Name
    self._NickName = other._NickName
    self._IsLeader = other._IsLeader

    for i = 1, #other._CharacterDataList do
        local characterData = XDlcCharacterData.New()

        characterData:Clone(other._CharacterDataList[i])
        self._CharacterDataList[i] = characterData
    end
end

function XDlcPlayerData:IsClear()
    return self._IsClear
end

function XDlcPlayerData:Clear()
    if self:IsClear() then
        return
    end

    self._IsClear = true
    self._PlayerId = nil
    self._CharacterDataList = {}
    self._Level = nil
    self._State = XEnumConst.DlcRoom.PlayerState.None
    self._Name = nil
    self._NickName = nil
    self._IsLeader = false
end

function XDlcPlayerData:_InitWithRoomData(data)
    if data then
        local characterData = self._CharacterDataList[1]

        self._PlayerId = data.Id
        self._Name = data.Name
        self._NickName = XDataCenter.SocialManager.GetPlayerRemark(self:GetPlayerId(), self:GetName())
        self._State = data.State
        self._IsLeader = data.Leader
        self._Level = data.Level
        self._IsClear = false

        if not characterData then
            self._CharacterDataList[1] = XDlcCharacterData.New(data.WorldNpcData)
        else
            characterData:SetData(data.WorldNpcData)
        end
    end
end

function XDlcPlayerData:_InitWithWorldData(data)
    if data then
        local npcList = data.NpcList

        self._PlayerId = data.Id
        self._Name = data.Name
        self._NickName = XDataCenter.SocialManager.GetPlayerRemark(self:GetPlayerId(), self:GetName())
        self._IsLeader = data.IsLeader
        self._IsClear = false

        if not XTool.IsTableEmpty(npcList) then
            for i = 1, #npcList do
                local characterData = self._CharacterDataList[i]

                if not characterData then
                    self._CharacterDataList[i] = XDlcCharacterData.New(npcList[i])
                else
                    characterData:SetData(npcList[i])
                end
            end
        end
    end
end

return XDlcPlayerData
