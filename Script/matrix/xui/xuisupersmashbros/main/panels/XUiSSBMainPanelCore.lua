--=================
--主界面核心面板
--=================
local XUiSSBMainPanelCore = {}
--=================
--面板
--=================
local Panel = {}
--=================
--点击超数核心按钮事件
--=================
local OnClickBtnCore = function()
    XLuaUiManager.Open("UiSuperSmashBrosCore")
end
--=================
--点击排行榜按钮事件
--=================
local OnClickBtnRanking = function()
    local rankingMode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)

    if not rankingMode:CheckUnlock() then 
        local tipText = CSXTextManagerGetText("SuperSmashModeLock", rankingMode:GetName())
        XUiManager.TipMsg(tipText)   
        return
    end
    Panel.BtnRanking:ShowReddot(false)
    XSaveTool.SaveData(XPlayer.Id .. "SurviveRankingBtn" .. rankingMode:GetId() .. rankingMode:GetActivityId(), true)
    XLuaUiManager.Open("UiSuperSmashBrosRanking")
end
--=================
--=================
--点击队伍等级按钮事件
--=================
local OnClickTeamLevel = function()
    XLuaUiManager.Open("UiSuperSmashBrosTips")
end
--=================
--初始化超数核心按钮事件
--=================
local InitBtnCore = function()
    if Panel.BtnCore then
        Panel.BtnCore.CallBack = OnClickBtnCore
    end
end
--=================
--初始化排行榜按钮事件
--=================
local InitBtnRanking = function()
    if Panel.BtnRanking then
        -- 连战未开放就不显示排行榜按钮
        local rankingMode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive) 
        Panel.BtnRanking.gameObject:SetActive(rankingMode:CheckUnlock())
    
        -- 检查解锁记录 首次开放后 排行榜按钮显示一此红点 点击后不再显示
        local unlockFlag = XSaveTool.GetData(XPlayer.Id .. "SurviveRankingBtn" .. rankingMode:GetId() .. rankingMode:GetActivityId())
        Panel.BtnRanking:ShowReddot(not unlockFlag)

        Panel.BtnRanking.CallBack = OnClickBtnRanking
    end
end
--=================
--初始化队伍等级按钮
--=================
local InitBtnTeamLv= function()
    if Panel.BtnTeamLv then
        Panel.BtnTeamLv.CallBack = OnClickTeamLevel
    end
end
--=================
--刷新剩余首战怪物文本
--=================
local RefreshLeftMonsters = function()
    if Panel.TxtLeftMonsters then
        local leftNum = XDataCenter.SuperSmashBrosManager.GetAllLeftMonsters()
        Panel.TxtLeftMonsters.text = XUiHelper.GetText("SSBMainLeftMonsters", leftNum)
    end
end
--=================
--刷新入口红点
--=================
local RefreshRedPoint = function()
    if Panel.BtnCore then
        Panel.BtnCore:ShowReddot(XDataCenter.SuperSmashBrosManager.CheckNewCoreFlag())
    end
end
--=================
--刷新剩余能量文本
--=================
local RefreshLeftEnergy = function()
    if Panel.TxtLeftEnergy then
        Panel.TxtLeftEnergy.text = XUiHelper.GetText("SSBMainLeftEnergy", XDataCenter.SuperSmashBrosManager.GetLeftEnergy()) 
    end
end
--=================
--刷新队伍等级数据
--=================
local RefreshTeamLv = function()
    local isMaxLevel = XDataCenter.SuperSmashBrosManager.GetIsTeamLvMax()
    local teamLv = XDataCenter.SuperSmashBrosManager.GetTeamLevel()
    local teamItemNum = XDataCenter.SuperSmashBrosManager.GetTeamItem()
    local teamLevelConfig = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.TeamLevel)

    local nextLv = isMaxLevel and #teamLevelConfig or teamLv + 1 --防止读取下一个等级的数据越界

    if Panel.TxtTeamLv then
        Panel.TxtTeamLv.text = XUiHelper.GetText("SuperSmashTeamLevel", teamLv) 
    end
    if Panel.TeamLvImgProgress then -- cxldV2 队伍等级
        Panel.TeamLvImgProgress.fillAmount = isMaxLevel and 1 or teamItemNum / teamLevelConfig[nextLv].NeedItem
    end
end
--监听添加标记
local EventListenerFlag
--=================
--添加事件监听
--=================
local AddEventListeners = function()
    if EventListenerFlag then return end
    XEventManager.AddEventListener(XEventId.EVENT_SSB_STAGE_REFRESH, XUiSSBMainPanelCore.Refresh)
    EventListenerFlag = true
end
--=================
--移除事件监听
--=================
local RemoveEventListeners = function()
    if not EventListenerFlag then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_SSB_STAGE_REFRESH, XUiSSBMainPanelCore.Refresh)
    EventListenerFlag = false
end
--=================
--初始化
--=================
function XUiSSBMainPanelCore.Init(ui)
    Panel = XTool.InitUiObjectByUi(Panel, ui.PanelCore)
    InitBtnCore() --按钮只需要初始化时注册事件一次
    InitBtnRanking()
    InitBtnTeamLv()
end
--=================
--当主界面显示时
--=================
function XUiSSBMainPanelCore.OnEnable()
    AddEventListeners()
    XUiSSBMainPanelCore.Refresh()
end
--=================
--当主界面隐藏时
--=================
function XUiSSBMainPanelCore.OnDisable()
    RemoveEventListeners()
end
--=================
--当主界面销毁时
--=================
function XUiSSBMainPanelCore.OnDestroy()
    Panel = {}
    EventListenerFlag = nil
end
--=================
--刷新面板
--=================
function XUiSSBMainPanelCore.Refresh()
    RefreshLeftMonsters()
    RefreshLeftEnergy()
    RefreshRedPoint()
    RefreshTeamLv()
end

return XUiSSBMainPanelCore