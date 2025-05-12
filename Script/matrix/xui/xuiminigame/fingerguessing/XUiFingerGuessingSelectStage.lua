local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
-- 猜拳选择关卡界面
---@class XUiFingerGuessingSelectStage : XLuaUi
---@field GameController XFingerGuessingGameController
---@field StageSelected XFingerGuessingStage
local XUiFingerGuessingSelectStage = XLuaUiManager.Register(XLuaUi, "UiFingerGuessingSelectStage")
--================
--OnAwake 初始化界面
--================
function XUiFingerGuessingSelectStage:OnAwake()
    XTool.InitUiObject(self)
    self.GameController = XDataCenter.FingerGuessingManager.GetGameController()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    if self.BtnHelp then self.BtnHelp.CallBack = function() self:OnClickBtnHelp() end end
    self:InitPanels()
end

function XUiFingerGuessingSelectStage:OnStart(result)
    --如果是从一局游戏结束打开此界面的话，检查对局结果
    if result == false then
        XUiManager.TipMsg(CS.XTextManager.GetText("FingerGuessingOpenEyeTips"))
    end
end
--================
--点击返回按钮
--================
function XUiFingerGuessingSelectStage:OnClickBtnBack()
    self:Close()
end
--================
--点击主界面按钮
--================
function XUiFingerGuessingSelectStage:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--================
--点击帮助按钮
--================
function XUiFingerGuessingSelectStage:OnClickBtnHelp()
    XUiManager.ShowHelpTip("FingerGuessingGameHelp")
end
--================
--初始化所有面板控件
--================
function XUiFingerGuessingSelectStage:InitPanels()
    self.Panels = {}
    self:InitPanelAsset()
    self:InitPanelTitle()
    self:InitPanelExplain()
    self:InitPanelStart()
    self:InitPanelRole()
    self:InitPanelEye()
    self:InitPanelLevel()
end
--================
--OnEnable 调用所有子面板OnEnable方法
--================
function XUiFingerGuessingSelectStage:OnEnable()
    self:RunAllPanelsFunc("OnEnable")
    if XDataCenter.FingerGuessingManager.GetIsFirstIn() then
        local callBack = function()
            XUiManager.ShowHelpTip("FingerGuessingGameHelp")
        end
        local movieId = self.GameController:GetStartMovieId()
        if not string.IsNilOrEmpty(movieId) then
            XDataCenter.MovieManager.PlayMovie(movieId, callBack, nil, nil, false)
        else
            callBack()
        end
    end
end
--================
--OnDisable 调用所有子面板OnDisable方法
--================
function XUiFingerGuessingSelectStage:OnDisable()
    self:RunAllPanelsFunc("OnDisable")
end
--================
--初始化资源代币面板
--================
function XUiFingerGuessingSelectStage:InitPanelAsset()
    local coinId = self.GameController:GetCoinItemId()
    local asset = XUiPanelAsset.New(self, self.PanelAsset, coinId)
    asset:RegisterJumpCallList({[1] = function()
                XLuaUiManager.Open("UiTip", coinId)
            end})
end
--================
--初始化标题面板
--================
function XUiFingerGuessingSelectStage:InitPanelTitle()
    local PanelTitle = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSTitlePanel")
    table.insert(self.Panels, PanelTitle.New(self.PanelTitle, self))
end
--================
--初始化规则解说面板
--================
function XUiFingerGuessingSelectStage:InitPanelExplain()
    local PanelExplain = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSExplainPanel")
    table.insert(self.Panels, PanelExplain.New(self.PanelExplain, self))
end
--================
--初始化开始挑战面板
--================
function XUiFingerGuessingSelectStage:InitPanelStart()
    local PanelStart = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSStartPanel")
    table.insert(self.Panels, PanelStart.New(self.PanelStart, self))
end
--================
--初始化角色画像面板
--================
function XUiFingerGuessingSelectStage:InitPanelRole()
    local PanelRole = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSRolePanel")
    table.insert(self.Panels, PanelRole.New(self.PanelRole, self))    
end
--================
--初始化天眼面板
--================
function XUiFingerGuessingSelectStage:InitPanelEye()
    local PanelEye = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessingEyePanel")
    table.insert(self.Panels, PanelEye.New(self.PanelEye, self))
end
--================
--初始化关卡面板
--================
function XUiFingerGuessingSelectStage:InitPanelLevel()
    local PanelLevel = require("XUi/XUiMiniGame/FingerGuessing/XUiFingerGuessSSLevelPanel")
    table.insert(self.Panels, PanelLevel.New(self.PanelLevel, self))
end
--================
--运行所有面板指定方法
--@param funcName:方法名
--================
function XUiFingerGuessingSelectStage:RunAllPanelsFunc(funcName)
    for _, panel in pairs(self.Panels) do
        local func = panel[funcName]
        if func then func(panel) end
    end
end
--================
--关卡选中时
--================
function XUiFingerGuessingSelectStage:OnStageSelected(component, stage)
    if self.StageComponent == component then return end
    if self.StageComponent then self.StageComponent:OnOtherStageSelect() end
    self.StageComponent = component
    self.StageSelected = stage
    self:RunAllPanelsFunc("OnStageSelected")
    self:PlayAnimation("QieHuan")
end
--================
--活动结束时处理
--================
function XUiFingerGuessingSelectStage:OnGameEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end