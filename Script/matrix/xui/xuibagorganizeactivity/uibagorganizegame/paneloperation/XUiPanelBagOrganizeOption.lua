---@class XUiPanelBagOrganizeOption:XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiPanelBagOrganizeOption = XClass(XUiNode, 'XUiPanelBagOrganizeOption')
local XUiPanelBagOrganizeOptionGoodsProxy = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelOperation/XUiPanelBagOrganizeOptionGoodsProxy')
local XUiGridBagOrganizeOptionPrice = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelOperation/XUiGridBagOrganizeOptionPrice')

local CSEventSystem = CS.UnityEngine.EventSystems.EventSystem

function XUiPanelBagOrganizeOption:OnStart()
    self.BtnDelete.CallBack = handler(self, self.OnDeleteEvent)
    self.BtnChange.CallBack = handler(self, self.OnChangeEvent)
    self.BtnYes.CallBack = handler(self, self.OnAddEvent)
    
    self.PanelDrag:AddBeginDragListener(handler(self, self.OnBeginDragEvent))
    self.PanelDrag:AddDragListener(handler(self, self.OnDragEvent))
    self.PanelDrag:AddEndDragListener(handler(self, self.OnEndDragEvent))
    
    self._GameControl = self._Control:GetGameControl()
    
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPEN_GOODSOPTION, self.OnBeCalledOpen, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CLOSE_ITEMOPTION, self.Close, self)

    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTIONPOSITION_INIT, self.SetPositionByAbsoluteEventPos, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_BEGINDRAG, self.OnBeginDragEvent, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_DRAGGING, self.OnDragEvent, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_ENDDRAG, self.OnEndDragEvent, self)

    self._GoodsProxy = XUiPanelBagOrganizeOptionGoodsProxy.New(self.ShowProxyRoot, self)
    self._GoodsProxy:Close()

    self.GridPrice.gameObject:SetActiveEx(false)
    self._PricePool = XPool.New(function() 
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridPrice, self.GridPrice.transform.parent)
        local grid = XUiGridBagOrganizeOptionPrice.New(go, self)
        grid:Open()
        return grid
    end, nil, false)
    
    self:InitBlock()
    
    self._UpBoard = self._Control:GetClientConfigNum('PanelControlUpAndDownBorad', 1)
    self._DownBoard = self._Control:GetClientConfigNum('PanelControlUpAndDownBorad', 2)
    self._LeftBoard = self._Control:GetClientConfigNum('PanelControlLeftAndRightBorad', 1)
    self._RightBoard = self._Control:GetClientConfigNum('PanelControlLeftAndRightBorad', 2)

    -- parent是UiBagOrganizeGame，拿到的是按Canvas拉伸规则的长宽尺寸
    self._HalfHeight = self.Parent.Transform.rect.height * 0.5
    self._HalfWidth = self.Parent.Transform.rect.width * 0.5
    
    self._Vector3CacheForCal = Vector3.zero -- 缓存一份三维向量数据，用于参与计算
end

function XUiPanelBagOrganizeOption:OnEnable()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_MAP_SHOW, self.OnBagChanged, self)
    
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPTIONSTATE_CHANGED, true)
    self.PanelGoodsCanvasGroup.blocksRaycasts = false
    self:RefreshProxy()
    XEventManager.AddEventListener(XEventId.EVENT_BAGORGANIZE_SET_OPTION_POS, self.TryAddByGuideEvent, self)
end

function XUiPanelBagOrganizeOption:OnDisable()
    self.PanelGoodsCanvasGroup.blocksRaycasts = true
    self._GameControl:RefreshValidTotalScore()
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_USING_STATE)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPTIONSTATE_CHANGED, false)
    XEventManager.RemoveEventListener(XEventId.EVENT_BAGORGANIZE_SET_OPTION_POS, self.TryAddByGuideEvent, self)

    self._GameControl:RemoveEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_MAP_SHOW, self.OnBagChanged, self)

end

