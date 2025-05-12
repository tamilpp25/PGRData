---@class XLogUploadAgency : XAgency
---@field private _Model XLogUploadModel
local XLogUploadAgency = XClass(XAgency, "XUploadLogAgency")
local UploadAgreeSaveKey = "__UploadAgreeSaveKey__"
local LastUploadTimeSaveKey = "__LastUploadTimeSaveKey__"
local UPLOAD_TIME_LIMIT = 30 --30秒内不能重复上传
function XLogUploadAgency:OnInit()
    --初始化一些变量
    self._Uploader = false
    self._Setting = false
    self._IsLoginUpload = false
end


function XLogUploadAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XLogUploadAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end


function XLogUploadAgency:__InitUploader()
    if not self._Uploader then

        local result, ossBucket, ossEndPoint, folderType = self:__ParseOssUrl()
        if not result then
            XLog.Error(string.format("XRemoteConfig.LogUploadOssUrl 解析失败: %s", CS.XRemoteConfig.LogUploadOssUrl))
            return
        end

        local setting = CS.XLogPackageSetting()
        setting.LogDir = CS.XLog.LogDir
        setting.TempLogDir = string.format("%s/%s", CS.UnityEngine.Application.persistentDataPath, "tempLog")
        setting.OssEndPoint = ossEndPoint
        setting.OssBucket = ossBucket

        setting.RemoteKey = string.format("%s_%s", CS.XRemoteConfig.ApplicationVersion, folderType) --以版本号(_Dev _Prod)为目录, 如: 1.0.0_Prod
        setting.SingleSizeMax = 50 * 1024 * 1024
        setting.AllSizeMax = 50 * 1024 * 1024 * 10 --500M
        setting.TimeOut = 60
        --setting.UserId = XPlayer.UserId --这里重登可能需要做下更新

        self._Setting = setting
        self._Uploader = CS.XLogPackageUploader(self._Setting)

        self._ProgressCallback = handler(self, self._OnProgressHandler)
        self._OnCompleteCallback = handler(self, self._OnCompleteHandler)
    end
end

function XLogUploadAgency:__ParseOssUrl()
    local ossConfig = CS.XRemoteConfig.LogUploadOssUrl
    if string.IsNilOrEmpty(ossConfig) then
       return false
    end

    local ossBucket, ossEndPoint = ossConfig:match("([^%.]+)%.(.*)")
    if string.IsNilOrEmpty(ossBucket) then
       return false
    end

    local folderType = ossBucket:match("^[^-]+")
    if string.IsNilOrEmpty(folderType) then
        return false
    end

    folderType = folderType:gsub("^(%l)", string.upper)
    return true, ossBucket, ossEndPoint, folderType
end

----------public start----------
function XLogUploadAgency:IsAgreeUpload()
    return XSaveTool.GetData(UploadAgreeSaveKey)
end

function XLogUploadAgency:UpdateIsAgreeUpload()
    XSaveTool.SaveData(UploadAgreeSaveKey, not self:IsAgreeUpload())
end

function XLogUploadAgency:IsOpen()
    return true
end

---@return boolean 是否显示登录按钮
function XLogUploadAgency:ShowLoginBtn()
    local CSRemoteConfig = CS.XRemoteConfig
    --两个审核模式都不在 && 配置显示
    return not CSRemoteConfig.IsHideFunc and not CSRemoteConfig.IsHideFuncAndroid and CSRemoteConfig.IsShowLogUpload and not XUserManager.IsNeedLogin() and not XUserManager.HasLoginError()
end

function XLogUploadAgency:OpenLogUploadUi()
    self._IsLoginUpload = false
    XLuaUiManager.Open("UiLogUpload")
end

---从登录界面打开的, 由于重登并没有清理XPlayer.Id, 所以这时候无法判断是否登录进游戏了没有
function XLogUploadAgency:OpenLogUploadUiFromLogin()
    self._IsLoginUpload = true
    XLuaUiManager.Open("UiLogUpload")
end

---检查并开始上传
function XLogUploadAgency:CheckAndUpload()
    self:__InitUploader()
    if self._IsLoginUpload then
        self._Setting.UserId = XUserManager.UserId --每次调用赋值最新的玩家id
        self._Setting.RemoteDir = "Login"
    else
        self._Setting.UserId = XPlayer.Id --每次调用赋值最新的玩家id
        self._Setting.RemoteDir = "Game"
    end

    if not self:_CheckUploadTimeLimit() then
        XUiManager.TipText("LogUploadTimeLimit", XUiManager.UiTipType.Tip)
        return false
    end

    if not self._Uploader:StartUpload(self._ProgressCallback, self._OnCompleteCallback) then
        XUiManager.TipText("LogUploadNoNeed", XUiManager.UiTipType.Tip)
        return false
    end
    return true
end

function XLogUploadAgency:RetryUpload()
    self._Uploader:StartUpload(self._ProgressCallback, self._OnCompleteCallback)
end

----------public end----------

----------private start----------
function XLogUploadAgency:_CheckUploadTimeLimit()
    local lastTime = XSaveTool.GetData(LastUploadTimeSaveKey) or 0
    local curTime = XTime.GetLocalNowTimestamp()
    return math.abs(curTime - lastTime) > UPLOAD_TIME_LIMIT
end

function XLogUploadAgency:_UpdateLastUploadTime()
    XSaveTool.SaveData(LastUploadTimeSaveKey, XTime.GetLocalNowTimestamp())
end

function XLogUploadAgency:_OnProgressHandler(value)
    self:SendAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_PROGRESS, value)
end

function XLogUploadAgency:_OnCompleteHandler(code)
    self:SendAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_COMPLETE, code)
    if code == CS.XLogPackageUploadCode.SUCCESS then --上传成功, 更新上次的时间
        self:_UpdateLastUploadTime()
    end
end

----------private end----------

return XLogUploadAgency