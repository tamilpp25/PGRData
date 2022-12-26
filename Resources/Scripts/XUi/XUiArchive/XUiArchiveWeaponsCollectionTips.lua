local XUiArchiveWeaponsCollectionTips = XLuaUiManager.Register(XLuaUi, "UiArchiveWeaponsCollectionTips")
local FirstLevel = 0
function XUiArchiveWeaponsCollectionTips:OnStart(data)
    self.Data = data
    self:AutoAddListener()
end

function XUiArchiveWeaponsCollectionTips:OnEnable()
    if not self.Data then return end
    self.RImgOldIconLock.gameObject:SetActiveEx(self.Data.Level == FirstLevel)
    self.RImgOldIcon.gameObject:SetActiveEx(self.Data.Level ~= FirstLevel)
    self.RImgOldTitleText.gameObject:SetActiveEx(self.Data.Level ~= FirstLevel)

    if self.Data.OldIcon then
        self.RImgOldIcon:SetRawImage(self.Data.OldIcon)
        self.RImgOldIconLock:SetRawImage(self.Data.OldIcon)
    end
    if self.Data.CurIcon then
        self.RImgCurIcon:SetRawImage(self.Data.CurIcon)
    end

    self.RImgOldTitleText.text = self.Data.OldText or ""
    self.RImgCurTitleText.text = self.Data.CurText or ""
end

function XUiArchiveWeaponsCollectionTips:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
end