function XUiPanelBagOrganizeOption:InitBlock()
    -- 固定4x4尺寸
    self._Blocks = {}
    XUiHelper.RefreshCustomizedList(self.GridBlock.transform.parent, self.GridBlock, 16, function(index, go)
        local img = go:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if img then
            table.insert(self._Blocks, img)
        else
            XLog.Error('操作区格子缺少Image组件')    
        end
    end)
end

function XUiPanelBagOrganizeOption:GetUIBlocks()
    return self._Blocks
end

function XUiPanelBagOrganizeOption:GetBlockGridByIndex(index)
    return self.Parent:GetBlockGridByIndex(index)
end

function XUiPanelBagOrganizeOption:GetPriceGrid()
    return self._PricePool:GetItemFromPool()
end

function XUiPanelBagOrganizeOption:BackPriceGrid(grid)
    grid:Close()
    self._PricePool:ReturnItemToPool(grid)
end

function XUiPanelBagOrganizeOption:RefreshProxy()
    if self._CurProxy then
        self._CurProxy:Close()
    end
    
    local itemType = self._GameControl:GetPreItemType()

    if itemType == XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods then
        self._CurProxy = self._GoodsProxy
    end

    if self._CurProxy then
        self._CurProxy:Open()
    end
end

function XUiPanelBagOrganizeOption:RefreshNewItem()
    self:RefreshProxy()
    self._CurProxy:RefreshNewItem()
    self:RefreshPrices()
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_USING_STATE)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_OPTIONSTATE_CHANGED, true)
end

function XUiPanelBagOrganizeOption:OnDeleteEvent()
    if self._CurProxy:OnDeleteEvent() then
        self:Close()
    end
end

function XUiPanelBagOrganizeOption:DeleteByHand()
    if self._CurProxy:DeleteByHand() then
        self:Close()
    end
end

function XUiPanelBagOrganizeOption:OnChangeEvent()
    -- 旋转
    self._GameControl:RotatePreItem()
    -- 旋转完后看看有没有越界
    local leftUpX, leftUpY = self._GameControl:GetPreItemLeftUp()
    if self._CurProxy:CheckPreItemPositionIsOutBoard(leftUpX, leftUpY) then
        local fixSize = self._CurProxy:GetFixSize()
        -- 越界了，先看是在哪个边界
        local fixX = 0
        local fixY = 0
        -- 根据越界情况确认修正方向
        if leftUpX < 1 then
            fixX = fixSize
        elseif leftUpX >= self._GameControl.MapControl:GetMapWidth() - fixSize then
            fixX = -fixSize
        end

        if leftUpY < 1 then
            fixY = fixSize
        elseif leftUpY >= self._GameControl.MapControl:GetMapHeight() - fixSize then
            fixY = -fixSize
        end
        -- 尝试修正
        self:TryToFixPosition(leftUpX, leftUpY, fixX, fixY)
    end
    
    self._CurProxy:AfterChangeEvent()
    self:RefreshPrices()
end

function XUiPanelBagOrganizeOption:OnAddEvent()
    if self._CurProxy:OnAddEvent() then
        self:Close()
    end
end

--region 拖拽事件

