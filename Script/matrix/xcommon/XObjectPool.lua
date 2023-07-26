---@class XObjectPool 对象池类
---@field _Container XStack
---@field _Total number
---@field _NewFunc function
XObjectPool = XClass(nil, "XObjectPool")

function XObjectPool:Ctor(newFunc)
    if not newFunc then
        XLog.Error("[XObjectPool]:对象池创建失败，对象创建函数为空!")
    end
    self._Container = XStack.New()
    self._Total = 0
    self._NewFunc = newFunc
end 

function XObjectPool:Create(...)
    local freeCount = self:FreeCount()
    local obj
    if freeCount > 0 then
        obj = self._Container:Pop()
    else
        obj = self._NewFunc and self._NewFunc(...) or nil
        self._Total = self._Total + 1
    end

    if not obj then
        XLog.Error("[XObjectPool]:创建对象失败!")
    end

    if obj and obj.Init and type(obj.Init) == "function" then
        obj:Init(...)
    end
    
    return obj
end 

function XObjectPool:Recycle(obj)
    if not obj then
        XLog.Warning("[XObjectPool]:空对象不能回收!")
        return
    end
    self._Container:Push(obj)
end 

--- 已经创建对象数量
---@return number
--------------------------
function XObjectPool:TotalCount()
    return self._Total
end 

--- 使用中对象数量
---@return number
--------------------------
function XObjectPool:UsingCount()
    return self:TotalCount() - self:FreeCount()
end

--- 池中对象个数
---@return number
--------------------------
function XObjectPool:FreeCount()
    return self._Container:Count()
end

function XObjectPool:Clear()
    self._Total = 0
    self._Container:Clear()
end 