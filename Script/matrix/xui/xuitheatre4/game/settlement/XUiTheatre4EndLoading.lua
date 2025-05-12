---@class XUiTheatre4EndLoading : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4EndLoading = XLuaUiManager.Register(XLuaUi, "UiTheatre4EndLoading")

function XUiTheatre4EndLoading:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
    self.TxtRole.transform.parent.gameObject:SetActiveEx(false)
    self.EffectGo = {
        [XEnumConst.Theatre4.SettleType.Failed] = {
            self.EffectRedL,
            self.EffectRedR,
        },
        [XEnumConst.Theatre4.SettleType.Success] = {
            self.EffectBlueL,
            self.EffectBlueR,
        },
    }
    -- 全部隐藏
    for _, settleType in pairs(XEnumConst.Theatre4.SettleType) do
        for _, effectGo in pairs(self.EffectGo[settleType] or {}) do
            effectGo.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre4EndLoading:OnStart(endingId)
    self.EndingId = endingId
    local endingConfig = self._Control:GetEndingConfig(endingId)
    if not endingConfig then
        return
    end
    if not string.IsNilOrEmpty(endingConfig.Bg) then
        self.BgCommonBai:SetRawImage(endingConfig.Bg)
    end
    if not string.IsNilOrEmpty(endingConfig.BgEffect) then
        self.BgEffect:LoadUiEffect(endingConfig.BgEffect)
    end
    if not string.IsNilOrEmpty(endingConfig.SpineBg) then
        self.SpineBg:LoadSpinePrefab(endingConfig.SpineBg)
        self.BgCommonBai.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(endingConfig.IconBg) then
        self.IconBg:SetRawImage(endingConfig.IconBg)
    end
    if not string.IsNilOrEmpty(endingConfig.Icon) then
        self.Icon:SetRawImage(endingConfig.Icon)
        self.Icon.gameObject:SetActiveEx(true)
    else
        self.Icon.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(endingConfig.RImgTitle) then
        self.RImgLine:SetRawImage(endingConfig.RImgTitle)
    end
    if self.TxtEndTitle then
        self.TxtEndTitle.text = endingConfig.Name
    end
    if self.TxtEndInfo then
        self.TxtEndInfo.text = endingConfig.Desc
        if not string.IsNilOrEmpty(endingConfig.DescColor) then
            self.TxtEndInfo.color = XUiHelper.Hexcolor2Color(endingConfig.DescColor)
        end
    end
    -- 新纪录
    --self.ImgNew.gameObject:SetActiveEx(self._Control:CheckEndingIsNew(endingId))
    self.ImgNew.gameObject:SetActiveEx(false)
    --self.TxtRole.text = XPlayer.Name
    --local time = XTime.GetServerNowTimestamp()
    --self.TxtTime.text = XTime.TimestampToGameDateTimeString(time, "yyyy-MM-dd")
    --self.TxtName.text = endingConfig.EndingDesc
    -- 显示特效
    for _, effectGo in pairs(self.EffectGo[endingConfig.PassType] or {}) do
        effectGo.gameObject:SetActiveEx(true)
    end
    -- 播放音效
    self._Control:AdventurePlayBgm(endingConfig.BgmCueId)
end

function XUiTheatre4EndLoading:OnBtnClickClick()
    -- 兼容处理 避免屏蔽剧情后黑屏
    XMVCA.XTheatre4:RemoveBlackUi()
    XLuaUiManager.PopThenOpen("UiTheatre4Settlement", self.EndingId)
end

return XUiTheatre4EndLoading