function XUiPanelBagOrganizeOption:OnBeginDragEvent(eventData)
    self.IsDragging = true
    --缓存触点起始位置
    self._BeginLeftUpX, self._BeginLeftUpY = self._GameControl:GetPreItemLeftUp()
    self._BeginDragX, self._BeginDragY = self:GetPosByEventData(eventData)
    self._BeginLocalPos = self.Transform.localPosition
    self._BeginDragPointX, self._BeginDragPointY = self._BeginDragX, self._BeginDragY

    self:PlayAnimation('Loop', nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

function XUiPanelBagOrganizeOption:OnDragEvent(eventData)
    local curX, curY = self:GetPosByEventData(eventData)
    
    -- 表现位置部分处理：实时跟随触点
    self._Vector3CacheForCal.x = curX - self._BeginDragPointX
    self._Vector3CacheForCal.y = curY - self._BeginDragPointY
    self._Vector3CacheForCal.z = 0
    
    self.Transform.localPosition = self._BeginLocalPos + self._Vector3CacheForCal
    
    -- 映射位置部分处理：离散数据，与地图坐标一一对应
    -- 计算触点偏移量(从开始拖拽开始到现在）
    local deltaX = curX - self._BeginDragX
    local deltaY = curY - self._BeginDragY
    -- 触点偏移量换算成离散值
    local blockWidth = self._GameControl.MapControl:GetBlockWidth()
    local blockHeight = self._GameControl.MapControl:GetBlockHeight()
    
    local moveX = XMath.ToInt(deltaX / blockWidth)
    local moveY = - (XMath.ToInt(deltaY / blockHeight))
    
    -- 更新当前的离散坐标
    local aimleftUpX = self._BeginLeftUpX + moveX
    local aimleftUpY = self._BeginLeftUpY + moveY

    self._CurProxy:OnDragPositionUpdate(aimleftUpX, aimleftUpY, true)
end

function XUiPanelBagOrganizeOption:OnEndDragEvent(eventData)
    local curX, curY = self:GetPosByEventData(eventData)
    -- 计算触点偏移量(从开始拖拽开始到现在）
    local deltaX = curX - self._BeginDragX
    local deltaY = curY - self._BeginDragY
    -- 触点偏移量换算成离散值
    local blockWidth = self._GameControl.MapControl:GetBlockWidth()
    local blockHeight = self._GameControl.MapControl:GetBlockHeight()

    local moveX = XMath.ToInt(deltaX / blockWidth)
    local moveY = - (XMath.ToInt(deltaY / blockHeight))

    -- 更新当前的离散坐标
    local aimleftUpX = self._BeginLeftUpX + moveX
    local aimleftUpY = self._BeginLeftUpY + moveY
    
    -- 结束拖拽后判断是否在总网格范围外
    local isOutBorad = self._GameControl:CheckPreGoodsPositionIsOutBoard(aimleftUpX, aimleftUpY)

    if isOutBorad then
        -- 超出最大范围则放回
        self:OnDeleteEvent()
    else
        -- 按照离散坐标修正位置
        local leftUpX, leftUpY = self._GameControl:GetPreItemLeftUp()
        local centerX = leftUpX + 2
        local centerY = leftUpY + 1
        self.Transform.localPosition = Vector3((centerX - 1) * blockWidth, - centerY * blockHeight)
    end

    self.IsDragging = false

    -- 刷新方块聚焦显示
    if self._CurProxy.RefreshBlockFocusShow then
        self._CurProxy:RefreshBlockFocusShow()
    end

    self:PlayAnimation('End')
end

--endregion

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPanelBagOrganizeOption:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.Transform.parent.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiPanelBagOrganizeOption:SetPosition(blockGrid, leftUpX, leftUpY)
    if blockGrid then
        self.Transform.position = blockGrid.Transform.position
        self:UpdateControlsPos()
        self._GameControl:UpdatePreItemLeftUpPos(leftUpX, leftUpY)
        self._CurProxy:AfterPositionChanged()
        self:RefreshPrices()
    end
end

--- 直接设置位置，其中左上角坐标用于记录到数据中，中心坐标用于UI位置设置
function XUiPanelBagOrganizeOption:SetPositionEx(leftUpX, leftUpY, centerX, centerY, ignoreUiPos)
    local blockWidth = self._GameControl.MapControl:GetBlockWidth()
    local blockHeight = self._GameControl.MapControl:GetBlockHeight()

    if not ignoreUiPos then
        self.Transform.localPosition = Vector3((centerX - 1) * blockWidth, - centerY * blockHeight)
    end
    
    self:UpdateControlsPos()
    self._GameControl:UpdatePreItemLeftUpPos(leftUpX, leftUpY)
    self._CurProxy:AfterPositionChanged()
    self:RefreshPrices()
end

function XUiPanelBagOrganizeOption:ResetPosition()
    self._CurProxy:ResetPosition()
end

function XUiPanelBagOrganizeOption:OnBeCalledOpen(uiPos)
    self:Open()
    self:ResetPosition()
    self._CurProxy:RefreshShow()
    self.Transform.position = uiPos
    self:UpdateControlsPos()
end

-- 从一个无效的位置向有效的位置逐步逼近，找到最近的有效位置
-- 优先单一方向调整
-- 只有越界时才会走，直到完成步数或未越界
function XUiPanelBagOrganizeOption:TryToFixPosition(leftUpX, leftUpY, moveX, moveY)
    local xStep = XTool.IsNumberValid(moveX) and XMath.ToInt(moveX / math.abs(moveX)) or 0
    local yStep = XTool.IsNumberValid(moveY) and XMath.ToInt(moveY / math.abs(moveY)) or 0

    -- 先预设双向都移动完所有步数
    local tmpLeftUpX = leftUpX + moveX
    local tmpLeftUpY = leftUpY + moveY
    
    -- 先调整水平位置
    while math.abs(xStep) <= math.abs(moveX) do
        local aimX = leftUpX + xStep
        
        if not self._CurProxy:CheckPreItemPositionIsOutBoard(aimX, tmpLeftUpY) then
            -- 横向移动成功
            tmpLeftUpX = aimX
            break
        else
            xStep = xStep + 1
        end
    end
    
    -- 再调整竖直位置
    while math.abs(yStep) <= math.abs(moveY) do
        local aimY = leftUpY + yStep
        
        if not self._CurProxy:CheckPreItemPositionIsOutBoard(tmpLeftUpX, aimY) then
            -- 纵向移动成功
            tmpLeftUpY = aimY
            break
        else
            yStep = yStep + 1
        end
    end

    self._CurProxy:RefreshPositionAfterFindWay(tmpLeftUpX, tmpLeftUpY)
end

function XUiPanelBagOrganizeOption:RefreshPrices()
    self._CurProxy:RefreshPrices()
    self._GameControl:RefreshValidTotalScore()
end

-- 更新UI上的功能按钮、提示文本等的相对方位
function XUiPanelBagOrganizeOption:UpdateControlsPos()
    -- 调整关闭和旋转的位置
    local isVerticalChanged = false
    local isUpper = false
    if self._HalfHeight - self.Transform.anchoredPosition.y <= self._UpBoard then
        self.PanelControl.transform:SetParent(self.ControlPosDown.transform)
        self.PanelControl.transform.anchoredPosition = Vector2.zero
        isVerticalChanged = true
    elseif self.Transform.anchoredPosition.y - self._HalfHeight <= self._DownBoard then
        self.PanelControl.transform:SetParent(self.ControlPosUp.transform)
        self.PanelControl.transform.anchoredPosition = Vector2.zero
        isUpper = true
        isVerticalChanged = true
    end
    
    -- 调整确认和数值显示面板的位置
    if self._HalfWidth - self.Transform.anchoredPosition.x <= self._RightBoard then
        if isUpper then
            self.PanelPrice.transform:SetParent(self.ControlPosScoreUpLeft.transform)
        else
            self.PanelPrice.transform:SetParent(self.ControlPosScoreDownLeft.transform)
        end
        self.PanelPrice.transform.anchoredPosition = Vector2.zero

        self.BtnYes.transform:SetParent(self.ControlPosBtnYesDownRight.transform)
        self.BtnYes.transform.anchoredPosition = Vector2.zero
    elseif self.Transform.anchoredPosition.x - self._HalfWidth <= self._LeftBoard then
        if isUpper then
            self.PanelPrice.transform:SetParent(self.ControlPosScoreUpRight.transform)
        else
            self.PanelPrice.transform:SetParent(self.ControlPosScoreDownRight.transform)
        end
        self.PanelPrice.transform.anchoredPosition = Vector2.zero

        self.BtnYes.transform:SetParent(self.ControlPosBtnYesDownLeft.transform)
        self.BtnYes.transform.anchoredPosition = Vector2.zero
    elseif isVerticalChanged then
        -- 价值详情UI的竖直方向位置需要单独调整，其变化时机跟随确认按钮位置变化
        if isUpper then
            if self.PanelPrice.transform.parent == self.ControlPosScoreDownRight.transform then
                self.PanelPrice.transform:SetParent(self.ControlPosScoreUpRight.transform)
            elseif self.PanelPrice.transform.parent == self.ControlPosScoreDownLeft.transform then
                self.PanelPrice.transform:SetParent(self.ControlPosScoreUpLeft.transform)
            end
        else
            if self.PanelPrice.transform.parent == self.ControlPosScoreUpRight.transform then
                self.PanelPrice.transform:SetParent(self.ControlPosScoreDownRight.transform)
            elseif self.PanelPrice.transform.parent == self.ControlPosScoreUpLeft.transform then
                self.PanelPrice.transform:SetParent(self.ControlPosScoreDownLeft.transform)
            end
        end

        self.PanelPrice.transform.anchoredPosition = Vector2.zero
    end
end

-- 根据引导传参直接设置位置，以4x4为尺寸的左上角坐标及中心坐标
function XUiPanelBagOrganizeOption:TryAddByGuideEvent(leftUpX, leftUpY)
    self:SetPositionEx(leftUpX, leftUpY, leftUpX + 2, leftUpY + 1)
    self:UpdateControlsPos()
    self._CurProxy:RefreshShow()
end

--- 根据传入的拖拽事件，取它的屏幕触点实际值，来设置编辑中的物体位置（包括显示的平滑位置和数据层的离散位置）
--- 用于拖拽物品栏时的间接调整
---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPanelBagOrganizeOption:SetPositionByAbsoluteEventPos(eventData, ignorePosFix)
    if not ignorePosFix then
        local curX, curY = self:GetPosByEventData(eventData)

        -- 设置离散坐标
        local blockWidth = self._GameControl.MapControl:GetBlockWidth()
        local blockHeight = self._GameControl.MapControl:GetBlockHeight()

        local showCenterX = XMath.ToInt(curX / blockWidth)
        local showCenterY = XMath.ToInt(-curY / blockHeight)

        local aimCenterX = showCenterX + 1
        local aimCenterY = showCenterY

        local showDiffX = curX - showCenterX * blockWidth
        local showDiffY = curY + showCenterY * blockHeight

        local aimleftUpX = aimCenterX - 2
        local aimleftUpY = aimCenterY - 1

        -- 因为起始坐标是从（1,1）开始，所以需要补上0到1的差值
        if aimleftUpX <= 0 then
            --aimleftUpX = aimleftUpX + 1
        end

        if aimleftUpY <= 0 then
            aimCenterY = aimCenterY + 1
        end

        -- 设置显示位置
        -- 聚焦中心距离离散中心相差半格
        self._Vector3CacheForCal.x = curX - showDiffX
        self._Vector3CacheForCal.y = curY - showDiffY
        self._Vector3CacheForCal.z = 0

        self.Transform.localPosition = self._Vector3CacheForCal

        self._GameControl:UpdatePreItemLeftUpPos(aimleftUpX, aimleftUpY)
    end
    self._CurProxy:AfterPositionChanged()
    self._CurProxy:RefreshShow()
    self:RefreshPrices()
    self:UpdateControlsPos()

    -- 切换事件系统拖拽聚焦的对象，从拖拽货物栏UI 变成 拖拽编辑面板
    -- 将后续的拖拽行为变成真拖拽，隔离货物栏和编辑面板操作，防止货物栏UI变动对拖拽过程产生的影响
    eventData.pointerDrag = self.PanelDrag.gameObject
    eventData.pointerPress = self.PanelDrag.gameObject
    CSEventSystem.current:SetSelectedGameObject(self.PanelDrag.gameObject, eventData)
end

function XUiPanelBagOrganizeOption:OnBagChanged()
    -- 背包发生改变了，当前编辑的物品有效情况需要刷新
    if self._CurProxy then
        self._CurProxy:RefreshShow()
    end
end

function XUiPanelBagOrganizeOption:RefreshBtnYesState()
    self.BtnYes:SetButtonState(self._CurProxy:GetIsConflict() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

return XUiPanelBagOrganizeOption