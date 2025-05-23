local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")
local ResFileType = "matrix" --暂时只支持这个目录的更新
local PreloadIndexName = "preindex"
local IndexName = "index"

local TIMEOUT = 10 * 1000
local READ_TIMEOUT = 15 * 1000
local RETRY = 10

--CS层引用
local CsLog = CS.XLog
local CsInfo = CS.XInfo
local CsTool = CS.XTool
local CsApplication = CS.XApplication
local UnityApplication = CS.UnityEngine.Application
local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform
local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
local DownloadType = DOWNLOAD_SOURCE.PRELOAD

local DOWNLOADING = false

local SingleThread = 1 --单线程数量
local MultiThread = 5 --多线程数量

local State = XEnumConst.Preload.State
local CSXMTDownloadTaskGroupState = CS.XMTDownloadTaskGroupState
local XLaunchPreloadModuleCls = require("XLaunchPreloadModule")

---@class XPreloadAgency : XAgency
---@field private _Model XPreloadModel
local XPreloadAgency = XClass(XAgency, "XPreloadAgency")
function XPreloadAgency:OnInit()

    self.IsDlcBuild = CsInfo.IsDlcBuild

    ---@type XLaunchPreloadModule
    self._PreloadModule = XLaunchPreloadModuleCls()

    self._DocumentDirPath = nil --持久目录下存放热更新文件的目录, 即document
    --初始化一些变量
    self._PreloadDirPath = nil --预下载存储目录
    self._PreloadCdnUrl = nil --远程下载路径
    self._PreloadIndexUrl = nil --preloadIndex 预下载url

    self._LocalPreloadIndexPath = nil --本地存储的preloadIndex文件路径

    self._AllDownloadAssets = nil --所有下载资源列表
    self._AllDownloadCount = 0 --所有下载资源总数
    self._AllDownloadSize = 0 --所有下载资源大小
    self._AllDownloadSizeMB = 0 --所有下载资源大小, 转MB

    self._CurDownloadThreadCount = SingleThread --当前下载的线程数
    self._IsWaitChangeThread = false --是否等待线程数切换
    self._IsChangeThread = false --表示当前是否正在切换线程数量
    self._CurDownloader = nil --当前的下载器
    self._CurTaskGroup = nil --当前下载器的group
    self._CurDownloadSize = 0 --当前下载的资源大小
    self._CurProgressSize = 0 --正在下载的尺寸
    self._CurProgress = 0 --当前更新进度
    self._IsFixErrorDownload = false --是否正在处理下载失败文件
    self._TickTimer = 0 --用来间隔计算下载大小
    self._LastTickProgress = 0 --上一次计算速度的进度
    self._TickSpeed = 0 --用来显示速度的
    self._LeftDownloadTime = 0 --预计剩余下载时间

    self._StartTimer = 0 --开始时间, 用来埋点的
    self._PauseTimer = 0 --暂停时间

    self._NoticeHtmlContent = nil --公告内容
    self._CheckNetWork = false --检查网络情况
    self._AutoResumeDownload = false --网络切换太快，下载器还在暂停中，导致没办法正常回复需要在接受到暂停后再给它恢复下载

    self._StateMsg = {
        [State.IndexDownloadFail] = "PreloadIndexDownloadFail",
        [State.PreIndexLoadFail] = "PreloadPreIndexLoadFail",
        [State.PreloadDisable] = "PreloadDisable",
        [State.None] = "PreloadNone",
        [State.Start] = "PreloadStart",
        [State.CheckIndex] = "PreloadCheckIndex",
        [State.ResolveIndex] = "PreloadResolveIndex",
        [State.Downloading] = "PreloadDownloading",
        [State.Pausing] = "PreloadPausing",
        [State.Pause] = "PreloadPause",
        [State.Complete] = "PreloadComplete",
    }

    self._State = State.None
    self._ErrorDialog = false --标记结束战斗后要弹错误提示框
    self:InitPreloadConfig()
    self._OnNetworkReachabilityChangedCb = handler(self, self.OnNetworkReachabilityChanged)
    self._OnExitFightCb = handler(self, self.OnExitFight)
    self._OnDownloadStateUpdate = handler(self, self.DownloadStateUpdate)
    self._OnDownloadProgressUpdate = handler(self, self.DownloadProgressUpdate)
    self._ProgressTimer = nil
    self._DownloadEnable = false --该时机是否可以下载
end

---下载完成清理所有数据
function XPreloadAgency:ClearAllDownload()
    self._AllDownloadAssets = nil --所有下载资源列表
    if self._CurDownloader then
        self._CurDownloader = nil --当前的下载器
        self._CurTaskGroup.NotifyStateChanged = nil
        self._CurTaskGroup.NotifyProgressChanged = nil
        self._CurTaskGroup = nil
    end
end

---设置是否自动恢复下载
function XPreloadAgency:SetAutoResume(value)
    self._CheckNetWork = value
end

function XPreloadAgency:OnRelease()
    --本地一键重登需要做释放兼容
end

function XPreloadAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XPreloadAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
    self._DownloadEnable = true
    CS.XNetworkReachability.AddListener(self._OnNetworkReachabilityChangedCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self.OnLoginUiOpenHandler, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, self.OnMainUiEnableHandler, self)

    if self._CurTaskGroup and self._CurTaskGroup.State == CSXMTDownloadTaskGroupState.Downloading then --这里是断线重连回到登录界面可能导致的
        self:RemoveProgressTimer()
        self:AddProgressTimer()
    end
end

function XPreloadAgency:RemoveEvent()
    CS.XNetworkReachability.RemoveListener(self._OnNetworkReachabilityChangedCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self.OnLoginUiOpenHandler, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, self.OnMainUiEnableHandler, self)
end

----------public start----------
function XPreloadAgency:OpenRecord()
    CS.XRecord.Record("88801", "PreloadOpen")
end

function XPreloadAgency:GetDownloadingTip()
    if self._State == State.Downloading then
        return XUiHelper.GetText("PreloadScrollTip")
    elseif self._State == State.Pause then
        return XUiHelper.GetText("PreloadPauseScrollTip")
    elseif self:CheckHasNewPreload() then
        return XUiHelper.GetText("PreloadHasScrollTip")
    end
end

---获取状态的信息
---@return string
function XPreloadAgency:GetStateMessage(state)
    if self._StateMsg[state] then
        local textKey = self._StateMsg[state]
        return XUiHelper.GetText(textKey)
    end
    return ""
end

---返回当前状态
function XPreloadAgency:GetCurState()
    return self._State
end

---返回当前状态信息
function XPreloadAgency:GetCurStateMessage()
    return self:GetStateMessage(self._State)
end

function XPreloadAgency:TestMovePreFiles(onProgress, onComplete)
    if self._PreloadModule then
        --CSPlayerPrefs.SetString(self._PreloadModule.PrefKeys.PreloadIndexKey, "2.8.2")
        --CSPlayerPrefs.Save()
        self._PreloadModule.Check(ResFileType, self._DocumentDirPath .. "/" .. ResFileType .. "/", self._Model:GetPreloadVersion(), onProgress, onComplete)
        --self._PreloadModule.Check(ResFileType, self._DocumentDirPath .. "/" .. ResFileType .. "/", "2.8.2", onProgress, onComplete)
    end
end

---返回是否正在修复下载失败的文件
function XPreloadAgency:GetIsFixErrorDownload()
    return self._IsFixErrorDownload
end

function XPreloadAgency:GetTickSpeed()
    return self._TickSpeed
end

function XPreloadAgency:GetLeftDownloadTime()
    return self._LeftDownloadTime
end

function XPreloadAgency:GetAllDownloadSize()
    return self._AllDownloadSize
end

function XPreloadAgency:GetAllDownloadSizeMB()
    return self._AllDownloadSizeMB
end

function XPreloadAgency:GetLocalDocVersion()
    return self._Model:GetLocalDocVersion()
end

function XPreloadAgency:GetPreloadVersion()
    return self._Model:GetPreloadVersion()
end


function XPreloadAgency:SetIsPause(value)
    if self._State < State.Downloading or self._State == State.Complete then --下载中或者完成了不能再暂停
        XLog.Debug("[Preload] 当前无法设置暂停状态")
        return
    end

    if value then --需要暂停
        if self._State == State.Downloading then
            self:PauseDownload()
            self:RecordPauseStatus(1)
        end
    else
        if self._State == State.Pause then
            self:ResumeDownload()
            self:RecordPauseStatus(0)
        end
    end
end

function XPreloadAgency:GetRecordDict()
    local dict = {}
    dict.time = self:CostTimer()
    if self._CurTaskGroup then
        dict.file_count = self._CurTaskGroup:GetFinishedTaskCount()
    else
        dict.file_count = 0
    end
    dict.file_size = self._CurDownloadSize
    return dict
end

--暂停状态切换埋点
function XPreloadAgency:RecordPauseStatus(isPause)
    local dict = self:GetRecordDict()
    dict.is_pause = isPause
    CS.XRecord.Record(dict, "88806", "PreloadPauseChange")
end

---设置是否多线程下载
---@return boolean 返回是否允许切换
function XPreloadAgency:SetIsMultiThread(value, notShowTip)
    --self._State < State.Downloading or 现在没下载也可以先设置多线程了
    if self._State == State.Complete then --下载中或者完成了不能再暂停
        if not notShowTip then
            XLog.Debug("[Preload] 当前无法切换线程下载")
        end
        return false
    end

    local threadCount = value and MultiThread or SingleThread
    if threadCount == self._CurDownloadThreadCount then
        if not notShowTip then
            XLog.Debug("[Preload] 当前线程数相同, 无需切换")
        end
        return false
    end

    --if value and self._State ~= State.Downloading then --切换到多线程只能在下载状态的时候才可用
    --    if not notShowTip then
    --        XLog.Debug("[Preload] 当前无法切换多线程数下载")
    --    end
    --    return false
    --end

    if threadCount ~= self._CurDownloadThreadCount then
        self._IsChangeThread = true
        self._CurDownloadThreadCount = threadCount
        if self._CurDownloader then
            self._CurDownloader:SetThreadNumber(threadCount)
        end

        if not self._IsWaitChangeThread then
            self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_MUlTI_THREAD_CHANGE) --这里不等待就直接抛出去
        end

        local dict = {}
        dict.is_multi = self:GetIsMultiThread() and 1 or 0
        CS.XRecord.Record(dict, "88807", "PreloadMultiThreadChange")

        return true
    end
    return false
end

function XPreloadAgency:ResetMultiThread()
    if self._CurDownloadThreadCount ~= SingleThread then
        self._CurDownloadThreadCount = SingleThread
        self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_MUlTI_THREAD_CHANGE)
    end
end

---返回是否正在多线程下载(暂时不用, 因为现在不在下载状态也可以切换线程了)
---@return boolean
function XPreloadAgency:GetIsMultiThreadDownloading()
    if self._State == State.Downloading then
        return self._CurDownloadThreadCount == MultiThread
    end
    return false
end

---返回现在设置的是否是多线程
---@return boolean
function XPreloadAgency:GetIsMultiThread()
    return self._CurDownloadThreadCount == MultiThread
end

---返回是否正在切换多线程
function XPreloadAgency:GetIsChangeMultiThread()
    if self._State == State.Downloading then
        if self._IsWaitChangeThread then
            return self._CurDownloader:GetCurrentRunningTaskNumber() ~= self._CurDownloadThreadCount
        end
    end
    return false
end

function XPreloadAgency:IsComplete()
    local preloadVersion = self._Model:GetPreloadVersion()
    local preloadCompleteVersion = self._Model:GetLocalPreloadCompleteVersion()
    return preloadVersion == preloadCompleteVersion
end

function XPreloadAgency:GetCurProgress()
    return self._CurProgress
end

---初始化远程配置
function XPreloadAgency:InitPreloadConfig()
    local preloadEnable = CS.XRemoteConfig.PreloadEnable
    local preloadBaseVersion = CS.XRemoteConfig.PreloadBaseVersion
    local preloadVersion = CS.XRemoteConfig.PreloadVersion
    local preloadSha = CS.XRemoteConfig.PreloadSha
    local preloadSize = CS.XRemoteConfig.PreloadSize
    self._Model:InitLocalConfig()
    self._Model:InitRemoteConfig(preloadEnable, preloadBaseVersion, preloadVersion, preloadSha, preloadSize)
    self:InitPath()
end

function XPreloadAgency:CheckAndStart()
    if self._State > State.None then
        CsLog.Debug("[Preload] 当前状态不能开始")
        return false
    end
    local result = self:CheckPreload(true, true)
    if result ~= XEnumConst.Preload.CheckCode.None then
        CsLog.Debug("[Preload] 预下载不允许:" .. tostring(result))
        self:SetStatus(State.PreloadDisable)
        return false
    end

    self._CheckNetWork = CS.XNetworkReachability.IsViaLocalArea() --如果当前是wifi环境, 就需要检查网络变化

    self:SetStatus(State.Start)
    self._StartTimer = os.time()
    self:CheckPreloadIndex()

    local dict = {}
    dict.is_multi = self:GetIsMultiThread() and 1 or 0
    CS.XRecord.Record(dict, "88802", "PreloadStart") --预下载开始埋点
    return true
end

---检测是否可以预下载
---@param showLog boolean 是否有输出
---@param checkComplete boolean 是否检查已完成
function XPreloadAgency:CheckPreload(showLog, checkComplete)
    if not self:PlatformEnable() then
        if showLog then
            CsLog.Debug("XPreloadAgency:CheckPreload 设备平台不支持预下载")
        end
        return XEnumConst.Preload.CheckCode.Disable
    end

    if not self:CheckChannelEnable() then
        if showLog then
            CsLog.Debug("XPreloadAgency:CheckPreload 对应渠道没有开启预下载功能")
        end
        return XEnumConst.Preload.CheckCode.Disable
    end

    if not self._Model:GetPreloadEnable() then --没有开启预下载
        if showLog then
            CsLog.Debug("XPreloadAgency:CheckPreload 未开启预下载功能")
        end
        return XEnumConst.Preload.CheckCode.Disable
    end

    if checkComplete and self:IsComplete() then
        if showLog then
            local preloadCompleteVersion = self._Model:GetLocalPreloadCompleteVersion()
            CsLog.Debug(string.format("XPreloadAgency:CheckPreload 当前预下载版本: %s 已完成", preloadCompleteVersion))
        end
        return XEnumConst.Preload.CheckCode.Complete
    end

    if self._Model:GetCompareVersionsResult() >= 0 then
        if showLog then
            local curDocumentVersion = self._Model:GetLocalDocVersion()
            local curPreloadVersion = self._Model:GetPreloadVersion()
            CsLog.Debug(string.format("XPreloadAgency:CheckPreload 预下载版本号过期: %s , 当前版本号: %s", curPreloadVersion, curDocumentVersion))
        end
        return XEnumConst.Preload.CheckCode.Expire --过期的版本号
    end

    return XEnumConst.Preload.CheckCode.None
