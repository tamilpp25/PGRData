local XUiPanelScoreTowerStage = require("XUi/XUiScoreTower/Popup/XUiPanelScoreTowerStage")
local XUiGridScoreTowerStagePlugin = require("XUi/XUiScoreTower/Popup/XUiGridScoreTowerStagePlugin")
---@class XUiPanelScoreTowerStageBoss : XUiPanelScoreTowerStage
---@field private _Control XScoreTowerControl
local XUiPanelScoreTowerStageBoss = XClass(XUiPanelScoreTowerStage, "XUiPanelScoreTowerStageBoss")

function XUiPanelScoreTowerStageBoss:OnStart()
    self.Super.OnStart(self)
    self.GridStageStar.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridPlugin.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStageStarList = {}
    ---@type UiObject[]
    self.GridBuffList = {}
    ---@type XUiGridScoreTowerStagePlugin[]
    self.GridPluginList = {}
end

function XUiPanelScoreTowerStageBoss:RefreshOther()
    self:RefreshPlugin()
    self:RefreshTarget()
    self:RefreshBuff()
    self:RefreshStageState()
end

-- 刷新关卡目标
function XUiPanelScoreTowerStageBoss:RefreshTarget()
    -- 是否是最终boss
    local isFinalBoss = self._Control:IsStageFinalBoss(self.StageId)
    self.ImgBgTarget.gameObject:SetActiveEx(not isFinalBoss)
    self.StageContent.gameObject:SetActiveEx(isFinalBoss)

    local addFightTime, reduceScore = self._Control:GetPlugEffectAddFightTimeAndReduceScore(self.SelectedPluginIdList)
    if isFinalBoss then
        self:RefreshStar(addFightTime, reduceScore)
        return
    end
    self.TxtTarget.text = self._Control:GetStageBossScoreDesc(self.StageId, 1, addFightTime, reduceScore, "StageBossTargetDesc")
end

-- 刷新关卡星级
function XUiPanelScoreTowerStageBoss:RefreshStar(addFightTime, reduceScore)
    local curStar = self._Control:GetStageCurStar(self.ChapterId, self.TowerId, self.StageId)
    local totalStar = self._Control:GetStageTotalStar(self.StageId)
    for i = 1, totalStar do
        local star = self.GridStageStarList[i]
        if not star then
            star = XUiHelper.Instantiate(self.GridStageStar, self.StageContent)
            self.GridStageStarList[i] = star
        end
        star.gameObject:SetActiveEx(true)
        local desc = self._Control:GetStageBossScoreDesc(self.StageId, i, addFightTime, reduceScore, "StageBossStarDesc")
        star:GetObject("TxtUnActive").text = desc
        star:GetObject("TxtActive").text = desc
        star:GetObject("PanelUnActive").gameObject:SetActiveEx(i > curStar)
        star:GetObject("PanelActive").gameObject:SetActiveEx(i <= curStar)
    end
    for i = totalStar + 1, #self.GridStageStarList do
        self.GridStageStarList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新关卡词缀
function XUiPanelScoreTowerStageBoss:RefreshBuff()
    local bossAffixList = self._Control:GetStageBossAffixEvent(self.StageId)
    if XTool.IsTableEmpty(bossAffixList) then
        self.PanelBuff.gameObject:SetActiveEx(false)
        return
    end
    self.PanelBuff.gameObject:SetActiveEx(true)
    local removeAffixIds = self._Control:GetPlugEffectRemoveAffixIds(self.SelectedPluginIdList)
    for index, affixId in pairs(bossAffixList) do
        local buff = self.GridBuffList[index]
        if not buff then
            buff = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            self.GridBuffList[index] = buff
        end
        buff.gameObject:SetActiveEx(true)
        local icon = self._Control:GetFightEventIcon(affixId)
        if not string.IsNilOrEmpty(icon) then
            buff:GetObject("RImgBuff"):SetRawImage(icon)
        end
        buff:GetObject("PanelDisable").gameObject:SetActiveEx(table.contains(removeAffixIds, affixId))
        buff:GetObject("BtnBuff").CallBack = function() self:OnBuffClick() end
    end
    for index = #bossAffixList + 1, #self.GridBuffList do
        self.GridBuffList[index].gameObject:SetActiveEx(false)
    end
end

-- 点击关卡词缀
function XUiPanelScoreTowerStageBoss:OnBuffClick()
    local removeAffixIds = self._Control:GetPlugEffectRemoveAffixIds(self.SelectedPluginIdList)
    self.Parent:ShowBubbleBuffDetail(removeAffixIds)
