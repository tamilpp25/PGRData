---@class XUiGridMonsterCombatStage
local XUiGridMonsterCombatStage = XClass(nil, "XUiGridMonsterCombatStage")

function XUiGridMonsterCombatStage:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiGridMonsterCombatStage:Refresh(stageId)
    self.StageId = stageId
    self.StageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(stageId)
    -- 刷新基本信息
    self:RefreshStageData()
    -- 刷新关卡状态
    self:RefreshStageStatus()
    -- 播放动画
    self.IconEnable:PlayTimelineAnimation()
end

function XUiGridMonsterCombatStage:RefreshStageData()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    -- 关卡背景图
    self.RImgFightActiveNor:SetRawImage(stageCfg.Icon)
    self.RImgFightActiveLock:SetRawImage(stageCfg.Icon)
    -- 关卡名前缀
    local prefixText = string.format("%02d", stageCfg.OrderId)
    self.TxtStagePrefixNor.text = prefixText
    self.TxtStagePrefixLock.text = prefixText
    -- 关卡名
    self.TxtStageTitleNor.text = stageCfg.Name
    self.TxtStageTitleLock.text = stageCfg.Name
    -- 怪物图标
    if self.StageEntity:CheckIsChallengeModel() and self.RImgHeadNor and self.RImgHeadLock then
        local unlockMonsterIds = self.StageEntity:GetUnlockMonsterIds()
        local isEmpty = XTool.IsTableEmpty(unlockMonsterIds)
        self.RImgHeadNor.gameObject:SetActiveEx(not isEmpty)
        self.RImgHeadLock.gameObject:SetActiveEx(not isEmpty)
        if not isEmpty then
            -- 默认取第一个怪物Id
            local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(unlockMonsterIds[1])
            self.RImgHeadNor:SetRawImage(monsterEntity:GetIcon())
            self.RImgHeadLock:SetRawImage(monsterEntity:GetIcon())
        end
    end
    -- 关卡评分
    if self.StageEntity:CheckIsScoreModel() then
        if self.TxtNumber then
            self.TxtNumber.text = self.StageEntity:GetStageMaxScore()
        end
    end
end

function XUiGridMonsterCombatStage:RefreshStageStatus()
    -- 取消选中
    self.ImageSelected.gameObject:SetActiveEx(false)
    local isUnlock = self.StageEntity:CheckIsUnlock()
    -- 是否未解锁
    self.PanelStageNormal.gameObject:SetActiveEx(isUnlock)
    self.PanelStageLock.gameObject:SetActiveEx(not isUnlock)
    if self.StageEntity:CheckIsScoreModel() then
        if self.PanelMastNumber then
            self.PanelMastNumber.gameObject:SetActiveEx(isUnlock)
        end
    end
    -- 是否通关  积分关卡不显示通关图标
    if self.StageEntity:CheckIsScoreModel() then
        self.PanelStagePass.gameObject:SetActiveEx(false)
    else
        self.PanelStagePass.gameObject:SetActiveEx(self.StageEntity:CheckIsPass())
    end
end

-- 是否显示选中框
function XUiGridMonsterCombatStage:SetStageSelect(isSelect)
    if self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridMonsterCombatStage:OnBtnStageClick()
    local isUnlock = self.StageEntity:CheckIsUnlock()
    if not isUnlock then
        XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(self.StageId))
        return
    end
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiGridMonsterCombatStage:OnDisable()
    self.IconDisable:PlayTimelineAnimation()
end

return XUiGridMonsterCombatStage