end

---检查渠道是否开放下载
function XPreloadAgency:CheckChannelEnable()
    local openChannels =  CS.XRemoteConfig.PreloadAppChannel --字符串, 直接判断是否包含在里面
    if string.IsNilOrEmpty(openChannels) then
        return true
    end

    local channelId = CS.XHeroSdkAgent.GetAppChannelId()
    if string.IsNilOrEmpty(channelId) then
        return false
    end
    return string.find(openChannels, channelId)
end

---检查是否有新的预下载
function XPreloadAgency:CheckHasNewPreload()
    if self:CheckPreload(false, true) == XEnumConst.Preload.CheckCode.None then
        return self._Model:GetLocalPreloadRedPoint() ~= self._Model:GetPreloadVersion() --版本号对不上就需要展示红点
    end
    return false
end

---是否显示入口
function XPreloadAgency:CheckShowPreloadEntry()
    return self:CheckPreload(false, false) == XEnumConst.Preload.CheckCode.None
end

---保存红点标记
function XPreloadAgency:CancelRedPoint()
    self._Model:SavePreloadRedPoint()
    self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_RED_POINT_UPDATE)
end

---检测preloadIndex是否需要下载
function XPreloadAgency:CheckPreloadIndex()
    self:SetStatus(State.CheckIndex)
    local curIndexVersion = self._Model:GetLocalPreloadIndexVersion()
    local preloadIndexVersion = self._Model:GetPreloadVersion()
    local downloadIndex = false
    if curIndexVersion ~= preloadIndexVersion then --前后两次预下载的index文件不一样, 需要清理index文件
        downloadIndex = true
        self._Model:ClearPreloadAll()
        if CS.System.IO.File.Exists(self._LocalPreloadIndexPath) then --如果文件存在直接清理掉
            CS.XFileTool.DeleteFile(self._LocalPreloadIndexPath)
        end
    else --如果相等的话要校验一下sha值
        if CS.System.IO.File.Exists(self._LocalPreloadIndexPath) then
            local sha1 = self._Model:GetPreloadSha()
            local isCorrect = CS.XFileTool.CheckSha1(self._LocalPreloadIndexPath, sha1)
            if not isCorrect then --不相等要干掉
                downloadIndex = true
                self._Model:ClearPreloadAll()
                CS.XFileTool.DeleteFile(self._LocalPreloadIndexPath)
            end
        else
            downloadIndex = true
        end
    end

    if downloadIndex then --需要下载preloadIndex
        self:DownloadPreloadIndex()
    else
        self:ResolvePreloadIndex() --无需下载index直接解析
    end
end

---下载预下载index文件
function XPreloadAgency:DownloadPreloadIndex()
    local preloadVersion = self._Model:GetPreloadVersion()
    local indexUrl = self._PreloadCdnUrl .. "/" .. preloadVersion .. "/" .. ResFileType .. "/" .. PreloadIndexName
    local sha1 = self._Model:GetPreloadSha()
    local size = self._Model:GetPreloadSize()
    local downloader = CS.XUriPrefixDownloader.CreateBySource(DownloadType, indexUrl, self._LocalPreloadIndexPath, false, sha1, size, TIMEOUT, RETRY, READ_TIMEOUT)
    CsTool.WaitCoroutine(downloader:Send(), function()
        if downloader.State ~= CS.XDownloaderState.Success then
            self:SetStatus(State.IndexDownloadFail) --下载index失败
            local dict = {}
            dict.file = PreloadIndexName
            CS.XRecord.Record(dict, "88804", "PreloadDownloadFail") --下载index文件失败
            CsLog.Error("[Preload] 下载preindex文件失败")
        else
            self._Model:SavePreloadVersion() --下载完成保存记录
            self:ResolvePreloadIndex()
        end
    end)

end

function XPreloadAgency:ParseAssetMap(assetTab)
    local assetMap = {}
    for _, info in pairs(assetTab) do
        assetMap[info[1]] = info
    end
    return assetMap
end

