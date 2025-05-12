

---@class XUiGridVideoTipDownload : XUiNode
local XUiGridVideoTipDownload = XClass(XUiNode, "XUiGridVideoTipDownload")

function XUiGridVideoTipDownload:SetInitData(resId)
    self.ResId = resId
    local resItem = XMVCA.XSubPackage:GetResourceItem(self.ResId)
    if resItem then
        local num, unit = resItem:GetSourceSizeWithUnit()
        self.TxtNum.text = num .. unit
    end
    self.TxtProgress.text = "0%"
    self.ImgBar.fillAmount = 0
end

function XUiGridVideoTipDownload:RefreshProgress(progress)
    local progressPercent = math.floor(progress * 100) .. "%"
    self.TxtProgress.text = progressPercent
    self.ImgBar.fillAmount = progress
end

return XUiGridVideoTipDownload