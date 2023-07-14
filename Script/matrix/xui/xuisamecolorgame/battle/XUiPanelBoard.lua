local XUiPanelBoard = XClass(nil, "XUiPanelBoard")
local XUiGridBall = require("XUi/XUiSameColorGame/Battle/XUiGridBall")
local XUiGridPos = require("XUi/XUiSameColorGame/Battle/XUiGridPos")
local CSTextManagerGetText = CS.XTextManager.GetText
local ComboSoundMaxIndex = 4
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local MinSize = 4
local MaxSize = 6
local NoneAniDelayTime = 0
local AniDelayTime = 400
local PrepareTime = 3 -- 限时关卡预备3秒
local Instantiate = CS.UnityEngine.Object.Instantiate
local ShowScoreTime = 600 -- 显示分数item的时间
local RemoveEffectWaitTime = 150
local CsTime = CS.UnityEngine.Time
local ComboEffectInterval = 0.3 -- combo特效播放间隔
local CSXAudioManager = CS.XAudioManager

function XUiPanelBoard:Ctor(ui, base, role, boss)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Role = role
    self.Boss = boss
    XTool.InitUiObject(self)

    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.FinishCountDic = {}
    self.ComboCountText:TextToSprite(0,0)
    self.ComboSoundIndex = 1
    self.OldCombo = 0
    self.OldComboLevel = 0
    self.OldComboTime = 0
    self.ScoreItemDic = {}
    self.PanelCombo.gameObject:SetActiveEx(false)
    self.ScoreItem.gameObject:SetActiveEx(false)
    self.BoardMask.gameObject:SetActiveEx(false)
    self.TextCountDown.gameObject:SetActiveEx(false)
    self:InitEffect()
    self:InitPos()
end

function XUiPanelBoard:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.ShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.ShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAPINIT, self.InitBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLREMOVE, self.RemoveBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLDROP, self.DropBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLADD, self.AddBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.ShuffleBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLSWAP, self.SwapBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALLCHANGECOLOR, self.ChangeBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.CloseCombo, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAPRESET, self.ResetBall, self)
end

function XUiPanelBoard:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.ShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.ShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAPINIT, self.InitBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLREMOVE, self.RemoveBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLDROP, self.DropBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLADD, self.AddBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.ShuffleBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLSWAP, self.SwapBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALLCHANGECOLOR, self.ChangeBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER, self.CloseCombo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAPRESET, self.ResetBall, self)
end

function XUiPanelBoard:OnDisable()
    self:StopBallTween()
    self:ClearCountDown()
    self:ClearScoreTimer()
    self:ClearRefreshGridTimer()
    self:ClearSelectEffectTimer()
end

local GetTruePos = function(row, col, IsMiniRow, IsMiniCol, MaxSize)
    local IsNotUse = (IsMiniRow and (row == 1 or row == MaxSize)) or (IsMiniCol and (col == 1 or col == MaxSize))
    local trueCol = IsMiniCol and col - 1 or col
    local trueRow = IsMiniRow and row - 1 or row

    return (not IsNotUse) and trueRow, trueCol
end

function XUiPanelBoard:InitEffect()
    self.EffectCombo = {
        self.EffectComboW,
        self.EffectComboY,
        self.EffectComboR,
        }
    self.EffectComboR.gameObject:SetActiveEx(false)
    self.EffectComboW.gameObject:SetActiveEx(false)
    self.EffectComboY.gameObject:SetActiveEx(false)
end

