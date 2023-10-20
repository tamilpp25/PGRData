---@class XSubPackageAgency : XAgency
---@field private _Model XSubPackageModel
---@field private _DownloadQueue number[] 分包下载Id列表
---@field private _LaunchDlcManager XLaunchDlcManager 下载管理器
---@field private _DownloadCenter XMTDownloadCenter 多线程下载器
local XSubPackageAgency = XClass(XAgency, "XSubPackageAgency")

local MIN_SIZE = 1024

local CheckStageId = 10030304

local LaunchTestPath = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalCdn"
local LaunchTestDirApp = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalDirApp"
local LaunchTestDirDoc = CS.UnityEngine.Application.dataPath .. "/../../../Product/Temp/LocalDirDoc"

local SingleThreadCount = 1 --单线程线程数
local MultiThreadCount = 5 --多线程线程数

--分包下载源
local DownloadType = DOWNLOAD_SOURCE.SUBPACKAGE

local CsXApplication = CS.XApplication

function XSubPackageAgency:OnInit()

    self._DownloadQueue = {}

    self._IsDownloading = false
    self._DownloadPackageId = 0
    self._IsDownloadGroup = false --是否为一组同时下载
    self._PreparePauseId = 0 --准备暂停的Id
    self._IsPause = false

    self._ThreadCount = SingleThreadCount --线程数

    self._OnPreEnterFightCb = handler(self, self.OnPreEnterFight)
    self._OnExitFightCb = handler(self, self.OnExitFight)
    self._OnNetworkReachabilityChangedCb = handler(self, self.OnNetworkReachabilityChanged)
    self._OnLoginSuccessCb = handler(self, self.OnLoginSuccess)
    self._OnSingleTaskFinishCb = handler(self, self.OnSingleTaskFinish)

    self._LaunchDlcManager = require("XLaunchDlcManager")

    self._SubIndexInfo = self._LaunchDlcManager.GetIndexInfo()

    self._TipDialog = false

    self._ErrorSubpackageId = nil
    --是否需要测试
    self._IsNeedLaunchTest = CS.XResourceManager.NeedLaunchTest

    self._DocumentUrl = self._LaunchDlcManager.GetPathModule().GetDocumentUrl()

    self._DocumentVersion = self._LaunchDlcManager.GetVersionModule().GetNewDocVersion()

    self._DocumentFilePath = self._LaunchDlcManager.GetPathModule().GetDocumentFilePath()

    self._DownloadCenter = nil

    self._RecordRegisterGroup = {} --记录已经注册的Group, 不想一股脑全部注册
end

function XSubPackageAgency:InitRpc()

end

function XSubPackageAgency:AfterInitManager()
    self:ResolveResIndex()
end

function XSubPackageAgency:InitEvent()
    --进入战斗
    XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self._OnPreEnterFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._OnPreEnterFightCb)

    --退出战斗
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)

    --单个文件下载完毕
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_MT_DOWNLOAD_SINGLE_TASK_FINISH, self._OnSingleTaskFinishCb)

    --网络状态改变
    CS.XNetworkReachability.AddListener(self._OnNetworkReachabilityChangedCb)

    --主界面可以操作
    XEventManager.AddEventListener(XEventId.EVENT_FIRST_ENTER_UI_MAIN, self._OnLoginSuccessCb)
end

function XSubPackageAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self._OnPreEnterFightCb)

    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._OnPreEnterFightCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)

    --单个文件下载完毕
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_MT_DOWNLOAD_SINGLE_TASK_FINISH, self._OnSingleTaskFinishCb)

    CS.XNetworkReachability.RemoveListener(self._OnNetworkReachabilityChangedCb)

    XEventManager.RemoveEventListener(XEventId.EVENT_FIRST_ENTER_UI_MAIN, self._OnLoginSuccessCb)

end

function XSubPackageAgency:IsOpen()
    return self._Model:IsOpen()
end

function XSubPackageAgency:OpenUiMain(groupId)
    if not self:IsOpen() then
        return
    end

    XLuaUiManager.Open("UiDownLoadMain", groupId)
end

--- 转换单位
---@param size number 文件大小，对应字节byte
---@return number, string 文件大小，对应单位
--------------------------
function XSubPackageAgency:TransformSize(size)
    local unit = "B"
    local num = size
    if num >= MIN_SIZE then
        unit = "KB"
        num = num / MIN_SIZE
    end

    if num >= MIN_SIZE then
        unit = "MB"
        num = num / MIN_SIZE
    end

    return math.ceil(num), unit
