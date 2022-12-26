local XSignBoardPlayer = {}

local PlayerState = {
    IDLE = 0,
    PLAYING = 1,
    CHANGING = 2,
    PAUSE = 3
}

--创建一个播放器
function XSignBoardPlayer.New(playUi, coolTime, delay)
    if playUi == nil then
        return nil
    end

    local player = {}
    setmetatable(player, { __index = XSignBoardPlayer })
    player:Init(playUi, coolTime, delay)
    return player
end

--初始化
function XSignBoardPlayer:Init(playUi, coolTime, delay)

    self.CoolTime = coolTime --冷却时间
    self.PlayUi = playUi    --执行Ui
    self.Status = PlayerState.IDLE
    self.DelayStart = XTime.GetServerNowTimestamp() + delay
    self.LastPlayTime = -1
    self.Delay = delay
    self.Time = XTime.GetServerNowTimestamp()
    self.AutoPlay = true
    self.PlayOne = false
end


-- self.PlayerData.PlayerList = {} --播放列表
-- self.PlayerData..PlayingElement = nil --播放对象
-- self.PlayerData.PlayedList = {} --播放过的列表
-- self.LastPlayTime = -1 --上次播放时间
function XSignBoardPlayer:SetPlayerData(data)
    self.PlayerData = data
end

--设置播放队列
function XSignBoardPlayer:SetPlayList(playList)
    if not playList or #playList <= 0 then
        return
    end

    self.PlayerData.PlayerList = {}
    self.PlayerData.LastPlayTime = -1
    self.DelayStart = self.Time + self.Delay

    for _, element in ipairs(playList) do
        table.insert(self.PlayerData.PlayerList, element)
    end
end

--播放
function XSignBoardPlayer:Play(tab, cvType)
    if not tab then
        return false
    end

    if not self:IsActive() then
        return false
    end

    if self.PlayerData.PlayingElement and self.PlayerData.PlayingElement.Id == tab.Id then
        return false
    end

    local element = {}
    element.Id = tab.Id --Id
    element.AddTime = self.Time  -- 添加事件
    element.StartTime = -1 --开始播放的时间
    element.EndTime = -1 --结束时间

    -- 获取相应语言的动作持续时间
    local duration
    local defaultCvType = CS.XGame.Config:GetInt("DefaultCvType")
    local curElementCvType = cvType or CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", defaultCvType)

    if tab.Duration[curElementCvType] == nil then
        if tab.Duration[defaultCvType] == nil then
            XLog.Error(string.format("XSignBoardPlayer:Play函数错误，配置表SignboardFeedback.tab没有配置Id:%s的Duration数据", tostring(element.Id)))
            return false
        end
        duration = tab.Duration[defaultCvType]
    else
        duration = tab.Duration[curElementCvType]
    end

    element.Duration = duration
    element.Validity = tab.Validity --有效期
    element.CoolTime = 0--tab.CoolTime --冷却时间
    element.Weight = tab.Weight --权重
    element.SignBoardConfig = tab
    element.CvType = cvType
    table.insert(self.PlayerData.PlayerList, 1, element)

    return true
end

--播放下一个
--isRecord决定是否要保存当前动作播放记录
function XSignBoardPlayer:PlayNext(isRecord)
    if not self:IsActive() then
        return
    end

    if not self.PlayerData.PlayerList or #self.PlayerData.PlayerList == 0 then
        return
    end

    --获取第一个在有限期之类的动画
    local head = nil
    while #self.PlayerData.PlayerList > 0 and not head do

        local temp = table.remove(self.PlayerData.PlayerList, 1)
        -- local lastPlayTime = self.PlayerData.PlayedList[temp.Id]
        -- --如果还在冷却中
        -- if lastPlayTime and self.Time < lastPlayTime then
        --     if #self.PlayerData.PlayerList <= 0 then
        --         break
        --     end
        --     temp = table.remove(self.PlayerData.PlayerList, 1)
        -- end
        --检测是否过期
        if temp.Validity < 0 then
            head = temp
        else
            local validity = temp.Validity + temp.AddTime
            if validity > self.Time then
                head = temp
            end
        end
    end

    --如果找不到合适的动画
    if not head then
        return
    end

    head.StartTime = self.Time

    self.PlayerData.PlayingElement = head
    self.Status = PlayerState.PLAYING
    self.PlayerData.LastPlayTime = head.StartTime + head.Duration

    if isRecord then
        -- 记录播放过的动作
        XDataCenter.SignBoardManager.RecordSignBoard(head.SignBoardConfig)
    end

    self.PlayUi:Play(head)

    if self.PlayOne then
        -- 清空播放列表，只播放当前权重最高的动画(head)
        self.PlayerData.PlayerList = {}
    end
