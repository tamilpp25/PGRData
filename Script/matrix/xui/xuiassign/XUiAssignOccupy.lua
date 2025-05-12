local XUiAssignOccupy = XLuaUiManager.Register(XLuaUi, "UiAssignOccupy")

local XUiGridAssignBuffText = require("XUi/XUiAssign/XUiGridAssignBuffText")

function XUiAssignOccupy:OnAwake()
    self:InitComponent()
    self.ConditionGrids = {}
    self.BuffGrids = {}
end

function XUiAssignOccupy:OnStart(chapterId)
    self.ChapterId = chapterId
end

function XUiAssignOccupy:OnEnable()

    -- self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self:Refresh()
end

function XUiAssignOccupy:OnDisable()

end

function XUiAssignOccupy:OnGetEvents()
    return { XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END }
end

function XUiAssignOccupy:OnNotify(evt)
    if evt == XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END then
        self:Refresh()
    end
end

function XUiAssignOccupy:InitComponent()
    self.BuffTextGridList = {}
    self.GridOccupyBuff.gameObject:SetActiveEx(false)

    self.ConditionTxtList = {}
    self.TxtCondition.gameObject:SetActiveEx(false)

    self.RawImage.gameObject:SetActiveEx(false)
    self.Image_Add.gameObject:SetActiveEx(false)
    self.Text_Hint.gameObject:SetActiveEx(false)

    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTangchuangCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnOccupy, self.OnBtnOccupyClick)
end

function XUiAssignOccupy:GetBuffTextGrid(index)
    local grid = self.BuffTextGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridOccupyBuff)
        obj.transform:SetParent(self.PanelOccupyBuff, false)
        grid = XUiGridAssignBuffText.New(obj)
        self.BuffTextGridList[index] = grid
    end
    return grid
end

function XUiAssignOccupy:ResetBuffTextList(len)
    if #self.BuffTextGridList > len then
        for i = len + 1, #self.BuffTextGridList do
            self.BuffTextGridList[i].GameObject:SetActiveEx(false)
        end
    end
end

function XUiAssignOccupy:Refresh()
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    local isOccupy = chapterData:IsOccupy()
    if isOccupy then
        self.Image_Add.gameObject:SetActiveEx(false)
        self.RawImage:SetRawImage(chapterData:GetCharacterBodyIcon())
        self.RawImage.gameObject:SetActiveEx(true)
        self.Text_Hint.gameObject:SetActiveEx(true)
    else
        self.Image_Add.gameObject:SetActiveEx(true)
        self.RawImage.gameObject:SetActiveEx(false)
        self.Text_Hint.gameObject:SetActiveEx(false)
    end

    local selectConditions = chapterData:GetSelectCharCondition()
    for i = 1, #selectConditions, 1 do
        local grid = self.ConditionGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridOccupyBuff, self.PanelOccupyCondition)
            grid = XUiGridAssignBuffText.New(obj)
            self.ConditionGrids[i] = grid
        end
        local str = XConditionManager.GetConditionTemplate(selectConditions[i]).Desc
        grid:Refresh(str, true)
        grid.GameObject:SetActiveEx(true)
    end

    local buffList = chapterData:GetBuffDescList()
    for i = 1, #buffList, 1 do
        local grid = self.BuffGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridOccupyBuff2, self.PanelOccupyBuff)
            grid = XUiGridAssignBuffText.New(obj)
            self.BuffGrids[i] = grid
        end
        local str = buffList[i]
        grid:Refresh(str, true)
        grid.ImgSkill:SetRawImage(chapterData:GetSkillIcon())
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiAssignOccupy:OnBtnTangchuangCloseClick()
    self:Close()
end

function XUiAssignOccupy:OnBtnCloseClick()
    self:Close()
end

function XUiAssignOccupy:OnBtnOccupyClick()
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    local characterId = chapterData:GetCharacterId()
    -- XLuaUiManager.Open("UiAssignSelectOccupy")
    -- XLuaUiManager.Open("UiAssignSelectCharacter", self.ChapterId, characterId)
    XLuaUiManager.Open("UiSelectCharacterAssignOccupy", characterId, self.ChapterId)
    self:Close()
end