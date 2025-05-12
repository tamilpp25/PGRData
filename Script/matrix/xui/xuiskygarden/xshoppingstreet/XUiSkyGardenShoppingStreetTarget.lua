local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")
---@class XUiSkyGardenShoppingStreetTarget : XLuaUi
---@field BtnStart XUiComponent.XUiButton
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetTarget = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetTarget")

--region 生命周期
function XUiSkyGardenShoppingStreetTarget:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetTarget:OnStart(stageId)
    self._Control:X3CSetVirtualCameraByCameraIndex(1)
    self._stageId = stageId
    
    local stageId = self._stageId
    local config = self._Control:GetStageConfigsByStageId(stageId)
    self._Targets = {}
    XTool.UpdateDynamicItem(self._Targets, config.TargetTaskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)

    if self.PanelReward then
        local historyStageIds = self._Control:GetPassedStageIds()
        local HasFinish = false
        for i = 1, #historyStageIds do
            if historyStageIds[i] == stageId then
                HasFinish = true
                break
            end
        end
        self.PanelReward.gameObject:SetActive(not HasFinish)
        if not HasFinish then
            self._Rewards = {}
            local rewards = XRewardManager.GetRewardList(config.RewardId)
            XTool.UpdateDynamicItem(self._Rewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
        end
    else
        self._Rewards = {}
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        XTool.UpdateDynamicItem(self._Rewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
    end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetTarget:OnBtnStartClick()
    self._Control:EnterStreetShopGame(self._stageId)
end

function XUiSkyGardenShoppingStreetTarget:OnBtnBackClick()
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetTarget:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick, true)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetTarget
