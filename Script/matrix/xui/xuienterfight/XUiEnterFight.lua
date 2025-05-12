local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
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
    end
    self:UpdateReward()
end

function XUiEnterFight:InitAutoScript()
    self:AutoAddListener()
end

function XUiEnterFight:AutoAddListener()
    self:RegisterClickEvent(self.BtnMaskB, self.OnBtnMaskBClick)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
    self.BtnEnterArena.gameObject:SetActiveEx(false)
    self.BtnCannotAutoFight.gameObject:SetActiveEx(false)
    self.BtnAutoFight.gameObject:SetActiveEx(false)
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