---@class XUiTheatre3NewFunction : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3NewFunction = XLuaUiManager.Register(XLuaUi, "UiTheatre3NewFunction")

function XUiTheatre3NewFunction:OnAwake()
    self._IsClose = true
    self:AddBtnListener()
end

function XUiTheatre3NewFunction:OnStart(cb)
    self.CloseCb = cb
    ---@type UnityEngine.UI.Image
    self.RImgLine = XUiHelper.TryGetComponent(self.TxtNewFunction2.transform.parent, "RImgLine", "Image")
    self.TxtEndInfo.text = self._Control:GetClientConfigTxtByConvertLine("QuantumOpenTipTxt", 1)
    self:RefreshAnimTxt(0)
    self:StartAnim()
end

function XUiTheatre3NewFunction:OnDisable()
    self._Control:SetOpenQuantumIsTip()
    self:StopAnim()
end

--region Anim
function XUiTheatre3NewFunction:StartAnim()
    if self._Timer then
        self:StopAnim()
    end
    self._IsClose = false
    self._Timer = XUiHelper.Tween(2, function(f)
        if self.RImgLine then
            self.RImgLine.fillAmount = f
        end
        self:RefreshAnimTxt(math.ceil(100 * f))
    end, function()
        self._IsClose = true
        self:RefreshAnimTxt(100)
    end)
end

function XUiTheatre3NewFunction:StopAnim()
    XScheduleManager.UnSchedule(self._Timer)
end

function XUiTheatre3NewFunction:RefreshAnimTxt(value)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.TxtNewFunction2.text = string.format(self._Control:GetClientConfigTxtByConvertLine("QuantumOpenTipTxt", 2), value)
end
--endregion

--region Ui - BtnListener
function XUiTheatre3NewFunction:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnBackClick)
end

function XUiTheatre3NewFunction:OnBtnBackClick()
    if self._IsClose then
        self:Close()
        if self.CloseCb then
            self.CloseCb()
        end
    end
end
--endregion

return XUiTheatre3NewFunction