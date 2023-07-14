local XUiGridNierRepeatMainStage = XClass(nil, "XUiGridNierRepeatMainStage")
local MAX_GIRD_COUNT = 3
function XUiGridNierRepeatMainStage:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    self.RootUi:RegisterClickEvent(self.BtnChapter, function()
        self:OnBtnChapterClick()
    end)
    self.GridList = {}
end

function XUiGridNierRepeatMainStage:UpdateInfo(data)
    self.NierRepeatStageId = data:GetNieRRepeatStageId()
    self.StageId = data:GetNieRRepeatStageId()
    self.Stage = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TitleName.text = self.Stage.Name
    self.RepeatData = data

    local Icon = self.Stage.Icon
    
    if data:CheckNieRRepeatMainStageUnlock() then
        self.PanelNewEffect.gameObject:SetActiveEx(false)
        local starNum = data:GetNieRRepeatStar()
        starNum = starNum > 4 and 4 or starNum
        for index = 1, 4 do
            if index <= starNum then
                self["DarkStar"..index].gameObject:SetActiveEx(false)
            else
                self["DarkStar"..index].gameObject:SetActiveEx(true)
            end
        end
        self.ImgFinish.gameObject:SetActiveEx(starNum > 4)
        self:UpdateRewardShow(data, starNum)

        local consumeId, consumCount = XDataCenter.NieRManager.GetRepeatStageConsumeId(), data:GetNierRepeatStageConsumeCount()
        local haveCount = XDataCenter.ItemManager.GetCount(consumeId)
        local needActionPoint = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
        local haveActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
        local redByShowTime = XDataCenter.NieRManager.CheckNieRRepeatRedTime()
        local isRed = false
        if redByShowTime and haveCount >= consumCount and haveActionPoint >= needActionPoint then
            isRed = true
        end
        self.ImgRedDot.gameObject:SetActiveEx(isRed)
        if not Icon or Icon == "" then
            self.PanelNormal.gameObject:SetActiveEx(false)
            self.PanelSpecial.gameObject:SetActiveEx(true)
            self.SpecoalBgLock.gameObject:SetActiveEx(false)
            self.SpecoalBg.gameObject:SetActiveEx(true)
        else
            self.PanelNormal.gameObject:SetActiveEx(true)
            self.PanelSpecial.gameObject:SetActiveEx(false)
            self.BgLock.gameObject:SetActiveEx(false)  
            self.RawBgBg:SetRawImage(Icon)
            self.RawBg:SetRawImage(Icon)
            self.RawBg.gameObject:SetActiveEx(true)
        end
    else
        for index = 1, 4 do
            self["DarkStar"..index].gameObject:SetActiveEx(true)
        end
        self.ImgRedDot.gameObject:SetActiveEx(false)
        self.ImgFinish.gameObject:SetActiveEx(false)
        self.PanelNewEffect.gameObject:SetActiveEx(false)
        if not Icon or Icon == "" then
            self.PanelNormal.gameObject:SetActiveEx(false)
            self.PanelSpecial.gameObject:SetActiveEx(true)
            self.SpecoalBgLock.gameObject:SetActiveEx(true)
            self.SpecoalBg.gameObject:SetActiveEx(false)
        else
            self.PanelNormal.gameObject:SetActiveEx(true)
            self.PanelSpecial.gameObject:SetActiveEx(false)
            self.BgLock.gameObject:SetActiveEx(true)  
            self.RawBgBg:SetRawImage(Icon)
            self.RawBg:SetRawImage(Icon)
            self.RawBgLock:SetRawImage(Icon)
            self.RawBg.gameObject:SetActiveEx(false)
        end
        self:UpdateRewardShow(data, 0)
    end
end

function XUiGridNierRepeatMainStage:UpdateRewardShow(data, starNum)
    local rewardId = 0
    local stage = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local rewards
    local IsFirst = false
    if starNum > 0 then
        rewardId = data:GetNieRExStarReward(starNum)
    else
        rewardId = data:GetNieRNormalReward()
    end
    if rewardId == 0 then
        for j = 1, MAX_GIRD_COUNT do
            if self.GridList[j] then
                self.GridList[j].GameObject:SetActiveEx(false)
            elseif self["Grid"..j] then
                self["Grid"..j].gameObject:SetActiveEx(false)  
            end
        end
        return
    end
    
    rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
        rewardsCount = rewardsCount > 3 and 3 or rewardsCount
        for i = 1, rewardsCount, 1 do
            local grid
            local item = rewards[i]
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = self["Grid"..i]
                grid = XUiGridCommon.New(self.RootUi, ui)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    for j = 1, MAX_GIRD_COUNT do
        if j > rewardsCount then
            if self.GridList[j] then
                self.GridList[j].GameObject:SetActiveEx(false)
            elseif self["Grid"..j] then
                self["Grid"..j].gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiGridNierRepeatMainStage:OnBtnChapterClick()
    local condit, desc = self.RepeatData:CheckNieRRepeatMainStageUnlock()
    if condit then
        self.RootUi:OnBtnChapterClick(self.StageId, self.NierRepeatStageId)
    else
        XUiManager.TipMsg(desc)
    end
end

return XUiGridNierRepeatMainStage