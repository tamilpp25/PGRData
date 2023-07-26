local XUiDlcDownload = XLuaUiManager.Register(XLuaUi, "UiDownload")


function XUiDlcDownload:OnAwake()
end

function XUiDlcDownload:OnStart(args)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnOk, self.OnBtnOkClick)
    self.onOkCb = args
end

function XUiDlcDownload:OnEnable()
  
end

function XUiDlcDownload:OnDestroy()
end


function XUiDlcDownload:OnBtnCancelClick()
    self:Close()
end

function XUiDlcDownload:OnBtnOkClick()
    self:Close()
    if self.onOkCb then
        self.onOkCb()
        self.onOkCb = nil
    end
end

