local XUiAssignSelectOccupy = XLuaUiManager.Register(XLuaUi, "UiAssignSelectOccupy")

local XUiGridAssignSelectOccupy = require("XUi/XUiAssign/XUiGridAssignSelectOccupy")

function XUiAssignSelectOccupy:OnAwake()
    self:InitComponent()
end

function XUiAssignSelectOccupy:OnStart()
end

function XUiAssignSelectOccupy:InitComponent()
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnUnselect.CallBack = function() self:OnBtnUnselectClick() end
    CsXUiHelper.RegisterClickEvent(self.BtnClose, function() self:Close() end)
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.PanelNoCharacter.gameObject:SetActiveEx(false)
    self.BtnUnselect.gameObject:SetActiveEx(false)

    self.CharacterGridList = {}
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiAssignSelectOccupy:OnGetEvents()
    return { XEventId.EVENT_ASSIGN_SELECT_OCCUPY_BEGIN }
end

function XUiAssignSelectOccupy:OnNotify(evt)
    if evt == XEventId.EVENT_ASSIGN_SELECT_OCCUPY_BEGIN then
        self:Refresh()
    end
end

function XUiAssignSelectOccupy:OnEnable()
    -- 打开界面自动选中当前角色
    local chapterId = XDataCenter.FubenAssignManager.SelectChapterId
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    XDataCenter.FubenAssignManager.SelectCharacterId = chapterData:GetCharacterId()

    self:Refresh()
end

function XUiAssignSelectOccupy:OnDisable()
end

function XUiAssignSelectOccupy:GetCharacterGrid(index)
    local grid = self.CharacterGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridCharacter)
        obj.transform:SetParent(self.PanelCharacterContent, false)
        grid = XUiGridAssignSelectOccupy.New(self, obj)
        self.CharacterGridList[index] = grid
    end
    return grid
end

function XUiAssignSelectOccupy:ResetCharacterGridList(len)
    if #self.CharacterGridList > len then
        for _ = len + 1, #self.CharacterGridList do
            self.CharacterGridList.GameObject:SetActiveEx(false)
        end
    end
end

function XUiAssignSelectOccupy:Refresh()
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    local selectCharacterId = XDataCenter.FubenAssignManager.SelectCharacterId

    self.IsSelected = (selectCharacterId and selectCharacterId ~= 0)

    -- 选择了当前的驻守成员 则下阵
    if self.IsSelected and selectCharacterId == chapterData:GetCharacterId() then
        self.BtnUnselect.gameObject:SetActiveEx(true)
        self.BtnConfirm.gameObject:SetActiveEx(false)
    else
        self.BtnUnselect.gameObject:SetActiveEx(false)
        self.BtnConfirm.gameObject:SetActiveEx(true)
        self.BtnConfirm:SetButtonState(self.IsSelected and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end

    local ownCharacters = XDataCenter.CharacterManager.GetOwnCharacterList()

    -- 排序
    -- 未占领>已占领>不可委派 战力>解放阶段>品质
    local tmpChapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    local weights = {} -- 满足条件[1位] + 战力[6位] + 终解等级[1位] + 品质[1位]
    local CheckCharacterInOccupy = XDataCenter.FubenAssignManager.CheckCharacterInOccupy
    local GetCharacterAbility = XDataCenter.CharacterManager.GetCharacterAbility
    local GetCharacterGrowUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel
    for _, character in ipairs(ownCharacters) do
        local isInOccupy = CheckCharacterInOccupy(character.Id)
        local isMatch = tmpChapterData:IsCharConditionMatch(character.Id)
        local state = isMatch and (not isInOccupy and 3 or 2) or 1
        local ability = GetCharacterAbility(character)
        local growUpLevel = GetCharacterGrowUpLevel(character.Id)
        local weightState = state * 100000000
        local weightAbility = ability * 100
        local weightGrowUpLevel = growUpLevel * 10
        local weightQuality = character.Quality
        weights[character.Id] = weightState + weightAbility + weightGrowUpLevel + weightQuality
        -- XLog.Debug("Sort " .. XCharacterConfigs.GetCharacterTradeName(character.Id) .. ": " .. character.Id .. ", weight: " .. weights[character.Id], {"isInOccupy, isMatch, state, ability, growUpLevel", isInOccupy, isMatch, state, ability, growUpLevel})
    end

    table.sort(ownCharacters, function(a, b)
        return weights[a.Id] > weights[b.Id]
    end)

    self:ResetCharacterGridList(#ownCharacters)
    for i, character in ipairs(ownCharacters) do
        local grid = self:GetCharacterGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(character, self.ChapterId)
    end
end

function XUiAssignSelectOccupy:OnBtnConfirmClick()
    if not self.IsSelected then
        return
    end
    local selectCharacterId = XDataCenter.FubenAssignManager.SelectCharacterId
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    chapterData:SetCharacterId(selectCharacterId)
    XDataCenter.FubenAssignManager.AssignSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END) -- 刷新驻守界面
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupySelected")) -- 驻守成功
    end)
end

function XUiAssignSelectOccupy:OnBtnUnselectClick()
    local selectCharacterId = 0
    XDataCenter.FubenAssignManager.SelectCharacterId = selectCharacterId
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    chapterData:SetCharacterId(selectCharacterId)
    XDataCenter.FubenAssignManager.AssignSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END) -- 刷新驻守界面
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupyUnselected")) -- 下阵成功
    end)
end