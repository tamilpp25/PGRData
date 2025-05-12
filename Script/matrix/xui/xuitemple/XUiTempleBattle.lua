local XUiTempleBattleGridRule = require("XUi/XUiTemple/XUiTempleBattleGridRule")
local XUiTempleBattleGridStar = require("XUi/XUiTemple/XUiTempleBattleGridStar")
local XUiTempleBattleBlockOption = require("XUi/XUiTemple/XUiTempleBattleBlockOption")
local XUiTempleBattleOperation = require("XUi/XUiTemple/XUiTempleBattleOperation")
local XUiTempleBattleRoundWithScore = require("XUi/XUiTemple/XUiTempleBattleRoundWithScore")
local XUiTempleBattleSmallRound = require("XUi/XUiTemple/XUiTempleBattleSmallRound")
local XUiTempleBattleGridPreviewScore = require("XUi/XUiTemple/XUiTempleBattleGridPreviewScore")
local XUiTempleChessBoardPanel = require("XUi/XUiTemple/XUiTempleChessBoardPanel")
local XUiTempleUtil = require("XUi/XUiTemple/XUiTempleUtil")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XUiTempleBattleTalk = require("XUi/XUiTemple/XUiTempleBattleTalk")

---@class XUiTempleBattle : XLuaUi
---@field BtnHelp XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field GridRule UnityEngine.RectTransform
---@field ImgBar UnityEngine.UI.Image
---@field GridStar1 UnityEngine.RectTransform
---@field GridStar2 UnityEngine.RectTransform
---@field GridStar3 UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field GridRound1 UnityEngine.RectTransform
---@field GridSmallRound UnityEngine.RectTransform
---@field RImgCheckerboard UnityEngine.UI.RawImage
---@field PanelControl UnityEngine.RectTransform
---@field PanelScore UnityEngine.RectTransform
---@field GridScore UnityEngine.RectTransform
---@field BtnDelete XUiComponent.XUiButton
---@field BtnChange XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field BtnMove XUiComponent.XUiButton
---@field PanelOption UnityEngine.RectTransform
---@field BubbleGridDetail UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field BtnSkip XUiComponent.XUiButton
---@field BtnOption1 XUiComponent.XUiButton
---@field BtnOption2 XUiComponent.XUiButton
---@field PanelCharacter UnityEngine.RectTransform
---@field BtnSettlement XUiComponent.XUiButton
---@field PanelQingrenjieCharacter UnityEngine.RectTransform
---@field BtnRestart XUiComponent.XUiButton
---@field PanelSpeak UnityEngine.RectTransform
---@field TxtChat UnityEngine.UI.Text
---@field _Control XTempleControl
local XUiTempleBattle = XLuaUiManager.Register(XLuaUi, "UiTempleBattle")

function XUiTempleBattle:Ctor()
    ---@type XUiTempleBattleGridRule
    self.GridRuleUi = nil
    ---@type XUiTempleBattleGridStar[]
    self._GridStars = nil

    self._Rules = {}

    self._Grids = {}

    self._TimeOfDays = {}

    self._Rounds = {}

    self._Previews = {}

    self._DragOffset = XLuaVector2.New()
    self._OperationPos = XLuaVector2.New()

    self._TimerPrompt = false

    self._AnimationScoreDuration1 = 1
    self._AnimationScoreDuration2 = 1
    self._TimerAnimationScore = false

    self._OldRulesData = false
    self._IsRuleDirty = true

    self._DataProgress = false
end

function XUiTempleBattle:InitGameControl()
    ---@type XTempleGameControl
    self._GameControl = self._Control:GetGameControl()
end

