---@class XPool
XPool = XClass(nil, "XPool")

function XPool:Ctor(createFunc, onRelease, isDebug)
    if not createFunc then
        XLog.Error("XPool:Ctor Error:createFunc is Empty.")
        return
    end

    self.__Container = XStack.New()
    self.__CreateFunc = createFunc
    self.__OnRelease = onRelease
    self.__TotalCount = 0
    if isDebug == nil then
        isDebug = true
    end
    self.__IsDebug = isDebug
end

function XPool:Clear()
    self.__TotalCount = 0

    self.__Container:Clear()
end

function XPool:GetItemFromPool()
    local item = self.__Container:Pop()
    if not item then
        item = self.__CreateFunc()
        if not item then
            XLog.Error("XPool:GetItemFromPool Error:createFunc return nil.")
            return
        end
        self.__TotalCount = self.__TotalCount + 1
    end
    return item
end

function XPool:ReturnItemToPool(item)
    if not item then
        return
    end

    if self:UsingCount() < 1 then
        return
    end

    if XMain.IsEditorDebug then
        -- 在入池之前检查是不是同一个对象重复入池了
        local isInPool = table.contains(self.__Container.__Container, item)
        if isInPool then
            XLog.Error("对象重复入池了")
            return
        end
    end

    if self.__OnRelease then
        self.__OnRelease(item)
    end

    -- 检测进池后再次被访问
    if XMain.IsWindowsEditor and self.__IsDebug then
        if item.__cname == "XUiNode" then
            XLog.Error("[XPool] XUiNode不能开debug功能来检测, 请传参关闭")
            self.__IsDebug = false
        else
            item = self:DebugCheckPoolReference(item)
            if not item then
                return
            end
        end
    end

    self.__Container:Push(item)
end

--池中剩余对象数量
function XPool:LeftCount()
    return self.__Container:Count()
end

--使用中对象数量
function XPool:UsingCount()
    return self.__TotalCount - self:LeftCount()
end

--已创建对象数量
function XPool:TotalCount()
    return self.__TotalCount
end

function XPool:DebugCheckPoolReference(item)
    local typeOfItem = type(item)
    if typeOfItem == "table" then
        local newItem = {}
        for i, v in pairs(item) do
            newItem[i] = v
        end
        for i, v in pairs(item) do
            item[i] = nil
        end
        local metatable = getmetatable(item)
        if type(metatable) == "table" or metatable == nil then
            if metatable then
                setmetatable(newItem, metatable)
            end
            local accessDenied = {
                __metatable = "access denied",
                __index = function(_, k)
                    XLog.Error("[XPool] 尝试访问已进对象池的table")
                end,
                __newindex = function()
                    XLog.Error("[XPool] 尝试写入已进对象池的table")
                end }
            setmetatable(item, accessDenied)
        else
            if metatable == "access denied" then
                XLog.Error("[XPool] 重复入池")
                return false
            else
                XLog.Error("[XPool] metatable受保护的object, 无法进行对象池引用检测")
                return false
            end
        end

        item = newItem
    else
        XLog.Error("[XPool] 对象池引用检测, 未处理table以外的类型:" .. typeOfItem)
    end
    return item
end