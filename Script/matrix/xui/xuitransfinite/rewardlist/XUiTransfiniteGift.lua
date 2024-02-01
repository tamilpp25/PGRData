local XViewModelTransfiniteGift = require("XEntity/XTransfinite/ViewModel/XViewModelTransfiniteGift")
local XUiTransfiniteChallengeReward = require("XUi/XUiTransfinite/RewardList/XUiTransfiniteChallengeReward")
local XUiTransfinitePointsReward = require("XUi/XUiTransfinite/RewardList/XUiTransfinitePointsReward")

---@class XUiTransfiniteGift:XLuaUi
local XUiTransfiniteGift = XLuaUiManager.Register(XLuaUi, "UiTransfiniteGift")

function XUiTransfiniteGift:Ctor()
    ---@type XViewModelTransfiniteGift
    self._ViewModel = XViewModelTransfiniteGift.New()

    ---@type XUiTransfinitePointsReward
    self._ScorePanel = nil

    ---@type XUiTransfiniteChallengeReward
    self._ChallengePanel = nil

    self._ItemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
end

function XUiTransfiniteGift:OnAwake()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    XUiPanelAsset.New(self, self.AssetPanel, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self._ChallengePanel = XUiTransfiniteChallengeReward.New(self, self.PanelChallenge, self._ViewModel)
    self._ScorePanel = XUiTransfinitePointsReward.New(self.PanelTask, self._ViewModel)

    self.TabPanel:Init({ self.TogGift, self.TogChallenge }, function(index)
        self:OnSelectTab(index)
    end)
    self.TabPanel:SelectIndex(self._ViewModel:GetTabIndex(), false)

    self._ScorePanel:OnAwake()
end

function XUiTransfiniteGift:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_SCORE_REWARD, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self._ItemId, self.Refresh, self)
    self._ScorePanel:OnEnable()
    self:UpdateByTab()
    self:UpdateRedPoint()
end

function XUiTransfiniteGift:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_SCORE_REWARD, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self._ItemId, self.Refresh, self)
end

function XUiTransfiniteGift:Refresh()
    self:UpdateRedPoint()
    self:UpdateByTab()
end

function XUiTransfiniteGift:UpdateRedPoint()
    self.TogGift:ShowReddot(self._ViewModel:IsShowRedDotScore())
    self.TogChallenge:ShowReddot(self._ViewModel:IsShowRedDotChallenge())
end

function XUiTransfiniteGift:UpdateByTab()
    local index = self._ViewModel:GetTabIndex()
    if index == XTransfiniteConfigs.GiftTabIndex.Score then
        self._ScorePanel:SetActive(true)
        self._ChallengePanel:SetActive(false)
        self._ScorePanel:Update()
    elseif index == XTransfiniteConfigs.GiftTabIndex.Challenge then
        self._ScorePanel:SetActive(false)
        self._ChallengePanel:SetActive(true)
        self._ChallengePanel:Update()
    end
end

function XUiTransfiniteGift:OnSelectTab(index)
    self._ViewModel:SetTabIndex(index)
    self:UpdateByTab()
    self:PlayAnimation("QieHuan")
end

return XUiTransfiniteGift
