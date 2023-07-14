---@class XUiTheatre3EndLoading : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3EndLoading = XLuaUiManager.Register(XLuaUi, "UiTheatre3EndLoading")

function XUiTheatre3EndLoading:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3EndLoading:OnStart(endingId)
    local endingCfg = self._Control:GetEndingById(endingId)
    if not endingCfg then
        return
    end
    if not string.IsNilOrEmpty(endingCfg.Bg) then
        self.BgCommonBai:SetRawImage(endingCfg.Bg)
    end
    if not string.IsNilOrEmpty(endingCfg.SpineBg) then
        self.SpineBg:LoadSpinePrefab(endingCfg.SpineBg)
        self.BgCommonBai.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(endingCfg.RImgTitle) then
        self.RImgLine:SetRawImage(endingCfg.RImgTitle)
    end
    if not string.IsNilOrEmpty(endingCfg.RImgDesc) then
        self.RImgDesc:SetRawImage(endingCfg.Bg)
    end
    if not string.IsNilOrEmpty(endingCfg.IconBg) then
        self.IconBg:SetRawImage(endingCfg.IconBg)
    end
    if not string.IsNilOrEmpty(endingCfg.Icon) then
        self.Icon:SetRawImage(endingCfg.Icon)
    end
    if self.TxtEndTitle then
        self.TxtEndTitle.text = endingCfg.Name
    end
    if self.TxtEndInfo then
        self.TxtEndInfo.text = endingCfg.Desc
        if not string.IsNilOrEmpty(endingCfg.DescColor) then
            self.TxtEndInfo.color = XUiHelper.Hexcolor2Color(endingCfg.DescColor)
        end
    end
end

--region Ui - BtnListener
function XUiTheatre3EndLoading:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnBackClick)
end

function XUiTheatre3EndLoading:OnBtnBackClick()
    local settle = self._Control:GetSettleData()
    if settle and settle:CheckIsEnding() and settle:IsShowSettle() then
        XLuaUiManager.PopThenOpen("UiTheatre3Settlement")
    else
        self._Control:InitAdventureData()
        self:Close()
    end
end
--endregion

return XUiTheatre3EndLoading