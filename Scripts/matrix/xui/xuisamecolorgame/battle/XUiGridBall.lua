local XUiGridBall = XClass(nil, "XUiGridBall")
local CSTextManagerGetText = CS.XTextManager.GetText
local TweenSpeed = 0.1
local Vector3 = CS.UnityEngine.Vector3

local WaitTime = {
    ["Before"] = 130,
    ["After"] = 80,
    }
-- 球拖拽距离限制
local dragLimit = XUiHelper.GetClientConfig("SCGameBallDragLimit", XUiHelper.ClientConfigType.Float)
-- 球拖拽计时间隔
local dragDelay = 10
local Offset = 5

function XUiGridBall:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Row = 1
    self.Col = 1
    self.IsBeginSelect = false
    self.IsInSwapBall = false
    XTool.InitUiObject(self)
    self.GridBallQieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/GridBallQieHuan")
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.EffectGain.gameObject:SetActiveEx(false)
    self.EffectReduction.gameObject:SetActiveEx(false)
    self.EffectTiShi.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(false)
    -- 添加点击事件处理组件
    self.GoInputHandler = self.BtnClick.gameObject:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.BtnClick.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self.GoInputHandler.GoType = CS.XGoType.Ui
    self:SetPointEventCallBack()
end

function XUiGridBall:SetPointEventCallBack()
    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown() end)
        self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp() end)
        self.GoInputHandler:AddBeginDragListener(function(eventData) self:OnBeginDrag() end)
    end
end

-- 按下手指选择球
function XUiGridBall:OnPointerDown()
    if self.BattleManager:GetIsResetting() or self:IsAniming() then 
        return
    end

    -- 调节层级为球盘最上级
    local count = self.Transform.parent.childCount
    self.Transform:SetSiblingIndex(count - 1)
    -- 记录初始选择状态
    self.IsBeginSelect = self.Select.gameObject.activeSelf
    -- 按下手指记录球坐标
    self.Position = self.Base:GetBallGridPosition(self.Col, self.Row)

    local isInSwapBall, _, _ = self.Base:IsCanRequset(self)
    -- 已选有球再点其他球，两球可交换时做交换并锁拖拽
    self.IsInSwapBall = isInSwapBall
    -- 准备技能时也锁拖拽
    self.IsInPreSkill = self.BattleManager:GetPrepSkill() ~= nil
    if self.IsInSwapBall or self.IsInPreSkill then
        self.Base:DoSelectBall(self)
    else
        self.Base:DoStartSelectBall(self)
    end
end

function XUiGridBall:OnBeginDrag()
    if self.IsInSwapBall or self.IsInPreSkill or not self.Base:IsBallSelect(self) or self.BattleManager:GetIsResetting() or self:IsAniming() then
        return
    end
    self.PressTime = 0
    self:RemoveTimer()
    self.Timer = XScheduleManager.ScheduleForever(
        function() self:DragTick() end,
        dragDelay
    )
    self.InDrag = true
end

-- 手指拖拽球
function XUiGridBall:OnDrag()
    if not self.InDrag then
        return
    end
    if self.IsInSwapBall or self.IsInPreSkill or not self.Base:IsBallSelect(self) then
        self:RemoveTimer()
        self.InDrag = false
        self.Transform.localPosition = self.Position
        return
    end
    self.Transform.localPosition = self:GetDragPosition()
end

