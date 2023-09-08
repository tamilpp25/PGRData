--===========================================================================
--v1.28 品质预览：XUiPanelQualityPreview
--===========================================================================
local stringFormat = string.format

local XUiPanelQualityPreview = XLuaUiManager.Register(XLuaUi, "UiPanelQualityPreview")
local UiPanelQualitySkillDynamic = require("XUi/XUiCharacter/XUiPanelQualityPreview/XUiPanelQualityPreviewDynamic/XUiPanelQualitySkillDynamic")
local UiPanelQualityAttributeDynamaic = require("XUi/XUiCharacter/XUiPanelQualityPreview/XUiPanelQualityPreviewDynamic/XUiPanelQualityAttributeDynamic")

-- v1.28 升阶拆分
local TabKind = {
    Skill = 1,      --技能成长
    Attibute = 2,   --数值成长
}
local AttributeGrade = {
    Before = 1,     --升级前
    After = 2,      --升级后
}
local AttributeShow = {
    Life = 1,
    AttackNormal = 2,
    DefenseNormal = 3,
    Crit = 4,
    Quality = 5
}

function XUiPanelQualityPreview:OnAwake()
    self:AutoAddListener()
    self.AttributeData = {}
    self.SkillData = {}

    self:InitTabGroup()
end

function XUiPanelQualityPreview:OnStart(parent, characterId, skillStar)
    self.Parent = parent
    self:InitQualityPreviewData(characterId, skillStar)
    self:InitDynamicTableIndex()
    self:InitDynamicTable()
    
    if #self.SkillData > 0 then
        self.TabBtns[TabKind.Skill].gameObject:SetActiveEx(true)
        self.BtnGroup:SelectIndex(TabKind.Skill)
    else
        self.TabBtns[TabKind.Skill].gameObject:SetActiveEx(false)
        self.BtnGroup:SelectIndex(TabKind.Attibute)
    end
end

function XUiPanelQualityPreview:OnEnable()
    --self.BtnGroup:SelectIndex(self.SelectIndex or 1)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 初始化预览界面数据
--===========================================================================
function XUiPanelQualityPreview:InitQualityPreviewData(characterId, skillStar)
    self.CharacterId = characterId
    self.CharacterMinQuality = XMVCA.XCharacter:GetCharMinQuality(self.CharacterId)
    self.CharacterMaxQuality = XCharacterConfigs.GetCharMaxQuality(self.CharacterId)
    self.Character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    --技能节点打开的位置
    self.SkillStar = skillStar
    --获取成长率数据
    self.AttributeData = {}
    local attritubues = {}
    for i = self.CharacterMinQuality, self.CharacterMaxQuality do
        local attrbis = XCharacterConfigs.GetNpcPromotedAttribByQuality(self.CharacterId, i)
        local temp = {}
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Life])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.AttackNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.DefenseNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Crit])))
        table.insert(temp, i)
        table.insert(attritubues, temp)
    end
    --处理品质前后数值变化
    for i = 1, #attritubues - 1 do
        local result = {}
        table.insert(result, attritubues[i])
        table.insert(result, attritubues[i + 1])
        table.insert(self.AttributeData, result)
    end

    --获取技能升阶数据
    self.SkillData = XDataCenter.CharacterManager.GetCharQualitySkillInfo(self.CharacterId)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 初始化动态列表index
