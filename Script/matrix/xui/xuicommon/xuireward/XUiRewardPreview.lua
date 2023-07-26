local XUiRewardPreview = XLuaUiManager.Register(XLuaUi, "UiGachaPanelPreview2")

function XUiRewardPreview:OnAwake()
    -- 重定义名字 begin
    self.PanelSpecialContainer = self.PanelDrawItemSP
    self.PanelNormalContainer = self.PanelDrawItemNA
    self.BtnClose = self.BtnPreviewConfirm
    self.BtnOutClose = self.BtnPreviewClose
    self.RewardGridPrefab = self.GridDrawActivity
    self.TxtRewardCountInto = self.TxetFuwenben
    self.PanelRewardCountInfo = self.PanelTxt
    -- 重定义名字 end
    -- XRewardPreviewViewModel
    self.RewardPreviewViewModel = nil
    self:RegisterUiEvents()
end

-- viewModel : XRewardPreviewViewModel
function XUiRewardPreview:OnStart(viewModel)
    self.RewardPreviewViewModel = viewModel
    -- 设置标题
    local showTitle = viewModel:GetTitle()
    if showTitle then self.TxtTitle.text = showTitle end
    if viewModel:GetSpecialTitle() then
        self.TxtSpecialTitle.text = viewModel:GetSpecialTitle()
    end
    if viewModel:GetNormalTitle() then
        self.TxtNormalTitle.text = viewModel:GetNormalTitle()
    end
    -- 设置获得数量信息
    local currentCount = viewModel:GetCurrentCount()
    local maxCount = viewModel:GetMaxCount()    
    self.TxtRewardCountInto.text = string.format( "<size=40><color=#0f70bc>%s</color></size>/%s"
        , currentCount, maxCount)
    self.PanelRewardCountInfo.gameObject:SetActiveEx(maxCount > 0)
    -- 设置特殊奖励
    self.RewardGridPrefab.gameObject:SetActiveEx(false)
    local specialRewards = viewModel:GetSpecialRewards()
    self.PanelSpecialTitle.gameObject:SetActiveEx(#specialRewards > 0)
    self.PanelSpecialContainer.gameObject:SetActiveEx(#specialRewards > 0)
    local go, grid
    for _, reward in ipairs(specialRewards) do
        go = XUiHelper.Instantiate(self.RewardGridPrefab, self.PanelSpecialContainer)
        grid = XUiGridCommon.New(self, go)
        grid:Refresh(reward, nil, nil, nil, reward.StockCount)
    end
    -- 设置普通奖励
    local normalRewards = viewModel:GetNormalRewards()
    self.PanelNormalTitle.gameObject:SetActiveEx(#normalRewards > 0)
    self.PanelNormalContainer.gameObject:SetActiveEx(#normalRewards > 0)
    for _, reward in ipairs(normalRewards) do
        go = XUiHelper.Instantiate(self.RewardGridPrefab, self.PanelNormalContainer)
        grid = XUiGridCommon.New(self, go)
        grid:Refresh(reward, nil, nil, nil, reward.StockCount)
    end
    -- 设置显示优先级
    if viewModel:GetIsFirstShowSpecial() then
        self.PanelSpecialContainer.transform:SetAsFirstSibling()
        self.ImgSpecialBg.transform:SetAsFirstSibling()
    else
        self.PanelNormalContainer.transform:SetAsFirstSibling()
        self.ImgNormalBg.transform:SetAsFirstSibling()
    end
end

--######################## 私有方法 ########################

function XUiRewardPreview:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnOutClose, self.Close)
end

return XUiRewardPreview
