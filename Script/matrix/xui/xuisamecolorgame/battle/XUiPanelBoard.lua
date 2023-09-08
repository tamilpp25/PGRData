local XUiGridBall = require("XUi/XUiSameColorGame/Battle/XUiGridBall")
local XUiGridPos = require("XUi/XUiSameColorGame/Battle/XUiGridPos")

---@class XUiSCBattlePanelBoard:XUiNode
---@field _Control XSameColorControl
---@field ComboCountText XUiSpriteText
---@field ComboTitle XUiSpriteText
---@field TextCountDown XUiSpriteText
local XUiPanelBoard = XClass(XUiNode, "XUiPanelBoard")
local ComboSoundMaxIndex = 4
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local MinSize = 4
local MaxSize = 6
local PrepareTime = 3 -- 限时关卡预备3秒
local ShowScoreTime = 600 -- 显示分数item的时间
local RemoveEffectWaitTime = 150
local CsTime = CS.UnityEngine.Time
local ComboEffectInterval = 0.3 -- combo特效播放间隔
local BallBeforeRemoveAnimTimeDir = {
    [XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE] = 0,
    [XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.BOOM_CENTER] = 400,
}

function XUiPanelBoard:Ctor(ui, base, role, boss)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    ---@type XSCRole
    self.Role = role
    ---@type XSCBoss
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    
    
    self:InitPos()
    self:InitCombo()
    self:InitBallTween()
    self:InitScoreItem()
    self:InitTimeRefresh()
    self:InitSkillEffect()
end

function XUiPanelBoard:OnEnable()
    self:AddEventListener()
end

function XUiPanelBoard:OnDisable()
    self:StopBallTween()
    self:ClearCountDown()
    self:ClearScoreTimer()
    self:ClearRefreshGridTimer()
    self:ClearSelectEffectTimer()
    self:RemoveEventListener()
end

--region Ui - Map
local GetTruePos = function(row, col, isMiniRow, isMiniCol, maxSize)
    local IsNotUse = (isMiniRow and (row == 1 or row == maxSize)) or (isMiniCol and (col == 1 or col == maxSize))
    local trueCol = isMiniCol and col - 1 or col
    local trueRow = isMiniRow and row - 1 or row

    return (not IsNotUse) and trueRow, trueCol
end

function XUiPanelBoard:InitPos()
    ---@type XUiSCBattleGridPos[]
    self.GridPosDic = {}
    ---@type XUiSCBattleGridBall[]
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
            ---@type XUiSCBattleGridPos
            local gridPos = XUiGridPos.New(obj, self, trueRow, trueCol)
            gridPos:ShowGrid(posKey)
            if posKey then
                self.GridPosDic[posKey] = gridPos
                ----------逆位初始化------------------------------
                local subPosKey = XSameColorGameConfigs.CreatePosKey(trueCol, -trueRow)
                local subPosObj = CS.UnityEngine.Object.Instantiate(self.GridPos, self.PanelPosParent)
                subPosObj.gameObject.name = string.format("Pos%s", subPosKey)
                subPosObj.gameObject:SetActiveEx(false)
                ---@type XUiSCBattleGridPos
                local subGridPos = XUiGridPos.New(subPosObj, self, -trueRow, trueCol)
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
    self:_PrepareBallPosEffect()
end
--endregion

--region Ui - Combo
function XUiPanelBoard:InitCombo()
    self.ComboCountText:TextToSprite(0,0)
    self.ComboSoundIndex = 1
    self.OldCombo = 0
    self.OldComboLevel = 0
    self.OldComboTime = 0
    
    ---@type UnityEngine.Transform[]
    self.EffectCombo = {
        self.EffectComboW,
        self.EffectComboY,
        self.EffectComboR,
    }
    
    self.PanelCombo.gameObject:SetActiveEx(false)
    for _, combo in pairs(self.EffectCombo) do
        combo.gameObject:SetActiveEx(false)
    end
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
    XEventManager.DispatchEvent(XEventId.EVENT_SC_GAME_SOUND_PLAY, string.format("Remove%d",self.ComboSoundIndex))
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
--endregion

--region Ui - Score
function XUiPanelBoard:InitScoreItem()
    ---@type table<XUiSpriteText, number>
    self.ScoreItemDic = {}
    self.ScoreItem.gameObject:SetActiveEx(false)
end

-- 获取一个消除分数item
function XUiPanelBoard:GetScoreItem()
    ---@type XUiSpriteText
    local scoreItem
    for item, timerId in pairs(self.ScoreItemDic) do
        local canUse = timerId == 0
        if canUse then
            scoreItem = item
            break
        end
    end
    if not scoreItem then
        local go = XUiHelper.Instantiate(self.ScoreItem, self.PanelScore)
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
--endregion

