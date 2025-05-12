local XEditorBOObject = require('XModule/XBagOrganizeActivity/Editor/Base/XEditorBOObject')

--- 背包编辑器网格地图类，存储网格信息
---@class XEditorBagmap
local XEditorBagmap = XClass(XEditorBOObject, 'XEditorBagmap')

local XEditorBlockEntity = require('XModule/XBagOrganizeActivity/Editor/XEditorBlockEntity')

local GetNewBlockEntityFunc = function()
    return XEditorBlockEntity.New()
end

local ReleaseBlockEntityFunc = function(block) 
    block:FillTile(0)
    block:SetPosition(0, 0)
end

function XEditorBagmap:Ctor()
    self._Map = {}
    self._Width = 0
    self._Height = 0
    
    self._FreeBlockPool = XPool.New(GetNewBlockEntityFunc, ReleaseBlockEntityFunc, false)
end

function XEditorBagmap:Release()
    self._Map = nil
    self._FreeBlockPool:Clear()
    self._FreeBlockPool = nil
end

function XEditorBagmap:SetMapSize(width, height)
    
    local sizeChanged = width ~= self._Width or height ~= self._Height
    
    self._Width = math.floor(width)
    self._Height = math.floor(height)

    if sizeChanged then
        -- 先回收所有
        for i = #self._Map, 1, -1 do
            self._FreeBlockPool:ReturnItemToPool(self._Map[i])
            self._Map[i] = nil
        end
        -- 再重新生成
        for i = 1, self._Width do
            for j = 0, self._Height - 1 do
                local entity = self._FreeBlockPool:GetItemFromPool()
                entity:SetPosition(i, j)
                self._Map[i + j * self._Width] = entity
            end
        end
    end
end

function XEditorBagmap:ClearMap()
    if self._Width > 0 and self._Height > 0 then
        for i = 1, self._Width do
            for j = 0, self._Height - 1 do
                self._Map[i + j * self._Width]:FillTile(0)
            end
        end
    end
end

function XEditorBagmap:FillTileByPos(tileId, x, y)
    local index = x + y * self._Width
    if self._Map[index] then
        self._Map[index]:FillTile(tileId)
    end
end

function XEditorBagmap:FillTileByIndex(tileId, index)
    if self._Map[index] then
        self._Map[index]:FillTile(tileId)
    end
end

function XEditorBagmap:GetTileIdByIndex(index)
    if self._Map[index] then
        return self._Map[index]:GetFillTile()
    end
    return 0
end

--- 获取二维表形式的网格数据
function XEditorBagmap:GetDataArray()
    -- 网格数据同步到文件
    -- 一行行扫描
    local data = {}
    for j = 0, self._Height - 1 do
        local line = {}
        for i = 1, self._Width do
            local index = i + j * self._Width
            table.insert(line, self:GetTileIdByIndex(index))
        end
        table.insert(data, line)
    end
    
    return data, self._Width, self._Height
end

return XEditorBagmap