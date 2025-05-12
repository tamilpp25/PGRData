local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiConnectingLineGameAvatar = require("XUi/XUiConnectingLine/XUiConnectingLineGameAvatar")
--local XUiConnectingLineBubble = require("XUi/XUiConnectingLine/XUiConnectingLineBubble")
local XConnectingLineOperation = require("XModule/XConnectingLine/XEntity/XConnectingLineOperation")
local XUiConnectingLineGameGrid = require("XUi/XUiConnectingLine/XUiConnectingLineGameGrid")
local XUiConnectingLineGameChapterGrid = require("XUi/XUiConnectingLine/XUiConnectingLineGameChapterGrid")
local XRedPointConditionConnectingLine = require("XRedPoint/XRedPointConditions/XRedPointConditionConnectingLine")
local OPERATION_TYPE = XEnumConst.CONNECTING_LINE.OPERATION_TYPE

---@field private _Control XConnectingLineControl
---@class XUiConnectingLineGame:XLuaUi
local XUiConnectingLineGame = XLuaUiManager.Register(XLuaUi, "UiConnectingLineGame")

function XUiConnectingLineGame:Ctor()
    ---@type  XUiComponent.XUiLineRenderer
    self._LineNormal = {}

    ---@type  XUiComponent.XUiLineRenderer
    self._LineEnable = {}

    ---@type XUiConnectingLineGameAvatar[][]
    self._Avatars = {}

    ---@type XUiConnectingLineGameGrid[]
    self._GridList = {}

    ---@type XUiGridCommon[]
    self._GridRewardList = {}

    ---@type XUiConnectingLineBubble
    --self._Bubble = false

    self._Timer = false

    self._IsCanPlayAnimationInfoChanged = false

    self._ChapterList = {}
    ---@type XConnectingLineChapterData[]
    self._DataChapters = {}

    ---@type XUiConnectingLineGameChapterGrid[]
    self._StageList = {}
end

function XUiConnectingLineGame:OnAwake()
    local itemId = self._Control:GetCoinItemId()
    if itemId then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId)
        self.PanelAsset.gameObject:SetActiveEx(true)
    else
        self.PanelAsset.gameObject:SetActiveEx(false)
    end

    self:BindHelpBtn(self.BtnHelp, XEnumConst.CONNECTING_LINE.HELP_KEY)

    self.LineNormal.gameObject:SetActiveEx(false)
    self.LineEnable.gameObject:SetActiveEx(false)
    -- 背景grid
    self.GridBoard.gameObject:SetActiveEx(false)
    -- 头像背景grid
    self.GridBoardHead.gameObject:SetActiveEx(false)
    -- 头像
    self.GridHead.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActive(false)

    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end, nil, true)

    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBack)

    self:AddListenerInput()
    XUiHelper.RegisterClickEvent(self, self.ButtonReset, self.OnClickReset)
    --XUiHelper.RegisterClickEvent(self, self.ButtonStart, self.OnClickStart)
    XUiHelper.RegisterClickEvent(self, self.ButtonFinish, self.OnClickFinish)
    XUiHelper.RegisterClickEvent(self, self.PanelFinish, self.OnClickFinish)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnClickTask)

    self.BtnChapter.gameObject:SetActiveEx(false)

    self.PanelChapter.gameObject:SetActive(true)
    self._StageList = {
        XUiConnectingLineGameChapterGrid.New(self.ChapterGrid1, self),
        XUiConnectingLineGameChapterGrid.New(self.ChapterGrid2, self),
        XUiConnectingLineGameChapterGrid.New(self.ChapterGrid3, self),
        XUiConnectingLineGameChapterGrid.New(self.ChapterGrid4, self),
        --XUiConnectingLineGameChapterGrid.New(self.ChapterGrid5, self),
    }
end

function XUiConnectingLineGame:OnStart()
    if not self._Control:IsActivityOpen() then
        self:Close()
        XUiManager.TipText("CommonActivityNotStart")
        return
    end
    self._Control:InitStage()
    --self:InitBubble()
end

