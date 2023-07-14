XReportManagerCreater = function()
    local XReportManager = {}

    local LastReportTime = -9999
    local ReportInterval = CS.XGame.Config:GetInt("ReportInterval")
    local ReportTimes = 0       --举报次数
    local LastReportTime = 0    --上次举报时间

    function XReportManager.Report(playerId, playerName, msg, playerLevel, chatContent, entry, tags, chatChannel)
        if not XReportManager.IsReqReport() then
            return
        end

        XNetwork.Call("ReportRequest", {
            PlayerId = playerId,            --被举报人ID
            PlayerName = playerName,        --被举报人名字
            Entry = entry,                  --入口ID
            Tags = tags,                    --ReportTag表的Id
            Message = msg,                  --举报人备注
            PlayerLevel = playerLevel,      --被举报人等级
            ReportMessage = chatContent,    --被举报信息
            ChatChannel = chatChannel,      --聊天频道ID
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("ReportFinish")
        end)
    end

    --举报公会
    function XReportManager.RequestReportGuild(guildId, entry, tags, reportMessage, message)
        if not XReportManager.IsReqReport() then
            return
        end

        XNetwork.Call("ReportGuildRequest", {
            GuildId = guildId,            --被举报公会ID
            Entry = entry,                  --入口ID
            Tags = tags,                    --ReportTag表的Id
            Message = message,                --举报人备注
            ReportMessage = reportMessage,    --被举报信息
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("ReportGuildFinish")
        end)
    end

    --登录下发数据
    function XReportManager.NotifyPlayerReportData(data)
        ReportTimes = data.ReportData.ReportTimes
        LastReportTime = data.ReportData.LastReportTime
        XEventManager.DispatchEvent(XEventId.EVENT_REPORT_NOTIFY)
    end

    function XReportManager.IsReqReport()
        if LastReportTime < 0 then
            LastReportTime = XPlayer.ReportTime
        end
        local now = XTime.GetServerNowTimestamp()
        if now - LastReportTime < ReportInterval then
            local tempTime = (ReportInterval - (now - LastReportTime))
            XUiManager.TipError(CS.XTextManager.GetText("ReportError", tostring(tempTime)))
            return false
        end
        return true
    end

    function XReportManager.GetReportTimes()
        return ReportTimes
    end

    function XReportManager.GetLastReportTime()
        return LastReportTime
    end

    return XReportManager
end

XRpc.NotifyPlayerReportData = function(data)
    XDataCenter.ReportManager.NotifyPlayerReportData(data)
end