---V2.13 小岛&宿舍躲猫猫
local XLevelScript1041 = XDlcScriptManager.RegLevelPresentScript(1041, "XLevelPresentScript1041")
local Timer = require("Level/Common/XTaskScheduler")

-- 脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript1041:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
end

-- 初始化
function XLevelScript1041:Init()
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID(1041小岛，1051宿舍)
    if self._levelId == 1041 then
        for i = 2, 62 do
            self._proxy:SetSceneObjectShadowEnable(i, false) --1041中ID为2~62的场景物件关闭阴影
        end
    elseif self._levelId == 1051 then
        for i = 100004, 100075 do
            self._proxy:SetSceneObjectShadowEnable(i, false) --1051中ID为100004~100075的场景物件关闭阴影
        end
    elseif self._levelId == 1061 then                          --***************************&&&&&&&&&&&&&&&&&&&&&&&&1061中需要隐藏得场景物体阴影 ID待定
        for i = 1, 84 do
            self._proxy:SetSceneObjectShadowEnable(i, false) --1051中ID为100004~100075的场景物件关闭阴影
        end
    end
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._localPlayerNpc = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npc
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, false) -- 锁定
    self._proxy:SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, false) -- 猎矛
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillBlue, false)
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillGreen, false)
    -- self._proxy:SetUiWidgetActive(EUiIndex.CasualGames, EUiFightDlcCasualWidgetKey.BtnSkillYellow, false)
    if self._proxy:CheckBuffByKind(self._localPlayerNpc, 200023) then
        local phase = self._proxy:CheckLevelMemoryInt(4000) and self._proxy:GetLevelMemoryInt(4000) or 0
        local time = self._proxy:CheckLevelMemoryInt(4001) and self._proxy:GetLevelMemoryInt(4001) or 0
        local timeAddBuff = self._proxy:CheckLevelMemoryFloat(4003) and self._proxy:GetLevelMemoryFloat(4003) or 0
        time = math.floor(time - (self._proxy:GetFightTime() - timeAddBuff))
        if time > 0 then
            self:ShowTip(phase, time) --调用显示
        end
    end
end

-- 事件
---@param eventType number
---@param eventArgs userdata
function XLevelScript1041:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcAddBuff then
        if eventArgs.BuffTableId == 200023 and eventArgs.NpcUUID == self._localPlayerNpc then --UI显示的指令buff
            local phase = self._proxy:CheckLevelMemoryInt(4000) and self._proxy:GetLevelMemoryInt(4000) or 0
            local time = self._proxy:CheckLevelMemoryInt(4001) and self._proxy:GetLevelMemoryInt(4001) or 0
            self:ShowTip(phase, time)                  --调用显示
        elseif eventArgs.BuffTableId == 200042 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowMouseHunterCampTip(104109) --猫的阵营提示
        elseif eventArgs.BuffTableId == 200043 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowMouseHunterCampTip(104110) --鼠的阵营提示
        elseif eventArgs.BuffTableId == 200035 and eventArgs.NpcUUID == self._localPlayerNpc then
            local uiTypeCat = self._proxy:CheckLevelMemoryInt(4004) and self._proxy:GetLevelMemoryInt(4004) or 0
            if uiTypeCat == 1 then
                self._proxy:ShowMouseHunterCampTip(104105) --猫的开战UI
            elseif uiTypeCat == 2 then
                self._proxy:ShowMouseHunterCampTip(104107) --猫的抓获UI
            end
        elseif eventArgs.BuffTableId == 200036 and eventArgs.NpcUUID == self._localPlayerNpc then
            local uiTypeMouse = self._proxy:CheckLevelMemoryInt(4002) and self._proxy:GetLevelMemoryInt(4002) or 0
            if uiTypeMouse == 1 then
                self._proxy:ShowMouseHunterCampTip(104106) --鼠的开战UI
            elseif uiTypeMouse == 2 then
                self._proxy:ShowTip(104104)                --鼠的被捕UI
            end
        elseif eventArgs.BuffTableId == 200037 and eventArgs.NpcUUID == self._localPlayerNpc then
            local phase = self._proxy:CheckLevelMemoryInt(4000) and self._proxy:GetLevelMemoryInt(4000) or 0
            self:CloseTip(phase)
        elseif eventArgs.BuffTableId == 200046 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104108) --"游戏结束UI"
        elseif eventArgs.BuffTableId == 1900111 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104111) --鼠被标记提示
        elseif eventArgs.BuffTableId == 1900067 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104112) --猫固定扫描提示
        elseif eventArgs.BuffTableId == 1900101 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104113) --获得能量饮料提示
        elseif eventArgs.BuffTableId == 1900102 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104114) --获得捕鼠夹提示
        elseif eventArgs.BuffTableId == 1900103 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104115) --获得冲刺提示
        elseif eventArgs.BuffTableId == 1900104 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104116) --获得导弹提示
        elseif eventArgs.BuffTableId == 1900105 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104117) --获得隐身提示
        elseif eventArgs.BuffTableId == 1900106 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104118) --获得固定扫描提示
        elseif eventArgs.BuffTableId == 1900107 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104119) --获得钩锁提示
        elseif eventArgs.BuffTableId == 1900108 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104120) --获得渔网提示
        elseif eventArgs.BuffTableId == 1900116 and eventArgs.NpcUUID == self._localPlayerNpc then
            self._proxy:ShowTip(104121) --标记目标隐身提示
        elseif eventArgs.BuffTableId == 1900121 and eventArgs.NpcUUID == self._localPlayerNpc then
            if not self._proxy:CheckBuffByKind(self._localPlayerNpc, 200046) then            --如果已经被被标记了游戏结束UI就不提示，以免顶掉UI显示
                self._proxy:ShowTip(104122) --标记目标被捕提示 
            end
        end
    end
end

-- 每帧执行
---@param dt number @ delta time
function XLevelScript1041:Update(dt)
    self._timer:Update(dt)
end

--UI显示
function XLevelScript1041:ShowTip(phase, time)
    if phase == 1 then
        self._proxy:ShowTip(104101) --准备阶段
        self._proxy:ShowTip(400100, time)
    elseif phase == 2 then
        --self._proxy:CloseTip(104101)
        --self._proxy:CloseTip(400100)
        self._proxy:ShowTip(104102) --对战阶段
        self._proxy:ShowTip(400100, time)
    elseif phase == 3 then
        --self._proxy:CloseTip(104102)
        --self._proxy:CloseTip(400100)
        self._proxy:ShowTip(104103)                               --最终阶段
        self._proxy:ShowTip(400100, time)
        self._proxy:PlayMusicInOut(5013, -1, -1, -1, -1, 0, 0.65) --切换bgm
    end
end

--UI隐藏
function XLevelScript1041:CloseTip(phase)
    if phase == 1 then
        self._proxy:CloseTip(104101) --准备阶段
        self._proxy:CloseTip(400100)
    elseif phase == 2 then
        self._proxy:CloseTip(104102) --对战阶段
        self._proxy:CloseTip(400100)
    elseif phase == 3 then
        self._proxy:CloseTip(104103) --最终阶段
        self._proxy:CloseTip(400100)
    end
end

-- 脚本终止
function XLevelScript1041:Terminate()

end

return XLevelScript1041
