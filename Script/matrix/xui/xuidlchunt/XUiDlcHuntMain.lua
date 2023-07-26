local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiDlcHuntMain:XLuaUi
local XUiDlcHuntMain = XLuaUiManager.Register(XLuaUi, "UiDlcHuntMain")

local CHILD_UI = {
    UiDlcHuntBoss = "UiDlcHuntBoss",
    UiDlcHuntBossLevel = "UiDlcHuntBossLevel",
}

function XUiDlcHuntMain:Ctor()
end

function XUiDlcHuntMain:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, self.OnClickTutorial)
    XUiHelper.RegisterClickEvent(self, self.PanelBt, self.OnClickShop)
    XUiHelper.RegisterClickEvent(self, self.PanelCy, self.OnClickCharacter)
    XUiHelper.RegisterClickEvent(self, self.PanelBb, self.OnClickBag)
    XUiHelper.RegisterClickEvent(self, self.PanelXp, self.OnClickChip)
    XUiHelper.RegisterClickEvent(self, self.ButtonTask, self.OnClickTask)
    XUiHelper.RegisterClickEvent(self, self.BtnSupport, self.OnClickSupport)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnClickStart)

    local root = self.UiModelGo.transform
    local sceneAnimationEnable = XUiHelper.TryGetComponent(root, "Animation/Enable", "PlayableDirector")
    sceneAnimationEnable.gameObject:PlayTimelineAnimation()

    self.Case1 = root:FindTransform("Case1")
    self.Case2 = root:FindTransform("Case2")

    local panelRoleModel1 = self.Case1:FindTransform("PanelRoleModel1")
    local panelRoleModel2 = self.Case2:FindTransform("PanelRoleModel2")
    local panelRoleModel3 = self.Case2:FindTransform("PanelRoleModel3")

    ---@type XUiPanelRoleModel
    self._UiModel1 = XUiPanelRoleModel.New(panelRoleModel1, self.Name, nil, true)

    ---@type XUiPanelRoleModel
    self._UiModel2 = XUiPanelRoleModel.New(panelRoleModel2, self.Name, nil, true)

    ---@type XUiPanelRoleModel
    self._UiModel3 = XUiPanelRoleModel.New(panelRoleModel3, self.Name, nil, true)

    self._UiEffectHuanren1 = XUiHelper.TryGetComponent(panelRoleModel1, "ImgEffectHuanren", "Transform")
    self._UiEffectHuanren1.gameObject:SetActiveEx(false)

    self._UiEffectHuanren2 = XUiHelper.TryGetComponent(panelRoleModel2, "ImgEffectHuanren", "Transform")
    self._UiEffectHuanren2.gameObject:SetActiveEx(false)

    self._UiEffectHuanren3 = XUiHelper.TryGetComponent(panelRoleModel3, "ImgEffectHuanren", "Transform")
    self._UiEffectHuanren3.gameObject:SetActiveEx(false)

    self:UpdateBossModel(XDlcHuntConfigs.GetModelMainUi(), nil, false)

    self._UiCameraMain = root:FindTransform("UiNearMain")
    self._UiCameraBoss = root:FindTransform("UiNearBoss")
    self._UiCameraBossLevel = root:FindTransform("UiNearBossLevel")

    local uiFarRootObj = self.UiModel.UiFarRoot
    self._UiCameraMainFar = uiFarRootObj:FindTransform("UiFarMain")
    self._UiCameraBossFar = uiFarRootObj:FindTransform("UiFarBoss")
    self._UiCameraBossLevelFar = uiFarRootObj:FindTransform("UiFarBossLevel")

    self._UiCameraMain.gameObject:SetActiveEx(true)
    self._UiCameraMainFar.gameObject:SetActiveEx(true)

    local helpBtn = XUiHelper.TryGetComponent(self.BtnBack.transform.parent, "BtnHelp (1)", "Button")
    self:BindHelpBtn(helpBtn, XDlcHuntConfigs.HELP_KEY.MAIN)
end

function XUiDlcHuntMain:OnEnable()
    if XDataCenter.DlcRoomManager.IsCanReconnect() then
        XDataCenter.DlcRoomManager.ReconnectToRoom()
    end
    self:UpdateTask()
    XDataCenter.DlcHuntManager.ReceiveAssistPointRequest()
end

function XUiDlcHuntMain:OnBtnClickStart()
    self:DlcOpenChildUi(CHILD_UI.UiDlcHuntBoss)
end

function XUiDlcHuntMain:OnClickBag()
    XLuaUiManager.Open("UiDlcHuntBag")
end

function XUiDlcHuntMain:OnClickChip()
    XLuaUiManager.Open("UiDlcHuntChipMain")
end

function XUiDlcHuntMain:OnClickCharacter()
    XLuaUiManager.Open("UiDlcHuntCharacter")
end

function XUiDlcHuntMain:OnClickTask()
    XLuaUiManager.Open("UiDlcHuntTask")
end

function XUiDlcHuntMain:OnClickShop()
    XLuaUiManager.Open("UiDlcHuntShop")
end

local sortFunc = function(a, b)
    return a.Id < b.Id
end