---解析index文件
--- {[assetPath] = value{[1] = Name, [2] = Sha1, [3] = Size}, ... }
function XPreloadAgency:ResolvePreloadIndex()
    self:SetStatus(State.ResolveIndex)

    local preAssetTable, preDlcAssetTable = self:LoadIndexBundle(self._LocalPreloadIndexPath)
    if not preAssetTable or not preDlcAssetTable then
        self:SetStatus(State.PreIndexLoadFail) --加载preindex失败弹窗
        CsLog.Error("[Preload] 解析preindex index失败")
        return
    end

    --与本地的index文件进行对比过滤
    local allDownloadCount = 0
    local dlcDownloadCount = 0
    local allDownloadSize = 0
    local dlcDownloadSize = 0
    local allDownloadAssets = {} --记录所有的预下载资源
    local dlcDownloadAssets = {} --dlc单独记录, 后续好做分析

    local preAssetMapTab = self:ParseAssetMap(preAssetTable)
    for name, info in pairs(preAssetMapTab) do
        if not allDownloadAssets[name] then
            allDownloadAssets[name] = info
            allDownloadCount = allDownloadCount + 1
            allDownloadSize = allDownloadSize + info[3]
        end
    end

    local hasDlcData = true
    local dlcIds = self._Model:GetLocalPreloadDlcIds()
    if not dlcIds then
        hasDlcData = false
        dlcIds = {}
    end

    if CS.XInfo.IsDlcBuild then
        local subPackageAgency = XMVCA.XSubPackage
        for dlcId, dlcTable in pairs(preDlcAssetTable) do --遍历所有的dlc
            local needDownload = false --表示这个dlc是否需要下载
            if hasDlcData then
                needDownload = dlcIds[dlcId]
            else
                needDownload = subPackageAgency:CheckSubpackageComplete(dlcId) --如果分包功能没开启或者该分包有下载
                if needDownload then
                    dlcIds[dlcId] = true --标记起来
                end
            end
            if needDownload then
                local preDlcMap = self:ParseAssetMap(dlcTable)
                for name, info in pairs(preDlcMap) do
                    if not allDownloadAssets[name] then
                        allDownloadAssets[name] = info
                        dlcDownloadAssets[name] = info
                        dlcDownloadCount = dlcDownloadCount + 1
                        allDownloadCount = allDownloadCount + 1
                        allDownloadSize = allDownloadSize + info[3]
                        dlcDownloadSize = dlcDownloadSize + info[3]
                    end
                end
            end
        end
    end

    if not hasDlcData then --记录起来, 下次就不用再获取了
        self._Model:SetLocalPreloadDlcIds(dlcIds)
        self._Model:SavePreloadDlcIds()
    end

    --处理document目录里的一下载文件
    local docFiles = CS.XFileTool.GetFiles(self._DocumentDirPath .. "/" .. ResFileType)
    for i = 0, docFiles.Count - 1 do
        local file = docFiles[i]
        local name = CS.XFileTool.GetFileName(file)
        local info = allDownloadAssets[name]
        if info then
            allDownloadAssets[name] = nil
            allDownloadCount = allDownloadCount - 1
            allDownloadSize = allDownloadSize - info[3]

            if dlcDownloadAssets[name] then
                dlcDownloadAssets[name] = nil
                dlcDownloadCount = dlcDownloadCount - 1
                dlcDownloadSize = dlcDownloadSize - info[3]
            end
        end
    end


    local preFiles = CS.XFileTool.GetFiles(self._PreloadDirPath .. "/" .. ResFileType)
    for i = 0, preFiles.Count - 1 do
        local file = preFiles[i]
        local name = CS.XFileTool.GetFileName(file)
        local isIndex = name == PreloadIndexName --跳过preloadIndex
        if isIndex then
            goto CONTINUE
        end

        local info = allDownloadAssets[name]
        if info then
            allDownloadAssets[name] = nil
            allDownloadCount = allDownloadCount - 1
            allDownloadSize = allDownloadSize - info[3]

            if dlcDownloadAssets[name] then
                dlcDownloadAssets[name] = nil
                dlcDownloadCount = dlcDownloadCount - 1
                dlcDownloadSize = dlcDownloadSize - info[3]
            end
            goto CONTINUE
        end

        local nameWithOutExt = CS.XFileTool.GetFileNameWithoutExtension(file)
        if allDownloadAssets[nameWithOutExt] then --保留下载文件, download后缀
            goto CONTINUE
        end

        CS.XFileTool.DeleteFile(file)
        CsLog.Debug("[Preload] .. clean file: " .. file)
        :: CONTINUE ::
    end

    self._AllDownloadAssets = allDownloadAssets
    self._AllDownloadCount = allDownloadCount
    self._AllDownloadSize = allDownloadSize
    self._AllDownloadSizeMB = allDownloadSize / 1024 / 1024

    CsLog.Debug(string.format("[Preload] 预下载资源总数: %s (%sMB), 其中分包资源数量: %s (%sMB)", allDownloadCount, math.floor(allDownloadSize / 1024 / 1024), dlcDownloadCount, math.floor(dlcDownloadSize / 1024 / 1024)))
    --无需解析本地包体里有没有, preloadIndex已经过滤下个版本进包的资源了

    self:StartDownload()
end

--开始下载
function XPreloadAgency:StartDownload()
    if self._AllDownloadCount <= 0 then
        CsLog.Debug("[Preload] 预下载数量为0, 跳过预下载")
        self:PreloadComplete()
        return
    end
    self:SetStatus(State.Downloading)
    self:MultiThreadDownload()
end

--暂停下载
function XPreloadAgency:PauseDownload()
    self:SetStatus(State.Pausing)
    if self._CurDownloader then
        self._CurDownloader:PauseAll()
    end
end

--恢复下载
function XPreloadAgency:ResumeDownload()
    self._CheckNetWork = CS.XNetworkReachability.IsViaLocalArea() --重新检测网络状态
    self:ResumeTimer() --剔除暂停时间
    self:SetStatus(State.Downloading)
    if self._CurDownloader then
        local state = self._CurTaskGroup.State
        if state == CSXMTDownloadTaskGroupState.CompleteError then
            self._CurDownloader:SetFailedTaskGroupMethod(1) --重试
        else
            self._CurDownloader:StartAll()
        end
    end
