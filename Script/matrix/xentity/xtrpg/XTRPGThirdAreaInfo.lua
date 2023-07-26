local type = type
local pairs = pairs

local XTRPGThirdAreaInfo = XClass(nil, "XTRPGThirdAreaInfo")

local Default = {
    __Id = 0,
    __FinshedFunctionIdDic = {},
}

function XTRPGThirdAreaInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGThirdAreaInfo:UpdateData(data)
    if not data then return end

    self.__Id = data.Id
    for _, functionId in pairs(data) do
        self.__FinshedFunctionIdDic[functionId] = functionId
    end
end

function XTRPGThirdAreaInfo:GetId()
    return self.__Id
end

function XTRPGThirdAreaInfo:IsFunctionFinished(functionId)
    return self.__FinshedFunctionIdDic[functionId] and true or false
end

function XTRPGThirdAreaInfo:SetFunctionFinished(functionId)
    self.__FinshedFunctionIdDic[functionId] = functionId
end

return XTRPGThirdAreaInfo