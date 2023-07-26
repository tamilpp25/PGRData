-- 新手任务二期 播放器
---@class XNewbieTaskAnimPlayer
local XNewbieTaskAnimPlayer = XClass(nil, "XNewbieTaskAnimPlayer")
local CoolTime = 999 -- 冷却时间为999时进入系统只触发一次

local PlayerState = {
    IDLE = 0,
    PLAYING = 1,
    CHANGING = 2,
    PAUSE = 3
}

function XNewbieTaskAnimPlayer:Ctor(playUi, startTime, delay)
    if playUi == nil then
        return
    end
    
    self.PlayUi = playUi
    self.Status = PlayerState.IDLE
    self.Time = startTime
    self.DelayStart = self.Time + delay
    self.Delay = delay
    self.LastPlayTime = -1
    self.PlayOne = false -- 是否只播放优先级最高的动画
end

-- self.PlayerData.PlayerList = {} -- 播放列表
-- self.PlayerData.PlayingElement = nil --播放对象
-- self.PlayerData.PlayedList = {} -- 播放过的列表
-- self.PlayerData.LastPlayTime = -1 -- 上次播放的时间
function XNewbieTaskAnimPlayer:SetPlayerData(data)
    self.PlayerData = data
end

-- 设置播放队列
function XNewbieTaskAnimPlayer:SetPlayList(playList)
    if XTool.IsTableEmpty(playList) then
        return
    end
    
    self.PlayerData.PlayerList = {}
    self.PlayerData.LastPlayTime = -1
    self.DelayStart = self.Time + self.Delay

    for _, element in ipairs(playList) do
        if not self:CheckInCooling(element) then
            table.insert(self.PlayerData.PlayerList, element)
        end
    end
end

-- 播放
function XNewbieTaskAnimPlayer:Play(tab)
    if not tab then
        return false
    end

    if not self:IsActive() then
        return false
    end

    if self.PlayerData.PlayingElement and self.PlayerData.PlayingElement.Id == tab.Id then
        return false
    end

    if self:CheckInCooling(tab) then
        return false
    end
    
    local element = {}
    element.Id = tab.Id
    element.StartTime = -1 --开始播放的时间
    element.EndTime = -1 --结束时间
    element.Duration = tab.Duration  --播放持续时间
    element.CoolTime = tab.CoolTime --冷却时间
    element.Priority = tab.Priority -- 优先级
    element.Config = tab

    table.insert(self.PlayerData.PlayerList, element)

    if #self.PlayerData.PlayerList > 1 then
        -- 根据优先级排序
        table.sort(self.PlayerData.PlayerList, function(a, b)
            return a.Priority < b.Priority
        end)
    end
    
    return true
end

-- 播放下一个
function XNewbieTaskAnimPlayer:PlayNext()
    if not self:IsActive() then
        return
    end

    if XTool.IsTableEmpty(self.PlayerData.PlayerList) then
        return
    end
    
    -- 取第一个动画播放
    local head = self.PlayerData.PlayerList[1]
    
    head.StartTime = self.Time
    head.EndTime = head.StartTime + head.Duration
    
    self.PlayerData.PlayingElement = head
    self.Status = PlayerState.PLAYING
    self.PlayerData.LastPlayTime = head.EndTime

    self.PlayUi:Play(head)

    if self.PlayOne then
        -- 清空播放列表，只播放当前优先级最高的动画(head)
        self.PlayerData.PlayerList = {}
    end
end

function XNewbieTaskAnimPlayer:Update(deltaTime)
    self.Time = self.Time + deltaTime

    if self.Time < self.DelayStart then
        return
    end

    if not self:IsActive() then
        return
    end

    if XTool.IsTableEmpty(self.PlayerData.PlayerList) and self.PlayerData.PlayingElement == nil then
        return
    end

    if self.Status == PlayerState.PAUSE then
        return
    end
    
    -- 存在播放中的动作
    if self.PlayerData.PlayingElement ~= nil and self.PlayerData.PlayingElement.Duration > 0 then
        local deadline = self.PlayerData.PlayingElement.EndTime
        if deadline < self.Time then
            self:Stop()
            return
        end
    end

    if self.Status ~= PlayerState.PLAYING then
        self:PlayNext()
    end
end

function XNewbieTaskAnimPlayer:IsPlaying()
    return self.Status == PlayerState.PLAYING
end

function XNewbieTaskAnimPlayer:SetPlayOne(bPlayOne)
    self.PlayOne = bPlayOne
end

function XNewbieTaskAnimPlayer:CheckIsPlayIdle(conditionParam)
    local bWaitInterval = self.Time - self.LastPlayTime >= conditionParam
    if self.Status == PlayerState.IDLE and self.LastPlayTime > 0 and bWaitInterval then
        return true
    end
    return false
end

-- 判断动画是否在冷却中
function XNewbieTaskAnimPlayer:CheckInCooling(tab)
    -- 判断当前动画是否在冷却中
    local lastPlayTime = self.PlayerData.PlayedList[tab.Id]
    if lastPlayTime then
        if tab.CoolTime == CoolTime then
            -- 只播放一次
            return true
        end
        if self.Time < lastPlayTime then
            return true
        end
    end
    
    return false
end

-- 停止
function XNewbieTaskAnimPlayer:Stop()
    if self.PlayerData.PlayingElement == nil then
        return
    end
    self.PlayerData.PlayedList[self.PlayerData.PlayingElement.Id] = self.PlayerData.PlayingElement.EndTime + self.PlayerData.PlayingElement.CoolTime
    self.PlayUi:OnStop(self.PlayerData.PlayingElement)
    self.PlayerData.PlayingElement = nil
    self.Status = PlayerState.IDLE
    self.LastPlayTime = self.Time
end

-- 暂停
function XNewbieTaskAnimPlayer:Pause()
    self.Status = PlayerState.PAUSE
end

-- 恢复
function XNewbieTaskAnimPlayer:Resume()
    self.LastPlayTime = self.Time
    self.Status = PlayerState.IDLE
end

--region 生命周期

function XNewbieTaskAnimPlayer:IsActive()
    return self.Active
end

function XNewbieTaskAnimPlayer:OnEnable()
    self.Active = true
    self:Resume()
end

function XNewbieTaskAnimPlayer:OnDisable()
    self.Active = false
    self:Stop()
end

function XNewbieTaskAnimPlayer:OnDestroy()
    self:Stop()
end

--endregion

return XNewbieTaskAnimPlayer