--region Ui - TimeRefresh
function XUiPanelBoard:InitTimeRefresh()
    self.BoardMask.gameObject:SetActiveEx(false)
    self.TextCountDown.gameObject:SetActiveEx(false)
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
--endregion

--region Game - Action
function XUiPanelBoard:DoActionShowBallEffect()
    for _,ball in pairs(self.GridBallList or {}) do
        ball:ShowSelectEffect()
    end
end

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionInitBall(data)
    self.BallCount = {}
    local ballList = data.BallList
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self.GridBallList[index]
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:ShowSelectEffect()
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

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionShuffleBall(data)
    self:DoActionInitBall(data)
    XUiManager.TipText("SameColorGameShuffleBallHint")
end

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionDropBall(data)
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

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionAddBall(data)
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

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionSwapBall(data)
    local ballList = {}
    ballList[1] = {StartX = data.SourceBall.PositionX, StartY = data.SourceBall.PositionY,
                   EndX = data.DestinationBall.PositionX, EndY = data.DestinationBall.PositionY}

    ballList[2] = {StartX = data.DestinationBall.PositionX, StartY = data.DestinationBall.PositionY,
                   EndX = data.SourceBall.PositionX, EndY = data.SourceBall.PositionY}
    self:MoveBall(ballList, "SwapBall", function ()
        self.BattleManager:DoActionFinish(data.ActionType)
    end)
end

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionSwapBallEx(data)
    local ballList = {}
    for i, _ in ipairs(data.SourceBallList) do
        table.insert(ballList, {
            StartX = data.SourceBallList[i].PositionX, StartY = data.SourceBallList[i].PositionY,
            EndX = data.DestinationBallList[i].PositionX, EndY = data.DestinationBallList[i].PositionY
        })
        table.insert(ballList, {
            StartX = data.DestinationBallList[i].PositionX, StartY = data.DestinationBallList[i].PositionY,
            EndX = data.SourceBallList[i].PositionX, EndY = data.SourceBallList[i].PositionY
        })
    end
    self:MoveBall(ballList, "SwapBall", function ()
        self.BattleManager:DoActionFinish(data.ActionType)
    end)
end

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionChangeBallColor(data, isPlayQieHuanAnim)
    for _, gridBall in pairs(self.GridBallList) do
        gridBall:InitEffect()
        if isPlayQieHuanAnim then
            gridBall:PlayQieHuanAnim()
        end
    end

    -- 播切换动画时
    local ballList = data.BallList
    if isPlayQieHuanAnim then
        self:_DoShowSkillEffect(XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.CHANGER_BALL)
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

function XUiPanelBoard:DoActionCloseCombo()
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

---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionResetBall(data)
    self:DoActionChangeBallColor(data, true)
end
--endregion

--region Game - Action:Remove
---@param data XSCBattleActionInfo
function XUiPanelBoard:DoActionRemoveBall(data)
    local ballList = data.RemoveBallList
    ---@type XUiSCBattleGridBall[]
    local gridBallList = {}
    local animNotMask = false -- 动画是否不阻塞流程
    local preSkill = self.BattleManager:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        if XEnumConst.SAME_COLOR_GAME.SKILL_ANIM_NOT_MASK[XSameColorGameConfigs.GetSkillType(skillId)] then
            animNotMask = true
        end
    end

    -- 具有特殊移除动画的球
    local aniBallList = {}
    local time = BallBeforeRemoveAnimTimeDir[XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE]
    -- 收集待移除球数据
    for _, ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        table.insert(gridBallList, gridBall)
        -- 收集具有特殊移除动画的球
        if ballData.ItemType ~= XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE then
            if XTool.IsTableEmpty(aniBallList[ballData.ItemType]) then
                aniBallList[ballData.ItemType] = {}
            end
            table.insert(aniBallList[ballData.ItemType], gridBall)
        end
    end
    -- 消球前动画时长处理
    for type, _ in ipairs(aniBallList) do
        local temp = BallBeforeRemoveAnimTimeDir[type]
        if temp > time then
            time = temp
        end
    end
    
    self:_CheckCurSkillWhenRemove(ballList)
    local skillEffectParam = self:_CreateSkillEffectParam(aniBallList)
    local skillEffectTime = self:_DoShowSkillEffect(XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.BEFORE_REMOVE, skillEffectParam)
    if skillEffectTime and skillEffectTime > time then
        time = skillEffectTime
    end
    self:_DoBallAniBeforeRemove(aniBallList)

    -- 消球动画处理
    local removeAnim = function()
        self:_DoRemoveBall(data, gridBallList, ballList, animNotMask, skillEffectParam)
    end
    if time > 0 then
        XScheduleManager.ScheduleOnce(removeAnim, time)
    else
        removeAnim()
    end

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

