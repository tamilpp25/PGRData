local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--=================
--主界面奖励面板
--=================
local XUiSSBMainPanelReward = {}
--=================
--面板
--=================
local Panel = {}
--=================
--图标控件
--=================
local Icon
--=================
--初始化奖励详情界面按钮
--=================
local InitBtnRewardDetails = function()
    if Panel.BtnRewardDetails then
        Panel.BtnRewardDetails.CallBack = function()
            -- XLuaUiManager.Open("UiSuperSmashBrosReward", function() XUiSSBMainPanelReward.RefreshReward() end)
            XLuaUiManager.Open("UiSuperSmashBrosTask")
        end
    end
end
--=================
--显示积分获取情况
--=================
local ShowPointGet = function()
    local manager = XDataCenter.SuperSmashBrosManager
    local isComplete = manager.CheckIsAllComplete()
    if Panel.ScoreProgress then
        Panel.ScoreProgress.gameObject:SetActiveEx(not isComplete)
    end
    if Panel.TxtComplete then
        Panel.TxtComplete.gameObject:SetActiveEx(isComplete)
    end
    if not isComplete and Panel.TxtScoreProgress then
        local mode = manager.GetFirstModeHaveRewardGet()
        if mode then
            Panel.TxtScoreProgress.text = XUiHelper.GetText(
                "SSBMainRewardLevel",
                manager.GetTaskProgress()
                )
        end
    end
end
--=================
--初始化图标控件
--=================
local InitIcon = function(rootUi)
    if Panel.RewardIcon then
        local icon = require("XUi/XUiSuperSmashBros/Main/Grids/XUiSSBMainRewardIcon")
        Icon = icon.New(Panel.RewardIcon,function()
                XLuaUiManager.Open("UiSuperSmashBrosReward", function() XUiSSBMainPanelReward.RefreshReward() end)
            end)
    end
end
--=================
--显示奖励图标
--=================
local ShowRewardIcon = function()
    local mode = XDataCenter.SuperSmashBrosManager.GetFirstModeHaveRewardGet()
    Icon:Refresh(mode)
end
--=================
--初始化
--=================
function XUiSSBMainPanelReward.Init(ui)
    Panel.Parent = ui
    Panel = XTool.InitUiObjectByUi(Panel, ui.PanelReward)
    InitBtnRewardDetails()
    InitIcon(ui)
end
--=================
--显示时
--=================
function XUiSSBMainPanelReward.OnEnable()
    XUiSSBMainPanelReward.RefreshReward()
    XUiSSBMainPanelReward.AddEventListeners()
    XUiSSBMainPanelReward.UpdateDailyReward()
end
--=================
--隐藏时
--=================
function XUiSSBMainPanelReward.OnDisable()
    XUiSSBMainPanelReward.RemoveEventListeners()
end
--=================
--销毁时
--=================
function XUiSSBMainPanelReward.OnDestroy()
    Panel = {}
    Icon = nil
end
--=================
--注册监听
--=================
local EventListenrAdded
function XUiSSBMainPanelReward.AddEventListeners()
    if EventListenrAdded then return end
    XEventManager.AddEventListener(XEventId.EVENT_SSB_STAGE_REFRESH, XUiSSBMainPanelReward.RefreshReward)
    EventListenrAdded = true
end
--=================
--移除监听
--=================
function XUiSSBMainPanelReward.RemoveEventListeners()
    if not EventListenrAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_SSB_STAGE_REFRESH, XUiSSBMainPanelReward.RefreshReward)
    EventListenrAdded = nil
end
--=================
--刷新奖励
--=================
function XUiSSBMainPanelReward.RefreshReward()
    ShowRewardIcon()
    ShowPointGet()
end

--==============
--新增每日任务奖励，任务可领取时点击图标后领取奖励；每日奖励类型中的任务不计入总任务数与完成任务数
--==============
function XUiSSBMainPanelReward.UpdateDailyReward()
    if not Panel.UiDailyRewardItem then
        Panel.UiDailyRewardItem = XUiGridCommon.New(Panel.Parent, Panel.GridDailyReward)
        Panel.RewardPanelEffect = XUiHelper.TryGetComponent(Panel.GridDailyReward, "PanelEffect", "Transform")
    end
    
    local rewardItemId = XSuperSmashBrosConfig.GetDailyRewardItemId()
    if not rewardItemId or rewardItemId == 0 then
        Panel.UiDailyRewardItem.GameObject:SetActiveEx(false)
        return
    end
    Panel.UiDailyRewardItem:Refresh(rewardItemId)

    local isReceiveDailyReward = XDataCenter.SuperSmashBrosManager.IsReceiveDailyReward()
    if not isReceiveDailyReward then
        Panel.UiDailyRewardItem:SetClickCallback(function()
            XDataCenter.SuperSmashBrosManager.ReceiveDailyReward(function()
                Panel.Parent:UpdateRewardAndTeamLevel()
            end)
        end)
        Panel.UiDailyRewardItem:SetReceived(false)
        Panel.RewardPanelEffect.gameObject:SetActiveEx(true)
    else
        Panel.RewardPanelEffect.gameObject:SetActiveEx(false)
        Panel.UiDailyRewardItem:SetReceived(true)
        Panel.UiDailyRewardItem:SetClickCallback(function()
            --do nothing
        end)
    end
end
return XUiSSBMainPanelReward