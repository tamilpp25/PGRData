local XUiColorTableMainTips = XLuaUiManager.Register(XLuaUi,"UiColorTableMainTips")

function XUiColorTableMainTips:OnAwake()
    self:_AddBtnListener()
    self:_Init()
end

function XUiColorTableMainTips:OnStart(colorType, cb)
    self:Refresh(colorType, cb)
end

-- public
----------------------------------------------------------------

function XUiColorTableMainTips:Refresh(colorType, cb)
    self.CloseCallBack = cb
    self.TxtDes.text = XUiHelper.GetText("ColorTableStudyLevelMaxDes", XColorTableConfigs.GetColorText(colorType))
end

----------------------------------------------------------------



-- private
----------------------------------------------------------------

function XUiColorTableMainTips:_Init()
    self.Text.text = XUiHelper.GetText("ColorTableStudyLevelMaxTip")
    self.TxtMassage.text = XUiHelper.GetText("ColorTableStudyLevelMaxMassage")
end

function XUiColorTableMainTips:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self._OnBtnCloseClick)
end

function XUiColorTableMainTips:_OnBtnCloseClick()
    self:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
end

----------------------------------------------------------------