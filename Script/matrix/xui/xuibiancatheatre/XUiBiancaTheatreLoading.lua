local XUiBiancaTheatreLoading = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreLoading")

function XUiBiancaTheatreLoading:OnAwake()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.CurrentAdventureManager = self.TheatreManager:GetCurrentAdventureManager() or XDataCenter.BiancaTheatreManager.CreateAdventureManager()
    self.BtnClose.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiBiancaTheatreLoading:OnStart()
    XDataCenter.BiancaTheatreManager.CheckBgmPlay()
    self.CurrentChapter = self.CurrentAdventureManager:GetCurrentChapter()
    self.RImgIndexIcon:SetRawImage(self.CurrentChapter:GetOpenIndexIcon())
    self.RImgTitleIcon:SetRawImage(self.CurrentChapter:GetOpenTitleIcon())
    self.BgCommonBai:SetRawImage(self.CurrentChapter:GetOpenBg())

    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.BtnClose.gameObject:SetActiveEx(true)
    end, XScheduleManager.SECOND)
end

function XUiBiancaTheatreLoading:OnBtnCloseClick()
    XDataCenter.BiancaTheatreManager.SetIsAutoOpen(true)
    XLuaUiManager.Remove("UiBiancaTheatreLoading")
    XDataCenter.BiancaTheatreManager.CheckOpenView()
end

return XUiBiancaTheatreLoading
