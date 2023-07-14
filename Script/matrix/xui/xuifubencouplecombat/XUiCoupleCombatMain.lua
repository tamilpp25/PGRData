local XUiPanelChapter = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelChapter")
local XUiGlobalComboIcon = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGlobalComboIcon")
local XUiGridSkill = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGridSkill")

--关卡选择界面
local XUiCoupleCombatMain = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatMain")

function XUiCoupleCombatMain:OnAwake()
    self.TabBtns = {}
    self.SwitchEffect = {}
    self.GridSkillTemplates = {}
    self.GridSkill.gameObject:SetActiveEx(false)
end

function XUiCoupleCombatMain:OnEnable()
    self:Refresh()
    self:UpdateSkill()
    XDataCenter.FubenCoupleCombatManager.CheckCharacterCareerSkillInDic()
end

function XUiCoupleCombatMain:OnStart(chapterId, chapterIndex)
    self.ChapterId = chapterId
    self.ChapterIndex = chapterIndex

    self:InitGlobalCombo()

    self.TxtTitle.text = XFubenCoupleCombatConfig.GetChapterName(chapterId)

    self:InitUiView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PointRewardGridList = {}
end

function XUiCoupleCombatMain:OnReleaseInst()
    return self.ChapterId
end

function XUiCoupleCombatMain:OnGetEvents()
    return { XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE,
             CS.XEventId.EVENT_UI_DONE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiCoupleCombatMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE then
        self:Refresh()
    elseif evt == CS.XEventId.EVENT_UI_DONE then
        if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
            XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
            return
        end
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.CoupleCombat then return end
        XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
    end
end

function XUiCoupleCombatMain:Refresh(isAutoScroll)
    if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
        XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
        return
    end

    local chapterId = self:GetChapterId()
    self.PanelStage:SetUiData(chapterId, isAutoScroll)

    local passCount, allCount = XDataCenter.FubenCoupleCombatManager.GetStageSchedule(chapterId)
    self.TxtPassCount.text = passCount
    self.TxtStageCount.text = string.format("/%d", allCount)
end

function XUiCoupleCombatMain:UpdateSkill()
    local usedSkillIds = XDataCenter.FubenCoupleCombatManager.GetUsedSkillIds()
    local gridSkill
    local skillCount = #usedSkillIds
    for i, skillId in ipairs(usedSkillIds) do
        gridSkill = self.GridSkillTemplates[i]
        if not gridSkill then
            local grid = CS.UnityEngine.Object.Instantiate(self.GridSkill.gameObject, self.PanelSkillList)
            local index = skillCount - i + 1
            gridSkill = XUiGridSkill.New(grid, self, index)
            self.GridSkillTemplates[i] = gridSkill
        end
        gridSkill:RefreshData(skillId)
        gridSkill.GameObject:SetActiveEx(true)
    end

    for i = skillCount + 1, #self.GridSkillTemplates do
        self.GridSkillTemplates[i].GameObject:SetActiveEx(false)
    end
end

function XUiCoupleCombatMain:OnDestroy()
    self:StopActivityTimer()
    if self.PanelStage then
        self.PanelStage:OnDestroy()
    end
end

function XUiCoupleCombatMain:InitGlobalCombo()
    local chapterId = self:GetChapterId()
    local showFightEventIds = XFubenCoupleCombatConfig.GetChapterShowFightEventIds(chapterId)

    if not self.GlobalIcons then self.GlobalIcons = {} end
    for i, showFightEventId in ipairs(showFightEventIds) do
        if not self.GlobalIcons[i] then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuffIcon.gameObject, self.PanelBuffIcon)
            local icon = XUiGlobalComboIcon.New(prefab, self)
            table.insert(self.GlobalIcons, icon)
        end
        self.GlobalIcons[i]:RefreshData(showFightEventId)
        self.GlobalIcons[i].GameObject:SetActiveEx(true)
    end
    for i = #showFightEventIds + 1, #self.GlobalIcons do
        self.GlobalIcons[i].gameObject:SetActiveEx(false)
    end

    self.GridBuffIcon.gameObject:SetActiveEx(false)
    self.BtnBuff.gameObject:SetActiveEx(not XTool.IsTableEmpty(showFightEventIds))
end

function XUiCoupleCombatMain:InitUiView()
    self.SceneBtnBack.CallBack = function() self:Close() end
    self.SceneBtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnBuff.CallBack = function() self:OnBtnBuffClick() end
    self.BtnSkill.CallBack = function() self:OnBtnSkillClick() end

    self:BindHelpBtn(self.BtnHelp, "CoupleCombat")
    self.PanelStage = XUiPanelChapter.New(self.PanelChapter, self, self.ChapterIndex)
    self.RImgBgNor.gameObject:SetActiveEx(XFubenCoupleCombatConfig.GetChapterType(self.ChapterId) == XFubenCoupleCombatConfig.ChapterType.Normal)
    self.RImgBgHard.gameObject:SetActiveEx(XFubenCoupleCombatConfig.GetChapterType(self.ChapterId) == XFubenCoupleCombatConfig.ChapterType.Hard)
end

function XUiCoupleCombatMain:OnBtnSkillClick()
    XLuaUiManager.Open("UiCoupleCombatSwitchSkill")
end

function XUiCoupleCombatMain:OnBtnBuffClick()
    local chapterId = self:GetChapterId()
    XLuaUiManager.Open("UiCoupleCombatBuffTips", chapterId)
end

function XUiCoupleCombatMain:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

function XUiCoupleCombatMain:GetChapterId()
    return self.ChapterId
end