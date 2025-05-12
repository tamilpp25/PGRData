local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTemple2MainGrid = require("XUi/XUiTemple2/System/Main/XUiTemple2MainGrid")
local XRedPointConditionTemple2 = require("XRedPoint/XRedPointConditions/XRedPointConditionTemple2")

---@class XUiTemple2Main : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Main = XLuaUiManager.Register(XLuaUi, "UiTemple2Main")

function XUiTemple2Main:Ctor()
    ---@type XUiTemple2MainGrid[]
    self._Chapters = {}
    self._Items = {}
end

function XUiTemple2Main:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(nil, "Temple2Help")
    --self.Grid256New
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:RegisterClickEvent(self.BtnStory, self.OnClickStory)
    self:RegisterClickEvent(self.BtnShop, self.OnClickShop)
    self.BtnStory:ShowReddot(false)
    self.BtnShop:ShowReddot(false)
    self._Timer = false

    if self.GridChapter1 then
        self._Chapters[1] = XUiTemple2MainGrid.New(self.GridChapter1, self)
    end
    if self.GridChapter2 then
        self._Chapters[2] = XUiTemple2MainGrid.New(self.GridChapter2, self)
    end

    if self.PanelAsset then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.Temple2)
    end
end

function XUiTemple2Main:OnStart()
    self:UpdateReward()
end

function XUiTemple2Main:OnEnable()
    self:Update()
    self:UpdateTime()
    self.BtnTask:ShowReddot(XRedPointConditionTemple2.CheckTask())
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiTemple2Main:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiTemple2Main:Update()
    self._Control:GetSystemControl():UpdateChapter()
    local chapters = self._Control:GetSystemControl():GetDataChapter()

    for i = 1, #chapters do
        local grid = self._Chapters[i]
        if not grid then
            local parent = self["Chapter" .. i]
            if parent then
                local prefab = XUiHelper.Instantiate(self.GridChapter, parent)
                grid = XUiTemple2MainGrid.New(prefab, self)
                self._Chapters[i] = grid
            else
                XLog.Error("[XUiTemple2Main] 配置的数量大于，章节的ui节点数量了，通知ui加一下")
            end
        end
        if grid then
            grid:Update(chapters[i])
        end
    end
    --self.GridChapter.gameObject:SetActiveEx(false)
end

function XUiTemple2Main:OnClickTask()
    XLuaUiManager.Open("UiTemple2Task")
end

function XUiTemple2Main:OnClickStory()
    XLuaUiManager.Open("UiTemple2Story")
end

function XUiTemple2Main:OnClickShop()
    self._Control:OpenShop()
end

function XUiTemple2Main:UpdateTime()
    local time = self._Control:GetSystemControl():GetRemainTime()
    self.TxtTime.text = time

    local chapters = self._Control:GetSystemControl():GetDataChapter()
    local isLock = false
    for i = 1, #chapters do
        local chapter = chapters[i]
        if not chapter.IsUnlock then
            isLock = true
            break
        end
    end
    if isLock then
        self:Update()
    end
end

function XUiTemple2Main:UpdateReward()
    local rewardList = self._Control:GetTaskReward4Show()
    XUiHelper.CreateTemplates(self, self._Items, rewardList, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    self.Grid256New.gameObject:SetActiveEx(false)
    --self._TimerReward = XScheduleManager.ScheduleOnce(function()
    --    self.Grid256New.transform.parent.gameObject:SetActiveEx(false)
    --end, 3 * XScheduleManager.SECOND)
end

return XUiTemple2Main