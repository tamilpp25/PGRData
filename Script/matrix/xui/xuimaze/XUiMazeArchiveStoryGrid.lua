---@class XUiMazeArchiveStoryGrid
local XUiMazeArchiveStoryGrid = XClass(nil, "XUiMazeArchiveStoryGrid")

function XUiMazeArchiveStoryGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.StoryBtn, self.OnClick)
end

---@param data XMazeStoryData
function XUiMazeArchiveStoryGrid:Update(data)
    self._Data = data
    if data.Icon then
        self.RImgHeadBg:SetRawImage(data.Icon)
        self.RImgHead:SetRawImage(data.Icon)
        self.RImgHeadBg.gameObject:SetActiveEx(true)
        self.RImgHead.gameObject:SetActiveEx(true)
    else
        self.RImgHeadBg.gameObject:SetActiveEx(false)
        self.RImgHead.gameObject:SetActiveEx(false)
    end
    self.TxtStoryTitle.text = data.Name
    self.PanelLock.gameObject:SetActiveEx(not data.IsPass)
    self.TxtLock.text = XUiHelper.ReadTextWithNewLine("MazeStoryUnlock", data.NamePartner)
end

function XUiMazeArchiveStoryGrid:OnClick()
    if self._Data.IsPass then
        XDataCenter.MovieManager.PlayMovie(self._Data.StoryId)
    else
        XUiManager.TipText("MazeStoryLock")
    end
end

return XUiMazeArchiveStoryGrid