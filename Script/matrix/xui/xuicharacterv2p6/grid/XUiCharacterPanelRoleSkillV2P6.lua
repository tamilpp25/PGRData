local XGridSkill = XClass(XUiNode, "XGridSkill")
local SHOW_SKILL_LEVEL = 1 --展示的等级

function XGridSkill:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSubSkillIconBg, self.OnBtnSubSkillIconBgClick)
end

function XGridSkill:Refresh(skillGroupId)
    if not skillGroupId then 
        self.GameObject:SetActiveEx(false) 
        return
    end

    local skillId = XMVCA.XCharacter:GetGroupDefaultSkillId(skillGroupId)
    local cfg = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, SHOW_SKILL_LEVEL)
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

local XUiCharacterPanelRoleSkillV2P6 = XClass(XUiNode, "XUiCharacterPanelRoleSkillV2P6")

local SIGNAL_BAL_MEMBER     = 3 --信号球技能（红黄蓝)

function XUiCharacterPanelRoleSkillV2P6:OnStart(onBackCb)
    self.OnBackCb = onBackCb
    
    self.SkillGrids = {}
    self.BallSkillGrids = {}
    
    self:InitUI()
    self.IsOpen = true
end 

function XUiCharacterPanelRoleSkillV2P6:InitUI()
    self.GridActiveSkill.gameObject:SetActiveEx(false)
    self.BasicSkills.gameObject:SetActiveEx(false)
    for i = 2, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiCharacterPanelRoleSkillV2P6:Refresh(characterId)
    if not characterId then return end

    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    self.SkillList = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(characterId)
    
    self:RefreshDetail(self.IsOpen)
end

function XUiCharacterPanelRoleSkillV2P6:RefreshDetail(isOpen)
    if not isOpen then return end
    
    self.IsOpen = true
    
    if not self.SkillList or XTool.IsTableEmpty(self.SkillList) then
        return
    end
    -- 特殊处理
    local ballSkill1 = {}
    local ballSkill2 = {}
    for _, skillGroupId in pairs(self.SkillList[1] or {}) do
        local skillId = XMVCA.XCharacter:GetGroupDefaultSkillId(skillGroupId)
        local skillType = XMVCA.XCharacter:GetSkillType(skillId)
        if skillType <= SIGNAL_BAL_MEMBER then
            table.insert(ballSkill1, skillGroupId)
        else
            table.insert(ballSkill2, skillGroupId)
        end
    end
    self:RefreshBallSkill(ballSkill1)
    self:RefreshSkill(ballSkill2, self.GridActiveSkill, self.PanelSkillGroup1, 1)
    
    for i = 2, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local panel = self["PanelSkillGroup" .. i]
        local skills = self.SkillList[i]
        local parent =  XUiHelper.TryGetComponent(panel, "PanelActiveSkill")
        local grid = XUiHelper.TryGetComponent(panel, "PanelActiveSkill/GridActiveSkill")
        
        self:RefreshSkill(skills, grid, parent, i)
    end
end

function XUiCharacterPanelRoleSkillV2P6:RefreshSkill(skills, grid, parent, index)
    if XTool.IsTableEmpty(self.SkillGrids[index]) then
        self.SkillGrids[index] = {}
    end
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.SkillGrids[index])
        return
    end

    self:RefreshGrid(#skills, skills, self.SkillGrids[index], grid, parent)
end

function XUiCharacterPanelRoleSkillV2P6:RefreshBallSkill(skills)
    if XTool.IsTableEmpty(skills) then
        self:DisableSkillGrid(self.BallSkillGrids)
        return
    end
    
    self:RefreshGrid(#skills, skills, self.BallSkillGrids, self.BasicSkills, self.PanelSkillGroup1)
end

function XUiCharacterPanelRoleSkillV2P6:DisableSkillGrid(skillGirdList)
    for _, grid in ipairs(skillGirdList) do
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiCharacterPanelRoleSkillV2P6:RefreshGrid(length, skills, grids, grid, parent)
    for idx = 1, length do
        local item  = grids[idx]
        if not item then
            local ui = XUiHelper.Instantiate(grid, parent);
            item = XGridSkill.New(ui, self)
            item.GameObject:SetActiveEx(true)
            grids[idx] = item
        end
        item:Open()
        item:Refresh(skills[idx])
    end

    for i = length + 1, #grids do
        grids[i].GameObject:SetActiveEx(false)
    end
end

return XUiCharacterPanelRoleSkillV2P6