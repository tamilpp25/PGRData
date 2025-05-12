---@class XUiGridLinkCraftActivityChapterDetailAffix
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkCraftActivityChapterDetailAffix = XClass(XUiNode, 'XUiGridLinkCraftActivityChapterDetailAffix')


function XUiGridLinkCraftActivityChapterDetailAffix:Refresh(icon,desc)
    self.RImgIcon:SetRawImage(icon)
    self.TxtDetail.text = desc
end

return XUiGridLinkCraftActivityChapterDetailAffix