end

--预下载完成
function XPreloadAgency:PreloadComplete()
    self._TickSpeed = 0
    self._LeftDownloadTime = 0
    self._CurProgress = 1
    self._IsFixErrorDownload = false
    self._CheckNetWork = false
    self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_PROCESS) --抛出多一次, 就整界面展示数据

    self._Model:SavePreloadCompleteVersion()
    self:SetStatus(State.Complete)
    local dict = self:GetRecordDict() --先计算一下, 后续会被清理掉

    self:ResetMultiThread()
    self:ClearAllDownload()

    local costTime = self:CostTimer()
    CsLog.Debug(string.format("[Preload] 预下载完成, 耗时: %s 秒", tostring(costTime)))
    CS.XRecord.Record(dict, "88803", "PreloadComplete") --预下载完成埋点
end

function XPreloadAgency:Print()
    if self._CurDownloader then
        XLog.Debug(self._CurDownloader:Info())
        XLog.Debug("TaskStack.Count: " .. tostring(self._CurTaskGroup.TaskStack.Count))

        local nodeInfo = ""
        for _, node in pairs(self._CurDownloader.RunningList) do
            nodeInfo = nodeInfo .. node.ResourceName .. ":" .. node.CurrentSize .. "/" .. node.CheckSize .. " State: " .. tostring(node.State) .. "\n"
        end
        XLog.Debug("nodeInfo: " .. nodeInfo)
    end
end

--多线程下载
function XPreloadAgency:MultiThreadDownload()
    --重置各种状态
    self._CurDownloadSize = 0
    self._CurProgress = 0
    self._TickTimer = 0
    self._TickSpeed = 0
    self._LeftDownloadTime = 0
    self._LastTickProgress = 0
    self._IsFixErrorDownload = false
    --self._CurDownloadThreadCount = SingleThread --开始的时候是单线程的(不在只是单线程了)
    self._AutoResumeDownload = false

    local preloadVersion = self._Model:GetPreloadVersion()

    self._CurDownloader = CS.XMTDownloadCenter()
    self._CurDownloader:SetThreadNumber(self._CurDownloadThreadCount) --先设置一次线程数量
    self._CurTaskGroup = CS.XMTDownloadTaskGroup(1)
    self._CurTaskGroup.NotifyStateChanged = self._OnDownloadStateUpdate
    --self._CurTaskGroup.NotifyProgressChanged = self._OnDownloadProgressUpdate --使用定时器

    for name, info in pairs(self._AllDownloadAssets) do
        local url = string.format("%s/%s/%s/%s", self._PreloadCdnUrl, preloadVersion, ResFileType, name)
        local path = self._PreloadDirPath .. "/" .. ResFileType .. "/" .. name
        local sha1 = info[2]
        local fileSize = info[3]
        self._CurTaskGroup:AddTask(url, path, fileSize, sha1)
    end
    self._CurDownloader:RegisterTaskGroup(self._CurTaskGroup)
    self._CurDownloader:Run()

    if self._DownloadEnable then
        self._CurDownloader:StartAll()
    else
        self:SetStatus(State.Pause) --不给下就先暂停
    end
end

function XPreloadAgency:AddProgressTimer()
    if not self._ProgressTimer then
        self._ProgressTimer = XScheduleManager.ScheduleForever(self._OnDownloadProgressUpdate, 200, 0)
    end
end

function XPreloadAgency:RemoveProgressTimer()
    if self._ProgressTimer then
        XScheduleManager.UnSchedule(self._ProgressTimer)
        self._ProgressTimer = nil
    end
end

function XPreloadAgency:DownloadStateUpdate()
    local state = self._CurTaskGroup.State
    XLog.Error("下载器刷新: " .. tostring(state))
    if state == CSXMTDownloadTaskGroupState.Registered then --暂停后会回到这个状态
        self:RemoveProgressTimer()
        self:CheckPauseStatus()
    elseif state == CSXMTDownloadTaskGroupState.Downloading then --下载中
        self:AddProgressTimer()
    elseif state == CSXMTDownloadTaskGroupState.Complete then --下载完成
        self:RemoveProgressTimer()
        self:PreloadComplete()
    elseif state == CSXMTDownloadTaskGroupState.CompleteError then --下载完成但是存在失败文件
        self:RemoveProgressTimer()
        self:PreloadCompleteWithError()
    end
end

function XPreloadAgency:DownloadProgressUpdate()
    self:CheckMultiThreadChange() --策划说不做等待
    self:CheckDownloadProgress()
end

--检查是否切换暂停状态
function XPreloadAgency:CheckPauseStatus()
    if self._State == State.Pausing then --如果当前正在暂停中
        self:SetPauseTimer()
        self:SetStatus(State.Pause)

        --这里检测是否是因为网络状态切换触发的暂停
        if self._CheckNetWork and self:GetIsMultiThread() then --全速下载是不能自己暂停的
            self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_NETWORK_CHANGE_PAUSE) --网络问题导致需要暂停
        end
        if self._AutoResumeDownload then --这里又要给恢复回去
            self._AutoResumeDownload = false
            self:SetIsPause(false)
        end
    end
