---@class XResource
---@field _Id number
---@field _TaskGroup XMTDownloadTaskGroup
local XResource = XClass(nil, "XResource")
local XLaunchDlcManager = require("XLaunchDlcManager")

function XResource:Ctor(resId)
    self._Id = resId
    self._RepeatName = {}
    self._DownSize = 0
    self._TotalSize = 0
    self._MaxProgress = 0
    self._TaskGroup = CS.XMTDownloadTaskGroup(resId) -- 以ResId为唯一标识
    self._WaitPause = false
end

function XResource:InitState()
    local downloadSize = self:GetDownloadSize()
    local totalSize = self:GetTotalSize()

    if downloadSize <= 0 then
        if totalSize <= 0 then
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
        else
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD
        end

    elseif downloadSize > 0 and downloadSize < totalSize then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    else
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    end
end

function XResource:GetState()
    return self._State
end

function XResource:PrepareDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XResource:StartDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
end

--等待状态
function XResource:PreparePause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XResource:Pause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XResource:Complete()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    XEventManager.DispatchEvent(XEventId.EVENT_RES_COMPLETE, self._Id)
    self:Release()
end

function XResource:IsComplete()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XResource:IsPrepare()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XResource:IsPause()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XResource:GetSourceSizeWithUnit()
    local size = self:GetTotalSize()
    return XMVCA.XSubPackage:TransformSize(size)
end

function XResource:InitFileInfo(filePath, data)
    local fileName, sha1, size = data[1], data[2], data[3]
    if self._RepeatName[fileName] then
        return
    end
    self._RepeatName[fileName] = true
    local isComplete = XLaunchDlcManager.IsNameDownloaded(fileName)
    if isComplete then
        self._DownSize = self._DownSize + size
    else --只添加未下载
        self._TaskGroup:AddTask(XMVCA.XSubPackage:GetUrlPath(fileName), XMVCA.XSubPackage:GetSavePath(fileName), size, sha1)
    end
end

function XResource:FileInitComplete()
    self._TaskGroup:AddFinishedSizeAfterAddTask(self._DownSize)
    self:InitState()
    self._RepeatName = nil
end

---@return XMTDownloadTaskGroup
function XResource:GetTaskGroup()
    return self._TaskGroup
end

function XResource:GetProgress()
    return self._TaskGroup.ProgressRatio
end

function XResource:GetMaxProgress()
    return math.max(self:GetProgress(), self._MaxProgress)
end

function XResource:UpdateMaxProgress(progress)
    self._MaxProgress = math.max(progress, self._MaxProgress)
end

-- 下载过程中，临时文件可能出错，删除掉会导致进度减少
function XResource:IsProgressLess()
    return self:GetProgress() < self._MaxProgress
end

function XResource:GetTotalSize()
    if self._TotalSize <= 0 then
        self._TotalSize = XMVCA.XSubPackage:GetResTotalSize(self._Id)
    end
    return self._TotalSize
end

function XResource:GetDownloadSize()
    return self._TaskGroup.DownloadedBytes
end

function XResource:IsComplete()
    return self._TaskGroup.State == CS.XMTDownloadTaskGroupState.Complete
end

---@param center XMTDownloadCenter
function XResource:OnStateChanged()
    local state = self._TaskGroup.State
    print("hyx XResource:OnStateChanged", self._Id, state)
    if state == CS.XMTDownloadTaskGroupState.Registered and self._WaitPause then
        XMVCA.XSubPackage:OnResDownloadRelease()
        self._WaitPause = false
    elseif state == CS.XMTDownloadTaskGroupState.Complete then
        self:Complete()
        XMVCA.XSubPackage:OnResDownloadRelease()
        self._WaitPause = false
    elseif state == CS.XMTDownloadTaskGroupState.Pausing then
        self._WaitPause = true
    elseif state == CS.XMTDownloadTaskGroupState.CompleteError then
        XMVCA.XSubPackage:OnResDownloadRelease()
    end

    local subpackageIdList = XMVCA.XSubPackage:GetSubpackageIdByResId(self._Id)
    if XTool.IsTableEmpty(subpackageIdList) then
        return
    end
    for k, subPackageId in pairs(subpackageIdList) do
        local subpackageItem = XMVCA.XSubPackage:GetSubpackageItem(subPackageId)
        if subpackageItem then
            subpackageItem:OnStateChanged(state)
        end
    end
end

function XResource:Release()
    if not self._TaskGroup then
        return
    end
    self._TaskGroup:Release()
end

return XResource