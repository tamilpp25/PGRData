--关卡详情界面
local XUiAreaWarStageDetail = XLuaUiManager.Register(XLuaUi, "UiAreaWarStageDetail")

function XUiAreaWarStageDetail:OnAwake()
    local closeFunc = handler(self, self.OnClickBtnClose)
    for i = 1, 4 do
        self["BtnCloseMask" .. i].CallBack = closeFunc
    end
    self.BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
    self.BtnDispatch.CallBack = function()
        self:OnClickBtnDispatch()
    end
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiAreaWarStageDetail:OnStart(blockId, closeCb)
    self.BlockId = blockId
    self.CloseCb = closeCb
    self.RewardGrids = {}

    self:InitView()
end

function XUiAreaWarStageDetail:OnEnable()
    self:UpdateView()
    self:UpdateAssets()
end

function XUiAreaWarStageDetail:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE
    }
end

function XUiAreaWarStageDetail:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateView()
    end
end

function XUiAreaWarStageDetail:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarStageDetail:InitView()
    local blockId = self.BlockId

    --背景图片
    self.RImgIcon:SetRawImage(XAreaWarConfigs.GetBlockShowTypeStageBgByBlockId(blockId))

    local rewardItemId = XDataCenter.AreaWarManager.GetCoinItemId()
    --派遣奖励（固定只显示货币图标，读不到真实奖励数量）
    self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self, self.Grid128)
    self.RewardGrid:Refresh(rewardItemId)
    --作战奖励（固定只显示货币图标，读不到真实奖励数量）
    self.FightRewardGrid = self.FightRewardGrid or XUiGridCommon.New(self, self.Grid128Fight)
    self.FightRewardGrid:Refresh(rewardItemId)

    --作战消耗
    local icon = XDataCenter.AreaWarManager.GetActionPointItemIcon()
    self.RImgCost:SetRawImage(icon)
    self.RImgCostFight:SetRawImage(icon)
    --派遣消耗
    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    self.BtnDispatch:SetNameByGroup(0, costCount)
    --战斗消耗
    local costCount = XAreaWarConfigs.GetBlockActionPoint(blockId)
    self.BtnFight:SetNameByGroup(0, costCount)

    --全服奖励展示
    local block = XDataCenter.AreaWarManager.GetBlock(blockId)
    local rewards = block:GetRewardItems()
    for index, item in ipairs(rewards) do
        local grid = self.RewardGrids[index]
        if not grid then
            local go = index == 1 and self.GridCommon or CSObjectInstantiate(self.GridCommon, self.RewardParent)
            grid = XUiGridCommon.New(self, go)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(item)
        --奖励已发放
        local isFinished = XDataCenter.AreaWarManager.IsBlockClear(blockId)
        grid:SetReceived(isFinished)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[index].GameObject:SetActiveEx(false)
    end

    self.TxtName.text = XAreaWarConfigs.GetBlockName(blockId)
    self.TxtNumber.text = XAreaWarConfigs.GetBlockNameEn(blockId)
end

function XUiAreaWarStageDetail:UpdateView()
    local blockId = self.BlockId

    local isFighting = XDataCenter.AreaWarManager.IsBlockFighting(blockId)
    self.BtnFight:SetDisable(not isFighting, isFighting)
    self.BtnDispatch:SetDisable(not isFighting, isFighting)
end

function XUiAreaWarStageDetail:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb(self.BlockId)
    end
end

function XUiAreaWarStageDetail:OnClickBtnFight()
    XDataCenter.AreaWarManager.TryEnterFight(self.BlockId)
end

function XUiAreaWarStageDetail:OnClickBtnDispatch()
    XDataCenter.AreaWarManager.OpenUiDispatch(self.BlockId)
end
