---@class XUiPanelPcgGameMonster : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
local XUiPanelPcgGameMonster = XClass(XUiNode, "XUiPanelPcgGameMonster")

function XUiPanelPcgGameMonster:OnStart()
    self.GridMonster.gameObject:SetActiveEx(false)
    ---@type table<number, XUiGridPcgMonster>
    self.GridMonsterDic = {}
    self.IsEnterUi = true -- 刚进入界面
    self:RegisterUiEvents()
end

function XUiPanelPcgGameMonster:OnEnable()
    
end

function XUiPanelPcgGameMonster:OnDisable()
    
end

function XUiPanelPcgGameMonster:OnDestroy()
    self:ClearInitTimer()
end

function XUiPanelPcgGameMonster:RegisterUiEvents()

end

function XUiPanelPcgGameMonster:Refresh()
    self:RefreshMonsters()
    self:RefreshMonsterSelected()

    -- 初始化动画
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init then
        self:PlayInitAnim()
    end
end

function XUiPanelPcgGameMonster:GetMonster(idx)
    return self.GridMonsterDic[idx]
end

function XUiPanelPcgGameMonster:GetMonsterPosition(idx)
    local grid = self.GridMonsterDic[idx]
    return grid.Transform.position
end

function XUiPanelPcgGameMonster:RefreshMonsters()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgMonster[]
    local monsterDatas = stageData:GetMonsters()
    for _, monsterData in pairs(monsterDatas) do
        self:RefreshMonster(monsterData)
    end

    -- 隐藏没有怪物的格子
    for idx, grid in pairs(self.GridMonsterDic) do
        if not stageData:GetMonster(idx) then
            grid:Reset()
            grid:Close()
        end
    end
end

-- 刷新单个怪物
---@param monsterData XPcgMonster
function XUiPanelPcgGameMonster:RefreshMonster(monsterData, isNew)
    local hp =  monsterData:GetHp()
    -- 已死亡的怪物不创建/刷新
    if hp <= 0 then return end
    
    local id = monsterData:GetId()
    local idx = monsterData:GetIdx()
    local armor = monsterData:GetArmor()
    local tokens = monsterData:GetTokens()
    local behaviorPreviews = monsterData:GetBehaviorPreviews()
    
    ---@type XUiGridPcgMonster
    local grid = self.GridMonsterDic[idx]
    if not grid then
        local go = CS.UnityEngine.Object.Instantiate(self.GridMonster.gameObject, self["Monster"..idx])
        go.gameObject:SetActiveEx(true)
        self.XUiGridPcgMonster = self.XUiGridPcgMonster or require("XUi/XUiPcg/XUiGrid/XUiGridPcgMonster")
        grid = self.XUiGridPcgMonster.New(go, self)
        self.GridMonsterDic[idx] = grid
        grid:SetInputCallBack(function(idx)
            self:OnPointerUp(idx)
        end, function(idx, time)
            self:OnPress(idx, time)
        end)
    end

    grid:Open()
    grid:SetMonsterData(id, idx, hp, armor)
    grid:SetTokens(tokens)
    grid:SetBehaviorPreviews(behaviorPreviews)
    if isNew then
        grid:PlayEnableAnim()
    end
end

-- 刷新怪物选中
function XUiPanelPcgGameMonster:RefreshMonsterSelected()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local commander = stageData:GetCommander()
    local targetMonsterIdx = commander:GetTargetMonsterIdx()
    for idx, grid in pairs(self.GridMonsterDic) do
        local isTarget = idx == targetMonsterIdx
        grid:SetTarget(isTarget)
    end
end

-- 召唤怪物
function XUiPanelPcgGameMonster:ChangeMonsters(monster1, monster2, monster3, monster4, monster5)
    local monsterIds = {monster1, monster2, monster3, monster4, monster5}
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()

    for i, monsterId in ipairs(monsterIds) do
        if XTool.IsNumberValid(monsterId) then
            local monsterData = stageData:GetMonster(i)
            if not monsterData then
                XLog.Warning(string.format( "请服务端老师检查，EffectSettleType = 8，召唤位置%s的怪物Id%s未下发怪物数据", i, monsterId))
            else
                self:RefreshMonster(monsterData, true)
            end
        end
    end
end

