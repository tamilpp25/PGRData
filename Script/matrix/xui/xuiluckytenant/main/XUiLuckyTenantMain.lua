local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiLuckyTenantMainStageGrid = require("XUi/XUiLuckyTenant/Main/XUiLuckyTenantMainStageGrid")

---@class XUiLuckyTenantMain : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantMain = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantMain")

function XUiLuckyTenantMain:Ctor()
    self._Items = {}
    ---@type XUiLuckyTenantMainStageGrid[]
    self._StageGrids = {}
    self._TimerAnimation = {}
end

function XUiLuckyTenantMain:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, self._Control:GetUiData().HelpKey)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnClickReward, nil, true)
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.Coin)
    --self.DynamicTable = XDynamicTableNormal.New(self.ListChapter)
    --self.DynamicTable:SetDelegate(self)
    --self.DynamicTable:SetProxy(XUiLuckyTenantMainStageGrid, self)
    self._Index = false
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiLuckyTenantMain:OnStart()
    --self.GridStage
    --self.BtnReward
    --self.Grid256New
    --self.PanelItem
    --self.CommonTaskRewardLeft
end

---@param grid XUiLuckyTenantMainStageGrid
--function XUiLuckyTenantMain:OnDynamicTableEvent(event, index, grid)
--    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--        grid:Update(self.DynamicTable:GetData(index))
--    end
--end

function XUiLuckyTenantMain:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_STAGE, self.Update, self)
    self:Update()
    self:UpdateTime()
    self:UpdateReward()
    self:UpdateTaskRedDot()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
    self:PlayAnimationGrids()
end

function XUiLuckyTenantMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT_UPDATE_STAGE, self.Update, self)
    XScheduleManager.UnSchedule(self._Timer)
end

function XUiLuckyTenantMain:Update()
    self._Control:UpdateStageList()
    local stages = self._Control:GetUiData().Stages
    self:UpdateDynamicItem(self._StageGrids, stages, self.GridStage, self.GridStage02, XUiLuckyTenantMainStageGrid, self)
    --self.DynamicTable:SetDataSource(stages)
    if not self._Index then
        local index = 1
        for i = 1, #stages do
            local stage = stages[i]
            if stage.IsCanChallenge then
                index = i
            end
            if stage.IsPlaying then
                index = i
                break
            end
        end
        self._Index = index
        --self.DynamicTable:ReloadDataSync(self._Index)
        if not self._ScrollTimer then
            self._ScrollTimer = XScheduleManager.ScheduleNextFrame(function()
                XUiHelper.ScrollTo(self.ListChapter, self._StageGrids[index].Transform)
                self._ScrollTimer = false
            end)
        end
        return
    end
    --self.DynamicTable:ReloadDataSync()
end

function XUiLuckyTenantMain:UpdateTime()
    local uiData = self._Control:GetUiData()
    local remainTime = uiData.RemainTime
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiLuckyTenantMain:OnClickReward()
    XLuaUiManager.Open("UiLuckyTenantTask")
end

function XUiLuckyTenantMain:UpdateReward()
    if XMVCA.XLuckyTenant:IsAllTaskFinish() then
        self.CommonTaskRewardRight.gameObject:SetActiveEx(false)
        return
    end
    local rewardList = self._Control:GetTaskReward4Show()
    XUiHelper.CreateTemplates(self, self._Items, rewardList, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    self.Grid256New.gameObject:SetActiveEx(false)
    --self._TimerReward = XScheduleManager.ScheduleOnce(function()
    --    self.Grid256New.transform.parent.gameObject:SetActiveEx(false)
    --end, 3 * XScheduleManager.SECOND)
end

function XUiLuckyTenantMain:UpdateTaskRedDot()
    self.BtnReward:ShowReddot(XMVCA.XLuckyTenant:IsShowRedDotTask())
end

---@param gridArray XUiNode[]
function XUiLuckyTenantMain:UpdateDynamicItem(gridArray, dataArray, uiObject1, uiObject2, class, parent)
    if #gridArray == 0 and uiObject1 then
        uiObject1.gameObject:SetActiveEx(false)
        uiObject2.gameObject:SetActiveEx(false)
    end
    local dataCount = dataArray and #dataArray or 0
    for i = 1, dataCount do
        local grid = gridArray[i]
        if not grid then
            local uiObject
            if dataArray[i].IsChallengeStage then
                uiObject = uiObject1
            else
                uiObject = uiObject2
            end
            local ui = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(ui, parent)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = dataCount + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiLuckyTenantMain:OnDestroy()
    if self._ScrollTimer then
        XScheduleManager.UnSchedule(self._ScrollTimer)
        self._ScrollTimer = false
    end
    self:StopAllAnimationGrids()
end

function XUiLuckyTenantMain:PlayAnimationGrids()
    self:StopAllAnimationGrids()
    local gap = 100 -- 单位:毫秒
    --local begin = math.max(1, self._Index - 5)
    local begin = 1
    for i = begin, #self._StageGrids do
        local uiGrid = self._StageGrids[i]
        local group = XUiHelper.TryGetComponent(uiGrid.Transform, "Group", "CanvasGroup")
        group.alpha = 0
        local timer = XScheduleManager.ScheduleOnce(function()
            local uiGrid = self._StageGrids[i]
            if uiGrid then
                uiGrid:PlayAnimation("GridStageEnable")
            end
            self._TimerAnimation[i] = nil
        end, gap * (i - begin))
        self._TimerAnimation[i] = timer
    end
end

function XUiLuckyTenantMain:StopAllAnimationGrids()
    for i, timer in pairs(self._TimerAnimation) do
        XScheduleManager.UnSchedule(timer)
        self._TimerAnimation[i] = nil
    end
end

return XUiLuckyTenantMain