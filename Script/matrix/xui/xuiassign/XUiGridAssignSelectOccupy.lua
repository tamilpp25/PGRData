local XUiGridAssignSelectOccupy = XClass(nil, "XUiGridAssignSelectOccupy")

function XUiGridAssignSelectOccupy:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.Ui = ui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.OnClickCallBack = function() self:OnClick() end
    self.IsMatch = false
    self.IsUsed = true
end

function XUiGridAssignSelectOccupy:Refresh(character, chapterId)
    self.Character = character
    self.ChapterId = chapterId
    if not self.Grid then
        self.Grid = XUiGridCharacter.New(self.Ui, self.RootUi, self.Character, self.OnClickCallBack)
    else
        self.Grid:UpdateGrid(self.Character)
    end
    self:UpdateCharacterInfo()

    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)

    self.IsSelect = (XDataCenter.FubenAssignManager.SelectCharacterId == self.Character.Id)
    self.IsMatch = chapterData:IsCharConditionMatch(self.Character.Id)
    self.OccupyChapterId = XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(self.Character.Id) or 0
    self.IsUsed = (self.OccupyChapterId ~= 0)
    self.IsCurrentChapter = (self.OccupyChapterId == self.ChapterId)

    self.Grid:SetSelect(self.IsSelect)
    self.PanelStateUsed.gameObject:SetActiveEx(self.IsMatch and self.IsUsed)
    self.PanelStateNotMatch.gameObject:SetActiveEx(not self.IsMatch)
end

function XUiGridAssignSelectOccupy:UpdateCharacterInfo()
    local characterId = self.Character.Id
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)
    local levelIcon = XExhibitionConfigs.GetExhibitionLevelIconByLevel(growUpLevel)
    if not levelIcon or levelIcon == "" then
        self.ImgClassIcon.gameObject:SetActive(false)
    else
        self.RootUi:SetUiSprite(self.ImgClassIcon, levelIcon)
        self.ImgClassIcon.gameObject:SetActive(true)
    end
end


function XUiGridAssignSelectOccupy:OnClick()
    if not (self.ChapterId and self.Character) then
        return
    end

    if not self.IsMatch then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectNotMatch")) -- "该成员不符合条件"
        return
    end

    if self.IsUsed and not self.IsCurrentChapter then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectIsUsed")) -- "该成员已在其他区域驻守"
        return
    end

    local characterId = self.Character.Id
    self.Grid:SetSelect(true)
    XDataCenter.FubenAssignManager.SelectCharacterId = characterId
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_BEGIN)
end

return XUiGridAssignSelectOccupy