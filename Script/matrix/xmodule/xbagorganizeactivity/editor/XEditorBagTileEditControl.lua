local XEditorControl = require("XModule/XBagOrganizeActivity/Editor/Base/XEditorControl")
---@class XEditorBagTileEditControl: XEditorControl
---@field private _Model XBagOrganizeActivityModel
local XEditorBagTileEditControl = XClass(XEditorControl, 'XEditorBagTileEditControl')

local XEditorTileEntity = require('XModule/XBagOrganizeActivity/Editor/XEditorTileEntity')
local XEditorBagmap = require('XModule/XBagOrganizeActivity/Editor/XEditorBagmap')
local XEditorFileEntity = require('XModule/XBagOrganizeActivity/Editor/XEditorFileEntity')

local BagBlockId = 1

function XEditorBagTileEditControl:OnRelease()
    if self._Map then
        self._Map:Release()
        self._Map = nil
    end

    if self._Files then
        for i, v in pairs(self._Files) do
            v:Release()
        end
        self._Files = nil
    end

    if self._Tiles then
        for i, v in pairs(self._Tiles) do
            v:Release()
        end
        self._Tiles = nil
    end
end

---@overload
function XEditorBagTileEditControl:ReloadMap()
    if not self._Map then
        self._Map = XEditorBagmap.New()
    end
    local sizeVec2 = self._Model:GetClientConfigVector2('BagSize')
    self._Map:SetMapSize(sizeVec2.x, sizeVec2.y)
end

---@overload
function XEditorBagTileEditControl:ReloadTiles()
    self._Tiles = {}
    -- 背包编辑器只有一个预制瓦片，代表背包格子,格子单元在正中间
    local tile = XEditorTileEntity.New(BagBlockId)
    tile:AddCeil(0, 0)
    
    table.insert(self._Tiles, tile)
end

---@overload
function XEditorBagTileEditControl:ReloadFiles()
    local cfgs = self._Model:GetBagOrganizeBagsCfgs()

    if not XTool.IsTableEmpty(cfgs) then
        self._Files = {}
        
        local halfPath = 'Client/MiniActivity/BagOrganize/Maps/BagOrganizeMap'
        
        for i, cfg in pairs(cfgs) do
            local path = halfPath..tostring(cfg.Id)..'.tab'

            local fileEntity = XEditorFileEntity.New(cfg.Id, CS.ConfigConst.XTablePath..path, path)
            table.insert(self._Files, fileEntity)
        end
    end
    
    -- 按照Id排序
    table.sort(self._Files, function(a, b) 
        return a.Id < b.Id
    end)
end

function XEditorBagTileEditControl:GetTiles()
    return self._Tiles
end

function XEditorBagTileEditControl:GetMap()
    return self._Map
end

function XEditorBagTileEditControl:GetFiles()
    return self._Files
end

function XEditorBagTileEditControl:GetMapWidth()
    return self._Model:GetClientConfigNum('BagSize', 1)
end

function XEditorBagTileEditControl:GetMapHeight()
    return self._Model:GetClientConfigNum('BagSize', 2)
end

function XEditorBagTileEditControl:SetCurrentTileId(id)
    self._CurrentTileId = id
end

function XEditorBagTileEditControl:GetCurrentTileId()
    return self._CurrentTileId or 0
end

function XEditorBagTileEditControl:SetCurrentFileId(id)
    self._CurrentFileId = id
end

function XEditorBagTileEditControl:GetCurrentFileId()
    return self._CurrentFileId or 0
end

function XEditorBagTileEditControl:CheckFileIsChanged(fileId)
    if XTool.IsNumberValid(fileId) and not XTool.IsTableEmpty(self._Files) then
        local file = self._Files[fileId]
        if file then
            return file:IsDataChanged()
        end
    end
end

function XEditorBagTileEditControl:MarkDataState(isChanged)
    if XTool.IsNumberValid(self._CurrentFileId) and not XTool.IsTableEmpty(self._Files) then
        local file = self._Files[self._CurrentFileId]
        if file then
            file:MarkDataState(isChanged)
        end
    end
end

function XEditorBagTileEditControl:GetTileColor(tileId)
    -- 一般是取tile的图片，这里简单点就颜色了
    if tileId == 0 then
        return CS.UnityEngine.Color(1,1,1,1)
    elseif tileId == 1 then
        return CS.UnityEngine.Color(0.8,0.8,1,1)
    end
end

function XEditorBagTileEditControl:ClearMap()
    if self._Map then
        self._Map:ClearMap()
    end
end

function XEditorBagTileEditControl:SaveMap()
    if XTool.IsNumberValid(self._CurrentFileId) and not XTool.IsTableEmpty(self._Files) then
        local file = self._Files[self._CurrentFileId]
        if file then
            -- 网格数据同步到文件
            local data, columns, rows = self._Map:GetDataArray()
            -- 保存数据
            if file:SaveData(data, columns) then
                self:_SaveBag(file.Id, file.MaxWidth, file.MaxHeight)
                XUiManager.TipMsg('保存成功')
            end
        end
    end
end

--- 目前是改动一个就遍历和保存整张表，因为数量不多且是编辑器，所以暂时先这样
function XEditorBagTileEditControl:_SaveBag(bagId, maxWidth, maxHeight)
    local cfgs = self._Model:GetBagOrganizeBagsCfgs()

    if not XTool.IsTableEmpty(cfgs) then
        local content = {}

        -- 设置表头
        local title = 'Id\tCost\tMaxWidth\tMaxHeight\tIconAddress\r\n'
        table.insert(content, title)
        
        ---@param v XTableBagOrganizeBags
        for i, v in pairs(cfgs) do
            local realMaxWidth = v.MaxWidth
            local realMaxHeight = v.MaxHeight

            if v.Id == bagId then
                realMaxWidth = maxWidth
                realMaxHeight = maxHeight
            end
            
            local line = { tostring(v.Id), '\t', tostring(v.Cost), '\t', tostring(realMaxWidth), '\t', tostring(realMaxHeight), '\t', v.IconAddress or '',' \r\n'}
            table.insert(content, table.concat(line))
        end
        
        CS.System.IO.File.WriteAllText(CS.ConfigConst.XTablePath..'Client/MiniActivity/BagOrganize/BagOrganizeBags.tab', table.concat(content))
        self._Model:ClearBagOrganizeBagsCfgs()
    end
end

function XEditorBagTileEditControl:ReloadFileById(fileId)
    if XTool.IsNumberValid(fileId) and not XTool.IsTableEmpty(self._Files) then
        local file = self._Files[fileId]
        if file then
            file:ReloadData()

            if self._Map then
                -- 加载完成后需同步进网格
                if not file.IsEmpty then
                    for i1, cfg in ipairs(file.Data) do
                        for i2, tileId in ipairs(cfg.Blocks) do
                            self._Map:FillTileByPos(tileId, i2, i1 - 1)
                        end
                    end
                else
                    self._Map:ClearMap()
                end
            end
        end
    end
end

return XEditorBagTileEditControl