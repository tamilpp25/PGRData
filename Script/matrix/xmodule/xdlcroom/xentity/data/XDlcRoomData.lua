---@class XDlcRoomData
local XDlcRoomData = XClass(nil, "XDlcRoomData")
local XDlcPlayerData = require("XModule/XDlcRoom/XEntity/Data/XDlcPlayerData")

function XDlcRoomData:Ctor(data)
    self._Id = nil
    self._WorldId = nil
    self._LevelId = nil
    self._IsTutorial = false
    self._IsReconnect = false
    self._IsOnline = false
    self._IsAutoMatch = false
    self._State = XEnumConst.DlcRoom.RoomState.None
    self._AbilityLimit = nil
    ---@type XDlcPlayerData[]
    self._PlayerDataList = {}
    ---@type table<number, XDlcPlayerData>
    self._PlayerDataDic = {}
    self._IsClear = true
    self:SetData(data)
end

function XDlcRoomData:SetData(data)
    self:_Init(data)
end

function XDlcRoomData:SetLevelId(levelId)
    self._LevelId = levelId
end

function XDlcRoomData:SetIsTutorial(isTutorial)
    self._IsTutorial = isTutorial
end

function XDlcRoomData:SetIsReconnect(isReconnect)
    self._IsReconnect = isReconnect
end

function XDlcRoomData:SetIsOnline(isOnline)
    self._IsOnline = isOnline
end

function XDlcRoomData:GetId()
    return self._Id
end

function XDlcRoomData:GetWorldId()
    return self._WorldId
end

function XDlcRoomData:IsOnline()
    return self._IsOnline
end

function XDlcRoomData:IsAutoMatch()
    return self._IsAutoMatch
end

function XDlcRoomData:IsTutorial()
    return self._IsTutorial
end

function XDlcRoomData:IsReconnect()
    return self._IsReconnect
end

function XDlcRoomData:GetLevelId()
    return self._LevelId
end

function XDlcRoomData:GetState()
    return self._State
end

function XDlcRoomData:GetAbilityLimit()
    return self._AbilityLimit
end

---@type XDlcPlayerData
function XDlcRoomData:GetPlayerDataByPos(pos)
    return self._PlayerDataList[pos or 1]
end

---@type XDlcPlayerData
function XDlcRoomData:GetPlayerDataById(playerId)
    return self._PlayerDataDic[playerId]
end

---@type XDlcPlayerData[]
function XDlcRoomData:GetPlayerDataList()
    return self._PlayerDataList
end

function XDlcRoomData:GetPlayerAmount()
    return #self._PlayerDataList
end

function XDlcRoomData:SetAutoMatch(value)
    self._IsAutoMatch = value
end

function XDlcRoomData:SetState(value)
    self._State = value
end

function XDlcRoomData:SetAbilityLimit(value)
    self._AbilityLimit = value
end

function XDlcRoomData:SetWorldId(value)
    self._WorldId = value
end

---@param playerData XDlcPlayerData
function XDlcRoomData:AddPlayerData(playerData)
    if playerData and not playerData:IsEmpty() then
        self._PlayerDataList[#self._PlayerDataList + 1] = playerData
        self._PlayerDataDic[playerData:GetPlayerId()] = playerData
    end
end

function XDlcRoomData:AddPlayerDataBySource(playerData)
    if playerData then
        local player = XDlcPlayerData.New(playerData)

        self:AddPlayerData(player)
    end
end

function XDlcRoomData:RemovePlayerDataById(playerId)
    if playerId then
        for i = 1, #self._PlayerDataList do
            local player = self._PlayerDataList[i]

            if player:GetPlayerId() == playerId then
                self._PlayerDataDic[playerId] = nil
                XTool.TableRemove(self._PlayerDataList, player)

                return true
            end
        end
    end

    return false
end

---@param other XDlcRoomData
function XDlcRoomData:Clone(other)
    self:Clear()

    self._IsClear = false
    self._Id = other._Id
    self._WorldId = other._WorldId
    self._IsOnline = other._IsOnline
    self._IsAutoMatch = other._IsAutoMatch
    self._State = other._State
    self._AbilityLimit = other._AbilityLimit

    for i = 1, #other._PlayerDataList do
        local playerData = XDlcPlayerData.New()

        playerData:Clone(other._PlayerDataList[i])
        self._PlayerDataList[i] = playerData
        self._PlayerDataDic[playerData:GetPlayerId()] = playerData
    end
end

function XDlcRoomData:Clear()
    if self:IsClear() then
        return
    end

    self._IsClear = true
    self._Id = nil
    self._WorldId = nil
    self._IsOnline = false
    self._IsAutoMatch = false
    self._State = XEnumConst.DlcRoom.RoomState.None
    self._AbilityLimit = nil
    self._PlayerDataList = {}
    self._PlayerDataDic = {}
end

function XDlcRoomData:IsClear()
    return self._IsClear
end

---@param worldData XDlcWorldData
function XDlcRoomData:SyncFromWorldData(worldData)
    if not self:IsClear() and not worldData:IsClear() then
        self:SetWorldId(worldData:GetId())
        self:SetLevelId(worldData:GetLevelId())
        self:SetIsTutorial(worldData:IsTutorial())
        self:SetIsOnline(worldData:IsOnline())
        self._Id = worldData:GetRoomId()
    end
end

function XDlcRoomData:_Init(data)
    if data then
        local playerDataList = data.PlayerDataList

        self._IsClear = false
        self._Id = data.Id
        self._WorldId = data.WorldId
        self._IsOnline = data.IsOnline
        self._IsAutoMatch = data.AutoMatch
        self._State = data.State
        self._AbilityLimit = data.AbilityLimit

        if not XTool.IsTableEmpty(playerDataList) then
            for i = 1, #playerDataList do
                local playerData = self._PlayerDataList[i]

                if not playerData then
                    playerData = XDlcPlayerData.New(playerDataList[i])
                else
                    if not playerData:IsEmpty() then
                        self._PlayerDataDic[playerData:GetPlayerId()] = nil
                    end

                    playerData:SetDataWithRoomData(playerDataList[i])
                end

                self._PlayerDataList[i] = playerData
                self._PlayerDataDic[playerData:GetPlayerId()] = playerData
            end
        end
    end
end

return XDlcRoomData
