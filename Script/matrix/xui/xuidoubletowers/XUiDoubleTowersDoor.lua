local StageState = XDoubleTowersConfigs.StageState

---@class XUiDoubleTowersDoor
local XUiDoubleTowersDoor = XClass(nil, "XUiDoubleTowersDoor")

function XUiDoubleTowersDoor:Ctor(ui)
    self._GroupId = false
    self._IsUnfold = false
    self._Timer = false
    ---@type XUiDoubleTowersDoorUnfoldStage[]
    self._UiStage = {}

    XUiHelper.InitUiClass(self, ui)
    self:InitUi()
end

function XUiDoubleTowersDoor:OnEnable()
    for i = 1, #self._UiStage do
        self._UiStage[i]:OnEnable()
    end
    self:BeginTimer()
end

function XUiDoubleTowersDoor:OnDisable()
    for i = 1, #self._UiStage do
        self._UiStage[i]:OnDisable()
    end
    self:StopTimer()
end

function XUiDoubleTowersDoor:GetButtonComponent()
    return self.ButtonTower
end

function XUiDoubleTowersDoor:SetGroup(groupId)
    self._GroupId = groupId
    self.TowerNumber.gameObject:SetActiveEx(false)
    if self:CountDown() then
        self:BeginTimer()
    else
        self:StopTimer()
    end
    self:UpdateStage(groupId)
    self:UpdateStageName(groupId)
    self.TowerSelect.gameObject:SetActiveEx(false)
    self:ShowDoor()
end

function XUiDoubleTowersDoor:ShowDoor()
    local state = XDataCenter.DoubleTowersManager.GetGroupState(self._GroupId)
    if state == StageState.NotClear then
        self.TowerNormal.gameObject:SetActiveEx(true)
        self.TowerFinish.gameObject:SetActiveEx(false)
        self.TowerLock.gameObject:SetActiveEx(false)
        return
    end
    if state == StageState.Lock then
        self.TowerNormal.gameObject:SetActiveEx(false)
        self.TowerFinish.gameObject:SetActiveEx(false)
        self.TowerLock.gameObject:SetActiveEx(true)
        return
    end
    if state == StageState.Clear then
        self.TowerNormal.gameObject:SetActiveEx(false)
        self.TowerFinish.gameObject:SetActiveEx(true)
        self.TowerLock.gameObject:SetActiveEx(false)
        return
    end
end

function XUiDoubleTowersDoor:HideDoor()
    self.TowerNormal.gameObject:SetActiveEx(false)
    self.TowerFinish.gameObject:SetActiveEx(false)
    self.TowerLock.gameObject:SetActiveEx(false)
end

function XUiDoubleTowersDoor:UpdateStage(groupId)
    for i = 1, #self._UiStage do
        local uiStage = self._UiStage[i]
        local stageId = XDataCenter.DoubleTowersManager.GetStageId(groupId, i)
        uiStage:SetStageId(stageId)
    end
end

function XUiDoubleTowersDoor:Fold()
    self._IsUnfold = false
    self:ShowDoor()
    if self.TowerSelect.gameObject.activeInHierarchy then
        self.TowerSelectDisable.gameObject:PlayTimelineAnimation(
            function()
                if not self._IsUnfold then
                    self.TowerSelect.gameObject:SetActiveEx(false)
                end
            end
        )
    end
end

function XUiDoubleTowersDoor:Unfold()
    self._IsUnfold = true
    local state = XDataCenter.DoubleTowersManager.GetGroupState(self._GroupId)
    self.TowerSelect.gameObject:SetActiveEx(true)
    self.TowerSelectEnable.gameObject:PlayTimelineAnimation()
    self:HideDoor()
end

function XUiDoubleTowersDoor:BeginTimer()
    if self._Timer then
        return
    end
    if not self:CountDown() then
        return
    end
    self.TowerNumber.gameObject:SetActiveEx(true)
    self._Timer =
        XScheduleManager.ScheduleForever(
        function()
            self:CountDown()
        end,
        XScheduleManager.SECOND
    )
end

function XUiDoubleTowersDoor:CountDown()
    local remainTime = XDataCenter.DoubleTowersManager.GetGroupOpenRemainTime(self._GroupId)
    if remainTime <= 0 then
        self:StopTimer()
        self:ShowDoor()
        self.TowerNumber.gameObject:SetActiveEx(false)
        return false
    end
    self.CountDownText.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DOUBLE_TOWER)
    return true
end

function XUiDoubleTowersDoor:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

-- 由于这部分text都是关卡名，且无甚意义，因此代码统一处理
function XUiDoubleTowersDoor:UpdateStageName(groupId)
    local name = XDoubleTowersConfigs.GetGroupName(groupId)
    self:SetStageName(name, self.TxtTowers1)
    self:SetStageName(name, self.TxtTowers2)
    self:SetStageName(name, self.TxtTowers3)
    self:SetStageName(name, self.TxtTowers4)
end

function XUiDoubleTowersDoor:SetStageName(name, textComponent)
    textComponent.text = name
end

function XUiDoubleTowersDoor:InitUi()
    self.TowerSelectDisable =
        XUiHelper.TryGetComponent(self.Transform, "Animation/TowerSelectDisable", "PlayableDirector")
    self.TowerSelectEnable =
        XUiHelper.TryGetComponent(self.Transform, "Animation/TowerSelectEnable", "PlayableDirector")
    self:InitUnfoldStage()
end

function XUiDoubleTowersDoor:InitUnfoldStage()
    local XUiDoubleTowersDoorUnfoldStage = require("XUi/XUiDoubleTowers/XUiDoubleTowersDoorUnfoldStage")
    for i = 1, XDoubleTowersConfigs.MaxStageAmountPerGroup do
        local uiStage = self.Transform:Find("TowerSelect/BtnLevel/BtnLevel" .. i)
        if uiStage then
            self._UiStage[i] = XUiDoubleTowersDoorUnfoldStage.New(uiStage, self)
        end
    end
end

function XUiDoubleTowersDoor:IsUnfold()
    return self._IsUnfold
end

return XUiDoubleTowersDoor
