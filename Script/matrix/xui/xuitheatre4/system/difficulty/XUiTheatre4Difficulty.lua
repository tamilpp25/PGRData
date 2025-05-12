local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiTheatre4DifficultyGrid = require("XUi/XUiTheatre4/System/Difficulty/XUiTheatre4DifficultyGrid")
local XUiTheatre4DifficultyDescGrid = require("XUi/XUiTheatre4/System/Difficulty/XUiTheatre4DifficultyDescGrid")
local ANIMATION_TYPE = {
    FIXED_SPEED = 1,
    FIXED_TIME = 2,
}

---@class XUiTheatre4Difficulty : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4Difficulty = XLuaUiManager.Register(XLuaUi, "UiTheatre4Difficulty")

function XUiTheatre4Difficulty:Ctor()
    ---@type XUiTheatre4DifficultyDescGrid[]
    self._DescGrids = {}

    self._ButtonGrids = {}

    self._TargetDissolutionThreshold = 0
    self._CurrentDissolutionThreshold = 0

    self._Type = ANIMATION_TYPE.FIXED_TIME
    self._VelocityDissolutionThreshold = 2

    self._DurationDissolutionThreshold = 1.5
    self._TimeDissolutionThreshold = 0

    self._Freeze = { 0, 0.05, 0.1, 0.3, 0.6, 1 }

    self._BtnIndex = 0

    self._TimerScroll = false
end

function XUiTheatre4Difficulty:OnAwake()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnSure, self.OnClickNextStep)

    ---@type XDynamicTableCurve
    --self.DynamicTableCurve = XDynamicTableCurve.New(self.ListDifficulty)
    --self.DynamicTableCurve:SetProxy(XUiTheatre4DifficultyGrid, self)
    --self.DynamicTableCurve:SetDelegate(self)
    ---@type XUiComponent.XTableCurve
    self._TableCurve = self.ListDifficulty
    self._ScrollRect = self._TableCurve.gameObject:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))

    self.GridDifficulty.gameObject:SetActiveEx(false)
    self.DescGrid.gameObject:SetActiveEx(false)
end

function XUiTheatre4Difficulty:OnEnable()
    self:UpdateCurrentDifficulty()
    self:UpdateAllDifficulty()
end

function XUiTheatre4Difficulty:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiTheatre4Difficulty:UpdateAllDifficulty()
    self:RefreshDifficultyList()
    self._TableCurve:UpdateTabButtonGroup()
    local data = self._Control.SetControl:GetUiData().Difficulty
    for i = 1, #data.DifficultyList do
        local difficulty = data.DifficultyList[i]
        if difficulty.IsSelected then
            self._TableCurve:SetIndex(i)
            break
        end
    end
    self._TableCurve.CallBack = function(index)
        self._BtnIndex = index
        self._Control.SetControl:SelectDifficulty(index)
        self:UpdateCurrentDifficulty()
        self:PlayAnimationFreeze(index)
        self:RefreshDifficultyList()
    end
    self:InitButtonGroupClick()
end

function XUiTheatre4Difficulty:UpdateCurrentDifficulty()
    self._Control.SetControl:UpdateCurrentDifficulty()
    local data = self._Control.SetControl:GetUiData().Difficulty
    self.TxtNumReward.text = math.roundDecimals(data.RewardRatio, 1)
    self.TxtNumHp.text = data.Hp

    local descList = data.CurrentDifficultyDescList
    for i = 1, #descList do
        local grid = self._DescGrids[i]
        if not grid then
            local obj = XUiHelper.Instantiate(self.DescGrid, self.DescGrid.transform.parent)
            grid = XUiTheatre4DifficultyDescGrid.New(obj, self)
            self._DescGrids[i] = grid
        end
        grid:Update(descList[i])
        grid:Open()
    end
    for i = #descList + 1, #self._DescGrids do
        local grid = self._DescGrids[i]
        grid:Close()
    end

    if self.TxtStoryDesc then
        self.TxtStoryDesc.text = data.StoryDesc
    end

    -- 难度选择 ：难度未解锁时，‘下一步按钮需要置灰，并且提示解锁条件’
    if data.IsUnlock then
        self.BtnSure:SetButtonState(CS.UiButtonState.Normal)
        if self.TxtUnlock then
            self.TxtUnlock.gameObject:SetActiveEx(false)
        end
    else
        self.BtnSure:SetButtonState(CS.UiButtonState.Disable)
        if self.TxtUnlock then
            self.TxtUnlock.text = data.UnlockDesc
            self.TxtUnlock.gameObject:SetActiveEx(true)
        end
    end
end

function XUiTheatre4Difficulty:RefreshDifficultyList()
    self._Control.SetControl:UpdateAllDifficulty()
    local data = self._Control.SetControl:GetUiData().Difficulty
    XTool.UpdateDynamicItem(self._ButtonGrids, data.DifficultyList, self.GridDifficulty, XUiTheatre4DifficultyGrid, self)
end

function XUiTheatre4Difficulty:GetIndex(index)
    return index % self.DynamicTableCurve.Imp.TotalCount + 1
end

function XUiTheatre4Difficulty:OnClickNextStep()
    if self.BtnSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    self._Control.SetControl:RequestSetDifficulty()
end

