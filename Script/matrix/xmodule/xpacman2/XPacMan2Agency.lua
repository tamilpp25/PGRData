local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPacMan2Agency : XAgency
---@field private _Model XPacMan2Model
local XPacMan2Agency = XClass(XFubenActivityAgency, "XPacMan2Agency")
function XPacMan2Agency:OnInit()
    self:RegisterActivityAgency()
end

function XPacMan2Agency:InitRpc()
    XRpc.NotifyPacMan2Activity = Handler(self, self.NotifyPacMan2Activity)
end

function XPacMan2Agency:OpenMain()
    ---@type XTablePacMan2Activity
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    local timeId = activityConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    XLuaUiManager.Open("UiPacMan2Main")
    return true
end

function XPacMan2Agency:NotifyPacMan2Activity(data)
    self._Model:SetDataFromServer(data)
end

function XPacMan2Agency:PacMan2StageStartRequest(stageId, callback)
    if self._Model.IsPlaying then
        XLog.Error("[XPacMan2Agency] playing状态出错, 很麻烦")
        callback(false)
        return
    end
    XNetwork.Call("PacMan2StageStartRequest", {
        StageId = stageId
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            callback(false)
            return
        end
        self._Model.IsPlaying = true
        callback(true)
    end)
end

function XPacMan2Agency:PacMan2SettleRequest(data)
    if not self._Model.IsPlaying then
        XLog.Warning("[XPacMan2Agency] 未开始游戏")
        return
    end
    XNetwork.Call("PacMan2SettleRequest", data, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetStageData(res.StageData)
        self._Model.IsPlaying = false
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
    end)
end

function XPacMan2Agency:ExCheckInTime()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local isInTime = XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId)
    return isInTime
end

return XPacMan2Agency