--region 生命周期
function XUiTempleBattle:OnAwake()
    self:InitGameControl()
    self.GridRuleUi = XUiTempleBattleGridRule.New(self.GridRule, self)
    self._GridStars = {
        XUiTempleBattleGridStar.New(self.GridStar1, self),
        XUiTempleBattleGridStar.New(self.GridStar2, self),
        XUiTempleBattleGridStar.New(self.GridStar3, self),
    }

    ---@type XUiTempleBattleBlockOption
    self._OptionBlock1 = XUiTempleBattleBlockOption.New(self.BtnOption1, self)
    ---@type XUiTempleBattleBlockOption
    self._OptionBlock2 = XUiTempleBattleBlockOption.New(self.BtnOption2, self)
    ---@type XUiTempleBattleOperation
    self._Operation = XUiTempleBattleOperation.New(self.PanelOption, self, self._Control:GetGameControl())
    self:_RegisterButtonClicks()
    if self.PanelGridRule then
        self:HidePanelGridRule()
    end
    ---@type XUiTempleChessBoardPanel
    self._PanelChessBoard = XUiTempleChessBoardPanel.New(self.PanelCheckerboard, self)

    ---@type XUiTempleBattleTalk
    self._PanelTalk = XUiTempleBattleTalk.New(self.PanelCharacter, self)
    self._PanelTalk:Close()
    ---@type XUiTempleBattleTalk
    self._PanelTalkCouple = XUiTempleBattleTalk.New(self.PanelQingrenjieCharacter, self)
    self._PanelTalkCouple:Close()

    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_TALK, self.UpdateTalk, self)

    self.PanelPrompt = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPrompt", "Transform")
    if self.PanelPrompt then
        self.PromptBg = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTop/ImgBg", "RawImage")
        self.PromptText = XUiHelper.TryGetComponent(self.PanelPrompt, "Image/Text", "Text")
    end

    self.PanelStar = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTop/PanelStar", "Transform")
end

function XUiTempleBattle:OnRelease()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
    XLuaUi.OnRelease(self)
end

function XUiTempleBattle:OnStart(stageId)
    self:AddListenerInput()
    if stageId then
        self._GameControl:StartGame(stageId)
    end
    XMVCA.XTemple:SetCurrentStageId(stageId)

    local chapterId = self._GameControl:GetChapterId(stageId)
    if chapterId then
        if chapterId == XTempleEnumConst.CHAPTER.SPRING then
            self.SpringEffect.gameObject:SetActiveEx(true)
            self.ValentineEffect.gameObject:SetActiveEx(false)
            self.LanternEffect.gameObject:SetActiveEx(false)

        elseif chapterId == XTempleEnumConst.CHAPTER.COUPLE then
            self.SpringEffect.gameObject:SetActiveEx(false)
            self.ValentineEffect.gameObject:SetActiveEx(true)
            self.LanternEffect.gameObject:SetActiveEx(false)

        elseif chapterId == XTempleEnumConst.CHAPTER.LANTERN then
            self.SpringEffect.gameObject:SetActiveEx(false)
            self.ValentineEffect.gameObject:SetActiveEx(false)
            self.LanternEffect.gameObject:SetActiveEx(true)

        end
    end
end

function XUiTempleBattle:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_OPERATION, self.UpdateUiOperation, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.UpdateAfterAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_SHOW_TIME, self.ShowPrompt, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideEnd, self)
end

function XUiTempleBattle:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_OPERATION, self.UpdateUiOperation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.UpdateAfterAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_TALK, self.UpdateTalk, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_SHOW_TIME, self.ShowPrompt, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideEnd, self)
end

function XUiTempleBattle:OnDestroy()
    XMVCA.XTemple:ClearCurrentStageId()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:RemoveAllListeners()

    self._GameControl:LeaveGameUi()

    if self._TimerPrompt then
        XScheduleManager.UnSchedule(self._TimerPrompt)
        self._TimerPrompt = false
    end
    if self._TimerAnimationScore then
        XScheduleManager.UnSchedule(self._TimerAnimationScore)
        self._TimerAnimationScore = false
    end
end

--endregion

--region 按钮事件
function XUiTempleBattle:OnBtnSkipClick()
    self._GameControl:Skip()
end

