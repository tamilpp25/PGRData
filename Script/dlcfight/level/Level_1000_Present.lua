---V2.13 躲猫猫 测试脚本 Present
local XLevelScript1000 = XDlcScriptManager.RegLevelPresentScript(1000, "XLevelPresentScript1000")
local Timer = require("Level/Common/XTaskScheduler")


--脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript1000:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
end

--初始化
function XLevelScript1000:Init()
    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()  --获取本端玩家npc
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)  --锁定
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)  --猎矛
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, false)
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, false)
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, false)
end

--事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript1000:HandleEvent(eventType, eventArgs)
end

--每帧执行
---@param dt number @ delta time
function XLevelScript1000:Update(dt)
    self._timer:Update(dt)
end

--脚本终止
function XLevelScript1000:Terminate()
    XLog.Debug("Level0100 Present Terminate")
end

return XLevelScript1000