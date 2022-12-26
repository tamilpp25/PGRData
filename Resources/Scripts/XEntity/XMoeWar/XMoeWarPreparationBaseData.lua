--萌战赛事筹备--基本数据
local type = type
local tableInsert = table.insert

local XMoeWarPreparationHelper = require("XEntity/XMoeWar/XMoeWarPreparationHelper")
local XMoeWarPreparationAssistance = require("XEntity/XMoeWar/XMoeWarPreparationAssistance")
local XMoeWarPreparationVoteItem = require("XEntity/XMoeWar/XMoeWarPreparationVoteItem")
local XMoeWarPreparationStage = require("XEntity/XMoeWar/XMoeWarPreparationStage")

local XMoeWarPreparationBaseData = XClass(nil, "XMoeWarPreparationBaseData")

local DefaultMain = {
    ActivityId = 0,     --活动id
    MatchId = 0,        --赛事阶段id
    Stage = {},        --关卡对象
    GetRewardGears = {},    --已领取奖励的档位字典
    HelpersDic = {},       --帮手字典（服务端是列表）
    Assistance = {},    --援助数据
    VoteItemsDic = {},     --应援道具
}

function XMoeWarPreparationBaseData:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.Assistance = XMoeWarPreparationAssistance.New()
    self.Stage = XMoeWarPreparationStage.New()
end

function XMoeWarPreparationBaseData:UpdateData(data)
    if not data then return end
    self.ActivityId = data.ActivityId
    self.MatchId = data.MatchId
    self.GetRewardGears = data.GetRewardGears
    self:UpdateAssistance(data.Assistance)
    self:UpdateHelper(data.Helpers)
    self:UpdateVoteItems(data.VoteItems)
    self:UpdateStage(data.Stage)
end

------关卡对象 begin----------
function XMoeWarPreparationBaseData:UpdateStage(stage)
    self.Stage:UpdateData(stage)
end

function XMoeWarPreparationBaseData:GetStages()
    return self.Stage:GetStages()
end

function XMoeWarPreparationBaseData:GetStagesAndOneReserveStage()
    return self.Stage:GetStagesAndOneReserveStage()
end

function XMoeWarPreparationBaseData:GetReserveStageTimeByIndex(index)
    return self.Stage:GetReserveStageTimeByIndex(index)
end

function XMoeWarPreparationBaseData:GetAllOpenStageIdList()
    return self.Stage:GetAllOpenStageIdList()
end

function XMoeWarPreparationBaseData:GetAllOpenStageCount()
    return self.Stage:GetAllOpenStageCount()
end
------关卡对象 end----------

------应援数据 begin----------
function XMoeWarPreparationBaseData:UpdateVoteItems(voteItems)
    for _, voteItem in pairs(voteItems) do
        self:UpdateVoteItem(voteItem)
    end
end

function XMoeWarPreparationBaseData:UpdateVoteItem(voteItem)
    if not self.VoteItemsDic[voteItem.ItemId] then
        self.VoteItemsDic[voteItem.ItemId] = XMoeWarPreparationVoteItem.New()
    end
    self.VoteItemsDic[voteItem.ItemId]:UpdateData(voteItem)
end

function XMoeWarPreparationBaseData:GetVoteItemCount(itemId)
    return self.VoteItemsDic[itemId] and self.VoteItemsDic[itemId]:GetItemCount() or 0
end
------应援数据 end----------

--------帮手 begin----------
function XMoeWarPreparationBaseData:GetHelper(helperId)
    if not self.HelpersDic[helperId] then
        self.HelpersDic[helperId] = XMoeWarPreparationHelper.New()
        self.HelpersDic[helperId]:SetId(helperId)
    end
    return self.HelpersDic[helperId]
end

function XMoeWarPreparationBaseData:UpdateHelper(helpers)
    self.HelpersDic = {}
    for _, helperData in ipairs(helpers) do
        local helper = self:GetHelper(helperData.Id)
        helper:UpdateData(helperData)
    end
end

function XMoeWarPreparationBaseData:GetHelperStatus(helperId)
    if not XTool.IsNumberValid(helperId) then
        return 0
    end
    local helper = self:GetHelper(helperId)
    return helper:GetStatus()
