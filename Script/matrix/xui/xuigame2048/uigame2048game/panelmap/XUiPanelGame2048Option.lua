---@class XUiPanelGame2048Option: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiPanelGame2048Option = XClass(XUiNode, 'XUiPanelGame2048Option')
local CSXInputManager = CS.XInputManager

function XUiPanelGame2048Option:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.PanelDrag:AddBeginDragListener(handler(self, self.OnBeginDragEvent))
    self.PanelDrag:AddDragListener(handler(self, self.OnDragEvent))
    self.PanelDrag:AddEndDragListener(handler(self, self.OnEndDragEvent))
    self._PointMoveLimit = self._Control:GetClientConfigNum('GameDragTriggerLength')
end

function XUiPanelGame2048Option:OnEnable() 
    self:InitGamePadInputListener()
    XEventManager.AddEventListener(XEventId.EVENT_GAME2048_TRY_MOVE_BLOCK, self.DoDragByGuide, self) 
end

function XUiPanelGame2048Option:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GAME2048_TRY_MOVE_BLOCK, self.DoDragByGuide, self)
    self:RemoveGamePadInputListener()
end

function XUiPanelGame2048Option:OnBeginDragEvent(eventData)
    --缓存触点起始位置
    self._BeginDragPoint = eventData.position
    self._HasTrigger = false
end

function XUiPanelGame2048Option:OnDragEvent(eventData)
    --计算触点偏移量
    local x_delta = eventData.position.x - self._BeginDragPoint.x
    local y_delta = eventData.position.y - self._BeginDragPoint.y
    
    self:TryDrag(x_delta, y_delta)
end

function XUiPanelGame2048Option:OnEndDragEvent(eventData)
    
end

--region 键盘输入映射
function XUiPanelGame2048Option:InitGamePadInputListener()
    -- 由父节点确定切换时机
    --XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.Game2048)
     
    self._OnPcClickCbHandle = handler(self, self.OnPcClickCb)
    CSXInputManager.RegisterOnClick(CS.XInputManager.XOperationType.Game2048, self._OnPcClickCbHandle)
end

function XUiPanelGame2048Option:RemoveGamePadInputListener()
    if self._GameControl then
        self._GameControl:ResumeCurInputMap()
    end

    CSXInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.Game2048, self._OnPcClickCbHandle)
end

function XUiPanelGame2048Option:OnPcClickCb(inputDeviceType, key, clickType, operationType)
    -- 引导时禁止键盘映射操作
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    
    if clickType == CS.XOperationClickType.KeyDown then
        if key == XEnumConst.GAME_PC_KEY.Left then
            self:OnClickLeft()
        elseif key == XEnumConst.GAME_PC_KEY.Right then
            self:OnClickRight()
        elseif key == XEnumConst.GAME_PC_KEY.Up then
            self:OnClickUp()
        elseif key == XEnumConst.GAME_PC_KEY.Down then
            self:OnClickDown()
        elseif key == XEnumConst.GAME_PC_KEY.Esc then
            self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_TRY_EXIT_GAME)
        end
    end
end

function XUiPanelGame2048Option:OnClickLeft()
    self:DoDragByGuide(XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Left)
end

function XUiPanelGame2048Option:OnClickRight()
    self:DoDragByGuide(XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Right)
end

function XUiPanelGame2048Option:OnClickUp()
    self:DoDragByGuide(XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Up)
end

function XUiPanelGame2048Option:OnClickDown()
    self:DoDragByGuide(XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Down)
end
--endregion

function XUiPanelGame2048Option:CheckCannotDrag()
    return self._Control:GetIsGameOver() or self._GameControl:GetIsActionPlaying() or self._GameControl:GetIsUsingProp() or self._Control:GetIsWaitForSettle() or self._GameControl:GetIsWaitForNextStep()
end

function XUiPanelGame2048Option:TryDrag(x_delta, y_delta)
    if self:CheckCannotDrag() then
        return
    end
    
    self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_OPTION)
    
    local x_delta_abs = math.abs(x_delta)
    local y_delta_abs = math.abs(y_delta)
    if x_delta_abs >= self._PointMoveLimit or
            y_delta_abs >= self._PointMoveLimit then

        if not self._HasTrigger then
            self._HasTrigger = true
            x_delta = XMath.ToMinInt(x_delta)
            y_delta = XMath.ToMinInt(y_delta)

            if x_delta_abs >= y_delta_abs then
                y_delta = 0
            elseif y_delta_abs > x_delta_abs then
                x_delta = 0
            end

            if self._GameControl:DoMove(x_delta, y_delta) then
                self._GameControl.ActionsControl:StartActionList(function()
                    self._GameControl:RequestGame2048NextStep(function()
                        self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_MAPDATA_VERIFICATION)
                        -- 检查游戏是否结束
                        if self._GameControl:CheckIsGameOver() then
                            self._Control:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.CannotMove, function(res)
                                self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_GAMEOVER, res, nil, self._Control:GetClientConfigNum('GameSettlePopDelay'))
                                self._GameControl.BoardShowControl:OnStageEnd()
                            end)
                        end
                    end)
                end)
                self._GameControl.BoardShowControl:ResetNoOperationTimer()
            else
                -- 检查游戏是否结束
                if self._GameControl:CheckIsGameOver() then
                    self._Control:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.CannotMove, function(res)
                        self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_GAMEOVER, res)
                        self._GameControl.BoardShowControl:OnStageEnd()
                    end)
                end
            end
        end
    end
end

function XUiPanelGame2048Option:DoDragByGuide(direction)
    direction = tonumber(direction)
    self._HasTrigger = false
    if direction == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Up then
        self:TryDrag(0, self._PointMoveLimit)
    elseif direction == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Down then
        self:TryDrag(0, -self._PointMoveLimit)
    elseif direction == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Left then
        self:TryDrag(-self._PointMoveLimit, 0)
    elseif direction == XMVCA.XGame2048.EnumConst.DragDirectionByGuide.Right then
        self:TryDrag(self._PointMoveLimit, 0)
    end
end

return XUiPanelGame2048Option