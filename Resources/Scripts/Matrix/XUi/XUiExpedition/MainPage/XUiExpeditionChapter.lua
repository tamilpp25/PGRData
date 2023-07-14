-- 虚像地平线章节控件
local XUiExpeditionChapter = XClass(nil, "XUiExpeditionChapter")
local XUiExpeditionChapterComponent = require("XUi/XUiExpedition/MainPage/XUiExpeditionChapterComponent")
function XUiExpeditionChapter:Ctor(rootUi)
    self.RootUi = rootUi
    self.Chapter = XDataCenter.ExpeditionManager.GetCurrentChapter()
end
--=============
--显示章节
--@param difficulty:难度
--=============
function XUiExpeditionChapter:Show(difficulty)
    if (not difficulty) or (not self.Chapter) then return end
    local chapterName = "Chapter" .. difficulty
    if not self[chapterName] then
        local chapterPrefab
        if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
            chapterPrefab = self.RootUi.PanelStageListNormal.transform:LoadPrefab(self.Chapter:GetChapterPrefabByDifficulty(difficulty))
        else
            chapterPrefab = self.RootUi.PanelStageListNightmare.transform:LoadPrefab(self.Chapter:GetChapterPrefabByDifficulty(difficulty))
        end
        if chapterPrefab then
            self[chapterName] = XUiExpeditionChapterComponent.New(self.RootUi, chapterPrefab, difficulty)
            self[chapterName]:RefreshData(difficulty)
            if self.CurrentComponent then self.CurrentComponent:Hide() end
            self.CurrentComponent = self[chapterName]
            self.CurrentComponent:Show()
        end
    else
        if self.CurrentComponent and self.CurrentComponent ~= self[chapterName] then self.CurrentComponent:Hide() end
        self.CurrentComponent = self[chapterName]
        self.CurrentComponent:Show()
    end
    self.CurrentComponent:RefreshData()
    self.RootUi:ChangeBg(self.Chapter:GetStageBgByDifficult(difficulty))
    self.RootUi:ChangeBgFx(self.Chapter:GetChapterBgFxByDifficult(difficulty))
    self.RootUi:ChangeRewardIcon(self.Chapter:GetRewardIconByDifficult(difficulty))
end

return XUiExpeditionChapter