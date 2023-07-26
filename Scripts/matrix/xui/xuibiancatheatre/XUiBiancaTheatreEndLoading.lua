local XUiBiancaTheatreEndLoading = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreEndLoading")

---@param adventureEnd XBiancaTheatreAdventureEnd
function XUiBiancaTheatreEndLoading:OnStart(adventureEnd)
    self.Transform:GetComponent("XPlayMusic").enabled = false
    --设置剧情已经播放完
    XDataCenter.BiancaTheatreManager.SetInMovieState(false)
    self.AdventureEnd = adventureEnd
    --标题
    self.RImgTitleName:SetRawImage(adventureEnd:GetRImgTitle())
    --背景
    local spineBgPath = adventureEnd:GetSpineBg()
    local iconBgPath = adventureEnd:GetBg()
    if self.SpineBg and not string.IsNilOrEmpty(spineBgPath) then
        self.SpineBg.transform:LoadSpinePrefab(spineBgPath)
    end
    if not string.IsNilOrEmpty(iconBgPath) then
        self.BgCommonBai:SetRawImage(iconBgPath)
    end
    --描述
    self.RImgTitle:SetRawImage(adventureEnd:GetRImgDesc())
    --图标
    local icon = adventureEnd:GetIcon()
    if self.IconBg then
        self.IconBg:SetSprite(adventureEnd:GetIconBg())
    end
    if icon then
        self.Icon:SetSprite(icon)
    end
    self.Icon.gameObject:SetActiveEx(icon and true or false)

    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:RegisterClickEvent(self.BtnClick, self.OnBtnClick)
    end, XScheduleManager.SECOND)
    XDataCenter.BiancaTheatreManager.CheckEndBgmPlay(adventureEnd)
end

function XUiBiancaTheatreEndLoading:OnBtnClick()
    XLuaUiManager.PopThenOpen("UiBiancaTheatreInfiniteSettleWin", self.AdventureEnd)
end

return XUiBiancaTheatreEndLoading
