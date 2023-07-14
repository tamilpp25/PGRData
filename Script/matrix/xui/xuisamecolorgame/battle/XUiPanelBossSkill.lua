local XUiPanelBossSkill= XClass(nil, "XUiPanelBossSkill")
local XUiGridBuff = require("XUi/XUiSameColorGame/Battle/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelBossSkill:Ctor(ui, base, boss)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Boss = boss
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPanelBossSkill:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BOSSSKILL, self.BossSkillChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BOSSSKIPSKILL, self.BossSkillChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoSkillCountDown, self)
end

function XUiPanelBossSkill:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BOSSSKILL, self.BossSkillChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BOSSSKIPSKILL, self.BossSkillChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoSkillCountDown, self)
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

return XUiPanelBossSkill