function XUiPanelBoard:InitPos()
    self.GridPosDic = {}
    self.GridBallList = {}
    self.GridPos.gameObject:SetActiveEx(false)
    self.GridBall.gameObject:SetActiveEx(false)

    local boardRow = self.Role:GetRow()
    local boardCol = self.Role:GetCol()
    local IsMiniRow = boardRow < MaxSize
    local IsMiniCol = boardCol < MaxSize

    for row = 1 , MaxSize do
        for col = 1 , MaxSize do
            ----------------正位初始化------------------------
            local trueRow, trueCol = GetTruePos(row, col, IsMiniRow, IsMiniCol, MaxSize)
            local posKey = XSameColorGameConfigs.CreatePosKey(trueCol, trueRow)
            local obj = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelPosParent)
            obj.gameObject.name = string.format("Pos%s", posKey)
            obj.gameObject:SetActiveEx(true)
            local posX = self.GridPos.sizeDelta.x * ((col - 1) - (MaxSize / 2 - 0.5))
            local posY = self.GridPos.sizeDelta.y * ((MaxSize / 2 - 0.5) - (row - 1))
            obj.transform.localPosition = Vector3(posX, posY, 0)
            local gridPos = XUiGridPos.New(obj, trueRow, trueCol)
            gridPos:ShowGrid(posKey)
            if posKey then
                self.GridPosDic[posKey] = gridPos
                ----------逆位初始化------------------------------
                local subPosKey = XSameColorGameConfigs.CreatePosKey(trueCol, -trueRow)
                local subPosObj = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelPosParent)
                subPosObj.gameObject.name = string.format("Pos%s", subPosKey)
                subPosObj.gameObject:SetActiveEx(false)
                local subGridPos = XUiGridPos.New(subPosObj, -trueRow, trueCol)
                local tmpPos = gridPos.Transform.localPosition
                local offset = (gridPos.Row * 2 - 1) * (self.GridPos.sizeDelta.y)
                subGridPos.Transform.localPosition = Vector3(tmpPos.x , tmpPos.y + offset, tmpPos.z)
                self.GridPosDic[subPosKey] = subGridPos
                ----------------球初始化---------------------
                local ballObj = CS.UnityEngine.Object.Instantiate(self.GridBall, self.PanelBallParent)
                ballObj.gameObject:SetActiveEx(true)
                table.insert(self.GridBallList, XUiGridBall.New(ballObj, self))
            end

        end
    end

    self.PanelBallParent.sizeDelta = Vector2(boardCol * self.GridPos.sizeDelta.x ,boardRow * self.GridPos.sizeDelta.y)
end

function XUiPanelBoard:ShowCombo(count)
    local comboLevel = self.BattleManager:GetBattleComboLevel(count)
    self.ComboCountText:TextToSprite(count,comboLevel - 1)
    self.ComboTitle:TextToSprite("c",comboLevel - 1)
    
    if count > 1 then
        self.PanelCombo.gameObject:SetActiveEx(true)
        self.ComboCountText.gameObject:SetActiveEx(true)
        self.ComboTitle.gameObject:SetActiveEx(true)
        self.Base:PlayAnimation("ComboTextEnable")
        self:ShowComboEffect(comboLevel)
    end

    if self.OldCombo < count and count > 1 then
        self.ComboSoundIndex = self.ComboSoundIndex < ComboSoundMaxIndex and self.ComboSoundIndex + 1 or ComboSoundMaxIndex
    else
        self.ComboSoundIndex = 1
    end
    self.OldCombo = count
    self.Base:PlayGameSound(string.format("Remove%d",self.ComboSoundIndex))
end

function XUiPanelBoard:CloseCombo()
    if self.OldCombo <= 1 then
        return
    end

    self.Base:PlayAnimation("ComboTextDisable", function ()
        self.ComboCountText.gameObject:SetActiveEx(false)
        self.ComboTitle.gameObject:SetActiveEx(false)
    end)
    self.ComboFlagDic = {}
    self.OldCombo = 0
end

function XUiPanelBoard:ShowBallEffect()
    for _,ball in pairs(self.GridBallList or {}) do
        ball:SelectEffect()
    end
end

function XUiPanelBoard:ShowComboEffect(comboLevel)
    local now = CsTime.realtimeSinceStartup
    if self.OldComboLevel == comboLevel and (now - self.OldComboTime < ComboEffectInterval) then
        return
    end

    self.OldComboLevel = comboLevel
    self.OldComboTime = now
    for index, effect in pairs(self.EffectCombo or {}) do
        effect.gameObject:SetActiveEx(false)
        effect.gameObject:SetActiveEx(index == comboLevel)
    end
end

-----------------------------------------BallEvent-------------------------------------------------
function XUiPanelBoard:InitBall(data)
    self.BallCount = {}
    local ballList = data.BallList
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self.GridBallList[index]
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:SelectEffect()
            local posKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
            local gridPos = self.GridPosDic[posKey]
            gridBall:EqualPosToGridPos(gridPos)
        end
    end

    if self.Boss:IsTimeType() then
        self:OpenCountDown()
    end
    self.BattleManager:DoActionFinish(data.ActionType)
