local XUiPanelChapter = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelChapter")
local XUiPanelSkillTips = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelSkillTips")
local XUiPanelSkillDesc = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelSkillDesc")
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
    local icon = XFubenCoupleCombatConfig.GetChapterNameIcon(chapterId)
    if icon then
        self.ImgTitle:SetRawImage(icon)
    end

    self:InitUiView()
    self:InitSkillDesc()
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
    self.TxtProgress.text = string.format("%d/%d", passCount, allCount)
    if not self.ImgProgress then
        self.ImgProgress = self.TxtProgress.transform.parent:GetChild(self.TxtProgress.transform.parent.childCount - 1):GetComponent("Image")
    end
    self.ImgProgress.fillAmount = passCount / allCount
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
        gridSkill:RefreshData(skillId, function(careerskillId, index, cb) self:OpenPanelSkillTips(careerskillId, index, cb) end)
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
    self.BtnSkill.CallBack = function() self:OpenPanelSkillDesc() end

    self:BindHelpBtn(self.BtnHelp, "CoupleCombat")
    self.PanelStage = XUiPanelChapter.New(self.PanelChapter, self, self.ChapterIndex)
    self.RImgBgNor.gameObject:SetActiveEx(XFubenCoupleCombatConfig.GetChapterType(self.ChapterId) == XFubenCoupleCombatConfig.ChapterType.Normal)
    self.RImgBgHard.gameObject:SetActiveEx(XFubenCoupleCombatConfig.GetChapterType(self.ChapterId) == XFubenCoupleCombatConfig.ChapterType.Hard)
end

-- v1.32 四期技能介绍不再新开界面
function XUiCoupleCombatMain:InitSkillDesc()
    self.PanelSkillTips = XUiPanelSkillTips.New(self, self.PanelSkillTC2)
    self.PanelSkillDesc = XUiPanelSkillDesc.New(self, self.PanelSkillTC)
    self.PanelSkillTips:SetActive(false)
    self.PanelSkillDesc:SetActive(false)
end

-- 三期打开技能介绍
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

-- 四期打开技能介绍
function XUiCoupleCombatMain:OpenPanelSkillDesc()
    self.PanelSkillDesc:SetActive(true)
end

-- 四期打开单个技能介绍
function XUiCoupleCombatMain:OpenPanelSkillTips(careerskillId, index, cb)
    self.PanelSkillTips:SetData(careerskillId, index, cb)
    self.PanelSkillTips:SetActive(true)
end