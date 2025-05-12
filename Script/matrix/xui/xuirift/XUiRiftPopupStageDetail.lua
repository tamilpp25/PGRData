local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiRiftPopupStageDetail : XLuaUi 关卡详情
---@field _Control XRiftControl
local XUiRiftPopupStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftPopupStageDetail")

function XUiRiftPopupStageDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnBuff, self.OnBtnBuffClick)
    self:RegisterClickEvent(self.BtnBattle, self.OnBtnBattleClick)
    self:RegisterClickEvent(self.BtnBubbleClose, self.OnHideBubble)
    self:RegisterClickEvent(self.BtnStory, self.OnBtnStoryClick)
    self:RegisterClickEvent(self.BtnBubbleClose, self.OnClosePluginTip)
end

function XUiRiftPopupStageDetail:OnStart(fightLayer, isLuck)
    ---@type XRiftFightLayer
    self._FightLayer = fightLayer
    self._IsLuck = isLuck

    ---@type XUiGridRiftPluginDrop
    self._Tip = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(self.GridRiftPluginTips, self)
    self._Param = {}
    self._Param.DecomposeCount = 0

    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiRiftPopupStageDetail:OnEnable()
    self:OnHideBubble()

    local config = self._FightLayer:GetConfig()
    self.TxtTitle.text = self._IsLuck and self._Control:GetLuckName() or config.Name
    self.TxtDetail.text = self._IsLuck and self._Control:GetLuckDesc() or config.Desc
    self.Grid256New.gameObject:SetActiveEx(false)
    self.GridPlugin.gameObject:SetActiveEx(false)
    self.GridRiftPlugin.gameObject:SetActiveEx(false)
    self.BtnStory.gameObject:SetActiveEx(self._FightLayer:HasStory() and not self._IsLuck)
    -- 通关奖励
    if self._IsLuck then
        self.PanelReward.gameObject:SetActiveEx(false)
    else
        self.PanelReward.gameObject:SetActiveEx(true)
        local rewards = {}
        local rewardId = config.RewardId
        if rewardId > 0 then
            rewards = XRewardManager.GetRewardList(rewardId)
        end
        for _, item in ipairs(rewards) do
            local ui = XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            local grid = XUiGridCommon.New(self, ui)
            grid:Refresh(item)
            grid:SetName("")
            grid:SetReceived(self._FightLayer:CheckFirstPassed())
            grid.GameObject:SetActive(true)
        end
        local plugins = config.FirstPassDropPluginIds
        for _, plugin in ipairs(plugins) do
            local go = XUiHelper.Instantiate(self.GridPlugin, self.GridPlugin.parent)
            go.gameObject:SetActive(true)
            ---@type XUiRiftPluginGrid
            local grid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid").New(go, self)
            local data = self._Control:GetPlugin(plugin)
            grid:Refresh(data)
            grid:SetChange(self._Control:IsLayerPass(self._FightLayer:GetFightLayerId()))
            grid:Init(function()
                self:OpenPluginTip(plugin, grid.Transform)
            end)
        end
    end
    -- 掉落概率
    local layerDetail = self._Control:GetLayerDetailConfigById(self._FightLayer:GetFightLayerId())
    local pluginIds = self._IsLuck and layerDetail.LuckPluginList or layerDetail.PluginList
    for i, pluginId in ipairs(pluginIds) do
        local ui = XUiHelper.Instantiate(self.GridRiftPlugin, self.GridRiftPlugin.parent)
        ---@type XUiRiftPluginGrid
        local grid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid").New(ui, self)
        local plugin = self._Control:GetPlugin(pluginId)
        grid:Refresh(plugin)
        grid:Init(function()
            self:OpenPluginTip(pluginId, grid.Transform)
        end)
        local drop = self._IsLuck and self._Control:GetLuckPluginDrop(i) or self._FightLayer:GetPluginDrop(i)
        grid:SetDropPercentage(math.round(drop / 100))
        grid.GameObject:SetActive(true)
    end
    -- buff
    local chapter = self._FightLayer:GetParent():GetConfig()
    self.BtnBuff:SetNameByGroup(0, chapter.BuffName)
    self.BtnBuff:SetSprite(chapter.BuffIcon)
    self.TxtBuffDetail.text = chapter.BuffDesc
    -- 进度/通关时间
    local isShowBar = false
    local timeStr, numStr, passTime, progress
    if self._FightLayer:IsChallenge() then
        passTime = self._FightLayer:GetParent():GetPassTime()
        if XTool.IsNumberValid(passTime) then
            isShowBar = true
            timeStr = XUiHelper.GetTime(passTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        end
    else
        progress = self._FightLayer:GetFightProgress()
        if XTool.IsNumberValid(progress) then
            isShowBar = true
            numStr = string.format("%s%%", math.floor(progress * 100))
        end
    end
    self.ImgBg01.gameObject:SetActiveEx(isShowBar and not self._IsLuck)
    self.PanelBar.gameObject:SetActiveEx(isShowBar and numStr and not self._IsLuck)
    if timeStr and not self._IsLuck then
        self.TxtTime.gameObject:SetActiveEx(true)
        self.TxtTime.text = timeStr
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
    if numStr and not self._IsLuck then
        self.TxtNum.gameObject:SetActiveEx(true)
        self.TxtNum.text = numStr
        self.ImgBar.fillAmount = progress
    else
        self.TxtNum.gameObject:SetActiveEx(false)
    end
end

-- 注意GridRiftPluginTips的锚点
function XUiRiftPopupStageDetail:OpenPluginTip(pluginId, grid)
    self._Tip:Open()
    self._Param.PluginId = pluginId
    self._Tip:Refresh(self._Param)
    local pos = self.GridRiftPluginTips.parent:InverseTransformPoint(grid.transform.position)
    local posX = pos.x - grid.rect.width * grid.localScale.x * grid.pivot.x
    local posY = pos.y + grid.rect.height * grid.localScale.y * (1 - grid.pivot.y)
    posY = math.max(posY, self.GridRiftPluginTips.rect.height - self.Transform.rect.height / 2)
    self.GridRiftPluginTips.pivot.x = posX + self.GridRiftPluginTips.rect.width > self.Transform.rect.width / 2 and 1 or 0
    self.GridRiftPluginTips.localPosition = Vector3(posX, posY, 0)
    self.TipAnimEnable.gameObject:PlayTimelineAnimation()
end

function XUiRiftPopupStageDetail:OnBtnBattleClick()
    if self._IsLuck then
        self._Control:RiftStartLuckyNodeRequest(function()
            local stageId = self._Control:GetLuckStageId()
            if XTool.IsNumberValid(stageId) then
                local teamData = self._Control:GetSingleTeamData(true)
                self:Close()
                XLuaUiManager.Open("UiBattleRoleRoom", stageId, teamData, require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
            end
        end)
    else
        local chapter = self._FightLayer:GetParent()
        self._Control:CheckDayTipAndDoFun(chapter, function()
            local stageId = self._Control:GetCurrSelectRiftStageGroup():GetAllEntityStages()[1]._StageId
            local teamData = self._Control:GetSingleTeamData()
            self:Close()
            XLuaUiManager.Open("UiBattleRoleRoom", stageId, teamData, require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
        end)
    end
end

function XUiRiftPopupStageDetail:OnBtnBuffClick()
    if self.BubbleBuffDetail.gameObject.activeSelf then
        self:OnHideBubble()
    else
        self.BubbleBuffDetail.gameObject:SetActiveEx(true)
    end
end

function XUiRiftPopupStageDetail:OnHideBubble()
    self.BubbleBuffDetail.gameObject:SetActiveEx(false)
end

function XUiRiftPopupStageDetail:OnBtnStoryClick()
    self:Close()
    XLuaUiManager.OpenWithCloseCallback("UiRiftPopupStory", function()
        XLuaUiManager.Open("UiRiftPopupStageDetail", self._FightLayer, self._IsLuck)
    end, self._FightLayer:GetConfig().StoryId)
end

function XUiRiftPopupStageDetail:OnClosePluginTip()
    self._Tip:Close()
end

return XUiRiftPopupStageDetail