---@param data XSCBattleActionInfo
---@param gridBallList XUiSCBattleGridBall[]
---@param ballList XSCBattleBallInfo[]
---@param skillEffectParam XSCBattleSkillEffectParam
function XUiPanelBoard:_DoRemoveBall(data, gridBallList, ballList, animNotMask, skillEffectParam)
    -- 消除特效
    XScheduleManager.ScheduleOnce(function()
        local time = self:_DoShowSkillEffect(XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.REMOVE, skillEffectParam)
        -- 有技能特效且技能特效无特殊消球特效则取消普通消球特效
        local curUsingSkillId = self.BattleManager:GetCurUsingSkillId()
        if not time or (curUsingSkillId and not XTool.IsTableEmpty(self._Control:GetCfgSkillBallRemoveEffect(curUsingSkillId))) then
            self:_DoShowRemoveEffect(ballList)
        end
        self:_DoSetRemoveBallAfterSkill()
    end, RemoveEffectWaitTime)
    self:PlayBallWait(gridBallList, "RemoveBall", "Before", function ()
        local combo = self.BattleManager:GetCountCombo()
        self:ShowCombo(combo)

        for _,ballData in pairs(ballList or {}) do
            self.BallCount[ballData.PositionX] = self.BallCount[ballData.PositionX] and self.BallCount[ballData.PositionX] + 1 or 1
            local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
            local tagPosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, -self.BallCount[ballData.PositionX])
            local tagGridPos = self.GridPosDic[tagPosKey]

            gridBall:InitEffect()
            gridBall:EqualPosToGridPos(tagGridPos)
        end

        local cb = not animNotMask and function()
            self.BattleManager:DoActionFinish(data.ActionType)
        end
        self:PlayBallWait(gridBallList, "RemoveBall", "After", cb)
    end)
end

---设置本次消球AfterSkill,用以处理连续消球技能标记,如5期薇拉打雷(使用技能后首次消球)
function XUiPanelBoard:_DoSetRemoveBallAfterSkill()
    if self.BattleManager:GetCurUsingSkillId() then
        self.BattleManager:SetIsAfterSkill(true)
    end
end

---消球前特效动画
---@param aniBallList table<number, XUiSCBattleGridBall[]>
function XUiPanelBoard:_DoBallAniBeforeRemove(aniBallList)
    if XTool.IsTableEmpty(aniBallList) then
        return
    end
    for type, ballList in ipairs(aniBallList) do
        for _, ball in ipairs(ballList) do
            ball:PlayBeforeRemoveAniByType(type)
        end
    end
end
--endregion

--region Game - Ball
---@return XUiSCBattleGridBall
function XUiPanelBoard:GetBallGrid(x, y)
    for _,ball in pairs(self.GridBallList or {}) do
        local position = ball:GetPositionIndex()
        if position.x == x and position.y == y then
            return ball
        end
    end
    return
end

function XUiPanelBoard:UnSelectBall()
    for _,gridBall in pairs(self.GridBallList or {}) do
        gridBall:ShowSelect(false)
    end
    ---@type XUiSCBattleGridBall
    self.SelectedBall = nil
end
--endregion

--region Game - BallTween
function XUiPanelBoard:InitBallTween()
    ---@type table<string, number>
    self.FinishCountDic = {}
end

---@param ballList XUiSCBattleGridBall[]
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

