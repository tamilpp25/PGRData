XStack = XClass(nil, "XStack")

function XStack:Ctor()
    self:Clear()
end

function XStack:Clear()
    self.__Container = {}
    self.__EndIndex = 0
end

function XStack:IsEmpty()
    return self.__EndIndex < 1
end

function XStack:Count()
    return self.__EndIndex
end

function XStack:Push(element)
    if not element then return end

    local endIndex = self.__EndIndex + 1
    self.__EndIndex = endIndex
    self.__Container[endIndex] = element
end

function XStack:Pop()
    if self:IsEmpty() then
        self:Clear()
        return
    end

    local endIndex = self.__EndIndex
    local element = self.__Container[endIndex]

    self.__EndIndex = endIndex - 1
    self.__Container[endIndex] = nil

    return element
end

function XStack:Peek()
    return self.__Container[self.__EndIndex]
end