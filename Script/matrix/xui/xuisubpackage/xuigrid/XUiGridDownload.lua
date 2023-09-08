

---@class XUiGridDownload : XUiNode
---@field _Control XSubPackageControl
local XUiGridDownload = XClass(XUiNode, "XUiGridDownload")

function XUiGridDownload:OnStart(isPreview)
    self.IsPreview = isPreview
    self:InitCb()
end

function XUiGridDownload:InitCb()
    self.BtnDownLoad.CallBack = function() 
        self:OnBtnDownLoadClick()
    end

    self.BtnPause.CallBack = function()
        self:OnBtnPauseClick()
    end

    self.BtnDownLoading.CallBack = function()
        self:OnBtnDownLoadingClick()
    end
    
    self.BtnPrepare.CallBack = function()
        self:OnBtnPrepareClick()
    end
end


function XUiGridDownload:Refresh(index, subpackageId)
    self.TxtName.text = string.format("%02d %s", index, self._Control:GetSubPackageName(subpackageId))
    self.TxtDescribe.text = self._Control:GetSubPackageDesc(subpackageId)
    local item = self._Control:GetSubpackageItem(subpackageId)
    local size, unit = item:GetSubpackageSizeWithUnit(subpackageId)
    self.TxtSize.text = size .. unit
    
    local imgBanner = self._Control:GetSubPackageBanner(subpackageId)
    if not string.IsNilOrEmpty(imgBanner) then
        self.BgImage:SetRawImage(imgBanner)
    end
    
    
    local state = item:GetState()
    local progress = item:GetProgress()
    local progressPercent = math.floor(progress * 100) .. "%"
    self.ImgProgress.fillAmount = progress
    
    self.BtnPause:SetNameByGroup(0, progressPercent)
    self.BtnDownLoading:SetNameByGroup(0, progressPercent)
    if self.IsPreview then
        self.BtnDownLoad.gameObject:SetActiveEx(false)
        self.BtnPause.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE 
                or state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD 
                or state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING)
        self.BtnDownLoading.gameObject:SetActiveEx(false)
        self.BtnComplete.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE)
        self.BtnPrepare.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD)
    else
        self.BtnDownLoad.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD)
        self.BtnPause.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE)
        self.BtnDownLoading.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING)
        self.BtnComplete.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE)
        self.BtnPrepare.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD)
    end
    
    
    self.Id = subpackageId
end

function XUiGridDownload:OnBtnDownLoadClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:AddToDownload(self.Id)
end

function XUiGridDownload:OnBtnPauseClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:AddToDownload(self.Id)
end

function XUiGridDownload:OnBtnDownLoadingClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:PauseDownload(self.Id)
end

function XUiGridDownload:OnBtnPrepareClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:ProcessPrepare(self.Id)
end

function XUiGridDownload:GetSubpackageId()
    return self.Id
end


return XUiGridDownload