function XUiConnectingLineGame:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CONNECTING_LINE_NEXT_STAGE, self.OnNextStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE, self.OnResetStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_CONNECTING_LINE_UPDATE, self.UpdateByUiStatus, self)

    if not self._Control:IsActivityOpen() then
        return
    end

    --self:UpdateByUiStatus()
    self:UpdateChapterBtnGroup()
    self:UpdateTaskRedPoint()
    self:UpdateTime()
    self:StartTimer()

    local index = 1
    for i = #self._DataChapters, 1, -1 do
        local chapter = self._DataChapters[i]
        if chapter.IsUnlock then
            index = i
            break
        end
    end
    self.ChapterBtnList:SelectIndex(index)
    self._IsCanPlayAnimationInfoChanged = true
    self:UpdateChapterBtn()
end

function XUiConnectingLineGame:OnDisable()
    -- 预先close, 否则在切换任务界面后回来, 触发uiNode.active检测报错
    for i = 1, #self._GridList do
        local grid = self._GridList[i]
        grid:Close()
    end
    for i, avatars in pairs(self._Avatars) do
        for j, avatar in pairs(avatars) do
            avatar:Hide()
        end
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_CONNECTING_LINE_NEXT_STAGE, self.OnNextStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE, self.OnResetStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CONNECTING_LINE_UPDATE, self.UpdateByUiStatus, self)
    self:StopTimer()
end

function XUiConnectingLineGame:InitGame()
    -- todo by zlb 添加 luaGen
    ---@type UnityEngine.RectTransform
    local grid = self.GridHead
    local gridSize = grid.rect.size
    self._Control:InitGame(gridSize.x, gridSize.y)
    self:SetUiGrids()
    self:UpdateBackgroundSize()
end

function XUiConnectingLineGame:UpdatePainting()
    local game = self._Control:GetGame()
    local bufferList = game:GetBuffer()
    local lineCountNormal = 0
    local lineCountEnable = 0

    --region 由于grid的x，y坐标以中心为锚点， 故line坐标需转换
    ---@type UnityEngine.RectTransform
    local panelGrid = self.GridHead
    local gridSize = panelGrid.rect.size
    local gridLayoutGroup = self.BgGridLayout
    local rectTransform = gridLayoutGroup:GetComponent("RectTransform")
    local rect = rectTransform.rect
    local boardHeight = rect.height
    local offset = { X = -gridSize.x / 2, Y = boardHeight - gridSize.y / 2 }
    --endregion

    for i = 1, #bufferList do
        local buffer = bufferList[i]
        local lineDataList = buffer:GetLine()
        local isLineEnable = buffer:IsLinked()
        for j = 1, #lineDataList do
            local line
            if isLineEnable then
                lineCountEnable = lineCountEnable + 1
                line = self:GetLine(lineCountEnable, isLineEnable)
            else
                lineCountNormal = lineCountNormal + 1
                line = self:GetLine(lineCountNormal, isLineEnable)
            end

            local lineData = lineDataList[j]
            local pointCount = #lineData
            line:SetPositionCount(pointCount)
            line.gameObject:SetActiveEx(true)
            local hexColor = buffer:GetLineColor()
            local color = XUiHelper.Hexcolor2Color(hexColor)
            line:SetColor(color)
            for k = 1, pointCount do
                local point = lineData[k]
                line:SetPosition(k - 1, point.X + offset.X, point.Y + offset.Y)
            end
        end
    end

    -- 隐藏没用到的line
    for i = lineCountNormal + 1, #self._LineNormal do
        local line = self._LineNormal[i]
        if line then
            line.gameObject:SetActiveEx(false)
        end
    end
    for i = lineCountEnable + 1, #self._LineEnable do
        local line = self._LineEnable[i]
        if line then
            line.gameObject:SetActiveEx(false)
        end
    end

    -- 从color转成图片
    local lightGridBgMap = {}
    for i = 1, #bufferList do
        ---@type XConnectingLineGridBuffer
        local buffer = bufferList[i]
        if buffer:IsLinked() then
            local grids = buffer:GetGrids()
            for j = 1, #grids do
                local grid = grids[j]
                lightGridBgMap[grid:GetPosUid()] = buffer:GetHeadGrid():GetGridBg()
            end
        else
            local headGrid = buffer:GetHeadGrid()
            if headGrid then
                lightGridBgMap[headGrid:GetPosUid()] = headGrid:GetGridBg()
            end
        end
    end

    for i = 1, #self._GridList do
        local uiGrid = self._GridList[i]
        local gridBg = lightGridBgMap[uiGrid:GetPosUid()]
        local pos = uiGrid:GetPos()
        local avatar = self:GetAvatar(pos)
        if gridBg then
            uiGrid:SetConnected(true)
            --uiGrid:SetColor(color)
            uiGrid:SetGridBg(gridBg)
            if avatar then
                avatar:SetConnected(true)
            end
        else
            uiGrid:SetConnected(false)
            if avatar then
                avatar:SetConnected(false)
            end
        end
    end
