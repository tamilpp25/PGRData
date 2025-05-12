local XUiAccumulateDrawRewardGrid = require("XUi/XUiAccumulateDraw/XUiAccumulateDrawRewardGrid")

---@class XUiAccumulateDrawGrid : XUiNode
---@field ImgPointOff UnityEngine.UI.Image
---@field ImgPointOn UnityEngine.UI.Image
---@field PanelPassedLineOff UnityEngine.UI.Image
---@field PanelBgNormal UnityEngine.RectTransform
---@field PanelBgNormalReceive UnityEngine.RectTransform
---@field PanelBgNormalFinish UnityEngine.RectTransform
---@field PanelBgSpecial UnityEngine.RectTransform
---@field PanelBgSpecialReceive UnityEngine.RectTransform
---@field PanelBgSpecialFinish UnityEngine.RectTransform
---@field PanelPassedLineOn UnityEngine.UI.Image
---@field PanelPassedLineOnBg UnityEngine.RectTransform
---@field PanelPassedLineOffBg UnityEngine.RectTransform
---@field PanelPassedLineOffFinished UnityEngine.UI.Image
---@field PanelPassedLineOnFinished UnityEngine.UI.Image
---@field ImgOnFinished UnityEngine.UI.Image
---@field _Control XAccumulateExpendControl
local XUiAccumulateDrawGrid = XClass(XUiNode, "XUiAccumulateDrawGrid")

local RewardType = {
    Normal = 1,
    NormalReceive = 2,
    NormalFinish = 3,
    Special = 4,
    SpecialReceive = 5,
    SpecialFinish = 6,
}

-- region 生命周期

function XUiAccumulateDrawGrid:OnStart()
    ---@type XUiAccumulateDrawRewardGrid[]
    self._PanelRewardList = {
        [RewardType.Normal] = XUiAccumulateDrawRewardGrid.New(self.PanelBgNormal, self, self.Parent),
        [RewardType.NormalReceive] = XUiAccumulateDrawRewardGrid.New(self.PanelBgNormalReceive, self, self.Parent),
        [RewardType.NormalFinish] = XUiAccumulateDrawRewardGrid.New(self.PanelBgNormalFinish, self, self.Parent),
        [RewardType.Special] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecial, self, self.Parent),
        [RewardType.SpecialReceive] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecialReceive, self, self.Parent),
        [RewardType.SpecialFinish] = XUiAccumulateDrawRewardGrid.New(self.PanelBgSpecialFinish, self, self.Parent),
    }
end

-- endregion

---@param reward XAccumulateExpendReward
---@param preReward XAccumulateExpendReward
---@param nextReward XAccumulateExpendReward
function XUiAccumulateDrawGrid:Refresh(reward, preReward, nextReward)
    local isAchieved = reward:IsAchieved()
    local isFinish = reward:IsFinish()
    local isAchievedOrFinish = isFinish or isAchieved
    local isMain = reward:IsMainReward()
    local isEnd = nextReward == nil
    local isAllFinish = self._Control:CheckAllFinish()
    local isNextAchieved = nextReward and nextReward:IsComplete() or false
    local progress = 0

    if isEnd then
        self.ImgPointOff.gameObject:SetActiveEx(false)
        self.ImgPointOn.gameObject:SetActiveEx(false)
        self.ImgOnFinished.gameObject:SetActiveEx(false)
        self.PanelPassedLineOnBg.gameObject:SetActiveEx(false)
        self.PanelPassedLineOffBg.gameObject:SetActiveEx(false)
        self.PanelPassedLineOn.gameObject:SetActiveEx(false)
        self.PanelPassedLineOff.gameObject:SetActiveEx(false)
        self.PanelPassedLineOffFinished.gameObject:SetActiveEx(false)
        self.PanelPassedLineOnFinished.gameObject:SetActiveEx(false)
    else
        self.ImgPointOff.gameObject:SetActiveEx(not isAchievedOrFinish and not isAllFinish)
        self.ImgPointOn.gameObject:SetActiveEx(isAchievedOrFinish and not isAllFinish)
        self.ImgOnFinished.gameObject:SetActiveEx(isAllFinish)
        self.PanelPassedLineOnBg.gameObject:SetActiveEx(isEnd)
        self.PanelPassedLineOffBg.gameObject:SetActiveEx(not isEnd and not isAllFinish)
        self.PanelPassedLineOn.gameObject:SetActiveEx(isEnd)
        self.PanelPassedLineOff.gameObject:SetActiveEx(not isEnd and not isAllFinish)
        self.PanelPassedLineOffFinished.gameObject:SetActiveEx(not isEnd and isAllFinish)
        self.PanelPassedLineOnFinished.gameObject:SetActiveEx(isEnd and isAllFinish)
    end


    if isMain then
        if isAchieved then
            self:_RefreshReward(reward, RewardType.SpecialReceive)
        elseif isFinish then
            self:_RefreshReward(reward, RewardType.SpecialFinish)
        else
            self:_RefreshReward(reward, RewardType.Special)
        end
    else
        if isAchieved then
            self:_RefreshReward(reward, RewardType.NormalReceive)
        elseif isFinish then
            self:_RefreshReward(reward, RewardType.NormalFinish)
        else
            self:_RefreshReward(reward, RewardType.Normal)
        end
    end
    if isNextAchieved or (isEnd and reward:IsComplete()) then
        progress = 1
    else
        local count = reward:GetItemCount()
        local preCount = preReward and preReward:GetItemCount() or -reward:GetItemCount()
        local nextCount = nextReward and nextReward:GetItemCount() or reward:GetItemCount()
        local totalProgress = self._Control:GetCurrentRewardCount()

        if totalProgress < count then
            local middle = (count + preCount) / 2

            if totalProgress <= middle then
                progress = 0
            else
                progress = (totalProgress - middle) / middle
            end
        elseif totalProgress >= count and totalProgress <= nextCount then
            local middle = (count + nextCount) / 2

            if totalProgress <= middle then
                progress = (totalProgress - count) / middle + 0.5
            else
                progress = 1
            end
        end
    end
    if isEnd then
        if isAllFinish then
            self.PanelPassedLineOnFinished.fillAmount = progress
        else
            self.PanelPassedLineOn.fillAmount = progress
        end
    else
        if isAllFinish then
            self.PanelPassedLineOffFinished.fillAmount = progress
        else
            self.PanelPassedLineOff.fillAmount = progress
        end
    end
end

---@param reward XAccumulateExpendReward
function XUiAccumulateDrawGrid:_RefreshReward(reward, targetType)
    for rewardType, rewardPanel in pairs(self._PanelRewardList) do
        if rewardType == targetType then
            rewardPanel:Open()
            rewardPanel:Refresh(reward)
        else
            rewardPanel:Close()
        end
    end
end

return XUiAccumulateDrawGrid
