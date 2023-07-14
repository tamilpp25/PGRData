-- 选择关卡界面关卡面板
local XUiFingerGuessSSLevelPanel = XClass(nil, "XUiFingerGuessSSLevelPanel")

function XUiFingerGuessSSLevelPanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessSSLevelPanel:InitPanel()
    self.GridStage.gameObject:SetActiveEx(false)
    self:InitStages()
    self:RefreshProgress()
    XUiHelper.RegisterClickEvent(self, self.RImgTreasure, self.OnClickTask, self)
end
--================
--显示面板时
--================
function XUiFingerGuessSSLevelPanel:OnEnable()
    self:AddEventListeners()
    self:RefreshProgress()
end
--================
--隐藏面板时
--================
function XUiFingerGuessSSLevelPanel:OnDisable()
    self:RemoveEventListeners()
end
--================
--初始化关卡进度
--================
function XUiFingerGuessSSLevelPanel:SetTxtStageProgress(current, total)
    self.TxtStageProgress.text = string.format(tostring(current) .. "/" .. tostring(total))
end
--================
--初始化关卡
--================
function XUiFingerGuessSSLevelPanel:InitStages()
    local StageScript = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessStage")
    self.Stages = {}
    local lastStage
    local isLast = false
    local stageList = self.RootUi.GameController:GetAllStages()
    for _, stage in pairs(stageList) do
        local ui = CS.UnityEngine.GameObject.Instantiate(self.GridStage)
        ui.transform:SetParent(self.PanelStage.transform, false)
        ui.gameObject:SetActiveEx(true)
        self.Stages[stage:GetId()] = StageScript.New(ui, stage, self.RootUi)
        if not isLast then lastStage = self.Stages[stage:GetId()] end
        if not stage:GetIsClear() then
            isLast = true
        end
    end
    lastStage:OnClickStageSelect()
end
--================
--刷新关卡列表
--================
function XUiFingerGuessSSLevelPanel:RefreshStages()
    for _, stage in pairs(self.Stages) do
        stage:Refresh()
    end
    self:RefreshProgress()
end

function XUiFingerGuessSSLevelPanel:RefreshProgress()
    self.ImgRedProgress.gameObject:SetActiveEx(XDataCenter.TaskManager.GetFingerGuessingHaveAchievedTask())
    local achived, total = XDataCenter.TaskManager.GetFingerGuessingTaskNum()
    self:SetTxtStageProgress(achived, total)
    self.ImgJindu.fillAmount = achived / ((total and total > 0 and total) or 1)
end
--================
--宝箱按钮点击
--================
function XUiFingerGuessSSLevelPanel:OnClickTask()
    XLuaUiManager.Open("UiFingerGuessingTask")
end
--================
--注册监听
--================
function XUiFingerGuessSSLevelPanel:AddEventListeners()
    if self.ListenersAdded then return end
    self.ListenersAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshProgress, self)
end
--================
--注销监听
--================
function XUiFingerGuessSSLevelPanel:RemoveEventListeners()
    if not self.ListenersAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshProgress, self)
    self.ListenersAdded = false
end
return XUiFingerGuessSSLevelPanel