end

function XMoeWarPreparationBaseData:GetHelperExpirationTime(helperId)
    if not XTool.IsNumberValid(helperId) then
        return 0
    end
    local helper = self:GetHelper(helperId)
    return helper:GetExpirationTime()
end

function XMoeWarPreparationBaseData:GetTotalQuestionCount(helperId)
    if not XTool.IsNumberValid(helperId) then
        return 0
    end
    local helper = self:GetHelper(helperId)
    return helper:GetTotalQuestionCount()
end

function XMoeWarPreparationBaseData:GetAnswerRecords(helperId)
    if not XTool.IsNumberValid(helperId) then
        return 0
    end
    local helper = self:GetHelper(helperId)
    return helper:GetAnswerRecords()
end

function XMoeWarPreparationBaseData:GetFinishQuestionCount(helperId)
    if not XTool.IsNumberValid(helperId) then
        return 0
    end
    local helper = self:GetHelper(helperId)
    return helper:GetFinishQuestionCount()
end

function XMoeWarPreparationBaseData:GetAllHelpersDic()
    return self.HelpersDic
end

function XMoeWarPreparationBaseData:InsertQuestion(helperId, questionId)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:InsertQuestion(questionId)
end

function XMoeWarPreparationBaseData:UpdateAnswerRecord(helperId, answerId, isRight)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:UpdateAnswerRecord(answerId, isRight)
end

function XMoeWarPreparationBaseData:SetCurrQuestionId(helperId, questionId)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:SetCurrQuestionId(questionId)
end

function XMoeWarPreparationBaseData:GetCurrQuestionId(helperId)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    return helper:GetCurrQuestionId()
end

function XMoeWarPreparationBaseData:SetHelperStatus(helperId, status)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:SetStatus(status)
end

function XMoeWarPreparationBaseData:SetHelperExpirationTime(helperId, expirationTime)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:SetExpirationTime(expirationTime)
end

function XMoeWarPreparationBaseData:ClearAnswerRecords(helperId)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:ClearAnswerRecords()
end

function XMoeWarPreparationBaseData:AddOnceFinishQuestionCount(helperId)
    if not XTool.IsNumberValid(helperId) then
        return
    end
    local helper = self:GetHelper(helperId)
    helper:AddOnceFinishQuestionCount()
end

function XMoeWarPreparationBaseData:QuestionIsRight(helperId, questionId)
    if not XTool.IsNumberValid(helperId) or not XTool.IsNumberValid(questionId) then
        return false
    end

    local helper = self:GetHelper(helperId)
    return helper:QuestionIsRight(questionId)
end

function XMoeWarPreparationBaseData:GetAnswerId(helperId, questionId)
    if not XTool.IsNumberValid(helperId) or not XTool.IsNumberValid(questionId) then
        return false
    end

    local helper = self:GetHelper(helperId)
    return helper:GetAnswerId(questionId)
end
--------帮手 end-----------

------援助数据 begin----------
function XMoeWarPreparationBaseData:UpdateAssistance(assistance)
    self.Assistance:UpdateData(assistance)
end

function XMoeWarPreparationBaseData:GetAssistanceCount()
    return self.Assistance:GetAssistanceCount()
end

function XMoeWarPreparationBaseData:GetAssistanceRecoveryTime()
    return self.Assistance:GetRecoveryTime()
end
------援助数据 end----------

function XMoeWarPreparationBaseData:GetMatchId()
    return self.MatchId
end

function XMoeWarPreparationBaseData:GetActivityId()
    return self.ActivityId
end

function XMoeWarPreparationBaseData:SetOverReceiveRewardGear(gearId)
    tableInsert(self.GetRewardGears, gearId)
end

function XMoeWarPreparationBaseData:IsGetRewardGears(gear)
    for _, gearId in pairs(self.GetRewardGears) do
        if gear == gearId then
            return true
        end
    end
    return false
end

function XMoeWarPreparationBaseData:ClearGetRewardGears()
    self.GetRewardGears = {}
end

return XMoeWarPreparationBaseData