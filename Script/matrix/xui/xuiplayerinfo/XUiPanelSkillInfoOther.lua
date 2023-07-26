-- V1.29 角色技能优化 该类不在使用 具体使用在 UiSkillDetailsOther
XUiPanelSkillInfoOther = XClass(nil, "XUiPanelSkillInfoOther")

local MAX_SUB_SKILL_GRID_COUNT = 6
local MAX_MAIN_SKILL_GRID_COUNT = 5

function XUiPanelSkillInfoOther:Ctor(ui, parent, rootUi, npcData,assignChapterRecords)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.RootUi = rootUi
    self.NpcData = npcData
    self.AssignChapterRecords = assignChapterRecords
    self:InitAutoScript()

    self.SkillPoint.gameObject:SetActive(false)
    self.SubSkillInfo.gameObject:SetActive(false)
    self.GridSkillInfo.gameObject:SetActive(false)
    self.GridSubSkill.gameObject:SetActive(false)

    self.SkillInfoGo = {}
    self.SkillInfoGrids = {}
    table.insert(self.SkillInfoGo, self.GridSkillInfo)

    self:InitSubSkillGrids()
end

function XUiPanelSkillInfoOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelSkillInfoOther:AutoInitUi()
    self.SkillPoint = self.Transform:Find("SkillPoint")
    self.SubSkillInfo = self.Transform:Find("PaneSkillInfo/SubSkillInfo")
    self.GridSubSkill = self.Transform:Find("PaneSkillInfo/PanelSubSkillList/GridSubSkill")
    self.GridSkillInfo = self.Transform:Find("PaneSkillInfo/PanelScroll/GridSkillInfo")

    self.PanelSkillBig = self.Transform:Find("PaneSkillInfo/PanelSkillBig")
    self.PanelSubSkillList = self.Transform:Find("PaneSkillInfo/PanelSubSkillList")
    self.PanelScroll = self.Transform:Find("PaneSkillInfo/PanelScroll")
    self.BtnHuadong = self.Transform:Find("PaneSkillInfo/BtnHuadong"):GetComponent("Button")
    self.BtnHuadong1 = self.Transform:Find("PaneSkillInfo/BtnHuadong1"):GetComponent("Button")

    self.ImgSkillPointIcon = self.Transform:Find("PaneSkillInfo/PanelSkillBig/ImgSkillPointIcon"):GetComponent("Image")
    self.TxtSkillType = self.Transform:Find("PaneSkillInfo/PanelSkillBig/TxtSkillType"):GetComponent("Text")
    self.TxtSkillName = self.Transform:Find("PaneSkillInfo/PanelSkillBig/TxtSkillName"):GetComponent("Text")
    self.TxtSkillLevel = self.Transform:Find("PaneSkillInfo/PanelSkillBig/TxtSkillLevel"):GetComponent("Text")

end

function XUiPanelSkillInfoOther:InitSubSkillGrids()
    self.SubSkillGrids = {}
    for i = 1, MAX_SUB_SKILL_GRID_COUNT do
        local item = CS.UnityEngine.Object.Instantiate(self.GridSubSkill)  -- 复制一个item
        local grid = XUiGridSubSkillOther.New(item, i, self.NpcData, self.AssignChapterRecords, function(subSkill, index)
            self:UpdateSubSkillInfoPanel(subSkill, index)
        end)
        grid.GameObject:SetActive(false)
        grid.Transform:SetParent(self.PanelSubSkillList, false)
        table.insert(self.SubSkillGrids, grid)
    end
end

function XUiPanelSkillInfoOther:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSkillInfo:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSkillInfo:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSkillInfoOther:AutoAddListener()
    self:RegisterClickEvent(self.BtnHuadong, self.OnBtnHuadongClick)
    self:RegisterClickEvent(self.BtnHuadong1, self.OnBtnHuadong1Click)
end

function XUiPanelSkillInfoOther:OnBtnHuadongClick()
    if self.Pos then
        self:GotoSkill(self.Pos + 1)
    end
end

function XUiPanelSkillInfoOther:OnBtnHuadong1Click()
    if self.Pos then
        self:GotoSkill(self.Pos - 1)
    end
end

function XUiPanelSkillInfoOther:GotoSkill(index)
    if self.Parent.SkillGrids[index] then
        self.Parent.SkillGrids[index]:OnBtnIconBgClick()
    end
    self:UpdateArrowView()
end

function XUiPanelSkillInfoOther:UpdateArrowView()
    self.BtnHuadong.gameObject:SetActive(not (self.Pos == MAX_MAIN_SKILL_GRID_COUNT))
    self.BtnHuadong1.gameObject:SetActive(not (self.Pos == 1))
end

