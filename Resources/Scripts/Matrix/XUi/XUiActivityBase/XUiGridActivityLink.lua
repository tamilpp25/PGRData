local XUiGridActivityLink = XClass(nil, "XUiGridActivityLink")

function XUiGridActivityLink:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridActivityLink:AutoAddListener()
    self.BtnGo.CallBack = function()
        self:OnBtnLinkClick()
    end
end

function XUiGridActivityLink:UpdateGrid(data)
    self.Data = data
    --刷新图标
    self.ImgIcon:SetRawImage(self.Data.Icon)
    --显示链接名字
    self.TxtLink.text = self.Data.LinkName
end

function XUiGridActivityLink:OnBtnLinkClick()
    CS.UnityEngine.Application.OpenURL(self.Data.LinkUrl)
end

return XUiGridActivityLink