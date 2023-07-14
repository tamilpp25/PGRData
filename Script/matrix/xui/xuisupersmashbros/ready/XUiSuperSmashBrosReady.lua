--==============
--超限乱斗战斗准备页面
--==============
local XUiSuperSmashBrosReady = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosReady")

function XUiSuperSmashBrosReady:OnStart()
    self.Mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    self.FirstIn = true
    self:InitPanels() --初始化各子面板
    self:InitBaseBtns() --注册基础按钮
    self:SetActivityTimeLimit() --设置活动关闭时处理
end
--==============
--注册基础按钮
--==============
function XUiSuperSmashBrosReady:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
    self.BtnMonster.CallBack = handler(self, self.OnClickBtnMonster)
    self.BtnTrain.CallBack = handler(self, self.OnClickBtnTrain)
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosReady:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosReady:OnClickBtnBack()
    local tipTitle = CS.XTextManager.GetText("SSBExitConfirmTitle")
    local content = CS.XTextManager.GetText("SSBExitConfirmContent")
    local isLine = self.Mode:GetIsLinearStage()
    local giveUpCb = function()
        XDataCenter.SuperSmashBrosManager.BattleConfirm(function()
            if isLine then
                XLuaUiManager.Open("UiSuperSmashBrosSettle", self.Mode)
            else
                XDataCenter.SuperSmashBrosManager.ResetMode()
                XLuaUiManager.Open("UiSuperSmashBrosSelectStage", self.Mode)
                XLuaUiManager.Remove("UiSuperSmashBrosReady")
            end
            -- 重置彩蛋机器人数据
            XDataCenter.SuperSmashBrosManager.ResetEggRobotOpen()
        end, true)
    end
    local confirmCb = function()
        self:Close()
    end
    XLuaUiManager.Open("UiSuperSmashBrosDialog", tipTitle, content, giveUpCb, confirmCb)
end
--==============
--怪物按钮
--==============
function XUiSuperSmashBrosReady:OnClickBtnMonster()
    XLuaUiManager.Open("UiSuperSmashBrosMonster", XDataCenter.SuperSmashBrosManager.GetMonsterGroupListByIdList(self.Mode:GetEnemyTeam()))
end
--==============
--角色列表按钮
--==============
function XUiSuperSmashBrosReady:OnClickBtnTrain()
    XLuaUiManager.Open("UiSuperSmashBrosCharacter", self.Mode:GetBattleTeam(), false)
end
--==============
--初始化各子面板
--==============
function XUiSuperSmashBrosReady:InitPanels()
    self:LoadModePrefab()
    self:InitPanelOwn()
    self:InitPanelEnemy()
    self:InitPanelPrefab()
    self:InitPanelEnergy()
    self.TxtMode.text = self.Mode:GetName()
end
--==============
--读取模式预制件
--==============
function XUiSuperSmashBrosReady:LoadModePrefab()
    local prefabPath = self.Mode:GetReadyUiPrefab()
    if prefabPath then
        self.CustomPanel = self.PanelPrefab:LoadPrefab(prefabPath)
    end
end
--==============
--初始化我方队伍面板
--==============
function XUiSuperSmashBrosReady:InitPanelOwn()
    local script = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanelOwn")
    self.Own = script.New(self.PanelOwn, self.Mode)
end
--==============
--初始化敌方队伍面板
--==============
function XUiSuperSmashBrosReady:InitPanelEnemy()
    local script = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanelEnemy")
    self.Enemy = script.New(self.PanelEnemy, self.Mode)
end

function XUiSuperSmashBrosReady:InitPanelEnergy()
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelEnergy")
    self.Energy = script.New(self.PanelEnergy)
end
--==============
--初始化自定义面板
--==============
function XUiSuperSmashBrosReady:InitPanelPrefab()
    local is1v1 = self.Mode:GetRoleBattleNum() == 1
    local script
    if is1v1 then
        script = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanel1v1")
    else
        script = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanelNormal")
    end
    self.Custom = script.New(self.CustomPanel, self.Mode, self)
end
--==============
--界面显示时
--==============
function XUiSuperSmashBrosReady:OnEnable()
    XUiSuperSmashBrosReady.Super.OnEnable(self)
    if self.FirstIn then
        self:PlayAnimation("FirstAnimEnable")
    elseif self.IsBattleQuit then
        self:PlayAnimation("BattleDisable")
    end
    self:Refresh(self.FirstIn or self.IsBattleQuit)
    self.IsBattleQuit = false
    self.FirstIn = false
end

function XUiSuperSmashBrosReady:Refresh(playAnim)
    self.Enemy:Refresh(playAnim)
    self.Own:Refresh(playAnim)
    if self.Energy then self.Energy:Refresh(playAnim) end
    if self.Custom and self.Custom.Refresh then self.Custom:Refresh(playAnim) end
end

function XUiSuperSmashBrosReady:ConfirmNextEnemy()
    self.Enemy:PlaySwitchAnima(function()
        self.Enemy:Refresh(true)
        self.Own:Refresh(false)
        if self.Custom and self.Custom.Refresh then self.Custom:Refresh() end
    end)
end

function XUiSuperSmashBrosReady:OnEnterFight()
    XLuaUiManager.SetMask(true)
    self.Enemy:OnEnterFight()
    self.Own:OnEnterFight()
    self:PlayAnimation("UiDisable")
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.Mode:GetNextStageId())
        local isAssist = false
        local challengeCount = 1
        XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
    end, 1000)

end
--==============
--界面隐藏时
--==============
function XUiSuperSmashBrosReady:OnDisable()
    XUiSuperSmashBrosReady.Super.OnDisable(self)
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosReady:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
        end
    end)
end

function XUiSuperSmashBrosReady:OnReleaseInst()
    return { FirstIn = false, IsBattleQuit = true }
end

function XUiSuperSmashBrosReady:OnResume(data)
    self.FirstIn = data.FirstIn
    self.IsBattleQuit = data.IsBattleQuit
end