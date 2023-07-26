--
-- Author: wujie
-- Note: 图鉴意识详情格子

local XUiGridArchiveAwarenessDetail = XClass(nil, "XUiGridArchiveAwarenessDetail")

function XUiGridArchiveAwarenessDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

function XUiGridArchiveAwarenessDetail:OnBtnClick()
    if self.ClickCb then
        self.ClickCb()
    end
end

function XUiGridArchiveAwarenessDetail:SetClickCallback(clickCb)
    self.ClickCb = clickCb
end

function XUiGridArchiveAwarenessDetail:SetName(txt)
    self.TxtGet.text = txt
    self.TxtNotGet.text = txt
end

function XUiGridArchiveAwarenessDetail:SetGet(isGet)
    self.PanelGet.gameObject:SetActiveEx(isGet)
    self.PanelNotGet.gameObject:SetActiveEx(not isGet)
end

function XUiGridArchiveAwarenessDetail:ShowSelect(isShow)
    self.ImgSelect.gameObject:SetActiveEx(isShow)
end

return XUiGridArchiveAwarenessDetail