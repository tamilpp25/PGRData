---@class XUiSkyGardenShoppingStreetSettlement : XLuaUi
---@field TxtRound UnityEngine.UI.Text
---@field ListAsset UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field BtnLeave XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetSettlement = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetSettlement")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")
local XUiSkyGardenShoppingStreetAssetTag = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetAssetTag")

--region 生命周期
function XUiSkyGardenShoppingStreetSettlement:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetSettlement:OnStart(RewardGoodsList)
    local stageId = self._Control:GetCurrentStageId()
    local config = self._Control:GetStageConfigsByStageId(stageId)
    self._Targets = {}
    XTool.UpdateDynamicItem(self._Targets, config.TargetTaskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)
    for i = 1, #self._Targets do
        self._Targets[i]:SetFinish()
    end

    local isShowReward = RewardGoodsList and #RewardGoodsList > 0
    self._isFinishExit = isShowReward and config.IsFinishExit
    self.ListReward.gameObject:SetActive(isShowReward)
    self._Rewards = {}
    -- local rewards = XRewardManager.GetRewardList(config.RewardId)
    XTool.UpdateDynamicItem(self._Rewards, RewardGoodsList, self.UiBigWorldItemGrid, XUiGridBWItem, self)

    self.TxtRound.text = XMVCA.XBigWorldService:GetText("SG_SS_RoundText", self._Control:GetRunRound())
    self.TxtNum.text = self._Control:GetMaxDailyGold()
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold]
    self.ImgAsset:SetSprite(resCfg.Icon)
    self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)

    self._ResUis = {}
    local StageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    XTool.UpdateDynamicItem(self._ResUis, {
        StageResType.InitGold, 
        StageResType.InitFriendly, 
        StageResType.InitCustomerNum, 
        StageResType.InitEnvironment, }, self.GridGold, 
        XUiSkyGardenShoppingStreetAssetTag, self)
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetSettlement:OnBtnLeaveClick()
    local clickTime = CS.UnityEngine.Time.realtimeSinceStartup
    if self._ClickTime and clickTime - self._ClickTime < 5 then return end
    self._ClickTime = clickTime
    XMVCA.XBigWorldUI:CloseAllUntilTopUi("UiSkyGardenShoppingStreetMain")
    if self._isFinishExit then
        --判断是否返回到上个Level
        if not XMVCA.XSkyGardenShoppingStreet:IsEnterLevel() then
            XMVCA.XBigWorldUI:Close("UiSkyGardenShoppingStreetMain")
        end
        XMVCA.XSkyGardenShoppingStreet:ExitGameLevel()
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetSettlement:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnLeave.CallBack = function() self:OnBtnLeaveClick() end
end
--endregion

return XUiSkyGardenShoppingStreetSettlement
