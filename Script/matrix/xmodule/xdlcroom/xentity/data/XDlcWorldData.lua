---@class XDlcWorldData
local XDlcWorldData = XClass(nil, "XDlcWorldData")
local XDlcPlayerData = require("XModule/XDlcRoom/XEntity/Data/XDlcPlayerData")

function XDlcWorldData:Ctor(worldData)
    self._IsOnline = false
    self._IsTutorial = false
    self._IsClear = true
    self._RoomId = nil
    self._Id = nil
    self._LevelId = nil
    ---@type XDlcPlayerData[]
    self._PlayerDataList = {}
    ---@type table<number, XDlcPlayerData>
    self._PlayerDataDic = {}
    self:SetData(worldData)
end

function XDlcWorldData:SetData(data)
    self:_Init(data)
end

function XDlcWorldData:IsOnline()
    return self._IsOnline
end

function XDlcWorldData:IsTutorial()
    return self._IsTutorial
end

function XDlcWorldData:GetRoomId()
    return self._RoomId
end

function XDlcWorldData:GetId()
    return self._Id
end 

function XDlcWorldData:GetLevelId()
    return self._LevelId
end

---@type XDlcPlayerData
function XDlcWorldData:GetPlayerDataByPos(pos)
    return self._PlayerDataList[pos or 1]
end

---@type XDlcPlayerData
function XDlcWorldData:GetPlayerDataById(playerId)
    return self._PlayerDataDic[playerId]
end

---@type XDlcPlayerData[]
function XDlcWorldData:GetPlayerDataList()
    return self._PlayerDataList
end

function XDlcWorldData:GetPlayerAmount()
    return #self._PlayerDataList
end

---@param other XDlcWorldData
function XDlcWorldData:Clone(other)
    self:Clear()

    self._IsClear = false
    self._IsOnline = other._IsOnline
    self._IsTutorial = other._IsTutorial
    self._RoomId = other._RoomId
    self._Id = other._Id
    self._LevelId = other._LevelId

    for i = 1, #other._PlayerDataList do
        local playerData = XDlcPlayerData.New()

        playerData:Clone(other._PlayerDataList[i])
        self._PlayerDataList[i] = playerData
        self._PlayerDataDic[playerData:GetPlayerId()] = playerData
    end
end

function XDlcWorldData:Clear()
    if self:IsClear() then
        return
    end

    self._IsClear = true
    self._IsOnline = false
    self._IsTutorial = false
    self._RoomId = nil
    self._Id = nil
    self._LevelId = nil
    self._PlayerDataList = {}
    self._PlayerDataDic = {}
end

function XDlcWorldData:IsClear()
    return self._IsClear
end

function XDlcWorldData:_Init(data)
    if data then
        local playerDataList = data.Players

        self._Id = data.WorldId
        self._RoomId = data.RoomId
        self._IsOnline = data.Online
        self._IsTutorial = data.IsTeaching
        self._LevelId = data.LevelId
        self._IsClear = false

        self._PlayerDataDic = {}
        if not XTool.IsTableEmpty(playerDataList) then
            for i = 1, #playerDataList do
                local playerData = self._PlayerDataList[i]
                local worldType = XMVCA.XDlcWorld:GetWorldTypeById(self:GetId())

                if not playerData then
                    playerData = XDlcPlayerData.New(worldType, nil, playerDataList[i])
                else
                    playerData:SetDataWithWorldData(playerDataList[i], worldType)
                end

                self._PlayerDataList[i] = playerData
                self._PlayerDataDic[playerData:GetPlayerId()] = playerData
            end
            for i = #playerDataList + 1, #self._PlayerDataList do
                self._PlayerDataList[i] = nil
            end
        else
            self._PlayerDataList = {}
        end
    end
end

return XDlcWorldData
