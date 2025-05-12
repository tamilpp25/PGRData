---@class XLeftTimeAgency : XAgency
---@field private _Model XLeftTimeModel
local XLeftTimeAgency = XClass(XAgency, "XLeftTimeAgency")
function XLeftTimeAgency:OnInit()
    --初始化一些变量
end

function XLeftTimeAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XLeftTimeAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 提供的倒计时函数 
function XLeftTimeAgency:GetRegression3rd()
    local viewModel = XDataCenter.Regression3rdManager.GetViewModel()
    local res = XUiHelper.GetTime(viewModel:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY)
    return res
end

function XLeftTimeAgency:GetBirthday()
    return XMVCA.XBirthdayPlot:GetLeftTime()
end

function XLeftTimeAgency:GetByTimeIdAndTimeFormatType(timeId, timeFormatType)
    timeFormatType = timeFormatType or XUiHelper.TimeFormatType.ACTIVITY
    if not XTool.IsNumberValid(timeId)  then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local timeStr = XUiHelper.GetTime(endTime - nowTime, timeFormatType)
    return timeStr
end

function XLeftTimeAgency:GetByTimeIdCommon(timeId)
    return self:GetByTimeIdAndTimeFormatType(timeId, XUiHelper.TimeFormatType.ACTIVITY)
end

function XLeftTimeAgency:GetAccumulateDraw()
    return XMVCA.XAccumulateExpend:GetTimeStr()
end

function XLeftTimeAgency:GetWheelchairManualLeftTime()
    local hasLeftTime, leftTime = XMVCA.XWheelchairManual:GetLeftTime()

    if hasLeftTime then
        return XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    end
    return ''
end

function XLeftTimeAgency:GetReCall(timeId)
    return self:GetByTimeIdAndTimeFormatType(timeId, XUiHelper.TimeFormatType.RECALL)
end

--endregion

----------public start----------
function XLeftTimeAgency:GetLeftTimeByFunName(name, ...)
    local fun = self[name]
    return fun(self, ...)
end
----------public end----------

----------private start----------


----------private end----------

return XLeftTimeAgency