local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")
---@class XSameColorAgency : XFubenSimulationChallengeAgency
---@field private _Model XSameColorModel
local XSameColorAgency = XClass(XFubenSimulationChallengeAgency, "XSameColorAgency")
function XSameColorAgency:OnInit()
    --初始化一些变量
    XMVCA.XFubenEx:RegisterChapterAgency(self)
end

function XSameColorAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XSameColorAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 副本扩展

function XSameColorAgency:ExGetChapterType()
    return XDataCenter.FubenManager.ChapterType.SameColor
end

function XSameColorAgency:ExGetProgressTip()
    local all, cur = 0, 0
    for _, taskType in pairs(XEnumConst.SAME_COLOR_GAME.TASK_TYPE) do
        local datas = self._Model:GetTaskData(taskType)
        for _, taskData in pairs(datas) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
                cur = cur + 1
            end
            all = all + 1
        end
    end
    if all > 0 then
        return XUiHelper.GetText("SameColorGameTaskProgress", math.floor(cur / all * 100))
    end
    return XUiHelper.GetText("SameColorGameTaskProgress", 0)
end

function XSameColorAgency:ExCheckIsShowRedPoint()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SameColor) then
        return false
    end
    --活动开启
    if not XSaveTool.GetData(string.format("SameColorGameOpen_%s", XPlayer.Id)) then
        return true
    end
    --存在可领取任务
    return self:CheckTaskRedPoint()
end

--endregion

--region RedPoint
function XSameColorAgency:CheckTaskRedPoint(taskType)
    local taskList = {}
    if taskType == nil then
        taskList = appendArray(self:GetTaskData(XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY)
        , self:GetTaskData(XEnumConst.SAME_COLOR_GAME.TASK_TYPE.REWARD))
    else
        taskList = self:GetTaskData(taskType)
    end
    for _, taskData in pairs(taskList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
end
--endregion

--region Data
function XSameColorAgency:GetTaskData(taskType)
    return self._Model:GetTaskData(taskType)
end
--endregion

--region Cfg - ClientConfig
function XSameColorAgency:GetClientCfgStringValue(key, index)
    return self._Model:GetClientCfgStringValue(key, index)
end

function XSameColorAgency:GetClientCfgValue(key)
    return self._Model:GetClientCfgValue(key)
end
--endregion

--region 引导

-- 这里表现和数据没分离 只能先这么拿
function XSameColorAgency:HasPropBall()
    ---@type XUiSameColorGameBattle
    local panel = XLuaUiManager.GetTopLuaUi("UiSameColorGameBattle")
    if panel and panel.BoardPanel then
        return panel.BoardPanel:HasPropBall()
    end
    return false
end

function XSameColorAgency:HasWeakBall()
    ---@type XUiSameColorGameBattle
    local panel = XLuaUiManager.GetTopLuaUi("UiSameColorGameBattle")
    if panel and panel.BoardPanel then
        return panel.BoardPanel:HasWeakBall()
    end
    return false
end

--endregion

return XSameColorAgency