function XUiTempleBattle:OnBtnOption1Click()
    self._GameControl:OnClickBlockOption(1)
    self:HidePanelGridRule()
end

function XUiTempleBattle:OnBtnOption2Click()
    self._GameControl:OnClickBlockOption(2)
    self:HidePanelGridRule()
end

function XUiTempleBattle:OnBtnSettlementClick()

end

function XUiTempleBattle:OnBtnRestartClick()
    XLuaUiManager.Open("UiTempleTips", function()
        self._GameControl:OnClickRestartGame()
    end, XUiHelper.GetText("TempleRestart"))
end
--endregion

function XUiTempleBattle:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    if self._Control:IsCoupleChapter() then
        self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKeyCouple())
    else
        self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKey())
    end

    --self:RegisterClickEvent(self.BtnDelete, self.OnBtnDeleteClick, true)
    --self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick, true)
    --self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick, true)
    --self:RegisterClickEvent(self.BtnMove, self.OnBtnMoveClick, true)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick, true)
    self:RegisterClickEvent(self.BtnOption1, self.OnBtnOption1Click, true)
    self:RegisterClickEvent(self.BtnOption2, self.OnBtnOption2Click, true)
    self:RegisterClickEvent(self.BtnSettlement, self.OnBtnSettlementClick, true)
    self:RegisterClickEvent(self.BtnRestart, self.OnBtnRestartClick, true)
    self:RegisterClickEvent(self.ButtonRuleTips, self.OnBtnRuleTips, true)
    self:RegisterClickEvent(self.PanelGridRule, self.OnBtnGridRule, true)
end

function XUiTempleBattle:Update()
    -- 在不进入游戏的情况下，在登录界面操作，容易触发这个问题
    self._GameControl:SaturationInit()
    if self._GameControl:IsLockUpdateUi() then
        return false
    end
    self._IsRuleDirty = true
    self:UpdateRule()
    self:UpdateUiOperation()
    self:UpdateGrids()
    self:UpdateBlockOptions()
    self:UpdateStars()
    self:UpdateScore()
    self:UpdateTimeBg()
    return true
end

function XUiTempleBattle:UpdateAfterAnimation()
    self._IsRuleDirty = true
    self:UpdateUiOperation()
    self:UpdateGrids()
    self:UpdateBlockOptions()
    self:UpdateTimeBg()
    if not self:PlayAnimationScore() then
        self:UpdateRule()
        self:UpdateStars()
        self:UpdateScore()
    end
end

function XUiTempleBattle:UpdateUiOperation()
    if self._GameControl:IsShowOperation() then
        self._Operation:Open()
        local data = self._GameControl:GetBlockOperation()
        self._Operation:Update(data)
        self:UpdatePreviewScore()
    else
        self._Operation:Close()
    end
end

function XUiTempleBattle:UpdateRule()
    local dataProvider = self:GetRule()
    self:UpdateDynamicItem(self._Rules, dataProvider, self.GridRule, XUiTempleBattleGridRule)
    self._OldRulesData = dataProvider
end

function XUiTempleBattle:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    XUiTempleUtil:UpdateDynamicItem(self, gridArray, dataArray, uiObject, class)
end

function XUiTempleBattle:UpdateGrids()
    local dataProvider = self._GameControl:GetGrids()
    local bg = self._GameControl:GetStageBg()
    self._PanelChessBoard:Update(dataProvider, bg, true)
end

function XUiTempleBattle:UpdateBlockOptions()
    local options = self._GameControl:GetBlockOption()
    if options[1] then
        self._OptionBlock1:Update(options[1])
        self._OptionBlock1:Open()
    else
        self._OptionBlock1:Close()
    end
    if options[2] then
        self._OptionBlock2:Update(options[2])
        self._OptionBlock2:Open()
    else
        self._OptionBlock2:Close()
    end
    if self._GameControl:IsShowSkip() then
        self.BtnSkip.gameObject:SetActiveEx(true)
    else
        self.BtnSkip.gameObject:SetActiveEx(false)
    end
end