---@param gridBallList XUiSCBattleGridBall[]
function XUiPanelBoard:PlayBallWait(gridBallList, countKey, waitName, cb)
    self.FinishCountDic[countKey] = 0

    if gridBallList and next(gridBallList) then
        for index,gridBall in pairs(gridBallList) do
            gridBall:PlayWait(waitName, function ()
                self:CheckFinishCount(#gridBallList, countKey, cb)
            end)
        end
    else
        self:CheckFinishCount(0, countKey, cb)
    end
end

function XUiPanelBoard:CheckFinishCount(maxCount, key, cb)
    self.FinishCountDic[key] = self.FinishCountDic[key] + 1
    if self.FinishCountDic[key] >= maxCount then
        if cb then cb() end
    end
end

function XUiPanelBoard:StopBallTween()
    local IsHasTimer = false
    for _,ball in pairs(self.GridBallList or {}) do
        if ball:StopTween() then
            IsHasTimer = true
        end
    end
end
--endregion

--region Game - BallInteraction
-- v1.31 按下手指选择球
---@param ball XUiSCBattleGridBall
function XUiPanelBoard:DoStartSelectBall(ball)
    local prepSkill = self.BattleManager:GetPrepSkill()
    if prepSkill then
        return
    end
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        if self.SelectedBall ~= ball then
            if self:IsCanRequestButSameBall(ball) then
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

-- v1.31 一样的球交换
---@param ball XUiSCBattleGridBall
---@param targetBall XUiSCBattleGridBall
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
        self:_SelectBallNormal(ball)
    else
        self:_SelectBallBySkill(ball, prepSkill)
    end
end

function XUiPanelBoard:_SelectBallNormal(ball)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local IsCanRequest = true
        if self.SelectedBall ~= ball then
            --CSXAudioManager.PlaySound(XSameColorGameConfigs.Sound.SwapBall)
            local startPos, endPos
            IsCanRequest, startPos, endPos = self:IsCanRequest(ball)
            if IsCanRequest then
                XDataCenter.SameColorActivityManager.RequestSwapBall(startPos, endPos, function ()
                    self.BattleManager:CheckActionList()
                end)
            else
                if self:IsCanRequestButSameBall(ball) then
                    self:DoMoveSameBall(self.SelectedBall, ball)
                    self:CancelSelectBall()
                else
                    self.SelectedBall:ShowSelect(false)
                    self.SelectedBall = ball
                    ball:ShowSelect(true)
                end
            end
        end

        if IsCanRequest then
            self.SelectedBall:ShowSelect(false)
            self.SelectedBall = nil
        end
    end
end

---@param prepSkill XSCRoleSkill
function XUiPanelBoard:_SelectBallBySkill(ball, prepSkill)
    local skillId = prepSkill:GetSkillId()
    local skillGroupId = prepSkill:GetSkillGroupId()

    if prepSkill:GetControlType() == XEnumConst.SAME_COLOR_GAME.SKILL_CONTROL_TYPE.CLICK_BALL then
        self:DoOneBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XEnumConst.SAME_COLOR_GAME.SKILL_CONTROL_TYPE.CLICK_TWO_BALL then
        self:DoTwoBallSkill(ball, skillGroupId, skillId)
    elseif prepSkill:GetControlType() == XEnumConst.SAME_COLOR_GAME.SKILL_CONTROL_TYPE.CLICK_POPUP then
        self:DoPopUpSkill(ball, skillGroupId, skillId)
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

-- 能交换但不同球(服务端不能发送同色邻球交换)
---@param ball XUiSCBattleGridBall
function XUiPanelBoard:IsCanRequest(ball)
    if self.SelectedBall and self.SelectedBall ~= ball then
        local startPos = {PositionX = self.SelectedBall.Col, PositionY = self.SelectedBall.Row}
        local endPos = {PositionX = ball.Col, PositionY = ball.Row}
        return self._Control:CheckPosIsAdjoin(startPos, endPos) and self.SelectedBall:GetBallId() ~= ball:GetBallId(), startPos, endPos
    else
        return false
    end
end

-- 能交换且是同球交换
---@param ball XUiSCBattleGridBall
function XUiPanelBoard:IsCanRequestButSameBall(ball)
    if self.SelectedBall and self.SelectedBall ~= ball then
        local startPos = {PositionX = self.SelectedBall.Col, PositionY = self.SelectedBall.Row}
        local endPos = {PositionX = ball.Col, PositionY = ball.Row}
        return self._Control:CheckPosIsAdjoin(startPos, endPos) and self.SelectedBall:GetBallId() == ball:GetBallId()
    else
        return false
    end
end

-- v1.31 检查球周围四个方向是否有球
---@param ball XUiSCBattleGridBall
function XUiPanelBoard:CheckAroundSideIsHaveBall(ball)
    local x = ball.Col
    local y = ball.Row
    local isHaveLeftBall = self:GetBallGrid(x - 1, y)
    local isHaveRightBall = self:GetBallGrid(x + 1, y)
    local isHaveUpBall = self:GetBallGrid(x, y - 1)
    local isHaveDownBall = self:GetBallGrid(x, y + 1)
    return isHaveLeftBall, isHaveRightBall, isHaveUpBall, isHaveDownBall
end
--endregion

--region Game - Skill
---@param ball XUiSCBattleGridBall
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
    local isOpenSkill = XEnumConst.SAME_COLOR_GAME.SKILL_NEED_OPEN[XSameColorGameConfigs.GetSkillType(skillId)] and not prepSkill:IsInUsed()
    if isOpenSkill then
        useItemParam = nil
        cb = function()
            -- 关闭技能描述
            XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLE_CLOSE_BLACK_SCENE_TIPS)
        end
    end

    XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, useItemParam, cb)
