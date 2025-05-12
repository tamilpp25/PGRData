local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridSkillGroup = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGridSkillGroup")

local CsXTextManagerGetText = CsXTextManagerGetText
local TWEE_DURATION

--技能切换界面
local XUiCoupleCombatSwitchSkill = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatSwitchSkill")

function XUiCoupleCombatSwitchSkill:OnAwake()
    self:AutoAddListener()
    local viewPortWidth = self.ViewPort.rect.width
    self.MarkX = viewPortWidth * 0.25
    self.InitPos = self.PanelStageContent.localPosition
    self.CurSelectGroupType = 1
    self.SkillGridTemplates = {}     --技能组控件集合
    TWEE_DURATION = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:InitSkillGroup()
end

function XUiCoupleCombatSwitchSkill:OnStart(skillId)
    self:SelectGroupType(skillId)
end

--选中技能组并打开选择技能的界面
function XUiCoupleCombatSwitchSkill:SelectGroupType(skillId)
    if not skillId then
        return
    end

    local skillType = XFubenCoupleCombatConfig.GetCharacterCareerSkillType(skillId)
    for _, skillGrid in pairs(self.SkillGridTemplates) do
        if skillType == skillGrid:GetSkillType() then
            skillGrid:OnBtnSkillIconClick()
            return
        end
    end
end

function XUiCoupleCombatSwitchSkill:Refresh(skillIds)
    for _, skillGrid in pairs(self.SkillGridTemplates) do
        skillGrid:UpdateSkillLv(skillIds)
    end
end

function XUiCoupleCombatSwitchSkill:InitSkillGroup()
    local skillGroupTypeToSkillIdsMap = XFubenCoupleCombatConfig.GetSkillGroupTypeToSkillIdsMap()
    local index = 1
    for type in pairs(skillGroupTypeToSkillIdsMap) do
        if self["GridSkill" .. index] then
            self.SkillGridTemplates[index] = XUiGridSkillGroup.New(self["GridSkill" .. index], self, handler(self, self.ClickGridCallback))
            self.SkillGridTemplates[index]:RefreshData(type)
        else
            XLog.Error("未找到GridSkill" .. index .. "的引用")
        end

        index = index + 1
    end
end

function XUiCoupleCombatSwitchSkill:ClickGridCallback(grid)
    self.LastSelectGrid = grid
    self:PlayScrollViewMove(grid)
end

function XUiCoupleCombatSwitchSkill:PlayScrollViewMove(grid)
    local skillType = grid:GetSkillType()
    local gridX = grid.Transform.localPosition.x
    local markX = self.MarkX
    local diffX = gridX + markX
    local targetPosX = self.InitPos.x - diffX

    local gridY = grid.Transform.localPosition.y
    local targetPosY = self.InitPos.y - gridY

    local contentPos = self.PanelStageContent.localPosition
    local tarPos = contentPos
    tarPos.x = targetPosX
    tarPos.y = targetPosY

    XLuaUiManager.SetMask(true)
    self.AssetPanel.GameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiCoupleCombatSkillDetail", skillType, handler(self, self.CancalSelectLastGrid))
    XUiHelper.DoMove(self.PanelStageContent, tarPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiCoupleCombatSwitchSkill:CancalSelectLastGrid()
    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
    end

    self.AssetPanel.GameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, self.InitPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiCoupleCombatSwitchSkill:OnGetEvents()
    return { XEventId.EVENT_FUBEN_COUPLECOMBAT_AMEND_CHARACTER_CAREER_SKILL}
end

function XUiCoupleCombatSwitchSkill:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_COUPLECOMBAT_AMEND_CHARACTER_CAREER_SKILL then
        self:Refresh(args[1])
    end
end

function XUiCoupleCombatSwitchSkill:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

function XUiCoupleCombatSwitchSkill:GetCurSelectGroupType()
    return self.CurSelectGroupType
end