end

function XUiPanelBoard:RemoveBall(data)
    local ballList = data.RemoveBallList
    local gridBallList = {}

    local time = NoneAniDelayTime
    local aniBallList = {}

    local animNotMask = false -- 动画是否不阻塞流程
    local preSkill = self.BattleManager:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        if XSameColorGameConfigs.AnimNotMaskSkill[skillId] then
            animNotMask = true
        end
    end

    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        table.insert(gridBallList, gridBall)
        -- 收集具有特殊移除动画的球
        if ballData.ItemType ~= XSameColorGameConfigs.BallRemoveType.None then
            if XTool.IsTableEmpty(aniBallList[ballData.ItemType]) then
                aniBallList[ballData.ItemType] = {}
            end
            table.insert(aniBallList[ballData.ItemType], gridBall)
        end
    end
    
    if not XTool.IsTableEmpty(aniBallList) then
        time = AniDelayTime
        self:DoAniBeforeRemoveBall(aniBallList)
    end
    XScheduleManager.ScheduleOnce(function()
        self:DoRemoveBall(data, gridBallList, ballList, animNotMask)
    end, time)

    -- 计算消球列表位于最中心的球
    local centerItem = nil
    local centerLength = nil -- 距离其他球的总距离
    for _, item in ipairs(ballList) do
        local length = 0
        for _, item2 in ipairs(ballList) do
            if item ~= item2 then
                length = length + math.abs(item2.PositionX - item.PositionX) + math.abs(item2.PositionY - item.PositionY)
            end
        end
        if centerLength == nil or length <= centerLength then
            centerItem = item
            centerLength = length
        end
    end
    local localPos = self:GetBallGridPosition(centerItem.PositionX, centerItem.PositionY)

    -- 显示消除分数
    local scoreItem = self:GetScoreItem()
    scoreItem.transform.localPosition = Vector3(localPos.x, localPos.y, 0)
    scoreItem:TextToSprite(tostring(data.CurrentScore), 0)

    -- 消球音效
    --CSXAudioManager.PlaySound(XSameColorGameConfigs.Sound.RemoveBall)

    -- 动画不阻塞流程
    if animNotMask then 
        self.BattleManager:DoActionFinish(data.ActionType)
    end
end

