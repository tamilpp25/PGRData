local XUiGridMedal = XClass(nil, "XUiGridMedal")

function XUiGridMedal:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridMedal:AutoAddListener()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridMedal:OnBtnSelect()
    XLuaUiManager.Open("UiMeadalDetail", self.Chapter, self.InType, function() self:UpdateRedPoint() end)
end

function XUiGridMedal:UpdateGrid(chapter,parent)
    self.Parent = parent
    self.Chapter = chapter
    if chapter.MedalImg ~= nil then
        self.ImgMedalIcon:SetRawImage(chapter.MedalImg)
        self.ImgMedalIconlock:SetRawImage(chapter.MedalImg)
    end

    self.TxtMedalName.text = chapter.Name
    local IsLock = not XPlayer.IsMedalUnlock(self.Chapter.Id)
    self:ShowUesing(XPlayer.CurrMedalId == self.Chapter.Id)

    self:ShowLock(IsLock)
    self:ShowRedPoint(XDataCenter.MedalManager.CheckIsNewMedalById(self.Chapter.Id,XMedalConfigs.MedalType.Normal))
end

function XUiGridMedal:ShowUesing(bShow)
    self.LabelPress.gameObject:SetActiveEx(bShow)
end

function XUiGridMedal:ShowLock(Lock)
    self.LabelLock.gameObject:SetActiveEx(Lock)
    self.ImgMedalIcon.gameObject:SetActiveEx(not Lock)
    self.ImgMedalIconlock.gameObject:SetActiveEx(Lock)
end

function XUiGridMedal:UpdateRedPoint()
    self:ShowRedPoint(XDataCenter.MedalManager.CheckIsNewMedalById(self.Chapter.Id, self.Chapter.Type))
end

function XUiGridMedal:ShowRedPoint(bShow)
    self.Red.gameObject:SetActiveEx(bShow)
end

return XUiGridMedal