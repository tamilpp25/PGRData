--萌战赛事筹备--问题
local type = type

local XMoeWarPreparationAnswerRecord = XClass(nil, "XMoeWarPreparationAnswerRecord")

local DefaultMain = {
    QuestionId = 0, --问题 id
    AnswerId = 0,   --回答 id, 0 表示未回答
    IsRight = false,    --是否正确
}

function XMoeWarPreparationAnswerRecord:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XMoeWarPreparationAnswerRecord:UpdateData(data)
    self.QuestionId = data.QuestionId
    self.AnswerId = data.AnswerId
    self.IsRight = data.IsRight
end

function XMoeWarPreparationAnswerRecord:GetQuestionId()
    return self.QuestionId
end

function XMoeWarPreparationAnswerRecord:GetAnswerId()
    return self.AnswerId
end

function XMoeWarPreparationAnswerRecord:QuestionIsRight()
    return self.IsRight
end

function XMoeWarPreparationAnswerRecord:SetQuestionId(questionId)
    self.QuestionId = questionId
end

return XMoeWarPreparationAnswerRecord