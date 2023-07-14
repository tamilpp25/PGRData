local XUiAssignOccupy = XLuaUiManager.Register(XLuaUi, "UiAssignOccupy")

local XUiGridAssignBuffText = require("XUi/XUiAssign/XUiGridAssignBuffText")

function XUiAssignOccupy:OnAwake()
    self:InitComponent()
end

function XUiAssignOccupy:OnStart()
end

function XUiAssignOccupy:OnEnable()
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self:Refresh()
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
    for i = 1, XDataCenter.FubenAssignManager.MaxSelectConditionNum do
        local txt = CS.UnityEngine.Object.Instantiate(self.TxtCondition)
        txt.transform:SetParent(self.PanelCondition, false)
        self.ConditionTxtList[i] = txt
    end

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
    for i, txt in ipairs(self.ConditionTxtList) do
        local conditionId = selectConditions[i]
        if conditionId then
            txt.gameObject:SetActiveEx(true)
            -- txt.color = XDataCenter.FubenAssignManager.SelectConditionColor[(XConditionManager.CheckCondition(conditionId))]
            txt.text = XConditionManager.GetConditionTemplate(conditionId).Desc
        else
            txt.gameObject:SetActiveEx(false)
        end
    end

    local buffList = chapterData:GetBuffDescList()
    self:ResetBuffTextList(#buffList)
    for i, buffDesc in ipairs(buffList) do
        local grid = self:GetBuffTextGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(buffDesc, isOccupy)
    end
end

function XUiAssignOccupy:OnBtnTangchuangCloseClick()
    self:Close()
end

function XUiAssignOccupy:OnBtnCloseClick()
    self:Close()
end

function XUiAssignOccupy:OnBtnOccupyClick()
    XLuaUiManager.Open("UiAssignSelectOccupy")
end