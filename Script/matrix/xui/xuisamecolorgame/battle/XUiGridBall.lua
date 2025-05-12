---@class XUiSCBattleGridBall:XUiNode
---@field _Control XSameColorControl
---@field GoInputHandler XGoInputHandler
local XUiGridBall = XClass(XUiNode, "XUiGridBall")
local TweenSpeed = 0.1
local Vector3 = CS.UnityEngine.Vector3

local WaitTime = {
    ["Before"] = 130,
    ["After"] = 80,
}
-- 球拖拽距离限制
local dragLimit = XUiHelper.GetClientConfig("SCGameBallDragLimit", XUiHelper.ClientConfigType.Float)

function XUiGridBall:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XUiSCBattlePanelBoard
    self.Base = base
    self.Row = 1
    self.Col = 1
    self.WeakTimes = 1
    self.IsBeginSelect = false
    self.IsInSwapBall = false
    self.ClickTime = 0
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    
    self:InitAnim()
    self:InitEffect()
    self:InitInputHandler()
end

--region Data
function XUiGridBall:UpdateGrid(ballData)
    self.Ball = self.Base.Role:GetBall(ballData.ItemId)
    self.Bg:SetRawImage(self.Ball:GetBg())
    if self.Ball:IsWeakBall() then
        self.GameObject.name = "GridBallCall" -- 策划配引导节点用
        self:UpdateWeakHitTimes(ballData.WeakHitTimes)
    elseif self.Ball:IsPropBall() then
        self.GameObject.name = "GridBallProp"
        self:UpdateWeakHitTimes()
    else
        self.GameObject.name = "GridBall"
        self:UpdateWeakHitTimes()
    end
    self.Icon:SetRawImage(self.Ball:GetIcon())
end

function XUiGridBall:GetPositionIndex()
    return {x = self.Col, y = self.Row}
end

function XUiGridBall:GetBallId()
    return self.Ball:GetBallId()
end

---更新破绽剩余攻击次数
function XUiGridBall:UpdateWeakHitTimes(count)
    if self.TextNum then
        if XTool.IsNumberValid(count) then
            self.TextNum.text = count
        else
            self.TextNum.text = ""
        end
    end
end

--endregion

local GetMagnitude = function(v3a)
    return math.sqrt(v3a.x * v3a.x + v3a.y * v3a.y + v3a.z * v3a.z)
end

--region Ui - Move
---@param gridPos XUiSCBattleGridPos
function XUiGridBall:MoveToGridPos(gridPos, cb)
    local tagPos = gridPos.Transform.localPosition
    local selfPos = self.Transform.localPosition
    local power = GetMagnitude({x = tagPos.x - selfPos.x, y = tagPos.y - selfPos.y, z = tagPos.z - selfPos.z}) / gridPos:GetSizeDeltaY()
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

---@param gridPos XUiSCBattleGridPos
function XUiGridBall:EqualPosToGridPos(gridPos)
    if XTool.UObjIsNil(self.Transform) or XTool.UObjIsNil(gridPos.Transform) then
        return
    end
    self.Transform.localPosition = gridPos.Transform.localPosition
    self.Row = gridPos.Row
    self.Col = gridPos.Col
    self:_ClearWaitTimer()
end

function XUiGridBall:StopTween()
    if self.BallMoveTimer then
        XScheduleManager.UnSchedule(self.BallMoveTimer)
        self.BallMoveTimer = nil
        return true
    end
    return false
end
--endregion

--region Ui - Effect
function XUiGridBall:InitEffect()
    self.EffectGain.gameObject:SetActiveEx(false)
    self.EffectReduction.gameObject:SetActiveEx(false)
    self.EffectTiShi.gameObject:SetActiveEx(false)
    
    self.Select.gameObject:SetActiveEx(false)
    self.BuffEffect.gameObject:SetActiveEx(false)
end

function XUiGridBall:_ShowEffect(type)
    local effectUrl = self._Control:GetCfgBallBuffEffect(type)

    if self._EffectUrl ~= effectUrl then
        self.BuffEffect.gameObject:SetActiveEx(false)
        self._EffectUrl = effectUrl
    end
    if self.BuffEffect and not string.IsNilOrEmpty(effectUrl) then
        self.BuffEffect.gameObject:SetActiveEx(true)
        self.BuffEffect:LoadUiEffect(effectUrl)
    end
end

function XUiGridBall:ShowWaitEffect(waitName)
    if waitName == "Before" then
        self.EffectTiShi.gameObject:SetActiveEx(false)
        self.EffectTiShi.gameObject:SetActiveEx(true)
    end
end

function XUiGridBall:ShowSelectEffect()
    local effectType = XEnumConst.SAME_COLOR_GAME.BUFF_TYPE.NONE
    local buffList = self.BattleManager:GetShowBuffList()

    for _,buff in pairs(buffList or {}) do
        for _,targetColor in pairs(buff:GetTargetColorList() or {}) do
            if targetColor == self.Ball:GetColor() then
                if not (effectType and effectType == XEnumConst.SAME_COLOR_GAME.BUFF_TYPE.NO_DAMAGE) then
                    effectType = buff:GetType()
                end
            end
        end
    end

    self:_ShowEffect(effectType)
