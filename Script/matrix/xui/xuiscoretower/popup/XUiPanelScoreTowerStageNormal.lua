local XUiPanelScoreTowerStage = require("XUi/XUiScoreTower/Popup/XUiPanelScoreTowerStage")
---@class XUiPanelScoreTowerStageNormal : XUiPanelScoreTowerStage
---@field private _Control XScoreTowerControl
local XUiPanelScoreTowerStageNormal = XClass(XUiPanelScoreTowerStage, "XUiPanelScoreTowerStageNormal")

function XUiPanelScoreTowerStageNormal:OnStart()
    self.Super.OnStart(self)
    XUiHelper.RegisterClickEvent(self, self.BtnMopUp, self.OnBtnMopUpClick, nil, true)
    self.GridCondition.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridConditionList = {}
end

function XUiPanelScoreTowerStageNormal:RefreshOther()
    self:RefreshPlugPoint()
    self:RefreshCharacterList()
    self:RefreshMopUp()
    self:RefreshStartBattle()
end

-- 刷新插件点
function XUiPanelScoreTowerStageNormal:RefreshPlugPoint()
    local plugPointIds = self._Control:GetStagePlugPointIds(self.StageId)
    if XTool.IsTableEmpty(plugPointIds) then
        self.ListCondition.gameObject:SetActiveEx(false)
        return
    end
    self.ListCondition.gameObject:SetActiveEx(true)
    for index, pointId in pairs(plugPointIds) do
        local grid = self.GridConditionList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridCondition, self.ListCondition)
            self.GridConditionList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local isActive = self:IsPlugPointComplete(pointId)
        local panelActive = grid:GetObject("PanelActive")
        local panelUnActive = grid:GetObject("PanelUnActive")
        panelActive.gameObject:SetActiveEx(isActive)
        panelUnActive.gameObject:SetActiveEx(not isActive)
        ---@type UiObject
        local panelUi = isActive and panelActive or panelUnActive
        panelUi:GetObject("TxtCondition").text = self._Control:GetPlugPointDesc(pointId)
        panelUi:GetObject("TxtNum").text = string.format("+%s", self._Control:GetPlugPointPoint(pointId))
        local icon = self._Control:GetClientConfig("PlugPointIcon")
        if not string.IsNilOrEmpty(icon) then
            panelUi:GetObject("ImgIcon"):SetSprite(icon)
        end
    end
    for i = #plugPointIds + 1, #self.GridConditionList do
        self.GridConditionList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新扫荡
function XUiPanelScoreTowerStageNormal:RefreshMopUp()
    -- 扫荡战力
    local sweepAbility = self._Control:GetStageSweepAverFaRequire(self.StageId)
    self.TxtCondition.text = XUiHelper.FormatText(self._Control:GetClientConfig("SweepConditionDesc"), sweepAbility)
    -- 队伍平均战力
    local teamAverageAbility = self.StageTeam and self.StageTeam:GetTeamAverageAbility() or 0
    -- 是否满足扫荡战力
    local isSweep = teamAverageAbility >= sweepAbility
    local isFullMember = self.StageTeam and self.StageTeam:GetIsFullMember() or false
    self.ImgComplete.gameObject:SetActiveEx(isSweep)
    self.BtnMopUp:SetDisable(not isSweep or not isFullMember)
end

-- 刷新开始战斗按钮
function XUiPanelScoreTowerStageNormal:RefreshStartBattle()
    local isFullMember = self.StageTeam and self.StageTeam:GetIsFullMember() or false
    self.BtnStart:SetDisable(not isFullMember)
end

-- 检查是否符合要求
---@param pointId number 插件点Id
function XUiPanelScoreTowerStageNormal:IsPlugPointComplete(pointId)
    if not self.StageTeam then
        return false
    end
    local pointType = self._Control:GetPlugPointType(pointId)
    local pointParams = self._Control:GetPlugPointParams(pointId)
    if pointType == XEnumConst.ScoreTower.PointType.Tag then
        return self:CheckTagPoint(pointParams)
    elseif pointType == XEnumConst.ScoreTower.PointType.Fa then
        return self:CheckFaPoint(pointParams[1])
    elseif pointType == XEnumConst.ScoreTower.PointType.Liberate then
        return self:CheckLiberatePoint(pointParams[1])
    elseif pointType == XEnumConst.ScoreTower.PointType.Equip then
        return self:CheckEquipPoint(pointParams[1])
    elseif pointType == XEnumConst.ScoreTower.PointType.TagCompose then
        return self:CheckTagComposePoint(pointParams)
    end
    return false
end

---@param tags string[] 标签
function XUiPanelScoreTowerStageNormal:CheckTagPoint(tags)
    local allCharacterIds = self.StageTeam:GetAllCharacterIds()
    for _, characterId in pairs(allCharacterIds) do
        local characterTagList = self._Control:GetCharacterTagList(characterId)
        for _, tag in pairs(tags) do
            local tagNum = string.IsNumeric(tag) and tonumber(tag) or 0
            if table.contains(characterTagList, tagNum) then
                return true
            end
        end
    end
    return false
end

