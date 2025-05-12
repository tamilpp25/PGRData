---@class XQueue 队列
XQueue = XClass(nil, "XQueue")

function XQueue:Ctor(initialCapacity)
    self.InitialCapacity = initialCapacity
    self:Clear()
end

function XQueue:Clear()
    self.__Container = {}
    self.__StartIndex = 1
    self.__EndIndex = 0
    if self.InitialCapacity then
        for i = 1, self.InitialCapacity do
            table.insert(self.__Container, false)  -- 插入占位元素
        end
    end
end

function XQueue:ClearUnUsed()
    local temp = {}
    for i = self.__StartIndex, self.__EndIndex do
        temp[#temp + 1] = self.__Container[i]
    end
    self.__StartIndex = 1
    self.__Container = temp
    self.__EndIndex = #temp
end

function XQueue:IsEmpty()
    return self.__StartIndex > self.__EndIndex
end

function XQueue:Count()
    return self.__EndIndex - self.__StartIndex + 1
end

function XQueue:Enqueue(element)
    if not element then return end
    
    local endIndex = self.__EndIndex + 1
    self.__EndIndex = endIndex
    self.__Container[endIndex] = element
end

function XQueue:EnqueueFront(element)
    self.__Container[self.__StartIndex - 1] = element
    self.__StartIndex = self.__StartIndex - 1
end

function XQueue:Dequeue()
    if self:IsEmpty() then
        self:Clear()
        return
    end

    local startIndex = self.__StartIndex
    local element = self.__Container[startIndex]

    self.__StartIndex = startIndex + 1
    self.__Container[startIndex] = nil

    return element
end

function XQueue:Peek()
    return self.__Container[self.__StartIndex]
end

function XQueue:SetErgodicFun(fun)
    self.__ErgodicFun = fun
end

function XQueue:Ergodic(fun)
    for i = self.__StartIndex, self.__EndIndex, 1 do
        local item = self.__Container[i]
        if item then
            if fun then
                fun(item, i)
            elseif self.__ErgodicFun then
                self.__ErgodicFun(item, i)
            end
        end
    end
end