end
--endregion

--region Ui - Select
function XUiGridBall:ShowSelect(IsShow)
    self.Select.gameObject:SetActiveEx(IsShow)
end
--endregion

--region Ui - Anim
function XUiGridBall:InitAnim()
    ---@type UnityEngine.Transform
    self.GridBallQieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/GridBallQieHuan")
    ---@type UnityEngine.Playables.PlayableDirector[]
    self._RemoveAnimDir = {
        [XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.BOOM_CENTER] = self.GridBallShake
    }
end

function XUiGridBall:IsAnim()
    return self.WaitTimerId ~= nil
end

function XUiGridBall:PlayQieHuanAnim()
    self.GridBallQieHuan.gameObject:PlayTimelineAnimation()
end

function XUiGridBall:PlayWait(waitName, cb)
    self:ShowWaitEffect(waitName)

    self:_ClearWaitTimer()
    self.WaitTimerId = XScheduleManager.ScheduleOnce(function()
        if cb then cb() end
        self.WaitTimerId = nil
    end, WaitTime[waitName])
end

function XUiGridBall:_ClearWaitTimer()
    if self.WaitTimerId then
        XScheduleManager.UnSchedule(self.WaitTimerId)
        self.WaitTimerId = nil
    end
end

function XUiGridBall:PlayBeforeRemoveAniByType(removeType)
    self:_PlayRemoveAnim(removeType)
end

function XUiGridBall:_PlayRemoveAnim(removeType)
    if not self._RemoveAnimDir[removeType] then
        return
    end
    self._RemoveAnimDir[removeType].time = 0
    self._RemoveAnimDir[removeType]:Play()
end

function XUiGridBall:_GetAniDurationByRemoveType(removeType)
    if not self._RemoveAnimDir[removeType] then
        return 0
    end
    return self._RemoveAnimDir[removeType].duration
end
--endregion

