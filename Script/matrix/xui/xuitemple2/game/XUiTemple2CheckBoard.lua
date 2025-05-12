local XUiTemple2CheckBoardGrid = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardGrid")
local XUiTemple2CheckBoardRole = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardRole")
local XUiTemple2CheckBoardScorePreview = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardScorePreview")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local POS = {
    CENTER = 0,
    UP = 1,
    DOWN = 2,
    LEFT = 4,
    RIGHT = 8,
}

---@class XUiTemple2CheckBoard : XUiNode
---@field _Control XTemple2Control
local XUiTemple2CheckBoard = XClass(XUiNode, "XUiTemple2CheckBoard")

function XUiTemple2CheckBoard:OnStart(control)
    if not self.Panel then
        self.Panel = self.Content
    end

    self._IsAutoScroll = false

    self._OperationControl = control

    ---@type XUiTemple2Map
    self._Map = require("XUi/XUiTemple2/Game/XUiTemple2Map").New()
    self._MapPieces = { self.Image1, self.Image2, self.Image3, self.Image4 }

    ---@type XUiTemple2CheckBoardGrid[]
    self._Grids = {}
    self._BlockGrids = {}

    ---@type XLuaVector2
    self._ScreenPosBeginDragOfMouse = XLuaVector2.New()
    ---@type XLuaVector2
    self._ScreenPosBeginDragOfUi = XLuaVector2.New()
    ---@type XLuaVector2
    self._ScreenPosOfCurrentUi = XLuaVector2.New()
    ---@type XLuaVector2
    self._OperationPos = XLuaVector2.New(5, 5)

    self._GridSize = XTemple2Enum.GRID_SIZE
    self._MapSize = XLuaVector2.New()

    self._TempVector3 = Vector3()
    self:AddListenerInput()

    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnClickYes)
    XUiHelper.RegisterClickEvent(self, self.BtnDelete, self.OnClickDelete)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnClickRotate)

    self.PanelGridClick.OnClick = function(...)
        self:OnClickGrid(...)
    end

    self._Timer = false

    if self.GridPreview then
        self.GridPreview.gameObject:SetActiveEx(false)
    end
    if self.GridCharacter then
        ---@type XUiTemple2CheckBoardRole
        self._Role = XUiTemple2CheckBoardRole.New(self.GridCharacter, self)
        self._Role:Close()
    end

    self._IsOperationRight = nil
    self._IsOperationUp = nil

    local spaceY = 400
    local spaceX = 400
    local resolution = CS.UnityEngine.Screen.currentResolution
    local screen = CS.UnityEngine.Screen
    local ratioY = screen.height / resolution.height
    local ratioX = screen.width / resolution.width
    spaceY = spaceY * ratioY
    spaceX = spaceX * ratioX
    self._Box = {
        Up = screen.height - spaceY,
        Down = spaceY,
        Left = spaceX,
        Right = screen.width - spaceX,
    }
    spaceY = spaceY / 2
    spaceX = spaceX / 2
    self._AutoMoveBox = {
        Up = screen.height - spaceY,
        Down = spaceY,
        Left = spaceX,
        Right = screen.width - spaceX,
    }
    self._PosOnBox = POS.CENTER
    ---@type XLuaVector2
    self._TempOffset = XLuaVector2.New()
    self._ScrollSpeed = 17
    self._ScrollBoard = 50
    self._Epsilon = 1
    self:UpdateBlockAndPreview()

    if self.PanelScore then
        self.PanelScore.gameObject:SetActiveEx(false)
        self._GridScorePreview = {}
    end

    self._IsFirstTime = true

    self._TimerTweenSetPos = false
    self._TweenTime = 0
    self._TweenDuration = 0
    self._TweenStartPosition = false
    self._TweenTargetPosition = false

    self._TimerUpdateMap = false

    self._IsDragging = false
end

---@return XTemple2GameControl
function XUiTemple2CheckBoard:GetOperationControl()
    return self._OperationControl
end

