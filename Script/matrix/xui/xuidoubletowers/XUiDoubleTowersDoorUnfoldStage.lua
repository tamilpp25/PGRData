local StageState = XDoubleTowersConfigs.StageState

---@class XUiDoubleTowersDoorUnfoldStage
local XUiDoubleTowersDoorUnfoldStage = XClass(nil, "XUiDoubleTowersDoorUnfoldStage")

function XUiDoubleTowersDoorUnfoldStage:Ctor(ui, parent)
    ---@type XUiDoubleTowersDoor
    self._Parent = parent
    self._StageId = -1
    self._IsSelected = false
    self._UiFinish = false

    XUiHelper.InitUiClass(self, ui)
    self.Transform = ui
    self:InitUi()
end

function XUiDoubleTowersDoorUnfoldStage:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, self.UpdateSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_ON_DETAIL_CLOSED, self.ClearSelected, self)
end

function XUiDoubleTowersDoorUnfoldStage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, self.UpdateSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_ON_DETAIL_CLOSED, self.ClearSelected, self)
end

function XUiDoubleTowersDoorUnfoldStage:UpdateSelected(stageId)
    self._IsSelected = self._StageId == stageId
    self:UpdateState(self._StageId)
end

function XUiDoubleTowersDoorUnfoldStage:ClearSelected()
    self._IsSelected = false
    self:UpdateState(self._StageId)
end

function XUiDoubleTowersDoorUnfoldStage:InitUi()
    self.Button = XUiHelper.TryGetComponent(self.Transform, "", "Button")
    self._UiFinish = self.Transform:Find("Finish")
    self:RegisterButtonClick()
end

function XUiDoubleTowersDoorUnfoldStage:SetStageId(stageId)
    if self._StageId == stageId then
        return
    end
    self._StageId = stageId
    if not stageId then
        self.GameObject:SetActiveEx(false)
        return
    end
    self:UpdateStageName(stageId)
    self:UpdateState(stageId)
end

function XUiDoubleTowersDoorUnfoldStage:UpdateState(stageId)
    local state = XDataCenter.DoubleTowersManager.GetStageState(stageId)
    self._UiFinish.gameObject:SetActiveEx(state == StageState.Clear)
    if state == StageState.Clear then
        self:UpdateNormalState()
        return
    end
    if state == StageState.NotClear then
        self:UpdateNormalState()
        return
    end
    if state == StageState.Lock then
        self.Button:SetButtonState(CS.UiButtonState.Disable)
        return
    end
end

function XUiDoubleTowersDoorUnfoldStage:UpdateNormalState()
    if self._IsSelected then
        self.Button:SetButtonState(CS.UiButtonState.Select)
    else
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    end
end

-- 由于这部分text都是关卡名，且无甚意义，因此代码统一处理
function XUiDoubleTowersDoorUnfoldStage:UpdateStageName(stageId)
    local name = XDoubleTowersConfigs.GetStageName(stageId)
    self:SetStageNameByPath(name, "Normal/TxtLevel")
    self:SetStageNameByPath(name, "Press/TxtLevel")
    self:SetStageNameByPath(name, "Select/TxtLevel")
    self:SetStageNameByPath(name, "Disable/TxtLevel")
    self:SetStageNameByPath(name, "Finish/TxtLevel")
end

function XUiDoubleTowersDoorUnfoldStage:SetStageNameByPath(name, uiPath)
    local textComponent = XUiHelper.TryGetComponent(self.Transform, uiPath, "Text")
    if textComponent then
        textComponent.text = name
    end
end

function XUiDoubleTowersDoorUnfoldStage:RegisterButtonClick()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnStageClick)
end

function XUiDoubleTowersDoorUnfoldStage:OnStageClick()
    if not self._Parent:IsUnfold() then
        return
    end

    local stageId = self._StageId
    if not stageId then
        return
    end

    -- 已通关
    -- if XDataCenter.DoubleTowersManager.IsStageClear(stageId) then
    --     XUiManager.TipErrorWithKey("DoubleTowersPassed")
    --     return
    -- end

    -- 不可挑战
    if not XDataCenter.DoubleTowersManager.IsStageCanChallenge(stageId) then
        local preconditionStageId = XDoubleTowersConfigs.GetPreconditionStage(stageId)
        if not XDataCenter.DoubleTowersManager.IsStageClear(preconditionStageId) then
            local stageName = XDoubleTowersConfigs.GetStageName(preconditionStageId)
            XUiManager.TipErrorWithKey("DoubleTowersPreconditionStageNotClear", stageName)
        else
            XLog.Debug("[XUiDoubleTowersDoorUnfoldStage] other reason to lock stage, please fix it")
        end
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, stageId)
    local groupIndex = XDoubleTowersConfigs.GetGroupIndexByStageId(stageId)
    if groupIndex then
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_FOCUS, groupIndex)
    end
end

return XUiDoubleTowersDoorUnfoldStage