end

function XPreloadAgency:CheckDownloadProgress()
    self._CurDownloadSize = self._CurTaskGroup.DownloadedBytes
    local updateProgress = self._CurDownloadSize / self._AllDownloadSize
    local callEvent = false
    if updateProgress ~= self._CurProgress then
        callEvent = true
        if updateProgress > self._CurProgress then
            self._CurProgress = updateProgress
            self._IsFixErrorDownload = false
        else --小于或者等于都是在修复下载失败文件导致回退的情况
            self._IsFixErrorDownload = true
        end
    end

    if self:TickSpeed() then
        callEvent = true
    end

    if callEvent then
        --计算速度及剩余时间
        self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_PROCESS)
    end
end

--检测线程数是否变化
function XPreloadAgency:CheckMultiThreadChange()
    if self._IsChangeThread and self._IsWaitChangeThread then
        if self._CurDownloader:GetCurrentRunningTaskNumber() == self._CurDownloadThreadCount then
            --相等的证明线程切换完成了
            self._IsChangeThread = false
            self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_MUlTI_THREAD_CHANGE)
        end
    end
end

---下载完成了但是有下载失败的
function XPreloadAgency:PreloadCompleteWithError()
    --local msg = "[Preload] error, state error,  name: " .. tostring(name) .. " state: " .. tostring(self._CurDownloader.State)
    --XLog.Error(msg)
    self:ErrorPause()

    --收集下载失败的文件
    --local dict = {}
    --local files = {}
    --dict.files = files
    --for _, v in pairs(self._CurTaskGroup.FailedTaskQueue) do
    --    table.insert(files, v.ResourceName)
    --end
    --CS.XRecord.Record(dict, "88804", "PreloadDownloadFail")
end

function XPreloadAgency:ShowErrorDialog()
    if CS.XFightInterface.IsOutFight then
        self._ErrorDialog = false
        local content = XUiHelper.GetText("PreloadErrorTip")
        CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), content, function()
            XLog.Debug("发生下载错误, 不继续下载")
        end, function()
            self:ErrorRetry()
        end))
    else
        self._ErrorDialog = true
    end
end

function XPreloadAgency:ErrorRetry()
    self:SetIsPause(false)
end

--下载失败强制暂停
function XPreloadAgency:ErrorPause()
    self:SetPauseTimer()
    self:SetStatus(State.Pause)
    self:ShowErrorDialog()
end

function XPreloadAgency:TickSpeed()
    local now = CS.UnityEngine.Time.time
    if now - self._TickTimer > 1 then --一秒计算一次
        self._TickTimer = now
        self._TickSpeed = (self._CurProgress - self._LastTickProgress) * self._AllDownloadSize
        if self._TickSpeed > 0 then
            self._LeftDownloadTime = math.ceil((1 - self._CurProgress) * self._AllDownloadSize / self._TickSpeed) --单位秒
        else
            self._TickSpeed = 0
            self._LeftDownloadTime = 0
        end
        self._LastTickProgress = self._CurProgress
        return true
    end
    return false
end

---获取预下载公告
function XPreloadAgency:GetPreloadNotice()
    return self._NoticeHtmlContent
end

function XPreloadAgency:RequestNotice()
    local notice = XDataCenter.NoticeManager.GetPreloadNotice()
    if notice then
        local url = notice.Content[1].Url
        local request = CS.XUriPrefixRequest.Get(url)
        CsTool.WaitCoroutine(request:SendWebRequest(), function()
            if request.isNetworkError or request.isHttpError then
                return
            end
            local content = request.downloadHandler.text

            if string.IsNilOrEmpty(content) then
                return
            end

            request:Dispose()

            local html = XHtmlHandler.Deserialize(content)
            if not html then
                XLog.Error("html deserialize error, html is empty! " .. url)
                return
            end
            self._NoticeHtmlContent = html
            self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_NOTICE_UPDATE)
        end)
    end
end



----------public end----------

----------private start----------

function XPreloadAgency:OnLoginUiOpenHandler()
    self._DownloadEnable = false
    if self._State == State.Downloading then
        self:SetIsMultiThread(false, true) --切换到单线程
        self:SetIsPause(true) --暂停下载
        self:SetAutoResume(false) --自动恢复下载也不要了
    end
end

function XPreloadAgency:OnMainUiEnableHandler()
    if self._State == State.Downloading and self:GetIsMultiThread() then --在下载同时是多线程的
        self:SetIsMultiThread(false, true)
        --XLog.Error("回到主界面, 取消多线程")
    end
end

function XPreloadAgency:OnExitFight()
    if self._ErrorDialog then
        self:ShowErrorDialog()
    end
end

