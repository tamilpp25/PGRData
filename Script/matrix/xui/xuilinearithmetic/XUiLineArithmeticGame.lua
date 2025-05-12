local XUiLineArithmeticGameGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticGameGrid")
local XUiLineArithmeticGameEventGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticGameEventGrid")
local XUiLineArithmeticGameStarGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticGameStarGrid")

---@class XUiLineArithmeticGame : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticGame = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticGame")

function XUiLineArithmeticGame:Ctor()
    ---@type XUiLineArithmeticGameGrid[]
    self._UiGrids = {}

    ---@type XUiLineArithmeticGameGrid[]
    self._DictUiGrids = {}

    self._DictUiLine = {}

    self._UiLines = {}

    self._TimerGame = false

    ---@type XLineArithmeticAnimation
    self._CurrentAnimation = false

    ---@type XLinArithmeticAnimationNumberScrollData[]
    self._NumberScrollData = {}

    ---@type XUiLineArithmeticGameEventGrid[]
    self._EventGrids = {}

    ---@type XUiLineArithmeticGameStarGrid[]
    self._StarGrids = {}

    -- 为了特效的播放频率一致
    self._EffectTime = 0
    self._DurationGridSelectedEffect = 1
end

function XUiLineArithmeticGame:OnAwake()
    self:BindExitBtns()
    self.BtnGrid.gameObject:SetActiveEx(false)
    self.GridLine.gameObject:SetActiveEx(false)
    self.GridProp.gameObject:SetActiveEx(false)
    self.GridTarget.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnClickReset)
    XUiHelper.RegisterClickEvent(self, self.BtnSettlement, self.OnClickManualSettle)

    ---@type XGoInputHandler
    local goInputHandler = self.PanelTouch
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)

    --self:BindHelpBtn(self.BtnHelp, "LineArithmeticHelp")
    self:RegisterClickEvent(self.BtnHelp, self.OnClickTip)
    XUiHelper.RegisterClickEvent(self, self.BtnTips, self.OnClickHelp)
end

function XUiLineArithmeticGame:OnStart()
    self._Control:StartGame()
    -- 只在一开始更新一次
    self:UpdateEmptyGrid()
    self:UpdateTipsBtn()
end

function XUiLineArithmeticGame:OnEnable()
    self:Update()
    if not self._TimerGame then
        self._TimerGame = XScheduleManager.ScheduleForever(function()
            self:UpdateGame()
        end, 0, 0)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_LINE, self.UpdateLine, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME, self.UpdateFromEvent, self)

    self._Control:SetCurrentGameStageId()
end

function XUiLineArithmeticGame:OnDisable()
    if self._TimerGame then
        XScheduleManager.UnSchedule(self._TimerGame)
        self._TimerGame = false
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_LINE, self.UpdateLine, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME, self.UpdateFromEvent, self)

    self._Control:ClearCurrentGameStageId()
end

function XUiLineArithmeticGame:UpdateFromEvent()
    self:Update()
    self:UpdateTipsBtn()
end

function XUiLineArithmeticGame:Update()
    self:UpdateMap()
    self:UpdateEventGridDesc()
    self:UpdateTitle()
end

