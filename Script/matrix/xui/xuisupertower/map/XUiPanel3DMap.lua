local XUiPanel3DMap = XClass(nil, "XUiPanel3DMap")
local XUiPanel3DMapChapter = require("XUi/XUiSuperTower/Map/XUiPanel3DMapChapter")

function XUiPanel3DMap:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.StageManager = XDataCenter.SuperTowerManager.GetStageManager()
    self.ChapterList = {}
    self.NewestThemeIndex = 0
    self:InitPanel()
end

function XUiPanel3DMap:InitPanel()
    self:InitChapter()
end

function XUiPanel3DMap:InitChapter()
    local themeList = self.StageManager:GetAllThemeList()
    for index,data in pairs(themeList) do
        if not self.ChapterList[index] then
            self:CreateChapter(index)
        end
    end
end

function XUiPanel3DMap:UpdatePanel()
    self:UpdateNewestThemeIndex()
    self:UpdateChapter()
    self:CheckCurShowChapterSaveData()
end

function XUiPanel3DMap:UpdateChapter()
    local themeList = self.StageManager:GetAllThemeList()
    for index,data in pairs(themeList) do
        local IsNew = self.NewestThemeIndex > 0 and self.NewestThemeIndex == index
        self.ChapterList[index]:UpdatePanel(data, index, IsNew)
    end
end

function XUiPanel3DMap:CheckCurShowChapterSaveData()
    local saveThemeIndex = XDataCenter.SuperTowerManager.GetCurSelectThemeIndex() or 0
    if saveThemeIndex ~= self.NewestThemeIndex then
        XDataCenter.SuperTowerManager.RemoveCurSelectThemeIndex()
    end
end

function XUiPanel3DMap:CreateChapter(index)
    local str = index < 10 and "Chapter0%d" or "Chapter%d"
    local panelName = string.format(str,index)
    local chapterObj = self.PanelChapterParent:GetObject(panelName)
    local effectObj = self.PanelChapterEffect:GetObject(panelName)
    if not chapterObj or not effectObj then
        XLog.Error("Is Not Exist Chapter".. panelName .." In 3DUI")
    else
        self.ChapterList[index] = XUiPanel3DMapChapter.New(chapterObj, effectObj, self.GridTheme, self.GridStage)
    end
end

function XUiPanel3DMap:UpdateNewestThemeIndex()
    local themeList = self.StageManager:GetAllThemeList()
    for index = #themeList , 1, -1 do
        local theme = themeList[index]
        if theme:CheckIsOpen() then
            local exTheme = themeList[index - 1]
            if not exTheme or (exTheme and exTheme:CheckIsAllClear()) then
                self.NewestThemeIndex = index
                break
            end
        end
    end
end

function XUiPanel3DMap:SelectTheme(index)
    local themeAllIndex = XDataCenter.SuperTowerManager.ThemeIndex.ThemeAll
    if index == themeAllIndex then
        for _,chapter in pairs(self.ChapterList) do
            chapter:StopStageTimer()
            chapter:ShowThemeInfo(true)
            chapter:ShowStageInfo(false)
        end
    else
        for _,chapter in pairs(self.ChapterList) do
            if chapter then
                chapter:StopStageTimer()
                chapter:ShowThemeInfo(false and index == chapter:GetIndex())
                chapter:ShowStageInfo(true and index == chapter:GetIndex())
            end
        end
        self:SaveCurShowChapterSaveData(index)
    end
    self.AnimeChapterParentEnable:PlayTimelineAnimation()
end

function XUiPanel3DMap:SaveCurShowChapterSaveData(index)
    if self.NewestThemeIndex == index then
        XDataCenter.SuperTowerManager.SaveCurSelectThemeIndex(index)
    end
end

function XUiPanel3DMap:StopAllStageTimer()
    for _,chapter in pairs(self.ChapterList) do
        if chapter then
            chapter:StopStageTimer()
        end
    end
end

function XUiPanel3DMap:GetChapterByIndex(index)
    return self.ChapterList[index]
end


return XUiPanel3DMap