end

--停止
function XSignBoardPlayer:Stop()
    if self.PlayerData.PlayingElement == nil then
        return
    end

    self.PlayerData.PlayedList[self.PlayerData.PlayingElement.Id] = XTime.GetServerNowTimestamp() + self.PlayerData.PlayingElement.CoolTime
    self.PlayUi:OnStop(self.PlayerData.PlayingElement)
    self.PlayerData.PlayingElement = nil
    self.Status = PlayerState.IDLE
    self.LastPlayTime = XTime.GetServerNowTimestamp()
end

--暂停
function XSignBoardPlayer:Pause()
    self.Status = PlayerState.PAUSE
end

function XSignBoardPlayer:Freeze()
    self.Status = PlayerState.STOP
end

function XSignBoardPlayer:Resume()
    self.LastPlayTime = XTime.GetServerNowTimestamp()
    self.Status = PlayerState.IDLE
end

--更新
function XSignBoardPlayer:Update(deltaTime)
    self.Time = self.Time + deltaTime

    if self.Time < self.DelayStart then
        return
    end

    if not self:IsActive() then
        return
    end

    if (not self.PlayerData.PlayerList or #self.PlayerData.PlayerList == 0) and self.PlayerData.PlayingElement == nil then
        return
    end

    if self.Status == PlayerState.STOP then
        return
    end

    if self.Status == PlayerState.PAUSE then
        return
    end

    local nextElementTime = self.PlayerData.LastPlayTime + self.CoolTime

    --存在播放中的动作
    if self.PlayerData.PlayingElement ~= nil and self.PlayerData.PlayingElement.Duration > 0 then
        local deadline = self.PlayerData.PlayingElement.StartTime + self.PlayerData.PlayingElement.Duration
        if deadline < self.Time then
            if self.PlayUi.Parent.SetWhetherPlayChangeActionEffect then
                --动作生命周期正常结束，不用播放打断特效
                self.PlayUi.Parent:SetWhetherPlayChangeActionEffect(false)
            end
            self:SetInterruptDetection(false)
            self:Stop()
            return
        end
    end

    --冷却时间
    if nextElementTime < self.Time and self.Status ~= PlayerState.PLAYING and self.AutoPlay then
        self:PlayNext(true)
    end
end

function XSignBoardPlayer:SetInterruptDetection(boolValue)
    self.IsInInterruptDetection = boolValue
end

function XSignBoardPlayer:GetInterruptDetection()
    return self.IsInInterruptDetection
end

--强制运行
function XSignBoardPlayer:ForcePlay(tab, cvType, isRecord)
    if self.Status == PlayerState.STOP then
        return
    end

    if self:Play(tab, cvType) then
        self:PlayNext(isRecord)
    end
end

function XSignBoardPlayer:IsPlaying()
    return self.Status == PlayerState.PLAYING
end

--设置自动播放
function XSignBoardPlayer:SetAutoPlay(bAutoPlay)
    self.AutoPlay = bAutoPlay
end

-- 播放队列是否只播放权重最高的动画
function XSignBoardPlayer:SetPlayOne(bPlayOne)
    self.PlayOne = bPlayOne
end

---生命周期----------------------------------------------
function XSignBoardPlayer:IsActive()
    return self.Active
end

function XSignBoardPlayer:OnEnable()
    self.Active = true
    self:Resume()
end

function XSignBoardPlayer:OnDisable()
    self.Active = false
    self:Stop()
end

function XSignBoardPlayer:OnDestroy()
    self:Stop()
end

return XSignBoardPlayer