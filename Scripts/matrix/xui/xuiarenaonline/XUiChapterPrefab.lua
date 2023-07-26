local XUiChapterPrefab = XClass(nil, "XUiChapterPrefab")
local XUiGridSection = require("XUi/XUiArenaOnline/XUiGridSection")

local MAX_SECTION_COUNT = 10
function XUiChapterPrefab:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.SectionGrids = {}
    XTool.InitUiObject(self)
    self.Canvas.sortingOrder = self.Canvas.sortingOrder + self.UiRoot:GetSortingOrder()
    self.PanelTip.sortingOrder = self.PanelTip.sortingOrder + self.UiRoot:GetSortingOrder()
    self.PanelTip.gameObject:SetActiveEx(false)
end

function XUiChapterPrefab:OnEnable()
    self.Show = true
    self:Refresh()
    --XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.AreaChange, self)
end

function XUiChapterPrefab:OnDisable()
    self.Show = false
end

function XUiChapterPrefab:Refresh()
    self.AnimEnable:PlayTimelineAnimation()
    local chapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
    if not chapterCfg then return end

    self.TxtName.text = chapterCfg.Title
    self.TxtLv.text = CS.XTextManager.GetText("ArenaOnlineChapterLevel", chapterCfg.MinLevel, chapterCfg.MaxLevel)
    self:SetSectionInfo()
    self:SetTimer()
end

function XUiChapterPrefab:SetSectionInfo()
    local sectionDatas = XDataCenter.ArenaOnlineManager.GetSectionData()
    local index = 0
    for _, sectionData in ipairs(sectionDatas) do
        index = index + 1
        local name = "GridSection" .. index
        local go = XUiHelper.TryGetComponent(self.PanelSectionContent, name)
        if go then
            if not self.SectionGrids[sectionData.Id] then
                self.SectionGrids[sectionData.Id] = XUiGridSection.New(go, self.UiRoot)
            end

            self.SectionGrids[sectionData.Id]:Refresh(sectionData.Id)
        end
    end

    index = index + 1
    for i = index, MAX_SECTION_COUNT do
        local name = "GridSection" .. i
        local go = XUiHelper.TryGetComponent(self.PanelSectionContent, name)
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
end

function XUiChapterPrefab:SetTimer()
    local endTimeSecond = XDataCenter.ArenaOnlineManager.GetNextRefreshTime()
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CS.XTextManager.GetText("ArenaOnlineLeftTimeOver")
        self:StopTimer()
        if now <= endTimeSecond then
            self.TxtLeftTime.text = CS.XTextManager.GetText("ArenaOnlineChapterLeftTime", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT))
        else
            self.TxtLeftTime.text = activeOverStr
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
                now = XTime.GetServerNowTimestamp()
                if now > endTimeSecond then
                    self:StopTimer()
                    return
                end
                if now <= endTimeSecond then
                    self.TxtLeftTime.text = CS.XTextManager.GetText("ArenaOnlineChapterLeftTime", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT))
                else
                    self.TxtLeftTime.text = activeOverStr
                end
            end, XScheduleManager.SECOND, 0)
    end
end

function XUiChapterPrefab:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiChapterPrefab:OnDestroy()
    --XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.AreaChange, self)

    self:StopTimer()
    if not self.SectionGrids then return end

    for _, v in pairs(self.SectionGrids) do
        v:OnDestroy()
    end
end

function XUiChapterPrefab:PlayTipsAnimation()
    local begin = function()
        XLuaUiManager.SetMask(true)
        XDataCenter.ArenaOnlineManager.SetAreaChanged(false)
    end

    local finished = function()
        XLuaUiManager.SetMask(false)
        self.PanelTip.gameObject:SetActiveEx(false)
    end

    self.PanelTip.gameObject:SetActiveEx(true)
    self.TipEnable:PlayTimelineAnimation(finished, begin)
end

function XUiChapterPrefab:AreaChange()
    if not self.Show then
        return
    end
    self:PlayTipsAnimation()
end

return XUiChapterPrefab