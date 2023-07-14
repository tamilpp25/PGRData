local XPFReward = require("XEntity/XPickFlip/XPFReward")
local XUiPickFlipRewardGrid = require("XUi/XUiPickFlip/XUiPickFlipRewardGrid")
local XUiPickFlipDialog = XLuaUiManager.Register(XLuaUi, "UiPickFlipDialog")

function XUiPickFlipDialog:OnAwake()
    self.PickFlipManager = XDataCenter.PickFlipManager
    -- XPFRewardLayer
    self.RewardLayer = nil
    self.RewardIds = nil
    self:RegisterUiEvents()
end

-- rewardLayer : XPFRewardLayer
function XUiPickFlipDialog:OnStart(rewardLayer, rewardIds)
    self.RewardLayer = rewardLayer
    self.RewardIds = rewardIds
    self.TxtTitle.text = XUiHelper.GetText("TipTitle")
    self.TxtDesc.text = XUiHelper.GetText("PickFlipDialogTip")
    self:RefreshRewardList()
end

--######################## 私有方法 ########################

function XUiPickFlipDialog:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiPickFlipDialog:OnBtnConfirmClicked()
    self.PickFlipManager.RequestPickReward(self.RewardLayer:GetGroupId(), self.RewardIds, function()
        self:EmitSignal("PickRewardFinished")
        self:Close()
    end)
end

function XUiPickFlipDialog:RefreshRewardList()
    self.GridIcon.gameObject:SetActiveEx(false)
    local go
    for _, rewardId in ipairs(self.RewardIds) do
        go = XUiHelper.Instantiate(self.GridIcon, self.PanelIcon)
        XUiPickFlipRewardGrid.New(go, self)
            :SetData(XPFReward.New(rewardId))
        go.gameObject:SetActiveEx(true)
    end
end

return XUiPickFlipDialog