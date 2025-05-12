local tableInsert = table.insert
local Vector3 = CS.UnityEngine.Vector3

local XUiSlotMachineRewardItem = require("XUi/XUiSlotMachine/XUiSlotMachineRewardItem")
---@class XUiSlotMachineRewardPanel
local XUiSlotMachineRewardPanel = XClass(nil, "XUiSlotMachineRewardPanel")

function XUiSlotMachineRewardPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiSlotMachineRewardPanel:Init()
    self.RewardsPool = {}
    self.ShowBestRewardDistance = -1
    self.IsGotBestReward = false
end

function XUiSlotMachineRewardPanel:OnUpdate()
    self:CheckPanelBestEnable()
end

function XUiSlotMachineRewardPanel:CheckPanelBestEnable()
    if self.IsGotBestReward then return end
    self.PanelBest.gameObject:SetActiveEx((math.abs(self.Content.anchoredPosition.y) <= self.ShowBestRewardDistance))
end

function XUiSlotMachineRewardPanel:Refresh(machineId, isResetContentPos)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self.CurMachineConfig = XSlotMachineConfigs.GetSlotMachinesTemplateById(machineId)
    self.CurMachineActAmount = #(XSlotMachineConfigs.GetSlotMachinesActivityTemplate())
    local totalScore = self.CurMachineEntity:GetTotalScore()
    self.TxtCurScore.text = totalScore
    if self.TxtTotalScore then
        local rewardScores = self.CurMachineEntity:GetRewardScores()
        self.TxtTotalScore.text = string.format("/%s", rewardScores[#rewardScores])
    end
    --self.ImgProgress.fillAmount = totalScore / self.CurMachineEntity:GetScoreLimit()
    if isResetContentPos then
        self.Content.transform.localPosition = Vector3(self.Content.transform.localPosition.x, 0, 0)
    end
    self:RefreshRewardGrid()
    self:SetMoreWardsState()
    -- 这里目的是让content移动一下，规避奖励特效不出现问题
    self.Content.transform:DOLocalMoveY(self.Content.transform.localPosition.y - 1, 0.05):OnComplete(function()
        self.Content.transform:DOLocalMoveY(self.Content.transform.localPosition.y + 1, 0.05)
    end)
end

function XUiSlotMachineRewardPanel:RefreshRewardGrid()
    if self.CurMachineEntity then
        self.IsGotBestReward = false
        local rewardList = self:GetReverseTable(self.CurMachineEntity:GetRewardIds())
        local rewardScore = self:GetReverseTable(self.CurMachineEntity:GetRewardScores())
        local totalScore = self.CurMachineEntity:GetTotalScore()

        local rewardDatas = {}
        local rewardCount = #rewardList
        local curReachIndex = 0
        local bestRewardId = 0
        for index, rewardId in ipairs(rewardList) do
            local data = {
                Index = (rewardCount - index + 1),
                RewardId = rewardId,
                RewardScore = rewardScore[index],
            }
            if totalScore >= rewardScore[index] then
                curReachIndex = curReachIndex + 1
            end
            tableInsert(rewardDatas, data)
            if index == 1 then
                bestRewardId = rewardId
            end
        end
        local onCreatCb = function(item, data)
            item:SetActiveEx(true)
            item:OnCreat(data)
            item:SetTakedState(XDataCenter.SlotMachineManager.CheckRewardState(self.CurMachineEntity:GetId(), data.Index))
            item:SetBtnActiveCallBack(function()
                self:TakeReward(data.Index)
            end)
        end
        local process = 1
        local oneProcess = math.floor(1 / rewardCount * 100) / 100 --每一份奖励所占进度
        if curReachIndex < 10 then
            local nextReachIndex = rewardCount - curReachIndex
            local temp = rewardScore[nextReachIndex]
            local tempL = 0
            if nextReachIndex < 10 then
                tempL = rewardScore[nextReachIndex + 1]
            end
            local processL = ((totalScore - tempL) / (temp - tempL)) * oneProcess
            process = (math.floor((curReachIndex / rewardCount) * 100) / 100) + processL
            process = math.floor(process * 100) / 100
        end
        self.ImgProgress.fillAmount = process
        XUiHelper.CreateTemplates(self.RootUi, self.RewardsPool, rewardDatas, XUiSlotMachineRewardItem.New, self.RewardRoot, self.RewardPanel, onCreatCb)
        
        self.IsGotBestReward = XDataCenter.SlotMachineManager.CheckRewardState(self.CurMachineEntity:GetId(), rewardCount) == XSlotMachineConfigs.RewardTakeState.Took
        if self.IsGotBestReward then
            self.PanelBest.gameObject:SetActiveEx(false)
        else
            -- 刷新最好奖励显示距离
            local distanceDifference = self.Content.rect.size.y - self.Content.parent.rect.size.y
            self.ShowBestRewardDistance = distanceDifference - distanceDifference / #rewardList
            local bestReward = XRewardManager.GetRewardList(bestRewardId)[1]
            local BestRewardIcon = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(bestReward.TemplateId).Icon
            self.RImgBestIcon:SetRawImage(BestRewardIcon)
        end
    end
end

function XUiSlotMachineRewardPanel:SetMoreWardsState()
    if self.CurMachineEntity then
        local rewardList = self.CurMachineEntity:GetRewardIds()
        local rewardScore = self.CurMachineEntity:GetRewardScores()
        if #rewardList > 5 then
            for i = 6, #rewardList do
                local rewardState = XDataCenter.SlotMachineManager.CheckRewardState(self.CurMachineEntity:GetId(), i)
                if rewardState == XSlotMachineConfigs.RewardTakeState.NotTook then
                    --self.PanelMorerewards.gameObject:SetActiveEx(true)
                    self:SetMoreRewardPanelActive(true)
                    return
                end
            end
        end
    end
    --self.PanelMorerewards.gameObject:SetActiveEx(false)
    self:SetMoreRewardPanelActive(false)
end

function XUiSlotMachineRewardPanel:SetMoreRewardPanelActive(flag)
    if not flag then
        for i = 1, self.CurMachineActAmount do
            if self["Highlight" .. i] then
                self["Highlight" .. i].gameObject:SetActiveEx(false)
            end
        end
    else
        for i = 1, self.CurMachineActAmount do
            if self["Highlight" .. i] then
                if i == self.CurMachineConfig.HighLight then
                    self["Highlight" .. i].gameObject:SetActiveEx(true)
                else
                    self["Highlight" .. i].gameObject:SetActiveEx(false)
                end
            end
        end
    end
end

function XUiSlotMachineRewardPanel:SetRewardsEffectShow(isShow)
    for _, item in pairs(self.RewardsPool) do
        item:SetEffectShow(isShow)
    end
end

function XUiSlotMachineRewardPanel:TakeReward(index)
    XDataCenter.SlotMachineManager.GetSlotMachineReward(self.CurMachineEntity:GetId(), index, function(machineId)
        self:Refresh(machineId)
    end)
end

function XUiSlotMachineRewardPanel:GetReverseTable(arr)
    -- 翻转数组（只能是数组）
    local tmp = {}
    for i = #arr, 1, -1 do
        tableInsert(tmp, arr[i])
    end

    return tmp
end

return XUiSlotMachineRewardPanel