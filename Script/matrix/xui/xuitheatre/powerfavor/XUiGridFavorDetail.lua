local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridToken = require("XUi/XUiTheatre/PowerFavor/XUiGridToken")

local FavorCoin = XTheatreConfigs.TheatreFavorCoin

--肉鸽玩法势力详情的格子
local XUiGridFavorDetail = XClass(nil, "XUiGridFavorDetail")

function XUiGridFavorDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RewardGrids = {}
    self.TheatrePowerManager = XDataCenter.TheatreManager.GetPowerManager()
    self:SetButtonCallBack()
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiGridFavorDetail:Init(rootUi)
    self.RootUi = rootUi
    self.TokenRewardGrid = XUiGridToken.New(XUiHelper.Instantiate(self.GridCommon, self.GridContent), rootUi)
end

function XUiGridFavorDetail:Refresh(powerFavorId)
    self.PowerFavorId = powerFavorId

    local lv = XTheatreConfigs.GetPowerFavorLv(powerFavorId)
    self.TxtLevel.text = XUiHelper.GetText("TheatreDecorationTipsLevel", lv)

    self.TxtDescribe.text = XTheatreConfigs.GetPowerFavorRewardDesc(powerFavorId)

    --奖励进度
    self.TxtTaskNumQian.text = ""
    self.ImgProgress.fillAmount = 0

    --刷新奖励
    self:UpdateReward(powerFavorId)

    --刷新领取按钮状态
    self:UpdateBtnReceiveState()
end

function XUiGridFavorDetail:UpdateBtnReceiveState()
    local powerFavorId = self.PowerFavorId
    local isCanReceive = self.TheatrePowerManager:IsUnlockPowerFavor(powerFavorId)  --是否可领取
    local isReward = self.TheatrePowerManager:IsEffectPowerFavor(powerFavorId)  --是否已领取
    self.BtnReceive:SetDisable(not isCanReceive, isCanReceive)
    self.BtnReceive.gameObject:SetActiveEx(not isReward)
    self.ImgComplete.gameObject:SetActiveEx(isReward)
end

function XUiGridFavorDetail:UpdateReward(powerFavorId)
    self.TokenRewardGrid.GameObject:SetActiveEx(false)

    for _, reward in ipairs(self.RewardGrids) do
        reward.GameObject:SetActiveEx(false)
    end

    local rewardId
    local rewardTypes = XTheatreConfigs.GetPowerFavorRewardTypes(powerFavorId)
    for i, rewardType in ipairs(rewardTypes) do
        local params = XTheatreConfigs.GetPowerFavorRewardParams(powerFavorId)
        if rewardType == XTheatreConfigs.PowerFavorRewardType.PowerFavorRewardType1 then
            self:UpdateNormalReward(params[i])
            return
        end

        if rewardType == XTheatreConfigs.PowerFavorRewardType.PowerFavorRewardType5 then
            self:UpdateTokenReward(params[i])
            return
        end
    end
end

--刷新信物奖励
function XUiGridFavorDetail:UpdateTokenReward(keepsakeId)
    keepsakeId = tonumber(keepsakeId)
    if not XTool.IsNumberValid(keepsakeId) then
        return
    end

    self.TokenRewardGrid:Refresh(keepsakeId)
    self.TokenRewardGrid.GameObject:SetActiveEx(true)
end

--刷新通用奖励
function XUiGridFavorDetail:UpdateNormalReward(rewardId)
    rewardId = tonumber(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end

    local rewards = XRewardManager.GetRewardList(rewardId) or {}
    for index, reward in ipairs(rewards or {}) do
        local grid = self.RewardGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.GridContent)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiGridFavorDetail:SetButtonCallBack()
    self.BtnReceive.CallBack = function()
        self.TheatrePowerManager:RequestTheatreGetPowerFavorReward(self.PowerFavorId, handler(self, self.UpdateBtnReceiveState))
    end
end

return XUiGridFavorDetail