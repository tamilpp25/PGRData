local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")
---@class XUiSelectCharacterAssignOccupy:XUiSelectCharacterBase
local XUiSelectCharacterAssignOccupy = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectCharacterAssignOccupy")
local XUiGridCondition = require("XUi/XUiExhibition/XUiGridCondition")

function XUiSelectCharacterAssignOccupy:OnStartCb(chapterId, targetCharacter)
    self.ChapterId = chapterId
    self.TargetCharacter = targetCharacter

    self.Chapter = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    self.PanelEquips:SetForbidGotoEquip(true)
    self:SetMidButtonActive(false)
end

function XUiSelectCharacterAssignOccupy:GetGridProxy()
    local XUiGridSelectCharacter = require("XUi/XUiAssign/XUiGridSelectCharacter")
    return XUiGridSelectCharacter
end

function XUiSelectCharacterAssignOccupy:GetRefreshFun()
    local fun = function (index, grid, char)
        grid:Refresh(char, self.Chapter)
    end
    return fun
end

function XUiSelectCharacterAssignOccupy:GetOverrideSortTable()
    local sortOverride = 
    {
        CheckFunList = 
        {   
            -- 符合条件未驻守
            [CharacterSortFunType.Custom1] = function (idA, idB)
                local isAMatch = self.Chapter:IsCharConditionMatch(idA) and not XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA)
                local isBMatch = self.Chapter:IsCharConditionMatch(idB) and not XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB)
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
            -- 已驻守其他chapter
            [CharacterSortFunType.Custom2] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idA) ~= self.ChapterId
                local isBMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idB) ~= self.ChapterId
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
            -- 已驻守其当前chapter
            [CharacterSortFunType.Custom3] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idA) == self.ChapterId
                local isBMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idB) == self.ChapterId
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
        },
        SortFunList = 
        {
            [CharacterSortFunType.Custom1] = function (idA, idB)
                local isAMatch = self.Chapter:IsCharConditionMatch(idA) and not XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA)
                local isBMatch = self.Chapter:IsCharConditionMatch(idB) and not XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB)
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
            [CharacterSortFunType.Custom2] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idA) ~= self.ChapterId
                local isBMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idB) ~= self.ChapterId
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
            [CharacterSortFunType.Custom3] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idA) == self.ChapterId
                local isBMatch = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(idB) == self.ChapterId
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
        }
    }
    return sortOverride
end

function XUiSelectCharacterAssignOccupy:OnTagClickCb()
    self.Super.OnTagClickCb(self)
    self.MidButtons.gameObject:SetActiveEx(false)
end

function XUiSelectCharacterAssignOccupy:RefreshConditionInfo()
    local conditionIds = self.Chapter:GetSelectCharCondition()
    local ConditionDesNum = 4
    for i = 1, ConditionDesNum do
        local conditionGrid = self.ConditionGrids[i]
        if not conditionGrid then
            conditionGrid = XUiGridCondition.New(self["GridCondition" .. i])
            self.ConditionGrids[i] = conditionGrid
        end

        local conditionData = conditionIds[i]
        if conditionData then
            local skipId = self.Chapter:GetCfg().SelectCharSkipId[i]
            conditionGrid:Refresh(conditionData, self.CurCharacter.Id, skipId)
        end
        conditionGrid.GameObject:SetActiveEx(XTool.IsNumberValid(conditionData))
    end
    self:SetPanleConditonActive(true)
end

function XUiSelectCharacterAssignOccupy:RefreshMid()
    local isOccupyChar = self.Chapter:GetCharacterId() == self.CurCharacter.Id
    self.BtnJoin.gameObject:SetActiveEx(not isOccupyChar and self.Chapter:IsCharConditionMatch(self.CurCharacter.Id))
    self.BtnQuit.gameObject:SetActiveEx(isOccupyChar)
    self.BtnJoin.gameObject:GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("BtnOccupyJoinImg1"))
    self.TxtConditionTitle.text = CS.XTextManager.GetText("AssignSendMemberCalled")
end

function XUiSelectCharacterAssignOccupy:OnBtnJoinClick()
    local selectCharacterId = self.CurCharacter.Id

    if not self.Chapter:IsCharConditionMatch(selectCharacterId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectNotMatch")) -- "该成员不符合条件"
        return
    end

    local inOtherChapterId = XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(selectCharacterId)
    if inOtherChapterId and inOtherChapterId ~= self.ChapterId then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectIsUsed")) -- "该成员已在其他区域驻守"
        return
    end

    XDataCenter.FubenAssignManager.AssignSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupySelected")) -- 驻守成功
    end)
end

function XUiSelectCharacterAssignOccupy:OnBtnQuitClick()
    local selectCharacterId = 0

    XDataCenter.FubenAssignManager.AssignSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupyUnselected")) -- 卸下成功
    end)
end

return XUiSelectCharacterAssignOccupy
