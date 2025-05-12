local XUiLuckyTenantGameGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantGameGrid")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XUiLuckyTenantChessBagProp = require("XUi/XUiLuckyTenant/Game/Bag/XUiLuckyTenantChessBagProp")
local XUiLuckyTenantGameGetScore = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantGameGetScore")
local XUiLuckyTenantChessGrid = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantChessGrid")
local GameState = XLuckyTenantEnum.GameState

---@class XUiLuckyTenantGame : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantGame = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantGame")

function XUiLuckyTenantGame:Ctor()
    self._Timer = false
    ---@type XUiLuckyTenantGameGrid[]
    self._Grids = {}
    ---@type XUiLuckyTenantGameGetScore[]
    self._AnimationGetScore = {}
    ---@type XUiLuckyTenantGameGetItem[]
    self._AnimationGetItem = {}

    self._State = 0
    self._TimerNextState = false
    self._TimerAddScore = false
    self._QuestReward = { self.PropReward }
    self._StageId = 0

    self._StageId = 0
    self._Seed = 0
    self._IsFirstTimeEntering = false

    self._IsPause = false
    self._IsCancelNextState = false

    self._IsSpeedUp = false
    self._TimeScaleSpeedUp = 2.5
    self._TimerRoll = false
    self._IsCheckGuide = false
end

function XUiLuckyTenantGame:OnAwake()
    XMVCA.XLuckyTenant:SetPlaying(true)

    self:BindExitBtns()
    self:BindHelpBtn(nil, self._Control:GetUiData().HelpKey)
    XUiHelper.RegisterClickEvent(self, self.BtnArrange, self.OnClickNextRound, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnReStarts, self.OnClickRestart, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnOver, self.OnClickOver, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBag, self.OnClickBag, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.CloseRewardTips, nil, true)
    if self.Editor then
        self.Editor.gameObject:SetActiveEx(false)
    end
    if self.AnimationGetScore then
        self.AnimationGetScore.gameObject:SetActiveEx(false)
        self.AnimationGetItem.gameObject:SetActiveEx(false)
    end
    self.TxtAddScore.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_GUIDE, self._OnGuideEvent, self)

    if not self.BtnSpeedUp then
        self.BtnSpeedUp = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/BtnSpeedUp", "XUiButton")
    end
    if self.BtnSpeedUp then
        XUiHelper.RegisterClickEvent(self, self.BtnSpeedUp, self.OnClickSpeedUp, nil, true)

        local isOn = XSaveTool.GetData("LuckyTenantSpeedUp")
        if isOn then
            self.BtnSpeedUp:SetButtonState(CS.UiButtonState.Select)
        else
            self.BtnSpeedUp:SetButtonState(CS.UiButtonState.Normal)
        end
        self._IsSpeedUp = isOn
    end
    if self.GirdLuckyLandlordChessDetail then
        self.GirdLuckyLandlordChessDetail.gameObject:SetActiveEx(false)
        ---@type XUiLuckyTenantChessGrid
        self._Detail = XUiLuckyTenantChessGrid.New(self.GirdLuckyLandlordChessDetail, self)
        self._Detail:Close()
    end
    self:CloseRewardTips()
end

function XUiLuckyTenantGame:OnStart(stageId, seed, isFirstTimeEntering, record)
    self._StageId = stageId or 101
    self._Seed = seed or XTime.GetServerNowTimestamp()
    XMVCA.XLuckyTenant:Print("[XUiLuckyTenantGame] 随机种子为:" .. self._Seed)
    if isFirstTimeEntering == nil then
        isFirstTimeEntering = true
    end
    self._IsFirstTimeEntering = isFirstTimeEntering
    self:StartGame(record)
end

function XUiLuckyTenantGame:OnEnable()
    if not self._IsCheckGuide then
        local isGuide = XDataCenter.GuideManager.CheckGuideOpen()
        self:CheckGuide(isGuide)
        self._IsCheckGuide = true
    end

    if self._IsPause then
        --指引暂停时， 也得先刷新一次界面
        self:UpdateUi()
    else
        self:Update()
    end
    self._Control:UpdateBagAmount()
    self:ForceUpdateBagAmount()
    self.TxtTitle.text = self._Control:GetUiData().StageName
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_REWARD, self.OpenRewardTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_RESTART, self.Restart, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG, self.ForceUpdateBagAmount, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_PIECE_ON_CHESSBOARD, self.OnClickPieceOnChessboard, self)
end

