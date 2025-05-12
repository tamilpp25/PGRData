local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local tableInsert = table.insert

local XUiFubenActivityPuzzleRewardPanel = XClass(nil, "XUiFubenActivityPuzzleRewardPanel")
local XUiFubenActivityPuzzleAreaRewardBtn = require("XUi/XUiFubenActivityPuzzle/XUiFubenActivityPuzzleAreaRewardBtn")

function XUiFubenActivityPuzzleRewardPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiFubenActivityPuzzleRewardPanel:Init()
    self.CompleteGridReward = XUiGridCommon.New(self.RootUi, self.GridReward)
    self.AreaBtns = {}
    for i=1, 4, 1 do
        self["AreaBtn"..i] = XUiFubenActivityPuzzleAreaRewardBtn.New(self.RootUi, self["AwardBtn0"..i], function () self:OnRewardClick(i) end)
        XUiButtonLongClick.New(self["AreaBtn"..i].Pointer, 200, self, function() self:OnAreaLongExit() end, function () self:OnAreaLongClick(i) end, function () self:OnAreaLongUp() end, true)
        tableInsert(self.AreaBtns, self["AreaBtn"..i])
    end
end

function XUiFubenActivityPuzzleRewardPanel:RefreshPanel(puzzleId)
    self.PuzzleId = puzzleId
    self:RefreshCompleteReward(self.PuzzleId)
    self:RefreshAreaReward(self.PuzzleId)
end

function XUiFubenActivityPuzzleRewardPanel:RefreshCompleteReward(puzzleId)
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
    local reward = XRewardManager.GetRewardList(puzzleTemplate.CompleteRewardId)[1]
    local count = reward.Count
    self.CompleteRewardEffect.gameObject:SetActive(false) -- 隐藏特效
    if self.CompleteGridReward then
        self.CompleteGridReward:Refresh(reward)
        local isGot = XDataCenter.FubenActivityPuzzleManager.CheckCompleteRewardIsGot(puzzleId)
        if isGot and isGot == XFubenActivityPuzzleConfigs.CompleteRewardState.Rewarded then
            self.ReceiveItem.gameObject:SetActiveEx(true)
        else
            self.ReceiveItem.gameObject:SetActiveEx(false)
            if XDataCenter.FubenActivityPuzzleManager.GetPuzzleStateById(puzzleId) == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
                self:ShowCompleteRewardEffect()
            end
        end
    end
end

function XUiFubenActivityPuzzleRewardPanel:RefreshAreaReward(puzzleId)
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
    local rewardIds = puzzleTemplate.RewardId
    for index, rewardId in ipairs(rewardIds) do
        local reward = XRewardManager.GetRewardList(rewardId)[1]
        local itemId = reward.TemplateId
        local itemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
        local count = reward.Count
        if self.AreaBtns[index] then
            self.AreaBtns[index]:Refresh(itemIcon, count)
            if XDataCenter.FubenActivityPuzzleManager.IsRewardHasTaked(puzzleId, index) then
                self.AreaBtns[index]:SetTaked()
            else
                local isCanTake = XDataCenter.FubenActivityPuzzleManager.CheckAreaRewardCanTake(self.PuzzleId, index)
                if isCanTake then self.AreaBtns[index]:SetCanTake() else self.AreaBtns[index]:SetNormal() end
            end
        end
    end
end

function XUiFubenActivityPuzzleRewardPanel:OnRewardClick(index)
    if self.CurTouchedIndex then
        self.CurTouchedIndex = nil
        return
    end
    XDataCenter.FubenActivityPuzzleManager.GetReward(self.PuzzleId, index)
end

function XUiFubenActivityPuzzleRewardPanel:OnAreaLongClick(index)
    if XDataCenter.FubenActivityPuzzleManager.IsRewardHasTaked(self.PuzzleId, index) then
        return
    end

    if not self.CurTouchedIndex then
        local needBlockStr = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId).RewardPiecesStr[index]
        local needBlockArr = string.ToIntArray(needBlockStr)
        self.RootUi.PanelGame:ShowAwardAreaByList(needBlockArr)
        self.CurTouchedIndex = index
    else
        if self.CurTouchedIndex ~= index then
            local needBlockStr = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(self.PuzzleId).RewardPiecesStr[index]
            local needBlockArr = string.ToIntArray(needBlockStr)
            self.RootUi.PanelGame:HideAllAwardArea()
            self.RootUi.PanelGame:ShowAwardAreaByList(needBlockArr)
            self.CurTouchedIndex = index
        end
    end
end

function XUiFubenActivityPuzzleRewardPanel:OnAreaLongUp()
    self.RootUi.PanelGame:HideAllAwardArea()
end

function XUiFubenActivityPuzzleRewardPanel:OnAreaLongExit()
    self.CurTouchedIndex = nil
end

function XUiFubenActivityPuzzleRewardPanel:ShowCompleteRewardEffect()
    self.CompleteRewardEffect.gameObject:SetActive(false)
    self.CompleteRewardEffect.gameObject:SetActive(true)
end

function XUiFubenActivityPuzzleRewardPanel:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiFubenActivityPuzzleRewardPanel