

---@class XHomeRoomCache 宿舍房间缓存
---@field _Limit number 缓存限制
---@field _Count number 缓存长度
---@field _Container table<number,XHomeRoomObj> 缓存长度
---@field _RoomIds number[] 顺序插入Id
local XHomeRoomCache = XClass(nil, "XHomeRoomCache")

function XHomeRoomCache:Ctor(limit)
    self._Limit = limit
    self._Count = 0
    self._Container = {}
    self._RoomIds = {}
end

function XHomeRoomCache:Count()
    return self._Count
end

--- 出队
---@return XHomeRoomObj
--------------------------
function XHomeRoomCache:Dequeue()
    if self._Count <= 0 then
        return
    end
    local first = 1
    local roomId = self._RoomIds[first]
    if not XTool.IsNumberValid(roomId) then
        return
    end
    table.remove(self._RoomIds, first)
    self._Count = self._Count - 1
    local roomObj = self._Container[roomId]
    if roomObj then
        roomObj:CleanRoom()
    end
    self._Container[roomId] = nil
    return roomObj
end

--- 入队
---@param roomObj XHomeRoomObj
--------------------------
function XHomeRoomCache:Enqueue(roomObj)
    if not roomObj then
        return
    end
    
    local roomId = roomObj.Data.Id
    if self._Container[roomId] then
        return
    end

    if self._Count >= self._Limit then
        self:Dequeue()
    end

    self._Count = self._Count + 1
    self._Container[roomId] = roomObj
    table.insert(self._RoomIds, roomId)
end

function XHomeRoomCache:Clear()
    self._Count = 0
    self._Container = {}
    self._RoomIds = {}
end

return XHomeRoomCache