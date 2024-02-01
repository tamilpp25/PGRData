---@class XUiSCBattlePanelBossSkill
local XUiPanelBossSkill= XClass(nil, "XUiPanelBossSkill")
local XUiGridBuff = require("XUi/XUiSameColorGame/Battle/XUiGridBuff")

function XUiPanelBossSkill:Ctor(ui, base, boss)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    ---@type XSCBoss
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:Init()
end

function XUiPanelBossSkill:OnEnable()
    self:AddEventListener()
end

function XUiPanelBossSkill:OnDisable()
    self:RemoveEventListener()
end

function XUiPanelBossSkill:Init()
    self.GridBossSkill = nil
    self.GridSkill.gameObject:SetActiveEx(false)

    local bossSkill = self.Boss and self.Boss:GetSkillByRound(self.BattleManager:GetBattleRound())

    self.GridBossSkill = XUiGridBuff.New(self.GridSkill, self)
    self.GridBossSkill:UpdateGrid(bossSkill,true)
end

function XUiPanelBossSkill:BossSkillChange()
    local bossSkill = self.Boss and self.Boss:GetSkillByRound(self.BattleManager:GetBattleRound())
    if not self.GridBossSkill then
        self.GridBossSkill = self:CreateBuffGrid(self.GridSkill)
    end
    self.GridBossSkill:UpdateGrid(bossSkill,true)
end

function XUiPanelBossSkill:DoSkillCountDown()
    self.GridBossSkill:DoCountdown()
end

--region 
function XUiPanelBossSkill:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BOSS_SKILL, self.BossSkillChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BOSS_SKIP_SKILL, self.BossSkillChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoSkillCountDown, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFT_TIME_CHANGE, self.DoSkillCountDown, self)
end

function XUiPanelBossSkill:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BOSS_SKILL, self.BossSkillChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BOSS_SKIP_SKILL, self.BossSkillChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoSkillCountDown, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFT_TIME_CHANGE, self.DoSkillCountDown, self)
end
--endregion

return XUiPanelBossSkill