end

function XSubPackageAgency:MergeTable(src, dst)
    src = src or {}
    dst = dst or {}
    for k, v in pairs(dst) do
        if not src[k] then
            src[k] = v
        end
    end
    return src
end

function XSubPackageAgency:GetSubpackageTotalSize(subpackageId)
    local size = 0
    local indexInfo = self._SubIndexInfo[subpackageId]
    if not indexInfo then
        local str = string.format("分包 SubpackageId = %s 不存在IndexInfo", subpackageId)
        XLog.Warning(str)
        return 0
    end

    for assetPath, info in pairs(indexInfo) do
        size = size + info[3]
    end

    return size
end

--已经下载的大小
function XSubPackageAgency:GetSubpackageDownloadSize(subpackageId)
    local indexInfo = self._SubIndexInfo[subpackageId]
    if not indexInfo then
        local str = string.format("分包 SubpackageId = %s 不存在IndexInfo", subpackageId)
        XLog.Warning(str)
        return 0
    end

    local size = 0
    for assetPath, info in pairs(indexInfo) do
        if self._LaunchDlcManager.IsNameDownloaded(info[1]) then
            size = size + info[3]
        end
    end

    return size
end

--添加到下载队列
function XSubPackageAgency:AddToDownload(subpackageId)
    if not self:IsOpen() then
        return
    end
    if not self._DownloadQueue then
        self._DownloadQueue = {}
    end
    if self._IsDownloading and self._DownloadPackageId == subpackageId then
        return
    end
    for _, id in ipairs(self._DownloadQueue) do
        if id == subpackageId then
            return
        end
    end
    table.insert(self._DownloadQueue, subpackageId)
    self._Model:GetSubpackageItem(subpackageId):PrepareDownload()

    if not self._IsDownloading and not self._IsShowingWifiTip then
        self:StartDownload()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

--开始下载
function XSubPackageAgency:StartDownload()
    --没有需要下载的了
    if XTool.IsTableEmpty(self._DownloadQueue) then
        return
    end
    local isWifi = CS.XNetworkReachability.IsViaLocalArea()
    --wifi or 已经弹过提示
    if isWifi or self._TipDialog then
        self:DoDownload()
        return
    end

    if self._IsShowingWifiTip then
        return
    end
    self._IsShowingWifiTip = true
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DlcDownloadWIFIText"), nil, function()
        self:PauseAll()
        self._IsShowingWifiTip = false
    end, function()
        self._IsShowingWifiTip = false
        self._TipDialog = true
        self:DoDownload()
    end)
end

--执行下载逻辑
function XSubPackageAgency:DoDownload()
    if not self:IsOpen() then
        return
    end
    if XTool.IsTableEmpty(self._DownloadQueue) or self._IsDownloading then
        return
    end
    local index = 1
    local subpackageId = self._DownloadQueue[index]
    table.remove(self._DownloadQueue, index)
    self._DownloadPackageId = subpackageId
    self._IsDownloading = true

    --更新状态
    self._Model:GetSubpackageItem(subpackageId):StartDownload()
    --恢复下载状态
    self._IsPause = false
    --开始下载
    self:MultiThreadDownload(subpackageId)
    --事件通知
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_START, subpackageId)
end

--标记为暂停状态
function XSubPackageAgency:PauseDownload(subpackageId)
    self._Model:GetSubpackageItem(subpackageId):PreparePause()
    self._IsPause = true
    self._DownloadCenter:PauseById(subpackageId)
    --等待暂停
    self._PreparePauseId = subpackageId
    --事件通知
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

--暂停队列中的所有下载
function XSubPackageAgency:PauseAll()
    if not self:IsOpen() then
        return
    end
    if self._IsDownloading and XTool.IsNumberValid(self._DownloadPackageId) then
        self:PauseDownload(self._DownloadPackageId)
    end
    local queue = self._DownloadQueue or {}
    for _, subId in pairs(queue) do
        local item = self._Model:GetSubpackageItem(subId)
        item:InitState()
    end
    self._DownloadQueue = {}
    self:ChangeThread(true, true)
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)
end

