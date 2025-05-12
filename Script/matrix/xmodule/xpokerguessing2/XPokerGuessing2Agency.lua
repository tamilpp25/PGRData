local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPokerGuessing2Agency : XAgency
---@field private _Model XPokerGuessing2Model
local XPokerGuessing2Agency = XClass(XFubenActivityAgency, "XPokerGuessing2Agency")

function XPokerGuessing2Agency:OnInit()
    self._CurrentStageId = nil
    self._CurrentRound = nil
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XPokerGuessing2Agency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyPokerGuessing2Data = Handler(self, self.NotifyPokerGuessing2Data)
end

function XPokerGuessing2Agency:InitEvent()
    --实现跨Agency事件注册
end

function XPokerGuessing2Agency:NotifyPokerGuessing2Data(serverData)
    self._Model:SetServerData(serverData)
end

-- 开始游戏
function XPokerGuessing2Agency:StartNewPokerGuessing2Request(stageId, callback)
    XNetwork.Call("StartNewPokerGuessing2Request", {
        Stage = stageId,
    }, function(res)
        if res.Code ~= XCode.Success then
            if callback then
                callback(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        XSaveTool.SaveData("XPokerGuessing2StageCanChallenge" .. XPlayer.Id .. stageId, true)
        if callback then
            callback(res)
        end
    end)
end

-- 出牌
---@param card XPokerGuessing2Card
function XPokerGuessing2Agency:ActionPokerGuessing2Request(card, callback)
    XNetwork.Call("ActionPokerGuessing2Request", {
        PlayerCard = card:GetId(),
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

-- 使用帮助提示
function XPokerGuessing2Agency:UseTips2Request(callback)
    XNetwork.Call("UseTipsPokerGuessing2Request", {
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

-- 解锁角色剧情
function XPokerGuessing2Agency:UnlockStoryPokerGuessing2Request(storyId, callback)
    XNetwork.Call("UnlockStoryPokerGuessing2Request", {
        StoryId = storyId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

function XPokerGuessing2Agency:OpenMain()
    if self._Model:IsActivityOpen() then
        XLuaUiManager.Open("UiPokerGuessing2Main")
    else
        XUiManager.TipText("ActivityBranchNotOpen")
    end
end

function XPokerGuessing2Agency:ExCheckInTime()
    return true
end

function XPokerGuessing2Agency:HasTaskCanReceive()
    local activityId = self._Model:GetActivityId()
    if not activityId or activityId <= 0 then
        return false
    end
    local activityConfig = self._Model:GetPokerGuessing2ActivityConfigById(activityId)
    if not activityConfig then
        return false
    end
    local taskGroupId = activityConfig.TaskGroupId
    for i = 1, #taskGroupId do
        if XDataCenter.TaskManager.IsAnyTaskCanReceiveByTaskGroupId(taskGroupId[i]) then
            return true
        end
    end
    return false
end

function XPokerGuessing2Agency:IsShowRedDot()
    if self:HasTaskCanReceive() then
        return true
    end
    if self:HasStageCanChallenge() then
        return true
    end
    return false
end

function XPokerGuessing2Agency:HasStageCanChallenge()
    local stages = self._Model:GetPokerGuessing2StageConfigs()
    for i, stage in pairs(stages) do
        if self._Model:IsStageCanChallenge(stage.Id) and not self._Model:IsStagePassed(stage.Id) then
            if XSaveTool.GetData("XPokerGuessing2StageCanChallenge" .. XPlayer.Id .. stage.Id) == nil then
                return true
            end
        end
    end
    return false
end

function XPokerGuessing2Agency:ExGetProgressTip()
    local stages = self._Model:GetPokerGuessing2StageConfigs()
    local progress, max = 0, #stages
    for i, stage in pairs(stages) do
        if self._Model:IsStagePassed(stage.Id) then
            progress = progress + 1
        end
    end
    return XUiHelper.GetText("BossSingleProgress", progress, max)
end

function XPokerGuessing2Agency:SetCurrentStageId(stageId)
    self._CurrentStageId = stageId
end

function XPokerGuessing2Agency:SetCurrentRound(round)
    self._CurrentRound = round
end

function XPokerGuessing2Agency:CheckIsInStageAndRound(stageId, round)
    if not self._CurrentStageId then
        return false
    end
    if not self._CurrentRound then
        return false
    end
    if self._CurrentStageId == stageId and self._CurrentRound == round then
        return true
    end
    return false
end

function XPokerGuessing2Agency:IsAvgPlayed()
    if XSaveTool.GetData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id) == true then
        return true
    end
    return false
end

return XPokerGuessing2Agency