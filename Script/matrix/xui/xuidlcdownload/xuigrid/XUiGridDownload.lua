local XUiGridDownload = XClass(nil, "XUiGridDownload")

function XUiGridDownload:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.OnCompleteCb = handler(self, self.OnDownloadComplete)
    self:InitCb()
end

function XUiGridDownload:InitCb()
    self.BtnDownLoad.CallBack = function()
        self:OnBtnDownLoadClick()
    end

    self.BtnDownLoading.CallBack = function()
        self:OnBtnDownLoadingClick()
    end

    self.BtnPause.CallBack = function()
        self:OnBtnPauseClick()
    end
end

---@param rootUi XUiDownLoadMain
function XUiGridDownload:Init(rootUi)
    self.RootUi = rootUi
end

---@param itemData XDLCItem
function XUiGridDownload:Refresh(itemData)
    if not itemData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.ItemData = itemData
    self.TxtName.text = itemData:GetTitle()
    self.TxtDescribe.text = itemData:GetDesc()
    local imgBanner = itemData:GetImgBanner()
    if imgBanner then
        self.BgImage:SetRawImage(imgBanner)
    end
    self.TxtSize.text = itemData:GetTotalSizeWithUnit()
    self:BindViewModel()
end

function XUiGridDownload:Recycle()
    self:UnBindViewModel()
end

function XUiGridDownload:BindViewModel()
    if not self.RootUi or not self.ItemData then
        return
    end
    
    local itemData = self.ItemData
    --状态变化
    self.RootUi:BindViewModelPropertyToObj(itemData, function(state)
        --下载中
        local downloading = itemData:IsDownloading()
        --完全下载
        local complete = itemData:IsComplete()
        --未下载
        local noDownload = itemData:IsNoDownload()
        --暂停下载
        local pause = itemData:IsPause()
        self:RefreshButtonState(complete, pause, noDownload, downloading)
    end, "_State")

    --进度变化
    self.RootUi:BindViewModelPropertiesToObj(itemData, function(progress, progressCache)
        local showProgress = itemData:IsDownloading() and math.max(progress, progressCache) or progressCache
        self:OnProgressChange(showProgress)
        if showProgress >= 1.0 then
            self:RefreshButtonState(true, false, false, false)
        end
    end, "_Progress", "_ProgressCache")
end

function XUiGridDownload:UnBindViewModel()
    if not self.RootUi or not self.ItemData then
        return
    end
    local uiName = self.RootUi.Name
    self.ItemData:UnBindPropertyByUiName("_Progress", uiName)
    self.ItemData:UnBindPropertyByUiName("_ProgressCache", uiName)
    self.ItemData:UnBindPropertyByUiName("_State", uiName)
end

function XUiGridDownload:TryDownload()
    if not self.ItemData then
        return
    end

    if XDataCenter.DlcManager.CheckIsDownloading() then
        XDataCenter.DlcManager.TipDownloading()
        return
    end
    
    self.ItemData:TryDownload(nil, self.OnCompleteCb)
    self:RefreshButtonState(false, false, false, true)
    XDataCenter.DlcManager.InterruptDownload()
    self.RootUi:RefreshBtnDownAll()
end

--开始下载
function XUiGridDownload:OnBtnDownLoadClick()
    self:TryDownload()
end

--恢复下载
function XUiGridDownload:OnBtnPauseClick()
    self:TryDownload()
end

--暂停下载
function XUiGridDownload:OnBtnDownLoadingClick()
    if not self.ItemData then
        return
    end
    local itemData = self.ItemData
    itemData:Pause()
    self:RefreshButtonState(false, true, false, false)
    XDataCenter.DlcManager.InterruptDownload()
    self.RootUi:RefreshBtnDownAll()
end

function XUiGridDownload:OnDownloadComplete()
    local itemData = self.ItemData
    if not itemData then
        return
    end

    if itemData:IsComplete() then
        XUiManager.PopupLeftTip(XUiHelper.GetText("DlcDownloadCompleteTitle"), itemData:GetTitle())
    end
end

--回调更新
function XUiGridDownload:OnProgressChange(progress)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    if not self.ItemData then
        return
    end
    self:RefreshProgress(progress)
end

--界面更新
function XUiGridDownload:UpdateProgress(itemData)
    if not itemData then
        return
    end
    local progress = itemData:GetProperty("_Progress")
    local progressCache = itemData:GetProperty("_ProgressCache")
    local showProgress = itemData:IsDownloading() and math.max(progress, progressCache) or progressCache
    self:RefreshProgress(showProgress)
end

function XUiGridDownload:RefreshProgress(progress)
    self.ImgProgress.fillAmount = progress
    local percent = math.floor(progress * 100) .. "%"
    self.BtnPause:SetNameByGroup(0, percent)
    self.BtnDownLoading:SetNameByGroup(0, percent)
end

function XUiGridDownload:RefreshButtonState(complete, pause, noDownload, downloading)
    self.BtnComplete.gameObject:SetActiveEx(complete)
    self.BtnDownLoad.gameObject:SetActiveEx(noDownload)
    self.BtnDownLoading.gameObject:SetActiveEx(downloading)
    self.BtnPause.gameObject:SetActiveEx(pause)
    self.ProgressBg.gameObject:SetActiveEx(pause or downloading)
end

function XUiGridDownload:GetId()
    return self.ItemData and self.ItemData:GetId() or -1
end

return XUiGridDownload