end

---@param ball XUiSCBattleGridBall
function XUiPanelBoard:DoTwoBallSkill(ball, skillGroupId, skillId)
    if not self.SelectedBall then
        self.SelectedBall = ball
        ball:ShowSelect(true)
    else
        local skill = XDataCenter.SameColorActivityManager.GetRoleShowSkill(skillGroupId)
        if skill and skill:GetSkillType(skillId) == XEnumConst.SAME_COLOR_GAME.SKILL_TYPE.COL_ALL_SWAP then
            if self.SelectedBall.Col == ball.Col then
                return
            end
        end
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

---@param selectBall XUiSCBattleGridBall
function XUiPanelBoard:DoPopUpSkill(selectBall, skillGroupId, skillId)
    local ball_1 = {
        ItemId = selectBall:GetBallId(),
        PositionX = selectBall.Col,
        PositionY = selectBall.Row
    }
    XLuaUiManager.Open("UiSameColorGameChangeColor", self.Role,
            XUiHelper.GetText("SameColorGameColorSelect"),
            function (ball)
                return ball:GetBallId() ~= selectBall:GetBallId()
            end,
            nil,
            function (ball_2, cb)
                XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1, Item2 = ball_2}, cb)
            end)
end
--endregion

--region Game - SkillEffect
function XUiPanelBoard:InitSkillEffect()
    ---@type XObjectPool
    self._EffectAllPool = XObjectPool.New(function()
        return self:_CreateEffectObj(true)
    end)
    ---@type XObjectPool
    self._EffectLocalPool = XObjectPool.New(function()
        return self:_CreateEffectObj(false)
    end)
    if self.PanelBoardEffect then
        self.PanelBoardEffect.gameObject:SetActiveEx(true)
    end
    self._TimerEffect = {}
end

---@return UnityEngine.Transform
function XUiPanelBoard:_CreateEffectObj(isAll)
    local effectObj = XUiHelper.Instantiate(isAll and self.EffectAll.gameObject or self.EffectLocal.gameObject, self.PanelBoardEffect)
    if not effectObj then
        return
    end
    return effectObj
end