-- 抬起手指决定是否交换球
function XUiGridBall:OnPointerUp()
    self:RemoveTimer()
    if self.IsInSwapBall or self.IsInPreSkill or not self.Base:IsBallSelect(self) or self.BattleManager:GetIsResetting() or self:IsAniming() then
        return
    end
    -- 抬起手指恢复球坐标
    self.Transform.localPosition = self.Position

    local touchPosition = XUiHelper.GetScreenClickPosition(self.Base.Transform, self.Base.Base.Transform:GetComponent("Canvas").worldCamera)
    local x = touchPosition.x - self.Position.x
    local y = touchPosition.y - self.Position.y
    if math.abs(x) > dragLimit or math.abs(y) > dragLimit then
        -- 非拖拽状态则不交换防止原地点球触发交换
        if not self.InDrag then return end

        local ball = nil
        if math.abs(x) > math.abs(y) then
            ball = self.Base:GetBallGrid(x > 0 and self.Col + 1 or self.Col - 1, self.Row)
        else
            ball = self.Base:GetBallGrid(self.Col, y > 0 and self.Row - 1 or self.Row + 1)
        end
        if ball then
            self.Base:DoSelectBall(ball)
        end
    else
        -- 初始已经是选择状态才需要解除选择
        if self.IsBeginSelect then
            self.Base:CancelSelectBall()
        end
    end
    self.InDrag = false
end

-- v1.31 计算拖拽时球的坐标
function XUiGridBall:GetDragPosition()
    local touchPosition = XUiHelper.GetScreenClickPosition(self.Base.Transform, self.Base.Base.Transform:GetComponent("Canvas").worldCamera)
    local targetPosition = {x = 0, y = 0, z = 0}
    local x = touchPosition.x - self.Position.x
    local y = touchPosition.y - self.Position.y
    local isHaveLeftBall, isHaveRightBall, isHaveUpBall, isHaveDownBall = self.Base:CheckAroundSideIsHaveBall(self)
    -- 计算x
    if x > 0 and isHaveRightBall and math.abs(x) > dragLimit then
        targetPosition.x = self.Position.x + dragLimit
    elseif x <= 0 and isHaveLeftBall and math.abs(x) > dragLimit then
        targetPosition.x = self.Position.x - dragLimit
    elseif (x > 0 and isHaveRightBall and math.abs(x) <= dragLimit) or (x <= 0 and isHaveLeftBall and math.abs(x) <= dragLimit) then
        targetPosition.x = touchPosition.x
    else
        targetPosition.x = self.Position.x
    end
    -- 计算y
    if y > 0 and isHaveUpBall and math.abs(y) > dragLimit then
        targetPosition.y = self.Position.y + dragLimit
    elseif y <= 0 and isHaveDownBall and math.abs(y) > dragLimit then
        targetPosition.y = self.Position.y - dragLimit
    elseif (y > 0 and isHaveUpBall and math.abs(y) <= dragLimit) or (y <= 0 and isHaveDownBall and math.abs(y) <= dragLimit) then
        targetPosition.y = touchPosition.y
    else
        targetPosition.y = self.Position.y
    end
    -- 限制十字滑动
    if math.abs(y) > math.abs(x) then
        targetPosition.x = self.Position.x
    else
        targetPosition.y = self.Position.y
    end
    return targetPosition
end

function XUiGridBall:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- v1.31 计时器拖拽法处理失焦
function XUiGridBall:DragTick()
    if not self.GameObject:Exist() or not self.GameObject.activeSelf or not self.GameObject.activeInHierarchy then
        self:RemoveTimer()
        return
    end
    self.PressTime = self.PressTime + dragDelay
    local pressingTime = self.PressTime - Offset
    if pressingTime > 0 then
        self:OnDrag()
    end
end

function XUiGridBall:UpdateGrid(ball)
    self.Ball = ball
    self.Bg:SetRawImage(ball:GetBg())
    self.Icon:SetRawImage(ball:GetIcon())
end

function XUiGridBall:MoveToGridPos(gridPos, cb)
    local tagPos = gridPos.Transform.localPosition
    local selfPos = self.Transform.localPosition
    local power = Vector3(tagPos.x - selfPos.x, tagPos.y - selfPos.y, tagPos.z - selfPos.z).magnitude / gridPos.Transform.sizeDelta.y
    if self.BallMoveTimer then
        XScheduleManager.UnSchedule(self.BallMoveTimer)
        self.BallMoveTimer = nil
    end
    self.BallMoveTimer = XUiHelper.DoMove(self.Transform, tagPos, TweenSpeed * power, XUiHelper.EaseType.Sin,function()
            self.BallMoveTimer = nil
            self.Row = gridPos.Row
            self.Col = gridPos.Col
            if cb then cb() end
    end)
