local XUiColorTableEnterMovie = XLuaUiManager.Register(XLuaUi,"UiColorTableEnterMovie")

function XUiColorTableEnterMovie:OnAwake()
    self.GameManager = XDataCenter.ColorTableManager.GetGameManager()
end

function XUiColorTableEnterMovie:OnStart(dramaId, callback, movieId, name, desc, icon)
    self.DramaId = dramaId
    self.CallBack = callback
    self.MovieId = movieId
    self.Name = name
    self.Desc = desc
    self.Icon = icon
    self.IsShowNew = false
    if self.DramaId then
        self.MovieId = XColorTableConfigs.GetDramaStoryId(self.DramaId)
        self.Name = XColorTableConfigs.GetDramaName(self.DramaId)
        self.Desc = XColorTableConfigs.GetDramaDesc(self.DramaId)
        self.Icon = XColorTableConfigs.GetDramaIcon(self.DramaId)
        self.IsShowNew = not XDataCenter.ColorTableManager.IsDramaPlayed(self.DramaId)
    end
    self.PanelNew = self.TxtStoryName.transform:Find("PanelNew")
    self:_AddBtnListener()
    self:_Refresh()
end

-- private
----------------------------------------------------------------

function XUiColorTableEnterMovie:_Refresh()
    self.PanelNew.gameObject:SetActiveEx(self.IsShowNew)
    self.TxtStoryName.text = self.Name
    self.TxtStoryDec.text = self.Desc
    self.RImgStory:SetRawImage(self.Icon)
end

function XUiColorTableEnterMovie:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterStory, self._OnBtnEnterStoryClick)
end

function XUiColorTableEnterMovie:_OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiColorTableEnterMovie:_OnBtnEnterStoryClick()
    if self.DramaId then
        XDataCenter.ColorTableManager.SetDramaPlayed(self.DramaId)
    end

    if self.CallBack then
        XDataCenter.MovieManager.PlayMovie(self.MovieId, self.CallBack)
    else
        XDataCenter.MovieManager.PlayMovie(self.MovieId)
    end
end

----------------------------------------------------------------