function XUiTheatre4Difficulty:PlayAnimationFreeze(index)
    local value = self._Freeze[index]
    if not value then
        --XLog.Error("[XUiTheatre4Difficulty] 困难对应的消融阈值为空:" .. index)
        value = 1
    end

    self._TargetDissolutionThreshold = value
    self._TimeDissolutionThreshold = 0

    if self._Timer then
        return
    end
    local effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/BgCommonBai/Effect4/FxUiTheatre4DifficultyBgFreeze(Clone)/All/Freeze", "Transform")
    self._Timer = XScheduleManager.ScheduleForever(function()
        -- 拖拽中不播放动画
        if self._TableCurve:IsDragging() then
            return
        end

        ---@type UnityEngine.UI.ScrollRect
        --local scrollRect = self._ScrollRect
        --local velocity = scrollRect.velocity
        ---- 滚动中不播放动画
        --if velocity.y > 300 then
        --    return
        --end

        -- 固定速度
        if self._Type == ANIMATION_TYPE.FIXED_SPEED then
            local distance = math.abs(self._TargetDissolutionThreshold - self._CurrentDissolutionThreshold)
            if distance == 0 then
                XScheduleManager.UnSchedule(self._Timer)
                self._Timer = false
                return
            end
            local time = distance / self._VelocityDissolutionThreshold
            local deltaTime = CS.UnityEngine.Time.deltaTime
            local ratio = deltaTime / time
            ratio = math.min(1, ratio)
            self._CurrentDissolutionThreshold = self._TargetDissolutionThreshold * ratio + self._CurrentDissolutionThreshold * (1 - ratio)

            -- 固定时间
        elseif self._Type == ANIMATION_TYPE.FIXED_TIME then
            local deltaTime = CS.UnityEngine.Time.deltaTime
            self._TimeDissolutionThreshold = self._TimeDissolutionThreshold + deltaTime
            if self._TimeDissolutionThreshold > self._DurationDissolutionThreshold then
                self._TimeDissolutionThreshold = self._DurationDissolutionThreshold
                XScheduleManager.UnSchedule(self._Timer)
                self._Timer = false
            end
            local ratio = self._TimeDissolutionThreshold / self._DurationDissolutionThreshold
            self._CurrentDissolutionThreshold = self._TargetDissolutionThreshold * ratio + self._CurrentDissolutionThreshold * (1 - ratio)
        end

        CS.XTool.SetDissolutionThreshold(effect.gameObject, self._CurrentDissolutionThreshold)

    end, 0, 0)
end

function XUiTheatre4Difficulty:OnDestroy()
    ---@type XUiButtonGroup
    local uiButtonGroup = self._TableCurve.gameObject:GetComponent("XUiButtonGroup")
    if uiButtonGroup then
        local tabBtnList = uiButtonGroup.TabBtnList
        for i = 0, tabBtnList.Count - 1 do
            ---@type XUiComponent.XUiButton
            local button = tabBtnList[i]
            -- 避免泄漏
            button.onClick:RemoveAllListeners()
        end
    end

    if self._TimerScroll then
        XScheduleManager.UnSchedule(self._TimerScroll)
        self._TimerScroll = false
    end
end

function XUiTheatre4Difficulty:InitButtonGroupClick()
    -- 点击按钮选中
    ---@type XUiButtonGroup
    local uiButtonGroup = self._TableCurve.gameObject:GetComponent("XUiButtonGroup")
    if uiButtonGroup then
        local tabBtnList = uiButtonGroup.TabBtnList
        for i = 0, tabBtnList.Count - 1 do
            ---@type XUiComponent.XUiButton
            local button = tabBtnList[i]
            button.onClick:AddListener(function()
                if self._BtnIndex == button.GroupIndex then
                    return
                end
                self._BtnIndex = button.GroupIndex
                local scrollView = self._TableCurve.gameObject:GetComponent("ScrollRect")
                local position = scrollView.content.anchoredPosition
                local viewportHeight = scrollView.viewport.rect.height
                local contentBox = self._TableCurve.ContentBox
                local centerY = -(position.y + viewportHeight / 2 + contentBox.anchoredPosition.y)
                local offsetSigned = button.transform.anchoredPosition.y - centerY
                position.y = position.y - offsetSigned
                local currentPosition = Vector2(position.x, position.y)

                --scrollView.content.anchoredPosition = position
                -- 滚动动画
                if self._TimerScroll then
                    XScheduleManager.UnSchedule(self._TimerScroll)
                end
                local beginPosition = scrollView.content.anchoredPosition
                local time = 0
                local speed = 1500
                local distance = math.abs(beginPosition.y - position.y)
                --self._TableCurve.enabled = false
                self._TimerScroll = XScheduleManager.ScheduleForever(function()
                    time = time + CS.UnityEngine.Time.deltaTime
                    local ratio = time * speed / distance
                    if ratio >= 1 then
                        ratio = 1
                        XScheduleManager.UnSchedule(self._TimerScroll)
                        self._TimerScroll = 0
                        --self._TableCurve.enabled = true
                    end
                    currentPosition.y = beginPosition.y * (1 - ratio) + position.y * ratio
                    scrollView.content.anchoredPosition = currentPosition
                end, 0, 0)
            end)
        end
    end
end

return XUiTheatre4Difficulty