end

-- 刷新插件
function XUiPanelScoreTowerStageBoss:RefreshPlugin()
    -- 插件Id列表
    self.PluginIdList = self._Control:GetStageBossPlugIds(self.StageId)
    -- 已选择的插件Id列表
    self.SelectedPluginIdList = self._Control:GetStageSelectedPlugIds(self.ChapterId, self.TowerId, self.StageId)
    for index, pluginId in pairs(self.PluginIdList) do
        local grid = self.GridPluginList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPlugin, self.PanelPlugin)
            grid = XUiGridScoreTowerStagePlugin.New(go, self, handler(self, self.OnPluginClick), handler(self, self.OnPlayPlugVideo))
            self.GridPluginList[index] = grid
        end
        grid:Open()
        grid:Refresh(pluginId)
        grid:SetSelected(table.contains(self.SelectedPluginIdList, pluginId))
    end
    for index = #self.PluginIdList + 1, #self.GridPluginList do
        self.GridPluginList[index]:Close()
    end
end

-- 获取剩余的插件点数
function XUiPanelScoreTowerStageBoss:GetRemainPluginPoint()
    local needPoint = self._Control:GetPlugTotalNeedPoint(self.SelectedPluginIdList)
    local totalPoint = self._Control:GetTowerTotalPlugInPoint(self.ChapterId, self.TowerId)
    return totalPoint - needPoint
end

-- 检查插件点数是否足够
function XUiPanelScoreTowerStageBoss:CheckPluginPointEnough(pluginId)
    return self:GetRemainPluginPoint() >= self._Control:GetPlugNeedPoint(pluginId)
end

-- 点击插件
---@param pluginId number 插件Id
---@param grid XUiGridScoreTowerStagePlugin 插件格子
function XUiPanelScoreTowerStageBoss:OnPluginClick(pluginId, grid)
    local contain, pos = table.contains(self.SelectedPluginIdList, pluginId)
    if contain then
        table.remove(self.SelectedPluginIdList, pos)
    else
        if not self:CheckPluginPointEnough(pluginId) then
            grid:SetSelected(false)
            XUiManager.TipMsg(self._Control:GetClientConfig("PluginPointNotEnough"))
            return
        end
        table.insert(self.SelectedPluginIdList, pluginId)
    end
    self.Parent:RefreshPlugInPointByPlugIds(self.SelectedPluginIdList)
    self:RefreshTarget()
    self:RefreshBuff()
end

-- 播放插件视频
---@param pluginId number 插件Id
function XUiPanelScoreTowerStageBoss:OnPlayPlugVideo(pluginId)
    self.Parent:ShowBubbleVideo(pluginId)
end

-- 刷新关卡状态
function XUiPanelScoreTowerStageBoss:RefreshStageState()
    -- 检查词缀关是否全部通关
    local isAllPass = self._Control:IsNormalStageAllPass(self.ChapterId, self.TowerId, self.FloorId)
    self.TxtTips.gameObject:SetActiveEx(not isAllPass)
    self.ListCharacter.gameObject:SetActiveEx(isAllPass)
    self.BtnStart:SetDisable(not isAllPass)
    if isAllPass then
        self:RefreshCharacterList()
    else
        self.TxtTips.text = self._Control:GetClientConfig("EnterStageBossTips")
    end
end

-- boss关卡不显示推荐
function XUiPanelScoreTowerStageBoss:IsRecommendTag(entityId)
    return false
end

-- 进编队前检查
function XUiPanelScoreTowerStageBoss:CheckBeforeEnterFormation()
    local isAllPass = self._Control:IsNormalStageAllPass(self.ChapterId, self.TowerId, self.FloorId)
    if not isAllPass then
        XUiManager.TipMsg(self._Control:GetClientConfig("EnterStageBossTips"))
        return false
    end
    return true
end

-- 进入编队前请求协议
function XUiPanelScoreTowerStageBoss:RequestBeforeEnterFormation(callback)
    -- 检查剩余插件点数
    if self:GetRemainPluginPoint() < 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("PluginPointNotEnough"))
        return
    end
    local selectedIndexList = self._Control:GetPlugIndexByPlugIds(self.SelectedPluginIdList, self.PluginIdList)
    self._Control:SelectPlugInRequest(self.ChapterId, self.TowerId, self.StageId, selectedIndexList, callback)
end

return XUiPanelScoreTowerStageBoss