function XUiPanelBoard:DropBall(data)
    local dropBallList = data.DropBallList
    local ballData = {}
    for _,dropBall in pairs(dropBallList or {}) do
        local tmepBall = {StartX = dropBall.StartPositionX, StartY = dropBall.StartPositionY,
            EndX = dropBall.EndPositionX, EndY = dropBall.EndPositionY}
        table.insert(ballData, tmepBall)
    end

    self:MoveBall(ballData, "DropBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:AddBall(data)
    local addBallList = data.AddBallList
    local ballData = {}

    for _,dropBall in pairs(addBallList or {}) do
        if self.BallCount[dropBall.PositionX] then
            local tmepBall = {ItemId = dropBall.ItemId, StartX = dropBall.PositionX, StartY = (dropBall.PositionY - self.BallCount[dropBall.PositionX] - 1),
                EndX = dropBall.PositionX, EndY = dropBall.PositionY}
            table.insert(ballData, tmepBall)
        end
    end
    self.BallCount = {}
    self:SetBallId(ballData)
    self:MoveBall(ballData, "AddBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:SwapBall(data)
    local ballList = {}
    ballList[1] = {StartX = data.SourceBall.PositionX, StartY = data.SourceBall.PositionY,
        EndX = data.DestinationBall.PositionX, EndY = data.DestinationBall.PositionY}

    ballList[2] = {StartX = data.DestinationBall.PositionX, StartY = data.DestinationBall.PositionY,
        EndX = data.SourceBall.PositionX, EndY = data.SourceBall.PositionY}
    self:MoveBall(ballList, "SwapBall", function ()
            self.BattleManager:DoActionFinish(data.ActionType)
        end)
end

function XUiPanelBoard:ChangeBall(data, isPlayQieHuanAnim)
    for _, gridBall in pairs(self.GridBallList) do
        gridBall:CloseEffect()
        if isPlayQieHuanAnim then 
            gridBall:PlayQieHuanAnim()
        end
    end

    -- 播切换动画时
    local ballList = data.BallList
    if isPlayQieHuanAnim then
        -- 延迟刷新球
        self:ClearRefreshGridTimer()
        self.RefreshGridTimer = XScheduleManager.ScheduleOnce(function()
            self:RefreshBallList(ballList)
            self.RefreshGridTimer = nil
        end, 300)

        -- 刷新特效
        self:ClearSelectEffectTimer()
        self.SelectEffectTimer = XScheduleManager.ScheduleOnce(function()
            self:RefreshBallListEffect(ballList)
            self.SelectEffectTimer = nil
            self.BattleManager:DoActionFinish(data.ActionType)
        end, 400)
    else
        self:RefreshBallList(ballList)
        self:RefreshBallListEffect(ballList)
        self.BattleManager:DoActionFinish(data.ActionType)
    end
end

function XUiPanelBoard:ClearRefreshGridTimer()
    if self.RefreshGridTimer then 
        XScheduleManager.UnSchedule(self.RefreshGridTimer)
        self.RefreshGridTimer = nil
    end
end

function XUiPanelBoard:ClearSelectEffectTimer()
    if self.SelectEffectTimer then
        XScheduleManager.UnSchedule(self.SelectEffectTimer)
        self.SelectEffectTimer = nil
    end
end

function XUiPanelBoard:RefreshBallList(ballList)
    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        if not gridBall then 
            gridBall = self:GetBallFromRecycleBall(ballData.PositionX, ballData.PositionY)
        end
        gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
    end
end

function XUiPanelBoard:RefreshBallListEffect(ballList)
    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        if not gridBall then 
            gridBall = self:GetBallFromRecycleBall(ballData.PositionX, ballData.PositionY)
        end
        local ballId = gridBall:GetBallId()
        local showSelectEffect = XSameColorGameConfigs.ShowSelectEffectBall[ballId]
        if showSelectEffect then
            gridBall:ShowSelect(true)
        end

        gridBall:SelectEffect()
    end
end

function XUiPanelBoard:ResetBall(data)
    self:ChangeBall(data, true)
end

function XUiPanelBoard:ShuffleBall(data)
    self:InitBall(data)
    XUiManager.TipText("SameColorGameShuffleBallHint")
end

-----------------------------------------------------------------------------------------------------------
function XUiPanelBoard:GetBallGrid(x, y)
    for _,ball in pairs(self.GridBallList or {}) do
        local position = ball:GetPositionIndex()
        if position.x == x and position.y == y then
            return ball
        end
    end
    return
end

-- 从回收的球里取
-- 触发消球但是不落球的技能结束之后，刷新球，取不到对应位置的球，从回收的球里取
function XUiPanelBoard:GetBallFromRecycleBall(x, y)
    if self.BallCount[x] then
        local posY = -self.BallCount[x]
        self.BallCount[x] = self.BallCount[x] - 1
        local gridBall = self:GetBallGrid(x, posY)
        local tagPosKey = XSameColorGameConfigs.CreatePosKey(x, y)
        local tagGridPos = self.GridPosDic[tagPosKey]
        gridBall:EqualPosToGridPos(tagGridPos)
        return gridBall
    end
    return
end

function XUiPanelBoard:SetBallId(ballList)
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.StartX, ballData.StartY)
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:SelectEffect()
        end
    end

end

function XUiPanelBoard:GetBallGridPosition(x, y)
    local tagPosKey = XSameColorGameConfigs.CreatePosKey(x, y)
    local tagGridPos = self.GridPosDic[tagPosKey]
    if tagGridPos then
        return tagGridPos.Transform.localPosition
    end
end

-- 能交换但不同球(服务端不能发送同色邻球交换)
function XUiPanelBoard:IsCanRequset(ball)
    if self.SelectedBall and self.SelectedBall ~= ball then
        local startPos = {PositionX = self.SelectedBall.Col, PositionY = self.SelectedBall.Row}
        local endPos = {PositionX = ball.Col, PositionY = ball.Row}
        return XSameColorGameConfigs.CheckPosIsAdjoin(startPos, endPos) and self.SelectedBall:GetBallId() ~= ball:GetBallId(), startPos, endPos
    else
        return false
    end
end

-- 能交换且是同球交换
function XUiPanelBoard:IsCanRequsetButSameBall(ball)
    if self.SelectedBall and self.SelectedBall ~= ball then
        local startPos = {PositionX = self.SelectedBall.Col, PositionY = self.SelectedBall.Row}
        local endPos = {PositionX = ball.Col, PositionY = ball.Row}
        return XSameColorGameConfigs.CheckPosIsAdjoin(startPos, endPos) and self.SelectedBall:GetBallId() == ball:GetBallId()
    else
        return false
    end
end

-- 直接执行三消除球行为
function XUiPanelBoard:DoRemoveBall(data, gridBallList, ballList, animNotMask)
    -- 消除特效
    XScheduleManager.ScheduleOnce(function()
        self:ShowRemoveEffect(ballList)
    end, RemoveEffectWaitTime)

    self:PlayBallWait(gridBallList, "RemoveBall", "Before", function ()
        local combo = self.BattleManager:GetCountCombo()
        self:ShowCombo(combo)

        for _,ballData in pairs(ballList or {}) do
            local removePosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
            local removeGridPos = self.GridPosDic[removePosKey]

            self.BallCount[ballData.PositionX] = self.BallCount[ballData.PositionX] and self.BallCount[ballData.PositionX] + 1 or 1
            local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
            local tagPosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, -self.BallCount[ballData.PositionX])
            local tagGridPos = self.GridPosDic[tagPosKey]
            gridBall:CloseEffect()
            gridBall:EqualPosToGridPos(tagGridPos)
        end

        local cb = not animNotMask and function()
            self.BattleManager:DoActionFinish(data.ActionType)
        end
        self:PlayBallWait(gridBallList, "RemoveBall", "After", cb)
    end)
