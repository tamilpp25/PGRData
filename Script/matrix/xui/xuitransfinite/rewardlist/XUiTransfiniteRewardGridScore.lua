local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local RewardState = XTransfiniteConfigs.RewardState

---@class XUiTransfiniteRewardGridScore
local XUiTransfiniteRewardGridScore = XClass(nil, "XUiTransfiniteRewardGridScore")

function XUiTransfiniteRewardGridScore:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)

    ---@type XViewModelTransfiniteGift
    self._ViewModel = nil

    ---@type XTransfiniteGridRewardSource
    self._Data = nil

    ---@class XUiTransfiniteRewardGridScoreUiGroup
    local uiGroupNormal = {
        ---@type XUiGridCommon
        GridCommon = XUiGridCommon.New(nil, self.NormalRewardCommon),
        ImgReceive = self.ImgNormalReceive,
        TxtReceive = self.TxtNormalReceive,
        Effect = self.EffectNormal,
        ImgLock = self.NormalLock,
        CanvasGroup = self.PanelJuniorReward,
    }
    self._UiNormal = uiGroupNormal
    self._UiNormal.GridCommon:SetProxyClickFunc(function()
        self:OnNormalGridClick()
    end)
end

function XUiTransfiniteRewardGridScore:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiTransfiniteRewardGridScore:SetData(data)
    self._Data = data
end

---@param data XTransfiniteScoreReward
---@param uiGroup XUiTransfiniteRewardGridScoreUiGroup
function XUiTransfiniteRewardGridScore:UpdateByChildData(data, uiGroup)
    uiGroup.GridCommon:Refresh(data.Reward)
    if data.RewardState == RewardState.Lock then
        uiGroup.TxtReceive.gameObject:SetActiveEx(false)
        uiGroup.ImgReceive.gameObject:SetActiveEx(false)
        uiGroup.Effect.gameObject:SetActiveEx(false)
        uiGroup.ImgLock.gameObject:SetActiveEx(true)
        uiGroup.CanvasGroup.alpha = 0.5

    elseif data.RewardState == RewardState.Active then
        uiGroup.TxtReceive.gameObject:SetActiveEx(false)
        uiGroup.ImgReceive.gameObject:SetActiveEx(false)
        uiGroup.Effect.gameObject:SetActiveEx(false)
        uiGroup.ImgLock.gameObject:SetActiveEx(false)
        uiGroup.CanvasGroup.alpha = 0.5

    elseif data.RewardState == RewardState.Achieved then
        uiGroup.TxtReceive.gameObject:SetActiveEx(true)
        uiGroup.ImgReceive.gameObject:SetActiveEx(true)
        uiGroup.Effect.gameObject:SetActiveEx(true)
        uiGroup.ImgLock.gameObject:SetActiveEx(false)
        uiGroup.TxtReceive.text = XUiHelper.GetText("TransfiniteRewardCanReceive")
        uiGroup.CanvasGroup.alpha = 1

    elseif data.RewardState == RewardState.Finish then
        uiGroup.TxtReceive.gameObject:SetActiveEx(true)
        uiGroup.ImgReceive.gameObject:SetActiveEx(true)
        uiGroup.Effect.gameObject:SetActiveEx(false)
        uiGroup.TxtReceive.text = data.Desc
        uiGroup.ImgLock.gameObject:SetActiveEx(false)
        uiGroup.TxtReceive.text = XUiHelper.GetText("TransfiniteRewardReceive")
        uiGroup.CanvasGroup.alpha = 1

    end
end

function XUiTransfiniteRewardGridScore:Update()
    local data = self._Data
    self:UpdateByChildData(data.Reward, self._UiNormal)
    self.Normal.gameObject:SetActiveEx(true)
    self.Lock.gameObject:SetActiveEx(false)
    self.TextNumber1.text = data.Reward.Desc
end

function XUiTransfiniteRewardGridScore:OnNormalGridClick()
    if self._Data.Reward.RewardState ~= RewardState.Achieved then
        XLuaUiManager.Open("UiTip", self._Data.Reward.Reward)
    else
        self:ReceiveReward()
    end
end

function XUiTransfiniteRewardGridScore:ReceiveReward()
    XDataCenter.TransfiniteManager.RequestReceiveScoreReward(self._Data.Reward.Index)
end

return XUiTransfiniteRewardGridScore