end

function XUiConnectingLineGame:GetLine(index, isEnable)
    local pool = isEnable and self._LineEnable or self._LineNormal
    local line = pool[index]
    if not line then
        local uiLine = isEnable and self.LineEnable or self.LineNormal
        line = CS.UnityEngine.GameObject.Instantiate(uiLine, uiLine.gameObject.transform.parent)
        pool[index] = line
        line:SetPositionCount(0)
        line.gameObject:SetActiveEx((true))
    end
    return line
end

function XUiConnectingLineGame:SetUiAvatar()
    for i, avatars in pairs(self._Avatars) do
        for j, avatar in pairs(avatars) do
            avatar:Hide()
        end
    end

    local game = self._Control:GetGame()
    local map = game:GetAvatarMap()
    local gridSize = game:GetGridSize()
    for column = 1, #map do
        local array = map[column]
        for row = 1, #array do
            ---@type XConnectingLineGrid
            local grid = array[row]
            local avatarId = grid:GetAvatarId()
            if avatarId > 0 then
                local avatar = self._Avatars[column] and self._Avatars[column][row]
                if not avatar then
                    ---@type UnityEngine.RectTransform
                    local uiAvatar = CS.UnityEngine.Object.Instantiate(self.GridHead, self.GridHead.gameObject.transform.parent)
                    uiAvatar.gameObject:SetActiveEx(true)
                    ---@type UnityEngine.RectTransform
                    local uiAvatarBoard = CS.UnityEngine.Object.Instantiate(self.GridBoardHead, self.GridBoardHead.gameObject.transform.parent)
                    uiAvatarBoard.gameObject:SetActiveEx(true)

                    ---@type XUiConnectingLineGameAvatar
                    avatar = XUiConnectingLineGameAvatar.New(uiAvatar, self)
                    avatar:SetUiGridBoardHead(uiAvatarBoard)

                    self._Avatars[column] = self._Avatars[column] or {}
                    self._Avatars[column][row] = avatar
                end

                local posUi = grid:GetPosUI()
                local x = posUi.X
                local y = posUi.Y
                avatar:SetPosition(x, y)

                local avatarIcon = grid:GetAvatarIcon()
                local headBgIcon = grid:GetHeadBg()
                avatar:Update(avatarIcon, headBgIcon)
                avatar:Show()
            end
        end
    end
end

function XUiConnectingLineGame:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

function XUiConnectingLineGame:OnDestroy()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:RemoveAllListeners()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiConnectingLineGame:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelDrag.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    x = x + transform.rect.width / 2
    y = y - transform.rect.height / 2
    return x, y
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiConnectingLineGame:OnBeginDrag(eventData)
    local game = self._Control:GetGame()

    ---@type XConnectingLineOperation
    local operation = XConnectingLineOperation.New()
    local x, y = self:GetPosByEventData(eventData)
    operation:SetPos(x, y)
    operation.Type = OPERATION_TYPE.POINT_DOWN
    game:Execute(operation)
    self:UpdatePainting()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiConnectingLineGame:OnDrag(eventData)
    local game = self._Control:GetGame()

    ---@type XConnectingLineOperation
    local operation = XConnectingLineOperation.New()
    local x, y = self:GetPosByEventData(eventData)
    operation:SetPos(x, y)
    operation.Type = OPERATION_TYPE.POINT_MOVE
    game:Execute(operation)
    self:UpdatePainting()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiConnectingLineGame:OnEndDrag(eventData)
    local game = self._Control:GetGame()

    ---@type XConnectingLineOperation
    local operation = XConnectingLineOperation.New()
    local x, y = self:GetPosByEventData(eventData)
    operation:SetPos(x, y)
    operation.Type = OPERATION_TYPE.POINT_UP
    game:Execute(operation)
    self:UpdatePainting()
    self:CheckFinish()
    self:UpdateGameInfo()
    self:ResetAnimation()
end

