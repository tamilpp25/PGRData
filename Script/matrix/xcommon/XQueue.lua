XQueue = XClass(nil, "XQueue")

function XQueue:Ctor()
    self:Clear()
end

function XQueue:Clear()
    self.__Container = {}
    self.__StartIndex = 1
    self.__EndIndex = 0
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