local XUiArchivePVGrid = XClass(XUiNode, "XUiArchivePVGrid")
local Rect = CS.UnityEngine.Rect(1, 1, 1, 1)
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")
local LockCGIconAspectRatio = CS.XGame.ClientConfig:GetFloat("LockStoryIconAspectRatio")
function XUiArchivePVGrid:OnStart()
    self:SetButtonCallBack()
    self.CGBtn:ShowReddot(false)
end

function XUiArchivePVGrid:SetButtonCallBack()
    self.CGBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiArchivePVGrid:OnBtnSelect()
    local detailId = self.DetailId
    local isUnLock, lockDes = self._Control:GetPVUnLock(detailId)
    if not isUnLock then
        XUiManager.TipError(lockDes)
        return
    end

    XDataCenter.VideoManager.PlayUiVideo(self._Control:GetPVDetailPv(detailId))
end

function XUiArchivePVGrid:UpdateGrid(detailId)
    self.DetailId = detailId

    local isUnLock = self._Control:GetPVUnLock(detailId)
    if not isUnLock then
        --未激活
        self.CGImg:SetRawImage(self._Control:GetPVDetailLockBg(detailId))
        self.CGTitle.text = LockNameText
        Rect.x = 0
        Rect.y = 0
        self.CGImg.uvRect = Rect
        self.CGImgAspect.aspectRatio = LockCGIconAspectRatio
        self:SetImagePlayActive(false)
    else
        --已激活
        self.CGImg:SetRawImage(self._Control:GetPVDetailBg(detailId))
        self.CGTitle.text = self._Control:GetPVDetailName(detailId)
        Rect.x = self._Control:GetPVDetailBgOffSetX(detailId) / 100
        Rect.y = self._Control:GetPVDetailBgOffSetY(detailId) / 100
        self.CGImg.uvRect = Rect
        local bgWidth = self._Control:GetPVDetailBgWidth(detailId)
        local bgHigh = self._Control:GetPVDetailBgHigh(detailId)
        local width = bgWidth ~= 0 and bgWidth or 1
        local high = bgHigh ~= 0 and bgHigh or 1
        self.CGImgAspect.aspectRatio = width / high
        self:SetImagePlayActive(true)
    end
end

function XUiArchivePVGrid:SetImagePlayActive(isActive)
    if self.ImagePlay then
        self.ImagePlay.gameObject:SetActiveEx(isActive)
    end
end

return XUiArchivePVGrid