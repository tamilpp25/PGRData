---@class XDlcPlayerCustomData
local XDlcPlayerCustomData = XClass(nil, "XDlcPlayerCustomData")

function XDlcPlayerCustomData:Ctor()
    self._IsClear = true 
end

function XDlcPlayerCustomData:SetDataWithRoomData(roomData)
    if roomData then
        self._IsClear = false
        self:_InitWithRoomData(roomData) 
    end
end

function XDlcPlayerCustomData:SetDataWithWorldData(worldData)
    if worldData then
        self._IsClear = false
        self:_InitWithWorldData(worldData)
    end
end

function XDlcPlayerCustomData:Clear()
    if not self._IsClear then
        self._IsClear = true
        self:_ClearData()
    end
end

function XDlcPlayerCustomData:IsClear()
    return self._IsClear
end

---@param other XDlcPlayerCustomData
function XDlcPlayerCustomData:Clone(other)
    if other and not other:IsClear() then
        self._IsClear = false
        self:_Clone(other)
    end
end

function XDlcPlayerCustomData:SetCustomData(data)
    if not XTool.IsTableEmpty(data) then
        self._IsClear = false
        for key, value in pairs(data) do
            self[key] = value
        end
    end
end

--- virtual 供子类重写
---@param other XDlcPlayerCustomData
function XDlcPlayerCustomData:_Clone(other)
    
end

--- virtual 供子类重写
function XDlcPlayerCustomData:_ClearData()
    
end

--- virtual 供子类重写
function XDlcPlayerCustomData:_InitWithRoomData(roomData)
    
end

--- virtual 供子类重写
function XDlcPlayerCustomData:_InitWithWorldData(worldData)
    
end

return XDlcPlayerCustomData
