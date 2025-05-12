--- 背包编辑器中所有实体类的基类
local XEditorBOObject = XClass(nil, 'XEditorBOEntity')

function XEditorBOObject:Ctor()
    if not XMain.IsWindowsEditor then
        XLog.Error('在非编辑器环境下实例化编辑器实体:'..tostring(self.__cname))
    end
end

function XEditorBOObject:Release()
    
end

return XEditorBOObject
