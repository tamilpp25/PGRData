local XUiEnterFight = XLuaUiManager.Register(XLuaUi, "UiEnterFight")

function XUiEnterFight:OnStart(type, name, dis, icon, rewardId, cb, stageId, areaId)
    self.Callback = cb
    self.RewardId = rewardId
    self.Items = {}
    self.StageId = stageId
    self.AreaId = areaId

    self:InitAutoScript()
    if type == XFubenExploreConfigs.NodeTypeEnum.Story then
        self:OnShowStoryDialog(name, dis, icon)
    elseif type == XFubenExploreConfigs.NodeTypeEnum.Stage then
        self:OnShowFightDialog(name, dis, icon)
    elseif type == XFubenExploreConfigs.NodeTypeEnum.Arena then
        self:OnShowArenaDialog()
    end
    self:UpdateReward()
end

function XUiEnterFight:OnGetEvents()
    return { XEventId.EVENT_ARENA_RESULT_AUTOFIGHT }
end

function XUiEnterFight:OnNotify(evt)
    if evt == XEventId.EVENT_ARENA_RESULT_AUTOFIGHT then
        self:OnShowArenaDialog()
    end
end

function XUiEnterFight:InitAutoScript()
    self:AutoAddListener()
end

function XUiEnterFight:AutoAddListener()
    self:RegisterClickEvent(self.BtnMaskB, self.OnBtnMaskBClick)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
    self:RegisterClickEvent(self.BtnEnterArena, self.OnBtnEnterArenaClick)
    self.BtnCannotAutoFight.CallBack = function()
        self:OnBtnCannotAutoFightClick()
    end

    self.BtnAutoFight.CallBack = function()
        self:OnBtnAutoFightClick()
    end
end

function XUiEnterFight:OnBtnMaskBClick()
    self:Close()
end

function XUiEnterFight:OnBtnEnterStoryClick()
    self:Close()
    self:OnCallback()
end

function XUiEnterFight:OnBtnEnterFightClick()
    self:Close()
    self:OnCallback()
end

function XUiEnterFight:OnBtnEnterArenaClick()
    self:Close()
    self:OnCallback()
end

function XUiEnterFight:OnBtnCannotAutoFightClick()
    --1.没有满分通关过
    if not XDataCenter.ArenaManager.IsCanAutoFightByStageId(self.StageId) then
        XUiManager.TipText("ArenaCannotAutoFight")
        return
    end
    --2.满分通关过，但是现在已经满分了
    local score = XDataCenter.ArenaManager.GetArenaStageScore(self.AreaId, self.StageId)
    local config = XArenaConfigs.GetArenaStageConfig(self.StageId)
    local maxPoint = XArenaConfigs.GetMarkMaxPointById(config.MarkId)
    if score == maxPoint then
        XUiManager.TipText("ArenaMarkAlreadyMax")
        return
    end
end

function XUiEnterFight:OnBtnAutoFightClick()
    XDataCenter.ArenaManager.RequestAutoFight(self.AreaId, self.StageId)
end

function XUiEnterFight:OnShowStoryDialog(name, dis, icon)
    self.PanelStory.gameObject:SetActiveEx(true)
    self.PanelFight.gameObject:SetActiveEx(false)
    self.PanelArena.gameObject:SetActiveEx(false)

    self.TxtStoryName.text = name
    self.TxtStoryDec.text = dis
    self.RImgStory:SetRawImage(icon)
end

function XUiEnterFight:OnShowFightDialog(name, dis, icon)
    self.PanelFight.gameObject:SetActiveEx(true)
    self.PanelStory.gameObject:SetActiveEx(false)
    self.PanelArena.gameObject:SetActiveEx(false)

    self.TxtFightName.text = name
    self.TxtFightDec.text = string.gsub(dis, "\\n", "\n")
    self.RImgFight:SetRawImage(icon)
end

function XUiEnterFight:OnShowArenaDialog()
    self.PanelFight.gameObject:SetActiveEx(false)
    self.PanelStory.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
    self.ImgGqdl.gameObject:SetActiveEx(false)
    self.PanelArena.gameObject:SetActiveEx(true)

    local score = XDataCenter.ArenaManager.GetArenaStageScore(self.AreaId, self.StageId)
    local config = XArenaConfigs.GetArenaStageConfig(self.StageId)
    local areaStageConfig = XArenaConfigs.GetArenaAreaStageCfgByAreaId(self.AreaId)
    if score > 0 then
        self.TxtArenaScore.text = CS.XTextManager.GetText("ArenaHighDesc", score)
    else
        self.TxtArenaScore.text = score
    end

    if areaStageConfig.AutoFight[config.MarkId] == nil or areaStageConfig.AutoFight[config.MarkId] == 0 then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnCannotAutoFight.gameObject:SetActiveEx(false)
    else
        local maxPoint = XArenaConfigs.GetMarkMaxPointById(config.MarkId)
        local isCurrentMaxMark = score == maxPoint
        if XDataCenter.ArenaManager.IsCanAutoFightByStageId(self.StageId) and not isCurrentMaxMark then
            self.BtnAutoFight.gameObject:SetActiveEx(true)
            self.BtnCannotAutoFight.gameObject:SetActiveEx(false)
        else
            self.BtnAutoFight.gameObject:SetActiveEx(false)
            self.BtnCannotAutoFight.gameObject:SetActiveEx(true)
        end
    end

    self.RImgArena:SetRawImage(config.BgIconBig)
    self.ImgArenaDifficulty:SetRawImage(config.DifficuIocn)
    self.TxtArenatName.text = config.Name
end

function XUiEnterFight:UpdateReward()
    self.Grid128.gameObject:SetActiveEx(false)
    if self.RewardId and self.RewardId > 0 then
        self.ImgGqdl.gameObject:SetActiveEx(true)
        self.PanelReward.gameObject:SetActiveEx(true)
        local data = XRewardManager.GetRewardList(self.RewardId)
        data = XRewardManager.MergeAndSortRewardGoodsList(data)
        XUiHelper.CreateTemplates(self, self.Items, data, XUiGridCommon.New, self.Grid128, self.PanelReward, function(grid, gridData)
            grid:Refresh(gridData)
        end)
    else
        self.PanelReward.gameObject:SetActiveEx(false)
        self.ImgGqdl.gameObject:SetActiveEx(false)
    end
end

function XUiEnterFight:OnCallback()
    if self.Callback then
        self.Callback()
    end
end