function XUiTempleBattle:AddListenerInput()
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

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleBattle:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelDrag.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    --x = x + transform.rect.width / 2
    --y = y - transform.rect.height / 2
    return x, y
end

---@param eventData UnityEngine.EventSystems.PointerEventData
--function XUiTempleBattle:OnBeginDrag(eventData)
--    local x, y = self:GetPosByEventData(eventData)
--    self._GameControl:SetBlockOperationPosition(x, y)
--end
--
-----@param eventData UnityEngine.EventSystems.PointerEventData
--function XUiTempleBattle:OnDrag(eventData)
--    local x, y = self:GetPosByEventData(eventData)
--    self._GameControl:SetBlockOperationPosition(x, y)
--end
--
-----@param eventData UnityEngine.EventSystems.PointerEventData
--function XUiTempleBattle:OnEndDrag(eventData)
--    local x, y = self:GetPosByEventData(eventData)
--    self._GameControl:SetBlockOperationPosition(x, y)
--end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleBattle:OnBeginDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._DragOffset.x = x
    self._DragOffset.y = y

    local panelPos = self._Operation.Transform.localPosition
    self._OperationPos.x = panelPos.x
    self._OperationPos.y = panelPos.y
end

-----@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleBattle:OnDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y
    self._GameControl:SetBlockOperationPosition(offsetX, offsetY)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleBattle:OnEndDrag(eventData)
    self._DragOffset.x = 0
    self._DragOffset.y = 0
    self._OperationPos.x = 0
    self._OperationPos.y = 0
end

function XUiTempleBattle:UpdateScore()
    local data = self._DataProgress
    self.TxtNum.text = data.Score

    local value = self._GameControl:GetStarFillAmount()

    ---@type XUiComponent.XUiImageFill
    local bar = self.ImgBar
    bar.fillAmount = value
end

function XUiTempleBattle:UpdatePreviewScore()
    if self._GameControl:IsShowPreviewScore() then
        local data = self._GameControl:GetPreviewScore()
        if XTool.IsTableEmpty(data) then
            self.PanelScore.gameObject:SetActiveEx(false)
            return
        end
        self.PanelScore.gameObject:SetActiveEx(true)
        self:UpdateDynamicItem(self._Previews, data, self.GridScore, XUiTempleBattleGridPreviewScore)
    else
        self.PanelScore.gameObject:SetActiveEx(false)
    end
end

function XUiTempleBattle:OnBtnRuleTips()
    XLuaUiManager.Open("UiTempleAffixDetail")
end

function XUiTempleBattle:UpdateTalk(type)
    local data = self._GameControl:GetTalkData(type)
    if data and not string.IsNilOrEmpty(data.Text) then
        if self._GameControl:IsCoupleChapter() then
            self._PanelTalkCouple:Open()
            self._PanelTalkCouple:Update(data)
        else
            self._PanelTalk:Open()
            self._PanelTalk:Update(data)
        end
    end
end

---@param grid XUiTempleBattleGrid
function XUiTempleBattle:OnClickGrid(data, grid)
    if self.PanelGridRule then
        local x = data.X
        local y = data.Y
        local ruleText = self._GameControl:GetGridRuleText(x, y)
        if ruleText then
            self.PanelGridRule.gameObject:SetActiveEx(true)
            self.TextGridRule.text = ruleText

            local worldPosition = grid.Transform:TransformPoint(Vector3.zero)
            local localPosition = self.PanelGridRuleAnchor.parent.transform:InverseTransformPoint(worldPosition)
            self.PanelGridRuleAnchor.transform.localPosition = localPosition
        else
            self:HidePanelGridRule()
        end
    end
end

function XUiTempleBattle:OnBtnGridRule()
    if self.PanelGridRule then
        self:HidePanelGridRule()
    end
end

