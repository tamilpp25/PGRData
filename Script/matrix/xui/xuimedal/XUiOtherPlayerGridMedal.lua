XUiOtherPlayerGridMedal = XClass(nil, "XUiOtherPlayerGridMedal")

function XUiOtherPlayerGridMedal:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.IsLock = false
end

function XUiOtherPlayerGridMedal:AutoAddListener()
    self.BtnMedal.CallBack = function()
        self:OnBtnMedal()
    end
end

function XUiOtherPlayerGridMedal:OnBtnMedal()
    if not self.IsLock then
        self:OnOpenMedalDetail(self.MedalId)
    end
end

function XUiOtherPlayerGridMedal:UpdateGrid(chapter, medalInfos)
    self.MedalId = chapter.Id
    self.MedalInfos = medalInfos
    if chapter.MedalImg ~= nil then
        self.IconMedalUnLock:SetRawImage(chapter.MedalImg)
        self.IconMedalLock:SetRawImage(chapter.MedalImg)
    end
    self:ShowLock(self:CheckMedalUnlock(self.MedalId))
end

function XUiOtherPlayerGridMedal:ShowLock(unLock)
    self.IconMedalUnLock.gameObject:SetActiveEx(unLock)
    self.IsLock = not unLock
end

function XUiOtherPlayerGridMedal:CheckMedalUnlock(id)
    for _, v in pairs(self.MedalInfos) do
        if v.Id == id then
            return true
        end
    end
    return false
end

function XUiOtherPlayerGridMedal:OnOpenMedalDetail(id)
    local infoList = XDataCenter.MedalManager.CreateOtherPlayerMedalList(self.MedalInfos)
    local info = infoList[id]
    if info then
        XLuaUiManager.Open("UiMeadalDetail", info, XDataCenter.MedalManager.InType.OtherPlayer)
    end
end