
local XGridSkill = XClass(nil, "XGridSkill")
local SHOW_SKILL_LEVEL = 1 --展示的等级

function XGridSkill:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnSubSkillIconBg, self.OnBtnSubSkillIconBgClick)
end

function XGridSkill:Refresh(skillGroupId)

    if not skillGroupId then 
        self.GameObject:SetActiveEx(false) 
        return
    end

    local skillId = XCharacterConfigs.GetGroupDefaultSkillId(skillGroupId)
    local cfg = XCharacterConfigs.GetSkillGradeDesConfig(skillId, SHOW_SKILL_LEVEL)
    if not cfg then return end
    self.SkillData = cfg or self.SkillData
    self.RImgSubSkillIconNormal:SetRawImage(cfg.Icon)

    if self.RImgSubSkillIconSelected then
        self.RImgSubSkillIconSelected:SetRawImage(cfg.Icon)
    end

    --兼容两个控件
    local txtLevel = self.TxtLevel or self.TxtSubSkillLevel
    txtLevel.text = SHOW_SKILL_LEVEL

    self.PanelSkillLock.gameObject:SetActiveEx(false)

    self.GameObject:SetActiveEx(true)
end

function XGridSkill:OnBtnSubSkillIconBgClick()
    if not self.SkillData then return end
    XLuaUiManager.Open("UiCharacterBuffDetails", self.SkillData)
end


--===========================================================================
---@desc 技能预览界面
--===========================================================================

local XUiCharacterPanelRoleSkill = XClass(nil, "XUiCharacterPanelRoleSkill")

local SIGNAL_BAL_MEMBER     = 3 --信号球技能（红黄蓝)
local ACTIVE_SKILL_INDEX    = 4 --主动技能下标
local PASSIVE_SKILL_INDEX   = 5 --被动技能下标

function XUiCharacterPanelRoleSkill:Ctor(ui, onBackCb)
    
    XTool.InitUiObjectByUi(self, ui)
    self.OnBackCb = onBackCb
    
    self.BallSkillGrids = {}
    self.ActiveSkillGrids = {}
    self.PassiveSkillGrids = {}
    
    self:InitUI()
    self:InitCB()
end 

function XUiCharacterPanelRoleSkill:InitCB()
    self.BtnGoBack.CallBack = function()
        if self.OnBackCb then
            self.IsOpen = false
            self.OnBackCb("Back", false)
        end
    end
end 

function XUiCharacterPanelRoleSkill:InitUI()
    
    self.GridSkillBall.gameObject:SetActiveEx(false)
    self.GridActiveSkill.gameObject:SetActiveEx(false)
    self.GridSubSkill.gameObject:SetActiveEx(false)
end

function XUiCharacterPanelRoleSkill:Refresh(characterId)
    if not characterId then return end

    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    self.SkillList = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    
    self:Open(self.IsOpen)
end

function XUiCharacterPanelRoleSkill:Open(isOpen)
    if not isOpen then return end
    
    self.IsOpen = true
    
    if not self.SkillList or XTool.IsTableEmpty(self.SkillList) then
        return
    end
    
    local ballSkills = {}
    for i = 1, SIGNAL_BAL_MEMBER do
        for j = 1, #self.SkillList[i] do
            local skillId = self.SkillList[i][j]
            if XTool.IsNumberValid(skillId) then
                table.insert(ballSkills, skillId)
            end
        end
    end

    local activeSkills = self.SkillList[ACTIVE_SKILL_INDEX]
    local passiveSkills = self.SkillList[PASSIVE_SKILL_INDEX]
    
    self:RefreshBallSkill(ballSkills)
    self:RefreshActiveSkill(activeSkills)
    self:RefreshPassiveSkill(passiveSkills)
end

function XUiCharacterPanelRoleSkill:RefreshBallSkill(skills)
    if not skills then
        self:DisableSkillGrid(self.BallSkillGrids)
        return
    end
    
    self:RefreshGrid(SIGNAL_BAL_MEMBER, skills, self.BallSkillGrids, self.GridSkillBall, self.PanelSkilBall)
end

function XUiCharacterPanelRoleSkill:RefreshActiveSkill(skills)
    if not skills then
        self:DisableSkillGrid(self.ActiveSkillGrids)
        return
    end

    self:RefreshGrid(#skills, skills, self.ActiveSkillGrids, self.GridActiveSkill, self.PanelActiveSkill)
end

function XUiCharacterPanelRoleSkill:RefreshPassiveSkill(skills)

    if not skills then
        self:DisableSkillGrid(self.PassiveSkillGrids)
        return
    end
    
    self:RefreshGrid(#skills, skills, self.PassiveSkillGrids, self.GridSubSkill, self.PanelPassiveSkill)
end

function XUiCharacterPanelRoleSkill:DisableSkillGrid(skillGirdList)
    for _, grid in ipairs(skillGirdList) do
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiCharacterPanelRoleSkill:RefreshGrid(length, skills, grids, grid, parent)
    for idx = 1, length do
        local item  = grids[idx]
        if not item then
            local ui = XUiHelper.Instantiate(grid, parent);
            item = XGridSkill.New(ui)
            item.GameObject:SetActiveEx(true)
            grids[idx] = item
        end
        item:Refresh(skills[idx])
    end
end


return XUiCharacterPanelRoleSkill