function XUiTemple2CheckBoard:OnEnable()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateOperation()
        end, 0, 0)
    end
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_OPERATION, self.UpdateBlockAndPreview, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_BEGIN_DRAG, self.OnBeginDrag, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_ON_DRAG, self.OnDrag, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_ON_END_DRAG, self.OnEndDrag, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_GAME, self.UpdateBlockAndMap, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_SET_CAMERA_POS, self.SetCameraPosAsync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_SET_BLOCK_POS, self.SetBlockPos, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_CANCEL_BLOCK, self.CancelBlockFromGuide, self)
end

function XUiTemple2CheckBoard:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    if self._TimerFocusCenter then
        XScheduleManager.UnSchedule(self._TimerFocusCenter)
        self._TimerFocusCenter = false
    end
    if self._TimerUpdateMap then
        XScheduleManager.UnSchedule(self._TimerUpdateMap)
        self._TimerUpdateMap = false
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_OPERATION, self.UpdateBlockAndPreview, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_BEGIN_DRAG, self.OnBeginDrag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_ON_DRAG, self.OnDrag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_ON_END_DRAG, self.OnEndDrag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_GAME, self.UpdateBlockAndMap, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_SET_CAMERA_POS, self.SetCameraPosAsync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_SET_BLOCK_POS, self.SetBlockPos, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_CANCEL_BLOCK, self.CancelBlockFromGuide, self)
end

function XUiTemple2CheckBoard:UpdateBg()
    local bgData = self:GetOperationControl():GetBgData()
    ---@type UnityEngine.UI.RawImage
    local bg = self.Bg
    if bg then
        bg:SetRawImage(bgData.Image)
        XUiHelper.SetSizeWithCurrentAnchors(bg.rectTransform, bgData.Width, bgData.Height)
        XUiHelper.SetSizeWithCurrentAnchors(bg.rectTransform, bgData.Width, bgData.Height)
        bg.rectTransform.localPosition = XLuaVector2.New(bgData.OffsetX, bgData.OffsetY)
    end
end

function XUiTemple2CheckBoard:OnDestroy()
    ---@type UnityEngine.UI.ScrollRect
    local scrollView = self.ScrollView
    scrollView.onValueChanged:RemoveAllListeners()
end

function XUiTemple2CheckBoard:Update()
    ---@type XUiTemple2CheckBoardData
    local data = self:GetOperationControl():GetUiDataMap()

    local x = data.X
    local y = data.Y
    self._MapSize.x = x
    self._MapSize.y = y
    local gridSize = self._GridSize
    local boardWidth = gridSize * x
    local boardHeight = gridSize * y

    ---@type UnityEngine.RectTransform
    local panel = self.Panel
    local left = math.abs(panel.offsetMin.x)
    local right = math.abs(panel.offsetMax.x)
    local top = math.abs(panel.offsetMax.y)
    local down = math.abs(panel.offsetMax.y)

    local panelWidth = boardWidth + left + right
    local panelHeight = boardHeight + top + down
    XTool.UpdateDynamicItem(self._Grids, data.Grids, self.Grid, XUiTemple2CheckBoardGrid, self)

    ---@type UnityEngine.RectTransform
    local content = self.Content
    content:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, panelWidth)
    content:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, panelHeight)
    local screen = CS.UnityEngine.Screen

    self.Checkerboard.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, boardWidth)
    self.Checkerboard.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, boardHeight)

    if boardWidth < screen.width or boardHeight < screen.height then
        self._IsAutoScroll = false
    else
        self._IsAutoScroll = true
    end

    -- 居中
    if self._IsFirstTime then
        self._IsFirstTime = false
        self:FocusCenter(x, y)
    end

    self._Map:SetRandomMap(data.StageId, self._MapPieces, self.Map)
end

