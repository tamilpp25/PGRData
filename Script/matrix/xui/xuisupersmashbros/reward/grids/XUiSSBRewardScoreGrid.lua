local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local XUiSSBRewardScoreGrid = XClass(nil, "XUiSSBRewardScoreGrid")

function XUiSSBRewardScoreGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.BtnReceive.CallBack = function() self:OnClickBtnReceive() end
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiSSBRewardScoreGrid:Refresh(rewardCfg, rootUi)
    self.GameObject:SetActiveEx(rewardCfg ~= nil)
    if not rewardCfg then return end
    self.RewardCfg = rewardCfg
    self.TxtScore.text = rewardCfg.NeedScore
    self:CreateDropListByRewardId(rewardCfg.RewardId, rootUi)
    self:RefreshGetButton()
end

function XUiSSBRewardScoreGrid:RefreshGetButton()
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(self.RewardCfg.ModeId)
    local canGet, isGet = mode:CheckRewardReceiveStateByLevel(self.RewardCfg.OrderId)
    self.PanelAlreadyGet.gameObject:SetActiveEx(isGet)
    self.BtnReceive.gameObject:SetActiveEx(not isGet)
    self.BtnReceive:SetButtonState(canGet and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiSSBRewardScoreGrid:CreateDropListByRewardId(rewardId, rootUi)
    if (not rewardId) or (rewardId == 0) then --若没有奖励ID 或 没有查到对应奖励列表
        self:HideAllDropItem()
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        local index = 1
        while(true) do
            if rewards[index] then
                self:GetDropItem(index, rootUi):Refresh(rewards[index])
            elseif self.DropItems[index] then
                self:GetDropItem(index, rootUi):Refresh(nil) --刷新空值可隐藏GridCommon组件
            else
                break
            end
            index = index + 1
        end
    end
end
--================
--根据序号获取掉落图标组件
--@param index：序号
--================
function XUiSSBRewardScoreGrid:GetDropItem(index, rootUi)
    if not self.DropItems then self.DropItems = {} end
    if not self.DropItems[index] then
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridReward, self.PanelRewardContent)
        local grid = XUiGridCommon.New(rootUi, prefab)
        self.DropItems[index] = grid
    end
    return self.DropItems[index]
end
--================
--隐藏所有掉落图标组件
--================
function XUiSSBRewardScoreGrid:HideAllDropItem()
    for _, dropGrid in pairs(self.DropItems or {}) do
        dropGrid:Refresh(nil) --刷新空值可隐藏GridCommon组件
    end
end

function XUiSSBRewardScoreGrid:OnClickBtnReceive()
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(self.RewardCfg.ModeId)
    local canGet, isGet = mode:CheckRewardReceiveStateByLevel(self.RewardCfg.OrderId)
    if not canGet then
        XUiManager.TipText("SSBRewardCantGet")
        return
    elseif isGet then
        XUiManager.TipText("SSBRewardAlreadyGet")
        return
    end
    XDataCenter.SuperSmashBrosManager.TakeScoreReward(self.RewardCfg, function(resultList)
            XUiManager.OpenUiObtain(resultList, nil, nil)
            self:RefreshGetButton()
        end)
end

return XUiSSBRewardScoreGrid