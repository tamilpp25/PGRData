local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4RewardCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4RewardCard")
---@class XUiTheatre4ReceiveReward : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4ReceiveReward = XLuaUiManager.Register(XLuaUi, "UiTheatre4ReceiveReward")

function XUiTheatre4ReceiveReward:OnAwake()
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self.GridRewardCard.gameObject:SetActiveEx(false)
    self.TxtAddNum.gameObject:SetActiveEx(false)
end

---@field id number 事务id 自增Id
function XUiTheatre4ReceiveReward:OnStart(id)
    self.Id = id
end

function XUiTheatre4ReceiveReward:OnEnable()
    self:RefreshGold()
    self:SetupDynamicTable()
    self:PlayAnimation("PopupEnable")
end

function XUiTheatre4ReceiveReward:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
    }
end

function XUiTheatre4ReceiveReward:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshGold()
    end
end

-- 刷新金币
function XUiTheatre4ReceiveReward:RefreshGold()
    -- 金币图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if icon then
        self.RImgGold:SetRawImage(icon)
    end
    -- 金币数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

function XUiTheatre4ReceiveReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XUiGridTheatre4RewardCard, self, nil, handler(self, self.OnYesCallback))
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4ReceiveReward:SetupDynamicTable()
    self.DataList = self:GetRewardDataList()
    if XTool.IsTableEmpty(self.DataList) then
        return
    end
    self._IsRefreshing = true
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTheatre4RewardCard
function XUiTheatre4ReceiveReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._IsRefreshing then
            grid:SetAlpha(0)
        end
        grid:SetBtnYes(true)
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayRewardAnimation()
        self._IsRefreshing = false
    end
end

-- 获取奖励数据列表
---@return { Id:number, Type:number, Count:number, Index:number }[]
function XUiTheatre4ReceiveReward:GetRewardDataList()
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

-- 确认回调
function XUiTheatre4ReceiveReward:OnYesCallback(index)
    -- 领取奖励
    self._Control:ConfirmFightRewardRequest(self.Id, index, function()
        self:CheckRewardPopup()
    end)
end

-- 检查是否有奖励弹框
---@param isGiveUp boolean 是否放弃奖励
function XUiTheatre4ReceiveReward:CheckRewardPopup(isGiveUp)
    local isRewardEmpty = isGiveUp or self._Control:CheckTransactionRewardEmpty(self.Id)
    if not isRewardEmpty then
        self:SetupDynamicTable()
    end
    self._Control:CheckNeedOpenNextPopup(self.Name, isRewardEmpty)
end

function XUiTheatre4ReceiveReward:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBag, self.OnBtnBagClick)
    self._Control:RegisterClickEvent(self, self.BtnAbandon, self.OnBtnAbandonClick)
end

-- 打开金币详情
function XUiTheatre4ReceiveReward:OnBtnGoldClick()
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

-- 打开背包
function XUiTheatre4ReceiveReward:OnBtnBagClick()
    XLuaUiManager.Open("UiTheatre4Bag")
end

-- 放弃奖励
function XUiTheatre4ReceiveReward:OnBtnAbandonClick()
    self._Control:QuitFightRewardRequest(self.Id, function()
        self:CheckRewardPopup(true)
    end)
end

function XUiTheatre4ReceiveReward:PlayRewardAnimation()
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

function XUiTheatre4ReceiveReward:GetPopupArgs()
    return { self.Id }
end

return XUiTheatre4ReceiveReward
