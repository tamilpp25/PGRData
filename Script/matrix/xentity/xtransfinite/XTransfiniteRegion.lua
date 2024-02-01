---@class XTransfiniteRegion
local XTransfiniteRegion = XClass(nil, "XTransfiniteRegion")

function XTransfiniteRegion:Ctor(id)
    self._Id = id
    self._Color = false
    self._IsRunning = false
    self._DictScoreRewardReceived = {}
end

function XTransfiniteRegion:SetId(id)
    self._Id = id
    self._Color = false
end

function XTransfiniteRegion:GetId()
    return self._Id
end

function XTransfiniteRegion:GetName()
    return XTransfiniteConfigs.GetRegionRegionName(self._Id)
end

function XTransfiniteRegion:GetMinLv()
    return XTransfiniteConfigs.GetRegionMinLv(self._Id)
end

function XTransfiniteRegion:GetMaxLv()
    return XTransfiniteConfigs.GetRegionMaxLv(self._Id)
end

function XTransfiniteRegion:GetChallengeTaskGroupId()
    return XTransfiniteConfigs.GetRegionChallengeTaskGroupId(self._Id)
end

function XTransfiniteRegion:IsAllChallengeRewardReceived()
    local taskGroupId = self:GetChallengeTaskGroupId()
    if XDataCenter.TransfiniteManager.IsTaskFinishedByTaksGroupId(taskGroupId) then
        return true  
    end
    return false
end

function XTransfiniteRegion:GetIslandId()
    return XTransfiniteConfigs.GetRegionIslandId(self._Id)
end

function XTransfiniteRegion:GetIslandStageGroupIdArray()
    local islandId = self:GetIslandId()
    local stageGroupIdArray = XTransfiniteConfigs.GetIslandStageGroupId(islandId)
    return stageGroupIdArray
end

function XTransfiniteRegion:GetIconLv()
    return XTransfiniteConfigs.GetRegionIconLv(self._Id)
end

function XTransfiniteRegion:GetRewardIds()
    return XTransfiniteConfigs.GetRegionDisplayRewardIds(self._Id)
end

function XTransfiniteRegion:GetColor()
    if not self._Color then
        if self._Id == 1 then
            self._Color = XUiHelper.Hexcolor2Color("34AFF8FF")
        else
            self._Color = XUiHelper.Hexcolor2Color("34A008FF")
        end
    end
    return self._Color
end

function XTransfiniteRegion:GetStageGroupIdArray()
    local rotateGroupId = XTransfiniteConfigs.GetRegionRotateGroupId(self._Id)
    local stageGroupIdArray = XTransfiniteConfigs.GetRotateStageGroupId(rotateGroupId)
    return stageGroupIdArray
end

function XTransfiniteRegion:GetIsSeniorRegion()
    return self._Id == XTransfiniteConfigs.RegionType.Senior
end

function XTransfiniteRegion:GetScoreAndRewardArray()
    local scoreArray, rewardArray = XTransfiniteConfigs.GetScoreArray(self:GetId())
    return scoreArray, rewardArray
end

function XTransfiniteRegion:IsRewardReceived(index)
    return self._DictScoreRewardReceived[index] ~= nil
end

function XTransfiniteRegion:SetRewardReceived(index)
    self._DictScoreRewardReceived[index] = 0
end

function XTransfiniteRegion:SetRewardReceivedFromServer(list)
    local dict = {}
    if list then
        for i = 1, #list do
            -- 服务端从0开始
            local index = list[i] + 1
            dict[index] = true
        end
    end
    self._DictScoreRewardReceived = dict
end

function XTransfiniteRegion:GetScoreRewardIndexCanReceive()
    local score = XDataCenter.TransfiniteManager.GetScore()
    local scoreArray = self:GetScoreAndRewardArray()
    local list = {}
    for i = 1, #scoreArray do
        local scoreNeed = scoreArray[i]
        if score >= scoreNeed and not self:IsRewardReceived(i) then
            list[#list + 1] = i - 1
        end
    end
    return list
end

function XTransfiniteRegion:GetScoreRewardIdCanReceive()
    local score = XDataCenter.TransfiniteManager.GetScore()
    local scoreArray, rewardIdArray = self:GetScoreAndRewardArray()
    local list = {}
    for i = 1, #scoreArray do
        local scoreNeed = scoreArray[i]
        if score >= scoreNeed and not self:IsRewardReceived(i) then
            list[#list + 1] = rewardIdArray[i]
        end
    end
    return list
end

function XTransfiniteRegion:IsScoreRewardCanReceive()
    local score = XDataCenter.TransfiniteManager.GetScore()
    local scoreArray = self:GetScoreAndRewardArray()
    for i = 1, #scoreArray do
        local scoreNeed = scoreArray[i]
        if score >= scoreNeed and not self:IsRewardReceived(i) then
            return true
        end
    end
    return false
end

function XTransfiniteRegion:IsAllScoreRewardReceived()
    local scoreArrayNormal = self:GetScoreAndRewardArray()
    for i = 1, #scoreArrayNormal do
        if not self:IsRewardReceived(i) then
            return false
        end
    end
    return true
end

function XTransfiniteRegion:IsRunning()
    return self._IsRunning
end

function XTransfiniteRegion:SetRunning(value)
    self._IsRunning = value
end

return XTransfiniteRegion