function XUiPanelBoard:AddTimer(timer)
    self._TimerEffect[#self._TimerEffect + 1] = timer
end

function XUiPanelBoard:RemoveTimer(timer)
    for i = 1, #self._TimerEffect do
        if self._TimerEffect[i] == timer then
            table.remove(self._TimerEffect, i)
        end
    end
end

---@return UnityEngine.Transform, number 特效对象, 特效时长
function XUiPanelBoard:PlayEffect(url, isAll, position, recycleTime)
    if string.IsNilOrEmpty(url) then
        return
    end
    local pool = isAll and self._EffectAllPool or self._EffectLocalPool
    local effectObj = pool:Create()

    effectObj.gameObject:SetActiveEx(false)
    effectObj.gameObject:SetActiveEx(true)
    effectObj:LoadUiEffect(url, false)
    if not isAll and position then
        effectObj.transform.position = position
    end
    local timer
    local duration = XScheduleManager.SECOND
    local effectSetting = XUiHelper.TryGetComponent(effectObj.transform:GetChild(0), "", "XEffectSetting")
    if effectSetting and XTool.IsNumberValid(effectSetting.LifeTime) then
        duration = math.floor(effectSetting.LifeTime * XScheduleManager.SECOND)
    end
    duration = XTool.IsNumberValid(recycleTime) and recycleTime or duration
    timer = XScheduleManager.ScheduleOnce(function()
        if not effectObj:Exist() then   -- 防止等待回收过程中立马销毁场景报错
            self:RemoveTimer(timer)
            return
        end
        effectObj.gameObject:SetActiveEx(false)
        if isAll then
            self._EffectAllPool:Recycle(effectObj)
        else
            self._EffectLocalPool:Recycle(effectObj)
        end
        self:RemoveTimer(timer)
    end, duration)
    self:AddTimer(timer)
    return effectObj, duration
end

---@param aniBallList table<number, XUiSCBattleGridBall[]>
---@return XSCBattleSkillEffectParam
function XUiPanelBoard:_CreateSkillEffectParam(aniBallList)
    local skillId = self.BattleManager:GetCurUsingSkillId()
    if not skillId then
        return
    end
    ---@type XSCBattleSkillEffectParam
    local param = {}
    param.EffectPositionList = {}
    
    -- 薇拉技能坐标
    local temp = aniBallList[XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.VERA_SKILL_LT]
    if not XTool.IsTableEmpty(temp) then
        local area = XSameColorGameConfigs.GetSkillConfig(skillId).SkillParam
        local position = Vector3.zero
        for _, ball in ipairs(temp) do
            local n = math.floor(area / 2)
            if area % 2 == 0 then
                local a = self:GetBallGridWorldPosition(math.min(ball.Col + n, MaxSize), math.min(ball.Row - n, MaxSize))
                local b = self:GetBallGridWorldPosition(math.min(ball.Col + n + 1, MaxSize), math.min(ball.Row - n - 1, MaxSize))
                position = (a + b) / 2
            else
                position = self:GetBallGridWorldPosition(math.min(ball.Col + n, MaxSize), math.min(ball.Row - n, MaxSize))
            end
            table.insert(param.EffectPositionList, position)
        end
    end
    -- 丽芙技能坐标
    temp = aniBallList[XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.LIFU_ROW]
    if not XTool.IsTableEmpty(temp) then
        param.LifuEffectIsRowList = param.LifuEffectIsRowList or {}
        param.LifuEffectPos = param.LifuEffectPos or {}
        for _, ball in ipairs(temp) do
            table.insert(param.EffectPositionList, self:GetBallGridWorldPosition(ball.Col, ball.Row))
            table.insert(param.LifuEffectIsRowList, true)
            table.insert(param.LifuEffectPos, { ball.Col, ball.Row })
        end
    end
    temp = aniBallList[XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.LIFU_COL]
    if not XTool.IsTableEmpty(temp) then
        param.LifuEffectIsRowList = param.LifuEffectIsRowList or {}
        param.LifuEffectPos = param.LifuEffectPos or {}
        for _, ball in ipairs(temp) do
            table.insert(param.EffectPositionList, self:GetBallGridWorldPosition(ball.Col, ball.Row))
            table.insert(param.LifuEffectIsRowList, false)
            table.insert(param.LifuEffectPos, { ball.Col, ball.Row })
        end
    end
    -- 回音震荡波技能坐标
    temp = aniBallList[XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.ALISA_LT]
    if not XTool.IsTableEmpty(temp) then
        local area = XSameColorGameConfigs.GetSkillConfig(skillId).SkillParam
        local n = math.floor(area / 2)
        local position = Vector3.zero
        for _, ball in ipairs(temp) do
            if area % 2 == 0 then
                local a = self:GetBallGridWorldPosition(math.min(ball.Col + n, MaxSize), math.min(ball.Row - n, MaxSize))
                local b = self:GetBallGridWorldPosition(math.min(ball.Col + n + 1, MaxSize), math.min(ball.Row - n - 1, MaxSize))
                position = (a + b) / 2
            else
                position = self:GetBallGridWorldPosition(math.min(ball.Col + n, MaxSize), math.min(ball.Row - n, MaxSize))
            end
            table.insert(param.EffectPositionList, position)
            param.EffectPositionList[1] = position
            param.EffectPositionList[2] = position
            --table.insert(param.EffectPositionList, self:GetBallGridWorldPosition(ball.Col, ball.Row))
            --table.insert(param.EffectPositionList, self:GetBallGridWorldPosition(ball.Col, ball.Row))
        end
    end
    return param
end

---检查本次消球是不是在使用技能
---@param ballList XSCBattleBallInfo[]
function XUiPanelBoard:_CheckCurSkillWhenRemove(ballList)
    local itemType = XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE
    for _,ballData in pairs(ballList or {}) do
        if ballData.ItemType ~= XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE then
            itemType = ballData.ItemType
        end
    end
    -- 处理连续性技能状态 没有特殊itemType且AfterSkill则清除技能记录
    if itemType == XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.NONE and self.BattleManager:GetIsAfterSkill() then
        -- 技能结束清除记录
        self.BattleManager:ClearCurSuingSkill()
    end
end

---@param ballList XSCBattleBallInfo[]
function XUiPanelBoard:_DoShowRemoveEffect(ballList)
    for _,ballData in pairs(ballList or {}) do
        local removePosKey = XSameColorGameConfigs.CreatePosKey(ballData.PositionX, ballData.PositionY)
        local removeGridPos = self.GridPosDic[removePosKey]
        removeGridPos:ShowRemoveEffect(ballData.ItemId)
    end
end

---技能棋盘特效
---@param timeType number XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE
---@param skillEffectParam XSCBattleSkillEffectParam
function XUiPanelBoard:_DoShowSkillEffect(timeType, skillEffectParam)
    local time = 0
    local curUsingSkillId = self.BattleManager:GetCurUsingSkillId()
    if not curUsingSkillId then
        return
    end
    local skillEffectType, skillEffectList
    if timeType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.BEFORE_REMOVE then
        skillEffectType = self._Control:GetCfgSkillBeforeRemoveEffectType(curUsingSkillId)
        skillEffectList = self._Control:GetCfgSkillBeforeRemoveEffectUrlList(curUsingSkillId)
    elseif timeType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.REMOVE then
        skillEffectType = self._Control:GetCfgSkillOnRemoveEffectType(curUsingSkillId)
        skillEffectList = self._Control:GetCfgSkillOnRemoveEffectUrlList(curUsingSkillId)
    elseif timeType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE.CHANGER_BALL then
        skillEffectType = self._Control:GetCfgSkillChangeBallEffectType(curUsingSkillId)
        skillEffectList = self._Control:GetCfgSkillChangeBallEffectUrlList(curUsingSkillId)
    end
    if XTool.IsTableEmpty(skillEffectList) then
        return
    end
    if skillEffectType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TYPE.ALL then
        local _, effectTime = self:PlayEffect(skillEffectList[1], true)
        time = effectTime
    elseif skillEffectType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TYPE.LOCAL_ONE then
        if XTool.IsTableEmpty(skillEffectParam) then
            return
        end
        local _, effectTime = self:PlayEffect(skillEffectList[1], false, skillEffectParam.EffectPositionList[1])
        time = effectTime
    elseif skillEffectType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TYPE.LOCAL_TWO then
        if XTool.IsTableEmpty(skillEffectParam) then
            return
        end
        local _, effectTime1 = self:PlayEffect(skillEffectList[1], false, skillEffectParam.EffectPositionList[1])
        local _, effectTime2 = self:PlayEffect(skillEffectList[2], false, skillEffectParam.EffectPositionList[2])
        time = math.max(effectTime1, effectTime2)
    elseif skillEffectType == XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TYPE.LIFU then
        if XTool.IsTableEmpty(skillEffectParam) or XTool.IsTableEmpty(skillEffectParam.LifuEffectIsRowList) then
            return
        end 
        time = tonumber(self._Control:GetClientCfgStringValue("LifuSkillEffectTime"))
        local effectUrl = skillEffectList[1]
        self:_PlayLifuSkillEffect(skillEffectParam, effectUrl, time)
    end
    return time
end

---@param skillEffectParam XSCBattleSkillEffectParam
function XUiPanelBoard:_PlayLifuSkillEffect(skillEffectParam, effectUrl, time)
    XScheduleManager.ScheduleOnce(function()
        ---@type UnityEngine.Material
        --local material
        --XLog.Error(skillEffectParam.LifuEffectPos)
        for i, isRow in ipairs(skillEffectParam.LifuEffectIsRowList) do
            local effectObj1, _ = self:PlayEffect(effectUrl, false, skillEffectParam.EffectPositionList[i], time)
            local effectObj2, _ = self:PlayEffect(effectUrl, false, skillEffectParam.EffectPositionList[i], time)
            --if effectObj1 and not material then
            --    local object = XUiHelper.TryGetComponent(effectObj1.transform:GetChild(0), "Ray/L4")
            --    material = object:GetComponent("Renderer").sharedMaterial
            --end
            --effectObj1.name = "a"..i
            --effectObj2.name = "d"..i
            --XLog.Error(i)
            if isRow then
                local h = effectObj1.transform.sizeDelta.x
                local position1 = effectObj1.transform.localPosition + Vector3(0, h / 2, 0)
                local position2 = effectObj1.transform.localPosition + Vector3(0, -h / 2, 0)
                effectObj1.transform.localPosition = position1
                effectObj2.transform.localPosition = position2
                effectObj1.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 90)
                effectObj2.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, -90)
            else
                local w = effectObj1.transform.sizeDelta.y
                local position1 = effectObj1.transform.localPosition + Vector3(w / 2, 0, 0)
                local position2 = effectObj1.transform.localPosition + Vector3(-w / 2, 0, 0)
                effectObj1.transform.localPosition = position1
                effectObj2.transform.localPosition = position2
                effectObj1.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
                effectObj2.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 180)
            end
        end
        --local offsetName = "_MaskTex"
        --if material and material:HasProperty(offsetName) then
        --    local startOffsetX = -0.69
        --    local addOffsetX = startOffsetX * 2
        --    XUiHelper.Tween(time / XScheduleManager.SECOND, function(f)
        --        XLog.Error(1)
        --        material:SetTextureOffset(offsetName, Vector2(f * addOffsetX + startOffsetX, 0))
        --    end, function()
        --        material:SetTextureOffset(offsetName, Vector2(addOffsetX + startOffsetX, 0))
        --    end)
        --end
    end, 0)
