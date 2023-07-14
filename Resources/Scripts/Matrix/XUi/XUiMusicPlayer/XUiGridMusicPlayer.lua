--
-- Author: wujie
-- Note: 播放器专辑格子相关

local UiGridMusicPlayer = XClass(nil, "UiGridMusicPlayer")

function UiGridMusicPlayer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function UiGridMusicPlayer:Refresh(id)
    self.Id = id
    local template = XMusicPlayerConfigs.GetAlbumTemplateById(id)
    local coverPath = template.Cover
    self.RImgCoverSelect:SetRawImage(coverPath)
    self.RImgCoverNotSelect:SetRawImage(coverPath)
end

function UiGridMusicPlayer:UpdateSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    self.PanelNotSelect.gameObject:SetActiveEx(not isSelect)
end

return UiGridMusicPlayer