function XUiTempleBattle:UpdateStars()
    local star = self._GameControl:GetCurrentStar()
    for i = 1, #self._GridStars do
        local gridStar = self._GridStars[i]
        if gridStar:IsNodeShow() then
            gridStar:Update(i <= star)
        end
    end

    local data = self._GameControl:GetProgress()
    self._DataProgress = data
    self:UpdateDynamicItem(self._TimeOfDays, data.TimeOfDayData, self.GridRound1, XUiTempleBattleRoundWithScore)
    self:UpdateDynamicItem(self._Rounds, data.RoundData, self.GridSmallRound, XUiTempleBattleSmallRound)
end

function XUiTempleBattle:HidePanelGridRule()
    self.PanelGridRule.gameObject:SetActiveEx(false)
end

function XUiTempleBattle:ShowPrompt(time)
    if not time then
        return
    end
    if not self.PanelPrompt then
        return
    end
    self.PanelPrompt.gameObject:SetActiveEx(true)

    local text = self._GameControl:GetTimePromptText(time)
    self.PromptText.text = text

    if self._TimerPrompt then
        XScheduleManager.UnSchedule(self._TimerPrompt)
        self._TimerPrompt = false
    end

    self._TimerPrompt = XScheduleManager.ScheduleOnce(function()
        self.PanelPrompt.gameObject:SetActiveEx(false)
        self._TimerPrompt = false
    end, 1420)

    if self._GameControl:IsPlayMusicChangeTime() then
        self._GameControl:PlayMusicChangeTime()
    end
end

function XUiTempleBattle:UpdateTimeBg()
    local promptBg = self._GameControl:GetTimePromptBg()
    if promptBg and self.PromptBg then
        self.PromptBg:SetRawImage(promptBg)
    end
end

function XUiTempleBattle:PlayAnimationScore()
    if self._TimerAnimationScore then
        return
    end
    if not self._OldRulesData then
        return false
    end

    local timeIndex = self._GameControl:GetTimeIndex()
    if not timeIndex then
        return false
    end

    if not self.EffectRule then
        return false
    end

    local ruleData = self:GetRule()
    local oldRuleData = self._OldRulesData
    local map = {}
    for i = 1, #oldRuleData do
        local rule = oldRuleData[i]
        map[rule.Id] = rule.Score
    end
    local isAddScore = false
    for i = 1, #ruleData do
        local rule = ruleData[i]
        local oldScore = map[rule.Id] or 0
        if rule.IsActive then
            if rule.Score > oldScore then
                local effect = XUiHelper.TryGetComponent(self.EffectRule, "EffectScoreFly_" .. i .. "_" .. timeIndex, "Transform")
                if effect then
                    effect.gameObject:SetActiveEx(false)
                    effect.gameObject:SetActiveEx(true)
                    isAddScore = true
                end
            end
        end
    end
    if not isAddScore then
        return false
    end

    self:UpdateRule()
    self._TimerAnimationScore = XScheduleManager.ScheduleOnce(function()
        self:UpdateStars()

        local effect = XUiHelper.TryGetComponent(self.EffectTime, "EffectScoreTime" .. timeIndex, "Transform")
        if effect then
            effect.gameObject:SetActiveEx(false)
            effect.gameObject:SetActiveEx(true)
        end
        self._TimerAnimationScore = false

        self._TimerAnimationScore = XScheduleManager.ScheduleOnce(function()
            self:UpdateScore()
            self.EffectScoreHalo.gameObject:SetActiveEx(false)
            self.EffectScoreHalo.gameObject:SetActiveEx(true)
            self._TimerAnimationScore = false

        end, self._AnimationScoreDuration2 * XScheduleManager.SECOND)

    end, self._AnimationScoreDuration1 * XScheduleManager.SECOND)

    return true
end

---@return XTempleGameUiDataRule[]
function XUiTempleBattle:GetRule()
    local rule = self._GameControl:GetRule(false, self._IsRuleDirty)
    self._IsRuleDirty = false
    return rule
end

function XUiTempleBattle:OnGuideEnd()
    XDataCenter.GuideManager.CheckGuideOpen()
end

return XUiTempleBattle
