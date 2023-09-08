---@class XSubPackageAgency : XAgency
---@field private _Model XSubPackageModel
---@field private _DownloadQueue number[] 分包下载Id列表
---@field private _LaunchDlcManager XLaunchDlcManager 下载管理器
---@field private _FileModule XLaunchFileModule 下载文件管理器
local XSubPackageAgency = XClass(XAgency, "XSubPackageAgency")

local MIN_SIZE = 1024

local UPDATE_INTERVAL = 200 --下载中时，每200ms更新一下

local CheckStageId = 10030304

--必要资源GroupId
local NecessaryDownloadGroupId = { 1, }

function XSubPackageAgency:OnInit()
    
    self._DownloadQueue = {}
    
    self._IsDownloading = false
    self._DownloadPackageId = 0
    self._IsDownloadGroup = false --是否为一组同时下载
    self._PreparePauseId = 0 --准备暂停的Id
    
    self._OnPreEnterFightCb = handler(self, self.OnPreEnterFight)
    self._OnExitFightCb = handler(self, self.OnExitFight)
    self._OnUpdateDownloadCb = handler(self, self.OnUpdateDownload)
    self._OnNetworkReachabilityChangedCb = handler(self, self.OnNetworkReachabilityChanged)
    self._OnLoginSuccessCb = handler(self, self.OnLoginSuccess)
    self._OnDownloadReleaseCb = handler(self, self.OnDownloadRelease)
    
    self._LaunchDlcManager = require("XLaunchDlcManager")
    
    self._SubIndexInfo = self._LaunchDlcManager.GetIndexInfo()
    
    self._SubIndexInfoDict = {}
    
    self._TipDialog = false
    
    self._ShowErrorDialog = nil
end

function XSubPackageAgency:InitRpc()
    
end

function XSubPackageAgency:InitEvent()
    --进入战斗
    XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self._OnPreEnterFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._OnPreEnterFightCb)
    
    --退出战斗
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, self._OnExitFightCb)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFightCb)
    
    --下载器释放（下载器正式暂停，可以继续下一个下载, 或者其他操作， 在下载器正式暂停之前不允许进行其他包的下载）
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_LAUNCH_DOWNLOAD_RELEASE, self._OnDownloadReleaseCb)
    
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
    
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_LAUNCH_DOWNLOAD_RELEASE, self._OnDownloadReleaseCb)
    
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
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    local size = 0
    for _, patchId in pairs(template.PatchId) do
        local indexInfo = self._SubIndexInfo[patchId]
        if not indexInfo then
            local str = string.format("分包Id = %s中，PatchId = %s 不存在IndexInfo", subpackageId, patchId)
            XLog.Warning(str)
            goto continue
        end

        for assetPath, info in pairs(indexInfo) do
            size = size + info[3]
        end

        ::continue::
    end
    
    return size
end

--已经下载的大小
function XSubPackageAgency:GetSubpackageDownloadSize(subpackageId)
    local indexInfo = self._SubIndexInfoDict[subpackageId]
    if not indexInfo then
        indexInfo = {}
        local template = self._Model:GetSubpackageTemplate(subpackageId)
        for _, patchId in pairs(template.PatchId) do
            local info = self._SubIndexInfo[patchId]
            if not info then
                local str = string.format("分包Id = %s中，PatchId = %s 不存在IndexInfo", subpackageId, patchId)
                XLog.Warning(str)
            else
                indexInfo = self:MergeTable(indexInfo, info)
            end
        end
        self._SubIndexInfoDict[subpackageId] = indexInfo
    end

    local size = 0
    for assetPath, info in pairs(indexInfo) do
        if self._LaunchDlcManager.IsNameDownloaded(info[1]) then
            size = size + info[3]
        end
    end
    
    return size
end

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

    if not self._IsDownloading then
        self:StartDownload()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subpackageId)
end

function XSubPackageAgency:StartDownload()
    local isWifi = CS.XNetworkReachability.IsViaLocalArea()
    --wifi or 已经弹过提示
    if isWifi or self._TipDialog then
        self:DoDownload()
        return
    end
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DlcDownloadWIFIText"), 
            nil, handler(self, self.PauseAll), function()
                self._TipDialog = true
                self.DoDownload()
            end)
end

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
    --这个接口仅恢复下载状态
    if self._FileModule then
        self._FileModule.ResumeDownload()
    end
    --开始下载
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    self._LaunchDlcManager.DownloadDlc(template.PatchId, nil, handler(self, self.OnComplete), function()
        if self._IsDownloading then
            self._ShowErrorDialog = self._DownloadPackageId
        end
        self:PauseAll()
        if self._FileModule then
            self._FileModule.ReleaseDownloader()
        end
    end)
    
    --事件通知
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_START, subpackageId)
    self:StartTimer()
end

