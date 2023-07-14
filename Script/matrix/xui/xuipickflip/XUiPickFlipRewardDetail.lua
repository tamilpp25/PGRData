local XUiPickFlipRewardGrid = require("XUi/XUiPickFlip/XUiPickFlipRewardGrid")
local XUiPickFlipRewardDetail = XLuaUiManager.Register(XLuaUi, "UiPickFlipSelect")

function XUiPickFlipRewardDetail:OnAwake()
    self.PickFlipManager = XDataCenter.PickFlipManager
    -- XPickFlipConfigs.UiRewardDetailType
    self.UiType = nil
    -- XPFRewardLayer
    self.RewardLayer = nil
    -- 当前选择奖励id字典
    self.CurrentSelectRewardIdDic = {}
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewardScroll)
    self.DynamicTable:SetProxy(XUiPickFlipRewardGrid, self)
    self.DynamicTable:SetDelegate(self)
    self:RegisterUiEvents()
end

-- rewardLayer : XPFRewardLayer
-- uiType : XPickFlipConfigs.UiRewardDetailType
function XUiPickFlipRewardDetail:OnStart(rewardLayer, uiType)
    self.RewardLayer = rewardLayer
    self.UiType = uiType
    self:RefreshPanelInfo()
    self:RefreshRewardList()
    self.TxtTips.text = XUiHelper.GetText("PickFlipConfigRewardTip")
end  

--######################## 私有方法 ########################

function XUiPickFlipRewardDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnClose)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnClose)
end

function XUiPickFlipRewardDetail:OnClose()
    self:EmitSignal("Close")
    self:Close()
end

function XUiPickFlipRewardDetail:OnBtnConfirmClicked()
    local rewardIds = {}
    for id, v in pairs(self.CurrentSelectRewardIdDic) do
        table.insert(rewardIds, id)
    end
    if #rewardIds < self.RewardLayer:GetMaxSelectCount() then
        XUiManager.TipErrorWithKey("PickFlipMaxRewardCountTip2")
        return
    end
    RunAsyn(function()
        XLuaUiManager.Open("UiPickFlipDialog", self.RewardLayer, rewardIds)
        local code = XLuaUiManager.AwaitSignal("UiPickFlipDialog", "PickRewardFinished", self)
        if code ~= XSignalCode.SUCCESS then return end
        self:EmitSignal("Close")
        self:Remove()
    end)
end

function XUiPickFlipRewardDetail:RefreshPanelInfo()
    if self.UiType == XPickFlipConfigs.UiRewardDetailType.Config then
        self:RefreshConfigInfo()
    elseif self.UiType == XPickFlipConfigs.UiRewardDetailType.Check then
        self:RefreshCheckInfo()
    end
    local showButton = self.UiType == XPickFlipConfigs.UiRewardDetailType.Config
    self.BtnConfirm.gameObject:SetActiveEx(showButton)
    self.BtnCancel.gameObject:SetActiveEx(showButton)
end

function XUiPickFlipRewardDetail:RefreshRewardList()
    if self.UiType == XPickFlipConfigs.UiRewardDetailType.Config then
        self:RefreshConfigRewardList()
    elseif self.UiType == XPickFlipConfigs.UiRewardDetailType.Check then
        self:RefreshCheckRewardList()
    end
end

function XUiPickFlipRewardDetail:RefreshConfigInfo()
    self.TxtTitle.text = XUiHelper.GetText("PickFlipSelectRewardTip1")
    self.TxtNumberTitle.text = XUiHelper.GetText("PickFlipSelectRewardTip2")
    self:RefreshConfigRewardCount()
end

function XUiPickFlipRewardDetail:RefreshConfigRewardCount()
    self.TxtNumber.text = string.format("%s/%s", self:GetCurrentSelectCount()
    , self.RewardLayer:GetMaxSelectCount())
end

function XUiPickFlipRewardDetail:RefreshCheckInfo()
    self.TxtTitle.text = XUiHelper.GetText("PickFlipWatchRewardTip1")
    self.TxtNumberTitle.text = XUiHelper.GetText("PickFlipWatchRewardTip2")
    self.TxtNumber.text = string.format("%s/%s", self.RewardLayer:GetCurrentRewardCount()
    , self.RewardLayer:GetMaxRewardCount())
end

function XUiPickFlipRewardDetail:RefreshConfigRewardList()
    self.DynamicTable:SetDataSource(self.RewardLayer:GetAllSelectableRewards())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPickFlipRewardDetail:RefreshCheckRewardList()
    self.DynamicTable:SetDataSource(self.RewardLayer:GetConfigFinishedRewards())
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPickFlipRewardDetail:OnDynamicTableEvent(event, index, grid)
    local reward = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(reward)
        if self.UiType == XPickFlipConfigs.UiRewardDetailType.Check then
            grid:SetSelectStatus(reward:GetIsReceived())
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridClicked(grid, reward)
    end
end

function XUiPickFlipRewardDetail:OnGridClicked(grid, reward)
    if self.UiType == XPickFlipConfigs.UiRewardDetailType.Config then
        -- 检查是否已满足最大配置
        if self:GetCurrentSelectCount() >= self.RewardLayer:GetMaxSelectCount() then
            local nextStatus = not self.CurrentSelectRewardIdDic[reward:GetId()]
            if nextStatus then
                XUiManager.TipErrorWithKey("PickFlipMaxRewardCountTip1")
                return 
            end
        end
        self:UpdateRewardSelectStatus(reward)
        grid:SetSelectStatus(self:CheckRewardIsSelected(reward))
        self:RefreshConfigRewardCount()
    elseif self.UiType == XPickFlipConfigs.UiRewardDetailType.Check then
        grid:ShowDetailUi()
    end
end

function XUiPickFlipRewardDetail:CheckRewardIsSelected(reward)
    return self.CurrentSelectRewardIdDic[reward:GetId()] == true
end

function XUiPickFlipRewardDetail:UpdateRewardSelectStatus(reward)
    local rewardId = reward:GetId()
    local lastStatus = self.CurrentSelectRewardIdDic[rewardId]
    if lastStatus == true then
        self.CurrentSelectRewardIdDic[rewardId] = nil
    else
        self.CurrentSelectRewardIdDic[rewardId] = true
    end
end

function XUiPickFlipRewardDetail:GetCurrentSelectCount()
    local result = 0
    for k, v in pairs(self.CurrentSelectRewardIdDic) do
        if v == true then
            result = result + 1 
        end
    end
    return result
end

return XUiPickFlipRewardDetail