--region Ui - Handler
function XUiGridBall:InitInputHandler()
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.BtnClick.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self.GoInputHandler.GoType = CS.XGoType.Ui

    self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnNewPointerDown(eventData) end)
    self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnNewPointerUp(eventData) end)
    self.GoInputHandler:AddBeginDragListener(function(eventData) self:OnNewBeginDrag(eventData) end)
    self.GoInputHandler:AddDragListener(function(eventData) self:OnNewDrag(eventData) end)
    self.GoInputHandler:AddFocusExitListener(function(eventData) self:OnFocusExit(eventData) end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridBall:OnNewPointerDown(eventData)
    if self.BattleManager:GetIsResetting() or self:IsAnim() then
        return
    end
    -- 屏蔽鼠标左右键同时点击
    if self._CurPointId and self._CurPointId ~= eventData.pointerId then
        return
    end
    self._CurPointId = eventData.pointerId

    local isDoubleClick = CS.UnityEngine.Time.time - self.ClickTime < 0.5
    -- 调节层级为球盘最上级
    local count = self.Transform.parent.childCount
    self.Transform:SetSiblingIndex(count - 1)
    -- 记录初始选择状态
    self.IsBeginSelect = self.Select.gameObject.activeSelf
    -- 按下手指记录球坐标
    self.Position = self.Base:GetBallGridPosition(self.Col, self.Row)

    local isInSwapBall, _, _ = self.Base:IsCanRequest(self)
    -- 已选有球再点其他球，两球可交换时做交换并锁拖拽
    self.IsInSwapBall = isInSwapBall
    -- 准备技能时也锁拖拽
    self.IsInPreSkill = self.BattleManager:GetPrepSkill() ~= nil

    if self.Ball:IsWeakBall() and not self.Base:IsInPrepSkill() then
        -- 使用技能时可以选择破绽
        self:CancelSelectBall()
        XUiManager.TipText("SameColorGameWeakSwap")
    elseif isDoubleClick and self.Ball:IsPropBall() then
        -- 双击
        self.Base:DoUsePropBall(self)
        self:CancelSelectBall()
    elseif self.IsInSwapBall or self.IsInPreSkill then
        self.Base:DoSelectBall(self)
    else
        self.Base:DoStartSelectBall(self)
    end
    self.ClickTime = CS.UnityEngine.Time.time
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridBall:OnNewPointerUp(eventData)
    self._CurPointId = nil
    if self.IsInSwapBall or self.IsInPreSkill or not self.Base:IsBallSelect(self) or self.BattleManager:GetIsResetting() or self:IsAnim() then
        return
    end

    local isResetPos = true
    local touchPosition = self:_GetPosByEventData(self.Base.Transform, eventData)
    local x = touchPosition.x - self.Position.x
    local y = touchPosition.y - self.Position.y
    if self.Ball:IsWeakBall() then
        self:CancelSelectBall()
        XUiManager.TipText("SameColorGameWeakSwap") -- 破绽不可交换
    elseif math.abs(x) > dragLimit or math.abs(y) > dragLimit then
        -- 非拖拽状态则不交换防止原地点球触发交换
        if not self._Drag then return end
        ---@type XUiSCBattleGridBall
        local ball = nil
        if math.abs(x) > math.abs(y) then
            ball = self.Base:GetBallGrid(x > 0 and self.Col + 1 or self.Col - 1, self.Row)
        else
            ball = self.Base:GetBallGrid(self.Col, y > 0 and self.Row - 1 or self.Row + 1)
        end
        if ball then
            if ball.Ball:IsWeakBall() then
                self:CancelSelectBall()
                XUiManager.TipText("SameColorGameWeakSwap")
            else
                isResetPos = false
                -- 交换失败 重置回原来的位置
                self.Base:DoSelectBall(ball, handler(self, self.ResetPosition))
            end
        end
    else
        -- 初始已经是选择状态才需要解除选择
        self:CancelSelectBall()
    end
    if isResetPos then
        self:ResetPosition()
    end
    self._Drag = false
end

function XUiGridBall:CancelSelectBall()
    if self.IsBeginSelect then
        self.Base:CancelSelectBall()
    end
end

-- 抬起手指恢复球坐标
function XUiGridBall:ResetPosition()
    self.Transform.localPosition = self.Position
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridBall:OnNewBeginDrag(eventData)
    self._Drag = not self.IsInSwapBall and not self.IsInPreSkill and self.Base:IsBallSelect(self)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridBall:OnNewDrag(eventData)
    if not self._Drag then
        return
    end
    self:_UpdateBallPosition(self:_GetDragPosition(self:_GetPosByEventData(self.Base.Transform, eventData)))
end

function XUiGridBall:OnFocusExit()
    self._CurPointId = nil
    if not self._Drag then
        return
    end
    self:_ResetBallPosition()
end

-- 计算拖拽时球的坐标
function XUiGridBall:_GetDragPosition(touchPosition)
    touchPosition = touchPosition or XUiHelper.GetScreenClickPosition(self.Base.Transform, CS.XUiManager.Instance.UiCamera)
    local targetPosition = {x = 0, y = 0, z = 0}
    local isHaveLeft, isHaveRight, isHaveUp, isHaveDown = self.Base:CheckAroundSideIsHaveBall(self)
    -- 计算x
    local xLLimit = isHaveLeft and self.Position.x - dragLimit or self.Position.x
    local xRLimit = isHaveRight and self.Position.x + dragLimit or self.Position.x
    targetPosition.x = math.max(touchPosition.x, xLLimit)
    targetPosition.x = math.min(targetPosition.x, xRLimit)
    -- 计算y
    local yULimit = isHaveUp and self.Position.y + dragLimit or self.Position.y
    local yDLimit = isHaveDown and self.Position.y - dragLimit or self.Position.y
    targetPosition.y = math.min(touchPosition.y, yULimit)
    targetPosition.y = math.max(targetPosition.y, yDLimit)

    local x = touchPosition.x - self.Position.x
    local y = touchPosition.y - self.Position.y
    -- 限制十字滑动
    if math.abs(y) > math.abs(x) then
        targetPosition.x = self.Position.x
    else
        targetPosition.y = self.Position.y
    end
    -- 限制球形滑动
    --local xSqrt = math.pow(x, 2)
    --local ySqrt = math.pow(y, 2)
    --local dSqrt = math.pow(dragLimit, 2)
    --if xSqrt + ySqrt > dSqrt then
    --    local rate = math.sqrt(dSqrt / (xSqrt + ySqrt))
    --    targetPosition.x = self.Position.x + x * rate
    --    targetPosition.y = self.Position.y + y * rate
    --end
    return targetPosition
end

function XUiGridBall:_UpdateBallPosition(position)
    self.Transform.localPosition = position and position or self:_GetDragPosition()
end

function XUiGridBall:_ResetBallPosition()
    self.InDrag = false
    self.Transform.localPosition = self.Position
end

---@param transform UnityEngine.RectTransform
---@param eventData UnityEngine.EventSystems.PointerEventData
---@return UnityEngine.Vector3
function XUiGridBall:_GetPosByEventData(transform, eventData)
    return self:_GetRectLocalPosByScreenPoint(transform, eventData.position)
end

---@param transform UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@return UnityEngine.Vector3
function XUiGridBall:_GetRectLocalPosByScreenPoint(transform, screenPoint)
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, screenPoint, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return Vector3.zero
    end
    return Vector3(point.x, point.y, 0)
end

---@param transform UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@return UnityEngine.Vector3
function XUiGridBall:_GetWorldPosByScreenPoint(transform, screenPoint)
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToWorldPointInRectangle(transform, screenPoint, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return Vector3.zero
    end
    return Vector3(point.x, point.y, 0)
end
--endregion

--region 道具

---道具刚生成时不会被触发
function XUiGridBall:ShowPropForbid(bo)
    local color = self.Icon.color
    color.a = bo and 0.3 or 1
    self.Icon.color = color
end

--endregion

return XUiGridBall