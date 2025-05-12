---@class XAreaWarQuest 全境任务
---@field _Id number
---@field _Type number 任务类型
---@field _StageId number 关卡Id
---@field _ChapterId number 区域
---@field _State number 任务状态
---@field _Like boolean 点赞状态
local XAreaWarQuest = XClass(nil, "XAreaWarQuest")

local State = {
    Inactive = 0,
    Finish = 1
}

function XAreaWarQuest:Ctor(id)
    self._Id = id
end

function XAreaWarQuest:UpdateData(data)
    if not data then
        return
    end
    self._Type = data.Type
    self._StageId = data.StageId
    self._ChapterId = data.ChapterId
    self._State = data.State
    self._Like = data.Like
    --包含字段
    --[[
        PlayerId,
        HeadPortraitId,
        HeadFrameId,
        Name,
    ]]
    self._CharacterInfo = data.Other
end

function XAreaWarQuest:GetId()
    return self._Id
end

function XAreaWarQuest:IsFight()
    return self._Type == XAreaWarConfigs.QuestType.Fight
end

function XAreaWarQuest:IsBeRescued()
    return self._Type == XAreaWarConfigs.QuestType.BeRescued
end

function XAreaWarQuest:IsRescue()
    return self._Type == XAreaWarConfigs.QuestType.Rescue
end

function XAreaWarQuest:GetType()
    return self._Type
end

function XAreaWarQuest:IsFinsh()
    return self._State == State.Finish
end

function XAreaWarQuest:Finish()
    self._State = State.Finish
    XEventManager.DispatchEvent(XEventId.EVNET_AREA_WAR_QUEST_FINISH, self._Id, self:IsRescue())
end

function XAreaWarQuest:GetStageId()
    if not XTool.IsNumberValid(self._StageId) then
        math.randomseed(XDataCenter.AreaWarManager.GetRandomSeed(false))
        local stageIds = XAreaWarConfigs.GetChapterStageIds(self._ChapterId)
        local count = #stageIds
        local index = math.random(1, count)
        self._StageId = stageIds[index]
    end
    return self._StageId
end

function XAreaWarQuest:GetStageName()
    return XAreaWarConfigs.GetQuestName(self._Type)
end

function XAreaWarQuest:GetStageDesc()
    return XAreaWarConfigs.GetQuestDesc(self._Type)
end

function XAreaWarQuest:GetRewardId()
    if self:IsFight() or self:IsBeRescued() then
        return XAreaWarConfigs.GetDailyBattleRewardId(self._ChapterId)
    elseif self:IsRescue() then
        if XDataCenter.AreaWarManager.GetPersonal():IsMaxRescueReward() then
            return -1
        end
        return XAreaWarConfigs.GetDailyHelpRewardId(self._ChapterId)
    end
    return 0
end

function XAreaWarQuest:GetRescuedPlayerId()
    return self._CharacterInfo and self._CharacterInfo[1] or 0
end

function XAreaWarQuest:GetRescuedHeadPortraitId()
    return self._CharacterInfo and self._CharacterInfo[2] or 0
end

function XAreaWarQuest:GetRescuedHeadFrameId()
    return self._CharacterInfo and self._CharacterInfo[3] or 0
end

function XAreaWarQuest:GetRescuedName()
    return self._CharacterInfo and self._CharacterInfo[4] or ""
end

function XAreaWarQuest:IsLiked()
    return self._Like
end

function XAreaWarQuest:SetLiked(value)
    self._Like = value
end

function XAreaWarQuest:Reset()
    self._Type = 0
    self._StageId = 0
    self._ChapterId = 0
    self._State = 0
    self._Like = 0
end

return XAreaWarQuest