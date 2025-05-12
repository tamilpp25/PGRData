local XEditorBOObject = require('XModule/XBagOrganizeActivity/Editor/Base/XEditorBOObject')

--- 背包编辑器文件配置类，对应背包绘制配置
local XEditorFileEntity = XClass(XEditorBOObject, 'XEditorFileEntity')

function XEditorFileEntity:Ctor(id, address, tableReadPath)
    self.Id = id
    self.Address = address
    self.TableReadPath = tableReadPath
    self.Data = nil
    self.isDataChanged = false
    self.IsEmpty = false
    
    self.MaxWidth = 0
    self.MaxHeight = 0
end

function XEditorFileEntity:Release()
    self.Data = nil
end

function XEditorFileEntity:IsDataChanged()
    return self.isDataChanged or self.IsEmpty
end

function XEditorFileEntity:MarkDataState(isChanged)
    self.isDataChanged = isChanged and true or false
end

function XEditorFileEntity:ReloadData()
    if CS.System.IO.File.Exists(self.Address) then
        self.Data = XTableManager.ReadAllByIntKey(self.TableReadPath, XTable.XTableBagOrganizeMap, 'Id')
        self.IsEmpty = false
    else
        self.isDataChanged = true
        self.IsEmpty = true
    end
end

function XEditorFileEntity:SaveData(newData, columns)
    if self.isDataChanged then
        columns = XTool.IsNumberValid(columns) and columns or 1
        self:_SaveData(newData, columns)
        self.isDataChanged = false
        return true
    end
    return false
end

function XEditorFileEntity:_SaveData(newData, columns)
    local content = {}
    -- 设置表头
    local title = {'Id'}
    for i = 1, columns do
        table.insert(title, '\tBlocks['..tostring(i)..']')
    end
    table.insert(title, '\r\n')
    table.insert(content, table.concat(title))

    self.MaxWidth = 0
    self.MaxHeight = 0
    
    -- 设置内容
    if not XTool.IsTableEmpty(newData) then
        local index = 1
        -- 遍历每一行
        for i1, cfg in ipairs(newData) do
            local line = {index}
            index = index +1
            
            local width = 0
            -- 遍历每一列
            for i2, tileId in ipairs(cfg) do
                if XTool.IsNumberValid(tileId) then
                    width = width + 1
                end
                table.insert(line, '\t'..tostring(tileId))
            end
            table.insert(line, '\r\n')

            if width > self.MaxWidth then
                self.MaxWidth = width
            end

            if width > 0 then
                self.MaxHeight = self.MaxHeight + 1
            end

            table.insert(content, table.concat(line))
        end
    end
    
    -- 写入文件
    CS.System.IO.File.WriteAllText(self.Address, table.concat(content))
    self:ReloadData()
end

return XEditorFileEntity