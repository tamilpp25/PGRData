XPool = XClass(nil, "XPool")

function XPool:Ctor(createFunc, onRelease)
    if not createFunc then
        XLog.Error("XPool:Ctor Error:createFunc is Empty.")
        return
    end

    self.__Container = XStack.New()
    self.__CreateFunc = createFunc
    self.__OnRelease = onRelease
    self.__TotalCount = 0
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
    if not item then return end

    if self:UsingCount() < 1 then
        return
    end

    if self.__OnRelease then
        self.__OnRelease(item)
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