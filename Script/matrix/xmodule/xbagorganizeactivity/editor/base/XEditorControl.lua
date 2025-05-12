---- 背包编辑器中Control的基类
---@class XEditorControl:XControl
local XEditorControl = XClass(XControl, 'XEditorControl')

function XEditorControl:OnInit()
    if not XMain.IsWindowsEditor then
        XLog.Error('在非编辑器环境下实例化编辑器Control:'..tostring(self.__cname))
    end
end

function XEditorControl:ReloadTiles()
    
end

function XEditorControl:ReloadMap()
    
end

function XEditorControl:ReloadFiles()
    
end

function XEditorControl:ClearMap()
    if self._BagMap then
        self._BagMap:ClearMap()
    end
end

return XEditorControl