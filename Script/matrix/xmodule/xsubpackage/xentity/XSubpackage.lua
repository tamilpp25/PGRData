local XLaunchDlcManager = require("XLaunchDlcManager")

---@class XSubpackage 分包数据
---@field _Id number
---@field _State number
---@field _TotalSize number
---@field _TaskGroup XMTDownloadTaskGroup
local XSubpackage = XClass(nil, "XSubpackage")

function XSubpackage:Ctor(packageId)
    self._Id = packageId
    self._TotalSize = -1
    self._DownSize = 0
    self._WaitPause = false
    self._MaxProgress = 0
    self._TaskGroup = CS.XMTDownloadTaskGroup(packageId)
end

function XSubpackage:InitState()
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

function XSubpackage:GetState()
    return self._State
end

function XSubpackage:GetProgress()
    return self._TaskGroup.ProgressRatio
end

function XSubpackage:GetMaxProgress()
    return math.max(self:GetProgress(), self._MaxProgress)
end

function XSubpackage:UpdateMaxProgress(progress)
    self._MaxProgress = math.max(progress, self._MaxProgress)
end

-- 下载过程中，临时文件可能出错，删除掉会导致进度减少
function XSubpackage:IsProgressLess()
    return self:GetProgress() < self._MaxProgress
end

function XSubpackage:GetTotalSize()
    if self._TotalSize <= 0 then
        self._TotalSize = XMVCA.XSubPackage:GetSubpackageTotalSize(self._Id)
    end
    return self._TotalSize
end

function XSubpackage:GetDownloadSize()
    return self._TaskGroup.DownloadedBytes
end

function XSubpackage:PrepareDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:StartDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
end

--等待状态
function XSubpackage:PreparePause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:Pause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XSubpackage:Complete()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    self:Release()
end

function XSubpackage:IsComplete()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XSubpackage:IsPrepare()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:IsPause()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XSubpackage:GetSubpackageSizeWithUnit()
    local size = self:GetTotalSize()
    return XMVCA.XSubPackage:TransformSize(size)
end

function XSubpackage:InitFileInfo(filePath, data)
    local fileName, sha1, size = data[1], data[2], data[3]
    local isComplete = XLaunchDlcManager.IsNameDownloaded(fileName)
    if isComplete then
        self._DownSize = self._DownSize + size
    else --只添加未下载
        self._TaskGroup:AddTask(XMVCA.XSubPackage:GetUrlPath(fileName), XMVCA.XSubPackage:GetSavePath(fileName), size, sha1)
    end
end

function XSubpackage:FileInitComplete()
    self._TaskGroup:AddFinishedSizeAfterAddTask(self._DownSize)
    self:InitState()
end

---@return XMTDownloadTaskGroup
function XSubpackage:GetTaskGroup()
    return self._TaskGroup
end

---@param center XMTDownloadCenter
function XSubpackage:OnStateChanged()
    local state = self._TaskGroup.State
    if state == CS.XMTDownloadTaskGroupState.Registered and self._WaitPause then
        XMVCA.XSubPackage:OnDownloadRelease()
        self._WaitPause = false
    elseif state == CS.XMTDownloadTaskGroupState.Complete then
        XMVCA.XSubPackage:OnComplete()
        XMVCA.XSubPackage:OnDownloadRelease()
        self._WaitPause = false
    elseif state == CS.XMTDownloadTaskGroupState.Pausing then
        self._WaitPause = true
    elseif state == CS.XMTDownloadTaskGroupState.CompleteError then
        XMVCA.XSubPackage:DoDownloadError(self._Id)
        XMVCA.XSubPackage:OnDownloadRelease()
    end
end

--下载完成后，将对应的数据结构与C#引用置空
function XSubpackage:Release()
    if not self._TaskGroup then
        return
    end
    self._TaskGroup:Release()
end

return XSubpackage