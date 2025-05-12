local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTemple2ChapterGrid = require("XUi/XUiTemple2/System/Main/XUiTemple2ChapterGrid")
local XRedPointConditionTemple2 = require("XRedPoint/XRedPointConditions/XRedPointConditionTemple2")

---@class XUiTemple2Chapter : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Chapter = XLuaUiManager.Register(XLuaUi, "UiTemple2Chapter")

function XUiTemple2Chapter:Ctor()
    ---@type XUiTemple2ChapterGrid[]
    self._Chapters = {}
    self._Items = {}
    self._TimerUpdate = false
end

function XUiTemple2Chapter:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(nil, "Temple2Help")
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:RegisterClickEvent(self.BtnStory, self.OnClickStory)
    self:RegisterClickEvent(self.BtnShop, self.OnClickShop)
    self.BtnStory:ShowReddot(false)
    self.BtnShop:ShowReddot(false)
end

function XUiTemple2Chapter:OnStart()
    self:UpdateReward()
end

function XUiTemple2Chapter:OnEnable()
    self:Update()
    self.BtnTask:ShowReddot(XRedPointConditionTemple2.CheckTask())
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_STAGE, self.Update, self)
    self._Control:GetSystemControl():CheckPlayMovie()
end

function XUiTemple2Chapter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_STAGE, self.Update, self)
    if self._TimerUpdate then
        XScheduleManager.UnSchedule(self._TimerUpdate)
    end
end

function XUiTemple2Chapter:Update()
    local chapterIndex = self._Control:GetSystemControl():GetCurrentChapterIndex()

    if self.PanelListChapter2 then
        for i = 1, 2 do
            ---@type UnityEngine.RectTransform
            local panelChapter = self["PanelListChapter" .. i]
            panelChapter.gameObject:SetActiveEx(chapterIndex == i)
        end
    end

    self._Control:GetSystemControl():UpdateStage()
    local stageList = self._Control:GetSystemControl():GetDataStage()
    for i = 1, #stageList do
        local grid = self._Chapters[i]
        if not grid then
            ---@type UnityEngine.RectTransform
            local panelChapter = self["PanelChapter" .. chapterIndex]
            if i <= panelChapter.childCount then
                local parent = panelChapter:GetChild(i - 1)
                if parent then
                    local prefab = XUiHelper.Instantiate(self.GridChapter, parent)
                    grid = XUiTemple2ChapterGrid.New(prefab, self)
                    self._Chapters[i] = grid
                else
                    XLog.Error("[XUiTemple2Chapter] 配置的数量大于，章节的ui节点数量了，通知ui加一下:", i)
                end
            end
        end
        if grid then
            grid:Update(stageList[i])
        end
    end
    self.GridChapter.gameObject:SetActiveEx(false)

    -- 未解锁时，定时刷新
    local isAnyStageLock = false
    for i = 1, #stageList do
        local stage = stageList[i]
        if not stage.IsUnlock then
            isAnyStageLock = true
        end
    end
    if isAnyStageLock then
        if not self._TimerUpdate then
            self._TimerUpdate = XScheduleManager.ScheduleForever(function()
                self:Update()
            end, 10000)
        end
    else
        -- 全解锁时， 解除定时器
        if self._TimerUpdate then
            XScheduleManager.UnSchedule(self._TimerUpdate)
            self._TimerUpdate = false
        end
    end
end

function XUiTemple2Chapter:OnClickTask()
    XLuaUiManager.Open("UiTemple2Task")
end

function XUiTemple2Chapter:OnClickStory()
    XLuaUiManager.Open("UiTemple2Story")
end

function XUiTemple2Chapter:OnClickShop()
    self._Control:OpenShop()
end

function XUiTemple2Chapter:UpdateReward()
    local rewardList = self._Control:GetTaskReward4Show()
    XUiHelper.CreateTemplates(self, self._Items, rewardList, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    self.Grid256New.gameObject:SetActiveEx(false)
    --self._TimerReward = XScheduleManager.ScheduleOnce(function()
    --    self.Grid256New.transform.parent.gameObject:SetActiveEx(false)
    --end, 3 * XScheduleManager.SECOND)
end

return XUiTemple2Chapter