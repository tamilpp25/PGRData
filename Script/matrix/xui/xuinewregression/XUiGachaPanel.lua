--######################## XUiGachaGrid ########################
local XUiGachaGrid = XClass(nil, "XUiGachaGrid")

function XUiGachaGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- XGachaManager
    self.GachaManager = nil
end

-- gachaGroup : XGachaGroup
function XUiGachaGrid:SetData(gachaGroup)
    self.GachaManager = XDataCenter.NewRegressionManager.GetGachaManager(gachaGroup:GetGachaId())
    local isOpen = self.GachaManager:CheckGachaGroupIsOpen(gachaGroup:GetId())
    local isDone = gachaGroup:GetIsDone()
    self.Normal.gameObject:SetActiveEx(isOpen and not isDone)
    self.Disable.gameObject:SetActiveEx(not isOpen or isDone)
    self.RImgLock.gameObject:SetActiveEx(not isOpen)
    self.PanelLockTip.gameObject:SetActiveEx(not isOpen)
    self.TxtStoreTip.gameObject:SetActiveEx(isDone)
end

--######################## XUiGachaPanel ########################
local XUiGachaPanel = XClass(XSignalData, "XUiGachaPanel")

function XUiGachaPanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    -- XGachaManager
    self.GachaManager = nil
    -- 奖池组动态列表
    -- XDynamicTableCurve的下标是从0开始
    self.DynamicTable = XDynamicTableCurve.New(self.PanelGachaList)
    self.DynamicTable:SetProxy(XUiGachaGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridGacha.gameObject:SetActiveEx(false)
    self.CurrentGachaIndex = 0
    self.RewardGrids = {}
    self.MaxGachaCount = 10
    self:RegisterUiEvents()
end

-- manager : XGachaManager
function XUiGachaPanel:SetData(manager)
    self.GachaManager = manager
    self.CurrentGachaIndex = manager:GetCurrentGachaGroupIndex() - 1
    -- 刷新奖池组
    self:RefreshGachaList()
    self:RefreshGachaData()
    self:RefreshSwitchBtns()
end

--######################## 私有方法 ########################

function XUiGachaPanel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnMore, self.OnBtnMoreClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitchLast, self.OnBtnSwitchLastClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitchNext, self.OnBtnSwitchNextClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnDrawOne, self.OnBtnDrawOneClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnDrawTen, self.OnBtnDrawTenClicked)
end

function XUiGachaPanel:OnBtnMoreClicked()
    XLuaUiManager.Open("UiGachaPanelPreview2", self:GetCurrentGachaGroup():GetRewardPreviewViewModel())
end

function XUiGachaPanel:OnBtnSwitchLastClicked()
    self.DynamicTable:TweenToIndex(math.max(self.CurrentGachaIndex - 1, 0))
end

function XUiGachaPanel:OnBtnSwitchNextClicked()
    self.DynamicTable:TweenToIndex(math.min(self.CurrentGachaIndex + 1, #self.DynamicTable.DataSource))
end

function XUiGachaPanel:OnBtnDrawOneClicked()
    self.GachaManager:RequestGetReward(self:GetCurrentGachaGroup():GetId(), 1, function()
        self:RefreshGachaList()
        self:RefreshGachaData()
        self:EmitSignal("RefreshRedPoint")
    end)
end

function XUiGachaPanel:OnBtnDrawTenClicked()
    self.GachaManager:RequestGetReward(self:GetCurrentGachaGroup():GetId(), self.MaxGachaCount, function()
        self:RefreshGachaList()
        self:RefreshGachaData()
        self:EmitSignal("RefreshRedPoint")
    end)
end

function XUiGachaPanel:GetCurrentGachaGroup()
    return self.DynamicTable.DataSource[self.CurrentGachaIndex + 1]
end

function XUiGachaPanel:RefreshGachaList()
    self.DynamicTable:SetDataSource(self.GachaManager:GetGachaGroups())
    self.DynamicTable:ReloadData(self.CurrentGachaIndex)
end

function XUiGachaPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index + 1])
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if self.DynamicTable:GetTweenIndex() == self.CurrentGachaIndex then
            return
        end
        self.CurrentGachaIndex = self.DynamicTable:GetTweenIndex()
        self:RefreshGachaData(self.CurrentGachaIndex + 1)
        if self.AnimRefresh then self.AnimRefresh:Play() end
        self:RefreshSwitchBtns()
    end
end

function XUiGachaPanel:RefreshSwitchBtns()
    local totalCount = #self.DynamicTable.DataSource
    self.BtnSwitchLast.gameObject:SetActiveEx(self.CurrentGachaIndex > 0 and totalCount > 1)
    self.BtnSwitchNext.gameObject:SetActiveEx(self.CurrentGachaIndex + 1 < totalCount and totalCount > 1)
end

-- index : 从1开始
function XUiGachaPanel:RefreshGachaData(index)
    if index == nil then index = self.CurrentGachaIndex + 1 end
    local currentGroup = self.DynamicTable.DataSource[index]
    self.TxtGachaCount.text = string.format( "%s/%s"
        , currentGroup:GetRewardRemainingCount()
        , currentGroup:GetRewardTotalCount())
    self.TxtGachaNumber.text = string.format( "0%s", index)
    -- 隐藏之前的
    for i = 0, self.PreviewContent.childCount - 1 do
        self.PreviewContent:GetChild(i).gameObject:SetActiveEx(false)
    end
    -- 创建或赋值
    local go, grid, gachaReward
    local coreRewards = currentGroup:GetCoreRewards()
    -- 最大显示4个
    for i = 1, 4 do
        gachaReward = coreRewards[i]
        if gachaReward == nil then break end
        if i > self.PreviewContent.childCount then
            -- 创建新的
            go = XUiHelper.Instantiate(self.PreviewGrid, self.PreviewContent)
            grid = XUiGridCommon.New(self.RootUi, go)
        else
            go = self.PreviewContent:GetChild(i - 1).gameObject
            grid = self.RewardGrids[i] or XUiGridCommon.New(self.RootUi, go)
        end
        go.gameObject:SetActiveEx(true)
        self.RewardGrids[i] = grid
        grid:Refresh({
            TemplateId = gachaReward:GetTemplateId(),
            Count = gachaReward:GetCount()
        }, nil, nil, nil, gachaReward:GetUsableTimes() - currentGroup:GetRewardUsedTimes(gachaReward:GetId()))
    end
    -- 刷新消耗信息
    local remainingCount = currentGroup:GetRewardRemainingCount()
    self.MaxGachaCount = math.min(remainingCount, 10)
    if self.MaxGachaCount <= 0 then self.MaxGachaCount = 10 end
    local consumeIcon = self.GachaManager:GetConsumeIcon()
    local consumeCount = self.GachaManager:GetConsumeCount()
    self.RImgDrawOneIcon:SetRawImage(consumeIcon)
    self.RImgDrawTenIcon:SetRawImage(consumeIcon)
    self.TxtDrawOneCount.text = consumeCount
    self.TxtDrawTenCount.text = consumeCount * self.MaxGachaCount
    self.TxtDrawOne.text = XUiHelper.GetText("DrawCount", 1)
    self.TxtDrawTen.text = XUiHelper.GetText("DrawCount", self.MaxGachaCount)
    -- 刷新抽奖按钮状态
    self.BtnDrawOne:SetDisable(remainingCount <= 0)
    self.BtnDrawTen:SetDisable(remainingCount <= 0)
end

return XUiGachaPanel