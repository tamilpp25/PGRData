local XUiSameColorGameGridBossSkill = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridBossSkill")

---@class XUiSameColorGamePanelBoss:XUiNode
---@field _Control XSameColorControl
local XUiSameColorGamePanelBoss = XClass(XUiNode, "XUiSameColorGamePanelBoss")

function XUiSameColorGamePanelBoss:Ctor(ui, rootUi)
    ---@type XUiSameColorGameBoss
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.QieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/QieHuan")
    ---@type XSCBoss
    self.Boss = nil
    ---@type XUiSameColorGameGridBossSkill[]
    self.SkillGrids = {}
    self:AddBtnListener()
end

--region Ui - Refresh
---@param boss XSCBoss
function XUiSameColorGamePanelBoss:SetData(boss)
    self.Boss = boss
    
    if self.TxtName then
        self.TxtName.text = boss:GetName()
    end
    if not string.IsNilOrEmpty(boss:GetNameEnIcon()) and self.RImgName then
        self.RImgName:SetRawImage(boss:GetNameEnIcon())
    end
    
    self:RefreshBossInfo()
    self:RefreshElement()
    self:RefreshSkills()
end
--endregion

--region Ui - BossInfo
function XUiSameColorGamePanelBoss:RefreshBossInfo()
    --local maxScore = self.Boss:GetMaxScore()
    --local showGradeInfo = self.Boss:GetIsOpen() and maxScore > 0
    --self.TxtMaxScore.text = XUiHelper.GetText("SCBossMaxScoreText", maxScore)
    --self.TxtMaxScore.gameObject:SetActiveEx(showGradeInfo)
    --self.RImgGradeIcon.gameObject:SetActiveEx(showGradeInfo)
    --self.RImgGradeIcon:SetRawImage(self.Boss:GetMaxGradeIcon())

    self.TxtTimesTitle.text = self.Boss:IsRoundType() and XUiHelper.GetText("SameColorRoundTitle")
            or self.Boss:IsTimeType() and XUiHelper.GetText("SameColorTimeTitle")
    self.TxtTimes.text = self.Boss:IsRoundType() and self.Boss:GetMaxRound()
            or self.Boss:IsTimeType() and self.Boss:GetMaxTime()
end
--endregion

--region Ui - Element
function XUiSameColorGamePanelBoss:RefreshElement()
    if not self.RImgElement then
        return
    end
    self.RImgElement:SetRawImage(self._Control:GetCfgAttributeTypeIcon(self.Boss:GetAttributeType()))
    self.TxtElementDescribe.text =  self._Control:GetCfgAttributeTypeBossDesc(self.Boss:GetAttributeType())
end
--endregion

--region Ui - Skill
function XUiSameColorGamePanelBoss:RefreshSkills()
    local skills = self.Boss:GetShowSkills()
    if not self.GridSkill then
        return
    end
    
    self.GridSkill.gameObject:SetActiveEx(false)
    for _, skillGrid in ipairs(self.SkillGrids) do
        skillGrid:Close()
    end
    for index, skill in ipairs(skills) do
        local skillGrid = self.SkillGrids[index]
        if skillGrid == nil then
            local go = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkill)
            skillGrid = XUiSameColorGameGridBossSkill.New(go, self)
            self.SkillGrids[index] = skillGrid
        end
        skillGrid:SetData(skill)
        skillGrid:Open()
    end
    --self:UpdateCurrentSkillDetail(skills[1])
    --self:SetGridSelectStatusBySkill(skills[1])
end

---@param skill XSCBossSkill 
function XUiSameColorGamePanelBoss:UpdateCurrentSkillDetail(skill)
    self.TxtSkillTitle.text = skill:GetName()
    self.TxtSkillDesc.text = skill:GetDesc()
end

---@param skill XSCBossSkill
function XUiSameColorGamePanelBoss:SetGridSelectStatusBySkill(skill)
    for _, value in ipairs(self.SkillGrids) do
        value:SetSelectStatusBySkill(skill)
    end
    self.QieHuan.gameObject:PlayTimelineAnimation()
end
--endregion

--region Ui - BtnListener
function XUiSameColorGamePanelBoss:AddBtnListener()
    local func = function()
        self.RootUi:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN)
    end
    self.BtnRole.CallBack = func
    XUiHelper.RegisterClickEvent(self, self.BtnClose, func)
end
--endregion

return XUiSameColorGamePanelBoss