--===========================================================================
function XUiPanelQualityPreview:InitDynamicTableIndex()
    --计算数值页签打开位置
    local attributeDataLength = #self.AttributeData
    for i = 1, attributeDataLength do
        if self.Character.Quality == self.AttributeData[i][AttributeGrade.Before][AttributeShow.Quality] then
            self.AttTabIndex = i
        end
    end
    --满品质特殊计算
    if self.Character.Quality == self.AttributeData[attributeDataLength][AttributeGrade.After][AttributeShow.Quality] then
        self.AttTabIndex = attributeDataLength
    end

    --计算技能页签打开位置
    local quality = self.Character.Quality
    local star = self.Character.Star
    local dataLength = #self.SkillData
    if dataLength <= 0 then return end
    if self.SkillStar then              --指定技能节点
        for i = 1, dataLength do
            local skillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillData[i])
            local skillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillData[i])
            if quality == skillQuality and self.SkillStar == skillPhase then
                self.SkillTabIndex = i
                return
            end
        end
    else                                --不指定技能节点
        for i = 1, dataLength do
            local skillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillData[i])
            local skillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillData[i])
            if quality > skillQuality or (quality == skillQuality and star >= skillPhase) then
                self.SkillTabIndex = i
            end
        end
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 更新动态列表数据
--===========================================================================
function XUiPanelQualityPreview:UpdateDynamicTableData(characterId, skillStar)
    self:InitQualityPreviewData(characterId, skillStar)
    self:InitDynamicTableIndex()

    self.SkillDynamicTable:RefreshData(self.SkillData, self.Character)
    self.AttDynamicTable:RefreshData(self.AttributeData, self.Character.Quality)
    if #self.SkillData > 0 then
        self.TabBtns[TabKind.Skill].gameObject:SetActiveEx(true)
        self.BtnGroup:SelectIndex(TabKind.Skill)
    else
        self.TabBtns[TabKind.Skill].gameObject:SetActiveEx(false)
        self.BtnGroup:SelectIndex(TabKind.Attibute)
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 初始化页签
--===========================================================================
function XUiPanelQualityPreview:InitTabGroup()
    self.TabBtns = {}
    if self.Btn1 then       --页签下技能成长数据
        self.Btn1:SetName(XUiHelper.GetText("CharacterQualitySkillText"))
        table.insert(self.TabBtns, self.Btn1)
    end
    if self.Btn2 then       --页签下数值成长数据
        self.Btn2:SetName(XUiHelper.GetText("CharacterQualityAttributeText"))
        table.insert(self.TabBtns, self.Btn2)
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 页签切换
--===========================================================================
function XUiPanelQualityPreview:OnSelectedTog(index)
    if not index and not self.SkillStar then
        return
    end
    self.SelectIndex = index
    --self:PlayAnimation("QieHuan")
    if self.SelectIndex == TabKind.Skill then
        self:RefreshSkill()
    else
        self:RefreshAttrib()
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 初始化动态表
--===========================================================================
function XUiPanelQualityPreview:InitDynamicTable()
    self.SkillDynamicTable = UiPanelQualitySkillDynamic.New(self.PanelSkill, self, self.SkillData, self.Character)
    self.AttDynamicTable = UiPanelQualityAttributeDynamaic.New(self.PanelPreview, self.AttributeData, self.Character.Quality)
    
    self.GridSkill.gameObject:SetActiveEx(false)
    self.GridAttribute.gameObject:SetActiveEx(false)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 展示技能成长动态列表
--===========================================================================
function XUiPanelQualityPreview:RefreshSkill()
    self.PanelSkill.gameObject:SetActive(true)
    self.PanelPreview.gameObject:SetActive(false)
    self.SkillDynamicTable:UpdateDynamicTable(self.SkillTabIndex)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 展示数值成长动态列表
--===========================================================================
function XUiPanelQualityPreview:RefreshAttrib()
    self.PanelSkill.gameObject:SetActiveEx(false)
    self.PanelPreview.gameObject:SetActiveEx(true)
    self.AttDynamicTable:UpdateDynamicTable(self.AttTabIndex)
end

function XUiPanelQualityPreview:AutoAddListener()
    self:RegisterClickEvent(self.BtnDarkBg, self.OnBtnDarkBgClick)
end

function XUiPanelQualityPreview:OnBtnDarkBgClick()
    self:Close()
end

--===========================================================================
--v1.28【角色】升阶拆分 - 跳转到升级的技能
--===========================================================================
function XUiPanelQualityPreview:OnBtnSkillClick(skillId)
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_QUALITY_SKILL, self.CharacterId, skillId)
    self:Close()
end