---@param requiredFaStr string 所需战力
function XUiPanelScoreTowerStageNormal:CheckFaPoint(requiredFaStr)
    local requiredFa = string.IsNumeric(requiredFaStr) and tonumber(requiredFaStr) or 0
    local teamAverageAbility = self.StageTeam:GetTeamAverageAbility()
    return teamAverageAbility >= requiredFa
end

---@param levelStr string 角色解放等级
function XUiPanelScoreTowerStageNormal:CheckLiberatePoint(levelStr)
    local level = string.IsNumeric(levelStr) and tonumber(levelStr) or 0
    local entityIds = self.StageTeam:GetEntityIds()
    for _, entityId in pairs(entityIds) do
        if XTool.IsNumberValid(entityId) then
            if XRobotManager.CheckIsRobotId(entityId) then
                ---@type XTableRobot
                local cfg = XRobotManager.GetRobotTemplate(entityId)
                if cfg and cfg.LiberateLv >= level then
                    return true
                end
            else
                local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(entityId)
                if growUpLevel >= level then
                    return true
                end
            end
        end
    end
    return false
end

---@param levelStr string 武器谐振等级
function XUiPanelScoreTowerStageNormal:CheckEquipPoint(levelStr)
    local level = string.IsNumeric(levelStr) and tonumber(levelStr) or 0
    local entityIds = self.StageTeam:GetEntityIds()
    for _, entityId in pairs(entityIds) do
        if XTool.IsNumberValid(entityId) then
            if XRobotManager.CheckIsRobotId(entityId) then
                ---@type XTableRobot
                local cfg = XRobotManager.GetRobotTemplate(entityId)
                if cfg and cfg.OverrunLevel >= level then
                    return true
                end
            else
                ---@type XEquip[]
                local characterEquips = XMVCA.XEquip:GetWearingEquipList(entityId)
                for _, equip in pairs(characterEquips) do
                    if equip:GetOverrunLevel() >= level then
                        return true
                    end
                end
            end
        end
    end
    return false
end

---@param tagFormulas string[] 角色tag
function XUiPanelScoreTowerStageNormal:CheckTagComposePoint(tagFormulas)
    if not XTool.IsTableEmpty(tagFormulas) then
        -- 解析的标签-数量映射表，用于后续的条件查找
        local tag2Num = {}

        -- 解析表达式
        for _, formula in pairs(tagFormulas) do
            local result = string.Split(formula, '|')

            if XTool.GetTableCount(result) >= 2 then
                local count = string.IsNumeric(result[1]) and tonumber(result[1]) or nil
                local tag = string.IsNumeric(result[2]) and tonumber(result[2]) or 0

                tag2Num[tag] = count
            end
        end

        -- 检查
        local allCharacterIds = self.StageTeam:GetAllCharacterIds()
        for _, characterId in pairs(allCharacterIds) do
            local characterTagList = self._Control:GetCharacterTagList(characterId)
            -- 检查该角色的标签，如果在映射表里对应的上，则计数-1直至为0
            if not XTool.IsTableEmpty(characterTagList) then
                for _, tag in pairs(characterTagList) do
                    if XTool.IsNumberValid(tag2Num[tag]) then
                        tag2Num[tag] = tag2Num[tag] - 1

                        if tag2Num[tag] <= 0 then
                            tag2Num[tag] = nil
                        end
                    end
                end
            end
        end

        -- 如果映射表为空，则表明标签计数满足
        if XTool.IsTableEmpty(tag2Num) then
            return true
        end
    end

    return false
end

-- 点击角色头像
---@param entityId number 实体Id
---@param index number 索引
function XUiPanelScoreTowerStageNormal:OnGridCharacterClick(entityId, index)
    self.Parent:ShowBubbleChooseCharacter(entityId, self.StageTeam, self.IndexMapping)
end

function XUiPanelScoreTowerStageNormal:CheckBeforeEnterFormation()
    if not self.StageTeam:GetIsFullMember() then
        XUiManager.TipMsg(self._Control:GetClientConfig("CharacterNumNotEnoughTip"))
        return false
    end
    if self.StageTeam:GetCurrentEntityLimit() == 1 then
        XMVCA.XScoreTower:EnterFight(self.StageCfgId, self.StageTeam, false, 1)
        return false
    end
    return true
end

function XUiPanelScoreTowerStageNormal:OnBtnMopUpClick()
    if not self.StageTeam:GetIsFullMember() then
        XUiManager.TipMsg(self._Control:GetClientConfig("CharacterNumNotEnoughTip"))
        return
    end
    local sweepAbility = self._Control:GetStageSweepAverFaRequire(self.StageId)
    local teamAverageAbility = self.StageTeam and self.StageTeam:GetTeamAverageAbility() or 0
    if teamAverageAbility < sweepAbility then
        XUiManager.TipMsg(self._Control:GetClientConfig("SweepConditionNotMeetTip"))
        return
    end
    self._Control:SetStageTeamRequestByTeam(self.StageTeam, true, function()
        self._Control:SweepStageRequest(self.ChapterId, self.TowerId, self.StageId, function()
            self.Parent:OnSweepSuccess()
        end)
    end)
end

return XUiPanelScoreTowerStageNormal
