local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridRewardTip = XClass(nil, "XUiGridRewardTip")

function XUiGridRewardTip:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnReceive.CallBack = handler(self, self.OnClickBtnReceive)
    self.GridCommon.gameObject:SetActiveEx(false)

    self.RewardGrids = {}
end

function XUiGridRewardTip:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridRewardTip:Refresh(starRewardId, diff)
    self.StarRewardId = starRewardId

    local requireStar = XKillZoneConfigs.GetStarRewardStar(starRewardId)
    local curStar = XDataCenter.KillZoneManager.GetTotalStageStarByDiff(diff)
    curStar = XMath.Clamp(curStar, curStar, requireStar)
    self.TxtGradeStarNums.text = CsXTextManagerGetText("KillZoneStarRewardProcess", curStar, requireStar)

    local canGet = XDataCenter.KillZoneManager.IsStarRewardCanGet(starRewardId)
    local hasGot = XDataCenter.KillZoneManager.IsStarRewardObtained(starRewardId)
    self.ImgCannotReceive.gameObject:SetActiveEx(not canGet and not hasGot)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(hasGot)
    self.BtnReceive.gameObject:SetActiveEx(canGet and not hasGot)

    local rewardGoodsId = XKillZoneConfigs.GetStarRewardGoodsId(starRewardId)
    local rewards = XRewardManager.GetRewardList(rewardGoodsId) or {}
    for index, reward in ipairs(rewards or {}) do
        local grid = self.RewardGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or CSUnityEngineObjectInstantiate(self.GridCommon, self.PanelTreasureContent)
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
end

function XUiGridRewardTip:OnClickBtnReceive()
    local starRewardId = self.StarRewardId
    local cb = function(rewardGoods)
        if not XTool.IsTableEmpty(rewardGoods) then
            XUiManager.OpenUiObtain(rewardGoods)
        end
    end
    XDataCenter.KillZoneManager.KillZoneTakeDiffStarRewardRequest(starRewardId, cb)
end

return XUiGridRewardTip