--萌战赛事筹备--援助数据
local type = type

local XMoeWarPreparationAssistance = XClass(nil, "XMoeWarPreparationAssistance")

local DefaultMain = {
    AssistanceCount = 0,  --援助次数
    RecoveryTime = 0,     --恢复时间点
}

function XMoeWarPreparationAssistance:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XMoeWarPreparationAssistance:UpdateData(data)
    self.AssistanceCount = data.AssistanceCount
    self.RecoveryTime = data.RecoveryTime
end

function XMoeWarPreparationAssistance:GetAssistanceCount()
    return self.AssistanceCount
end

function XMoeWarPreparationAssistance:GetRecoveryTime()
    return self.RecoveryTime
end

return XMoeWarPreparationAssistance