end

-- 显示消球移除特效
function XUiPanelBoard:ShowRemoveEffect(ballList)
    for _,ballData in pairs(ballList or {}) do
        local removePosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
        local removeGridPos = self.GridPosDic[removePosKey]
        removeGridPos:ShowRemoveEffect()
    end
end

-- 移除球前播放动画
function XUiPanelBoard:DoAniBeforeRemoveBall(aniBallList)
    for removeType, ballList in ipairs(aniBallList) do
        for _, ball in ipairs(ballList) do
            ball:PlayAniByRemoveType(removeType)
        end
    end
end

function XUiPanelBoard:MoveBall(ballList, countKey, cb)
    self.FinishCountDic[countKey] = 0

    if ballList and next(ballList) then
        for index,ballData in pairs(ballList) do
            local ball = self:GetBallGrid(ballData.StartX, ballData.StartY)
            local posKey = XSameColorGameConfigs.CreatePosKey(ballData.EndX, ballData.EndY)
            local gridPos = self.GridPosDic[posKey]
            ball:MoveToGridPos(gridPos, function ()
                    self:CheckFinishCount(#ballList, countKey, cb)
                end)
        end
    else
        self:CheckFinishCount(0, countKey, cb)
    end

end

function XUiPanelBoard:PlayBallWait(gridballList, countKey, waitName, cb)
    self.FinishCountDic[countKey] = 0

    if gridballList and next(gridballList) then
        for index,gridBall in pairs(gridballList) do
            gridBall:PlayWait(waitName, function ()
                    self:CheckFinishCount(#gridballList, countKey, cb)
                end)
        end
    else
        self:CheckFinishCount(0, countKey, cb)
    end

end

-- v1.31 检查球周围四个方向是否有球
function XUiPanelBoard:CheckAroundSideIsHaveBall(ball)
    local x = ball.Col
    local y = ball.Row
    local isHaveLeftBall = self:GetBallGrid(x - 1, y)
    local isHaveRightBall = self:GetBallGrid(x + 1, y)
    local isHaveUpBall = self:GetBallGrid(x, y - 1)
    local isHaveDownBall = self:GetBallGrid(x, y + 1)
    return isHaveLeftBall, isHaveRightBall, isHaveUpBall, isHaveDownBall
end

-- v1.31 按下手指选择球
function XUiPanelBoard:DoStartSelectBall(ball)
    local prepSkill = self.BattleManager:GetPrepSkill()
    if not prepSkill then
        self:StartSelectBall(ball)
    end
end

function XUiPanelBoard:StartSelectBall(ball)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        if self.SelectedBall ~= ball then
            if self:IsCanRequsetButSameBall(ball) then
                self:DoMoveSameBall(self.SelectedBall, ball)
                self:CancelSelectBall()
            else
                self.SelectedBall:ShowSelect(false)
                self.SelectedBall = ball
                ball:ShowSelect(true)
            end
        end
    end
end

function XUiPanelBoard:CancelSelectBall()
    if self.SelectedBall then
        self.SelectedBall:ShowSelect(false)
        self.SelectedBall = nil
    end
end

function XUiPanelBoard:IsBallSelect(ball)
    if self.SelectedBall then
        return self.SelectedBall == ball
    else
        return false
    end
end

-- v1.31 一样的球交换
function XUiPanelBoard:DoMoveSameBall(ball, targetBall)
    local ballList = {}
    local swapBackList = {}
    ballList[1] = {StartX = ball.Col, StartY = ball.Row,
        EndX = targetBall.Col, EndY = targetBall.Row}
    ballList[2] = {StartX = targetBall.Col, StartY = targetBall.Row,
        EndX = ball.Col, EndY = ball.Row}
    swapBackList[1] = ballList[2]
    swapBackList[2] = ballList[1]
    XLuaUiManager.SetMask(true)
    self:MoveBall(ballList, "SwapBall", function ()
        self:MoveBall(swapBackList, "SwapBall", function ()
            XLuaUiManager.SetMask(false)
        end)
    end)
end

-- v1.31 抬起手指选择球
function XUiPanelBoard:DoSelectBall(ball)
    local prepSkill = self.BattleManager:GetPrepSkill()

    if not prepSkill then
        self:NormalSelect(ball)
    else
        self:SkillSelect(ball, prepSkill)
    end
end

function XUiPanelBoard:NormalSelect(ball)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local IsCanRequset = true
        if self.SelectedBall ~= ball then
            --CSXAudioManager.PlaySound(XSameColorGameConfigs.Sound.SwapBall)
            local startPos, endPos
            IsCanRequset, startPos, endPos = self:IsCanRequset(ball)
            if IsCanRequset then
                XDataCenter.SameColorActivityManager.RequestSwapBall(startPos, endPos, function ()
                        self.BattleManager:CheckActionList()
                    end)
            else
                if self:IsCanRequsetButSameBall(ball) then
                    self:DoMoveSameBall(self.SelectedBall, ball)
                    self:CancelSelectBall()
                else
                    self.SelectedBall:ShowSelect(false)
                    self.SelectedBall = ball
                    ball:ShowSelect(true)
                end
            end
        end

        if IsCanRequset then
            self.SelectedBall:ShowSelect(false)
            self.SelectedBall = nil
        end
    end
end

function XUiPanelBoard:SkillSelect(ball, prepSkill)
    local skillId = prepSkill:GetSkillId()
    local skillGroupId = prepSkill:GetSkillGroupId()
    if prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickBall then
        self:DoOneBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickTwoBall then
        self:DoTwoBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XSameColorGameConfigs.ControlType.ClickPopup then
        self:DoPopUpSkill(ball, skillGroupId, skillId)
    end
end

function XUiPanelBoard:DoOneBallSkill(ball, skillGroupId, skillId)
    local ball_1 = {
        ItemId = ball:GetBallId(),
        PositionX = ball.Col,
        PositionY = ball.Row
    }
    local useItemParam = {Item1 = ball_1, Item2 = {}}
    local cb

    -- 是否作为开启技能
    local prepSkill = self.BattleManager:GetPrepSkill()
    local isOpenSkill = XSameColorGameConfigs.NeedOpenSkill[skillId] and prepSkill:GetUsedCount() == 0
    if isOpenSkill then
        useItemParam = nil
        cb = function()
            -- 关闭技能描述
            XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_CLOSE_BLACKSCENE_TIPS)
        end
    end
    
    XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, useItemParam, cb)
