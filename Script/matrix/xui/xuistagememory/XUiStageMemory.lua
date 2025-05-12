local XUiStageMemoryStage = require("XUi/XUiStageMemory/XUiStageMemoryStage")
local XUiStageMemoryReward = require("XUi/XUiStageMemory/XUiStageMemoryReward")
local XUiStageMemoryProgressPoint = require("XUi/XUiStageMemory/XUiStageMemoryProgressPoint")

---@class XUiStageMemory : XLuaUi
---@field _Control XStageMemoryControl
local XUiStageMemory = XLuaUiManager.Register(XLuaUi, "UiStageMemory")

function XUiStageMemory:OnAwake()
    self:BindExitBtns()
    ---@type XUiStageMemoryStage[]
    self._Stages = {
        XUiStageMemoryStage.New(self.PanelMemoryStage1, self),
        XUiStageMemoryStage.New(self.PanelMemoryStage2, self),
        XUiStageMemoryStage.New(self.PanelMemoryStage3, self),
        XUiStageMemoryStage.New(self.PanelMemoryStage4, self),
        XUiStageMemoryStage.New(self.PanelMemoryStage5, self),
    }
    ---@type XUiStageMemoryReward[]
    self._Rewards = {}
    ---@type XUiStageMemoryProgressPoint[]
    self._Points = {}
    self._IsAutoSelect = true
end

function XUiStageMemory:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnPrev, self.OnClickLeft)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnClickRight)
    self:BindHelpBtn(self.BtnHelp, "UiStageMemory")

    ---@type XUiComponent.XHorizontalListWithAutomaticCentering
    local list = self.PanelList
    list.CallBack = function(index)
        index = index + 1
        self:UpdateStagePoints(index)
        self:UpdateArrow(index)
    end
end

function XUiStageMemory:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_STAGE_MEMORY_UPDATE_TIME, self.UpdateTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_STAGE_MEMORY_UPDATE_REWARD, self.Update, self)
    self:Update()
    self:UpdateTime()

    if self._IsAutoSelect then
        self._IsAutoSelect = false
        self:AutoSelect()
    end
end

function XUiStageMemory:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_STAGE_MEMORY_UPDATE_TIME, self.UpdateTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_STAGE_MEMORY_UPDATE_REWARD, self.Update, self)
end

function XUiStageMemory:UpdateTime()
    local time = self._Control:GetUiData().RemainTime
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.DAY_HOUR_2)
end

function XUiStageMemory:Update()
    self._Control:UpdateUiData()

    local data = self._Control:GetUiData()
    local stages = data.Stages
    local dataProvider = {}
    for i = 1, #stages do
        local stage = stages[i]
        if stage.IsUnlock then
            dataProvider[#dataProvider + 1] = stage
        end
    end
    XTool.UpdateDynamicItem(self._Stages, dataProvider, self.PanelMemoryStage1, XUiStageMemoryStage, self)

    --self.PanelList
    --self.PanelProgress
    --self.PanelReward
    --self.PanelState
    self.TxtClearNum.text = data.PassedStageAmount
    self.TxtAllNum.text = data.StageAmount
    --self.ImgProgress
    --self.GridReward
    --self.GridEmpty

    local rewards = data.Rewards
    XTool.UpdateDynamicItem(self._Rewards, rewards, self.GridReward, XUiStageMemoryReward, self)

    local points = data.Stages
    XTool.UpdateDynamicItem(self._Points, points, self.PanelState, XUiStageMemoryProgressPoint, self)

    self.ImgProgress.fillAmount = data.PassedStageAmount / data.StageAmount
end

function XUiStageMemory:OnClickLeft()
    ---@type XUiComponent.XHorizontalListWithAutomaticCentering
    local list = self.PanelList
    list:ScrollToLeftAsync()
end

function XUiStageMemory:OnClickRight()
    ---@type XUiComponent.XHorizontalListWithAutomaticCentering
    local list = self.PanelList

    local nextIndex = list:GetCurrentIndex() + 2
    local stage = self._Control:GetUiData().Stages[nextIndex]
    if not stage then
        return
    end
    if not stage.IsUnlock then
        -- 复用了之前的文本
        local timeId = stage.TimeId
        local endTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local currentTime = XTime.GetServerNowTimestamp()
        local time = endTime - currentTime
        if time > 0 then
            XUiManager.TipMsg(XUiHelper.GetText("MemoryStageUnlock", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.DAY_HOUR_2)))
        else
            XUiManager.TipMsg("CommonNotOpen")
        end
        return
    end

    list:ScrollToRightAsync()
end

function XUiStageMemory:UpdateStagePoints(index)
    for i = 1, #self._Points do
        self._Points[i]:UpdateSelected(index)
    end
end

function XUiStageMemory:AutoSelect()
    local data = self._Control:GetUiData()
    local index = -1
    if data.PassedStageAmount == data.StageAmount then
        index = #data.Stages
    end
    --存在未通关且满足开启条件stage时，定位至最新的1个未通关且满足开启条件的stage
    if index == -1 then
        for i = 1, #data.Stages do
            local stage = data.Stages[i]
            if stage.IsUnlock and not stage.IsPassed then
                index = i
                break
            end
        end
    end
    --若不存在，定位至最后一个已通关的战斗
    if index == -1 then
        for i = 1, #data.Stages do
            local stage = data.Stages[i]
            if stage.IsPassed and stage.IsUnlock then
                index = i
            end
        end
    end
    if index == -1 then
        index = 1
    end
    ---@type XUiComponent.XHorizontalListWithAutomaticCentering
    local list = self.PanelList
    list:ScrollToIndex(index - 1)
end

function XUiStageMemory:UpdateArrow(index)
    local nextIndex = index + 1
    local stage = self._Control:GetUiData().Stages[nextIndex]
    if stage and stage.IsUnlock then
        self.BtnNext:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnNext:SetButtonState(CS.UiButtonState.Disable)
    end
end

return XUiStageMemory