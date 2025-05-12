---@class XDailyResetModel : XModel
local XDailyResetModel = XClass(XModel, "XDailyResetModel")
function XDailyResetModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._lastTimestamp = -1
    self._dayZero = -1
end

function XDailyResetModel:ClearPrivate()
    --这里执行内部数据清理
end

function XDailyResetModel:ResetAll()
    --这里执行重登数据清理
    self._lastTimestamp = -1
    self._dayZero = -1
end

----------public start----------
---获取当日的的0点时间戳
function XDailyResetModel:GetDayZero()
    local now = XTime.GetServerNowTimestamp()
    if self._lastTimestamp == now then
        return self._dayZero
    end

    self._lastTimestamp = now
    local dateTime = CS.XDateUtil.GetGameDateTime(now)
    self._dayZero = dateTime.Date:ToTimestamp()
    return self._dayZero
end

----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XDailyResetModel