---@class XRhythmGameAgency : XAgency
---@field private _Model XRhythmGameModel
local XRhythmGameAgency = XClass(XAgency, "XRhythmGameAgency")
function XRhythmGameAgency:OnInit()
    --初始化一些变量
end

function XRhythmGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XRhythmGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XRhythmGameAgency:EnterGame(...)
    XLuaUiManager.Open("UiRhythmGameTaikoPlay", ...)
end

function XRhythmGameAgency:RecordEnterMapCache(mapId)
    local key = XPlayer.Id.."RhythmGameEnterMapCache"..mapId
    XSaveTool.SaveData(key, true)
end

function XRhythmGameAgency:CheckHasRecordEnterMapCache(mapId)
    local key = XPlayer.Id.."RhythmGameEnterMapCache"..mapId
    return XSaveTool.GetData(key)
end

function XRhythmGameAgency:OpenEntrance(rhythmGameControlId, ...)
    local controlConfig = self:GetModeltRhythmGameControl()[rhythmGameControlId]
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

    XLuaUiManager.Open("UiRhythmGamePopupChoose", rhythmGameControlId, ...)
end

function XRhythmGameAgency:GetModeltRhythmGameControl()
    return self._Model:GetRhythmGameControl()
end

return XRhythmGameAgency