function XUiConnectingLineGame:SetUiGrids()
    local game = self._Control:GetGame()
    local map = game:GetAvatarMap()
    local count = 0
    for column = 1, #map do
        local grids = map[column]
        for row = 1, #grids do
            count = count + 1

            local uiGrid = self._GridList[count]
            if not uiGrid then
                local object = CS.UnityEngine.Object.Instantiate(self.GridBoard, self.GridBoard.gameObject.transform.parent)
                uiGrid = XUiConnectingLineGameGrid.New(object, self)
                self._GridList[count] = uiGrid
            end
            local grid = grids[row]
            uiGrid:SetPos(column, row, grid:GetPosUid())
            uiGrid:SetConnected(false)
            if grid:IsHole() then
                local holdImg = grid:GetAvatarIcon()
                uiGrid:SetGridBg(holdImg)
                uiGrid:SetIsHole(true)
            else
                uiGrid:SetIsHole(false)
            end
            uiGrid:Open()
            -- 因为使用了GridLayout, 会自动根据顺序排序
            ---@type UnityEngine.RectTransform
            local transform = uiGrid.Transform
            transform:SetSiblingIndex(count)
        end
    end
    for i = count + 1, #self._GridList do
        local grid = self._GridList[i]
        grid:Close()
        grid:Clear()
    end
end

function XUiConnectingLineGame:UpdateInfo()
    self._Control:Update()
    --local uiData = self._Control:GetUiData()
    --self.ImageBody:SetRawImage(uiData.BodyPicture)
    --if uiData.HairPicture then
    --    self.ImageHair.gameObject:SetActiveEx(true)
    --    self.ImageHair:SetRawImage(uiData.HairPicture)
    --else
    --    self.ImageHair.gameObject:SetActiveEx(false)
    --end
    self:UpdateReward()
    self:UpdateGameInfo()
    self:UpdateStageProgress()
end

function XUiConnectingLineGame:UpdateGameInfo()
    self._Control:UpdateGameInfo()
    local uiData = self._Control:GetUiData()
    local isInfoChanged = false
    if self.TextGrid.text ~= uiData.TextLightGrid then
        self.TextGrid.text = uiData.TextLightGrid
        isInfoChanged = true
    end
    if self.TextCharacter.text ~= uiData.TextLink then
        self.TextCharacter.text = uiData.TextLink
        isInfoChanged = true
    end
    -- 信息变化
    if self._IsCanPlayAnimationInfoChanged and isInfoChanged then
        self:PlayAnimation("TextTips")
    end
    --if uiData.PlayAnimationGridLoop then
    --    self:PlayAnimation("TextTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    --else
    --    self:StopAnimation("TextTipsLoop")
    --end

    ---@type XUiComponent.XUiButton
    local buttonReset = self.ButtonReset
    if uiData.IsEnableReset then
        buttonReset:SetButtonState(CS.UiButtonState.Normal)
    else
        buttonReset:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiConnectingLineGame:UpdateTime()
    self._Control:UpdateTime()
    local uiData = self._Control:GetUiData()
    self.TextTime.text = uiData.TextTime
end

function XUiConnectingLineGame:UpdateStageProgress()
    local uiData = self._Control:GetUiData()
    self.TextStageName.text = uiData.TextStageName
    self.TextReward.text = uiData.TextReward
end

function XUiConnectingLineGame:UpdateReward()
    local uiData = self._Control:GetUiData()
    local rewardList = uiData.Reward
    for i, item in ipairs(rewardList) do
        local grid = self._GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward, self.GridReward.parent)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self._GridRewardList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
        grid:SetReceived(uiData.IsRewardReceived)
    end
    for i = #rewardList + 1, #self._GridRewardList do
        local reward = self._GridRewardList[i]
        reward.GameObject:SetActiveEx(false)
    end
end

function XUiConnectingLineGame:OnClickReset()
    ---@type XUiComponent.XUiButton
    local button = self.ButtonReset
    if button.ButtonState == CS.UiButtonState.Normal then
        local callback = function()
            XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE)
        end
        XUiManager.DialogTip(XUiHelper.GetText("ConnectingLineReset1"), XUiHelper.GetText("ConnectingLineReset2"), nil, nil, callback)
    end
end

--function XUiConnectingLineGame:OnClickStart()
--    if self._Control:IsCanStartGame() then
--        self._Control:RequestStartGame()
--        return true
--    end
--    XUiManager.TipMsg(XUiHelper.GetText("ConnectingLineMoney"))
--    return false
--end

function XUiConnectingLineGame:OnClickFinish()
end

function XUiConnectingLineGame:StartGame()
    self:InitGame()
    self:SetUiAvatar()
    self:UpdatePainting()
    self:UpdateInfo()
