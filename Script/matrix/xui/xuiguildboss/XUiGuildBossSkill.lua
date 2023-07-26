--工会bossBuff页面
local XUiGuildBossSkillGrid = require("XUi/XUiGuildBoss/Component/XUiGuildBossSkillGrid")
local XUiGuildBossSkill = XLuaUiManager.Register(XLuaUi, "UiGuildBossSkill")

function XUiGuildBossSkill:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.Instantiate = CS.UnityEngine.GameObject.Instantiate
    self.VectorOne = CS.UnityEngine.Vector3.one
    self.VectorZero = CS.UnityEngine.Vector3.zero

    self.Buffs = {}
end

function XUiGuildBossSkill:OnStart()
    self.LevelData = XDataCenter.GuildBossManager.GetLevelData()
    for i = 1, #self.LevelData do
        if self.LevelData[i].Type ~= GuildBossLevelType.Boss and self.Buffs[i] == nil then
            self.Buffs[i] = XUiGuildBossSkillGrid.New(self.Instantiate(self.SkillGrid))
            --关卡类型 参考GuildBossData.tab
            if self.LevelData[i].Type == GuildBossLevelType.Low then
                self.Buffs[i].Transform:SetParent(self.SkillGroup1)
            elseif self.LevelData[i].Type == GuildBossLevelType.High then
                self.Buffs[i].Transform:SetParent(self.SkillGroup2)
            end
            
            self.Buffs[i]:Init(XGuildBossConfig.GetBossStageInfo(self.LevelData[i].StageId), self.LevelData[i], self.LevelData[i].NameOrder)
            self.Buffs[i].Transform.localScale = self.VectorOne
            self.Buffs[i].Transform.localPosition = self.VectorZero
            self.Buffs[i].GameObject:SetActiveEx(true)
        end
    end

end

function XUiGuildBossSkill:OnDestroy()
    self.Buffs = {}

end

function XUiGuildBossSkill:OnBtnCloseClick()
    self:Close()
end
