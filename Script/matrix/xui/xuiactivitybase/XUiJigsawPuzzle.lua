local XUiGridPuzzlePiece = require("XUi/XUiActivityBase/XUiGridPuzzlePiece")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiJigsawPuzzle = XClass(nil, "XUiJigsawPuzzle")

function XUiJigsawPuzzle:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.RewardPanelList = {}
    self.PieceGroup = {}
    self.IsInit = false
    self.ButtonLastState = nil
    XTool.InitUiObject(self)
    self.ImgComplete.gameObject:SetActiveEx(false)
    self.BtnFinish.gameObject:SetActiveEx(true)
    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
end

function XUiJigsawPuzzle:OnDestroy()
    for _,v in pairs(self.PieceGroup) do
        v:RemoveTimer()
    end
end

function XUiJigsawPuzzle:InitButton()
    local count = XDataCenter.PuzzleActivityManager.GetPieceAmountById(self.PuzzleId)
    for index=1, count do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridPiece)
        ui.transform:SetParent(self.GridPiece.parent, false)
        local pieceGrid = XUiGridPuzzlePiece.New(ui)
        pieceGrid:Init(self.PuzzleId, index)
        self.PieceGroup[index] = pieceGrid
    end
end

function XUiJigsawPuzzle:Refresh(activityCfg)
    if not (self.ActivityCfg or activityCfg) then return end
    if not self.IsInit or self.ActivityCfg ~= activityCfg then
        self.ActivityCfg = activityCfg or self.ActivityCfg
        self.PuzzleId = self.ActivityCfg.Params[1]

        self.TxtContentTimeTask.text = XActivityConfigs.GetActivityTimeStr(self.ActivityCfg.Id)
        self.TxtContentTitleTask.text = self.ActivityCfg.ActivityTitle
        self.TxtContentTask.text = self.ActivityCfg.ActivityDes
        -- end set normal activity info --

        self.PuzzleData = XDataCenter.PuzzleActivityManager.GetActivityPuzzleTemplateById(self.PuzzleId)
        self.ImgPicture:SetRawImage(self.PuzzleData.GroupCfg.BgImage)
        XDataCenter.PuzzleActivityManager.PuzzleActivityDataRequest(self.PuzzleId)
        self:SetReward()
        self:InitButton()
        self.IsInit = true
    end
    self:UpdateInfo()
end

function XUiJigsawPuzzle:UpdateInfo()
    for index, grid in ipairs(self.PieceGroup) do
        grid:Refresh()
    end
    self:UpdateButtonState()
end

function XUiJigsawPuzzle:OnAnimFinished()
    self.ImgPicture.enabled = true
end

function XUiJigsawPuzzle:OnAnimBegin()
    self.ImgPicture.enabled = false
end

function XUiJigsawPuzzle:UpdateButtonState()
    local state = self.PuzzleData.RewardState
    if state ~= self.ButtonLastState then
        if state == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
            self.BtnFinish:SetButtonState(CS.UiButtonState.Disable)
        elseif state == XPuzzleActivityConfigs.PuzzleRewardState.Rewarded then
            self.BtnFinish.gameObject:SetActiveEx(false)
            self.ImgComplete.gameObject:SetActiveEx(true)
        elseif state == XPuzzleActivityConfigs.PuzzleRewardState.CanReward then
            self.BtnFinish:SetButtonState(CS.UiButtonState.Normal)
        end
    end
    self.ButtonLastState = state
end

function XUiJigsawPuzzle:OnBtnFinishClick()
    if self.PuzzleData.RewardState ~= XPuzzleActivityConfigs.PuzzleRewardState.CanReward then
        return 
    end
    local closeCallback = self:UpdateInfo()
    XDataCenter.PuzzleActivityManager.PuzzleActivityGetRewardRequest(self.PuzzleId, function(rewardGoodsList)
        self.ImgComplete.gameObject:SetActiveEx(true)
        self.BtnFinish.gameObject:SetActiveEx(false)
        XUiManager.OpenUiObtain(rewardGoodsList, nil, closeCallback, nil)
    end)
end

function XUiJigsawPuzzle:SetReward()
    local rewards = XRewardManager.GetRewardList(self.PuzzleData.GroupCfg.RewardId)
    -- reset reward panel
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
    end
end

return XUiJigsawPuzzle