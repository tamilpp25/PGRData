-- 错误信息收集和日志文件上传
XUploadLogManagerCreator = function()
    local XUploadLogManager = {}

    local MASK_UPLOAD_LOG = "UploadLog"

    local ErrorUrl = ""
    local LogUrl = ""
    local NeedUploadError = false
    local NeedUploadLog = false
    local FullLogId -- 用于后台生成文件名
    local UPLOAD_LOG_DAY = 1 -- 规定上传多少天内日志
    
    function XUploadLogManager.Init()
        XUploadLogManager.InitConfig()
        XUploadLogManager.InitErrorUploader()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, XUploadLogManager.InitLogUploader)
    end

    function XUploadLogManager.InitConfig()
        local UploadLogUrl = CS.XRemoteConfig.UploadLogUrl
        if (UploadLogUrl and UploadLogUrl ~= "") then
            local strs = string.Split(UploadLogUrl, "|")
            local url = strs[1]

            UPLOAD_LOG_DAY = tonumber(strs[3]) or 0

            ErrorUrl = url .. "/client_error/"
            LogUrl = url .. "/client_log/"
            NeedUploadError = strs[2] == "1"
            NeedUploadLog = UPLOAD_LOG_DAY > 0
        else
            NeedUploadError = false
            NeedUploadLog = false
        end
    end

    function XUploadLogManager.InitErrorUploader()
        CS.XLogUploader:GetInstance().NeedUploadLog = NeedUploadError
        CS.XLogUploader:GetInstance().LOG_HTTP = ErrorUrl
    end

    function XUploadLogManager.InitLogUploader()
        FullLogId = tostring(XPlayer.Id)
        CS.XFullLogUploader:GetInstance():SetId(FullLogId)
        CS.XFullLogUploader:GetInstance().NeedUploadLog = NeedUploadLog
        CS.XFullLogUploader:GetInstance().LOG_HTTP = LogUrl
    end

    -- 主动上传本地日志
    -- day 几天内
    -- extraParam 额外参数
    function  XUploadLogManager.UplodaFullLog(day, extraParam)
        if not FullLogId or FullLogId == "" then
            XLog.Error("FullLogId invalid : " .. tostring(FullLogId))
            return
        end

        day = day or UPLOAD_LOG_DAY
        if not day or day <= 0 then
            XLog.Error("upload full log with invalid day " .. tostring(day))
            return
        end

       extraParam = extraParam or ""
       XLuaUiManager.SetAnimationMask(MASK_UPLOAD_LOG, true, 0)
        CS.XFullLogUploader:GetInstance():Upload(day, function() 
            XLog.Debug("finish Upload Log!!!")
            XLuaUiManager.SetAnimationMask(MASK_UPLOAD_LOG, false)
        end, extraParam)
    end

    XUploadLogManager.Init()
    return XUploadLogManager
end