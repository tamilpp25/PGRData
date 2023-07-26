local tableInsert = table.insert

local XUiInvertCardRewardPanel = XClass(nil, "XUiInvertCardRewardPanel")
local XUiInvertCardRewardItem = require("XUi/XUiInvertCardGame/XUiInvertCardRewardItem")

function XUiInvertCardRewardPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiInvertCardRewardPanel:Init()
    self.TextProgressDesc.gameObject:SetActiveEx(true)
    self.TextProgressDesc.text = ""
    self.ImgProgress.gameObject:SetActiveEx(true)
    self.ImgProgress.fillAmount = 0
    self.RewardTmp.gameObject:SetActiveEx(false)

    self.RewardsPool = {}
end

function XUiInvertCardRewardPanel:Refresh(stageEntity)
    self.StageEntity = stageEntity
    self.Rewards = stageEntity:GetRewards()
    self.Process = self.StageEntity:GetProgress()
    self:RefreashDescText()
    self:RefreashReward()
    self:RefreashProcessImg()
end

function XUiInvertCardRewardPanel:RefreashDescText()
    if not self.StageEntity then
        return
    end

    local desc = self.StageEntity:GetClearConditionDesc()
    self.TextProgressDesc.text = XUiHelper.ConvertLineBreakSymbol(desc)
end

function XUiInvertCardRewardPanel:RefreashReward()
    if not self.Rewards then
        return
    end

    local rewardDatas = {}
    local stageId = self.StageEntity:GetId()
    for index, rewardId in ipairs(self.Rewards) do
        local data = {
            StageId = stageId,
            Index = index,
            RewardId = rewardId,
        }
        tableInsert(rewardDatas, data)
    end

    local onCreatCb = function (item, data)
        item:SetActiveEx(true)
        item:OnCreat(data)
        item:SetTakedState(XDataCenter.InvertCardGameManager.CheckRewardState(self.StageEntity:GetId(), data.Index))
        item:SetBtnActiveCallBack(function () self:TakeReward() end)
    end

    XUiHelper.CreateTemplates(self.RootUi, self.RewardsPool, rewardDatas, XUiInvertCardRewardItem.New, self.RewardTmp, self.RewardContent, onCreatCb)
end

function XUiInvertCardRewardPanel:RefreashProcessImg()
    if not self.StageEntity then
        return
    end
    local finishedRewardCount = 0
    local finishProcess = XInvertCardGameConfig.GetStageFinishProgressById(self.StageEntity:GetId())
    for _, finishProcessNum in ipairs(finishProcess) do
        if self.Process >= finishProcessNum then
            finishedRewardCount = finishedRewardCount + 1
        end
    end
    local ratioProcess = finishedRewardCount/#self.Rewards
    if ratioProcess < 0 then ratioProcess = 0 end
    if ratioProcess > 1 then ratioProcess = 1 end
    self.ImgProgress.fillAmount = ratioProcess
end

function XUiInvertCardRewardPanel:TakeReward()
    if self.StageEntity then
        XDataCenter.InvertCardGameManager.InvertCardsRewardRequest(self.StageEntity:GetId())
    end
end

return XUiInvertCardRewardPanel