local XUiAwarenessOccupy = XLuaUiManager.Register(XLuaUi, "UiAwarenessOccupy")
local XUiGridAssignBuffText = require("XUi/XUiAssign/XUiGridAssignBuffText")

function XUiAwarenessOccupy:OnAwake()
    self:InitButton()
    self.ConditionGrids = {}
    self.BuffGrids = nil
    self.CurrSeleIndex = nil
end

function XUiAwarenessOccupy:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnOccupy, self.OnBtnOccupyClick)

    self:RegisterClickEvent(self.BtnLeft, function () self:OnBtnChangeTag(true) end)
    self:RegisterClickEvent(self.BtnRight, function () self:OnBtnChangeTag(false) end)

    self.TabBtns = 
    { 
        self.BtnNumber1,
        self.BtnNumber2,
        self.BtnNumber3,
        self.BtnNumber4,
        self.BtnNumber5,
        self.BtnNumber6,
    }
    self.BtnGridGroup:Init(self.TabBtns, function(index) self:OnSelectTab(index) end)
    for index, btn in pairs(self.TabBtns) do
        local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(index)
        if not chapterData:CanAssign() then
            btn:SetDisable(true)
        end
    end
end

function XUiAwarenessOccupy:OnSelectTab(index)
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(index)
    if not data:CanAssign() then
        XUiManager.TipError(CS.XTextManager.GetText("CopyToOpen", data:GetName()))
        return
    end
    
    self.CurrSeleIndex = index
    self.CurrChapterData = data
    self:RefreshOccupyInfo(self.CurrChapterData)
end

function XUiAwarenessOccupy:OnStart(chapterId)
    self.InitChapterId = chapterId
end

function XUiAwarenessOccupy:OnEnable()
    local initChapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.InitChapterId)
    local index = initChapterData:GetChapterOrder() or 1
    self.BtnGridGroup:SelectIndex(index)
    self.TabBtns[index]:SetButtonState(CS.UiButtonState.Select)
end

function XUiAwarenessOccupy:RefreshOccupyInfo(chapterData)
    -- 驻守角色
    local isOccupy = chapterData:IsOccupy()
    self.RawImage.gameObject:SetActiveEx(isOccupy)
    self.Text_Hint.gameObject:SetActiveEx(isOccupy)
    self.Image_Add.gameObject:SetActiveEx(not isOccupy)
    if isOccupy then
        self.RawImage:SetRawImage(chapterData:GetCharacterBodyIcon())
    end

    -- 条件
    local selectConditions = chapterData:GetSelectCharCondition()
    for i = 1, #selectConditions, 1 do
        local grid = self.ConditionGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridOccupyCondition, self.GridOccupyCondition.parent)
            grid = XUiGridAssignBuffText.New(obj)
            self.ConditionGrids[i] = grid
        end
        local str = XConditionManager.GetConditionTemplate(selectConditions[i]).Desc
        grid:Refresh(str, true)
    end
    self.GridOccupyCondition.gameObject:SetActiveEx(false)
    
    -- 加成
    local grid = self.BuffGrids
    if not grid then
        grid = XUiGridAssignBuffText.New(self.GridOccupyBuff.gameObject)
        self.BuffGrids = grid
    end
    grid:Refresh(chapterData:GetBuffDesc(), true)
end

function XUiAwarenessOccupy:OnBtnChangeTag(isLeft)
    local passNum = isLeft and -1 or 1
    local maxNum = isLeft and 1 or #self.TabBtns

    local targetIndex = self.CurrSeleIndex

    for index = self.CurrSeleIndex, maxNum, passNum do
        local data = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(index)
        if index ~= self.CurrSeleIndex and data:CanAssign() then
            targetIndex = index
            break
        end
    end
    self.BtnGridGroup:SelectIndex(targetIndex)
end

function XUiAwarenessOccupy:OnBtnOccupyClick()
    XLuaUiManager.Open("UiAwarenessSelectCharacter", self.CurrChapterData:GetId())
end
