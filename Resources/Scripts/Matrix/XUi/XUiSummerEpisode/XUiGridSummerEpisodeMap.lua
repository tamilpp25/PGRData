local XUiGridSummerEpisodeMap = XClass(nil, "XUiGridSummerEpisodeMap")

function XUiGridSummerEpisodeMap:Ctor(ui,stageId,rootUi)
    self.GameObject = ui
    self.Transform = ui.transform
    self.StageId = stageId
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitUiView()
end

function XUiGridSummerEpisodeMap:InitUiView()
    self.TxtMapName.text = XDataCenter.FubenManager.GetStageName(self.StageId)
    local config = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if config then
        self.RImgMap:SetRawImage(config.StoryIcon)
    end
end

function XUiGridSummerEpisodeMap:SetClickEvent(event)
    self.RootUi:RegisterClickEvent(self.BtnMap, function()
        event(self.StageId)
    end)
end

function XUiGridSummerEpisodeMap:SetSelect(isSelect)
    self.Activate.gameObject:SetActiveEx(isSelect)
end

return XUiGridSummerEpisodeMap