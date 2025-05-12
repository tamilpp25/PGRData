---@class XUiSkyGardenShoppingStreetBillboardGrid : XUiNode
local XUiSkyGardenShoppingStreetBillboardGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetBillboardGrid")
local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")
local XUiSkyGardenShoppingStreetBuffAssetGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffAssetGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetBillboardGrid:OnStart(...)
    self.GridTask.CallBack = function() self:OnGridLightClick() end

    self._GridBuffsUi = {}
    self._GridBuffsUi2 = {}
    self._GridBuffsUi3 = {}
end

function XUiSkyGardenShoppingStreetBillboardGrid:Update(billboardId, index)
    self._Index = index
    local billboardCfg = self._Control:GetBillboardConfigById(billboardId)
    local taskId = billboardCfg.TaskId
    local taskCfg = self._Control:GetStageTaskConfigsById(taskId)
    self.TxtTitle.text = taskCfg.Name
    self.TxtInfoDetail.text = taskCfg.Desc

    local scheduleDiv = taskCfg.ScheduleDiv
    if not scheduleDiv or scheduleDiv == 0 then
        scheduleDiv = 1
    end

    local isFinish = false
    local taskData = self._Control:GetTaskDataByConfigId(taskId)
    local configStr = XTool.MathGetRoundingValueStandard(taskCfg.Schedule / scheduleDiv, 1)
    if taskData then
        self.TxtTaskDetail.text = string.format(taskCfg.ConditionDesc, XTool.MathGetRoundingValueStandard(taskData.Schedule / scheduleDiv, 1) .. "/" .. configStr)
        isFinish = taskData.State ~= XMVCA.XSkyGardenShoppingStreet.XSgStreetTaskState.Activated
    else
        local selectBillboardId = self._Control:GetStageBillboardsSelectedId()
        isFinish = selectBillboardId > 0
        if isFinish then
            self.TxtTaskDetail.text = string.format(taskCfg.ConditionDesc, configStr .. "/" .. configStr)
        else
            self.TxtTaskDetail.text = string.format(taskCfg.ConditionDesc, 0 .. "/" .. configStr)
        end
    end

    XTool.UpdateDynamicItem(self._GridBuffsUi, billboardCfg.RestrictBuff, self.GridBuff, XUiSkyGardenShoppingStreetBuffGrid, self)
    for i = 1, #self._GridBuffsUi do
        self._GridBuffsUi[i]:SetClickCallback()
    end

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
    
    local isShowReward = #rewardBuffList1 > 0 or #rewardBuffList2 > 0
    self.PanelReward.gameObject:SetActive(isShowReward)
    if isShowReward then
        XTool.UpdateDynamicItem(self._GridBuffsUi2, rewardBuffList1, self.RewardGridBuff, XUiSkyGardenShoppingStreetBuffGrid, self)
        for i = 1, #self._GridBuffsUi2 do
            self._GridBuffsUi2[i]:SetClickCallback()
        end
        XTool.UpdateDynamicItem(self._GridBuffsUi3, rewardBuffList2, self.GridAsset, XUiSkyGardenShoppingStreetBuffAssetGrid, self)    
    end

    self.ImgComplete.gameObject:SetActive(isFinish)
    self.GridBuff.gameObject:SetActive(false)
    self.RewardGridBuff.gameObject:SetActive(false)
    self.GridAsset.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetBillboardGrid:SetSelected(isSelected)
    self.ImgSelect.gameObject:SetActive(isSelected)
end

function XUiSkyGardenShoppingStreetBillboardGrid:OnGridLightClick()
    self.Parent:OnSelectClick(self._Index)
end
--endregion

return XUiSkyGardenShoppingStreetBillboardGrid