function XUiLineArithmeticGame:UpdateMap()
    self._Control:UpdateMap()
    local uiData = self._Control:GetUiData()

    -- 画格子
    local map = uiData.MapData
    if not map then
        return
    end
    for i = 1, #map do
        local dataGrid = map[i]
        local uiGrid = self._UiGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.BtnGrid, self.BtnGrid.transform.parent)
            uiGrid = XUiLineArithmeticGameGrid.New(ui, self)
            self._UiGrids[i] = uiGrid
        end
        self._DictUiGrids[dataGrid.Uid] = uiGrid
        uiGrid:Update(dataGrid, self._EffectTime)
        uiGrid:Open()
    end
    for i = #map + 1, #self._UiGrids do
        local uiGrid = self._UiGrids[i]
        uiGrid:Close()
    end
    self:UpdateLine()
    self:UpdateStarTarget()
    self:UpdateResetButton()

    if uiData.IsCanManualSettle then
        self.BtnSettlement:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnSettlement:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiLineArithmeticGame:UpdateLine(lineCurrent)
    self._Control:UpdateLine(lineCurrent)
    local uiData = self._Control:GetUiData()

    -- 画线
    local line = uiData.LineData
    if not line then
        return
    end
    for i = 1, #line do
        local dataLine = line[i]
        local uiLine = self._UiLines[i]
        if not uiLine then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridLine, self.GridLine.transform.parent)
            uiLine = ui
            self._UiLines[i] = uiLine
        end
        uiLine.gameObject:SetActiveEx(true)
        self._DictUiLine[dataLine.Index] = uiLine
        local x = dataLine.X
        local y = dataLine.Y
        local rotation = dataLine.Rotation
        ---@type UnityEngine.RectTransform
        local rectTransform = uiLine
        rectTransform.localPosition = Vector3(x, y, 0)
        rectTransform.localEulerAngles = Vector3(0, 0, rotation)
    end
    for i = #line + 1, #self._UiLines do
        local uiLine = self._UiLines[i]
        uiLine.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmeticGame:OnDestroy()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelTouch
    goInputHandler:RemoveAllListeners()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmeticGame:OnBeginDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    local x, y = self:GetPosByEventData(eventData)
    self._Control:SetTouchPosOnBegin(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmeticGame:OnDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    local x, y = self:GetPosByEventData(eventData)
    self._Control:SetTouchPosOnDrag(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmeticGame:OnEndDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    self._Control:ConfirmTouch()
    self._Control:ClearTouchPos()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmeticGame:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelTouch.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiLineArithmeticGame:UpdateGame()
    local deltaTime = CS.UnityEngine.Time.deltaTime
    self._EffectTime = self._EffectTime + deltaTime
    if self._EffectTime > self._DurationGridSelectedEffect then
        self._EffectTime = self._EffectTime % self._DurationGridSelectedEffect
    end
    --if self._Control:UpdateGame() then
    --    self:UpdateMap()
    --end

    if self:IsPlayingAnimation() then
        if self._CurrentAnimation:IsFinish() and not self:IsPlayingNumberScroll() then
            if self._Control:IsRequesting() then
                return
            end
            self._CurrentAnimation = false
            self:UpdateMap()
            self._Control:CheckFinish()
        else
            self._CurrentAnimation:Update(self, deltaTime)
        end
    else
        if self._Control:UpdateGame() then
            local animation = self._Control:GetAnimation()
            if animation then
                self._CurrentAnimation = animation
            else
                self:UpdateMap()
                self._Control:CheckFinish()
            end
        end
    end

    self:UpdateNumberScroll()
end

function XUiLineArithmeticGame:OnClickReset()
    if not self._Control:IsGameDirty() then
        return
    end
    XLuaUiManager.Open("UiLineArithmeticTargetPopupTips", function()
        self._Control:OnClickReset()
        self._CurrentAnimation = false
        self._NumberScrollData = {}
        self._DictUiGrids = {}
        self._DictUiLine = {}
        self:Update()
        self:UpdateTipsBtn()
    end)
end

---@return XUiLineArithmeticGameGrid
function XUiLineArithmeticGame:GetUiGridByUid(uid)
    return self._DictUiGrids[uid]
end

function XUiLineArithmeticGame:GetUiLineByIndex(index)
    return self._DictUiLine[index]
end

function XUiLineArithmeticGame:HideUiLineByIndex(index)
    local line = self:GetUiLineByIndex(index)
    if line then
        line.gameObject:SetActiveEx(false)
    else
        XLog.Error("[XLineArithmeticAnimation] 移除箭头失败:", self._ArrowIndex)
    end
end

function XUiLineArithmeticGame:RemoveOverLineByIndex(index)
    if not index then
        XLog.Error("[XUiLineArithmeticGame] index为空")
        return
    end
    for i, uiLine in pairs(self._DictUiLine) do
        if i > index then
            uiLine.gameObject:SetActiveEx(false)
        end
    end
end

---@param numberScrollData XLinArithmeticAnimationNumberScrollData
function XUiLineArithmeticGame:AddNumberScrollData(numberScrollData)
    for i = 1, #self._NumberScrollData do
        local existData = self._NumberScrollData[i]
        if existData.Uid == numberScrollData.Uid then
            table.remove(self._NumberScrollData, i)
            break
        end
    end

    self._NumberScrollData[#self._NumberScrollData + 1] = numberScrollData
    local uiGrid = self:GetUiGridByUid(numberScrollData.Uid)
    if uiGrid then
        numberScrollData.CurrentScore = uiGrid:GetCurrentNumber()
    end
end

function XUiLineArithmeticGame:IsPlayingNumberScroll()
    return #self._NumberScrollData > 0
end

function XUiLineArithmeticGame:UpdateNumberScroll()
    if not self:IsPlayingNumberScroll() then
        return
    end
    local deltaTime = CS.UnityEngine.Time.deltaTime
    for i = #self._NumberScrollData, 1, -1 do
        local numberScrollData = self._NumberScrollData[i]
        if not numberScrollData.IsInit then
            numberScrollData.IsInit = true
            numberScrollData.Phase = 1
            numberScrollData.Time = 0
            local uiGrid = self:GetUiGridByUid(numberScrollData.Uid)
            if uiGrid then
                uiGrid:SetTextNumber(numberScrollData.CurrentScore)
            end
        end
        if numberScrollData.Phase == 1 then
            numberScrollData.Time = numberScrollData.Time + deltaTime
            if numberScrollData.Time > 0.1 then
                numberScrollData.Time = 0
                numberScrollData.Phase = 2
            end
        end
        if numberScrollData.Phase == 2 then
            numberScrollData.Time = numberScrollData.Time + deltaTime
            if numberScrollData.Time > 0.04 then
                numberScrollData.Time = 0
                local delta = numberScrollData.Score - numberScrollData.CurrentScore
                local diff = math.abs(delta)
                if diff < 1 then
                    table.remove(self._NumberScrollData, i)
                    local uiGrid = self:GetUiGridByUid(numberScrollData.Uid)
                    if uiGrid then
                        uiGrid:SetTextNumber(numberScrollData.Score)
                    end
                else
                    if delta > 0 then
                        delta = 1
                    elseif delta < 0 then
                        delta = -1
                    end
                    local number = numberScrollData.CurrentScore + delta
                    local uiGrid = self:GetUiGridByUid(numberScrollData.Uid)
                    if uiGrid then
                        uiGrid:SetTextNumber(number)
                        numberScrollData.CurrentScore = number
                    end
                end
            end
        end
    end
end

function XUiLineArithmeticGame:UpdateEventGridDesc()
    self._Control:UpdateEventGridDesc()
    local uiData = self._Control:GetUiData()
    local events = uiData.EventDescData

    for i = 1, #events do
        local event = events[i]
        local uiGrid = self._EventGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridProp, self.GridProp.parent)
            uiGrid = XUiLineArithmeticGameEventGrid.New(ui, self)
            self._EventGrids[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(event)
    end
    for i = #events + 1, #self._EventGrids do
        local uiGrid = self._EventGrids[i]
        uiGrid:Close()
    end
end

function XUiLineArithmeticGame:UpdateStarTarget()
    self._Control:UpdateStarTarget()

    local uiData = self._Control:GetUiData()
    local stars = uiData.StarDescData
    -- ui逻辑: 第四颗星作为隐藏星
    local starAmount = math.min(3, #stars)

    for i = 1, starAmount do
        local starDesc = stars[i]
        local uiGrid = self._StarGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridTarget, self.GridTarget.parent)
            uiGrid = XUiLineArithmeticGameStarGrid.New(ui, self)
            self._StarGrids[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(starDesc)
    end
    for i = starAmount + 1, #self._StarGrids do
        local uiGrid = self._StarGrids[i]
        uiGrid:Close()
    end
end

function XUiLineArithmeticGame:OnClickManualSettle()
    if self:IsPlayingAnimation() then
        return
    end
    if self._Control:GetUiData().IsCanManualSettle then
        if self._Control:IsGameSettle() then
            XLog.Error("[XUiLineArithmeticGame] 游戏已结算，不能手动结算")
            return
        end
        XLuaUiManager.Open("UiLineArithmeticTargetPopupTips", function()
            self._Control:RequestManualSettle()
            self:UpdateTipsBtn()
        end, XUiHelper.GetText("LineArithmeticManualSettle"))
        --else
        --if XMain.IsWindowsEditor then
        --    XLog.Error("[XUiLineArithmeticGame] 还不能手动结算")
        --end
    end
end

function XUiLineArithmeticGame:UpdateTipsBtn()
    if self._Control:IsShowHelpBtn() then
        if not self.BtnTips.gameObject.activeInHierarchy then
            self.BtnTips.gameObject:SetActiveEx(true)
            XDataCenter.GuideManager.CheckGuideOpen()
        end
    else
        self.BtnTips.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmeticGame:OnClickHelp()
    if self:IsPlayingAnimation() then
        return
    end
    self._Control:MarkOpenUiHelp()
    XLuaUiManager.Open("UiLineArithmeticTips")
end

function XUiLineArithmeticGame:IsPlayingAnimation()
    return self._CurrentAnimation and true or false
end

function XUiLineArithmeticGame:UpdateResetButton()
    if self._Control:IsGameDirty() then
        self.BtnResetting:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnResetting:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiLineArithmeticGame:OnClickTip()
    if self:IsPlayingAnimation() then
        return
    end
    XUiManager.ShowHelpTip("LineArithmeticHelp")
end

function XUiLineArithmeticGame:UpdateTitle()
    if self.Title then
        self.Title.text = self._Control:GetCurrentStageName()
    end
end

function XUiLineArithmeticGame:UpdateEmptyGrid()
    self._Control:UpdateEmptyData()
    local emptyData = self._Control:GetUiData().MapEmptyData
    XUiHelper.RefreshCustomizedList(self.PanelEmpty.transform, self.GridEmpty, #emptyData, function(index, grid)
        local data = emptyData[index]
        grid.transform.localPosition = Vector3(data.X, data.Y, 0)
    end)
end

return XUiLineArithmeticGame
