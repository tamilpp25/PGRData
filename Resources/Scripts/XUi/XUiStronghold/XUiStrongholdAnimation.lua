local XUiGridStrongholdBuff = require("XUi/XUiStronghold/XUiGridStrongholdBuff")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local INTERVAL = XScheduleManager.SECOND

local XUiStrongholdAnimation = XLuaUiManager.Register(XLuaUi, "UiStrongholdAnimation")

function XUiStrongholdAnimation:OnAwake()
    self.GridBuffBase.gameObject:SetActiveEx(false)
    self.GridBuffBoss.gameObject:SetActiveEx(false)
end

function XUiStrongholdAnimation:OnStart(groupId, closeCb)
    self.CloseCb = closeCb
    self.BossBuffGrids = {}
    self.BaseBuffGrids = {}

    self.TxtNameTitle.text = XStrongholdConfigs.GetGroupName(groupId)
    local isClickBtnUseDialog = true

    --据点BossBuff
    local bossBuffIds = XDataCenter.StrongholdManager.GetGroupBossBuffIds(groupId)
    local showBossBuff = #bossBuffIds > 0
    self.PanelBossBuffs.gameObject:SetActiveEx(showBossBuff)

    local isBossBuff = true
    for index, buffId in ipairs(bossBuffIds) do
        local grid = self.BossBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuffBoss or CSUnityEngineObjectInstantiate(self.GridBuffBoss, self.PanelBossBuffs)
            grid = XUiGridStrongholdBuff.New(go, nil, nil, handler(self, self.StopTimes), handler(self, self.StartTimes), isClickBtnUseDialog)
            self.BossBuffGrids[index] = grid
        end

        grid:Refresh(buffId, isBossBuff)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #bossBuffIds + 1, #self.BossBuffGrids do
        local grid = self.BossBuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    --据点BaseBuff
    local baseBuffIds = XDataCenter.StrongholdManager.GetGroupBaseBuffIds(groupId)
    local showBaseBuff = #baseBuffIds > 0
    self.PanelBaseBuffs.gameObject:SetActiveEx(showBaseBuff)

    local isBossBuff = false
    for index, buffId in ipairs(baseBuffIds) do
        local grid = self.BaseBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuffBase or CSUnityEngineObjectInstantiate(self.GridBuffBase, self.PanelBaseBuffs)
            grid = XUiGridStrongholdBuff.New(go, nil, nil, handler(self, self.StopTimes), handler(self, self.StartTimes), isClickBtnUseDialog)
            self.BaseBuffGrids[index] = grid
        end

        grid:Refresh(buffId, isBossBuff)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #baseBuffIds + 1, #self.BaseBuffGrids do
        local grid = self.BaseBuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    self.TimeSecond = XStrongholdConfigs.GetCommonConfig("UiStrongholdAnimationCloseTime")
    self:StartTimes()
end

function XUiStrongholdAnimation:OnDisable()
    self:StopTimes()
end

function XUiStrongholdAnimation:StartTimes()
    self:StopTimes()
    self.TxtTime.text = CSXTextManagerGetText("StrongholdAnimationClose", self.TimeSecond)
    self.Times = XScheduleManager.ScheduleForever(function()
        self.TimeSecond = self.TimeSecond - 1
        if self.TimeSecond == 0 then
            self.CloseCb()
            return
        end

        if self.TimeSecond < 0 then
            self:Close()
            return
        end

        self.TxtTime.text = CSXTextManagerGetText("StrongholdAnimationClose", self.TimeSecond)
    end, INTERVAL)
end

function XUiStrongholdAnimation:StopTimes()
    if self.Times then
        XScheduleManager.UnSchedule(self.Times)
        self.Times = nil
    end
end