function XSubPackageAgency:PauseDownload(subpackageId)
    self._Model:GetSubpackageItem(subpackageId):PreparePause()
    if self._FileModule then
        self._FileModule.PauseDownload()
    end
    --等待暂停
    self._PreparePauseId = subpackageId
    --停掉定时器，避免玩家发现异常
    self:StopTimer()

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
    
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_COMPLETE)
end

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

function XSubPackageAgency:OnComplete(isPause)
    --暂停回调不在这里处理
    if isPause then
        return
    end
    self._IsDownloading = false
    local id = self._DownloadPackageId
    self._CompleteIdCache = id
    self._DownloadPackageId = 0
    self._FileModule = nil

    self:StopTimer()

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

function XSubPackageAgency:SetFileModule(fileModule)
    if self._FileModule ~= fileModule then
        fileModule.ResumeDownload()
    end
    self._FileModule = fileModule
end

function XSubPackageAgency:OnUpdateDownload()
    if not self._IsDownloading then
        self:StopTimer()
        return
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, self._DownloadPackageId)
end

function XSubPackageAgency:StartTimer()
    if self.Timer then
        return
    end

    if not self._IsDownloading then
        self:StopTimer()
        return
    end
    
    self.Timer = XScheduleManager.ScheduleForever(self._OnUpdateDownloadCb, UPDATE_INTERVAL)
end

function XSubPackageAgency:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

-- 检查必要资源是否下载完毕
function XSubPackageAgency:CheckNecessaryComplete()
    if not self:IsOpen() then
        return true
    end
    local complete = true
    for _, groupId in ipairs(NecessaryDownloadGroupId) do
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
    --需要拦截，并且未下载必要资源
    if self._Model:CheckIntercept(enterType, param) and not self:CheckNecessaryComplete() then
        self:DoRecordIntercept(enterType, param)
        XLuaUiManager.Open("UiDownloadPreview")
        return false
    end
    return true
end

function XSubPackageAgency:CheckSubpackageByCvType(cvType)
    local isComplete = self:CheckCvDownload(cvType)
    if not isComplete then
        local template = self._Model:GetVoiceIntercept(cvType)
        local subpackageIds = template.SubpackageId
        XLuaUiManager.Open("UiDownloadPreview", subpackageIds)
    end
    return isComplete
end

function XSubPackageAgency:CheckCvDownload(cvType)
    if not self:IsOpen() then
        return true
    end

    local template = self._Model:GetVoiceIntercept(cvType)
    local subpackageIds = template.SubpackageId
    if XTool.IsTableEmpty(subpackageIds) then
        return true
    end

    local isComplete = true
    for _, subpackageId in ipairs(subpackageIds) do
        local item = self._Model:GetSubpackageItem(subpackageId)
        if not item:IsComplete() then
            isComplete = false
            break
        end
    end

    return isComplete
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

function XSubPackageAgency:GetNecessaryGroupIds()
    return NecessaryDownloadGroupId
end

function XSubPackageAgency:IsNecessaryGroup(groupId)
    for _, gId in pairs(NecessaryDownloadGroupId) do
        if gId == groupId then
            return true
        end
    end
    return false
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
    if not self._ShowErrorDialog then
        return
    end
    
    local errorCode = "FileManagerInitFileTableInGameDownloadError"
    CS.XHeroBdcAgent.BdcStartUpError(errorCode)
    local csApp = CS.XApplication
    CS.XTool.WaitCoroutine(csApp.CoDialog(csApp.GetText("Tip"), csApp.GetText(errorCode), 
            function()
            end, 
            function() 
                self:AddToDownload(self._ShowErrorDialog)
                self._ShowErrorDialog = nil
            end, nil, csApp.GetText("Retry")))
    
end

function XSubPackageAgency:OnNetworkReachabilityChanged()
    if not self:IsOpen() then
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
    self:RequestTask()
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
    for _, groupId in pairs(NecessaryDownloadGroupId) do
        self:DownloadAllByGroup(groupId)
    end
end

function XSubPackageAgency:OnDownloadRelease()
    if not self:IsOpen() then
        return
    end
    if XTool.IsNumberValid(self._PreparePauseId) then
        local item = self._Model:GetSubpackageItem(self._PreparePauseId)
        item:Pause()
        self._TipDialog = false
        
        XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PAUSE, self._PreparePauseId)
    end
    
    self._IsDownloading = false
    self._IsDownloadGroup = false
    self._DownloadPackageId = 0
    self._PreparePauseId = 0
    
    self:StartDownload()
end

function XSubPackageAgency:IsPreparePause()
    return XTool.IsNumberValid(self._PreparePauseId)
end

function XSubPackageAgency:GetLaunchDlcManager()
    return self._LaunchDlcManager
end

--是否为可选资源
function XSubPackageAgency:IsOptional(subpackageId)
    local groupId = self._Model:GetSubpackageGroupId(subpackageId)
    local isOptional = true
    for _, gId in pairs(NecessaryDownloadGroupId) do
        if gId == groupId then
            isOptional = false
            break
        end
    end
    
    return isOptional
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


return XSubPackageAgency