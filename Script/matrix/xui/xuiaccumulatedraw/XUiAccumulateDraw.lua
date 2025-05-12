local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiAccumulateDrawGrid = require("XUi/XUiAccumulateDraw/XUiAccumulateDrawGrid")
local XUiAccumulateDrawRewardGrid = require("XUi/XUiAccumulateDraw/XUiAccumulateDrawRewardGrid")

---@class XUiAccumulateDraw : XLuaUi
---@field PanelActivityAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TxtTime UnityEngine.UI.Text
---@field RImgItem UnityEngine.UI.RawImage
---@field TxtNum UnityEngine.UI.Text
---@field GridCourse UnityEngine.RectTransform
---@field PanelBottom UnityEngine.RectTransform
---@field SViewCourse UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field PanelBgSpecial UnityEngine.RectTransform
---@field PanelBgSpecialReceive UnityEngine.RectTransform
---@field PanelBgSpecialFinish UnityEngine.RectTransform
---@field _Control XAccumulateExpendControl
local XUiAccumulateDraw = XLuaUiManager.Register(XLuaUi, "UiAccumulateDraw")

local SpecialRewardState = {
    None = -1,
    Normal = 1,
    Receive = 2,
    Finish = 3,
}

function XUiAccumulateDraw:Ctor()
    self._Timer = nil
    self._SpecialTimer = nil
    self._DynamicTable = nil
    ---@type XUiAccumulateDrawRewardGrid[]
    self._SpecialRewardList = nil
    self._CurrentGridEndIndex = nil
    self._AtLastSpecialRewardIndex = nil
    self._CurrentSpecialReward = nil
    self._CurrentSpecialState = SpecialRewardState.None
    self._IsCloseSpecial = false
end

-- region 生命周期
function XUiAccumulateDraw:OnAwake()
    self._SpecialRewardList = {
        [SpecialRewardState.Normal] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecial, self, self),
        [SpecialRewardState.Receive] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecialReceive, self, self),
        [SpecialRewardState.Finish] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecialFinish, self, self),
    }
    
    self:_InitUi()
    self:_InitSpecialTool()
    self:_RegisterButtonClicks()
end

function XUiAccumulateDraw:OnStart()
    local endTime = self._Control:GetEndTime()

    self._DynamicTable = XDynamicTableNormal.New(self.SViewCourse)
    self._DynamicTable:SetProxy(XUiAccumulateDrawGrid, self)
    self._DynamicTable:SetDelegate(self)
    self._AtLastSpecialRewardIndex = self._Control:GetAtLastSpecialRewardIndex()

    self:SetAutoCloseInfo(endTime, Handler(self._Control, self._Control.AutoCloseHandler))
end

function XUiAccumulateDraw:OnEnable()
    self:_SetTime()
    self:_RefreshDynamicTable(true)
    self:_RefreshProgress()
    self:_RefreshSpecialReward()
    self:_RegisterSchedules()
    self:_RegisterListeners()
end

function XUiAccumulateDraw:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

-- endregion

-- region 按钮事件

function XUiAccumulateDraw:OnBtnHelpClick()
    XLuaUiManager.Open("UiAccumulateDrawLog")
end

function XUiAccumulateDraw:OnSpecialPanelClick()
    if self._CurrentGridEndIndex then
        local reward = self._Control:GetNextSpecialReward(self._CurrentGridEndIndex - 1)

        if reward:IsAchieved() then
            self._Control:ReceiveAllReward()
        end
    end
end

---@param grid XUiAccumulateDrawGrid
function XUiAccumulateDraw:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardCount = self._Control:GetRewardCount()
        local isEnd = index == rewardCount
        local isBegin = index == 1
        local endIndex = self._DynamicTable:GetEndIndex()
        local reward = self._DynamicTable:GetData(index)
        local nextReward = nil
        local preReward = nil
        
        if not isEnd then
            nextReward = self._DynamicTable:GetData(index + 1)
        end
        if not isBegin then
            preReward = self._DynamicTable:GetData(index - 1)
        end
        
        grid:Refresh(reward, preReward, nextReward)
        if self._CurrentGridEndIndex ~= endIndex then
            self._CurrentGridEndIndex = endIndex
            self:_RefreshSpecialReward(endIndex - 1)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        ---@type XAccumulateExpendReward
        local reward = self._DynamicTable:GetData(index)

        if reward:IsAchieved() then
            self._Control:ReceiveAllReward()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local index = self._Control:GetCurrentRewardIndex()
        local _, count = self._DynamicTable:GetFirstUseGridIndexAndUseCount()
        local totalCount = self._Control:GetRewardCount()

        if totalCount - index < count then
            index = totalCount - count + 1
        end

        self._DynamicTable:ScrollToIndex(index, 1)
    end
end

function XUiAccumulateDraw:OnTaskFinishRefresh()
    self:_RefreshDynamicTable(true)
    self:_RefreshProgress()

    if self._CurrentGridEndIndex then
        self:_RefreshSpecialReward(self._CurrentGridEndIndex - 1)
    end
end 

