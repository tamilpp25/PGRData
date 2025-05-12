local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridRewardTip = XClass(nil, "XUiGridRewardTip")

function XUiGridRewardTip:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnClickBtnFinish, nil, true)
    self.BtnGo.CallBack = handler(self, self.OnClickBtnGo)
    XUiHelper.RegisterClickEvent(self, self.BtnReceiveBlueLight, self.OnClickReceiveAll, nil, true)

    self.GridCommon.gameObject:SetActiveEx(false)

    self.RewardGrids = {}
end

function XUiGridRewardTip:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridRewardTip:Refresh(rewardId, levelId)
    self.RewardId = rewardId
    self.ReceiveAll = rewardId == -1
    self.PanelAnimation.gameObject:SetActiveEx(not self.ReceiveAll)
    self.TaskReceive.gameObject:SetActiveEx(self.ReceiveAll)

    if self.ReceiveAll then
        return
    end

    local name = XStrongholdConfigs.GetRewardTitle(rewardId)
    self.TxtTaskName.text = name

    local conditionId = XStrongholdConfigs.GetRewardConditionId(rewardId)
    local ret, des, haveCount, requireCount = XConditionManager.CheckCondition(conditionId)
    self.TxtTaskDescribe.text = des

    if haveCount and XTool.IsNumberValid(requireCount) then
        self.TxtTaskNumQian.text = CsXTextManagerGetText("StrongholdRewardProgress", haveCount, requireCount)
        self.TxtTaskNumQian.gameObject:SetActiveEx(true)

        self.ImgProgress.fillAmount = haveCount / requireCount
        self.ProgressBg.gameObject:SetActiveEx(true)
    else
        self.TxtTaskNumQian.gameObject:SetActiveEx(false)
        self.ProgressBg.gameObject:SetActiveEx(false)
    end

    local isFinished = XDataCenter.StrongholdManager.IsRewardFinished(rewardId)
    self.BtnFinish:SetDisable(not ret)
    self.BtnFinish.gameObject:SetActiveEx(not isFinished)
    local skipId = XStrongholdConfigs.GetRewardSkipId(rewardId)
    self.BtnGo.gameObject:SetActiveEx(not isFinished and not ret and XTool.IsNumberValid(skipId))
    self.BtnReceiveHave.gameObject:SetActiveEx(isFinished)

    local rewardGoodsId = XStrongholdConfigs.GetRewardGoodsId(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardGoodsId) or {}
    for index, reward in ipairs(rewards or {}) do
        local grid = self.RewardGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or CSUnityEngineObjectInstantiate(self.GridCommon, self.GridCommon.parent)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self.RewardGrids do
        local grid = self.RewardGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    local isShow = XRedPointConditions.Check(XRedPointConditions.Types.XRedPointConditionStrongholdMineralLeft, self.RewardId)
    self.BtnFinish:ShowReddot(isShow)

    --预览模式不显示按钮
    if XTool.IsNumberValid(levelId) then
        self.BtnFinish.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnReceiveHave.gameObject:SetActiveEx(false)
    end
end

function XUiGridRewardTip:OnClickBtnFinish()
    local rewardId = self.RewardId

    local conditionId = XStrongholdConfigs.GetRewardConditionId(rewardId)
    local ret = XConditionManager.CheckCondition(conditionId)
    if not ret then return end

    local cb = function(rewardGoods)
        if not XTool.IsTableEmpty(rewardGoods) then
            XUiManager.OpenUiObtain(rewardGoods)
        end
    end
    XDataCenter.StrongholdManager.GetStrongholdRewardRequest({ rewardId }, cb)
end

function XUiGridRewardTip:OnClickBtnGo()
    local skipId = XStrongholdConfigs.GetRewardSkipId(self.RewardId)
    XFunctionManager.SkipInterface(skipId)
end

function XUiGridRewardTip:OnClickReceiveAll()
    local rewardIds = XDataCenter.StrongholdManager.GetCanReceiveReward()
    XDataCenter.StrongholdManager.GetStrongholdRewardRequest(rewardIds, function(rewardGoods)
        if not XTool.IsTableEmpty(rewardGoods) then
            XUiManager.OpenUiObtain(rewardGoods)
        end
    end)
end

return XUiGridRewardTip