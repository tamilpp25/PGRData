
local XUiPickFlipRewardGrid = XClass(XSignalData, "XUiPickFlipRewardGrid")

function XUiPickFlipRewardGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XPFReward
    self.Reward = nil
    self.Index = 0
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClicked)
end

-- reward : XPFReward
function XUiPickFlipRewardGrid:SetReward(index, reward, isConfigFinished)
    self.Index = index
    self.Reward = reward
    self.PanelConfig.gameObject:SetActiveEx(isConfigFinished)
    self.PanelNoneConfig.gameObject:SetActiveEx(not isConfigFinished) 
    if isConfigFinished then 
        local isReceived = reward:GetIsReceived()
        self.PanelItem.gameObject:SetActiveEx(isReceived)
        self.RImgIcon:SetRawImage(reward:GetIcon())
        self.TxtCount.text = string.format("x%s", reward:GetCount())
    else
        self.PanelItem.gameObject:SetActiveEx(false)
    end
end

function XUiPickFlipRewardGrid:OnBtnClicked()
    self:EmitSignal("OnRewardGridClicked", self.Index)
end

--######################## XUiPickFlipRewardPanel ########################
local XUiPickFlipRewardPanel = XClass(nil, "XUiPickFlipRewardPanel")

function XUiPickFlipRewardPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- XPFRewardLayer
    self.RewardLayer = nil
    self.RewardGrids = {}
end

-- rewardLayer : XPFRewardLayer
function XUiPickFlipRewardPanel:SetData(rewardLayer)
    self.RewardLayer = rewardLayer
    self:RefrshRewards()
end

-- reward : XPFReward
function XUiPickFlipRewardPanel:SetReward(index, reward)
    self.RewardGrids[index]:SetReward(index, reward, self.RewardLayer:GetIsConfigFinished())
end

function XUiPickFlipRewardPanel:RefrshRewards()
    local rewardContainer
    local prefabAssetPath = self.RewardLayer:GetRewardAssetPath()
    local rewards = self.RewardLayer:GetConfigFinishedRewards()
    local go, rewardGrid, reward
    for i = 1, self.RewardLayer:GetMaxRewardCount() do
        reward = rewards[i]
        rewardGrid = self.RewardGrids[i]
        if rewardGrid == nil then
            rewardContainer = self["Stage" .. i]
            go = rewardContainer:LoadPrefab(prefabAssetPath)
            rewardGrid = XUiPickFlipRewardGrid.New(go)
            self.RewardGrids[i] = rewardGrid
        end
        rewardGrid:SetReward(i, reward, self.RewardLayer:GetIsConfigFinished())
    end
end

function XUiPickFlipRewardPanel:PlayAnimFinish()
    self.AnimFinish:Play()
end

function XUiPickFlipRewardPanel:PlayAnimFinish2()
    self.AnimFinish2:Play()
end

return XUiPickFlipRewardPanel