local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGame2048PopupSettlement: XLuaUi
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiGame2048PopupSettlement = XLuaUiManager.Register(XLuaUi, 'UiGame2048PopupSettlement')
local XUiGridGame2048Target = require('XUi/XUiGame2048/UiGame2048PopupSettlement/XUiGridGame2048Target')

local SettleButtonGroupType = {
    WithNext = 1, -- 左按钮再来一次， 右按钮下一关
    Normal = 2, -- 左按钮退出， 右按钮再来一次
}

function XUiGame2048PopupSettlement:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.ExitGame)
end

function XUiGame2048PopupSettlement:OnStart(res, closeCallback)
    self._LastScore = self._Control:GetStageLastMaxScore()
    self._LastMaxBlockNum = self._Control:GetStageLastMaxBlockNum()
    self._GameControl = self._Control:GetGameControl()
    self._CloseCallback = closeCallback
    self._StageId = self._Control:GetCurStageId()
    self._StageType = self._Control:GetStageTypeById(self._StageId)
    self.PanelRecord.gameObject:SetActiveEx(false)
    self.PanelTarget.gameObject:SetActiveEx(false)
    self:ResetSFXLock()

    self:RefreshStar(res)
    self:RefreshScore(res)
    
    self:InitButtons()
    self:RefreshReward(res)
end

function XUiGame2048PopupSettlement:InitButtons()
    if self._ButtonGroupType == SettleButtonGroupType.WithNext then
        self.BtnLeave.CallBack = handler(self, self.PlayAgain)
        self.BtnAgain.CallBack = handler(self, self.PlayNext)
        self.BtnLeave:SetNameByGroup(0, self._Control:GetClientConfigText('AgainLabelInSettle'))
        self.BtnAgain:SetNameByGroup(0, self._Control:GetClientConfigText('NextStageLabelInSettle'))
    else
        self.BtnLeave.CallBack = handler(self, self.ExitGame)
        self.BtnAgain.CallBack = handler(self, self.PlayAgain)
        self.BtnLeave:SetNameByGroup(0, self._Control:GetClientConfigText('ExitLabel'))
        self.BtnAgain:SetNameByGroup(0, self._Control:GetClientConfigText('AgainLabelInSettle'))
    end
end

function XUiGame2048PopupSettlement:ExitGame()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback(true)
        self._CloseCallback = nil
    end
end

function XUiGame2048PopupSettlement:PlayAgain()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback(false)
        self._CloseCallback = nil
    end
end

function XUiGame2048PopupSettlement:PlayNext()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback(false, self._NextStageId)
        self._CloseCallback = nil
    end
end

function XUiGame2048PopupSettlement:RefreshStar(res)
    -- 刷新星数
    self.PanelTarget.gameObject:SetActiveEx(true)
    self.GridTarget.gameObject:SetActiveEx(false)
    local starDescList = self._Control:GetStageStarDescList(self._StageId)
    local starScores = self._Control:GetStageScoreList(self._StageId)
    local nextIndex = starDescList and #starDescList + 1 or 1
    if self._TargetGrids == nil then
        self._TargetGrids = {}
    end
    
    self._AchieveAnyTarget = false
    
    XUiHelper.RefreshCustomizedList(self.GridTarget.transform.parent, self.GridTarget, starDescList and #starDescList or 0, function(index, go)
        local grid = self._TargetGrids[index]
        if not grid then
            grid = XUiGridGame2048Target.New(go, self)
            table.insert(self._TargetGrids, grid)
        end
        grid:Open()
        
        local isAchieve = starScores[index] <= res.CurrentScore

        if isAchieve then
            self._AchieveAnyTarget = true
        end
        
        grid:Refresh(starDescList[index], isAchieve)
    end)

    local count = #self._TargetGrids
    if count > nextIndex then
        for i = nextIndex, count do
            if self._TargetGrids[i] then
                self._TargetGrids:Close()
            end
        end
    end

    self.TxtTitle.text = self._Control:GetClientConfigText('SettleTitle', self._AchieveAnyTarget and 1 or 2)

    
    -- 满足通关时需要检查支持下一关
    if self._AchieveAnyTarget then
        self._NextStageId = self._Control:TryGetCurActivityNextStageIdInChapter(self._Control:GetCurChapterId(), self._StageId)
        self:EnableWinSFX()
    else
        self:EnableLoseSFX()
    end

    if XTool.IsNumberValid(self._NextStageId) then
        self._ButtonGroupType = SettleButtonGroupType.WithNext
    else
        self._ButtonGroupType = SettleButtonGroupType.Normal
    end
end

function XUiGame2048PopupSettlement:RefreshScore(res)
    self.PanelRecord.gameObject:SetActiveEx(true)
    self.TxtScoreNum.text = res.CurrentScore
    self.TagNew.gameObject:SetActiveEx(res.CurrentScore > self._LastScore)


    if self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless then
        self.TxtMaxMergeNum.text = res.CurrentMaxBlockNum
        self.TagNewMaxNum.gameObject:SetActiveEx(res.CurrentMaxBlockNum > self._LastMaxBlockNum)
    else
        self.TxtMaxMergeNum.transform.parent.gameObject:SetActiveEx(false)
    end
    
    -- 无限关一定满足通关条件，直接判断是否有下一关
    self._NextStageId = self._Control:TryGetCurActivityNextStageIdInChapter(self._Control:GetCurChapterId(), self._StageId)
    self:EnableWinSFX()
    
    if XTool.IsNumberValid(self._NextStageId) then
        self._ButtonGroupType = SettleButtonGroupType.WithNext
    else
        self._ButtonGroupType = SettleButtonGroupType.Normal
    end
end

function XUiGame2048PopupSettlement:RefreshReward(res)
    -- 刷新奖励
    local hasReward = not XTool.IsTableEmpty(res.RewardGoodsList)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.PanelRewardTitle.gameObject:SetActiveEx(hasReward)
    self.TxtNone.gameObject:SetActiveEx(not hasReward)
    
    if hasReward then
        XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, res.RewardGoodsList and #res.RewardGoodsList or 0, function(index, go)
            ---@type XUiGridCommon
            local grid = XUiGridCommon.New(nil, go)
            grid:Refresh(res.RewardGoodsList[index])
        end)
    end
end

--region 音效
function XUiGame2048PopupSettlement:HideAllSFX()
    self.SFX_SettleWin.gameObject:SetActiveEx(false)
    self.SFX_SettleLose.gameObject:SetActiveEx(false)
end

function XUiGame2048PopupSettlement:ResetSFXLock()
    self._WinSFXPlaying = false
    self._LoseSFXPlaying = false
    self:HideAllSFX()
end

function XUiGame2048PopupSettlement:EnableWinSFX()
    if not self._WinSFXPlaying then
        self._WinSFXPlaying = true
        self.SFX_SettleWin.gameObject:SetActiveEx(true)
    end
end

function XUiGame2048PopupSettlement:EnableLoseSFX()
    if not self._LoseSFXPlaying then
        self._LoseSFXPlaying = true
        self.SFX_SettleLose.gameObject:SetActiveEx(true)
    end
end
--endregion

return XUiGame2048PopupSettlement