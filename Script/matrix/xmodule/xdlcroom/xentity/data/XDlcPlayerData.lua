---@class XDlcPlayerData
local XDlcPlayerData = XClass(nil, "XDlcPlayerData")
local XDlcCharacterData = require("XModule/XDlcRoom/XEntity/Data/XDlcCharacterData")

function XDlcPlayerData:Ctor(worldType, roomData, worldData)
    self._PlayerId = nil
    ---@type XDlcCharacterData[]
    self._CharacterDataList = {}
    self._Level = nil
    self._State = XEnumConst.DlcRoom.PlayerState.None
    self._Name = nil
    self._NickName = nil
    self._IsLeader = false
    self._WorldType = nil
    ---@type XDlcPlayerCustomData
    self._CustomData = nil
    self._IsClear = true
    self._Camp = nil
    self._CatSkillId = nil
    self._MouseSkillId = nil

    self:_InitCustomData(worldType)
    self:_InitWithRoomData(roomData)
    self:_InitWithWorldData(worldData)
end

function XDlcPlayerData:IsEmpty()
    return self:GetPlayerId() == nil
end

function XDlcPlayerData:SetDataWithRoomData(data, worldType)
    self:_InitCustomData(worldType)
    self:_InitWithRoomData(data)
end

function XDlcPlayerData:SetDataWithWorldData(data, worldType)
    self:_InitCustomData(worldType)
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

function XDlcPlayerData:GetCamp()
    return self._Camp
end

function XDlcPlayerData:GetCatSkillId()
    return self._CatSkillId
end

function XDlcPlayerData:GetMouseSkillId()
    return self._MouseSkillId
end

---@return XDlcPlayerCustomData
function XDlcPlayerData:GetCustomData()
    return self._CustomData
end

function XDlcPlayerData:GetCharacterId(pos)
    local character = self._CharacterDataList[pos or 1]

    if character then
        return character:GetCharacterId()
    end

    return nil
end

function XDlcPlayerData:GetCharacterAmount()
    return self._CharacterDataList and #self._CharacterDataList or 0
end

function XDlcPlayerData:GetName()
    return self._Name or "???"
end

function XDlcPlayerData:GetNickname()
    return self._NickName or "???"
end

function XDlcPlayerData:SetCustomData(data)
    if self:HasCustomData() then
        self._CustomData:SetCustomData(data)
    end
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
    self._Camp = other._Camp
    self._CatSkillId = other._CatSkillId
    self._MouseSkillId = other._MouseSkillId

    if other:HasCustomData() then
        if not self:HasCustomData() then
            self:_InitCustomData(other._WorldType)
        end

        self._WorldType = other._WorldType
        self._CustomData:Clone(other._CustomData)
    end
    for i = 1, #other._CharacterDataList do
        local characterData = XDlcCharacterData.New()

        characterData:Clone(other._CharacterDataList[i])
        self._CharacterDataList[i] = characterData
    end
end

function XDlcPlayerData:HasCustomData()
    return self._CustomData ~= nil
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
    self._Camp = nil
    self._CatSkillId = nil
    self._MouseSkillId = nil
    if self:HasCustomData() then
        self._CustomData:Clear()
    end
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
        if self:HasCustomData() then
            self._CustomData:SetDataWithRoomData(data)
        end
    end
end

function XDlcPlayerData:_InitWithWorldData(data)
    if data then
        local npcList = data.NpcList
        local multiplayerData = data.MultiplayerData
        self._PlayerId = data.Id
        self._Name = data.Name
        self._NickName = XDataCenter.SocialManager.GetPlayerRemark(self:GetPlayerId(), self:GetName())
        self._IsLeader = data.IsLeader
        self._IsClear = false

        if not XTool.IsTableEmpty(multiplayerData) then
            self._Camp = multiplayerData.Camp
            self._CatSkillId = multiplayerData.CatSkillId
            self._MouseSkillId = multiplayerData.MouseSkillId
        end

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
        if self:HasCustomData() then
            self._CustomData:SetDataWithWorldData(data)
        end
    end
end

function XDlcPlayerData:_InitCustomData(worldType)
    if worldType and self._WorldType ~= worldType then
        local agency = XMVCA.XDlcWorld:GetAgencyByWorldType(worldType)

        self._WorldType = worldType
        if agency then
            self._CustomData = agency:DlcGetPlayerCustomData()
        end
    else
        self._CustomData = nil
    end
end

return XDlcPlayerData
