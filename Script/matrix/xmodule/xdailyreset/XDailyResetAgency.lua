---@class XDailyResetAgency : XAgency
---@field private _Model XDailyResetModel
local XDailyResetAgency = XClass(XAgency, "XDailyResetAgency")
function XDailyResetAgency:OnInit()
    --初始化一些变量
    self._DailyResetRedPoints = false
end

function XDailyResetAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDailyReset = Handler(self, self._OnNotifyDailyReset)
end

function XDailyResetAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XDailyResetAgency:RemoveEvent()
end

----------public start----------
---检查每日重置的红点是否开启
---@param key string 红点保存key
function XDailyResetAgency:CheckDailyRedPoint(key)
    local saveDayZero = XSaveTool.GetData(key) or 0
    return self._Model:GetDayZero() > saveDayZero
end

---保存最新的每日重置红点
---@param key string 红点保存key
---@param playerKey boolean 是否包含玩家id
function XDailyResetAgency:SaveDailyRedPoint(key)
    XSaveTool.SaveData(key, self._Model:GetDayZero())
end

function XDailyResetAgency:IsDailyResetRedPoint(key)
    return self:_GetDailyResetRedPoints()[key]
end

----------public end----------

----------private start----------
function XDailyResetAgency:_GetDailyResetRedPoints()
    if not self._DailyResetRedPoints then
        self._DailyResetRedPoints = {}
        self._DailyResetRedPoints[XRedPointConditions.Types.CONDITION_DAILY_RESET] = true
    end
    return self._DailyResetRedPoints
end


function XDailyResetAgency:_OnNotifyDailyReset()
    XEventManager.DispatchEvent(XEventId.EVENT_DAILY_RESET)
end
----------private end----------

return XDailyResetAgency