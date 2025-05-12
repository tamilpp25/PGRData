local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
-- 猜拳小游戏游戏进行界面
---@class XUiFingerGuessingGame : XLuaUi
---@field Stage XFingerGuessingStage
local XUiFingerGuessingGame = XLuaUiManager.Register(XLuaUi, "UiFingerGuessingGame")

--================
--OnAwake 初始化UiObject
--================
function XUiFingerGuessingGame:OnAwake()
    XTool.InitUiObject(self)
    self.GameController = XDataCenter.FingerGuessingManager.GetGameController()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    if self.BtnHelp then self.BtnHelp.CallBack = function() self:OnClickBtnHelp() end end
end
--================
--点击返回按钮
--================
function XUiFingerGuessingGame:OnClickBtnBack()
    self:Close()
end
--================
--点击主界面按钮
--================
function XUiFingerGuessingGame:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--================
--点击帮助按钮
--================
function XUiFingerGuessingGame:OnClickBtnHelp()
    XUiManager.ShowHelpTip("FingerGuessingGameHelp")
end
--================
--OnStart 加载关卡对象和初始化界面
--@param currentStage:正在进行的关卡
--================
function XUiFingerGuessingGame:OnStart(currentStage)
    self.Stage = currentStage
    self:InitPanels()
end
--================
--OnEnable 每次显示界面时注册事件
--================
function XUiFingerGuessingGame:OnEnable()
    self:RunAllPanelsFunc("OnEnable")
end
--================
--OnDisable 界面隐藏或销毁时注销事件
--================
function XUiFingerGuessingGame:OnDisable()
    self:RunAllPanelsFunc("OnDisable")
end
--================
--初始化所有面板控件
--================
function XUiFingerGuessingGame:InitPanels()
    self.Panels = {}
    self:InitPanelAsset()
    self:InitPanelTitle()
    self:InitPanelEye()
    self:InitPanelUpper()
    self:InitPanelLower()
end
--================
--初始化资源代币面板
--================
function XUiFingerGuessingGame:InitPanelAsset()
    local coinId = self.GameController:GetCoinItemId()
    local asset = XUiPanelAsset.New(self, self.PanelAsset, coinId)
    asset:RegisterJumpCallList({[1] = function()
                XLuaUiManager.Open("UiTip", coinId)
            end})
end
--================
--初始化标题面板
--================
function XUiFingerGuessingGame:InitPanelTitle()
    local PanelTitle = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSTitlePanel")
    self.TitlePanel = PanelTitle.New(self.PanelTitle, self)
    table.insert(self.Panels, self.TitlePanel)
end
--================
--初始化天眼面板
--================
function XUiFingerGuessingGame:InitPanelEye()
    local PanelEye = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessingEyePanel")
    self.EyePanel = PanelEye.New(self.PanelEye, self)
    table.insert(self.Panels, self.EyePanel)
end
--================
--初始化得分牌面板
--================
function XUiFingerGuessingGame:InitPanelUpper()
    local PanelScore = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessScorePanel")
    self.ScorePanel = PanelScore.New(self.PanelUpper, self)
    table.insert(self.Panels, self.ScorePanel)
end
--================
--初始化猜拳面板
--================
function XUiFingerGuessingGame:InitPanelLower()
    local PanelGame = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessGamePanel")
    self.GamePanel = PanelGame.New(self.PanelLower, self)
    table.insert(self.Panels, self.GamePanel)
end
--================
--运行所有面板指定方法
--@param funcName:方法名
--================
function XUiFingerGuessingGame:RunAllPanelsFunc(funcName)
    for _, panel in pairs(self.Panels) do
        local func = panel[funcName]
        if func then func(panel) end
    end
end

function XUiFingerGuessingGame:OnRefreshRound()
    self:RunAllPanelsFunc("OnStageRefresh")
end
--================
--活动结束时处理
--================
function XUiFingerGuessingGame:OnGameEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end