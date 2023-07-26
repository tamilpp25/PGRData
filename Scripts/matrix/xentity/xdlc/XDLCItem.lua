local default = {
    _Id = 0,
    _TotalSize = 0,
    _DownloadSize = 0,
    _Progress = 0,
    _ProgressCache = 0,
    _ValidDlcIds = {},
    _State = XDlcConfig.DownloadState.Ready,
    _ProgressCb = nil,
    _DoneCb = nil
}

local ProgressCache = "DLC_PROGRESS_CACHE_KEY"

local ProgressCacheUpdateFrame = 10 --缓存进度更新帧率间隔

local KeyCache = {}

local function GetCookiesKey(id)
    if KeyCache[id] then
        return KeyCache[id]
    end
    local val = string.format("%s_VER:_%s_%s", ProgressCache, CS.XInfo.Version, id) 
    KeyCache[id] = val
    return val
end

---@class XDLCItem : XDataEntityBase
---@field _Id number DLCList.tabId
---@field _TotalSize number 资源总大小
---@field _DownloadSize number 资源已下载大小
---@field _Progress number 进度
---@field _ProgressCache number 进度缓存，方便做动动画
---@field _ValidDlcIds number[] 有效资源Id
---@field _State number 当前状态
---@field _ProgressCb function 进度事件
---@field _DoneCb function 下载完成事件
---@field _RemainingSize number 剩余大小
local XDLCItem = XClass(XDataEntityBase, "XDLCItem")

function XDLCItem:Ctor(dlcListId)
    self:Init(default, dlcListId)
end

function XDLCItem:InitData(id)
    self:SetProperty("_Id", id)
    self:SetProperty("_RemainingSize", 0)
    local progressCache = XSaveTool.GetData(GetCookiesKey(id)) or 0
    self:SetProperty("_ProgressCache", progressCache)
end

function XDLCItem:GetConfig()
    return XDlcConfig.GetListConfigById(self._Id)
end

function XDLCItem:GetId()
    return self._Id
end

function XDLCItem:UpdateProgressCache(progress)
    self:SetProperty("_ProgressCache", progress)
    XSaveTool.SaveData(GetCookiesKey(self._Id), progress)
end

function XDLCItem:SetValidDlcIds(list)
    list = list or {}
    self:SetProperty("_ValidDlcIds", list)
    local totalSize = XDataCenter.DlcManager.GetTotalDownloadSize(list)
    self:SetProperty("_TotalSize", totalSize)
    local downloadSize = XDataCenter.DlcManager.GetDownloadedSize(list)
    self:SetProperty("_DownloadSize", downloadSize)
    if downloadSize == 0 then
        self:UpdateProgressCache(0)
    end

    if totalSize > 0 and downloadSize > 0 and totalSize ~= downloadSize then
        self:SetProperty("_State", self._ProgressCache > 0 and XDlcConfig.DownloadState.Pause or XDlcConfig.DownloadState.Ready)
    end
    local progress = totalSize <= 0 and 1 or downloadSize / totalSize
    self:SetProperty("_Progress", progress)
    if progress > 0 then
        self:UpdateProgressCache(math.min(progress, self._ProgressCache))
    end
end

function XDLCItem:GetValidDlcIds()
    return self._ValidDlcIds
end

function XDLCItem:GetValidDlcIdStr()
    local ids = self:GetValidDlcIds()
    if XTool.IsTableEmpty(ids) then
        return "nil"
    end
    return table.concat(ids, ",")
end

function XDLCItem:GetTotalSize()
    return self._TotalSize
end

function XDLCItem:GetTotalSizeWithUnit()
    local size, unit = XDlcConfig.GetSizeAndUnit(self._TotalSize)
    return size .. unit
end

function XDLCItem:GetDownloadedSize()
    local downloadSize = XDataCenter.DlcManager.GetDownloadedSize(self:GetValidDlcIds())
    self:SetProperty("_DownloadSize", downloadSize)
    return downloadSize
end

function XDLCItem:GetDownloadedSizeWithUnit()
    local size, unit = XDlcConfig.GetSizeAndUnit(self:GetDownloadedSize())
    return size .. unit
end

function XDLCItem:GetRootId()
    local config = self:GetConfig()
    return config.RootId
end

--- 资源是否下载完毕
---@return boolean
--------------------------
function XDLCItem:HasDownloaded()
    local dlcIds = self:GetValidDlcIds()
    local launchManager = XDataCenter.DlcManager.GetLaunchDlcManager()
    for _, dlcId in ipairs(dlcIds or {}) do
        local hasDownloaded = launchManager.HasDownloadedDlc(dlcId)
        if not hasDownloaded then
            return false
        end
    end
    return true
