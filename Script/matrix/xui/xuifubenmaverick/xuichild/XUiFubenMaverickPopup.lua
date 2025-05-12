local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenMaverickPopup = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickPopup")
local XUiFubenMaverickStageTipPanel = require("XUi/XUiFubenMaverick/XUiScrollView/XUiFubenMaverickStageTipPanel")
local Instantiate = CS.UnityEngine.Object.Instantiate

function XUiFubenMaverickPopup:OnAwake()
    self.RewardGrids = { }
    self.AffixGrids = { }
    self.AffixDetailGrids = { }
    self.EnemyGrids = { }
    
    XTool.InitUiObjectByUi(self, self.PanelStageDetail)
    
    self:InitButtons()
    self:InitPanelAsset()
    self:InitDynamicTale()
end

function XUiFubenMaverickPopup:OnStart(stagePanel)
    --因为是子Ui所以不需要设置计时器
    self.StagePanel = stagePanel
end

function XUiFubenMaverickPopup:OnEnable()
    self.Stage = self.StagePanel.SelectedGrid.Stage
    self.StagCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)

    self:InitTexts()
    self:InitRewards()
    self:InitAffixes()
    self:InitEnemies()
    self:SwitchPanel(true)
    self:PlayAnim("PanelPopupEnable")
end

function XUiFubenMaverickPopup:InitTexts()
    self.TxtTitle.text = self.StagCfg.Name
    self.TxtDanger.text = self.Stage.Danger
    self.DynamicTableTip:Refresh(self.Stage.Tips)
end

function XUiFubenMaverickPopup:InitDynamicTale()
    self.DynamicTableTip = XUiFubenMaverickStageTipPanel.New(self.PanelTips)
end

function XUiFubenMaverickPopup:InitAffixes()
    local affixes = XDataCenter.MaverickManager.GetStageAffixes(self.Stage.AffixIds)
    if affixes then
        for i, affix in ipairs(affixes) do
            local affixGrid
            if self.AffixGrids[i] then
                affixGrid = self.AffixGrids[i]
            else
                local ui = Instantiate(self.GridBuff, self.PanelBuffContent)
                affixGrid = { }
                XTool.InitUiObjectByUi(affixGrid, ui)
                self.AffixGrids[i] = affixGrid
            end
            
            affixGrid.RImgIcon:SetRawImage(affix.Icon)
            affixGrid.GameObject:SetActiveEx(true)            
            
            local affixDetailGrid
            if self.AffixDetailGrids[i] then
                affixDetailGrid = self.AffixDetailGrids[i]
            else
                local ui = Instantiate(self.GridDetailBuff, self.PanelDetailBuffContent)
                affixDetailGrid = { }
                XTool.InitUiObjectByUi(affixDetailGrid, ui)
                self.AffixDetailGrids[i] = affixDetailGrid
            end
            
            affixDetailGrid.RImgIcon:SetRawImage(affix.Icon)
            affixDetailGrid.TxtName.text = affix.Name
            affixDetailGrid.TxtDesc.text = affix.Description
            affixDetailGrid.GameObject:SetActiveEx(true)
        end
    end

    local affixCount = 0
    if affixes then
        affixCount = #affixes
    end

    for j = 1, #self.AffixGrids do
        if j > affixCount then
            self.AffixGrids[j].GameObject:SetActiveEx(false)
            self.AffixDetailGrids[j].GameObject:SetActiveEx(false)
        end
    end

    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridDetailBuff.gameObject:SetActiveEx(false)
    self.PanelBuffNone.gameObject:SetActiveEx(affixCount == 0)
end

function XUiFubenMaverickPopup:InitEnemies()
    local enemyIds = self.Stage.MonsterIds
    if enemyIds then
        for i, enemyId in ipairs(enemyIds) do
            local grid
            if self.EnemyGrids[i] then
                grid = self.EnemyGrids[i]
            else
                local ui = Instantiate(self.GridEnemy, self.PanelEnemies)
                grid = { }
                XTool.InitUiObjectByUi(grid, ui)
                self.EnemyGrids[i] = grid
            end
            local icon = XMVCA.XArchive:GetArchiveMonsterConfigById(enemyId).Icon
            grid.Icon:SetRawImage(icon)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local enemyCount = 0
    if enemyIds then
        enemyCount = #enemyIds
    end

    for j = 1, #self.EnemyGrids do
        if j > enemyCount then
            self.EnemyGrids[j].GameObject:SetActiveEx(false)
        end
    end

    self.GridEnemy.gameObject:SetActiveEx(false)
end

function XUiFubenMaverickPopup:InitRewards()
    local rewards = XRewardManager.GetRewardList(self.StagCfg.FirstRewardShow)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.RewardGrids[i] then
                grid = self.RewardGrids[i]
            else
                local ui = Instantiate(self.GridCommon, self.PanelDropContent)
                grid = XUiGridCommon.New(self, ui)
                self.RewardGrids[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.RewardGrids do
        if j > rewardsCount then
            self.RewardGrids[j].GameObject:SetActiveEx(false)
        end
    end

    self.GridCommon.gameObject:SetActiveEx(false)
    
    local isFinished = XDataCenter.MaverickManager.CheckStageFinished(self.Stage.StageId)
    self.Obtained.gameObject:SetActiveEx(isFinished)
    self.PanelDropContent.gameObject:SetActiveEx(not isFinished)
end

function XUiFubenMaverickPopup:PlayAnim(animName, callback)
    self.IsAnimPlaying = true
    self:PlayAnimation(animName, function()
        self.IsAnimPlaying = false
        if callback then
            callback()
        end
    end)
end

function XUiFubenMaverickPopup:InitPanelAsset()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiFubenMaverickPopup:Close()
    self.Super.Close(self)
    self.StagePanel:OnStageDetailClose()
end

function XUiFubenMaverickPopup:InitButtons()
    -- 关闭关卡详情界面
    self.BtnClose.CallBack = function()
        if self.IsAnimPlaying then
            return
        end
        
        self:PlayAnim("PanelPopupDisable", function() self:Close() end)
    end
    -- 进入战斗准备界面
    self.BtnEnter.CallBack = function()
        if self.IsAnimPlaying then
            return
        end
        
        self:Close()
        XLuaUiManager.Open("UiFubenMaverickPrepare", self.Stage.StageId)
    end
    -- 信息面板切换
    self.BtnEnemy.CallBack = function() self:SwitchPanel(false) end
    self.BtnStage.CallBack = function() self:SwitchPanel(true) end
    -- 词缀按钮
    self.BtnBuffTip.CallBack = function() self.PanelBuffDetail.gameObject:SetActiveEx(true) end
    self.BtnTanchuangCloseBig.CallBack = function() self.PanelBuffDetail.gameObject:SetActiveEx(false) end
end

function XUiFubenMaverickPopup:SwitchPanel(isStage)
    self.BtnEnemy.gameObject:SetActiveEx(isStage)
    self.PanelStage.gameObject:SetActiveEx(isStage)
    self.PanelEnemy.gameObject:SetActiveEx(not isStage)
    self.BtnStage.gameObject:SetActiveEx(not isStage)

    self:PlayAnim("QieHuan")
end 