function XUiDlcHuntMain:UpdateTask()
    local taskDict1 = XDataCenter.TaskManager.GetTaskByTypeAndGroup(TaskType.DlcHunt, XDlcHuntConfigs.GetWeekTaskGroupId())
    local taskDict2 = XDataCenter.TaskManager.GetTaskByTypeAndGroup(TaskType.DlcHunt, XDlcHuntConfigs.GetTaskGroupId())

    local taskList1 = {}
    local taskList2 = {}
    local taskListAll = {}

    for id, task in pairs(taskDict1) do
        taskList1[#taskList1 + 1] = task
    end
    for id, task in pairs(taskDict2) do
        taskList2[#taskList2 + 1] = task
    end

    --a.已完成但未领取奖励的任务，按照每周任务→活动任务的顺序，同类型任务按照TaskId由小到大
    table.sort(taskList1, sortFunc)
    table.sort(taskList2, sortFunc)

    taskListAll = XTool.MergeArray(taskList1, taskList2)

    local taskFinish = false
    --b.其次，显示未完成的任务，同样按照每周任务→活动任务的顺序
    local taskDoing = false

    local TaskState = XDataCenter.TaskManager.TaskState
    for id, task in pairs(taskListAll) do
        if not taskFinish then
            if task.State == TaskState.Achieved then
                taskFinish = task
                break
            end
        end
        if not taskDoing then
            if task.State ~= TaskState.Finish and task.State ~= TaskState.Invalid and task.State ~= TaskState.Achieved then
                taskDoing = task
            end
        end
    end

    local taskCurrent = taskFinish or taskDoing
    if not taskCurrent then
        --c.当所有任务类型都已完成且已领取奖励时，显示：【所有任务已完成】
        self.TxtKill.text = XUiHelper.GetText("DlcHuntTaskFinish")
    else
        local id = taskCurrent.Id
        local config = XDataCenter.TaskManager.GetTaskTemplate(id)
        local text1 = config.Title
        local text2 = config.Desc
        self.TxtKill.text = string.format("%s\n%s", text1, text2)
    end

    self:UpdateRedTask(taskFinish and true or false)
end

function XUiDlcHuntMain:OnClickSupport()
    XLuaUiManager.Open("UiDlcHuntPersonalSupport")
end

function XUiDlcHuntMain:OnClickTutorial()
    XDataCenter.DlcRoomManager.CreateRoomTutorial()
end

function XUiDlcHuntMain:UpdateRedTask(value)
    self.RedTask.gameObject:SetActiveEx(value)
end

function XUiDlcHuntMain:UpdateBossModel(modelId1, modelId2, playEffect)
    if modelId1 and modelId2 then
        self.Case1.gameObject:SetActiveEx(false)
        self.Case2.gameObject:SetActiveEx(true)
        self:UpdateChildModel(modelId1, self._UiModel2, self._UiEffectHuanren2, playEffect)
        self:UpdateChildModel(modelId2, self._UiModel3, self._UiEffectHuanren3, playEffect)
        return
    end
    if modelId1 and not modelId2 then
        self.Case1.gameObject:SetActiveEx(true)
        self.Case2.gameObject:SetActiveEx(false)
        self:UpdateChildModel(modelId1, self._UiModel1, self._UiEffectHuanren1, playEffect)
        return
    end
    self.Case1.gameObject:SetActiveEx(false)
    self.Case2.gameObject:SetActiveEx(false)
end

function XUiDlcHuntMain:UpdateChildModel(modelId, uiModel, uiEffect, playEffect)
    local funcRemoveComponentFight = function(model)
        -- 战斗用脚本，ui上会报错，后续此问题可能会继续扩增
        local componentUNpc = model:GetComponent("UNpc")
        if componentUNpc then
            XUiHelper.Destroy(componentUNpc)
        end
    end
    uiModel:UpdateBossModel(modelId, nil, nil, funcRemoveComponentFight)
    if playEffect ~= false then
        uiEffect.gameObject:SetActiveEx(false)
        uiEffect.gameObject:SetActiveEx(true)
    end
end

-- 与XLuaUi冲突，故加前缀Dlc
function XUiDlcHuntMain:DlcOpenChildUi(name, ...)
    self:OpenOneChildUi(name, ...)
    if name == CHILD_UI.UiDlcHuntBossLevel then
        self:CloseChildUi(CHILD_UI.UiDlcHuntBoss)
        self._UiCameraBossLevel.gameObject:SetActiveEx(true)
        self._UiCameraBossLevelFar.gameObject:SetActiveEx(true)
    end
    if name == CHILD_UI.UiDlcHuntBoss then
        self._UiCameraBoss.gameObject:SetActiveEx(true)
        self._UiCameraBossFar.gameObject:SetActiveEx(true)
    end
    local transform = self.Transform
    for i = 0, transform.childCount - 1 do
        local child = transform:GetChild(i)
        if child.name ~= name then
            child.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcHuntMain:DlcCloseChildUi(name)
    self:CloseChildUi(name)
    if name == CHILD_UI.UiDlcHuntBossLevel then
        self:OpenOneChildUi(CHILD_UI.UiDlcHuntBoss)
        self._UiCameraBossLevel.gameObject:SetActiveEx(false)
        self._UiCameraBossLevelFar.gameObject:SetActiveEx(false)
    end
    if name == CHILD_UI.UiDlcHuntBoss then
        local transform = self.Transform
        for i = 0, transform.childCount - 1 do
            local child = transform:GetChild(i);
            if not CHILD_UI[child.name] then
                child.gameObject:SetActiveEx(true)
            end
        end
        self._UiCameraBoss.gameObject:SetActiveEx(false)
        self._UiCameraBossFar.gameObject:SetActiveEx(false)
    end
end

return XUiDlcHuntMain