--释放下载器
function XSubPackageAgency:OnDownloadRelease()
    if not self:IsOpen() then
        return
    end
    --将当前下载的
    if self._DownloadCenter then
        self._DownloadCenter:SetFailedTaskGroupMethod(2)
    end
    if XTool.IsNumberValid(self._PreparePauseId) then
        local item = self._Model:GetSubpackageItem(self._PreparePauseId)
        item:Pause()
        self._TipDialog = false

        XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PAUSE, self._PreparePauseId)
    end
    --下载队列为空了
    if XTool.IsTableEmpty(self._DownloadQueue) then
        --切换为单线程下载
        self:ChangeThread(true)
    end
    self._IsDownloading = false
    self._IsDownloadGroup = false
    self._DownloadPackageId = 0
    self._PreparePauseId = 0
    self._Downloader = nil

    self:StartDownload()
end

--处理等待中
function XSubPackageAgency:ProcessPrepare(subpackageId)
    if not self:IsOpen() then
        return
    end
    --等到暂停结束
    if self:IsPreparePause() and self._PreparePauseId == subpackageId then
        return
    end
    local index
    --从下载队列里移除
    for idx, subId in pairs(self._DownloadQueue) do
        if subId == subpackageId then
            index = idx
            break
        end
    end
    if index then
        table.remove(self._DownloadQueue, index)
    end
    local item = self._Model:GetSubpackageItem(subpackageId)
    item:InitState()

    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

--单个分包下载完毕
function XSubPackageAgency:OnComplete()
    self._IsDownloading = false
    local id = self._DownloadPackageId
    self._CompleteIdCache = id
    self._DownloadPackageId = 0

    XUiManager.PopupLeftTip(XUiHelper.GetText("DlcDownloadCompleteTitle"), self._Model:GetSubPackageName(id))
    local item = self._Model:GetSubpackageItem(id)
    item:Complete()
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)

    if not self.IsSyncScene and self:CheckNecessaryComplete() then
        self.IsSyncScene = true
        XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)
    end

    --埋点
    self:DoRecordComplete(id)
end

function XSubPackageAgency:OnProgressUpdate(progress)
    local item = self._Model:GetSubpackageItem(self._DownloadPackageId)
    if item then
        item:UpdateMaxProgress(progress)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, self._DownloadPackageId, progress)
end

function XSubPackageAgency:ResolveResIndex()
    if not self:IsOpen() then
        return
    end
    if self._IsResolve then
        return
    end
    for subpackageId, indexInfo in pairs(self._SubIndexInfo) do
        if not XTool.IsNumberValid(subpackageId) then
            goto continue
        end
        local item = self._Model:GetSubpackageItem(subpackageId)
        if not item then
            goto continue
        end
        for assetPath, info in pairs(indexInfo) do
            item:InitFileInfo(assetPath, info)
        end
        item:FileInitComplete()
        :: continue ::
    end
    self._IsResolve = true
end

--多线程下载
function XSubPackageAgency:MultiThreadDownload(subpackageId)
    local item = self._Model:GetSubpackageItem(subpackageId)
    if not item then
        return
    end
    self:InitDownloader()
    self._DownloadCenter:StartById(subpackageId)
end

function XSubPackageAgency:InitDownloader()
    if not self._DownloadCenter then
        self._DownloadCenter = CS.XMTDownloadCenter()
        self._DownloadCenter:SetThreadNumber(self._ThreadCount)
        local groupIds = self._Model:GetGroupIdList()
        for _, groupId in ipairs(groupIds) do
            local group = self._Model:GetGroupTemplate(groupId)
            for _, subpackageId in ipairs(group.SubPackageId) do
                local item = self._Model:GetSubpackageItem(subpackageId)
                if item and not item:IsComplete() then
                    local taskGroup = item:GetTaskGroup()
                    taskGroup.NotifyStateChanged = handler(self, self.OnStateChanged)
                    taskGroup.NotifyProgressChanged = handler(self, self.OnProgressUpdate)
                    self._DownloadCenter:RegisterTaskGroup(taskGroup)
                end
            end
        end
    end

    self._DownloadCenter:Run()
end

function XSubPackageAgency:GetSavePath(fileName)
    if self._IsNeedLaunchTest then
        return string.format("%s/%s/%s", LaunchTestDirDoc, RES_FILE_TYPE.MATRIX_FILE, fileName)
    end
    return string.format("%s/%s/%s", self._DocumentFilePath, RES_FILE_TYPE.MATRIX_FILE, fileName)
end

function XSubPackageAgency:GetUrlPath(fileName)
    
    return string.format("%s/%s", self:GetUrlPrefix(), fileName)
end

