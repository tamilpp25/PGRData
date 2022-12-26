local XUiGridAssignBuffPart = XClass(nil, "XUiGridAssignBuffPart")

local XUiGridAssignBuffText = require("XUi/XUiAssign/XUiGridAssignBuffText")

function XUiGridAssignBuffPart:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAssignBuffPart:InitComponent()
    self.BuffTextGridList = {}
    self.RImgRole.gameObject:SetActiveEx(false)
    self.GridOccupyBuff.gameObject:SetActiveEx(false)
    CsXUiHelper.RegisterClickEvent(self.BtnOccupy, function() self:OnBtnOccupyClick() end)
end

function XUiGridAssignBuffPart:GetBuffTextGrid(index)
    local grid = self.BuffTextGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridOccupyBuff)
        obj.transform:SetParent(self.PanelOccupyBuff, false)
        grid = XUiGridAssignBuffText.New(obj)
        self.BuffTextGridList[index] = grid
    end
    return grid
end

function XUiGridAssignBuffPart:ResetBuffTextList(len)
    if #self.BuffTextGridList > len then
        for i = len + 1, #self.BuffTextGridList do
            self.BuffTextGridList[i].GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridAssignBuffPart:Refresh(chapterId)
    local data = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    self.ChapterId = chapterId
    self.ChapterData = data

    self.TxtName.text = data:GetDesc()
    self.RImgRegionIcon:SetRawImage(data:GetIcon())

    local isOccupy = data:IsOccupy()
    local isCanAssign = data:CanAssign()
    local buffList = data:GetBuffDescList()

    self:ResetBuffTextList(#buffList)
    for i, buffDesc in ipairs(buffList) do
        local grid = self:GetBuffTextGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(buffDesc, isOccupy)
    end

    self.TxtCharacterName.text = ""
    if isCanAssign then
        self.Occupied.gameObject:SetActiveEx(isOccupy)
        self.UnOccupied.gameObject:SetActiveEx(not isOccupy)
        self.OccupiedPress.gameObject:SetActiveEx(isOccupy)
        self.UnOccupiedPress.gameObject:SetActiveEx(not isOccupy)
        self.UnLock.gameObject:SetActiveEx(false)
        self.UnLockPress.gameObject:SetActiveEx(false)

        if isOccupy then
            local characterIcon = data:GetOccupyCharacterIcon()
            self.RImgRole.gameObject:SetActiveEx(true)
            self.RImgRole:SetRawImage(characterIcon)
            self.TxtCharacterName.text = data:GetOccupyCharacterName()
        else
            self.RImgRole.gameObject:SetActiveEx(false)
        end
    else
        self.RImgRole.gameObject:SetActiveEx(false)

        self.Occupied.gameObject:SetActiveEx(false)
        self.UnOccupied.gameObject:SetActiveEx(false)
        self.OccupiedPress.gameObject:SetActiveEx(false)
        self.UnOccupiedPress.gameObject:SetActiveEx(false)
        self.UnLock.gameObject:SetActiveEx(true)
        self.UnLockPress.gameObject:SetActiveEx(true)
    end
    self.isCanAssign = isCanAssign
end

function XUiGridAssignBuffPart:OnBtnOccupyClick()
    if not self.ChapterData then
        return
    end

    if not self.isCanAssign then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignBuffOccupyLock"))  -- 未满足驻守条件，具体请在关卡中查看
        return
    end

    XDataCenter.FubenAssignManager.SelectChapterId = self.ChapterId
    XDataCenter.FubenAssignManager.SelectCharacterId = self.ChapterData:GetCharacterId()
    XLuaUiManager.Open("UiAssignOccupy")
end

return XUiGridAssignBuffPart