end

function XUiPanelBoard:DoTwoBallSkill(ball, skillGroupId, skillId)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local ball_1 = {
            ItemId = self.SelectedBall:GetBallId(),
            PositionX = self.SelectedBall.Col,
            PositionY = self.SelectedBall.Row
        }
        local ball_2 = {
            ItemId = ball:GetBallId(),
            PositionX = ball.Col,
            PositionY = ball.Row
        }
        if self.SelectedBall ~= ball then
            XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = ball_2})
        end
        self.SelectedBall:ShowSelect(false)
        self.SelectedBall = nil
    end
end

function XUiPanelBoard:DoPopUpSkill(selectBall, skillGroupId, skillId)
    local ball_1 = {
        ItemId = selectBall:GetBallId(),
        PositionX = selectBall.Col,
        PositionY = selectBall.Row
    }
    XLuaUiManager.Open("UiSameColorGameChangeColor", self.Role,
        CSTextManagerGetText("SameColorGameColorSelect"),
        function (ball)
            return ball:GetBallId() ~= selectBall:GetBallId()
        end,
        nil,
        function (ball_2, cb)
            XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = ball_2}, cb)
        end)
end

function XUiPanelBoard:UnSelectBall()
    for _,gridBall in pairs(self.GridBallList or {}) do
        gridBall:ShowSelect(false)
    end
    self.SelectedBall = nil