function XUiTemple2CheckBoard:UpdateOperation()
    ---@type UnityEngine.RectTransform
    local panelOption = self.PanelOption
    if not panelOption.gameObject.activeInHierarchy then
        return
    end

    local x = self._GridSize * (self._OperationPos.x - 1) + self._GridSize / 2
    local y = self._GridSize * (self._OperationPos.y - 1) + self._GridSize / 2
    self._TempVector3.x = x
    self._TempVector3.y = y
    self._TempVector3.z = 0

    ---@type UnityEngine.RectTransform
    local checkBoard = self.Checkerboard.transform
    local worldPosition = checkBoard:TransformPoint(self._TempVector3)
    local localPosition = panelOption.parent:InverseTransformPoint(worldPosition)
    panelOption.localPosition = localPosition

    local screenPosition = self:GetScreenPosition(worldPosition)
    self:UpdateOperationPos(screenPosition)

    if self.BtnChange then
        if self._OperationControl:IsShowRotationIcon() then
            self.BtnChange.gameObject:SetActiveEx(true)
        else
            self.BtnChange.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTemple2CheckBoard:AddListenerInput()
    ---@type XGoInputHandler
    local dragInput = self.PanelDrag
    dragInput:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    dragInput:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    dragInput:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

function XUiTemple2CheckBoard:GetLocalPositionOfContent(screenPosition)
    local hasValue, position = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Checkerboard.transform, screenPosition, CS.XUiManager.Instance.UiCamera)
    if hasValue then
        return position
    end
    return false
end

function XUiTemple2CheckBoard:GetScreenPosition(worldPosition)
    local screenPosition = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(worldPosition)
    return screenPosition
end

function XUiTemple2CheckBoard:GetGrid(x, y)
    --TODO by zlb
    for i = 1, #self._Grids do
        local grid = self._Grids[i]
        local uiData = grid:GetUiData()
        if uiData.X == x and uiData.Y == y then
            return grid
        end
    end
end

function XUiTemple2CheckBoard:GetGridPos(x, y)
    local gridX = x / self._GridSize
    local gridY = y / self._GridSize
    gridX = math.ceil(gridX)
    gridY = math.ceil(gridY)
    gridX = XMath.Clamp(gridX, 1, self._MapSize.x)
    gridY = XMath.Clamp(gridY, 1, self._MapSize.y)
    return gridX, gridY
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTemple2CheckBoard:OnBeginDrag(eventData)
    local screenPosition = eventData.position
    self._ScreenPosBeginDragOfMouse:UpdateByVector(screenPosition)

    ---@type UnityEngine.RectTransform
    local panelOption = self.PanelOption
    local optionPosition = self:GetScreenPosition(panelOption.position)
    self._ScreenPosBeginDragOfUi:UpdateByVector(optionPosition)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTemple2CheckBoard:OnDrag(eventData)
    self._IsDragging = true
    local screenPosition = eventData.position
    local offsetX, offsetY = screenPosition.x - self._ScreenPosBeginDragOfMouse.x, screenPosition.y - self._ScreenPosBeginDragOfMouse.y
    self._ScreenPosOfCurrentUi.x = self._ScreenPosBeginDragOfUi.x + offsetX
    self._ScreenPosOfCurrentUi.y = self._ScreenPosBeginDragOfUi.y + offsetY

    local screen = CS.UnityEngine.Screen
    self._ScreenPosOfCurrentUi.x = XMath.Clamp(self._ScreenPosOfCurrentUi.x, 0, screen.width)
    self._ScreenPosOfCurrentUi.y = XMath.Clamp(self._ScreenPosOfCurrentUi.y, 0, screen.height)

    self:OnMove(self._ScreenPosOfCurrentUi)
end

function XUiTemple2CheckBoard:OnMove(position)
    local localPosition = self:GetLocalPositionOfContent(position)
    if localPosition then
        local gridX, gridY = self:GetGridPos(localPosition.x, localPosition.y)
        self:SetOperationPos(gridX, gridY)
        if self:GetOperationControl():SetPositionOfBlock2EditMap(self._OperationPos.x, self._OperationPos.y) then
            self:UpdateBlock()
            --self:UpdateBlockAndMap()
            -- 延时刷新
            self:StartTimerUpdatePreview()
            self:StartTimerUpdateMap()
        end
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTemple2CheckBoard:OnEndDrag(eventData)
    self._IsDragging = false
end

function XUiTemple2CheckBoard:OnDestroy()
    ---@type XGoInputHandler
    local dragInput = self.PanelDrag
    dragInput:RemoveAllListeners()
end