end

function XUiGridBall:EqualPosToGridPos(gridPos)
    if XTool.UObjIsNil(self.Transform) or XTool.UObjIsNil(gridPos.Transform) then
        --XLog.Error("Ball:")
        --XLog.Error(self.Transform)
        --XLog.Error("Pos:")
        --XLog.Error(gridPos)
        return
    end
    self.Transform.localPosition = gridPos.Transform.localPosition
    self.Row = gridPos.Row
    self.Col = gridPos.Col
    self:ClearWaitTimer()
end

function XUiGridBall:PlayWait(waitName, cb)
    self:ShowWaitEffect(waitName)

    self:ClearWaitTimer()
    self.WaitTimerId = XScheduleManager.ScheduleOnce(function()
        if cb then cb() end
        self.WaitTimerId = nil
    end, WaitTime[waitName])
end

function XUiGridBall:ClearWaitTimer()
    if self.WaitTimerId then
        XScheduleManager.UnSchedule(self.WaitTimerId)
        self.WaitTimerId = nil
    end
end

function XUiGridBall:SelectEffect()
    local effectType = XSameColorGameConfigs.BuffType.None
    local buffList = self.BattleManager:GetShowBuffList()
    
    for _,buff in pairs(buffList or {}) do
        for _,targetColor in pairs(buff:GetTargetColorList() or {}) do
            if targetColor == self.Ball:GetColor() then
                if not (effectType and effectType == XSameColorGameConfigs.BuffType.NoDamage) then
                    effectType = buff:GetType()
                end
            end
        end
    end
    
    self:ShowEffect(effectType)
end

function XUiGridBall:ShowEffect(type)
    self.EffectGain.gameObject:SetActiveEx(type == XSameColorGameConfigs.BuffType.AddDamage)
    self.EffectReduction.gameObject:SetActiveEx(type == XSameColorGameConfigs.BuffType.NoDamage)
end

function XUiGridBall:CloseEffect()
    self.EffectGain.gameObject:SetActiveEx(false)
    self.EffectReduction.gameObject:SetActiveEx(false)
    self.EffectTiShi.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(false)
end

function XUiGridBall:ShowWaitEffect(waitName)
    if waitName == "Before" then
        self.EffectTiShi.gameObject:SetActiveEx(false)
        self.EffectTiShi.gameObject:SetActiveEx(true)
    end
end

function XUiGridBall:ShowSelect(IsShow)
    self.Select.gameObject:SetActiveEx(IsShow)
end

function XUiGridBall:GetPositionIndex()
    return {x = self.Col, y = self.Row}
end

function XUiGridBall:GetBallId()
    return self.Ball:GetBallId()
end

function XUiGridBall:PlayAniByRemoveType(removeType)
    if removeType == XSameColorGameConfigs.BallRemoveType.BoomCenter then
        self.GridBallShake.time = 0
        self.GridBallShake:Play()
    end
end

function XUiGridBall:GetAniDurationByRemoveType(removeType)
    if removeType == XSameColorGameConfigs.BallRemoveType.BoomCenter then
        return self.GridBallShake.duration
    end
end

function XUiGridBall:StopTween()
    if self.BallMoveTimer then
        XScheduleManager.UnSchedule(self.BallMoveTimer)
        self.BallMoveTimer = nil
        return true
    end
    return false
end

function XUiGridBall:IsAniming()
    return self.WaitTimerId ~= nil
end

function XUiGridBall:PlayQieHuanAnim()
    self.GridBallQieHuan.gameObject:PlayTimelineAnimation()
end

return XUiGridBall