function XSubPackageAgency:GetUrlPrefix()
    if self._UrlPrefix then
        return self._UrlPrefix
    end
    if self._IsNeedLaunchTest then
        self._UrlPrefix = string.format("%s/%s/%s", "client/patch/com.kurogame.haru.internal.debug.subpack/1.0.0/android", CS.XRemoteConfig.DocumentVersion, RES_FILE_TYPE.MATRIX_FILE)
        return self._UrlPrefix
    end
    self._UrlPrefix = string.format("%s/%s/%s", self._DocumentUrl, CS.XRemoteConfig.DocumentVersion, RES_FILE_TYPE.MATRIX_FILE)
    
    return self._UrlPrefix
end

function XSubPackageAgency:ChangeThread(isSingle, isForce)
    if not self._IsDownloading and not isForce then
        return
    end
    local count = isSingle and SingleThreadCount or MultiThreadCount
    if count == self._ThreadCount and not isForce then
        return
    end
    self._ThreadCount = count
    if self._DownloadCenter then
        self._DownloadCenter:SetThreadNumber(self._ThreadCount)
    end

    if isSingle and self._IsDownloading then
        XUiManager.TipText("QuitFullDownloadTip")
    end

    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_MULTI_COUNT_CHANGED)
end

function XSubPackageAgency:IsMultiThread()
    if not self._IsDownloading then
        return false
    end
    return self._ThreadCount == MultiThreadCount
end

--正在切换线程数量
function XSubPackageAgency:IsChangingThread()
    if not self._IsDownloading then
        return false
    end

    if not self._DownloadCenter then
        return false
    end
    return self._DownloadCenter:GetCurrentRunningTaskNumber() ~= self._ThreadCount
end

function XSubPackageAgency:IsDownloading()
    return self._IsDownloading
end

function XSubPackageAgency:OnStateChanged(subpackageId, state)
    local item = self._Model:GetSubpackageItem(subpackageId)
    if item then
        item:OnStateChanged(state)
    end
end

---判断分包是否下载完成
---@return boolean
function XSubPackageAgency:CheckSubpackageComplete(subpackageId)
    if not self:IsOpen() then
        return true
    end

    --无需下载
    if subpackageId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID then
        return true
    elseif subpackageId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY then --检测必要资源
        return self:CheckNecessaryComplete()
    end

    local item = self._Model:GetSubpackageItem(subpackageId)
    if not item then
        return true
    end

    --当前分包未下载完
    if not item:IsComplete() then
        return false
    end
    local complete = true
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    local bindIds = template.BindSubIds
    if XTool.IsTableEmpty(bindIds) then
        return complete
    end
    --检查当前分包绑定的分包是否下载完毕
    for _, bindId in ipairs(bindIds) do
        local item = self._Model:GetSubpackageItem(bindId)
        if item and not item:IsComplete() then
            complete = false
            break
        end
    end

    return complete
end