end

--- 完全下载
---@return boolean
--------------------------
function XDLCItem:IsComplete()
    return self:HasDownloaded() or self._ProgressCache >= 1
end

--- 暂停状态
---@return boolean
--------------------------
function XDLCItem:IsPause()
    return self._State == XDlcConfig.DownloadState.Pause and not self:IsComplete()
end

--- 完全未下载状态
---@return boolean
--------------------------
function XDLCItem:IsNoDownload()
    return self._State == XDlcConfig.DownloadState.Ready 
            and not self:IsComplete() and self._ProgressCache <= 0
end

--- 正在下载
---@return boolean
--------------------------
function XDLCItem:IsDownloading()
    return self._State == XDlcConfig.DownloadState.InProgress and not self:IsComplete()
end

--- 下载资源
---@return void
--------------------------
function XDLCItem:Download(progressCb, doneCb)
    if XDataCenter.DlcManager.CheckIsDownloading() then
        XDataCenter.DlcManager.TipDownloading()
        return
    end
   
    if self:IsComplete() then
        if progressCb then progressCb(1) end
        if doneCb then doneCb(false) end
        return
    end

    if self._State ~= XDlcConfig.DownloadState.Ready then
        return
    end
    
    local newDoneCb = function(isPause)
        local downloadSize = XDataCenter.DlcManager.GetDownloadedSize(self:GetValidDlcIds())
        local progress = downloadSize / self._TotalSize
        self._RemainingSize = self._TotalSize - downloadSize
        self:SetProperty("_DownloadSize", downloadSize)
        self:SetProperty("_Progress", progress)
        self:UpdateProgressCache(progress)
        
        if doneCb then doneCb(isPause) end
    end

    local curFrame = 0
    local newProgressCb = function(progress)
        if not XTool.IsNumberValid(self._RemainingSize) then
            self._RemainingSize = self._TotalSize - self:GetDownloadedSize()
        end
        --剩余未下载大小下载量
        local size = math.floor(self._RemainingSize * progress)
        --真实进度
        local realProgress = (size + self._DownloadSize) / self._TotalSize
        self:SetProperty("_Progress", realProgress)
        --间隔一定帧更新缓存
        curFrame = curFrame + 1
        if curFrame >= ProgressCacheUpdateFrame then
            curFrame = 0
            self:UpdateProgressCache(realProgress)
        end
        if progressCb then progressCb(realProgress) end
    end
    
    self:SetProperty("_State", XDlcConfig.DownloadState.InProgress)
    XDataCenter.DlcManager.DownloadDlcByListId(self._Id, newProgressCb, newDoneCb)
end

--- 暂停下载
--------------------------
function XDLCItem:Pause()
    if self:IsComplete() then
        return
    end
    self:SetProperty("_State", XDlcConfig.DownloadState.Pause)
    self:UpdateProgressCache(self._Progress)
    XDataCenter.DlcManager.PauseDownloadDlc()
end

--- 恢复下载
--------------------------
function XDLCItem:Resume(progressCb, doneCb)
    if XDataCenter.DlcManager.CheckIsDownloading() then
        XDataCenter.DlcManager.TipDownloading()
        return
    end
    if self:IsComplete() then
        if progressCb then progressCb(1) end
        if doneCb then doneCb(false) end
        return
    end
    if XDataCenter.DlcManager.IsCurDlcListId(self._Id) then
        self:SetProperty("_State", XDlcConfig.DownloadState.InProgress)
        XDataCenter.DlcManager.ResumeDownloadDlc()
    else
        self:SetProperty("_State", XDlcConfig.DownloadState.Ready)
        self:Download()
    end
end

function XDLCItem:TryDownload(progressCb, doneCb)
    if self:IsPause() then
        self:Resume(progressCb, doneCb)
    else
        self:Download(progressCb, doneCb)
    end
end

--region   ------------------Config start-------------------
function XDLCItem:GetTitle()
    return self:GetConfig().Title
end

function XDLCItem:GetDesc()
    local cfg = self:GetConfig()
    if string.IsNilOrEmpty(cfg.Desc) then
        local rootCfg = XDlcConfig.GetListConfigById(cfg.RootId)
        return rootCfg.Desc
    end
    return cfg.Desc
end

function XDLCItem:GetImgBanner()
    return self:GetConfig().ImgBanner
end

function XDLCItem:GetEntryType()
    return self:GetConfig().EntryType
end
--endregion------------------Config finish------------------

return XDLCItem
    
