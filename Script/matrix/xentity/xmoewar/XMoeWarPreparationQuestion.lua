--萌战赛事筹备--帮手数据
local type = type

local XMoeWarPreparationQuestion = XClass(nil, "XMoeWarPreparationQuestion")

local DefaultMain = {
    QuestionId = 0, --问题 id
    AnswerId = 0,   --回答 id, 0 表示未回答
    IsRight = 0,    --是否正确，0 表示不正确
}

function XMoeWarPreparationQuestion:Ctor(data)
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:UpdateData(data)
end

function XMoeWarPreparationQuestion:UpdateData(data)
    self.QuestionId = data.QuestionId
    self.AnswerId = data.AnswerId
    self.IsRight = data.IsRight
end

function XMoeWarPreparationQuestion:GetQuestionId()
    return self.QuestionId
end

function XMoeWarPreparationQuestion:GetAnswerId()
    return self.AnswerId
end

function XMoeWarPreparationQuestion:IsRight()
    return self.IsRight == 1
end

return XMoeWarPreparationQuestion