end

function XUiConnectingLineGame:SetEmpty()
    self:InitGame()
    self:ClearBoard()
    self:SetUiAvatar()
    self:UpdatePainting()
    self:UpdateInfo()
end

--function XUiConnectingLineGame:ShowPanelStart()
--    self.PanelStart.gameObject:SetActiveEx(true)
--    local uiData = self._Control:GetUiData()
--    self.IconMoney1:SetRawImage(uiData.IconMoney)
--    self.TextMoney1.text = uiData.TextMoney
--end

--function XUiConnectingLineGame:HidePanelStart()
--    self.PanelStart.gameObject:SetActiveEx(false)
--end

--function XUiConnectingLineGame:ShowPanelFinish()
--    self.PanelFinish.gameObject:SetActiveEx(true)
--end

--function XUiConnectingLineGame:HidePanelFinish()
--    self.PanelFinish.gameObject:SetActiveEx(false)
--end

function XUiConnectingLineGame:ShowPanelNextStage()
    --XLuaUiManager.Open("UiConnectingLineReward")
    self._Control:RequestReward()
end

function XUiConnectingLineGame:CheckFinish()
    local game = self._Control:GetGame()
    if game:GetFinishState() == XEnumConst.CONNECTING_LINE.FINISH_STATE.PERFECT_COMPLETE then
        if self._Control:IsLastStage() then
            self:ClearBoard()
            --else
            --XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.FINISH)
        end
        if not game:HasRequested() then
            self._Control:RequestFinish()
        end
        -- 直接领奖
        --self._Control:RequestReward()
    end
end

function XUiConnectingLineGame:OnNextStage()
    --self:ShowPanelStart()
    self:StartGame()
end

function XUiConnectingLineGame:OnResetStage()
    self:StartGame()
end

function XUiConnectingLineGame:UpdateByGameStatus()
    local status = self._Control:GetStatus()
    if status == XEnumConst.CONNECTING_LINE.STAGE_STATUS.LOCK then
        --self:HidePanelFinish()
        self:StartGame()
        --self:ShowPanelStart()
        --XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.OPEN)
        return
    end
    if status == XEnumConst.CONNECTING_LINE.STAGE_STATUS.UNLOCK then
        --self:HidePanelFinish()
        --self:HidePanelStart()
        self:StartGame()
        return
    end
    if status == XEnumConst.CONNECTING_LINE.STAGE_STATUS.COMPLETE then
        if not self._Control:IsGameInit() then
            self:StartGame()
        end
        --self:HidePanelFinish()
        self:ShowPanelNextStage()
        return
    end
    if status == XEnumConst.CONNECTING_LINE.STAGE_STATUS.REWARD then
        --self:ShowPanelFinish()

        if self._Control:IsLastStage() then
            self:SetEmpty()
            --XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.FINISH_ALL)
        else
            if not self._Control:IsGameInit() then
                self:StartGame()
            end
            self:UpdateInfo()
        end
        return
    end
end

--function XUiConnectingLineGame:InitBubble()
--self.PanelBubble.gameObject:SetActiveEx(true)
--self._Control:InitBubble()
--local uiData = self._Control:GetUiData()
--self._Bubble = XUiConnectingLineBubble.New(self.PanelCharacter, self)
--self._Bubble:SetBubbleDataSource(uiData.BubbleDataSource)
--XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.DEFAULT)
--end

function XUiConnectingLineGame:StartTimer()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()

            -- kick out
            if not self._Control:IsActivityOpen() then
                XUiManager.TipText("CommonActivityNotStart")
                self:Close()
                return
            end

            self:UpdateChapterBtn()

        end, XScheduleManager.SECOND)
    end
end

