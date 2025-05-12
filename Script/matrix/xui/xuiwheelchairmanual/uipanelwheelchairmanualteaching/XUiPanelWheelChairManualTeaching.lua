local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelWheelChairManualTeaching: XUiNode
---@field _Control XWheelchairManualControl
local XUiPanelWheelChairManualTeaching = XClass(XUiNode, 'XUiPanelWheelChairManualTeaching')
local XUiGridWheelChairManualTeachingStage = require('XUi/XUiWheelchairManual/UiPanelWheelChairManualTeaching/XUiGridWheelChairManualTeachingStage')

function XUiPanelWheelChairManualTeaching:OnStart()
    self:Init()
    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.TeachingNew)
end

function XUiPanelWheelChairManualTeaching:OnEnable()
    self:Refresh()
end

function XUiPanelWheelChairManualTeaching:Init()
    -- 初始化关卡
    self._StageGrids = {}
    
    local commonStageIds = self._Control:GetCurActivityTeachCommonStageIds()
    local connectivityStageId = self._Control:GetCurActivityTeachConnectivityStageId()

    if not XTool.IsTableEmpty(commonStageIds) then
        for i, v in ipairs(commonStageIds) do
            local stageGo = self['GridStage'..i]

            if stageGo then
                local grid = XUiGridWheelChairManualTeachingStage.New(stageGo, self, v)
                grid:Open()
                table.insert(self._StageGrids, grid)
            end
        end
    end

    if XTool.IsNumberValid(connectivityStageId) then
        local grid = XUiGridWheelChairManualTeachingStage.New(self.ConnectivityStage, self, connectivityStageId)
        grid:Open()
        table.insert(self._StageGrids, grid)
    end
    
    -- 显示奖励预览
    local rewardId = self._Control:GetCurActivityTeachingShowRewardId()

    if XTool.IsNumberValid(rewardId) then
        local rewardGoodsList = XRewardManager.GetRewardList(rewardId)

        if not XTool.UObjIsNil(self.Grid256New) then
            XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
                ---@type XUiGridCommon
                local grid = XUiGridCommon.New(nil, go)
                grid:Refresh(rewardGoodsList[index])
            end)
        end
    end
    --初始化任务入口
    self.TaskBtnClick.CallBack = function() XLuaUiManager.OpenWithCloseCallback('UiWheelChairManualPopupTarget', handler(self, self.RefreshTasks)) end
end

function XUiPanelWheelChairManualTeaching:Refresh()
    self:RefreshStages()
    self:RefreshTasks()
end

function XUiPanelWheelChairManualTeaching:RefreshStages()
    if not XTool.IsTableEmpty(self._StageGrids) then
        for i, v in pairs(self._StageGrids) do
            v:RefreshState()
        end
    end
end

function XUiPanelWheelChairManualTeaching:RefreshTasks()
    -- 刷新下页签红点
    XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
    
    local taskIds = self._Control:GetCurActivityTeachTaskIds()
    if not XTool.IsTableEmpty(taskIds) then
        local taskList = XDataCenter.TaskManager.GetTaskIdListData(taskIds)

        if not XTool.IsTableEmpty(taskList) then
            local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
            self.TaskImgBar.fillAmount = passCount/allCount

            self.TaskBtnClick:SetButtonState(passCount >= allCount and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

            local hasTaskCanFinish = false
            ---@param v XTaskData
            for i, v in pairs(taskList) do
                if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                    hasTaskCanFinish = true
                end                
            end
            self.TaskBtnClick:ShowReddot(hasTaskCanFinish)
            return
        end
    end
    
    self.TaskImgBar.fillAmount = 0
    self.TaskBtnClick:SetButtonState(CS.UiButtonState.Normal)
    self.TaskBtnClick:ShowReddot(false)
end

return XUiPanelWheelChairManualTeaching