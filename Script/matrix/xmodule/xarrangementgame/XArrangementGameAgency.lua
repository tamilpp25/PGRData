---@class XArrangementGameAgency : XAgency
---@field private _Model XArrangementGameModel
local XArrangementGameAgency = XClass(XAgency, "XArrangementGameAgency")
function XArrangementGameAgency:OnInit()
    --初始化一些变量
end

function XArrangementGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XArrangementGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XArrangementGameAgency:GetModelArrangementGameMusic()
    return self._Model:GetArrangementGameMusic()
end

function XArrangementGameAgency:GetModelArrangementGameControl()
    return self._Model:GetArrangementGameControl()
end

function XArrangementGameAgency:OpenUi(arrangementGameControlId, finishCb, ...)
    local controlConfig = self:GetModelArrangementGameControl()[arrangementGameControlId]
    if XTool.IsNumberValid(controlConfig.Condition) then
        local res, desc = XConditionManager.CheckCondition(controlConfig.Condition)
        if not res then
            XUiManager.TipMsg(desc)
            return
        end
    end

    if controlConfig.TimeId then
        if not XFunctionManager.CheckInTimeByTimeId(controlConfig.TimeId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("ActivityBranchNotOpen")) --"不在活动时间"
            return
        end
    end
    
    XLuaUiManager.Open("UiArrangementGameMain", arrangementGameControlId, finishCb, ...)
end

return XArrangementGameAgency