function XUiConnectingLineGame:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiConnectingLineGame:UpdateBackgroundSize()
    local game = self._Control:GetGame()
    local column = game:GetColumn()
    ---@type UnityEngine.UI.GridLayoutGroup
    local gridLayoutGroup = self.BgGridLayout
    gridLayoutGroup.constraintCount = column

    ---@type UnityEngine.RectTransform
    local rectTransform = gridLayoutGroup:GetComponent("RectTransform")
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform)
    local rect = rectTransform.rect
    local width = rect.width
    local height = rect.height

    local enumHorizontal = CS.UnityEngine.RectTransform.Axis.Horizontal
    local enumVertical = CS.UnityEngine.RectTransform.Axis.Vertical

    ---@type UnityEngine.RectTransform
    local panel = self.Panel
    panel:SetSizeWithCurrentAnchors(enumHorizontal, width)
    panel:SetSizeWithCurrentAnchors(enumVertical, height)

    local imageBoard = self.ImageBoard
    imageBoard:SetSizeWithCurrentAnchors(enumHorizontal, width)
    imageBoard:SetSizeWithCurrentAnchors(enumVertical, height)

    ---@type UnityEngine.RectTransform
    --local panelStart = self.PanelStart
    --panelStart:SetSizeWithCurrentAnchors(enumHorizontal, width)
    --panelStart:SetSizeWithCurrentAnchors(enumVertical, height)

    ---@type UnityEngine.RectTransform
    --local panelFinish = self.PanelFinish
    --panelFinish:SetSizeWithCurrentAnchors(enumHorizontal, width)
    --panelFinish:SetSizeWithCurrentAnchors(enumVertical, height)

    ---@type UnityEngine.RectTransform
    local panelCanvas1 = self.Canvas1
    panelCanvas1:SetSizeWithCurrentAnchors(enumHorizontal, width)
    panelCanvas1:SetSizeWithCurrentAnchors(enumVertical, height)

    self.Canvas1.gameObject:SetActiveEx(true)
    self.Canvas2.gameObject:SetActiveEx(true)
    self.Canvas3.gameObject:SetActiveEx(true)

    for i = 1, #self._GridList do
        local uiGrid = self._GridList[i]
        local pos = uiGrid:GetPos()
        local grid = game:GetGrid(pos.X, pos.Y)
        if grid then
            local x, y = uiGrid:GetPosUi()
            grid:SetPosUi(x, y)
        end
    end
end

function XUiConnectingLineGame:GetAvatar(pos)
    local x = pos.X
    local y = pos.Y
    if self._Avatars[x] then
        return self._Avatars[x][y]
    end
    return false
end

function XUiConnectingLineGame:ResetAnimation()
    for i = 1, #self._GridList do
        local uiGrid = self._GridList[i]
        uiGrid:ResetAnimation()
    end
end

function XUiConnectingLineGame:ClearBoard()
    local game = self._Control:GetGame()
    game:ClearBoard()
end

function XUiConnectingLineGame:UpdateByUiStatus()
    local uiStatus = self._Control:GetUiStatus()
    local STATUS = XEnumConst.CONNECTING_LINE.UI_STATUS
    if uiStatus == STATUS.CHAPTER then
        self.PanelChapter.gameObject:SetActiveEx(true)
        self.ChapterList.gameObject:SetActiveEx(true)
        --self.ChapterCG.gameObject:SetActiveEx(false)
        self.PanelGame.gameObject:SetActiveEx(false)
        if self.PanelChapterList then
            self.PanelChapterList.gameObject:SetActiveEx(true)
        end
        self:UpdateChapterBtnGroup()
        self._Control:UpdateMoney()

        if self._Control:IsChapterPassed() then
            self.ChapterList.gameObject:SetActiveEx(false)
            self.RImgCG:SetRawImage(self._Control:GetChapterCG())
            self.RImgCG.gameObject:SetActiveEx(true)
        else
            self.ChapterList.gameObject:SetActiveEx(true)
            self.RImgCG.gameObject:SetActiveEx(false)
        end
        self:UpdateStageList()
        return
    end
    if uiStatus == STATUS.GAME then
        self.PanelChapter.gameObject:SetActiveEx(false)
        self.ChapterList.gameObject:SetActiveEx(false)
        --self.ChapterCG.gameObject:SetActiveEx(false)
        self.PanelGame.gameObject:SetActiveEx(true)
        if self.PanelChapterList then
            self.PanelChapterList.gameObject:SetActiveEx(false)
        end
        self:UpdateByGameStatus()
        return
    end
    --if uiStatus == STATUS.CG then
    --    self.PanelChapter.gameObject:SetActiveEx(true)
    --    self.ChapterList.gameObject:SetActiveEx(false)
    --    self.ChapterCG.gameObject:SetActiveEx(true)
    --    self.PanelGame.gameObject:SetActiveEx(false)
    --    return
    --end
end

