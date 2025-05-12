local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelPokemonStageDetail = XLuaUiManager.Register(XLuaUi, "UiPokemonStageDetail")
local XUiGridPokemonPortrait = require("XUi/XUiPokemon/XUiGridPokemonPortrait")

function XUiPanelPokemonStageDetail:OnStart(stageId)
    self.RewardPanelList = {}
    self.MonsterHeadIcons = {}
    self.BtnEnter.CallBack = function()
        self:OnClickEnterBtn()
    end

    if self.BtnMask then
        self.BtnMask.CallBack = function()
            self:Close()
        end
        self.BtnSkip.CallBack = function()
            self:OnClickSkipBtn()
        end
    end
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Refresh(stageId)
end

function XUiPanelPokemonStageDetail:Refresh(stageId)
    self.StageId = stageId
    self:RefreshMonsters()
    self:RefreshReward()
    self:RefreshTitle()
    self:RefreshSkipPanel()
end

function XUiPanelPokemonStageDetail:RefreshSkipPanel()
    local isCanSkip = XDataCenter.PokemonManager.IsCanSkipStage(self.StageId)
    local isSkip = XDataCenter.PokemonManager.CheckIsSkip(XDataCenter.PokemonManager.GetStageFightStageId(self.StageId))
    local isPassed = XDataCenter.PokemonManager.CheckStageIsPassed(XDataCenter.PokemonManager.GetStageFightStageId(self.StageId))
    if self.PanelSkip then
        self.PanelSkip.gameObject:SetActiveEx(isCanSkip and (not isSkip) and (not isPassed))
    end
    if self.TxtAT then
        self.TxtAT.text = CS.XTextManager.GetText("PokemonMonsterEnergyCost", XDataCenter.ItemManager.GetItemName(XPokemonConfigs.GetSkipItemId()))
        self.RImgSkipIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XPokemonConfigs.GetSkipItemId()))
    end
end

function XUiPanelPokemonStageDetail:RefreshMonsters()
    local monsters
    if XDataCenter.PokemonManager.IsInfinityStage(self.StageId) then
        monsters = XDataCenter.PokemonManager.GetRandomMonsters()
    else
        monsters = XDataCenter.PokemonManager.GetStageMonsterIds(self.StageId)
    end

    for i = 1, XPokemonConfigs.TeamNum do
        local panel = self.MonsterHeadIcons[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridPortrait)
            ui.transform:SetParent(self.GridPortrait.parent, false)
            panel = XUiGridPokemonPortrait.New(ui)
            table.insert(self.MonsterHeadIcons, panel)
        end
        panel:Refresh(monsters[i], XDataCenter.PokemonManager.IsInfinityStage(self.StageId))
    end
end

function XUiPanelPokemonStageDetail:RefreshReward()

    if XDataCenter.PokemonManager.CheckStageIsPassed(XDataCenter.PokemonManager.GetStageFightStageId(self.StageId)) then
        self.TxtSpecialReward.gameObject:SetActiveEx(false)
        self.PanelDropList.gameObject:SetActiveEx(false)
        return
    end

    self.TxtSpecialReward.gameObject:SetActiveEx(true)
    self.PanelDropList.gameObject:SetActiveEx(true)
    self.TxtSpecialReward.text = XDataCenter.PokemonManager.GetStageUnlockDesc(self.StageId)

    local fightStageId = XDataCenter.PokemonManager.GetStageFightStageId(self.StageId)
    local stage = XDataCenter.FubenManager.GetStageCfg(fightStageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(fightStageId)
    local rewardId = 0
    local IsFirst = false
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    local cfg = XDataCenter.FubenManager.GetStageLevelControl(fightStageId)
    if not stageInfo.Passed then
        rewardId = cfg and cfg.FirstRewardShow or stage.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or stage.FirstRewardShow > 0 then
            IsFirst = true
        end
    end
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or stage.FinishRewardShow
    end

    if rewardId == 0 then
        return
    end

    local rewardsList = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)

    if not rewardsList then
        return
    end

    for i = 1, #rewardsList do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.transform:SetParent(self.GridCommon.parent, false)
            panel = XUiGridCommon.New(self, ui)
        end
        panel:Refresh(rewardsList[i])
    end
end

function XUiPanelPokemonStageDetail:RefreshTitle()
    self.TxtTitle.text = XDataCenter.PokemonManager.GetStageName(self.StageId)
end

function XUiPanelPokemonStageDetail:OnClickEnterBtn()
    if XDataCenter.PokemonManager.CheckRemainingTimes() or XDataCenter.PokemonManager.IsInfinityStage(self.StageId) then
        self:Close()
        XLuaUiManager.Open("UiPokemonFormation", self.StageId)
    else
        XUiManager.TipText("PokemonRemainingTimeLimit")
    end

end

function XUiPanelPokemonStageDetail:OnClickSkipBtn()
    if not XDataCenter.PokemonManager.CheckCanSkip() then
        XUiManager.TipText("PokemonSkipTimesNotEnough")
    end
    XDataCenter.PokemonManager.PokemonSkipStageRequest(XDataCenter.PokemonManager.GetPokemonStageId(self.StageId),function(rewardsList)
        XUiManager.TipText("PokemonSkipSuccessTips")
        self:Close()
        if rewardsList and #rewardsList > 0 then
            XUiManager.OpenUiTipReward(rewardsList)
        end
    end)
end

return XUiPanelPokemonStageDetail