function XUiTemple2CheckBoard:UpdateBlock(worldPosition)
    if worldPosition then
        --XLog.Error(worldPosition)
        ---@type UnityEngine.RectTransform
        local transform = self.Checkerboard.transform
        local localPosition = transform:InverseTransformPoint(worldPosition)
        local gridX, gridY = self:GetGridPos(localPosition.x, localPosition.y)
        self:SetOperationPos(gridX, gridY)
        self:GetOperationControl():SetPositionOfBlock2EditMap(gridX, gridY)

        local screenPosition = self:GetScreenPosition(worldPosition)
        self._ScreenPosBeginDragOfMouse:UpdateByVector(screenPosition)
        self._ScreenPosBeginDragOfUi:UpdateByVector(screenPosition)

        local screenPositionOfOption = self.PanelOption.parent:InverseTransformPoint(worldPosition)
        self.PanelOption.localPosition = screenPositionOfOption
    end

    local editingBlockData = self:GetOperationControl():GetUiDataBlock2EditMap(self._OperationPos)
    if not editingBlockData then
        self.PanelOption.gameObject:SetActiveEx(false)
        return
    end
    self.PanelOption.gameObject:SetActiveEx(true)
    XTool.UpdateDynamicItem(self._BlockGrids, editingBlockData.Grids, self.BlockGrid, XUiTemple2CheckBoardGrid, self)
    if editingBlockData.Position then
        local position = editingBlockData.Position
        self:SetOperationPos(position.x, position.y)
    end
end

function XUiTemple2CheckBoard:UpdateBlockAndPreview(worldPosition)
    self:UpdateBlock(worldPosition)
    self:UpdateScorePreview()
end

function XUiTemple2CheckBoard:OnClickYes()
    local isSuccess = self:GetOperationControl():ConfirmBlock2EditMap(self._OperationPos)
    if isSuccess then
        self:UpdateBlockAndMap()
    else
        XUiManager.TipError(XUiHelper.GetText("TempleFailInsert"))
    end
end

function XUiTemple2CheckBoard:UpdateBlockAndMap()
    self:UpdateBlockAndPreview()
    self:Update()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_SCORE)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_BLOCK_OPTION)
end

function XUiTemple2CheckBoard:OnClickDelete()
    self:GetOperationControl():RemoveBlock2EditMap()
    self:UpdateBlockAndMap()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_SCORE)
end

