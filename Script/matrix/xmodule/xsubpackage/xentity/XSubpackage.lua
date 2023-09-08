---@class XSubpackage 分包数据
---@field _Id number
---@field _State number
---@field _TotalSize number
local XSubpackage = XClass(nil, "XSubpackage")

function XSubpackage:Ctor(packageId)
    self._Id = packageId
    self._TotalSize = -1
    
    self:InitState()
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
    if self:IsComplete() then
        return 1
    end
    local totalSize = self:GetTotalSize()
    if totalSize <= 0 then
        return 1
    end
    return self:GetDownloadSize() / self:GetTotalSize()
end

function XSubpackage:GetTotalSize()
    if self._TotalSize <= 0 then
        self._TotalSize = XMVCA.XSubPackage:GetSubpackageTotalSize(self._Id)
    end
    return self._TotalSize
end

function XSubpackage:GetDownloadSize()
    return XMVCA.XSubPackage:GetSubpackageDownloadSize(self._Id)
end

function XSubpackage:PrepareDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:StartDownload()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
end

--需要等到当前文件下载完毕后才能变换状态
function XSubpackage:PreparePause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XSubpackage:Pause()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XSubpackage:Complete()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XSubpackage:IsComplete()
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XSubpackage:GetSubpackageSizeWithUnit()
    local size = self:GetTotalSize()
    return XMVCA.XSubPackage:TransformSize(size)
end

return XSubpackage