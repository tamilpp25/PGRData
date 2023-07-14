--######################## XUiSkillGrid ########################
local XUiSkillGrid = XClass(nil, "XUiSkillGrid")

function XUiSkillGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    -- XSCBossSkill
    self.Skill = nil
    XTool.InitUiObject(self)
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

-- skill : XSCBossSkill
function XUiSkillGrid:SetData(bossSkill)
    self.Skill = bossSkill
    self.TxtName.text = bossSkill:GetName()
    self.RImgIcon:SetRawImage(bossSkill:GetIcon())
end

function XUiSkillGrid:OnBtnSelfClicked()
    self.RootUi:UpdateCurrentSkillDetail(self.Skill)
    self.RootUi:SetGridSelectStatusBySkill(self.Skill)
end

function XUiSkillGrid:SetSelectStatusBySkill(bossSkill)
    self.PanelSelect.gameObject:SetActiveEx(bossSkill:GetId() == self.Skill:GetId())
end

--######################## XUiSameColorGamePanelBoss ########################

local XUiSameColorGamePanelBoss = XClass(nil, "XUiSameColorGamePanelBoss")

function XUiSameColorGamePanelBoss:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.QieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/QieHuan")
    self.RootUi = rootUi
    -- XSCBoss
    self.Boss = nil
    self.SkillGrids = {}
    self:RegisterUiEvents()
end

-- boss : XSCBoss
function XUiSameColorGamePanelBoss:SetData(boss)
    self.Boss = boss
    self.TxtName.text = boss:GetName()
    self.RImgGradeIcon:SetRawImage(boss:GetMaxGradeIcon())
    local maxScore = boss:GetMaxScore()
    self.TxtMaxScore.text = XUiHelper.GetText("SCBossMaxScoreText", maxScore)
    self.TxtStepsTitle.gameObject:SetActiveEx(boss:IsRoundType())
    if boss:IsRoundType() then
        self.TxtSteps.text = boss:GetMaxRound()
    end
    self.TxtTimesTitle.gameObject:SetActiveEx(boss:IsTimeType())
    if boss:IsTimeType() then
        self.TxtTimes.text = boss:GetMaxTime()
    end
    local showGradeInfo = self.Boss:GetIsOpen() and maxScore > 0
    self.RImgGradeIcon.gameObject:SetActiveEx(showGradeInfo)
    self.TxtMaxScore.gameObject:SetActiveEx(showGradeInfo)
    self:RefreshSkills()
end

function XUiSameColorGamePanelBoss:RefreshSkills()
    local skills = self.Boss:GetShowSkills()
    self.GridSkill.gameObject:SetActiveEx(false)
    for _, skillGrid in ipairs(self.SkillGrids) do
        skillGrid.GameObject:SetActiveEx(false)
    end
    local go, skillGrid
    for index, skill in ipairs(skills) do
        skillGrid = self.SkillGrids[index]
        if skillGrid == nil then
            go = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkill)
            skillGrid = XUiSkillGrid.New(go, self)
            self.SkillGrids[index] = skillGrid
        end
        skillGrid:SetData(skill)
        skillGrid.GameObject:SetActiveEx(true)
    end
    self:UpdateCurrentSkillDetail(skills[1])
    self:SetGridSelectStatusBySkill(skills[1])
end

function XUiSameColorGamePanelBoss:UpdateCurrentSkillDetail(skill)
    self.TxtSkillTitle.text = skill:GetName()
    self.TxtSkillDesc.text = skill:GetDesc()
end

function XUiSameColorGamePanelBoss:SetGridSelectStatusBySkill(skill)
    for _, value in ipairs(self.SkillGrids) do
        value:SetSelectStatusBySkill(skill)
    end
    self.QieHuan.gameObject:PlayTimelineAnimation()
end

function XUiSameColorGamePanelBoss:RegisterUiEvents()
    self.BtnRole.CallBack = function() 
        self.RootUi:UpdateChildPanel(XSameColorGameConfigs.UiBossChildPanelType.Main) 
    end
end

return XUiSameColorGamePanelBoss