function XUiConnectingLineGame:UpdateChapterBtnGroup()
    ---@type XConnectingLineChapterData[]
    local chapters = self._Control:GetChapterList()
    self._DataChapters = chapters

    for i = 1, #chapters do
        ---@type XUiComponent.XUiButton
        local btn = self._ChapterList[i]
        if not btn then
            btn = CS.UnityEngine.GameObject.Instantiate(self.BtnChapter, self.BtnChapter.transform.parent)
            self._ChapterList[i] = btn
            -- 默认隐藏
            btn:SetNameByGroup(1, "")
        end
        local chapter = chapters[i]
        btn:SetNameByGroup(0, chapter.Name)
        btn.gameObject:SetActiveEx(true)

        if not chapter.IsUnlock then
            btn:SetButtonState(CS.UiButtonState.Disable)
        else
            if btn.ButtonState == CS.UiButtonState.Disable then
                btn:SetButtonState(CS.UiButtonState.Normal)
            end
        end
        btn:ShowReddot(chapter.IsShowRed)
    end
    ---@type XUiButtonGroup
    local btnGroup = self.ChapterBtnList
    btnGroup:InitBtns(self._ChapterList, function(index)
        self:OnClickChapter(index)
    end)
end

function XUiConnectingLineGame:UpdateStageList()
    ---@type XConnectingLineStageData[]
    local stageList = self._Control:GetStageList()
    -- 5 是因为ui固定5个
    for i = 1, 5 do
        local ui = self._StageList[i]
        if ui then
            local data = stageList[i]
            if data then
                ui:Open()
                ui:Update(data)
            else
                ui:Close()
            end
        end
    end
end

local function ConvertTimestampToFormattedDate(timestamp)
    return os.date("%Y/%m/%d   %H:%M", timestamp)
end

function XUiConnectingLineGame:OnClickChapter(index)
    local chapter = self._DataChapters[index]
    if chapter then
        if chapter.IsUnlock then
            self._Control:SetChapterId(chapter.ChapterId)
            self:UpdateByUiStatus()
            self:PlayAnimation("QieHuan")
        else
            if not chapter.IsInTime then
                local timeId = chapter.TimeId
                local openTime = XFunctionManager.GetStartTimeByTimeId(timeId)
                local str = ConvertTimestampToFormattedDate(openTime)
                XUiManager.TipMsg(XUiHelper.GetText("ConnectingLineUnlockTime", str))
            else
                XUiManager.TipText("BfrtChapterUnlockCondition")
            end
        end
    end
end

function XUiConnectingLineGame:OnClickTask()
    XLuaUiManager.Open("UiConnectingLineTableTask")
end

function XUiConnectingLineGame:UpdateTaskRedPoint()
    if self.BtnTask then
        self.BtnTask:ShowReddot(XRedPointConditionConnectingLine.CheckTask())
    end
end

function XUiConnectingLineGame:OnClickBack()
    if self._Control:IsPlaying() then
        self._Control:SetUiStatus(XEnumConst.CONNECTING_LINE.UI_STATUS.CHAPTER)
        return
    end
    self:Close()
end

-- 需要在章节列表显示上锁的倒计时，倒计时结束，可自动开放章节。
function XUiConnectingLineGame:UpdateChapterBtn()
    local isAllInTime = true
    for i = 1, #self._DataChapters do
        local chapter = self._DataChapters[i]
        self._Control:UpdateChapterData(chapter)
        if not chapter.IsInTime then
            isAllInTime = false
        end
    end
    if isAllInTime then
        return
    end

    for i = 1, #self._ChapterList do
        local btn = self._ChapterList[i]
        local chapter = self._DataChapters[i]
        if chapter then
            btn:ShowReddot(chapter.IsShowRed)
            -- 只处理 isInTime
            if chapter.IsInTime and chapter.IsUnlock then
                if btn.ButtonState == CS.UiButtonState.Disable then
                    btn:SetButtonState(CS.UiButtonState.Normal)
                end
            else
                btn:SetButtonState(CS.UiButtonState.Disable)
                local timeId = chapter.TimeId
                local openTime = XFunctionManager.GetStartTimeByTimeId(timeId)
                local currentTime = XTime.GetServerNowTimestamp()
                local remainTime = openTime - currentTime
                if remainTime > 0 then
                    btn:SetNameByGroup(1, XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
                else
                    btn:SetNameByGroup(1, "")
                end
            end
        else
            XLog.Error("XUiConnectingLineGame:UpdateChapterBtn() chapter is nil")
        end
    end
end

return XUiConnectingLineGame
