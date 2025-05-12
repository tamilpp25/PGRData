local XPokerGuessing2ConfigModel = require("XModule/XPokerGuessing2/XPokerGuessing2ConfigModel")

---@class XPokerGuessing2Model : XPokerGuessing2ConfigModel
local XPokerGuessing2Model = XClass(XPokerGuessing2ConfigModel, "XPokerGuessing2Model")

function XPokerGuessing2Model:OnInit()
    self:_InitTableKey()
    ---@type NotifyPokerGuessing2Data
    self._ServerData = false
end

function XPokerGuessing2Model:ClearPrivate()
end

function XPokerGuessing2Model:SetServerData(serverData)
    self._ServerData = serverData
end

function XPokerGuessing2Model:GetActivityId()
    if self._ServerData and self._ServerData.ActivityId and self._ServerData.ActivityId ~= 0 then
        return self._ServerData.ActivityId
    end
    return false
end

function XPokerGuessing2Model:IsActivityOpen()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PokerGuessing2, false, true) then
        return false
    end
    if not self._ServerData then
        return false
    end
    local activityId = self._ServerData.ActivityId
    if not activityId or activityId == 0 then
        return false
    end
    local config = self:GetPokerGuessing2ActivityConfigById(activityId)
    if not config then
        return false
    end
    if not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        return false
    end
    return true
end

function XPokerGuessing2Model:IsStagePassed(stageId)
    if not self._ServerData then
        return false
    end
    for i = 1, #self._ServerData.PassStages do
        if self._ServerData.PassStages[i] == stageId then
            return true
        end
    end
    return false
end

function XPokerGuessing2Model:SetStagePassed(stageId)
    self._ServerData = self._ServerData or {}
    self._ServerData.PassStages = self._ServerData.PassStages or {}
    for i = 1, #self._ServerData.PassStages do
        if self._ServerData.PassStages[i] == stageId then
            return
        end
    end
    table.insert(self._ServerData.PassStages, stageId)
end

function XPokerGuessing2Model:IsStageCanChallenge(stageId)
    if self:IsPreStagePassed(stageId) and self:IsStageOnTime(stageId) then
        return true
    end
    return false
end

function XPokerGuessing2Model:IsPreStagePassed(stageId)
    local config = self:GetPokerGuessing2StageConfigById(stageId)
    local preStageId = config.PreStage
    if preStageId ~= 0 then
        if not self:IsStagePassed(preStageId) then
            return false
        end
    end
    return true
end

function XPokerGuessing2Model:IsStageOnTime(stageId)
    local config = self:GetPokerGuessing2StageConfigById(stageId)
    local timeId = config.TimeId
    if timeId ~= 0 then
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            return false
        end
    end
    return true
end

function XPokerGuessing2Model:IsStoryUnlock(storyId)
    if not self._ServerData.UnlockStorys then
        return false
    end
    for i = 1, #self._ServerData.UnlockStorys do
        if self._ServerData.UnlockStorys[i] == storyId then
            return true
        end
    end
    return false
end

function XPokerGuessing2Model:GetSelectedRole()
    return self._ServerData.CharacterId
end

function XPokerGuessing2Model:GetUnlockStorys()
    return self._ServerData.UnlockStorys
end

function XPokerGuessing2Model:GetAllCharacters()
    local list = {}
    local configs = self:GetPokerGuessing2CharacterConfigs()
    for _, config in pairs(configs) do
        table.insert(list, config)
    end
    table.sort(list, function(a, b)
        --return a.Id < b.Id
        return a.Order < b.Order
    end)
    return list
end

function XPokerGuessing2Model:GetStoryConfig(characterId)
    local storyConfigs = self:GetPokerGuessing2StoryConfigs()
    for _, config in pairs(storyConfigs) do
        if config.CharacterId == characterId then
            return config
        end
    end
    return false
end

function XPokerGuessing2Model:SetStoryUnlock(storyId)
    self._ServerData = self._ServerData or {}
    self._ServerData.UnlockStorys = self._ServerData.UnlockStorys or {}
    for i = 1, #self._ServerData.UnlockStorys do
        if self._ServerData.UnlockStorys[i] == storyId then
            return
        end
    end
    table.insert(self._ServerData.UnlockStorys, storyId)
end

return XPokerGuessing2Model