local XUiSkillDetailGrid = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiSkillDetailGrid")

--主动技能列表界面
local XUiCoupleCombatSkillDetail = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatSkillDetail")

function XUiCoupleCombatSkillDetail:OnAwake()
    self.SkillGrids = {}
    self.GridActive.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiCoupleCombatSkillDetail:OnStart(skillType, cb)
    self.SkillType = skillType
    self.CloseCallback = cb

    self.TxtName.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupName(skillType)
    self.TxtPassive.text = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupDescription(skillType)

    local iconPath = XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupIcon(skillType)
    self.RImgIcon:SetRawImage(iconPath)
end

function XUiCoupleCombatSkillDetail:OnEnable()
    self:UpdateSkillGrids()
end

function XUiCoupleCombatSkillDetail:OnDisable()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiCoupleCombatSkillDetail:UpdateSkillGrids()
    local skillType = self.SkillType
    local skillIds = XFubenCoupleCombatConfig.GetCharacterCareerSkillIds(skillType)
    local skillGrid
    for i, skillId in ipairs(skillIds) do
        skillGrid = self.SkillGrids[i]
        if not skillGrid then
            local grid = CS.UnityEngine.Object.Instantiate(self.GridActive.gameObject, self.Content)
            skillGrid = XUiSkillDetailGrid.New(grid, self)
            self.SkillGrids[i] = skillGrid
        end
        skillGrid:RefreshData(skillId)
        skillGrid.GameObject:SetActiveEx(true)
    end

    for i = #skillIds + 1, #self.SkillGrids do
        self.SkillGrids[i].GameObject:SetActiveEx(false)
    end
end

function XUiCoupleCombatSkillDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnCloseDetail, self.Close)
end

function XUiCoupleCombatSkillDetail:OnGetEvents()
    return { XEventId.EVENT_FUBEN_COUPLECOMBAT_AMEND_CHARACTER_CAREER_SKILL}
end

function XUiCoupleCombatSkillDetail:OnNotify(evt)
    if evt == XEventId.EVENT_FUBEN_COUPLECOMBAT_AMEND_CHARACTER_CAREER_SKILL then
        self:UpdateSkillGrids()
    end
end