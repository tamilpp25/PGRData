---V2.9魔方嘉年华 新手关 关卡表现脚本
local XLevelScript1031 = XDlcScriptManager.RegLevelPresentScript(1031, "XLevelPresentScript1031")
local Timer = require("Level/Common/XTaskScheduler")


--脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript1031:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

end

--初始化
function XLevelScript1031:Init()
    self._proxy:SetFloatConfig("Gravity", -35)    --设置重力
    self._proxy:SetFloatConfig("JumpSpeed", 12)    --设置跳跃速度
    self._proxy:SetFloatConfig("IdleJumpSpeed", 1.8)    --设置站立时跳跃向前速度
    self._proxy:SetFloatConfig("MoveJumpSpeed", 3.3)    --设置移动时跳跃向前速度

    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()  --获取本端玩家npc
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false)  --锁定
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false)  --猎矛
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, false)
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, false)
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, false)
    
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)
    XLog.Debug("Level0100 Present trigger事件注册完成")
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._bossNpcId = self._proxy:GetLevelMemoryInt(2002)
    if self._bossNpcId > 0 then
        self._proxy:ShowDynamicHpBar(self._bossNpcId, true)
        self._proxy:SetNpcTopHpEnable(self._bossNpcId, false)
    else
        XLog.Error("Level0100 Present Init: Get BossNpcId failed:" .. tostring(self._bossNpcId))
    end

end

--事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript1031:HandleEvent(eventType, eventArgs)
    
    --[[XLog.Debug("Level0100 Present handle event:" .. tostring(eventType))
    if eventType == EWorldEvent.SceneObjectTrigger then
        XLog.Debug(string.format("Level0100 Present 有trigger被触发了:%d %d", eventArgs.TriggerId, eventArgs.SceneObjectId))
    end--]]

    if eventType == EWorldEvent.NpcAddBuff or eventType == EWorldEvent.NpcRemoveBuff then
        local show = eventType == EWorldEvent.NpcRemoveBuff
        if eventArgs.NpcUUID == self._bossNpcId and eventArgs.BuffTableId == 8101036 then --boss隐身了
            self._proxy:ShowDynamicHpBar(self._bossNpcId, show)
        end
    end

end

--每帧执行
---@param dt number @ delta time
function XLevelScript1031:Update(dt)
    self._timer:Update(dt)

    if self._proxy:CheckBuffByKind(self._localPlayerNpc, 200018) then  --退出爆炸球阶段
        self._proxy:RemoveBuff(self._localPlayerNpc, 200018)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, false)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, false)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, false)
    end
    if self._proxy:CheckBuffByKind(self._localPlayerNpc, 200019) then  --进入爆炸球阶段
        self._proxy:RemoveBuff(self._localPlayerNpc, 200019)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, true)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, true)
        self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, true)
    end
    if self._proxy:CheckBuffByKind(self._localPlayerNpc, 200023) then  --显示UI
        self._proxy:RemoveBuff(self._localPlayerNpc, 200023)
        local stage = self._proxy:CheckLevelMemoryInt(4000) and self._proxy:GetLevelMemoryInt(4000) or 1
        local round = self._proxy:CheckLevelMemoryInt(4001) and self._proxy:GetLevelMemoryInt(4001) or 1
        local delayTime = self._proxy:CheckLevelMemoryInt(4002) and self._proxy:GetLevelMemoryInt(4002) or 1
        self:ShowTip(stage, round, delayTime)
    end
    if self._proxy:CheckLevelMemoryInt(4003) then  --结束前关闭UI
        if self._proxy:GetLevelMemoryInt(4003) == 1  then
            self:CloseAllUi()
            self._proxy:SetLevelMemoryInt(4003, 0)
        end
    end
    if self._proxy:CheckLevelMemoryInt(4005) then  --关闭tips
        if self._proxy:GetLevelMemoryInt(4005) == 1  then
            self._proxy:CloseTip(102103)
            self._proxy:CloseTip(102106)
            self._proxy:CloseTip(102109)
            self._proxy:CloseTip(102112)
            self._proxy:CloseTip(102115)
            self._proxy:SetLevelMemoryInt(4005, 2) --关闭信号值
        end
    end
    if self._proxy:CheckLevelMemoryInt(4004) then  --引导UI开关
        --XLog.Debug("4004的值是"..self._proxy:GetLevelMemoryInt(4004))
        if self._proxy:GetLevelMemoryInt(4004) == 1  then
            self._proxy:SetUiWidgetActive(EUiIndex.Guide, EUiFightGuideWidgetKey.BtnNext, true)  --开启下一句按钮
            self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnJump, false)  --跳跃
            self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnDodge, false)  --闪避
            self._proxy:SetLevelMemoryInt(4004, 2) --关闭信号值
        elseif self._proxy:GetLevelMemoryInt(4004) == 0 then
            self._proxy:SetUiWidgetActive(EUiIndex.Guide, EUiFightGuideWidgetKey.BtnNext, false)  --关闭下一句按钮
            self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnJump, true)  --跳跃
            self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnDodge, true)  --闪避
            self._proxy:SetLevelMemoryInt(4004, 2) --关闭信号值            
        end
    end
