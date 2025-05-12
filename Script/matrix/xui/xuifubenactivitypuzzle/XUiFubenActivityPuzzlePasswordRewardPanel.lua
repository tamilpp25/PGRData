local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local tableInsert = table.insert

local XUiFubenActivityPuzzlePasswordRewardPanel = XClass(nil, "XUiFubenActivityPuzzlePasswordRewardPanel")

function XUiFubenActivityPuzzlePasswordRewardPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiFubenActivityPuzzlePasswordRewardPanel:Init()
    self.CompleteGridReward = XUiGridCommon.New(self.RootUi, self.GridReward)
    self.PasswordArr = {}
    for i = 1, 4 do
        if self["Password"..i] then
            tableInsert(self.PasswordArr, self["Password"..i])
        end
    end
    self.TxtPasswordArr = {}
    for i = 1, 4 do
        if self["TxtPassword"..i] then
            tableInsert(self.TxtPasswordArr, self["TxtPassword"..i])
        end
    end

    self:AutoRegisterListener()
end

function XUiFubenActivityPuzzlePasswordRewardPanel:RefreshPanel(puzzleId)
    self.PuzzleId = puzzleId
    self:RefreshCompleteReward(self.PuzzleId)
    self:RefreshPasswordReward(self.PuzzleId)
end

function XUiFubenActivityPuzzlePasswordRewardPanel:RefreshCompleteReward(puzzleId)
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

function XUiFubenActivityPuzzlePasswordRewardPanel:RefreshPasswordReward(puzzleId)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PaneNormal.gameObject:SetActiveEx(false)
    self.PanelSuccess.gameObject:SetActiveEx(false)
    local puzzleState = XDataCenter.FubenActivityPuzzleManager.GetPuzzleStateById(puzzleId)
    if puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Incomplete then
        self.PanelLock.gameObject:SetActiveEx(true)
    elseif puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
        self.PaneNormal.gameObject:SetActiveEx(true)
        local passwordList = XDataCenter.FubenActivityPuzzleManager.GetPasswordByPuzzleId(puzzleId)
        for index, passwordTrans in ipairs(self.PasswordArr) do
            if passwordList[index] then
                passwordTrans.gameObject:SetActiveEx(true)
                if self.TxtPasswordArr[index] then
                    self.TxtPasswordArr[index].text = passwordList[index]
                end
            else
                passwordTrans.gameObject:SetActiveEx(false)
            end
        end
    elseif puzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
        self.PanelSuccess.gameObject:SetActiveEx(true)
        local passwordList = XDataCenter.FubenActivityPuzzleManager.GetPasswordByPuzzleId(puzzleId)
        local passwordStr = table.concat(passwordList)
        self.TxtPasswordSuc.text = passwordStr
    end
end

-- function XUiFubenActivityPuzzlePasswordRewardPanel:OnRewardClick(index)
--     if self.CurTouchedIndex then
--         self.CurTouchedIndex = nil
--         return
--     end
--     XDataCenter.FubenActivityPuzzleManager.GetReward(self.PuzzleId, index)
-- end

function XUiFubenActivityPuzzlePasswordRewardPanel:AutoRegisterListener()
    self.BtnDecryption.CallBack = function () self:OnBtnBtnDecryptionClick() end
    self.BtnLock.CallBack = function () XUiManager.TipText("DragPuzzleActivityDercyptionNeedComplete") end
end

function XUiFubenActivityPuzzlePasswordRewardPanel:OnBtnBtnDecryptionClick()
    self.RootUi:OpenChildUi("UiFubenActivityPuzzlePassword", self)
end

function XUiFubenActivityPuzzlePasswordRewardPanel:ShowCompleteRewardEffect()
    self.CompleteRewardEffect.gameObject:SetActive(false)
    self.CompleteRewardEffect.gameObject:SetActive(true)
end

function XUiFubenActivityPuzzlePasswordRewardPanel:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiFubenActivityPuzzlePasswordRewardPanel