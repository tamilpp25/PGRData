---@class XSignBoardPlayer
local XSignBoardPlayer = {}

local PlayerState = {
    IDLE = 0,
    PLAYING = 1,
    CHANGING = 2,
    PAUSE = 3,
    STOP = 4
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
    self:SetStatus(PlayerState.IDLE)
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

-- 是否将互动事件加入到播放列表中
-- 看板界面播放动作都由玩家自主点击 不需要自动播互动事件
-- 如果不处理 那么当玩家长时间未登录 且助理没有【长时间未登录】这个动作时（比如露西亚） 进入看板界面 第一次点击任意动作 都会是【长时间未登录】
function XSignBoardPlayer:IgnoreInteractionAnim()
    self._IgnoreInteractionAnim = true
end

--设置（互动事件）播放队列
function XSignBoardPlayer:SetPlayList(playList, isClear)
    if self._IgnoreInteractionAnim then
        return
    end
    if not playList or #playList <= 0 then
        if isClear then
            self.PlayerData.PlayerList = {}
        end
        return
    end
    self.PlayerData.PlayerList = {}
    self.PlayerData.LastPlayTime = -1
    self.DelayStart = self.Time + self.Delay

    for _, element in ipairs(playList) do
        table.insert(self.PlayerData.PlayerList, element)
    end
end

--清空播放队列
function XSignBoardPlayer:ClearPlayList()
    if not self.PlayerData then
        return
    end
    self.PlayerData.PlayerList = {}
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
    local defaultCvType = 1
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
    --只播放权重最高的动画模式，同权限动画，只随机播放其中一个
    if self.PlayOne then
        local highestWeight = 0
        local randomList = {}
        for index, element in ipairs(self.PlayerData.PlayerList) do
            if element.Weight > highestWeight and self:CheckAnimValidity(element) then
                highestWeight = element.Weight --记录最高权重
            end
        end
        for index, element in ipairs(self.PlayerData.PlayerList) do
            if element.Weight == highestWeight and self:CheckAnimValidity(element) then
                table.insert(randomList,element)
            end
        end
        if #randomList > 0 then
            local index = math.random(1, #randomList)
            head = randomList[index]
        end
    else --顺序播放动画
        while #self.PlayerData.PlayerList > 0 and not head do

            local element = table.remove(self.PlayerData.PlayerList, 1)
            -- local lastPlayTime = self.PlayerData.PlayedList[temp.Id]
            -- --如果还在冷却中
            -- if lastPlayTime and self.Time < lastPlayTime then
            --     if #self.PlayerData.PlayerList <= 0 then
            --         break
            --     end
            --     temp = table.remove(self.PlayerData.PlayerList, 1)
            -- end
            --检测是否过期
            if self:CheckAnimValidity(element) then
                head = element
            end
        end
    end
    

    --如果找不到合适的动画
    if not head then
        return
    end

    head.StartTime = self.Time

    self.PlayerData.PlayingElement = head
    self:SetStatus(PlayerState.PLAYING)
    self.PlayerData.LastPlayTime = head.StartTime + head.Duration

    if isRecord then
        -- 记录播放过的动作
        XMVCA.XFavorability:RecordSignBoard(head.SignBoardConfig)
    end

    self.PlayUi:Play(head)
    self:PlayActionAnim(head)

    if self.PlayOne then
        -- 清空播放列表，只播放当前权重最高的动画(head)
        self.PlayerData.PlayerList = {}
    end
end

function XSignBoardPlayer:PlayNextCross(isRecord)
    if not self:IsActive() then
        return
    end

    if not self.PlayerData.PlayerList or #self.PlayerData.PlayerList == 0 then
        return
    end

    --获取第一个在有限期之类的动画
    local head = nil
    --只播放权重最高的动画模式，同权限动画，只随机播放其中一个
    if self.PlayOne then
        local highestWeight = 0
        local randomList = {}
        for index, element in ipairs(self.PlayerData.PlayerList) do
            if element.Weight > highestWeight and self:CheckAnimValidity(element) then
                highestWeight = element.Weight --记录最高权重
            end
        end
        for index, element in ipairs(self.PlayerData.PlayerList) do
            if element.Weight == highestWeight and self:CheckAnimValidity(element) then
                table.insert(randomList,element)
            end
        end
        if #randomList > 0 then
            local index = math.random(1, #randomList)
            head = randomList[index]
        end
    else --顺序播放动画
        while #self.PlayerData.PlayerList > 0 and not head do

            local element = table.remove(self.PlayerData.PlayerList, 1)
            -- local lastPlayTime = self.PlayerData.PlayedList[temp.Id]
            -- --如果还在冷却中
            -- if lastPlayTime and self.Time < lastPlayTime then
            --     if #self.PlayerData.PlayerList <= 0 then
            --         break
            --     end
            --     temp = table.remove(self.PlayerData.PlayerList, 1)
            -- end
            --检测是否过期
            if self:CheckAnimValidity(element) then
                head = element
            end
        end
    end

    --如果找不到合适的动画
    if not head then
        return
    end

    head.StartTime = self.Time

    self.PlayerData.PlayingElement = head
    self:SetStatus(PlayerState.PLAYING)
    self.PlayerData.LastPlayTime = head.StartTime + head.Duration

    if isRecord then
        -- 记录播放过的动作
        XMVCA.XFavorability:RecordSignBoard(head.SignBoardConfig)
    end

    self.PlayUi:PlayCross(head)
    self:PlayActionAnim(head)

    if self.PlayOne then
        -- 清空播放列表，只播放当前权重最高的动画(head)
        self.PlayerData.PlayerList = {}
    end
end

--检查动画是否过期(时效性)
function XSignBoardPlayer:CheckAnimValidity(Element)
    if Element.Validity < 0 then
        return true
    else
        local validity = Element.Validity + Element.AddTime
        if validity > self.Time then
            return true
        end
    end
    return false
end

--停止
function XSignBoardPlayer:Stop(force, isForceStop)
    if self.PlayerData.PlayingElement == nil then
        if isForceStop then
            self.PlayUi:OnStop(self.PlayerData.PlayingElement, force)
        end
        return
    end
    self.PlayerData.PlayedList[self.PlayerData.PlayingElement.Id] = XTime.GetServerNowTimestamp() + self.PlayerData.PlayingElement.CoolTime
    self:SetStatus(PlayerState.IDLE)
    self.PlayUi:OnStop(self.PlayerData.PlayingElement, force)
    self:StopActionAnim()
    self.PlayerData.PlayingElement = nil
    self.LastPlayTime = XTime.GetServerNowTimestamp()
end

--暂停
function XSignBoardPlayer:Pause()
    self:SetStatus(PlayerState.PAUSE)
    self:PauseActionAnim()
end

function XSignBoardPlayer:Freeze()
    self:SetStatus(PlayerState.STOP)
    self:PauseActionAnim()
end

function XSignBoardPlayer:Resume()
    self.LastPlayTime = XTime.GetServerNowTimestamp()
    local status = self.PlayerData.PlayingElement == nil and PlayerState.IDLE or PlayerState.PLAYING
    self:SetStatus(status)
    self:ResumeActionAnim()
end

--更新
function XSignBoardPlayer:Update(deltaTime)
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

    self.Time = self.Time + deltaTime

    if self.Time < self.DelayStart then
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

    --冷却时间(打脸弹窗时不播放)
    if nextElementTime < self.Time and self.Status ~= PlayerState.PLAYING and self.AutoPlay and XDataCenter.AutoWindowManager.CheckCanPlayActionByAutoWindow() 
    and XMVCA.XUiMain:CheckCanPlayActionByMainUi() and not XDataCenter.FunctionEventManager.IsPlaying() then
        self:PlayNextCross(true)
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

function XSignBoardPlayer:ForcePlayCross(tab, cvType, isRecord)
    if self.Status == PlayerState.STOP then
        return
    end

    if self:Play(tab, cvType) then
        self:PlayNextCross(isRecord)
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
    self:ClearPlayList()
end

function XSignBoardPlayer:OnDestroy()
    self:Stop()
end

-- v1.32 角色特殊动作
--===================================================================

-- 当前播放的动作是否有特殊场景动画
function XSignBoardPlayer:IsPlayingElementHaveSceneAnim()
    if self.PlayerData.PlayingElement == nil then
        return false
    end
    return XMVCA.XFavorability:CheckIsHaveSceneAnim(self.PlayerData.PlayingElement.SignBoardConfig.Id)
end

-- 当前播放的动作是否有特殊Ui动画
function XSignBoardPlayer:IsPlayingElementHaveUiAnim()
    if self.PlayerData.PlayingElement == nil then
        return false
    end
    return XMVCA.XFavorability:CheckIsShowHideUi(self.PlayerData.PlayingElement.SignBoardConfig.Id)
end

-- 开始播放
function XSignBoardPlayer:PlayActionAnim(head)
    -- Ui动画
    if XMVCA.XFavorability:CheckIsShowHideUi(head.SignBoardConfig.Id) then
        if self.PlayUi.PlayUiAnim then
            self.PlayUi:PlayUiAnim()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_ROLE_ACTION_UIANIM_START, head.SignBoardConfig.Id, head.Duration)
    end
    -- 镜头动画
    if XMVCA.XFavorability:CheckIsHaveSceneAnim(head.SignBoardConfig.Id) and self.PlayUi.PlaySceneAnim then
        self.PlayUi:PlaySceneAnim(head)
    else -- 避免本次播放没有镜头动画而上个动作有镜头动画且其处于被打断暂停状态时的镜头残留
        XMVCA.XFavorability:SceneAnimStop()
    end
end

function XSignBoardPlayer:PauseActionAnim()
    if self:IsPlayingElementHaveSceneAnim() then
        XMVCA.XFavorability:SceneAnimPause()
    end
end

function XSignBoardPlayer:ResumeActionAnim()
    if self:IsPlayingElementHaveSceneAnim() then
        XMVCA.XFavorability:SceneAnimResume()
    end
end

-- 结束播放
function XSignBoardPlayer:StopActionAnim()
    -- Ui动画处理
    if self:IsPlayingElementHaveUiAnim() then
        local signBoardid = self.PlayerData.PlayingElement ~= nil and self.PlayerData.PlayingElement.SignBoardConfig.Id
        XEventManager.DispatchEvent(XEventId.EVENT_ROLE_ACTION_UIANIM_END, signBoardid)
    end
    if self:IsPlayingElementHaveSceneAnim() then
        XMVCA.XFavorability:SceneAnimStop()
    end
    -- 取消打断监听
    XMVCA.XFavorability:StopBreakTimer()
end

function XSignBoardPlayer:SetStatus(status)
    self.Status = status
end

--===================================================================

return XSignBoardPlayer