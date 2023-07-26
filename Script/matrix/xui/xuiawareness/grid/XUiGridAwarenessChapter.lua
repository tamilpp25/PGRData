local XUiGridAwarenessChapter = XClass(nil, "XUiGridAwarenessChapter")

function XUiGridAwarenessChapter:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAwarenessChapter:InitComponent()
    CsXUiHelper.RegisterClickEvent(self.BtnRed, function() self:OnChapterClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnYellow, function() self:OnChapterClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnOccupy, function() self:OnBtnOccupyClick() end)
end

function XUiGridAwarenessChapter:SetCurrBtn()
    local targetBtn = nil
    if self.ChapterData:IsPass() then
        targetBtn = self.BtnYellow
        self.BtnRed.gameObject:SetActiveEx(false)
    else
        targetBtn = self.BtnRed
        self.BtnYellow.gameObject:SetActiveEx(false)
    end
    targetBtn.gameObject:SetActiveEx(true)
    return targetBtn
end

function XUiGridAwarenessChapter:OnChapterClick()
    if not self.ChapterData then
        return
    end
    XLuaUiManager.Open("UiAwarenessMainDetail", self.ChapterData:GetId())
end

function XUiGridAwarenessChapter:OnBtnOccupyClick()
    if not self.ChapterData then
        return
    end
    XLuaUiManager.Open("UiAwarenessOccupy", self.ChapterData:GetId())
end

function XUiGridAwarenessChapter:Refresh(chapterId)
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataById(chapterId)
    self.ChapterData = data
    self.ChapterId = chapterId
    
    -- 设置btn
    self.Btn = self:SetCurrBtn()
    self.RegionIcon:SetRawImage(data:GetIcon())
    self.Btn:SetNameByGroup(0, data:GetName())
    self.BtnOccupy.gameObject:SetActiveEx(data:CanAssign())
    if data:CanAssign() then
        self.BtnOccupy.gameObject.name = "BtnOccupyActive"
    end
    self.RImgRole.transform.parent.gameObject:SetActiveEx(data:IsOccupy())
    self.PanelEffect.gameObject:SetActiveEx(not data:IsOccupy())
    self.TxtNum.text = data:GetCfg().ChapterNo
    self.Red.gameObject:SetActiveEx(data:IsRed())
    
    if data:IsOccupy() then
        self.RImgRole:SetRawImage(data:GetOccupyCharacterIcon())
    end
end

return XUiGridAwarenessChapter
