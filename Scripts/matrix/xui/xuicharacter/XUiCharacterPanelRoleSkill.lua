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
    XLuaUiManager.Open("UiSkillDetailsTips", self.SkillData)
end


--===========================================================================
---@desc 技能预览界面
--===========================================================================

local XUiCharacterPanelRoleSkill = XClass(nil, "XUiCharacterPanelRoleSkill")

local SIGNAL_BAL_MEMBER     = 3 --信号球技能（红黄蓝)

function XUiCharacterPanelRoleSkill:Ctor(ui, onBackCb)
    
    XTool.InitUiObjectByUi(self, ui)
    self.OnBackCb = onBackCb
    
    self.SkillGrids = {}
    self.BallSkillGrids = {}
    
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
    self.GridActiveSkill.gameObject:SetActiveEx(false)
    self.BasicSkills.gameObject:SetActiveEx(false)
    for i = 2, XCharacterConfigs.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
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
    -- 特殊处理
    local ballSkill1 = {}
    local ballSkill2 = {}
    for _, skillGroupId in pairs(self.SkillList[1] or {}) do
        local skillId = XCharacterConfigs.GetGroupDefaultSkillId(skillGroupId)
        local skillType = XCharacterConfigs.GetSkillType(skillId)
        if skillType <= SIGNAL_BAL_MEMBER then
            table.insert(ballSkill1, skillGroupId)
        else
            table.insert(ballSkill2, skillGroupId)
        end
    end
    self:RefreshBallSkill(ballSkill1)
    self:RefreshSkill(ballSkill2, self.GridActiveSkill, self.PanelSkillGroup1, 1)
    
    for i = 2, XCharacterConfigs.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local skills = self.SkillList[i]
        local parent =  XUiHelper.TryGetComponent(panel, "PanelActiveSkill")
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")
        
        self:RefreshSkill(skills, grid, parent, i)
    end
end

function XUiCharacterPanelRoleSkill:RefreshSkill(skills, grid, parent, index)
    if XTool.IsTableEmpty(self.SkillGrids[index]) then
        self.SkillGrids[index] = {}
    end
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.SkillGrids[index])
        return
    end

    self:RefreshGrid(#skills, skills, self.SkillGrids[index], grid, parent)
end

function XUiCharacterPanelRoleSkill:RefreshBallSkill(skills)
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.BallSkillGrids)
        return
    end
    
    self:RefreshGrid(#skills, skills, self.BallSkillGrids, self.BasicSkills, self.PanelSkillGroup1)
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

    for i = length + 1, #grids do
        grids[i].GameObject:SetActiveEx(false)
    end
end


return XUiCharacterPanelRoleSkill