function XUiLuckyTenantGame:CheckGuide(isGuide)
    -- 指引中, 暂停游戏
    if isGuide or XDataCenter.GuideManager.CheckIsInGuide() then
        self:_OnGuideEvent(0)
    end
end

function XUiLuckyTenantGame:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_REWARD, self.OpenRewardTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_RESTART, self.Restart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_BAG, self.ForceUpdateBagAmount, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_PIECE_ON_CHESSBOARD, self.OnClickPieceOnChessboard, self)
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiLuckyTenantGame:OnDestroy()
    XMVCA.XLuckyTenant:SetPlaying(false)

    CS.UnityEngine.Time.timeScale = 1
    self._Control:ClearGame()
    XMVCA.XLuckyTenant:ClearAfterLeavingTheGame()
    if XLuaUiManager.IsMaskShow("LuckyTenant") then
        XLuaUiManager.SetMask(false, "LuckyTenant")
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_GUIDE, self._OnGuideEvent, self)
end

function XUiLuckyTenantGame:SetUiDirtyAndUpdate()
    self._Control:SetUiDataDirty(true)
    self:UpdateUi()
    --self:ShowPieceEffect()
end

function XUiLuckyTenantGame:UpdateUi()
    local uiData = self._Control:GetUiData()
    if uiData.IsDirty then
        self:UpdateInfo()
        self:UpdateChessboard()
        uiData.IsDirty = false
    end
end

function XUiLuckyTenantGame:Update()
    if self._IsPause then
        self:UpdateAnimation()
        return
    end
    -- 请求中，不进行下一步
    if XMVCA.XLuckyTenant:IsRequesting() then
        self:UpdateAnimation()
        return
    end
    local uiData = self._Control:GetUiData()
    self:UpdateUi()

    local gameState = uiData.GameState
    if self._State ~= gameState then
        self._State = gameState
        self:HandleStateAction()
    end
    self:UpdateAnimation()
end

function XUiLuckyTenantGame:UpdateAnimation()
    if self._State == GameState.Animation then
        local uiData = self._Control:GetUiData()
        local animationGroups = uiData.AnimationGroups
        if animationGroups then
            local animationGroup = animationGroups[1]
            if animationGroup then
                animationGroup:Update(self)
                if animationGroup:IsFinish() then
                    table.remove(animationGroups, 1)
                end
            end
        end
        if not animationGroups or #animationGroups == 0 then
            self._Control:FinishAnimation()
            if CS.UnityEngine.Time.timeScale ~= 1 then
                CS.UnityEngine.Time.timeScale = 1
                XMVCA.XLuckyTenant:Print("停止加速")
            end
        end
    end
end

