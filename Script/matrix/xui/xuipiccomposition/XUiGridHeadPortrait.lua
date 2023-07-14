XUiGridHeadPortrait = XClass(nil, "XUiGridHeadPortrait")

function XUiGridHeadPortrait:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridHeadPortrait:AutoAddListener()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiGridHeadPortrait:OnBtnRoleClick()
    self.Base:SetData(self.CharacterId)
    self:SetSelectShow(self.Base)
    self.Base.OldSelectGrig:SetSelectShow(self.Base)
    self.Base.OldSelectGrig = self
end

function XUiGridHeadPortrait:UpdateGrid(chapter, parent)
    self.Base = parent
    self.CharacterId = chapter.Id
    if chapter.Icon ~= nil then
        self.UnLockImgHeadImg:SetRawImage(chapter.Icon)
    end

    self:SetSelectShow(parent)
end

function XUiGridHeadPortrait:SetSelectShow(parent)
    if parent.SelectCharacterId == self.CharacterId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if not self.Base.OldSelectGrig then
        self.Base.OldSelectGrig = self
    end
end

function XUiGridHeadPortrait:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActiveEx(bShow)
end