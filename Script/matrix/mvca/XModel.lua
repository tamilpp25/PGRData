---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:27
---
local IsWindowsEditor = XMain.IsWindowsEditor
---@class XModel
---@field _ConfigUtil XConfigUtil
XModel = XClass(nil, "XModel")

function XModel:Ctor(id)
    self._Id = id
    self._ConfigUtil = XConfigUtil.New(id)
    self:OnInit()
end

---初始化函数,提供给子类重写
function XModel:OnInit()

end

---清理内部数据, 在Control生命周期结束的时候会触发
function XModel:ClearPrivate()
    XLog.Error("请子类重写Model.ClearPrivate方法")
end

function XModel:ClearPrivateConfig()
    if self._ConfigUtil then
        self._ConfigUtil:ClearPrivate()
    end
end

---重登清理, 回到登录界面的时候需重置数据
function XModel:ResetAll()

end

function XModel:Release()
    if self._ConfigUtil then
        self._ConfigUtil:Release()
        self._ConfigUtil = nil
    end
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Model, self)
    end
end
