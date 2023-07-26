---@class XViewModelMaze
local XViewModelMaze = XClass(nil, "XViewModelMaze")

function XViewModelMaze:Ctor()
end

function XViewModelMaze:OnEnable()
    if self:IsPlayMovie() then
        XDataCenter.MazeManager.AutoRequestGetTicket()
    end
end

function XViewModelMaze:GetActivityName()
    local name = XMazeConfig.GetName()
    return name
end

function XViewModelMaze:GetPlayerPrefsKey()
    return XDataCenter.MazeManager.GetPlayerPrefsKey()
end

-- 玩家首次进入玩法时，会播放首次进入剧情
function XViewModelMaze:IsPlayMovie()
    return XDataCenter.MazeManager.IsFirstTime()
end

function XViewModelMaze:SetHasPlayMovie()
    CS.UnityEngine.PlayerPrefs.SetInt(self:GetPlayerPrefsKey(), 0)
end

function XViewModelMaze:GetRemainTimeActivity()
    local timeId = XMazeConfig.GetTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    local remainTime = math.max(0, endTime - nowTime)
    return remainTime
end

function XViewModelMaze:GetRemainTimeTicket()
    local refreshTime = XTime.GetSeverNextRefreshTime()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = refreshTime - currentTime
    return remainTime
end

function XViewModelMaze:GetStoryId()
    return XMazeConfig.GetStoryId()
end

function XViewModelMaze:GetTaskProgress()
    return XDataCenter.MazeManager.GetTaskProgress()
end

function XViewModelMaze:IsGetTicket()
    return XDataCenter.MazeManager.IsGetTicket()
end

function XViewModelMaze:IsShowTaskRedDot()
    return XDataCenter.MazeManager.IsTaskCanGetReward()
end

return XViewModelMaze