function XUiLuckyTenantGame:HandleStateAction()
    --XMVCA.XLuckyTenant:Print("执行状态", self._State)
    if self._State == GameState.ShowQuestGoalsOnFirstRound then
        if not XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(true, "LuckyTenant")
        end
        self._TimerNextState = XScheduleManager.ScheduleForever(function()
            if self._IsPause then
                return
            end
            XScheduleManager.UnSchedule(self._TimerNextState)
            self._TimerNextState = false
            self._Control:NextGameState()
        end, 1000)
        self:_AddTimerId(self._TimerNextState)
        return
    end
    if self._State == GameState.SelectPiece then
        self.PanelTaskFinish.gameObject:SetActiveEx(false)
        if XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(false, "LuckyTenant")
        end
        self._Control:StartSelectPiece()
        return
    end
    if self._State == GameState.CheckQuestCompletionStatus then
        self._TimerNextState = XScheduleManager.ScheduleForever(function()
            if self._IsPause then
                return
            end
            XScheduleManager.UnSchedule(self._TimerNextState)
            self._TimerNextState = false
            self._Control:NextGameState()
        end, 1000)
        self:_AddTimerId(self._TimerNextState)
        return
    end
    if self._State == GameState.ShowNextQuestGoals then
        self.PanelTaskFinish.gameObject:SetActiveEx(true)
        self._TimerNextState = XScheduleManager.ScheduleForever(function()
            if self._IsPause then
                return
            end
            XScheduleManager.UnSchedule(self._TimerNextState)
            self._TimerNextState = false
            self.PanelTaskFinish.gameObject:SetActiveEx(false)
            self._Control:NextGameState()
        end, 3000)
        self:_AddTimerId(self._TimerNextState)
        return
    end
    if self._State == GameState.GameOver then
        if XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(false, "LuckyTenant")
        end
        XMVCA.XLuckyTenant:Print("游戏失败")
        self._Control:OnStagePassed()
        XLuaUiManager.Open("UiLuckyTenantSettlement")
        return
    end
    if self._State == GameState.NormalClear then
        if XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(false, "LuckyTenant")
        end
        XMVCA.XLuckyTenant:Print("游戏普通通关")
        self._Control:OnStagePassed()
        XLuaUiManager.Open("UiLuckyTenantSettlement")
        return
    end
    if self._State == GameState.PerfectClear then
        if XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(false, "LuckyTenant")
        end
        XMVCA.XLuckyTenant:Print("游戏完美通关")
        self._Control:OnStagePassed()
        XLuaUiManager.Open("UiLuckyTenantSettlement")
        return
    end
    if self._State == GameState.Animation then
        if not XLuaUiManager.IsMaskShow("LuckyTenant") then
            XLuaUiManager.SetMask(true, "LuckyTenant")
        end
        self:PlayAnimation("BtnArrangePress")
        if self._IsSpeedUp then
            local timeScale = self._TimeScaleSpeedUp
            CS.UnityEngine.Time.timeScale = timeScale
            XMVCA.XLuckyTenant:Print("加速， 当前速度是", timeScale)
        end
        return
    end
end

function XUiLuckyTenantGame:SetScore(value)
    self.TxtNumScore.text = value
end

function XUiLuckyTenantGame:SetAddScore(value)
    if value > 0 then
        self.TxtAddScore.text = "+" .. value
        self.TxtAddScore.gameObject:SetActiveEx(true)
        if self._TimerAddScore then
            XScheduleManager.UnSchedule(self._TimerAddScore)
        end
        self._TimerAddScore = XScheduleManager.ScheduleOnce(function()
            self.TxtAddScore.gameObject:SetActiveEx(false)
            self._TimerAddScore = false
        end, 3000)
        self:_AddTimerId(self._TimerAddScore)
    else
        -- 不要立即隐藏
        --self.TxtAddScore.gameObject:SetActiveEx(false)
    end
end

function XUiLuckyTenantGame:GetUiData()
    local data = self._Control:GetUiData()
    return data
end

function XUiLuckyTenantGame:UpdateInfo()
    local data = self:GetUiData()
    self:SetScore(data.Score)
    self:SetAddScore(data.AddScore)

    self.TxtTaskOrder.text = data.QuestCompletedAmount .. "/" .. data.QuestTotalAmount
    self.TxtNumRound.text = data.Round
    self.TxtTask.text = XUiHelper.ReplaceTextNewLine(data.QuestDesc)
    --self.BtnOver.gameObject:SetActiveEx(data.IsNormalClear)
    self:UpdateBagAmount()
    self:UpdateQuestReward()
end

function XUiLuckyTenantGame:ForceUpdateBagAmount()
    self._Control:UpdateBag()
    local data = self._Control:GetUiData()
    self.BtnBag:SetNameByGroup(0, data.PiecesAmount)
end

function XUiLuckyTenantGame:UpdateBagAmount()
    self._Control:UpdateBag()
    if self._State ~= XLuckyTenantEnum.GameState.Animation
            and self._State ~= XLuckyTenantEnum.GameState.Roll
    then
        local data = self._Control:GetUiData()
        self.BtnBag:SetNameByGroup(0, data.PiecesAmount)
    end
end

function XUiLuckyTenantGame:UpdateChessboard()
    local data = self._Control:GetUiData()
    XTool.UpdateDynamicItem(self._Grids, data.Chessboard, self.GridChess, XUiLuckyTenantGameGrid, self)
end

