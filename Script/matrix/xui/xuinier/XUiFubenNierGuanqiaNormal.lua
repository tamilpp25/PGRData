local XUiFubenNierGuanqiaNormal = XLuaUiManager.Register(XLuaUi, "UiFubenNierGuanqiaNormal")
local XUiGridFubenNierPODSkill = require("XUi/XUiNieR/XUiGridFubenNierPODSkill")
function XUiFubenNierGuanqiaNormal:OnAwake()
    --self.BtnClose.CallBack = function () self:Close() end
    self.BtnTanchuangClose.CallBack = function () self:Close() end

    self.BtnEnter.CallBack = function () self:OnBtnEnterClick() end
    if self.PanelAsset then
        self.PanelAsset.gameObject:SetActiveEx(false)
    end
    
    self:InitTextTipsPanels()
end

function XUiFubenNierGuanqiaNormal:OnStart(stageId, nieRStageType, repeatStageId, chapterId)
    self.GridList = {}
    self.RepeatStageId = repeatStageId
    self.ChapterId = chapterId
    self.StageId = stageId
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.NieRStageType = nieRStageType
    self.GirdSkillList = {}
end

function XUiFubenNierGuanqiaNormal:OnEnable()
    self:Refresh(self.Stage)
end

function XUiFubenNierGuanqiaNormal:OnDisable()
    
end

function XUiFubenNierGuanqiaNormal:InitAssetPanel()
    if not self.PanelAsset then return end
    self.PanelAsset.gameObject:SetActiveEx(true)
    local PanelTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1", nil)
    local RImgTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/RImgTool1", "RawImage")
    self.TxtTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/TxtTool1", "Text")
    self.BtnBuyJump1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/BtnBuyJump1", "Button")
    if self.BtnBuyJump1 then
        XUiHelper.RegisterClickEvent(self, self.BtnBuyJump1, self.OnTickJumpClick)
    end
    
    local itemId = XDataCenter.NieRManager.GetRepeatStageConsumeId()
    local item = XDataCenter.ItemManager.GetItem(itemId)

    if RImgTool1 ~= nil and RImgTool1:Exist() then
        RImgTool1:SetRawImage(item.Template.Icon, nil, false)
    end

    local func = function(textTool, id)
        local itemCount = XDataCenter.ItemManager.GetCount(id)
        textTool.text = itemCount .. "/" .. XDataCenter.NieRManager.GetNieRRepeatConsumeMaxCount()
    end
    local f = function()
        func(self.TxtTool1, itemId)
    end
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, f, self.TxtTool1)
    func(self.TxtTool1, itemId)
end

function XUiFubenNierGuanqiaNormal:OnTickJumpClick()
    local item = XDataCenter.ItemManager.GetItem(XDataCenter.NieRManager.GetRepeatStageConsumeId())
    local data = {
        Id = item.Id,
        Count = item ~= nil and tostring(item.Count) or "0"
    }
    XLuaUiManager.Open("UiTip", data)   
end

function XUiFubenNierGuanqiaNormal:InitTextTipsPanels()
    self.GridStarList = {}
    for i = 1, 3 do
        local tmpNode = {}
        tmpNode.node = self["TextTips"..i]
        tmpNode.text = self["TextTipsLabel"..i]
        self.GridStarList[i] = tmpNode
    end
    
end

function XUiFubenNierGuanqiaNormal:Refresh(stage)
    self.Stage = stage or self.Stage
    self:UpdateCommon()
    self.PanelRewards.gameObject:SetActiveEx(false)
    self.ShowRImg:SetRawImage(self.Stage.StoryIcon)
    if self.NieRStageType == XNieRConfigs.NieRStageType.BossStage then
        self.PanelJinduDetail.gameObject:SetActiveEx(true)
        self.PanelDropList.gameObject:SetActiveEx(false)
        self:UpdateBossInfo()
    else
        self.PanelDropList.gameObject:SetActiveEx(true)
        self.PanelJinduDetail.gameObject:SetActiveEx(false)
        self:UpdateRewards()
    end
    self:UpdatePODAndSkill()
end

