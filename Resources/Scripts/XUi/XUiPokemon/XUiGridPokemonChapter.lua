local XUiGridPokemonChapter = XClass(nil,"XUiGridPokemonChapter")
function XUiGridPokemonChapter:Ctor(ui)
    ---@type UnityEngine.GameObject
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridPokemonChapter:Refresh(index)
    local chapters = XDataCenter.PokemonManager.GetChapters()
    self.ChapterCfg = chapters[index]
    self.TxtName.text = XPokemonConfigs.GetChapterName(self.ChapterCfg.Id)
    self.RImgDz:SetRawImage(XPokemonConfigs.GetChapterBackground(self.ChapterCfg.Id))
    local isOpen,desc = self:CheckIsOpen()
    self.Imglock.gameObject:SetActiveEx(not isOpen)
    self.TxtUnlockCondition.text = desc
    local passCount = XDataCenter.PokemonManager.GetPassedCountByChapterId(self.ChapterCfg.Id)
    local totalCount = XPokemonConfigs.GetStageCountByChapter(XDataCenter.PokemonManager.GetCurrActivityId(),self.ChapterCfg.Id)
    self.TxtProgress.text = CS.XTextManager.GetText("PokemonChapterProgress",passCount,totalCount)
end

function XUiGridPokemonChapter:CheckIsOpen()
    local isInTime = XFunctionManager.CheckInTimeByTimeId(self.ChapterCfg.TimeId)
    local isOpen = true
    local desc = ""
    local condition = self.ChapterCfg.OpenCondition
    if condition and condition ~= 0 then
        isOpen,desc = XConditionManager.CheckCondition(self.ChapterCfg.OpenCondition)
    end
    return isInTime and isOpen, isInTime and desc or XUiHelper.GetInTimeDesc(XFunctionManager.GetStartTimeByTimeId(self.ChapterCfg.TimeId), XFunctionManager.GetEndTimeByTimeId(self.ChapterCfg.TimeId))
end

function XUiGridPokemonChapter:OnClickGrid(index)
    local isOpen,desc = self:CheckIsOpen()
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    XDataCenter.PokemonManager.SetSelectChapter(index)
    XLuaUiManager.Open("UiPokemonMain")
end

return XUiGridPokemonChapter