local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4RewardCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4RewardCard")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
---@class XUiTheatre4PopupChooseReward : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupChooseReward = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupChooseReward")

function XUiTheatre4PopupChooseReward:OnAwake()
    self._Control:RegisterClickEvent(self, self.BtnMap, self.OnBtnMapClick)
    self:InitColour()
    self:InitDynamicTable()
    self.GridRewardCard.gameObject:SetActiveEx(false)
end

function XUiTheatre4PopupChooseReward:InitColour()
    ---@type XUiTheatre4ColorResource
    self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self)
    self.PanelColour:Open()
end

---@param id number 事务id 自增Id
function XUiTheatre4PopupChooseReward:OnStart(id)
    self.Id = id
end

function XUiTheatre4PopupChooseReward:OnEnable()
    self:RefreshNum()
    self:SetupDynamicTable()
    self:PlayAnimation("PopupEnable")
end

-- 刷新选择数量
function XUiTheatre4PopupChooseReward:RefreshNum()
    -- 剩余可选择数量
    local selectTimes = self._Control:GetTransactionSelectTimes(self.Id)
    local selectLimit = self._Control:GetTransactionSelectLimit(self.Id)
    self.TxtNum.text = string.format("%d/%d", selectTimes, selectLimit)
end

function XUiTheatre4PopupChooseReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListReward)
    self.DynamicTable:SetProxy(XUiGridTheatre4RewardCard, self, handler(self, self.OnSelectCallback), handler(self, self.OnYesCallback))
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4PopupChooseReward:SetupDynamicTable()
    self.DataList = self:GetRewardDataList()
    if XTool.IsTableEmpty(self.DataList) then
        return
    end
    self._IsRefreshing = true
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTheatre4RewardCard
function XUiTheatre4PopupChooseReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._IsRefreshing then
            grid:SetAlpha(0)
        end
        grid:Refresh(self.DataList[index])
        local isSelect = self.CurSelectIndex and self.CurSelectIndex == grid:GetIndex()
        grid:SetSelect(isSelect)
        grid:SetBtnYes(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayRewardAnimation()
        self._IsRefreshing = false
    end
end

-- 获取奖励数据列表
---@return { Id:number, Type:number, Count:number, Index:number }[]
function XUiTheatre4PopupChooseReward:GetRewardDataList()
    ---@type { Reward:XTheatre4Asset, Index:number }[]
    local rewardDataList = self._Control:GetTransactionRewardDataList(self.Id)
    if XTool.IsTableEmpty(rewardDataList) then
        return nil
    end
    local data = {}
    for _, rewardData in pairs(rewardDataList) do
        table.insert(data, {
            Id = rewardData.Reward:GetId(),
            Type = rewardData.Reward:GetType(),
            Count = rewardData.Reward:GetNum(),
            Index = rewardData.Index
        })
    end
    return data
end

---@param grid XUiGridTheatre4RewardCard
function XUiTheatre4PopupChooseReward:OnSelectCallback(grid)
    if self.CurSelectIndex == grid:GetIndex() then
        return
    end
    self.CurSelectIndex = grid:GetIndex()
    -- 刷新选择状态
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        v:SetSelect(v:GetIndex() == self.CurSelectIndex)
        v:SetBtnYes(v:GetIndex() == self.CurSelectIndex)
    end
end

-- 确认回调
function XUiTheatre4PopupChooseReward:OnYesCallback(index)
    -- 选择奖励
    self._Control:ConfirmDropRequest(self.Id, index, function()
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

function XUiTheatre4PopupChooseReward:PlayRewardAnimation()
    local grids = self.DynamicTable:GetGrids()
    local startIndex = self.DynamicTable:GetStartIndex()

    if not XTool.IsTableEmpty(grids) then
        XLuaUiManager.SetMask(true, self.Name)
        RunAsyn(function()
            for i = startIndex, table.nums(grids) + startIndex - 1 do
                local grid = grids[i]

                if grid then
                    grid:PlayRewardAnimation()
                    asynWaitSecond(0.04)
                end
            end
            XLuaUiManager.SetMask(false, self.Name)
        end)
    end
end

function XUiTheatre4PopupChooseReward:OnBtnMapClick()
    self._Control:ShowViewMapPanel(XEnumConst.Theatre4.ViewMapType.SelectReward)
end

function XUiTheatre4PopupChooseReward:GetPopupArgs()
    return { self.Id }
end

return XUiTheatre4PopupChooseReward