-- 检查必要资源是否下载完毕
function XSubPackageAgency:CheckNecessaryComplete()
    if not self:IsOpen() then
        return true
    end
    local complete = true
    local necessaryIds = self._Model:GetNecessarySubIds()
    for _, subpackageId in ipairs(necessaryIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if item and not item:IsComplete() then
            complete = false
            break
        end
    end
    return complete
end

function XSubPackageAgency:CheckAllComplete()
    if not self:IsOpen() then
        return true
    end
    local complete = true
    local groupIds = self._Model:GetGroupIdList()
    for _, groupId in pairs(groupIds) do
        local template = self._Model:GetGroupTemplate(groupId)
        for _, subpackageId in ipairs(template.SubPackageId) do
            local item = self._Model:GetSubpackageItem(subpackageId)
            if not item:IsComplete() then
                complete = false
                break
            end
        end
        if not complete then
            break
        end
    end

    return complete
end

function XSubPackageAgency:CheckSubpackage(enterType, param)
    if not self:IsOpen() then
        return true
    end
    local subId = self._Model:GetEntrySubpackageId(enterType, param)
    --需要拦截，并且未下载必要资源
    if not self:CheckSubpackageComplete(subId) then
        self:DoRecordIntercept(enterType, param)
        XLuaUiManager.Open("UiDownloadPreview")
        return false
    end
    return true
end

function XSubPackageAgency:CheckSubpackageByCvType(cvType)
    local isComplete = self:CheckCvDownload(cvType)
    if not isComplete then
        local subpackageIds = self._Model:GetAllSubpackageIds(XEnumConst.SUBPACKAGE.ENTRY_TYPE.CHARACTER_VOICE, cvType)
        if not XTool.IsTableEmpty(subpackageIds) then
            XLuaUiManager.Open("UiDownloadPreview", subpackageIds)
        else
            isComplete = true
        end
    end
    return isComplete
end

function XSubPackageAgency:CheckCvDownload(cvType)
    if not self:IsOpen() then
        return true
    end

    local subId = self._Model:GetEntrySubpackageId(XEnumConst.SUBPACKAGE.ENTRY_TYPE.CHARACTER_VOICE, cvType)
    return self:CheckSubpackageComplete(subId)
end

function XSubPackageAgency:DownloadAllByGroup(groupId)
    if not self:IsOpen() then
        return
    end
    local template = self._Model:GetGroupTemplate(groupId)
    local subIds = template.SubPackageId
    local downloading = {}
    for _, subId in pairs(self._DownloadQueue) do
        downloading[subId] = subId
    end
    local need = {}
    for _, subId in ipairs(subIds) do
        --没在正在下载的列表
        if not downloading[subId] then
            local item = self._Model:GetSubpackageItem(subId)
            --未下载完
            if not item:IsComplete() then
                table.insert(need, subId)
            end
        end
    end

    table.sort(need, function(a, b)
        return a < b
    end)
    for _, subId in ipairs(need) do
        self:AddToDownload(subId)
    end
    self._IsDownloadGroup = true
end

function XSubPackageAgency:IsNecessaryGroup(groupId)
    local template = self._Model:GetGroupTemplate(groupId)
    local subIds = template and template.SubPackageId or {}
    local subId = subIds[1]
    if not XTool.IsNumberValid(subId) then
        return false
    end
    local subT = self._Model:GetSubpackageTemplate(subId)
    return subT.Type == XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.NECESSARY
end

---@return string
function XSubPackageAgency:GetDownloadingTip()
    if not self:IsOpen() then
        return
    end
    if not self._IsDownloading and not XTool.IsNumberValid(self._CompleteIdCache) then
        return
    end
    local id
    if self._IsDownloading then
        id = self._DownloadPackageId
        return XUiHelper.GetText("DlcDownloadingItemText", self._Model:GetSubPackageName(id))
    else
        id = self._CompleteIdCache
        self._CompleteIdCache = nil
        return XUiHelper.GetText("DlcItemCompleteText", self._Model:GetSubPackageName(id))
    end
end

function XSubPackageAgency:GetWifiAutoState(groupId)
    if self:IsNecessaryGroup(groupId) then
        return self._LaunchDlcManager.IsSelectWifiAutoDownload()
    end
    return self._Model:GetWifiAutoSelect(groupId)
end

function XSubPackageAgency:SetWifiAutoState(groupId, value)
    if self:IsNecessaryGroup(groupId) then
        self._LaunchDlcManager.SetSelectWifiAutoDownloadValue(value)
    else
        self._Model:SaveWifiAutoSelect(groupId, value)
    end

    self:OnNetworkReachabilityChanged()
end

function XSubPackageAgency:OnPreEnterFight()

end

function XSubPackageAgency:OnExitFight()
    if not self._ErrorSubpackageId then
        return
    end
    self:ErrorDialog("FileManagerInitFileTableInGameDownloadError", nil, function()
        self:AddToDownload(self._ErrorSubpackageId)
        self._ErrorSubpackageId = nil
    end, nil, CsXApplication.GetText("Retry"))

end

function XSubPackageAgency:MarkErrorDialogOnFight(subpackageId)
    self:PauseAll()
    self._ErrorSubpackageId = subpackageId
end

function XSubPackageAgency:DoDownloadError(subpackageId)
    --如果在战斗中
    if not CS.XFightInterface.IsOutFight then
        self:MarkErrorDialogOnFight(subpackageId)
        return
    end
    self:PauseAll()
    self:ErrorDialog("FileManagerInitFileTableInGameDownloadError", nil, function()
        self:AddToDownload(subpackageId)
    end, nil, CsXApplication.GetText("Retry"))
end

function XSubPackageAgency:ErrorDialog(errorCode, cancelCb, confirmCb, cancelStr, confirmStr)

    CS.XHeroBdcAgent.BdcStartUpError(errorCode)
    cancelCb = cancelCb or function()
    end
    confirmCb = confirmCb or function()
    end

    CS.XTool.WaitCoroutine(CsXApplication.CoDialog(CsXApplication.GetText("Tip"),
            CsXApplication.GetText(errorCode), cancelCb, confirmCb, cancelStr, confirmStr))
end

function XSubPackageAgency:OnNetworkReachabilityChanged()
    if not self:IsOpen() then
        return
    end

    local notConnected = CS.XNetworkReachability.IsNotReachable()
    if notConnected and self._IsDownloading then
        self:DoDownloadError(self._DownloadPackageId)
        return
    end

    local isWifi = CS.XNetworkReachability.IsViaLocalArea()

    if isWifi then
        local groupIds = self._Model:GetGroupIdList()
        for _, groupId in ipairs(groupIds) do
            if self:GetWifiAutoState(groupId) then
                self:DownloadAllByGroup(groupId)
            end
        end
    else
        self:PauseAll()
    end
end

function XSubPackageAgency:OnLoginSuccess()
    if not self:IsOpen() then
        return
    end
    --self:RequestTask()
    --已经在下载了，就不用处理了
    if self._IsDownloading then
        return
    end
    --非wifi环境
    if not CS.XNetworkReachability.IsViaLocalArea() then
        return
    end
    --玩家未选中自动下载
    if not self._LaunchDlcManager.IsSelectWifiAutoDownload() then
        return
    end
    --开始下载必要资源
    local subIds = self._Model:GetNecessarySubIds()
    for _, subId in ipairs(subIds) do
        self:AddToDownload(subId)
    end
end

function XSubPackageAgency:OnSingleTaskFinish(eventName, args)
    local resourceName = args[0]
    --resourceName 是带前缀的
    local fullLen = string.len(resourceName)
    local prefixLen = string.len(self:GetUrlPrefix())
    --Lua 下标从1开始，去掉斜杠
    local fileName = string.sub(resourceName, prefixLen + 2, fullLen)
    self._LaunchDlcManager.SetDownloadedFile(fileName, true)
end

function XSubPackageAgency:IsPreparePause()
    return XTool.IsNumberValid(self._PreparePauseId)
end

function XSubPackageAgency:GetLaunchDlcManager()
    return self._LaunchDlcManager
end

--是否为可选资源
function XSubPackageAgency:IsOptional(subpackageId)
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    return template.Type == XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.OPTIONAL
end

function XSubPackageAgency:CheckRedPoint()
    return false
end

function XSubPackageAgency:RequestTask()
    --分包未开放
    if not self:IsOpen() then
        return
    end
    --未选择基础包
    -- 1:基础资源 2:完整资源
    local downloadMode = self._LaunchDlcManager.IsFullDownload(CS.XInfo.Version) and 2 or 1
    if downloadMode == 2 then
        return
    end
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageTaskId")
    if not XTool.IsNumberValid(taskId) then
        return
    end
    local data = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if not data then
        return
    end

    if data.State == XDataCenter.TaskManager.TaskState.Achieved
            or data.State == XDataCenter.TaskManager.TaskState.Finish then
        return
    end

    XDataCenter.TaskManager.RequestClientTaskFinish(taskId)
end

function XSubPackageAgency:DoRecordComplete(subpackageId)
    if not self._LaunchDlcManager then
        return
    end
    --必要资源下载完成
    if self:CheckNecessaryComplete() then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(CheckStageId)
        local dict = {}
        dict["document_version"] = CS.XRemoteConfig.DocumentVersion
        dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["pass_main_line"] = tostring(stageInfo.Passed)

        CS.XRecord.Record(dict, "80033", "SubpackageNecessary")
    elseif self:IsOptional(subpackageId) then
        local dict = {}
        dict["document_version"] = CS.XRemoteConfig.DocumentVersion
        dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["cv_hk_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.HK))
        dict["cv_en_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.EN))
        dict["cv_jp_complete"] = tostring(self:CheckCvDownload(XEnumConst.CV_TYPE.JPN))
        CS.XRecord.Record(dict, "80034", "SubpackageOptional")
    end
end

function XSubPackageAgency:DoRecordIntercept(entryType, param)
    local dict = {}
    dict["document_version"] = CS.XRemoteConfig.DocumentVersion
    dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    dict["ui_name"] = XLuaUiManager.GetTopUiName()
    dict["entry_type"] = tostring(entryType or "empty")
    dict["param"] = tostring(param or "empty")
    CS.XRecord.Record(dict, "80035", "SubpackageIntercept")
end

function XSubPackageAgency:DoRecordDownloadError(fileName, fileSize)
    local dict = {}
    dict["file_name"] = fileName
    dict["file_size"] = fileSize
    dict["version"] = self._DocumentVersion
    dict["type"] = RES_FILE_TYPE.MATRIX_FILE

    CS.XRecord.Record(dict, "80007", "XFileManagerDownloadError")
end

return XSubPackageAgency