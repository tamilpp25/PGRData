local XUiAwarenessSettleWin = XLuaUiManager.Register(XLuaUi, "UiAwarenessSettleWin")

local XUiGridAwarenessTeamInfoExp = require("XUi/XUiAwareness/Grid/XUiGridAwarenessTeamInfoExp")
local ipairs = ipairs
local ANIMATION_OPEN = "AniBfrtPostWarCountBegin"

function XUiAwarenessSettleWin:OnAwake()
    self:InitComponent()
end

function XUiAwarenessSettleWin:OnStart(data)
    self:ResetDataInfo()
    self:UpdateDataInfo(data)
    self:PlayAnimation(ANIMATION_OPEN)
end

function XUiAwarenessSettleWin:InitComponent()
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)

    self.GridEchelonExp.gameObject:SetActive(false)
    self.GridReward.gameObject:SetActive(false)
    self.GridEchelonExp.gameObject:SetActive(false)
end

function XUiAwarenessSettleWin:OnNotify(evt, ...)
    local args = { ... }
    if evt == CS.XEventId.EVENT_UI_ALLOWOPERATE and args[1] == self.Ui then
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end
end

function XUiAwarenessSettleWin:OnGetEvents()
    return { CS.XEventId.EVENT_UI_ALLOWOPERATE }
end

function XUiAwarenessSettleWin:ResetDataInfo()
    self.RewardGoodsList = {}
    self.ChapterId = nil
end

function XUiAwarenessSettleWin:UpdateDataInfo(data)
    self.RewardGoodsList = data.RewardGoodsList
    self.ChapterId = XFubenAwarenessConfigs.GetChapterIdByStageId(data.StageId)

    self:UpdatePanelRewardContent()
    self:UpdatePanelEchelonExpContent()
    self:UpdatePanelPlayer()
end

function XUiAwarenessSettleWin:OnBtnExitClick()
    self:Close()
end

function XUiAwarenessSettleWin:OnBtnCloseClick()
    self:Close()
end

function XUiAwarenessSettleWin:UpdatePanelRewardContent()
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(self.RewardGoodsList)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(true)
    end
end

function XUiAwarenessSettleWin:UpdatePanelEchelonExpContent()
    local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
    local baseStageId = chapterData:GetStageId()[1]

    for index, teamInfoId in ipairs(chapterData:GetTeamInfoId()) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelonExp)
        local grid = XUiGridAwarenessTeamInfoExp.New(self, ui, baseStageId, index, teamInfoId)
        grid.Transform:SetParent(self.PanelEchelonExpContent, false)
        grid.GameObject:SetActive(true)
    end
end

function XUiAwarenessSettleWin:UpdatePanelPlayer()
    local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local maxExp = XPlayer.GetMaxExp()
    local teamExp = XDataCenter.FubenManager.GetTeamExp(chapterData:GetStageId()[1])

    self.TxtLevel.text = curLevel
    if XPlayer.IsHonorLevelOpen() then
        self.TxtLevelName.text = CS.XTextManager.GetText("HonorLevel")
    end
    self.TxtAddExp.text = "+ " .. teamExp
    self.ImgExp.fillAmount = curExp / maxExp
end