end

function XUiPanelBoard:StopBallTween()
    local IsHasTimer = false
    for _,ball in pairs(self.GridBallList or {}) do
        if ball:StopTween() then
            IsHasTimer = true
        end
    end
end

function XUiPanelBoard:CheckFinishCount(maxCount, key, cb)
    self.FinishCountDic[key] = self.FinishCountDic[key] + 1
    if self.FinishCountDic[key] >= maxCount then
        if cb then cb() end
    end
end

-- 打开倒计时
function XUiPanelBoard:OpenCountDown()
    self:ClearCountDown()

    self.Base:ShowBossAtkMask(true)
    self.CountDown = PrepareTime
    self.BoardMask.gameObject:SetActiveEx(true)
    self.TextCountDown.gameObject:SetActiveEx(true)
    self.TextCountDown:TextToSprite(self.CountDown, 0)
    self.CountDownTimer = XScheduleManager.ScheduleForever(function()
        self.CountDown = self.CountDown - 1
        if self.CountDown > 0 then
            self.TextCountDown:TextToSprite(self.CountDown, 0)
        else
            XDataCenter.SameColorActivityManager.RequestCountDown()
            self:ClearCountDown()
        end
    end, XScheduleManager.SECOND)
end

-- 清除倒计时
function XUiPanelBoard:ClearCountDown()
    if self.CountDownTimer then
        self.Base:ShowBossAtkMask(false)
        XScheduleManager.UnSchedule(self.CountDownTimer)
        self.CountDownTimer = nil
        self.BoardMask.gameObject:SetActiveEx(false)
        self.TextCountDown.gameObject:SetActiveEx(false)
    end
end

-- 获取一个消除分数item
function XUiPanelBoard:GetScoreItem()
    local scoreItem
    for item, timerId in pairs(self.ScoreItemDic) do
        local canUse = timerId == 0
        if canUse then
            scoreItem = item
            break
        end
    end
    if not scoreItem then
        local go = Instantiate(self.ScoreItem, self.PanelScore)
        scoreItem = go:GetComponent("XUiSpriteText")
    end

    scoreItem.transform.gameObject:SetActiveEx(true)
    self.ScoreItemDic[scoreItem] = XScheduleManager.ScheduleOnce(function()
        self:RecycleScoreItem(scoreItem)
    end, ShowScoreTime)
    return scoreItem
end

-- 回收一个消除分数item
function XUiPanelBoard:RecycleScoreItem(scoreItem)
    self.ScoreItemDic[scoreItem] = 0
    scoreItem.transform.gameObject:SetActiveEx(false)
end

-- 清除所有分数Item的定时器
function XUiPanelBoard:ClearScoreTimer()
    for item, timerId in pairs(self.ScoreItemDic) do
        XScheduleManager.UnSchedule(timerId)
        self.ScoreItemDic[item] = 0
    end
end

return XUiPanelBoard