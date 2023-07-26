local XUiTransfiniteRewardGridScore = require("XUi/XUiTransfinite/RewardList/XUiTransfiniteRewardGridScore")

---@class XUiTransfinitePointsReward
local XUiTransfinitePointsReward = XClass(nil, "UiTransfiniteGift")

function XUiTransfinitePointsReward:Ctor(ui, viewModel)
    XTool.InitUiObjectByUi(self, ui)

    ---@type XViewModelTransfiniteGift
    self._ViewModel = viewModel

    ---@type XDynamicTableNormal
    self._DynamicTable = nil
end

function XUiTransfinitePointsReward:OnAwake()
    self._DynamicTable = XDynamicTableNormal.New(self.PointsRewardList)
    self._DynamicTable:SetProxy(XUiTransfiniteRewardGridScore)
    self._DynamicTable:SetDelegate(self)
    self.PointsRewardPanel.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnGetPoints, self.OnClickGetPoints)
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnClickReceiveAllRewards)
end

function XUiTransfinitePointsReward:OnEnable()
    self:UpdateTitle()
end

function XUiTransfinitePointsReward:UpdateTitle()
    self._ViewModel:UpdateScoreTitle()
    local data = self._ViewModel:GetDataScoreTitle()
    self.TxtSeniorLvTitle.text = data.RegionTitle
    self.TxtSeniorLv.text = data.RegionLvText
    self.ImgSenior:SetRawImage(data.RegionIconLv)
    self.TxtPointNum.text = data.TxtProgress
    self.ImgProgress.fillAmount = data.Progress
end

---@param grid XUiTransfiniteRewardGridScore
function XUiTransfinitePointsReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        grid:SetData(data)
        grid:Update()
    end
end

function XUiTransfinitePointsReward:SetActive(value)
    self.GameObject:SetActiveEx(value)
end

function XUiTransfinitePointsReward:Update()
    self._ViewModel:UpdateScore()
    local data = self._ViewModel:GetDataScoreReward()
    self._DynamicTable:SetDataSource(data.DataSource)
    self._DynamicTable:ReloadDataASync(data.StartIndex)
end

function XUiTransfinitePointsReward:OnClickGetPoints()
    self._ViewModel:OnClickOpenRoom()
end

function XUiTransfinitePointsReward:OnClickReceiveAllRewards()
    self._ViewModel:OnClickReceiveAllScoreReward()
end

return XUiTransfinitePointsReward