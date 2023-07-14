local XUiGridChapter = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGridChapter")
local XUiGridSkill = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGridSkill")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--区域选择界面
local XUiCoupleCombatChapter = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatChapter")

function XUiCoupleCombatChapter:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterBtnGrids = {}
    self:AutoAddListener()
    self:InitChapterBtns()
    self:InitSkillIcons()
end

function XUiCoupleCombatChapter:OnEnable()
    self:CreateActivityTimer()
    self:UpdateSkill()
    self:UpdateTask()
end

function XUiCoupleCombatChapter:OnDisable()
    self:StopActivityTimer()
    self:StopGridChapterTimer()
end

function XUiCoupleCombatChapter:OnGetEvents()
    return { CS.XEventId.EVENT_UI_DONE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiCoupleCombatChapter:OnNotify(evt, ...)
    local args = { ... }
    if evt == CS.XEventId.EVENT_UI_DONE then
        if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
            XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
            return
        end
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.CoupleCombat then return end
        XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
    end
end

function XUiCoupleCombatChapter:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self:RegisterClickEvent(self.BtnSkill, self.OnClickBtnSkill)
    self:RegisterClickEvent(self.BtnTaskReward, self.OnBtnTaskRewardClick)
    
    self:BindHelpBtn(self.BtnHelp, "CoupleCombat")
end

function XUiCoupleCombatChapter:InitSkillIcons()
    self.GridSkillTemplates = {}
    self.GridSkill.gameObject:SetActiveEx(false)
end

function XUiCoupleCombatChapter:InitChapterBtns()
    self.ChapterIds = XDataCenter.FubenCoupleCombatManager.GetChapterIdList()
    for i, id in ipairs(self.ChapterIds) do
        local grid = XUiGridChapter.New(self["GridChapter" .. i])
        grid:Init(self)
        grid:Refresh(id, i)
        table.insert(self.ChapterBtnGrids, grid)
        self:RegisterClickEvent(grid.GridChapter, function()
            if not XDataCenter.FubenCoupleCombatManager.CheckChapterUnlock(id) then
                return
            end
            XLuaUiManager.Open("UiCoupleCombatMain", id, i)
        end)
    end
    -- 隐藏多余
    local index = #self.ChapterIds + 1
    local gridChapter = self["GridChapter" .. index]
    while gridChapter do
        gridChapter.gameObject:SetActiveEx(false)
        index = index + 1
        gridChapter = self["GridChapter" .. index]
    end
end

function XUiCoupleCombatChapter:UpdateTask()
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgress(TaskType.CoupleCombat)
    self.TxtTaskGotCount.text = passCount
    self.TxtTaskCount.text = allCount
    self.ImgJindu.fillAmount = passCount / allCount
    self.BtnTaskReward:ShowReddot(XDataCenter.TaskManager.GetIsRewardForEx(TaskType.CoupleCombat))
end

function XUiCoupleCombatChapter:UpdateSkill()
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

-- 计时器
function XUiCoupleCombatChapter:CreateActivityTimer()
    local endTime = XDataCenter.FubenCoupleCombatManager.GetEndTime()
    local time = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        time = XTime.GetServerNowTimestamp()
        if time > endTime then
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    end, XScheduleManager.SECOND, 0)
end

function XUiCoupleCombatChapter:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiCoupleCombatChapter:StopGridChapterTimer()
    local grids = self.ChapterBtnGrids
    for _, grid in pairs(grids) do
        grid:StopTimer()
    end
end

function XUiCoupleCombatChapter:OnBtnTaskRewardClick()
    XLuaUiManager.Open("UiFubenTaskReward", TaskType.CoupleCombat, nil, function()
        self:UpdateTask()
    end)
end

function XUiCoupleCombatChapter:OnClickBtnSkill()
    XLuaUiManager.Open("UiCoupleCombatSwitchSkill")
end

function XUiCoupleCombatChapter:OnClickBtnBack()
    self:Close()
end

function XUiCoupleCombatChapter:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end