function XUiAccumulateDraw:OnRefreshSpecialReward()
    if self._AtLastSpecialRewardIndex > self._DynamicTable:GetEndIndex() then
        return
    end

    if not XMVCA.XAccumulateExpend:CheckIsOpen() then
        self:_RemoveSpecialRewardTimer()
        return
    end

    local grid = self._DynamicTable:GetGridByIndex(self._AtLastSpecialRewardIndex)

    if grid then
        if grid.GameObject.transform.position.y > self.PanelBottom.transform.position.y then
            self:_CloseAllSpecialReward()
        else
            self:_OpenAllSpecialReward()
        end
    end
end

-- endregion

-- region 私有方法

function XUiAccumulateDraw:_RegisterButtonClicks()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick, true)
    self:RegisterClickEvent(self.PanelBottom, self.OnSpecialPanelClick, true)
end

function XUiAccumulateDraw:_RegisterSchedules()
    self:_RegisterActivityTimer()
    self:_RegisterSpecialRewardTimer()
end

function XUiAccumulateDraw:_RemoveSchedules()
    self:_RemoveActivityTimer()
    self:_RemoveSpecialRewardTimer()
end

function XUiAccumulateDraw:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinishRefresh, self)
end

function XUiAccumulateDraw:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinishRefresh, self)
end

function XUiAccumulateDraw:_RegisterActivityTimer()
    if self._Timer then
        self:_RemoveActivityTimer()
    end

    self._Timer = XScheduleManager.ScheduleForever(Handler(self, self._SetTime), XScheduleManager.SECOND)
end

function XUiAccumulateDraw:_RemoveActivityTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiAccumulateDraw:_RegisterSpecialRewardTimer()
    if self._SpecialTimer then
        self:_RemoveSpecialRewardTimer()
    end

    self._SpecialTimer = XScheduleManager.ScheduleForever(Handler(self, self.OnRefreshSpecialReward), 1)
end

function XUiAccumulateDraw:_RemoveSpecialRewardTimer()
    if self._SpecialTimer then
        XScheduleManager.UnSchedule(self._SpecialTimer)
        self._SpecialTimer = nil
    end
end

function XUiAccumulateDraw:_SetTime()
    self.TxtTime.text = self._Control:GetEndTimeStr()
end

function XUiAccumulateDraw:_RefreshDynamicTable(isRefresh)
    local rewardList = self._Control:GetRewardList(isRefresh)

    self._DynamicTable:SetDataSource(rewardList)
    self._DynamicTable:ReloadDataASync()
end

function XUiAccumulateDraw:_RefreshProgress()
    self.TxtNum.text = self._Control:GetCurrentRewardCount()
    self.RImgItem:SetRawImage(self._Control:GetItemIcon())
end

function XUiAccumulateDraw:_InitSpecialTool()
    local itemIds = { self._Control:GetItemId() }

    XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelActivityAsset, self)
end

function XUiAccumulateDraw:_RefreshSpecialReward(index)
    local reward = self._Control:GetNextSpecialReward(index)

    if not reward then
        self:_CloseSpecialReward()
    else
        self.PanelBottom.gameObject:SetActiveEx(true)
        if reward:IsAchieved() then
            self:_ChangeSpecialRewardState(SpecialRewardState.Receive, reward)
        elseif reward:IsFinish() then
            self:_ChangeSpecialRewardState(SpecialRewardState.Finish, reward)
        else
            self:_ChangeSpecialRewardState(SpecialRewardState.Normal, reward)
        end
    end
end

function XUiAccumulateDraw:_CloseSpecialReward()
    self:_ChangeSpecialRewardState(SpecialRewardState.None)
    self.PanelBottom.gameObject:SetActiveEx(false)
end

function XUiAccumulateDraw:_CloseAllSpecialReward()
    self._IsCloseSpecial = true
    for i, specialReward in pairs(self._SpecialRewardList) do
        specialReward:Close()
    end
    self.PanelBottom.gameObject:SetActiveEx(false)
end

function XUiAccumulateDraw:_OpenAllSpecialReward()
    self._IsCloseSpecial = false
    self.PanelBottom.gameObject:SetActiveEx(true)
    for i, specialReward in pairs(self._SpecialRewardList) do
        if i == self._CurrentSpecialState and self._CurrentSpecialReward then
            specialReward:Open()
            specialReward:Refresh(self._CurrentSpecialReward)
        else
            specialReward:Close()
        end
    end
end

---@param grid XUiAccumulateDrawGrid
function XUiAccumulateDraw:_ChangeSpecialRewardState(state, reward)
    self._CurrentSpecialState = state
    self._CurrentSpecialReward = reward
    for i, specialReward in pairs(self._SpecialRewardList) do
        if i == state and reward then
            if not self._IsCloseSpecial then
                specialReward:Open()
                specialReward:Refresh(reward)
            end
        else
            specialReward:Close()
        end
    end
end

function XUiAccumulateDraw:_InitUi()
    self.GridCourse.gameObject:SetActiveEx(false)
end

-- endregion

return XUiAccumulateDraw