function XUiLuckyTenantGame:OnClickNextRound()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    if self._State == GameState.CheckQuestCompletionStatus then
        --快进 直接开始选棋
        --self._Control:NextGameState()
        --if self._TimerNextState then
        --    XScheduleManager.UnSchedule(self._TimerNextState)
        --    self._TimerNextState = false
        --end
        return
    end
    if XLuaUiManager.IsUiLoad("UiLuckyTenantOverDetail") then
        return
    end
    if self._State == GameState.Roll then
        self._Control:Roll()
        self.BtnBag:SetNameByGroup(0, XUiHelper.GetText("LuckyTenantBagPlaying"))
        return
    end
end

function XUiLuckyTenantGame:OnClickRestart()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    if self._State == GameState.Roll
            or self._State == GameState.PerfectClear
            or self._State == GameState.GameOver
    then
        XLuaUiManager.Open("UiLuckyTenantOverDetail", XLuckyTenantEnum.OverDetailUi.Restart)
    end
end

function XUiLuckyTenantGame:Restart()
    self._Seed = XTime.GetServerNowTimestamp()
    XMVCA.XLuckyTenant:Print("[XUiLuckyTenantGame] 随机种子为:" .. self._Seed)
    self._Control:Restart(self._StageId, self._Seed, self._IsFirstTimeEntering)
end

function XUiLuckyTenantGame:StartGame(record)
    self._Control:StartGame(self._StageId, self._Seed, self._IsFirstTimeEntering, record)
end

function XUiLuckyTenantGame:OnClickOver()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    if self._State == GameState.Animation then
        return
    end
    self._Control:ManualSettle()
end

function XUiLuckyTenantGame:OnClickBag()
    if XMVCA.XLuckyTenant:IsRequesting() then
        return
    end
    if self._State == GameState.Roll then
        XLuaUiManager.Open("UiLuckyTenantChessBag")
    end
end

function XUiLuckyTenantGame:UpdateQuestReward()
    local rewards = self._Control:GetUiData().QuestRewards
    XTool.UpdateDynamicItem(self._QuestReward, rewards, self.PropReward, XUiLuckyTenantChessBagProp, self)
end

function XUiLuckyTenantGame:CloseRewardTips()
    self.RewardTips.gameObject:SetActiveEx(false)
    if self._Detail then
        self._Detail:Close()
    end
end

---@param data XUiLuckyTenantChessBagPropData
function XUiLuckyTenantGame:OpenRewardTips(data, worldPosition, pivotOnDown)
    self.RewardTips.gameObject:SetActiveEx(true)
    self.TxtRewardTips.text = data.Desc
    self.PanelRewardTips.gameObject:SetActiveEx(true)
    self._Detail:Close()

    ---@type UnityEngine.RectTransform
    local transform = self.PanelRewardTips.transform
    if pivotOnDown then
        transform.anchorMin = Vector2(0, 0)
        transform.anchorMax = Vector2(0, 0)
        transform.pivot = Vector2(0, 0)
    else
        transform.anchorMin = Vector2(0, 1)
        transform.anchorMax = Vector2(0, 1)
        transform.pivot = Vector2(0, 1)
    end
    transform.position = worldPosition
end

---@return XUiLuckyTenantGameGrid
function XUiLuckyTenantGame:GetGrid(index)
    local grid = self._Grids[index]
    if not grid then
        XMVCA.XLuckyTenant:Print("[XUiLuckyTenantGame] 找不到要播放动画的格子:" .. tostring(index))
        return false
    end
    return grid
end

function XUiLuckyTenantGame:PlayAnimationGetScore(index, value, time, callback)
    local grid = self:GetGrid(index)
    if not grid then
        --XMVCA.XLuckyTenant:Print("[XUiLuckyTenantGame] 找不到要播放动画的格子:" .. tostring(index))
        return
    end
    if not self.AnimationGetScore then
        return
    end

    ---@type UnityEngine.RectTransform
    local targetRectTransform = self.TxtNumScore.transform
    local endPosition = targetRectTransform.position
    local startPosition = grid.TxtCost.transform.position

    local getScoreGrid = self._AnimationGetScore[index]
    if not getScoreGrid then
        local ui = CS.UnityEngine.Object.Instantiate(self.AnimationGetScore, self.AnimationGetScore.transform.parent)
        ui.gameObject:SetActiveEx(true)
        getScoreGrid = XUiLuckyTenantGameGetScore.New(ui, self)
        self._AnimationGetScore[index] = getScoreGrid
    end
    getScoreGrid:Open()
    getScoreGrid:Update(value)
    getScoreGrid:StopTimer()
    getScoreGrid.Transform.position = startPosition
    local timer = self:DoWorldMove(getScoreGrid.Transform, endPosition, time, nil, function()
        getScoreGrid:ClearTimer()
        getScoreGrid:Close()
        if callback then
            callback()
        end
    end)
    getScoreGrid:SetTimer(timer)
