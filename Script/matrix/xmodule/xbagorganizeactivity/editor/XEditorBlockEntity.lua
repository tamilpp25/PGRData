local XEditorBOObject = require('XModule/XBagOrganizeActivity/Editor/Base/XEditorBOObject')

--- 背包编辑器格子实体类，存储一个格子中的信息
local XEditorBlockEntity = XClass(XEditorBOObject, 'XEditorBlockEntity')

function XEditorBlockEntity:Ctor()
    self._X = 0
    self._Y = 0
    self._FillTileId = 0
end

function XEditorBlockEntity:FillTile(tileId)
    self._FillTileId = tileId
end

function XEditorBlockEntity:GetFillTile()
    return self._FillTileId
end

function XEditorBlockEntity:SetPosition(x, y)
    self._X = x
    self._Y = y
end

function XEditorBlockEntity:GetPosition()
    return self._X, self._Y
end

return XEditorBlockEntity