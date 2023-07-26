local XUiPanelMovie3D = XClass(nil,"XUiPanelMovie3D")

function XUiPanelMovie3D:Ctor(ui,rootUi)
    self.RootUi = rootUi
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterBtnEvent()
end

function XUiPanelMovie3D:RegisterBtnEvent()
    self.BtnSkip.CallBack = function() self:OnClickBtnSkip() end
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.BtnHide.CallBack = function() self:OnClickBtnHide() end
    self.PanelHideMask:AddPointerClickListener(handler(self, self.OnClickHideMask))
end

function XUiPanelMovie3D:OnClickBtnSkip()
    self.RootUi:OnClickBtnSkip()
end

function XUiPanelMovie3D:OnClickBtnReview()
    self.RootUi:OpenChildUi("UiMovieReview")
end

function XUiPanelMovie3D:OnClickBtnHide()
    self.TopBtn3d.gameObject:SetActiveEx(false)
    self.IsShowDialog = self.PanelDialog.gameObject.activeSelf
    self:SetDialogActive(false)
    self.PanelHideMask.gameObject:SetActiveEx(true)
end

function XUiPanelMovie3D:OnClickHideMask()
    self.TopBtn3d.gameObject:SetActiveEx(true)
    self:SetDialogActive(self.IsShowDialog)
    self.PanelHideMask.gameObject:SetActiveEx(false)
end

function XUiPanelMovie3D:PlayTypeWriter(roleName, content, faceImg, duration, endCallback)
    self.TxtWords.text = content
    self.TxtName.text = roleName
    if faceImg then
        self.RImgHead:SetRawImage(faceImg)
        self.RImgHead.gameObject:SetActiveEx(true)
    else
        self.RImgHead.gameObject:SetActiveEx(false)
    end
    self.TxtTypeWriter.CompletedHandle = function()
        endCallback()
    end
    if duration then
        self.TxtTypeWriter.Duration = duration
    else
        self.TxtTypeWriter.Duration = string.Utf8Len(content) * XMovieConfigs.TYPE_WRITER_SPEED
    end
    self.TxtTypeWriter:Play()
end

function XUiPanelMovie3D:SetDialogActive(isActive)
    self.PanelDialog.gameObject:SetActiveEx(isActive)
end

function XUiPanelMovie3D:RegisterBtnSkipDialog(callback)
    self.BtnSkipDialog.CallBack = callback
end

return XUiPanelMovie3D