end

function XUiLuckyTenantGame:_OnGuideEvent(value)
    value = tonumber(value)
    if XLuaUiManager.IsMaskShow("LuckyTenant") then
        XLuaUiManager.SetMask(false, "LuckyTenant")
    end
    if value == 0 then
        --if self._TimerNextState then
        --    XScheduleManager.UnSchedule(self._TimerNextState)
        --    self._TimerNextState = false
        --    self._IsCancelNextState = true
        --end
        self._IsPause = true
        return
    end
    if value == 1 then
        self._IsPause = false
        --if self._IsCancelNextState then
        --    self._IsCancelNextState = false
        --    --self._Control:NextGameState()
        --end
    end
end

function XUiLuckyTenantGame:OnClickSpeedUp(event, isOn)
    local isOn = self.BtnSpeedUp.ButtonState == CS.UiButtonState.Select
    self._IsSpeedUp = isOn
    XSaveTool.SaveData("LuckyTenantSpeedUp", isOn)
end

---@param data XUiLuckyTenantChessBagPropData
function XUiLuckyTenantGame:OnClickPieceOnChessboard(data)
    self.RewardTips.gameObject:SetActiveEx(true)
    self.PanelRewardTips.gameObject:SetActiveEx(false)
    self._Detail:Open()
    self._Detail:Update(data)
end

function XUiLuckyTenantGame:HideChessboard()
    local data = {
        IsValid = false
    }
    for i = 1, #self._Grids do
        local grid = self._Grids[i]
        grid:Update(data)
    end
end

function XUiLuckyTenantGame:ShowPieceEffect()
    for i = 1, #self._Grids do
        local grid = self._Grids[i]
        grid:ShowEffect()
    end
end

---@param transform UnityEngine.RectTransform
function XUiLuckyTenantGame:SetAnimationIconByIndex(index, transform, data)
    local child = transform:GetChild(index)
    if child then
        if data then
            ---@type UnityEngine.UI.RawImage
            local icon = XUiHelper.TryGetComponent(child, "Icon", "RawImage")
            icon:SetRawImage(data.Icon)
            icon.gameObject:SetActiveEx(true)

            ---@type UnityEngine.UI.RawImage
            local qualityIcon = XUiHelper.TryGetComponent(child, "ImgQuality", "Image")
            qualityIcon:SetSprite(data.QualityIcon)
            qualityIcon.gameObject:SetActiveEx(true)
        else
            ---@type UnityEngine.UI.RawImage
            local icon = XUiHelper.TryGetComponent(child, "Icon", "RawImage")
            icon.gameObject:SetActiveEx(false)

            ---@type UnityEngine.UI.RawImage
            local qualityIcon = XUiHelper.TryGetComponent(child, "ImgQuality", "Image")
            qualityIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLuckyTenantGame:SetAnimationIcon(amount)
    local result = self._Control:GetIcon4Animation(amount)

    ---@type UnityEngine.RectTransform
    local transform = self.PlanelIcon
    local childCount = transform.childCount
    local indices = { }
    for i = 0, childCount - 1 do
        indices[i + 1] = i
    end
    -- 随机打乱索引
    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    -- 固定前三项，配合动画食用
    --Swap(index, 1, 7)
    --Swap(index, 2, 11)
    --Swap(index, 3, 13)

    for i = 1, childCount do
        local pos = indices[i]
        local length = #result
        if result[length] then
            self:SetAnimationIconByIndex(pos, transform, result[length])
            result[length] = nil
        else
            self:SetAnimationIconByIndex(pos, transform, nil)
        end
    end
end

function XUiLuckyTenantGame:PlayAnimationRollShow()
    self:HideChessboard()
    self:PlayAnimation("RollingShow")
    --local index = 1
    --self._TimerRoll = XScheduleManager.ScheduleOnce(function()
    --    if index == 1 then
    --    end
    --end, )
    self:SetAnimationIcon(20)
end

return XUiLuckyTenantGame