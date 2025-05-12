---@class XMusicGameActivityControl : XControl
---@field private _Model XMusicGameActivityModel
local XMusicGameActivityControl = XClass(XControl, "XMusicGameActivityControl")
function XMusicGameActivityControl:OnInit()
    --初始化内部变量
end

function XMusicGameActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMusicGameActivityControl:RemoveAgencyEvent()

end

function XMusicGameActivityControl:OnRelease()
end

function XMusicGameActivityControl:GetActivityEndTime()
    if not XTool.IsNumberValid(self._Model.ActivityId) then
        return 0
    end

    local timeId = self._Model:GetMusicGameActivity()[self._Model.ActivityId].TimeId
    return XFunctionManager.GetEndTimeByTimeId(timeId) or 0
end

function XMusicGameActivityControl:IsCanPopVolumeTip()
    local musicVolume = CS.XAudioManager.GetMusicVolume()
    local isMute = CS.XAudioManager.CheckIsMute()
    if musicVolume > 0 and not isMute then
        return false
    end

    local data = XSaveTool.GetData("MusicGameActivityToggleChoose")
    if data and data.NextCanShowTimeStamp and XTime.GetServerNowTimestamp() < data.NextCanShowTimeStamp then
        return false
    end
    return true
end

function XMusicGameActivityControl:SetIsToggleChoose(flag)
    XSaveTool.SaveData("MusicGameActivityToggleChoose", {Flag = flag, NextCanShowTimeStamp = XTime.GetSeverTomorrowFreshTime()})
end

function XMusicGameActivityControl:MusicGameArrangementRequest(gameMusicId, selectionIds, cb)
    XNetwork.Call("MusicGameArrangementRequest", { MusicId = gameMusicId, SelectionIds = selectionIds }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:RefreshServerData(res)

        if cb then
            cb()
        end
    end)
end

function XMusicGameActivityControl:MusicGameFinishRhythmRequest(mapId, cb)
    XNetwork.Call("MusicGameFinishRhythmRequest", { MapId = mapId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:RefreshServerData(res)

        if cb then
            cb()
        end
    end)
end

return XMusicGameActivityControl