function XUiFubenNierGuanqiaNormal:UpdateBossInfo()
    local nieRBoss = XDataCenter.NieRManager.GetNieRBossDataById(self.StageId)
    local leftHp = nieRBoss:GetLeftHp()
    local maxHp = nieRBoss:GetMaxHp()
    local score = nieRBoss:GetScore()
    local percent = (maxHp - leftHp) / maxHp 
    self.PanelExpBar.fillAmount = percent
    
    local percentStr
    if  (percent * 100) > 1 then
        percentStr = string.format("%d%%",math.floor( percent * 100), "%")
    else
        percentStr = string.format("%.2f%%", percent * 100, "%")
    end
    self.TextContsJindu.text = percentStr
    self.TextJinduNow.text = (maxHp - leftHp)
    self.TextJinduAll.text = string.format("/%s", maxHp)
    self.TextJifen.text = score
    if score > 0 then
        self.TextShowTips.gameObject:SetActiveEx(true)
    else
        self.TextShowTips.gameObject:SetActiveEx(false)
    end
end

function XUiFubenNierGuanqiaNormal:UpdateCommon()

    self.TxtTitle.text = self.Stage.Name
    for i = 1, 3 do
        if self.Stage.StarDesc[i] then
            self.GridStarList[i].node.gameObject:SetActiveEx(true)
            self.GridStarList[i].text.text = self.Stage.StarDesc[i]
        else
            self.GridStarList[i].node.gameObject:SetActiveEx(false)
        end
    end
    if self.NieRStageType  == XNieRConfigs.NieRStageType.RepeatStage then
        local nieRRepeat = XDataCenter.NieRManager.GetRepeatDataById(self.RepeatStageId)
        local consumeId, counsumCount
        if self.RepeatStageId == self.StageId then
            consumeId, counsumCount = XDataCenter.NieRManager.GetRepeatStageConsumeId(), nieRRepeat:GetNierRepeatStageConsumeCount()
        else
            consumeId, counsumCount = nieRRepeat:GetExConsumIdAndCount(self.StageId)
        end
        if counsumCount == 0 then
            self.UsePowerItemGrid1.gameObject:SetActiveEx(false)
        else
            self.UsePowerItemGrid1.gameObject:SetActiveEx(true)
            self.UsePowerIcon1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(consumeId))
            self.UsePowerNum1.text = counsumCount
        end
        local actionPoint = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
        if actionPoint == 0 then
            self.UsePowerItemGrid2.gameObject:SetActiveEx(false)
        else
            self.UsePowerItemGrid2.gameObject:SetActiveEx(true)
            self.UsePowerNum2.text = actionPoint
        end
        self:InitAssetPanel()
        XDataCenter.NieRManager.SaveNieRRepeatRedCheckCount()
        XEventManager.DispatchEvent(XEventId.EVENT_NIER_REPEAT_CLICK)
    else
        self.UsePowerItemGrid1.gameObject:SetActiveEx(false)
        local actionPoint = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
        if actionPoint == 0 then
            self.UsePowerItemGrid2.gameObject:SetActiveEx(false)
        else
            self.UsePowerItemGrid2.gameObject:SetActiveEx(true)
            self.UsePowerNum2.text = actionPoint
        end
        
    end
    
end