end

---预加载消球特效
function XUiPanelBoard:_PrepareBallPosEffect()
    local boardRow = self.Role:GetRow()
    local boardCol = self.Role:GetCol()
    local col, row = 1, 1
    XScheduleManager.Schedule(function()
        local key = XSameColorGameConfigs.CreatePosKey(col, row)
        if self.GridPosDic[key] then
            self.GridPosDic[key]:PrepareDefaultEffect()
        end
        col = col + 1
        if col > boardCol then
            col = 1
            row = row + 1
        end
    end, 0, boardRow * boardCol, 0)
end
--endregion

-----------------------------------------------------------------------------------------------------------


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

---@param ballList XSCBattleBallInfo[]
function XUiPanelBoard:RefreshBallList(ballList)
    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        if not gridBall then
            gridBall = self:GetBallFromRecycleBall(ballData.PositionX, ballData.PositionY)
        end
        gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
    end
end

---@param ballList XSCBattleBallInfo[]
function XUiPanelBoard:RefreshBallListEffect(ballList)
    for _,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.PositionX, ballData.PositionY)
        if not gridBall then
            gridBall = self:GetBallFromRecycleBall(ballData.PositionX, ballData.PositionY)
        end
        local ballId = gridBall:GetBallId()
        local showSelectEffect = XEnumConst.SAME_COLOR_GAME.BALL_SHOW_SELECT_EFFECT[ballId]
        if showSelectEffect then
            gridBall:ShowSelect(true)
        end

        gridBall:ShowSelectEffect()
    end
