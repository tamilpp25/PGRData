
---@class XUiBlackRockChessVictorySettlement : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessVictorySettlement = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessVictorySettlement")

local TempStageId

function XUiBlackRockChessVictorySettlement:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessVictorySettlement:OnStart(stageId, settle)
    self.StageId = stageId
    self.Settle = settle
    TempStageId = stageId
    
    self:RefreshReward()
    self:RefreshView()
end

function XUiBlackRockChessVictorySettlement:InitUi()
    self.Items = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    if self.PanelFail then
        self.PanelFail.gameObject:SetActiveEx(false)
    end
end

function XUiBlackRockChessVictorySettlement:InitCb()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    
    self.OnUiCloseCb = handler(self, self.DoClose)
end

function XUiBlackRockChessVictorySettlement:RefreshReward()
    local isFirstPass = self.Settle.IsFirstPass
    if isFirstPass then
        local firstPassWeaponId = self._Control:GetStageFirstPassWeaponId(self.StageId)
        if XTool.IsNumberValid(firstPassWeaponId) then
            local grid = self:GetGridCommon(false)
            grid:ResetUi()
            grid:ShowIcon(self._Control:GetWeaponIcon(firstPassWeaponId))
        end
        
        local firstPassSkillId = self._Control:GetStageFirstPassSkillId(self.StageId)
        if XTool.IsNumberValid(firstPassSkillId) then
            local grid = self:GetGridCommon(false)
            grid:ResetUi()
            grid:ShowIcon(self._Control:GetWeaponSkillIcon(firstPassSkillId))
        end
        
        local firstPassBuffIds = self._Control:GetStageFirstPassBuffIds(self.StageId)
        for _, buffId in pairs(firstPassBuffIds) do
            local grid = self:GetGridCommon(false)
            grid:ResetUi()
            grid:ShowIcon(self._Control:GetBuffIcon(buffId))
        end
    end
    local rewardGoodsList = self.Settle.RewardGoodsList or {}
    local list = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)

    XUiHelper.CreateTemplates(self, self.Items, list, XUiGridCommon.New, self.GridCommon, self.PanelDropContent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end

function XUiBlackRockChessVictorySettlement:RefreshView()
    self.TxtRound.text = string.format(self._Control:GetSettleText(1), self._Control:GetChessRound() - 1)
    self.TxtKill.text = string.format(self._Control:GetSettleText(2), self._Control:GetChessGamer():GetKillTotal())
    self.TxtRevive.text = string.format(self._Control:GetSettleText(3), self._Control:GetChessGamer():GetReviveCount())
end

---@return XUiGridCommon
function XUiBlackRockChessVictorySettlement:GetGridCommon(isNormal)
    local ui = XUiHelper.Instantiate(self.GridCommon, self.PanelDropContent)
    local grid = XUiGridCommon.New(self, ui)
    if not isNormal then
        grid:SetProxyClickFunc(handler(self, self.OnClickUncommon))
    end
    grid.GameObject:SetActiveEx(true)
    return grid
end

function XUiBlackRockChessVictorySettlement:OnClickUncommon()
    
end

function XUiBlackRockChessVictorySettlement:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback("UiBlackRockChessVictorySettlement", self.OnUiCloseCb)
end

function XUiBlackRockChessVictorySettlement:DoClose()
    if not XTool.IsNumberValid(TempStageId) then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE_UI_CLOSE, TempStageId)
end