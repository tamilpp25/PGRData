local XEditorBOObject = require('XModule/XBagOrganizeActivity/Editor/Base/XEditorBOObject')

--- 背包编辑器预制瓦片类
local XEditorTileEntity = XClass(XEditorBOObject, 'XEditorTileEntity')

function XEditorTileEntity:Ctor(id)
    self.Id = id or 0
    self._Ceils = {}
end

function XEditorTileEntity:Release()
    self._Ceils = nil
end

function XEditorTileEntity:ClearCeils()
    self._Ceils = {}
end

function XEditorTileEntity:AddCeil(x, y)
    local ceil = {}
    ceil.x = x
    ceil.y = y
    
    table.insert(self._Ceils, ceil)
end

return XEditorTileEntity