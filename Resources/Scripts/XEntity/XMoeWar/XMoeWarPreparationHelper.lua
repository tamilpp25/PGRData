--萌战赛事筹备--帮手数据
local type = type
local tableInsert = table.insert
local tableRemove = table.remove

local XMoeWarPreparationAnswerRecord = require("XEntity/XMoeWar/XMoeWarPreparationAnswerRecord")

local XMoeWarPreparationHelper = XClass(nil, "XMoeWarPreparationHelper")

local DefaultMain = {
    Id = 0,                 --帮手id
    ExpirationTime = 0,     --过期时间点，0表示不会过期
    TotalQuestionCount = 0, --题目总数
    FinishQuestionCount = 0,    --回答正确的题目数量
    Status = 0,             --帮手状态
    AnswerRecords = {},     --回答记录
}

function XMoeWarPreparationHelper:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.CurrQuestionId = 0
end

function XMoeWarPreparationHelper:UpdateData(data)
    self.Id = data.Id
    self.TotalQuestionCount = data.TotalQuestionCount
    self.FinishQuestionCount = data.FinishQuestionCount
    self.ExpirationTime = data.ExpirationTime
    self.Status = data.Status
    self:UpdateAnswerRecords(data.AnswerRecords)
end

function XMoeWarPreparationHelper:SetId(id)
    self.Id = id
end

function XMoeWarPreparationHelper:UpdateAnswerRecords(answerRecords)
    self.AnswerRecords = {}
    self:CheckQuestionStart()

    local answerRecord
    for _, anserRecordData in ipairs(answerRecords) do
        answerRecord = XMoeWarPreparationAnswerRecord.New()
        answerRecord:UpdateData(anserRecordData)
        tableInsert(self.AnswerRecords, answerRecord)
    end
end

function XMoeWarPreparationHelper:GetAnswerRecords()
    return self.AnswerRecords
end

function XMoeWarPreparationHelper:CheckQuestionStart()
    local status = self:GetStatus()
    if status ~= XMoeWarConfig.PreparationHelperStatus.Communicating then
        return
    end

    local isHasQuestionStart = false
    for _, answerRecord in ipairs(self.AnswerRecords) do
        local questionId = answerRecord:GetQuestionId()
        local questionType = XMoeWarConfig.GetPreparationQuestionType(questionId)
        if questionType == XMoeWarConfig.QuestionType.QuestionStart then
            isHasQuestionStart = true
            break
        end
    end
    if not isHasQuestionStart then
        local questionStartList = XMoeWarConfig.GetPreparationQuestionIdListByType(self.Id, XMoeWarConfig.QuestionType.QuestionStart)
        local answerRecord
        for _, questionId in ipairs(questionStartList) do
            answerRecord = XMoeWarPreparationAnswerRecord.New()
            answerRecord:SetQuestionId(questionId)
            tableInsert(self.AnswerRecords, answerRecord)
        end
    end
end

--检查问题是否都完了，插入结束语
function XMoeWarPreparationHelper:CheckQuestionEnd()
    local isHasQuestionEnd = false
    for _, answerRecord in ipairs(self.AnswerRecords) do
        local questionId = answerRecord:GetQuestionId()
        local questionType = XMoeWarConfig.GetPreparationQuestionType(questionId)
        if questionType == XMoeWarConfig.QuestionType.RecruitRight or questionType == XMoeWarConfig.QuestionType.RecruitLose then
            isHasQuestionEnd = true
            break
        end
    end
    if (not isHasQuestionEnd) and (self.Status == XMoeWarConfig.PreparationHelperStatus.CommunicationEnd or self.Status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish) then
        local questionType = self.Status == XMoeWarConfig.PreparationHelperStatus.CommunicationEnd and XMoeWarConfig.QuestionType.RecruitLose or XMoeWarConfig.QuestionType.RecruitRight
        local questionId = XMoeWarConfig.GetPreparationQuestionId(self.Id, questionType)
        local answerRecord = XMoeWarPreparationAnswerRecord.New()
        answerRecord:SetQuestionId(questionId)
        tableInsert(self.AnswerRecords, answerRecord)
    end
end

function XMoeWarPreparationHelper:InsertQuestion(questionId)
    local answerRecord = self:GetAnswerRecordByQuestionId(questionId)
    if answerRecord then
        return
    end
    self:CheckQuestionStart()
    answerRecord = XMoeWarPreparationAnswerRecord.New()
    answerRecord:SetQuestionId(questionId)
    tableInsert(self.AnswerRecords, answerRecord)
end

function XMoeWarPreparationHelper:UpdateAnswerRecord(answerId, isRight)
    local questionId = self:GetCurrQuestionId()
    local answerRecord = self:GetAnswerRecordByQuestionId(questionId)
    if answerRecord then
        answerRecord:UpdateData({QuestionId = questionId, AnswerId = answerId, IsRight = isRight})
    end
end

function XMoeWarPreparationHelper:GetAnswerRecordByQuestionId(questionId)
    for _, answerRecord in ipairs(self.AnswerRecords) do
        if answerRecord:GetQuestionId() == questionId then
            return answerRecord
        end
    end
end

function XMoeWarPreparationHelper:SetStatus(status)
    self.Status = status
    if status == XMoeWarConfig.PreparationHelperStatus.CommunicationEnd or status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish then
        self:CheckQuestionEnd()
    end
    if status == XMoeWarConfig.PreparationHelperStatus.NotCommunicating then
        self:ResetData()
    end
end

function XMoeWarPreparationHelper:ResetData()
    self.FinishQuestionCount = 0
    self:ClearAnswerRecords()
end

function XMoeWarPreparationHelper:SetCurrQuestionId(currQuestionId)
    self.CurrQuestionId = currQuestionId
end

function XMoeWarPreparationHelper:SetExpirationTime(expirationTime)
    self.ExpirationTime = expirationTime
end

function XMoeWarPreparationHelper:ClearAnswerRecords()
    self.AnswerRecords = {}
end

function XMoeWarPreparationHelper:GetCurrQuestionId()
    return self.CurrQuestionId
end

function XMoeWarPreparationHelper:GetId()
    return self.Id
end

function XMoeWarPreparationHelper:GetTotalQuestionCount()
    return self.TotalQuestionCount
end

function XMoeWarPreparationHelper:GetStatus()
    return self.Status
end

function XMoeWarPreparationHelper:GetExpirationTime()
    return self.ExpirationTime
end

function XMoeWarPreparationHelper:AddOnceFinishQuestionCount()
    self.FinishQuestionCount = self.FinishQuestionCount + 1
end

function XMoeWarPreparationHelper:GetFinishQuestionCount()
    return self.FinishQuestionCount
end

function XMoeWarPreparationHelper:GetAnswerRecord(questionId)
    local answerRecords = self:GetAnswerRecords()
    for _, v in ipairs(answerRecords) do
        if v:GetQuestionId() == questionId then
            return v
        end
    end
end

function XMoeWarPreparationHelper:QuestionIsRight(questionId)
    local answerRecord = self:GetAnswerRecord(questionId)
    return answerRecord and answerRecord:QuestionIsRight() or 0
end

function XMoeWarPreparationHelper:GetAnswerId(questionId)
    local answerRecord = self:GetAnswerRecord(questionId)
    return answerRecord and answerRecord:GetAnswerId() or 0
end

return XMoeWarPreparationHelper