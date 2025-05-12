---@class XUiSkyGardenShoppingStreetToastTaskSettlement : XLuaUi
---@field TxtRound UnityEngine.UI.Text
---@field ListAsset UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field BtnLeave XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetToastTaskSettlement = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastTaskSettlement")

local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")
local XUiSkyGardenShoppingStreetBuffAssetGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffAssetGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetToastTaskSettlement:OnAwake()
    self:_RegisterButtonClicks()
    self._GridBuffsUi2 = {}
    self._GridBuffsUi3 = {}
end

function XUiSkyGardenShoppingStreetToastTaskSettlement:OnStart(cb)
    self._closeCb = cb
    self._Control:CleanFinishLimitTask()
    local billboardId = self._Control:GetEndBillboardId()
    local isSuccess = self._Control:IsFinishBillboardTaskSuccess()

    local billboardCfg = self._Control:GetBillboardConfigById(billboardId)
    local taskCfg = self._Control:GetStageTaskConfigsById(billboardCfg.TaskId)

    local schedule = self._Control:GetLimitTaskSchedule()
    if not schedule then
        schedule = taskCfg.Schedule
    end
    if taskCfg.ScheduleDiv > 0 then
        self.TxtDetail.text = string.format(taskCfg.ConditionDesc, schedule / taskCfg.ScheduleDiv .. "/" .. taskCfg.Schedule / taskCfg.ScheduleDiv)
    else
        self.TxtDetail.text = string.format(taskCfg.ConditionDesc, schedule .. "/" .. taskCfg.Schedule)
    end

    local isSuccessDesc = isSuccess and XMVCA.XBigWorldService:GetText("SG_SS_LimitTaskSuccess") or XMVCA.XBigWorldService:GetText("SG_SS_LimitTaskFail")
    self.TxtHeadTitle.text = isSuccessDesc
    self.TxtTitle.text = taskCfg.Name

    local rewardBuffList1 = {}
    local rewardBuffList2 = {}
    local rewardBuffCount = #billboardCfg.RewardBuff
    for i = 1, rewardBuffCount do
        local rewardBuffId = billboardCfg.RewardBuff[i]
        local buffCfg = self._Control:GetBuffConfigById(rewardBuffId)
        if buffCfg.ShowType == 2 then
            table.insert(rewardBuffList2, rewardBuffId)
        elseif buffCfg.ShowType == 1 then
            table.insert(rewardBuffList1, rewardBuffId)
        end
    end
    local showReward = (#rewardBuffList1 > 0 or #rewardBuffList2 > 0) and isSuccess
    self.PanelReward.gameObject:SetActive(showReward)
    if showReward then
        XTool.UpdateDynamicItem(self._GridBuffsUi2, rewardBuffList1, self.GridBuff, XUiSkyGardenShoppingStreetBuffGrid, self)
        XTool.UpdateDynamicItem(self._GridBuffsUi3, rewardBuffList2, self.GridAsset, XUiSkyGardenShoppingStreetBuffAssetGrid, self)
    end
end

function XUiSkyGardenShoppingStreetToastTaskSettlement:OnDestroy()
    if self._closeCb then self._closeCb() end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetToastTaskSettlement:OnBtnCloseClick()
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetToastTaskSettlement:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end
--endregion

return XUiSkyGardenShoppingStreetToastTaskSettlement
