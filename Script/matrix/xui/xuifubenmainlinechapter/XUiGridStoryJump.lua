---@class XUiGridStoryJump
---@field BtnStoryJump XUiComponent.XUiButton
local XUiGridStoryJump = XClass(nil, "XUiGridStoryJump")

function XUiGridStoryJump:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnStoryJump, self.OnBtnStoryJumpClick)
end

function XUiGridStoryJump:Refresh(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self.SkipId = data.SkipId
    local chapterType = data.ChapterType
    local isPrequel = chapterType == XFubenConfigs.ChapterType.Prequel
    self.NormalPanelTxt.gameObject:SetActiveEx(isPrequel)
    self.PressPanelTxt.gameObject:SetActiveEx(isPrequel)
    if isPrequel then
        local prequelChapter = XPrequelConfigs.GetPrequelChapterById(data.ChapterId)
        self.BtnStoryJump:SetNameByGroup(0, XCharacterConfigs.GetCharacterTradeName(prequelChapter.CharacterId))
    end
    self.BtnStoryJump:SetNameByGroup(1, data.SkipName)
    self.BtnStoryJump:SetRawImage(data.ImgPath)
end

function XUiGridStoryJump:OnBtnStoryJumpClick()
    if XTool.IsNumberValid(self.SkipId) then
        XFunctionManager.SkipInterface(self.SkipId)
    end
end

return XUiGridStoryJump