-- 播放初始化动画
function XUiPanelPcgGameMonster:PlayInitAnim()
    for _, grid in pairs(self.GridMonsterDic) do
        grid:Close()
    end
    self:ClearInitTimer()

    -- 刚进入界面
    if self.IsEnterUi then
        self.IsEnterUi = false
        local playableDirector = self.Parent.Transform:Find("Animation/AnimStart"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        local animStartTime = math.floor(playableDirector.duration * 1000)
        -- 播完开始动画之后进场
        self.InitTimer1 = XScheduleManager.ScheduleOnce(function()
            self:PlayMonsterEnable(1)
        end, animStartTime)
        -- 间隔出场
        self.InitTimer2 = XScheduleManager.ScheduleOnce(function()
            self:PlayMonsterEnable(2)
            self:PlayMonsterEnable(3)
        end, animStartTime + XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET)

        -- 间隔出场
        self.InitTimer3 = XScheduleManager.ScheduleOnce(function()
            self:PlayMonsterEnable(4)
            self:PlayMonsterEnable(5)
        end, animStartTime + XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET * 2)
        
    -- 重新开始游戏
    else
        self:PlayMonsterEnable(1)
        -- 间隔出场
        self.InitTimer2 = XScheduleManager.ScheduleOnce(function()
            self:PlayMonsterEnable(2)
            self:PlayMonsterEnable(3)
        end, XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET)

        -- 间隔出场
        self.InitTimer3 = XScheduleManager.ScheduleOnce(function()
            self:PlayMonsterEnable(4)
            self:PlayMonsterEnable(5)
        end, XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET * 2)
    end
end

-- 检测怪物播放进场动画
function XUiPanelPcgGameMonster:PlayMonsterEnable(idx)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local monsterData = stageData:GetMonster(idx)
    if monsterData and monsterData:GetHp() > 0 then
        self.GridMonsterDic[idx]:Open()
        self.GridMonsterDic[idx]:PlayEnableAnim()
    end
end

function XUiPanelPcgGameMonster:ClearInitTimer()
    if self.InitTimer1 then
        XScheduleManager.UnSchedule(self.InitTimer1)
        self.InitTimer1 = nil
    end
    if self.InitTimer2 then
        XScheduleManager.UnSchedule(self.InitTimer2)
        self.InitTimer2 = nil
    end
    if self.InitTimer3 then
        XScheduleManager.UnSchedule(self.InitTimer3)
        self.InitTimer3 = nil
    end
end

-- 是否有怪物存在
function XUiPanelPcgGameMonster:IsMonsterExit()
    for _, monster in pairs(self.GridMonsterDic) do
        if not monster:GetIsDead() then
            return true
        end
    end    
    return false
end

-- 清理所有怪物
function XUiPanelPcgGameMonster:ClearAllMonster()
    for _, monster in pairs(self.GridMonsterDic) do
        if not monster:GetIsDead() then
            monster:Reset()
            monster:PlayDisableAnim()
        end
    end
end

--region 手势操作
function XUiPanelPcgGameMonster:OnPointerUp(idx)
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState(true) then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 当前打开弹窗详情，关闭弹窗详情
    if self.Parent:IsShowPanelPopupDetail() then
        self.Parent:ClosePanelPopupDetail()
        return
    end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end

    -- 增加点击CD，防止鼠标左右键同时按下
    local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
    if self.LastPointerUpTime and (nowTime - self.LastPointerUpTime) < 0.2 then
        return
    end
    self.LastPointerUpTime = nowTime
    
    self:OnMonsterClick(idx)
end

function XUiPanelPcgGameMonster:OnPress(idx, time)
    -- 长按超过0.2秒才响应操作
    if time < 0.2 then return end
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState() then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 当前打开弹窗详情，不可操作
    if self.Parent:IsShowPanelPopupDetail() then return end
    -- 已死亡不可操作
    if self.GridMonsterDic[idx]:GetIsDead() then return end

    -- 打开详情
    self.Parent:ShowPanelPopupDetail(XEnumConst.PCG.POPUP_DETAIL_TYPE.MONSTER, idx)
end

-- 点击怪物头像
function XUiPanelPcgGameMonster:OnMonsterClick(idx)
    local monster = self.GridMonsterDic[idx]
    if monster:GetHp() <= 0 then return end

    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local commander = stageData:GetCommander()
    local targetMonsterIdx = commander:GetTargetMonsterIdx()
    if idx == targetMonsterIdx then return end

    XMVCA.XPcg:PcgCommanderTargetRequest(idx, function()
        self:RefreshMonsterSelected()
    end)
end
--endregion

return XUiPanelPcgGameMonster
