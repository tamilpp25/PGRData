---@class XDlcFightBeginData
local XDlcFightBeginData = XClass(nil, "XDlcFightBeginData")
local XDlcRoomData = require("XModule/XDlcRoom/XEntity/Data/XDlcRoomData")
local XDlcWorldData = require("XModule/XDlcRoom/XEntity/Data/XDlcWorldData")

function XDlcFightBeginData:Ctor()
    ---@type XDlcWorldData
    self._WorldData = nil
    ---@type XDlcRoomData
    self._RoomData = nil
end

---@param roomData XDlcRoomData
function XDlcFightBeginData:SetRoomData(roomData)
    if self:IsRoomEmpty() then
        self._RoomData = XDlcRoomData.New()
    end

    self._RoomData:Clone(roomData)
end

---@param worldData XDlcWorldData
function XDlcFightBeginData:SetWorldData(worldData)
    if self:IsWorldEmpty() then
        self._WorldData = XDlcWorldData.New()
    end

    self._WorldData:Clone(worldData)
end

function XDlcFightBeginData:SetWorldDataBySource(worldData)
    if not self:IsWorldEmpty() then
        self._WorldData:SetData(worldData)
    else
        self._WorldData = XDlcWorldData.New(worldData)
    end

    if not self:IsRoomEmpty() then
        self._RoomData:SyncFromWorldData(self._WorldData)
    end
end

function XDlcFightBeginData:SetRoomDataBySource(roomData)
    if not self:IsRoomEmpty() then
        self._RoomData:SetData(roomData)
    else
        self._RoomData = XDlcRoomData.New(roomData)
    end

    if not self:IsRoomEmpty() then
        self._RoomData:SyncFromWorldData(self._WorldData)
    end
end

---@return XDlcRoomData
function XDlcFightBeginData:GetRoomData()
    return self._RoomData
end

---@return XDlcWorldData
function XDlcFightBeginData:GetWorldData()
    return self._WorldData
end

function XDlcFightBeginData:IsRoomEmpty()
    return self._RoomData == nil
end

function XDlcFightBeginData:IsWorldEmpty()
    return self._WorldData == nil
end 

function XDlcFightBeginData:IsRoomClear()
    return self._RoomData:IsClear()
end

function XDlcFightBeginData:IsWorldClear()
    return self._WorldData:IsClear()
end 

---@param other XDlcFightBeginData
function XDlcFightBeginData:Clone(other)
    self:SetRoomData(other._RoomData)
    self:SetWorldData(other._WorldData)
end

function XDlcFightBeginData:ClearRoomData()
    if not self:IsRoomEmpty() then
        self._RoomData:Clear()
    end
end

function XDlcFightBeginData:ClearWorldData()
    if not self:IsWorldEmpty() then
        self._WorldData:Clear()
    end
end

function XDlcFightBeginData:Clear()
    self:ClearRoomData()
    self:ClearWorldData()
end

function XDlcFightBeginData:IsExist()
    return not (self:IsRoomEmpty() or self:IsWorldEmpty() or self:IsRoomClear() or self:IsWorldClear())
end

return XDlcFightBeginData