end

-- 从回收的球里取
-- 触发消球但是不落球的技能结束之后，刷新球，取不到对应位置的球，从回收的球里取
---@return XUiSCBattleGridBall
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

---@param ballList XSCBattleBallInfo[]
function XUiPanelBoard:SetBallId(ballList)
    for index,ballData in pairs(ballList or {}) do
        local gridBall = self:GetBallGrid(ballData.StartX, ballData.StartY)
        if gridBall then
            gridBall:UpdateGrid(self.Role:GetBall(ballData.ItemId))
            gridBall:ShowSelectEffect()
        end
    end
end

---@return UnityEngine.Vector3
function XUiPanelBoard:GetBallGridPosition(x, y)
    local tagPosKey = XSameColorGameConfigs.CreatePosKey(x, y)
    local tagGridPos = self.GridPosDic[tagPosKey]
    if tagGridPos then
        local pos = tagGridPos.Transform.localPosition
        return { 
            x = pos.x,
            y = pos.y,
            z = pos.z,
        }
    end
end

---@return UnityEngine.Vector3
function XUiPanelBoard:GetBallGridWorldPosition(x, y)
    local tagPosKey = XSameColorGameConfigs.CreatePosKey(x, y)
    local tagGridPos = self.GridPosDic[tagPosKey]
    if tagGridPos then
        return tagGridPos.Transform.position
    end
end

--region Event
function XUiPanelBoard:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADD_BUFF, self.DoActionShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUB_BUFF, self.DoActionShowBallEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAP_INIT, self.DoActionInitBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_REMOVE, self.DoActionRemoveBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_DROP, self.DoActionDropBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_ADD, self.DoActionAddBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.DoActionShuffleBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_SWAP, self.DoActionSwapBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_SWAP_EX, self.DoActionSwapBallEx, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BALL_CHANGE_COLOR, self.DoActionChangeBallColor, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_LIST_OVER, self.DoActionCloseCombo, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_MAP_RESET, self.DoActionResetBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
end

function XUiPanelBoard:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADD_BUFF, self.DoActionShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUB_BUFF, self.DoActionShowBallEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAP_INIT, self.DoActionInitBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_REMOVE, self.DoActionRemoveBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_DROP, self.DoActionDropBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_ADD, self.DoActionAddBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SHUFFLE, self.DoActionShuffleBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_SWAP, self.DoActionSwapBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_SWAP_EX, self.DoActionSwapBallEx, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BALL_CHANGE_COLOR, self.DoActionChangeBallColor, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_LIST_OVER, self.DoActionCloseCombo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_MAP_RESET, self.DoActionResetBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_PREP_SKILL, self.UnSelectBall, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectBall, self)
end
--endregion

return XUiPanelBoard