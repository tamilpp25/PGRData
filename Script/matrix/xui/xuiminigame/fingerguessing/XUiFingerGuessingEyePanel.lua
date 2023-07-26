-- 选择关卡界面天眼面板
local XUiFingerGuessingEyePanel = XClass(nil, "XUiFingerGuessingEyePanel")
local RULE_INITIAL_STR = "RULE_INITIAL"
local FINGER_TYPE
--================
--构造函数
--================
function XUiFingerGuessingEyePanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessingEyePanel:InitPanel()
    if self.TxtRule then self.TxtRule.text = RULE_INITIAL_STR end
    if self.BtnOpenEye then
        self.BtnOpenEye.CallBack = function() self:OnClickBtnOpenEye() end
        self.BtnOpenEye.ButtonState = CS.UiButtonState.Disable
    end
    self:InitFingers()
end
--================
--选择关卡时
--================
function XUiFingerGuessingEyePanel:OnStageSelected()
    self:SetBtnOpenEyeStatus(self.RootUi.GameController:GetIsOpenEye())
    self:RefreshStageFingers()
    self.TxtRule.text = CS.XTextManager.GetText("FingerGuessingOpenEyeRuleStr", self.RootUi.StageSelected:GetCheatCount())
end
--================
--关卡更新时
--================
function XUiFingerGuessingEyePanel:OnStageRefresh()
    self:RefreshStageFingers()
end
--================
--刷新出拳列表
--================
function XUiFingerGuessingEyePanel:RefreshStageFingers()
    local stage = self.RootUi.StageSelected or self.RootUi.Stage
    if not stage then return end
    for _, fingerId in pairs(FINGER_TYPE) do
        self.Fingers[fingerId]:RefreshFinger(fingerId, stage:GetFingerTextByFingerId(fingerId))
    end
end
--================
--初始化猜拳控件
--================
function XUiFingerGuessingEyePanel:InitFingers()
    local FingerScript = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessFinger")
    self.Fingers = {}
    self.GridFinger.gameObject:SetActiveEx(false)
    if not FINGER_TYPE then
        FINGER_TYPE = {}
        for _, fingerId in pairs(XDataCenter.FingerGuessingManager.FINGER_TYPE) do
            FINGER_TYPE[fingerId + 1] = fingerId
        end
    end
    for _, fingerId in pairs(FINGER_TYPE) do
        local ui = CS.UnityEngine.GameObject.Instantiate(self.GridFinger)
        ui.transform:SetParent(self.PanelFinger.transform, false)
        ui.gameObject:SetActiveEx(true)
        self.Fingers[fingerId] = FingerScript.New(ui, fingerId)
    end
    self:RefreshStageFingers()
end
--================
--设置按钮状态
--================
function XUiFingerGuessingEyePanel:SetBtnOpenEyeStatus(isOpen)
    if not self.BtnOpenEye then return end
    if isOpen then
        self.BtnOpenEye.ButtonState = CS.UiButtonState.Disable
    else
        self.BtnOpenEye.ButtonState = CS.UiButtonState.Normal
    end
end
--================
--点击开眼按钮
--================
function XUiFingerGuessingEyePanel:OnClickBtnOpenEye()
    if self.BtnOpenEye.ButtonState == CS.UiButtonState.Disable then
        XUiManager.TipMsg(CS.XTextManager.GetText("FingerGuessingEyeClose"))
        XDataCenter.FingerGuessingManager.OpenEyes(self.RootUi.StageSelected)
        return
    else
        local tipTitle = self.RootUi.StageSelected:GetOpenEyeTipsTitle() or CS.XTextManager.GetText("FingerGuessingEyeOpenTipsTitle")
        local tipContent = self.RootUi.StageSelected:GetOpenEyeTipsContent() or CS.XTextManager.GetText("FingerGuessingEyeOpenTipsContent")
        XLuaUiManager.Open("UiDialog", tipTitle, tipContent, XUiManager.DialogType.Normal, nil, function() XDataCenter.FingerGuessingManager.OpenEyes(self.RootUi.StageSelected) end)
    end
end

function XUiFingerGuessingEyePanel:OnEnable()
    self:AddEventListeners()
end

function XUiFingerGuessingEyePanel:OnDisable()
    self:RemoveEventListeners()
end
--================
--注册事件
--================
function XUiFingerGuessingEyePanel:AddEventListeners()
    if self.EventAdded then return end
    self.EventAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_FINGER_GUESS_OPEN_EYE, self.OnStageSelected, self)
end
--================
--注销事件
--================
function XUiFingerGuessingEyePanel:RemoveEventListeners()
    if not self.EventAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_FINGER_GUESS_OPEN_EYE, self.OnStageSelected, self)
    self.EventAdded = false
end
return XUiFingerGuessingEyePanel