function XUiPanelSkillInfoOther:ShowPanel(characterId, skills, pos)
    self.CharacterId = characterId or self.CharacterId
    self.Skills = skills
    self.Pos = pos
    self.Skill = skills[pos]
    self.IsShow = true
    self.GameObject:SetActive(true)

    for i, skill in pairs(skills) do
        local grid = self.SkillInfoGrids[i]
        if (grid == nil) then
            local ui_item = self.SkillInfoGo[i]
            if (ui_item == nil) then
                ui_item = CS.UnityEngine.Object.Instantiate(self.GridSkillInfo, self.PanelScroll)
                ui_item.transform:SetAsFirstSibling()
                table.insert(self.SkillInfoGo, ui_item)
            end
            grid = XUiGridSkillInfo.New(ui_item, skill, function(skillId)
                self.Parent:ShowLevelDetail(skillId)
            end)
            table.insert(self.SkillInfoGrids, grid)
        else
            grid:UpdateData(skill)
        end

        grid.GameObject:SetActive(true)
    end

    self:RefreshPanel( self.Skill)
    self:RefreshData()
    -- 默认点击
    if self.SubSkillGrids[1] then
        self.SubSkillGrids[1]:OnBtnSubSkillIconBgClick()
    end

    self:UpdateArrowView()
    self.Parent.SkillInfoQiehuan:PlayTimelineAnimation()
end

function XUiPanelSkillInfoOther:RefreshData()
    local characterId = self.CharacterId
    if not characterId then return end

    self.Skills = XCharacterConfigs.GetCharacterSkillsByCharacter(self.NpcData.Character)
    local skill = self.Skills[self.Skill.config.Pos]
    local grid = self.SkillInfoGrids[self.Pos]
    for i = 1, #self.SkillInfoGrids do
        self.SkillInfoGrids[i].GameObject:SetActive(self.Pos == i)
    end
    if (grid) then
        grid:UpdateData(skill)
    end
    self.Parent:UpdatePanel(self.NpcData.Character)
    self:RefreshPanel(skill)
    self:RefreshBigSkill(skill)
end

function XUiPanelSkillInfoOther:RefreshBigSkill(skill)
    self.RootUi:SetUiSprite(self.ImgSkillPointIcon, skill.Icon)
    self.TxtSkillType.text = skill.TypeDes
    self.TxtSkillName.text = skill.Name

    local addLevel = 0

    for _, skillId in pairs(skill.SkillIdList) do
        local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(self.NpcData)
        local resonanceSkillLevel = resonanceSkillLevelMap[skillId] or 0
        addLevel = addLevel + resonanceSkillLevel + XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(self.NpcData.Character, skillId, self.AssignChapterRecords)
    end


    local totalLevel = skill.TotalLevel + addLevel
    self.TxtSkillLevel.text = totalLevel
end

function XUiPanelSkillInfoOther:RefreshPanel( skill)
    self:UpdateSubSkillList(skill.subSkills)

    for i, sub_skill in ipairs(skill.subSkills) do
        if (i == self.CurSubSkillIndex) then
            self:UpdateSubSkillInfoPanel(sub_skill, self.CurSubSkillIndex)
            break
        end
    end
end

function XUiPanelSkillInfoOther:UpdateSubSkillList(subSkillList)
    for _, grid in pairs(self.SubSkillGrids) do
        grid:Reset()
    end

    local count = #subSkillList

    if count > MAX_SUB_SKILL_GRID_COUNT then
        XLog.Warning("max subskill grid count is " .. MAX_SUB_SKILL_GRID_COUNT)
        count = MAX_SUB_SKILL_GRID_COUNT
    end

    for i = 1, count do
        local sub_skill = subSkillList[i]
        local grid = self.SubSkillGrids[i]
        grid:UpdateGrid(sub_skill)
        grid.GameObject.name = sub_skill.SubSkillId

        if i == 1 then
            grid:SetSelect(true)
        end
    end
end

--技能格子点击
function XUiPanelSkillInfoOther:UpdateSubSkillInfoPanel(subSkill, index)
    if not subSkill then return end

    if self.CurSubSkillIndex then
        self.SubSkillGrids[self.CurSubSkillIndex]:SetSelect(false)
    end

    local grid = self.SkillInfoGrids[self.Pos]
    if grid then
        grid:SetSubInfoByCharacterData(self.NpcData, index, subSkill.Level, subSkill.SubSkillId, self.AssignChapterRecords)
    end

    self.CurSubSkillIndex = index
    self.SubSkillGrids[self.CurSubSkillIndex]:SetSelect(true)
    self.CurSubSkill = subSkill

    for _, tmpGrid in pairs(self.SubSkillGrids) do
        tmpGrid:ResetSelect(subSkill.SubSkillId)
    end
end

function XUiPanelSkillInfoOther:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
    self.CurSubSkillIndex = nil
    self.CurSubSkill = nil
end