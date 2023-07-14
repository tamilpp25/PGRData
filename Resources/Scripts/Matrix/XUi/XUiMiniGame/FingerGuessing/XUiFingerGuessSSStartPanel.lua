-- 选择关卡界面开始挑战面板控件
local XUiFingerGuessSSStartPanel = XClass(nil, "XUiFingerGuessSSStartPanel")
local INITIAL_COST_NUM = 99999
--================
--构造函数
--================
function XUiFingerGuessSSStartPanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessSSStartPanel:InitPanel()
    self.RImgCoinIcon:SetRawImage(self.RootUi.GameController:GetCoinItemIcon())
    self:SetTxtCostCoin(INITIAL_COST_NUM)
    self.BtnStart.CallBack = function() self:OnClickBtnStart() end
end
--================
--选择关卡时
--================
function XUiFingerGuessSSStartPanel:OnStageSelected()
    local isClear = self.RootUi.StageSelected:GetIsClear()
    self.TxtHistoryScore.gameObject:SetActiveEx(isClear)
    self.ObjHistoryScoreTips.gameObject:SetActiveEx(isClear)
    self.RImgCoinIcon.gameObject:SetActiveEx(not isClear)
    self.TxtCostCoin.gameObject:SetActiveEx(not isClear)
    self.ObjCostCoinTips.gameObject:SetActiveEx(not isClear)
    if self.RootUi.StageSelected:GetIsClear() then
        self.TxtHistoryScore.text = CS.XTextManager.GetText("FingerGuessingHighScore", self.RootUi.StageSelected:GetHighScore())
    elseif self.RootUi.StageSelected:CheckIsFirstEntry() then
        self:SetTxtCostCoin(self.RootUi.StageSelected:GetCostItemCount())
    else
        self:SetTxtCostCoin(0)
    end
end
--================
--设置消耗金币文本
--================
function XUiFingerGuessSSStartPanel:SetTxtCostCoin(cost)
    if self.RootUi.GameController:CheckCoinEnough(cost) then
        self.TxtCostCoin.text = cost
    else
        self.TxtCostCoin.text = CS.XTextManager.GetText("CommonRedText", cost)
    end
end
--================
--点击开始挑战按钮
--================
function XUiFingerGuessSSStartPanel:OnClickBtnStart()
    if not self.RootUi.StageSelected then
        XUiManager.TipMsg(CS.XTextManager.GetText("FingerGuessingStageNotSelect"))
    elseif not self.RootUi.StageSelected:GetIsOpen() then
        XUiManager.TipMsg(CS.XTextManager.GetText("FingerGuessingStageNotOpen"))
    else
        XDataCenter.FingerGuessingManager.StartGame(self.RootUi.StageSelected)
    end
end
--================
--开始游戏回调
--================
function XUiFingerGuessSSStartPanel:OnStartGame(stage)
    XLuaUiManager.PopThenOpen("UiFingerGuessingGame", stage)
end

function XUiFingerGuessSSStartPanel:OnEnable()
    self:AddEventListeners()
end

function XUiFingerGuessSSStartPanel:OnDisable()
    self:RemoveEventListeners()
end
--================
--注册事件
--================
function XUiFingerGuessSSStartPanel:AddEventListeners()
    if self.EventAdded then return end
    self.EventAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_FINGER_GUESS_GAME_START, self.OnStartGame, self)
end
--================
--注销事件
--================
function XUiFingerGuessSSStartPanel:RemoveEventListeners()
    if not self.EventAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_FINGER_GUESS_GAME_START, self.OnStartGame, self)
    self.EventAdded = false
end

return XUiFingerGuessSSStartPanel