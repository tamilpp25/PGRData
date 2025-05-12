local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")
---@class XUiSelectCharacterAwarenessOccupy:XUiSelectCharacterBase
local XUiSelectCharacterAwarenessOccupy = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectCharacterAwarenessOccupy")
local XUiGridCondition = require("XUi/XUiExhibition/XUiGridCondition")

function XUiSelectCharacterAwarenessOccupy:OnStartCb(chapterId, targetCharacter)
    self.ChapterId = chapterId
    self.TargetCharacter = targetCharacter

    self.Chapter = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
    self.PanelEquips:SetForbidGotoEquip(true)
    self:SetMidButtonActive(false)
end

function XUiSelectCharacterAwarenessOccupy:GetGridProxy()
    local XUiGridAwarenessSelectCharacter = require("XUi/XUiAwareness/Grid/XUiGridAwarenessSelectCharacter")
    return XUiGridAwarenessSelectCharacter
end

function XUiSelectCharacterAwarenessOccupy:GetRefreshFun()
    local fun = function (index, grid, char)
        grid:Refresh(char, self.Chapter)
    end
    return fun
end

function XUiSelectCharacterAwarenessOccupy:GetOverrideSortTable()
    local sortOverride = 
    {
        CheckFunList = 
        {   
            -- 符合条件未驻守
            [CharacterSortFunType.Custom1] = function (idA, idB)
                local isAMatch = self.Chapter:IsCharConditionMatch(idA) and not XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA)
                local isBMatch = self.Chapter:IsCharConditionMatch(idB) and not XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB)
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
            -- 已驻守其他chapter
            [CharacterSortFunType.Custom2] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idA) ~= self.ChapterId
                local isBMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idB) ~= self.ChapterId
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
            -- 已驻守其当前chapter
            [CharacterSortFunType.Custom3] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idA) == self.ChapterId
                local isBMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idB) == self.ChapterId
                if isAMatch ~= isBMatch then
                    return true
                end
            end,
        },
        SortFunList = 
        {
            [CharacterSortFunType.Custom1] = function (idA, idB)
                local isAMatch = self.Chapter:IsCharConditionMatch(idA) and not XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA)
                local isBMatch = self.Chapter:IsCharConditionMatch(idB) and not XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB)
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
            [CharacterSortFunType.Custom2] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idA) ~= self.ChapterId
                local isBMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idB) ~= self.ChapterId
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
            [CharacterSortFunType.Custom3] = function (idA, idB)
                local isAMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idA) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idA) == self.ChapterId
                local isBMatch = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(idB) and XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(idB) == self.ChapterId
                if isAMatch ~= isBMatch then
                    return isAMatch
                end
            end,
        }
    }
    return sortOverride
end

function XUiSelectCharacterAwarenessOccupy:OnTagClickCb()
    self.Super.OnTagClickCb(self)
    self.MidButtons.gameObject:SetActiveEx(false)
end

function XUiSelectCharacterAwarenessOccupy:RefreshConditionInfo()
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

function XUiSelectCharacterAwarenessOccupy:RefreshMid()
    local isOccupyChar = self.Chapter:GetCharacterId() == self.CurCharacter.Id
    self.BtnJoin.gameObject:SetActiveEx(not isOccupyChar and self.Chapter:IsCharConditionMatch(self.CurCharacter.Id))
    self.BtnQuit.gameObject:SetActiveEx(isOccupyChar)
    self.BtnJoin.gameObject:GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("BtnOccupyJoinImg3"))
    self.TxtConditionTitle.text = CS.XTextManager.GetText("AwarenessSendMemberCalled")
end

function XUiSelectCharacterAwarenessOccupy:OnBtnJoinClick()
    local selectCharacterId = self.CurCharacter.Id
    if not self.Chapter:CanAssign() then
        XUiManager.TipMsg(CS.XTextManager.GetText("StageUnlockCondition", self.Chapter:GetName()))
        return
    end

    if not self.Chapter:IsCharConditionMatch(selectCharacterId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectNotMatch")) -- "该成员不符合条件"
        return
    end

    local inOtherChapterId = XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(selectCharacterId)
    if inOtherChapterId and inOtherChapterId ~= self.ChapterId then
        XUiManager.TipMsg(CS.XTextManager.GetText("AwarenessSelectIsUsed")) -- "该成员已在其他区域驻守"
        return
    end

    XDataCenter.FubenAwarenessManager.AwarenessSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AwarenessOccupySuccess")) -- 驻守成功
    end)
end

function XUiSelectCharacterAwarenessOccupy:OnBtnQuitClick()
    local selectCharacterId = 0

    XDataCenter.FubenAwarenessManager.AwarenessSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupyUnselected")) -- 卸下成功
    end)
end

return XUiSelectCharacterAwarenessOccupy