function XPreloadAgency:OnNetworkReachabilityChanged()
    local isWifi = CS.XNetworkReachability.IsViaLocalArea()
    if isWifi then
        if self._CheckNetWork then --需要检查网络的才恢复
            if self._State == State.Pausing then
                --暂停中的无法立马切换下载器
                self._AutoResumeDownload = true
            elseif self._State == State.Pause then
                self:SetIsPause(false)
            end
        else
            if self._State == State.Downloading then
                self._CheckNetWork = true --如果切换到wifi了, 这时候是正在下载, 下次就得给它做网络切换检查, 策划需求
            end
        end
    else
        if self._CheckNetWork or CS.XNetworkReachability.IsNotReachable() then --如果需要检查网络或者是没有网络了都暂停
            self._AutoResumeDownload = false
            if self._State == State.Downloading then
                self:SetIsPause(true)
            end
        end
    end
end

function XPreloadAgency:SetPauseTimer()
    self._TickSpeed = 0
    self._LeftDownloadTime = 0
    self._PauseTimer = os.time()
end

function XPreloadAgency:ResumeTimer()
    local pausePassTime = os.time() - self._PauseTimer --暂停所话的时间
    self._StartTimer = self._StartTimer + pausePassTime --加上暂停的时间, 到时候与当前时间相减, 就相当于剔除了暂停的时间
end

function XPreloadAgency:CostTimer()
    return os.time() - self._StartTimer
end

---设置当前状态
function XPreloadAgency:SetStatus(state)
    local oldState = self._State

    if oldState == state then
        XLog.Debug(string.format("[Preload] SetStatus 状态一致, 无需设置: %s [%s]", self._State, self:GetStateMessage(self._State)))
    end

    self._State = state
    if oldState == State.Downloading or state == State.Downloading then --如果其中一个是从下载状态切换过来的, 需要刷新scroll
        self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_DOWNLOAD_STATE)
    end
    XLog.Debug(string.format("当前预下载状态: %s [%s]", self._State, self:GetStateMessage(self._State)))
    self:SendAgencyEvent(XAgencyEventId.EVENT_PRELOAD_STATE_UPDATE, self._State)
end

function XPreloadAgency:LoadIndexBundle(indexPath)
    local assetBundle = CS.UnityEngine.AssetBundle.LoadFromFile(indexPath)
    if (assetBundle and assetBundle:Exist()) then
        local assetName = assetBundle:GetAllAssetNames()[0]
        local asset = assetBundle:LoadAsset(assetName, typeof(CS.UnityEngine.TextAsset))
        local indexFile = XMessagePack.Decode(asset.bytes)
        local indexTable = indexFile[1]
        local dlcIndexTable = indexFile[2] or {}
        assetBundle:Unload(true)
        return indexTable, dlcIndexTable
    end
    return nil
end

---@return boolean 返回平台是否支持预下载功能
function XPreloadAgency:PlatformEnable()
    return UnityApplication.platform == CS.UnityEngine.RuntimePlatform.Android or
            UnityApplication.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer or
            XMain.IsWindowsEditor
end

---初始化一些路径, 比如本地保存路径, 远程cdn路径
function XPreloadAgency:InitPath()
    self._DocumentDirPath = UnityApplication.persistentDataPath .. "/document"

    self._PreloadDirPath = UnityApplication.persistentDataPath .. "/preload"
    self._LocalPreloadIndexPath = self._PreloadDirPath .. "/" .. ResFileType .. "/" .. PreloadIndexName

    if UnityApplication.platform == UnityRuntimePlatform.Android then
        self._PreloadCdnUrl = "client/patch/" .. CS.XInfo.Identifier .. "/" .. self._Model:GetPreloadBaseVersion() .. "/android"
    elseif UnityApplication.platform == UnityRuntimePlatform.IPhonePlayer then
        self._PreloadCdnUrl = "client/patch/" .. CS.XInfo.Identifier .. "/" .. self._Model:GetPreloadBaseVersion() .. "/ios"
    elseif UnityApplication.platform == UnityRuntimePlatform.WindowsEditor then
        self._PreloadCdnUrl = "client/patch/" .. CS.XInfo.Identifier .. "/" .. self._Model:GetPreloadBaseVersion() .. "/android"
    elseif UnityApplication.platform == UnityRuntimePlatform.WindowsPlayer then
        self._PreloadCdnUrl = "client/patch/" .. CS.XInfo.Identifier .. "/" .. self._Model:GetPreloadBaseVersion() .. "/standalone"
    end
end

---清理本地所有的预下载记录
function XPreloadAgency:ClearPreloadHistory()
    if self._State > State.None and self._State < State.Complete then
        XLog.Debug("[Preload] 当前状态不允许清理")
        return
    end
    --清理整个预下载目录
    CS.XFileTool.DeleteDirectory(self._PreloadDirPath, true)
    self._Model:ClearPreloadAll()
    self:SetStatus(State.None)
end

function XPreloadAgency:OnRelease()
    self._DownloadEnable = false
    if self._State == State.Downloading then --释放的暂停, 这只在开发模式才会触发
        self:SetIsMultiThread(false, true)
        self:SetIsPause(true)
        self:RemoveProgressTimer()
    end
end

----------private end----------

return XPreloadAgency