function XUiTemple2CheckBoard:OnClickRotate()
    self:GetOperationControl():RotateBlock2EditMap()
    self:UpdateBlockAndMap()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_SCORE)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTemple2CheckBoard:OnClickGrid(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.Checkerboard.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if hasValue then
        local x, y = point.x, point.y

        local gridX, gridY = x / self._GridSize, y / self._GridSize
        gridX = math.ceil(gridX)
        gridY = math.ceil(gridY)
        self._ScreenPosOfCurrentUi.x = eventData.position.x
        self._ScreenPosOfCurrentUi.y = eventData.position.y
        self:CancelBlock(gridX, gridY)
    end
end

function XUiTemple2CheckBoard:_OnClickGrid(x, y)

end

function XUiTemple2CheckBoard:GetCharacter()
    return self._Role
end

function XUiTemple2CheckBoard:HideCharacter()
    self._Role:SetEmoj(false)
    self._Role:Close()
end

function XUiTemple2CheckBoard:GetPosOnBox(pos)
    local posOnBox = POS.CENTER
    if pos.y > self._Box.Up then
        posOnBox = posOnBox | POS.UP
    elseif pos.y < self._Box.Down then
        posOnBox = posOnBox | POS.DOWN
    end
    if pos.x < self._Box.Left then
        posOnBox = posOnBox | POS.LEFT
    elseif pos.x > self._Box.Right then
        posOnBox = posOnBox | POS.RIGHT
    end
    return posOnBox
end

function XUiTemple2CheckBoard:UpdateOperationPos(pos)
    if self.PanelControl then
        local posOnBox = self:GetPosOnBox(pos)
        if posOnBox ~= self._PosOnBox then
            self._PosOnBox = posOnBox
            if posOnBox & POS.RIGHT ~= 0 then
                self.BtnYes.transform:SetParent(self.ControlPosLeft, false)
            else
                self.BtnYes.transform:SetParent(self.ControlPosRight, false)
            end
            if posOnBox & POS.UP ~= 0 then
                self.PanelControl.transform:SetParent(self.ControlPosDown, false)
            else
                self.PanelControl.transform:SetParent(self.ControlPosUp, false)
            end
        end

        if self._IsAutoScroll and posOnBox ~= POS.CENTER then
            ---@type UnityEngine.RectTransform
            local content = self.Content

            ---@type UnityEngine.UI.ScrollRect
            local scrollView = self.ScrollView

            local offset = self._TempOffset
            offset:Clear()
            local time = CS.UnityEngine.Time.deltaTime

            local up = -content.rect.height + scrollView.viewport.rect.height
            local down = 0
            local left = 0
            local right = -content.rect.width + scrollView.viewport.rect.width

            if self._IsDragging then
                if pos.y > self._AutoMoveBox.Up then
                    offset.y = (self._AutoMoveBox.Up - pos.y) * self._ScrollSpeed * time
                elseif pos.y < self._AutoMoveBox.Down then
                    offset.y = (self._AutoMoveBox.Down - pos.y) * self._ScrollSpeed * time
                end
                if pos.x > self._AutoMoveBox.Right then
                    offset.x = (self._AutoMoveBox.Right - pos.x) * self._ScrollSpeed * time
                elseif pos.x < self._AutoMoveBox.Left then
                    offset.x = (self._AutoMoveBox.Left - pos.x) * self._ScrollSpeed * time
                end
            end

            local anchoredPosition = content.anchoredPosition
            local anchoredPositionX = anchoredPosition.x + offset.x
            local anchoredPositionY = anchoredPosition.y + offset.y

            anchoredPositionX = XMath.Clamp(anchoredPositionX, right, left)
            anchoredPositionY = XMath.Clamp(anchoredPositionY, up, down)

            if math.abs(anchoredPositionX - anchoredPosition.x) > self._Epsilon
                    or math.abs(anchoredPositionY - anchoredPosition.y) > self._Epsilon then
                anchoredPosition.x = anchoredPositionX
                anchoredPosition.y = anchoredPositionY
                content.anchoredPosition = anchoredPosition
                --self:OnMove(self._ScreenPosOfCurrentUi)
            end

            if self._ScreenPosOfCurrentUi.x ~= 0 and self._ScreenPosOfCurrentUi.y ~= 0 then
                self:OnMove(self._ScreenPosOfCurrentUi)
            end
        end
    end
end

function XUiTemple2CheckBoard:SetOperationPos(x, y)
    x, y = self:GetOperationControl():ClampBlockPosition(x, y)
    self._OperationPos.x = x
    self._OperationPos.y = y
end

function XUiTemple2CheckBoard:UpdateScorePreview()
    if not self.PanelScore then
        return
    end
    local gameControl = self:GetOperationControl()
    if not gameControl.GetScorePreview then
        return
    end
    local scorePreview = gameControl:GetScorePreview()
    if scorePreview and #scorePreview > 0 then
        self.PanelScore.gameObject:SetActiveEx(true)
        XTool.UpdateDynamicItem(self._GridScorePreview, scorePreview, self.GridScore, XUiTemple2CheckBoardScorePreview, self)
    else
        self.PanelScore.gameObject:SetActiveEx(false)
    end
end

function XUiTemple2CheckBoard:SetCharacterIcon(icon)
    self._Role:SetIcon(icon)
end

---@param transform UnityEngine.RectTransform
function XUiTemple2CheckBoard:_GetPosition4Screen(transform)
    local localPosition = transform.localPosition
    local worldPosition = transform.parent:TransformPoint(localPosition)
    --local position4Parent = parent:InverseTransformPoint(worldPosition)
    --return position4Parent
    local screenPosition = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(worldPosition)
    -- z 值没用
    local result = Vector2(screenPosition.x, screenPosition.y)
    return result
end

function XUiTemple2CheckBoard:SetCameraPosSync(gridX, gridY)
    gridX = tonumber(gridX)
    gridY = tonumber(gridY)

    -- A:格子 相对屏幕的坐标
    -- B:Content 相对屏幕的坐标
    -- C:中心点的屏幕坐标
    -- D:Content的目标屏幕坐标
    -- E = (C-A) + B 要把content移动到屏幕中央

    local gridPositionBefore, contentPositionBefore, screenCenter, contentPositionAfter

    local uiGrid
    for i = 1, #self._Grids do
        local grid = self._Grids[i]
        if grid:IsPositionAndActive(gridX, gridY) then
            uiGrid = grid
            break
        end
    end
    if not uiGrid then
        XLog.Error(string.format("[XUiTemple2CheckBoard] 设置'相机'坐标失败, 找不到对应的格子(%s,%s)", gridX, gridY))
        return
    end

    gridPositionBefore = self:_GetPosition4Screen(uiGrid.Transform)
    --XLog.Debug("格子坐标:", a)

    contentPositionBefore = self:_GetPosition4Screen(self.Content)
    --XLog.Debug("content坐标:", b)

    local screen = CS.UnityEngine.Screen
    screenCenter = Vector2(screen.width / 2, screen.height / 2)
    --XLog.Debug("屏幕中心坐标:", c)

    contentPositionAfter = (screenCenter - gridPositionBefore) + contentPositionBefore
    --XLog.Debug("应该到的坐标:", d)

    ---@type UnityEngine.RectTransform
    local content = self.Content
    local parent = content.parent

    local hasValue, e = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(parent, contentPositionAfter, CS.XUiManager.Instance.UiCamera)
    if hasValue then
        content.localPosition = Vector3(e.x, e.y, 0)
        --XLog.Debug("转换后坐标:", e)
    end
end

function XUiTemple2CheckBoard:SetCameraPosAsync(gridX, gridY, time, callback)
    if not time or time == 0 or time == "0" then
        self:SetCameraPosSync(gridX, gridY)
        if callback then
            callback()
        end
        return
    end

    gridX = tonumber(gridX)
    gridY = tonumber(gridY)
    if time then
        time = tonumber(time)
    end

    -- A:格子 相对屏幕的坐标
    -- B:Content 相对屏幕的坐标
    -- C:中心点的屏幕坐标
    -- D:Content的目标屏幕坐标
    -- E = (C-A) + B 要把content移动到屏幕中央

    local gridPositionBefore, contentPositionBefore, screenCenter, contentPositionAfter

    local uiGrid
    for i = 1, #self._Grids do
        local grid = self._Grids[i]
        if grid:IsPositionAndActive(gridX, gridY) then
            uiGrid = grid
            break
        end
    end
    if not uiGrid then
        XLog.Error(string.format("[XUiTemple2CheckBoard] 设置'相机'坐标失败, 找不到对应的格子(%s,%s)", gridX, gridY))
        return
    end

    gridPositionBefore = self:_GetPosition4Screen(uiGrid.Transform)
    --XLog.Debug("格子坐标:", gridPositionBefore)

    contentPositionBefore = self:_GetPosition4Screen(self.Content)
    --XLog.Debug("content坐标:", contentPositionBefore)

    local screen = CS.UnityEngine.Screen
    screenCenter = Vector2(screen.width / 2, screen.height / 2)
    --XLog.Debug("屏幕中心坐标:", screenCenter)

    contentPositionAfter = (screenCenter - gridPositionBefore) + contentPositionBefore
    --XLog.Debug("应该到的坐标:", contentPositionAfter)

    ---@type UnityEngine.RectTransform
    local content = self.Content
    local parent = content.parent

    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(parent, contentPositionAfter, CS.XUiManager.Instance.UiCamera)
    if hasValue then
        --content.localPosition = point
        self._TweenStartPosition = content.localPosition
        self._TweenTargetPosition = Vector3(point.x, point.y, 0)
        --print("clamp 前:", self._TweenTargetPosition)
        self:ClampContentBoarder(self._TweenTargetPosition)
        --print("clamp 后:", self._TweenTargetPosition)
        self._TweenTime = 0
        self._TweenDuration = time

        if self._TimerTweenSetPos then
            XScheduleManager.UnSchedule(self._TimerTweenSetPos)
            self._TimerTweenSetPos = false
        end
        self._TimerTweenSetPos = XScheduleManager.ScheduleForever(function()
            self:_DoTweenSetCameraPosition(callback)
        end, 0)
    end
end

function XUiTemple2CheckBoard:_DoTweenSetCameraPosition(callback)
    self._TweenTime = self._TweenTime + CS.UnityEngine.Time.deltaTime
    local duration = self._TweenDuration
    local ratio
    if duration == 0 then
        ratio = 1
    else
        ratio = self._TweenTime / self._TweenDuration
    end

    local position = self._TweenStartPosition * (1 - ratio) + self._TweenTargetPosition * ratio

    ---@type UnityEngine.RectTransform
    local content = self.Content
    content.localPosition = position

    if ratio >= 1 then
        XScheduleManager.UnSchedule(self._TimerTweenSetPos)
        self._TimerTweenSetPos = false
        if callback then
            callback()
        end
    end
end

function XUiTemple2CheckBoard:SetBlockPos(gridX, gridY, time)
    gridX = tonumber(gridX)
    gridY = tonumber(gridY)
    --if self._OperationPos.x ~= gridX and self._OperationPos.y ~= gridY then
    --self:SetCameraPosAsync(gridX, gridY, time, function()
    self:SetOperationPos(gridX, gridY)
    -- 刷新一下特效位置
    self:GetOperationControl():SetPositionOfBlock2EditMap(gridX, gridY)
    self:GetOperationControl():UpdateScorePreview()
    self:UpdateBlockAndMap()
    --end)
    --else
    --    self:SetOperationPos(gridX, gridY)
    --end
end

function XUiTemple2CheckBoard:FocusCenter(x, y)
    if not self._TimerFocusCenter then
        self._TimerFocusCenter = XScheduleManager.ScheduleOnce(function()
            self:SetCameraPosSync(math.ceil(x / 2), math.ceil(y / 2))
            self._TimerFocusCenter = false
        end, 0)
    end
end

function XUiTemple2CheckBoard:CancelBlockFromGuide(gridX, gridY)
    self:CancelBlock(tonumber(gridX), tonumber(gridY))
end

function XUiTemple2CheckBoard:CancelBlock(gridX, gridY)
    local isValid, position = self:GetOperationControl():OnClickGrid(gridX, gridY)
    if isValid then
        self._OperationPos:Update(position.X, position.Y)
        self:UpdateBlockAndPreview()
        self:Update()
    end
end

-- 计算content在ViewPort内的范围
function XUiTemple2CheckBoard:ClampContentBoarder(position)
    local minX, maxX, minY, maxY

    local screen = CS.UnityEngine.Screen
    local screenWidth, screenHeight = screen.width, screen.height

    ---@type UnityEngine.RectTransform
    local content = self.Content
    local rect = content.rect
    local contentWidth, contentHeight = rect.width, rect.height

    minX = math.min(screenWidth - contentWidth, 0)
    maxX = 0

    minY = math.min(screenHeight - contentHeight, 0)
    maxY = 0

    position.x = XMath.Clamp(position.x, minX, maxX)
    position.y = XMath.Clamp(position.y, minY, maxY)
end

function XUiTemple2CheckBoard:StartTimerUpdatePreview()
    if self._TimerUpdatePreview then
        XScheduleManager.UnSchedule(self._TimerUpdatePreview)
        self._TimerUpdatePreview = false
    end
    if not self._TimerUpdatePreview then
        self._TimerUpdatePreview = XScheduleManager.ScheduleOnce(function()
            self:GetOperationControl():UpdateScorePreview()
            self:UpdateScorePreview()
            self._TimerUpdatePreview = false
        end, 200)
    end
end

function XUiTemple2CheckBoard:StartTimerUpdateMap()
    if self._TimerUpdateMap then
        XScheduleManager.UnSchedule(self._TimerUpdateMap)
        self._TimerUpdateMap = false
    end
    if not self._TimerUpdateMap then
        self._TimerUpdateMap = XScheduleManager.ScheduleOnce(function()
            self:Update()
            self._TimerUpdateMap = false
        end, 400)
    end
end

return XUiTemple2CheckBoard