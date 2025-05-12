local type = type
local pairs = pairs
local isNumberValid = XTool.IsNumberValid

local Default = {
    _Id = 0, --关卡Id
    _BuffId = 0, --环境BuffId
    _IsFinished = false, --是否完成
}

---@class XStrongholdStageData
local XStrongholdStageData = XClass(nil, "XStrongholdStageData")

function XStrongholdStageData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XStrongholdStageData:SetBuff(buffId, extendBuffId)
    if not isNumberValid(buffId) then return end
    self._BuffId = buffId
    self._ExtendBuffId = extendBuffId
end

function XStrongholdStageData:GetBuffId()
    return self._BuffId
end

function XStrongholdStageData:GetExtendBuffId()
    return self._ExtendBuffId
end

function XStrongholdStageData:SetFinished(value)
    self._IsFinished = value and true or false
end

function XStrongholdStageData:IsFinished()
    return self._IsFinished
end

return XStrongholdStageData