end

--显示UI处理
---@param stage number @ 第一还是第二阶段
---@param round number @ 回合数
function XLevelScript1031:ShowTip(stage, round, delayTime)
    local time = delayTime
    if round == 1 then
        if stage == 1 then
            self._proxy:ShowTip(102101)
        elseif stage == 2 then
            self._proxy:ShowTip(102102)
            self._proxy:ShowTip(400100, time)
            self._timer:Schedule(time, self, self.ShowTip02, round)     
        end
    elseif round == 2 then
        if stage == 1 then
            self._proxy:ShowTip(102104)
        elseif stage == 2 then
            self._proxy:ShowTip(102105)
            self._proxy:ShowTip(400100, time)
            self._timer:Schedule(time, self, self.ShowTip02, round)     
        end
    elseif round == 3 then
        if stage == 1 then
            self._proxy:ShowTip(102107)
        elseif stage == 2 then
            self._proxy:ShowTip(102108)
            self._proxy:ShowTip(400100, time)
            self._timer:Schedule(time, self, self.ShowTip02, round)     
        end
    elseif round == 4 then
        if stage == 1 then
            self._proxy:ShowTip(102110)
        elseif stage == 2 then
            self._proxy:ShowTip(102111)
            self._proxy:ShowTip(400100, time)
            self._timer:Schedule(time, self, self.ShowTip02, round)     
        end
    elseif round == 5 then
        if stage == 1 then
            self._proxy:ShowTip(102113)
        elseif stage == 2 then
            self._proxy:ShowTip(102114)
            self._proxy:ShowTip(400100, time)
            self._timer:Schedule(time, self, self.ShowTip02, round)     
        end
    end
end

---@param round number @ 回合数
function XLevelScript1031:ShowTip02(round)
    self._proxy:CloseTip(400100) --关闭倒计时显示
    if round == 1 then
        self._proxy:ShowTip(102103)  --显示结算阶段UI
    elseif round == 2 then
        self._proxy:ShowTip(102106)
    elseif round == 3 then
        self._proxy:ShowTip(102109)
    elseif round == 4 then
        self._proxy:ShowTip(102112)
    elseif round == 5 then
        self._proxy:ShowTip(102115)
    end
end

function XLevelScript1031:CloseAllUi()
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.Joystick, false)  --左侧摇杆
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnJump, false)  --跳跃
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnDodge, false)  --闪避
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, false)
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, false)
    self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, false)
    if self._bossNpcId > 0 then
        self._proxy:ShowDynamicHpBar(self._bossNpcId, false)
    else
        XLog.Error("Level0100 Present Init: Get BossNpcId failed:" .. tostring(self._bossNpcId))
    end
end

--脚本终止
function XLevelScript1031:Terminate()
    XLog.Debug("Level0100 Present Terminate")
end

return XLevelScript1031