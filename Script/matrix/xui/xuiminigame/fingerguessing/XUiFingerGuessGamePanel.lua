-- 猜拳小游戏游戏进行面板控件
---@class XUiFingerGuessGamePanel
local XUiFingerGuessGamePanel = XClass(nil, "XUiFingerGuessGamePanel")
--================
--构造函数
--================
---@param rootUi XUiFingerGuessingGame
function XUiFingerGuessGamePanel:Ctor(uiGameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, uiGameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessGamePanel:InitPanel()
    self:InitPanelPK()
    self.PanelSelectFinger.gameObject:SetActiveEx(true)
    self:InitFingerBtns()
    self.ObjSelectRule.gameObject:SetActiveEx(true)
    if self.TxtTurn then self.TxtTurn.text = CS.XTextManager.GetText("FingerGuessingTurnStr", self.RootUi.Stage:GetCurrentRound(), self.RootUi.Stage:GetRoundNum()) end
end
--================
--初始化PK面板
--================
function XUiFingerGuessGamePanel:InitPanelPK()
    local PanelPK = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessPKPanel")
    self.PKPanel = PanelPK.New(self.PanelPK, self.RootUi)
    self.PKPanel.GameObject:SetActiveEx(false)
end
--================
--初始化出拳按钮
--================
function XUiFingerGuessGamePanel:InitFingerBtns()
    self.BtnRock.CallBack = function() self:OnClickBtnRock() end
    self.BtnScissors.CallBack = function() self:OnClickBtnScissors() end
    self.BtnPaper.CallBack = function() self:OnClickBtnPaper() end
end
--================
--石头按钮
--================
function XUiFingerGuessGamePanel:OnClickBtnRock()
    if self.IsPlayingFinger then return end
    self.IsPlayingFinger = true
    self:SavePreRound()
    self.RootUi:PlayAnimation("ChooseStone",function()
            XDataCenter.FingerGuessingManager.PlayFinger(XDataCenter.FingerGuessingManager.FINGER_TYPE.Rock)
        end)
end
--================
--剪刀按钮
--================
function XUiFingerGuessGamePanel:OnClickBtnScissors()
    if self.IsPlayingFinger then return end
    self.IsPlayingFinger = true
    self:SavePreRound()
    self.RootUi:PlayAnimation("ChooseScissors", function()
            XDataCenter.FingerGuessingManager.PlayFinger(XDataCenter.FingerGuessingManager.FINGER_TYPE.Scissors)
            end)
end
--================
--布按钮
--================
function XUiFingerGuessGamePanel:OnClickBtnPaper()
    if self.IsPlayingFinger then return end
    self.IsPlayingFinger = true
    self:SavePreRound()
    self.RootUi:PlayAnimation("ChooseCloth",function()
        XDataCenter.FingerGuessingManager.PlayFinger(XDataCenter.FingerGuessingManager.FINGER_TYPE.Paper)
    end)
end

function XUiFingerGuessGamePanel:SavePreRound()
    self.PreRound = self.RootUi.Stage:GetCurrentRound()
    self.PreActionId = self.RootUi.Stage:GetActionByRound(self.PreRound)
    --self.PreActionImg = self.RootUi.Stage:GetActionImg()
end

function XUiFingerGuessGamePanel:OnFingerPlay(fingerId, roundResult, isEnd)
    self:HideSelectFinger()
    self.PKPanel:ShowPanel(fingerId, self.PreRound, self.PreActionId, roundResult, isEnd, function() self:OnShowPKFinished(isEnd) end)
end

function XUiFingerGuessGamePanel:HideSelectFinger()
    self.ObjSelectRule.gameObject:SetActiveEx(false)
    self.TxtTurn.gameObject:SetActiveEx(false)
    self.PanelSelectFinger.gameObject:SetActiveEx(false)
end

function XUiFingerGuessGamePanel:OnShowPKFinished(isEnd)
    if not isEnd then
        self:ShowSelectFinger()
    else
        XLuaUiManager.Open("UiFingerGuessingResult", self.RootUi.Stage, function(result) self:OnShowResultEnd(result) end)
    end
    self.IsPlayingFinger = false
end

function XUiFingerGuessGamePanel:ShowSelectFinger()
    self.ObjSelectRule.gameObject:SetActiveEx(true)
    self.TxtTurn.gameObject:SetActiveEx(true)
    self.PanelSelectFinger.gameObject:SetActiveEx(true)
    self:RefreshSelectFinger()
end

function XUiFingerGuessGamePanel:RefreshSelectFinger()
    self.RootUi:OnRefreshRound()
    self.RootUi:PlayAnimation("GridEnable",function()
            if self.TxtTurn then self.TxtTurn.text = CS.XTextManager.GetText("FingerGuessingTurnStr", self.RootUi.Stage:GetCurrentRound(), self.RootUi.Stage:GetRoundNum()) end
        end)
end

function XUiFingerGuessGamePanel:OnShowResultEnd(result)
    local callBack = function()
        XLuaUiManager.PopThenOpen("UiFingerGuessingSelectStage", result)
    end
    if result and XDataCenter.FingerGuessingManager.GetIsFirstEndInStage(self.RootUi.Stage:GetStageId()) then
        local movieId = self.RootUi.Stage:GetEndMovieId()
        if not string.IsNilOrEmpty(movieId) then 
            XDataCenter.MovieManager.PlayMovie(movieId, callBack, nil, nil, false)
            return
        end
    end
    callBack()
end

function XUiFingerGuessGamePanel:OnEnable()
    self:AddEventListeners()
end

function XUiFingerGuessGamePanel:OnDisable()
    self:RemoveEventListeners()
end
--================
--注册事件
--================
function XUiFingerGuessGamePanel:AddEventListeners()
    if self.EventAdded then return end
    self.EventAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_FINGER_GUESS_PLAY_FINGER, self.OnFingerPlay, self)
end
--================
--注销事件
--================
function XUiFingerGuessGamePanel:RemoveEventListeners()
    if not self.EventAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_FINGER_GUESS_PLAY_FINGER, self.OnFingerPlay, self)
    self.EventAdded = false
end
return XUiFingerGuessGamePanel