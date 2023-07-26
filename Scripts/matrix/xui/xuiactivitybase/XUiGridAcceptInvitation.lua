--
--Author: wujie
--Note: 回归活动发送邀请奖励格子

local XUiGridAcceptInvitation = XClass(nil, "XUiGridAcceptInvitation")

function XUiGridAcceptInvitation:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridCommon = XUiGridCommon.New(rootUi, self.PanelGridCommon)
end

function XUiGridAcceptInvitation:UpdateGetStatus(isGet)
    self.ImgGet.gameObject:SetActiveEx(isGet)
end

function XUiGridAcceptInvitation:Refresh(itemId)
    if not itemId then return end
    self.GridCommon:Refresh(itemId)
end

return XUiGridAcceptInvitation