function XUiFubenNierGuanqiaNormal:UpdateRewards()
    local stage = self.Stage

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)
    -- 获取显示奖励Id
    local rewardId = 0
    local IsFirst = false
    local rewards 
    self.TxtDrop.text = CS.XTextManager.GetText("DropRewardTitle")
    if self.NieRStageType  == XNieRConfigs.NieRStageType.RepeatStage and XDataCenter.NieRManager.CheckNieRRepeatMainStage(stage.StageId) then
        local nierRepeat = XDataCenter.NieRManager.GetRepeatDataById(stage.StageId)
        local starNum = nierRepeat:GetNieRRepeatStar()
        
        if starNum > 0 then
            self.PanelRewards.gameObject:SetActiveEx(true)
            self.TextContRewards.text = "X" .. starNum
            rewardId = nierRepeat:GetNieRExStarReward(starNum)
        else
            self.PanelRewards.gameObject:SetActiveEx(true)
            self.TextContRewards.text = "X" .. starNum
            rewardId = nierRepeat:GetNieRNorStarReward()
        end
        if rewardId == 0 then
            for j = 1, #self.GridList do
                self.GridList[j].GameObject:SetActiveEx(false)
            end
            return
        end
        rewards = starNum >= 0 and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    else
        local cfg = XDataCenter.FubenManager.GetStageLevelControl(stage.StageId)
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
            rewardId = cfg and cfg.FirstRewardShow or stage.FirstRewardShow
            if cfg and cfg.FirstRewardShow > 0 or stage.FirstRewardShow > 0 then
                IsFirst = true
            end
        end
        if rewardId == 0 then
            for j = 1, #self.GridList do
                self.GridList[j].GameObject:SetActiveEx(false)
            end
            return
        end
        if IsFirst then
            self.TxtDrop.text = CS.XTextManager.GetText("FirstRewardTitle")
        else
            self.TxtDrop.text = CS.XTextManager.GetText("DropRewardTitle")
        end
        rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end
    
    -- if IsFirst then
    --     self.TxtDrop.text = CS.XTextManager.GetText("FirstRewardTitle")
    -- else
    --     self.TxtDrop.text = CS.XTextManager.GetText("DropRewardTitle")
    -- end
    -- rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.RewardGridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.RewardDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
            local obj = grid.Transform:Find("GetTips")
            if IsFirst and stageInfo.Passed then
                if obj then
                    obj.gameObject:SetActiveEx(true)
                end
            else
                if obj then
                    obj.gameObject:SetActiveEx(false)
                end
            end
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end

function XUiFubenNierGuanqiaNormal:UpdatePODAndSkill()
    local nieRPOD = XDataCenter.NieRManager.GetNieRPODData()
    local skillList = nieRPOD:GetFightSkillList()
    self.PODHeadImg:SetSprite(nieRPOD:GetNieRPODHeadIcon())
    self.SkillList = skillList
    local defIndex = 1
    local defSelSkillId = nieRPOD:GetNieRPODSelectSkillId()
    for index, skillInfo in ipairs(skillList) do
        local grid
        if not self.GirdSkillList[index] then
            local ui
            local parent = self.PODPanelSkillContent
            
            if index == 1 then
                ui = self.PODGridSkillNormal 
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(parent, false)
                grid = XUiGridFubenNierPODSkill.New(ui, self)
            else
                ui = CS.UnityEngine.Object.Instantiate(self.PODGridSkillNormal)
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(parent, false)
                grid = XUiGridFubenNierPODSkill.New(ui, self)
            end
            self.GirdSkillList[index] = grid
        else
            grid = self.GirdSkillList[index]
        end
        if defSelSkillId == skillInfo.SkillId and nieRPOD:CheckNieRPODSkillActive(defSelSkillId) then
            defIndex = index
        end
        grid:SetSelectStatue(false)
        grid:RefreshData(skillInfo, index)
    end
    self:OnBtnSkillClick(defIndex)
end

function XUiFubenNierGuanqiaNormal:OnBtnSkillClick(index)
    local info =  self.SkillList[index]
    if not info then
        return 
    end
    if not info.IsActive then
        XUiManager.TipMsg(info.Desc)
        return
    end
    local grid
    if self.SelectNieRPODIndex then
        grid = self.GirdSkillList[self.SelectNieRPODIndex]
        grid:SetSelectStatue(false)
    end
    self.SelectNieRPODIndex = index
    self.SelectNieRPODSkillId = info and info.SkillId
    grid = self.GirdSkillList[self.SelectNieRPODIndex]
    grid:SetSelectStatue(true)
end

function XUiFubenNierGuanqiaNormal:OnBtnEnterClick() 
    if XDataCenter.FubenManager.CheckPreFight(self.Stage) then 
        if self.SelectNieRPODSkillId ~= XDataCenter.NieRManager.GetNieRPODData():GetNieRPODSelectSkillId() then
            XDataCenter.NieRManager.NieRSelectSupportSkill(self.SelectNieRPODSkillId)
        end
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.Stage.StageId) --, nil, self.RepeatStageId, self.ChapterId)
    end
end