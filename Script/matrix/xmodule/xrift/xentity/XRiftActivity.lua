---@class XRiftActivity
---@field _LuckyNode XRiftLuckyNodeData
---@field _MultiTeamData XRiftTeam[] 队伍数据（存本地）
---@field _SingleTeamData XRiftTeam
---@field _TeamDatas table 队伍对应的加点模板
---@field _MaxLoad number 角色负载上限
---@field _SweepTimes number 已扫荡次数
---@field _SweepTick number 扫荡时间
---@field _TotalAttrLevel number 队伍加点：当前已拥有的属性点数
---@field _AttrLevelMax number 队伍加点：当前单个属性加点最大值
---@field _AttrTemplateDicById XRiftAttributeTemplate[] 队伍加点模板列表
---@field _RankData table 排行榜数据
---@field _ChapterDatas RiftChapterData[] 章节信息
---@field _FightLayerDatas RiftFightLayerData[] 正在挑战的章节的所有作战层信息（一次只能挑战一个章节）
---@field _RolePluginMap table<number, number[]> 角色插件
---@field _OwnPluginIdMap table<number, boolean> 已拥有的插件列表
---@field ChapterId number 当前进行中的章节Id
---@field LayerId number 当前进行中的层Id
local XRiftActivity = XClass(nil, "XRiftActivity")

function XRiftActivity:Ctor()
    self._ChapterDatas = {}
    self._FightLayerDatas = {}
end

function XRiftActivity:NotifyRiftData(data, count)
    self.ActivityId = data.ActivityId
    self:InitMultiTeamData(count)
    self:UpdateCurFight(data.ChapterId, data.LayerId)
    self:UpdateBattleData(data)
    self:UpdateCharacterPluginData(data)
    self:UpdateTeamTemplateData(data)
    self:UpdateMaxLoad(data.PluginPeakLoad)
    self:UpdateSweepTimes(data.SweepTimes, data.SweepTick)
    self:UpdateAttrTemplate(data)
    self:UnlockedPlugin(data.UnlockedPluginIds)
    self:UpdateLuckNode(data.LuckyNode, data.LuckyValue)
    self:UpdateAffixs(data.PluginDetail)
end

--region 关卡数据

function XRiftActivity:UpdateCurFight(chapterId, layerId)
    self.ChapterId = chapterId
    self.LayerId = layerId or 0
end

function XRiftActivity:UpdateBattleData(datas)
    -- 章节信息
    for _, data in ipairs(datas.ChapterDatas) do
        self:UpdateChapterData(data)
    end
end

function XRiftActivity:UpdateChapterData(chapterData)
    ---@type RiftChapterData
    local chapter = self._ChapterDatas[chapterData.ChapterId] or {}
    chapter.PassedLayerOrderMax = chapterData.PassedLayerOrderMax
    chapter.UnlockedLayerOrderMax = chapterData.UnlockedLayerOrderMax
    chapter.RewardedLayerOrderMax = chapterData.RewardedLayerOrderMax
    chapter.TotalPassTime = chapterData.TotalPassTime
    self._ChapterDatas[chapterData.ChapterId] = chapter
    -- 所有作战层信息
    self:UpdateFightLayer(chapterData.ChapterId, chapterData.LayerDataList)
end

-- 作战层
function XRiftActivity:UpdateFightLayer(chapterId, layerDatas)
    if not layerDatas then
        return
    end
    for _, layerData in pairs(layerDatas) do
        ---@type RiftFightLayerData
        local layer = {}
        layer.ChapterId = chapterId
        layer.PluginDropRecords = layerData.PluginDropRecords
        self:UpdateStageGroup(layerData.NodeData, layer, layerData.LayerId)
        self._FightLayerDatas[layerData.LayerId] = layer
    end
end

function XRiftActivity:AddFightLayerDropPlugin(layerId, value)
    local layer = self:GetFightLayerDataById(layerId)
    layer.PluginDropRecords = value
end

---@param layer RiftFightLayerData
function XRiftActivity:UpdateStageGroup(nodeData, layer, layerId)
    ---@type RiftStageGroupData
    local stageGroup = {}
    stageGroup.FightLayerId = layerId
    stageGroup.StageDatas = {}
    for i, data in ipairs(nodeData.StageDatas) do
        self:UpdateStage(i, data, stageGroup)
    end
    layer.StageGroup = stageGroup
end

---@param stageGroup RiftStageGroupData
function XRiftActivity:UpdateStage(index, stageData, stageGroup)
    ---@type RiftStageData
    local stage = {}
    stage.RiftStageId = stageData.RiftStageId
    stage.IsPassed = stageData.IsCurPassed
    stage.PassTime = stageData.PassTime
    stage.Wave = stageData.Wave
    stageGroup.StageDatas[index] = stage
end

function XRiftActivity:GetChapterDatas()
    return self._ChapterDatas
end

function XRiftActivity:GetChapterData(chapterId)
    return self._ChapterDatas and self._ChapterDatas[chapterId] or nil
end

function XRiftActivity:GetFightLayerDataById(id)
    return self._FightLayerDatas and self._FightLayerDatas[id] or nil
end

function XRiftActivity:GetStageGroupByLayerId(id)
    local layer = self:GetFightLayerDataById(id)
    if layer then
        return layer.StageGroup
    end
    return nil
end

function XRiftActivity:GetStageData(layerId, stageIndex)
    local stageGroup = self:GetStageGroupByLayerId(layerId)
    return stageGroup.StageDatas[stageIndex]
end

function XRiftActivity:UpdateStagePass(layerId, stageIndex, isPass, passTime, wave)
    local stageData = self:GetStageData(layerId, stageIndex)
    if stageData then
        stageData.IsPassed = isPass
        stageData.PassTime = passTime
        stageData.Wave = wave
    end
end

function XRiftActivity:GetSweepTimes()
    return self._SweepTimes or 0
end

function XRiftActivity:GetSweepTick()
    return self._SweepTick or 0
end

function XRiftActivity:AddSweepTimes(sweepTick)
    self:UpdateSweepTimes(self:GetSweepTimes() + 1, sweepTick)
end

function XRiftActivity:UpdateSweepTimes(sweepTimes, sweepTick)
    self._SweepTimes = sweepTimes
    self._SweepTick = sweepTick or 0
end

--endregion

--region 角色

function XRiftActivity:UpdateCharacterPluginData(datas)
    if not self._RolePluginMap then
        self._RolePluginMap = {}
    end
    for _, data in pairs(datas.CharacterDatas) do
        local roleId = XTool.IsNumberValid(data.CharacterId) and data.CharacterId or data.RobotId
        self:AddPluginToCharacter(roleId, data.PluginIds)
    end
end

function XRiftActivity:AddPluginToCharacter(roleId, pluginIds)
    if not self._RolePluginMap then
        self._RolePluginMap = {}
    end
    self._RolePluginMap[roleId] = pluginIds
end

function XRiftActivity:GetCharacterPluginData(entityId)
    return self._RolePluginMap and self._RolePluginMap[entityId] or {}
end

--endregion

--region 编队

function XRiftActivity:UpdateTeamTemplateData(datas)
    for _, data in pairs(datas.TeamDatas) do
        local xTeam = self._MultiTeamData and self._MultiTeamData[data.Id]
        if xTeam then
            xTeam:SetAttrTemplateId(data.AttrSetId)
        end
    end
    self._TeamDatas = datas.TeamDatas
end

function XRiftActivity:GetTeamDatas()
    return self._TeamDatas
end

function XRiftActivity:InitMultiTeamData(count)
    if self._MultiTeamData then
        return
    end
    -- 队伍数据会在实例XRiftTeam更新时自动保存到本地
    self._MultiTeamData = {}
    for i = 1, count do
        self._MultiTeamData[i] = require("XModule/XRift/XEntity/XRiftTeam").New(i)
    end
end

function XRiftActivity:CheckRoleInTeam(roleId)
    if self._MultiTeamData then
        for _, xTeam in pairs(self._MultiTeamData) do
            for i = 1, 3 do
                local idInTeam = xTeam:GetEntityIdByTeamPos(i)
                if roleId == idInTeam then
                    return true, xTeam, i
                end
            end
        end
    end
    return false
end

function XRiftActivity:SwapMultiTeamMember(aTeamIndex, aPos, bTeamIndex, bPos)
    local aRoleId = self._MultiTeamData[aTeamIndex]:GetEntityIdByTeamPos(aPos)
    local bRoleId = self._MultiTeamData[bTeamIndex]:GetEntityIdByTeamPos(bPos)
    self._MultiTeamData[aTeamIndex]:UpdateEntityTeamPos(bRoleId, aPos, true)
    self._MultiTeamData[bTeamIndex]:UpdateEntityTeamPos(aRoleId, bPos, true)
end

function XRiftActivity:GetMultiTeamData()
    return self._MultiTeamData
end

function XRiftActivity:ChangeMultiTeamData(data)
    self._MultiTeamData = data
end

function XRiftActivity:GetSingleTeamData(isLuckStage)
    if XTool.IsTableEmpty(self._SingleTeamData) then
        self._SingleTeamData = require("XModule/XRift/XEntity/XRiftTeam").New(-1)
    end
    self._SingleTeamData:SetLuckyStage(isLuckStage)
    return self._SingleTeamData
end

--endregion

--region 加点、模板

function XRiftActivity:UpdateAttrTemplate(riftData)
    self:SetTotalAttrLevel(riftData.TotalAttrLevel)
    self:UpdateAttrLevelMax(riftData.AttrLevelMax)
    -- 更新本地模板
    for _, attrSet in ipairs(riftData.AttrSets) do
        self:UpdateAttrSet(attrSet.Id, attrSet.AttrLevels, attrSet.Name)
    end
end

function XRiftActivity:UpdateAttrSet(id, attrLevels, name)
    if not self._AttrTemplateDicById then
        self._AttrTemplateDicById = {}
    end
    local attrTemp = self._AttrTemplateDicById[id]
    if attrTemp then
        for _, attr in ipairs(attrLevels) do
            attrTemp:SetAttrLevel(attr.Id, attr.Level)
        end
    else
        local xAttrTemplate = require("XModule/XRift/XEntity/XRiftAttributeTemplate").New(id, attrLevels, name)
        self._AttrTemplateDicById[id] = xAttrTemplate
    end
end

---@return XRiftAttributeTemplate
function XRiftActivity:GetAttrTemplate(id)
    if not self._AttrTemplateDicById then
        self._AttrTemplateDicById = {}
    end
    if id == nil then
        id = XEnumConst.Rift.DefaultAttrTemplateId
    end
    if not self._AttrTemplateDicById[id] then
        self._AttrTemplateDicById[id] = require("XModule/XRift/XEntity/XRiftAttributeTemplate").New(id)
    end
    return self._AttrTemplateDicById[id]
end

function XRiftActivity:GetTotalAttrLevel()
    return self._TotalAttrLevel or 0
end

function XRiftActivity:SetTotalAttrLevel(lv)
    self._TotalAttrLevel = lv
end

function XRiftActivity:UpdateAttrLevelMax(attrLevelMax)
    self._AttrLevelMax = attrLevelMax
end

function XRiftActivity:GetAttrLevelMax()
    return self._AttrLevelMax or 0
end

--endregion

--region 插件

function XRiftActivity:UnlockedPlugin(unlockedPluginIds)
    if unlockedPluginIds == nil then
        return
    end
    for _, pluginId in ipairs(unlockedPluginIds) do
        self:SetPluginHave(pluginId)
    end
end

function XRiftActivity:SetPluginHave(pluginId)
    if not self._OwnPluginIdMap then
        self._OwnPluginIdMap = {}
    end
    self._OwnPluginIdMap[pluginId] = true
end

function XRiftActivity:GetOwnPluginIds()
    return self._OwnPluginIdMap
end

function XRiftActivity:IsHavePlugin(pluginId)
    return self._OwnPluginIdMap and self._OwnPluginIdMap[pluginId] or false
end

function XRiftActivity:UpdateMaxLoad(maxLoad)
    self._MaxLoad = maxLoad
end

function XRiftActivity:GetMaxLoad()
    return self._MaxLoad or 0
end

function XRiftActivity:UpdateAffixs(datas)
    self._AffixMap = {}
    if datas then
        for pluginId, affixInfo in pairs(datas) do
            for i, affixId in ipairs(affixInfo.AffixList) do
                self:UpdateAffix(pluginId, i, affixId)
            end
        end
    end
end

function XRiftActivity:UpdateAffix(pluginId, index, affixId)
    if not self._AffixMap[pluginId] then
        self._AffixMap[pluginId] = {}
    end
    self._AffixMap[pluginId][index] = affixId
end

function XRiftActivity:GetAffix(pluginId)
    return self._AffixMap and self._AffixMap[pluginId] or nil
end

--endregion

--region 幸运关

function XRiftActivity:UpdateLuckNode(luckyNode, luckyValue)
    if not self._LuckyNode then
        self._LuckyNode = require("XModule/XRift/XEntity/XRiftLuckyNodeData").New()
    end
    if luckyNode then
        self._LuckyNode:RefreshNode(luckyNode)
    end
    if luckyValue then
        self._LuckyNode:RefreshLuckyValue(luckyValue)
    end
end

function XRiftActivity:GetLuckRiftChapterId()
    return self._LuckyNode and self._LuckyNode:GetLuckRiftChapterId() or 0
end

function XRiftActivity:GetLuckRiftLayerId()
    return self._LuckyNode and self._LuckyNode:GetLuckRiftLayerId() or 0
end

function XRiftActivity:GetLuckRiftStageId()
    return self._LuckyNode and self._LuckyNode:GetLuckRiftStageId() or 0
end

function XRiftActivity:GetLuckyValue()
    return self._LuckyNode and self._LuckyNode:GetLuckyValue() or 0
end

function XRiftActivity:SetLuckPassTime(time)
    if self._LuckyNode then
        self._LuckyNode:SetPassTime(time)
    end
end

function XRiftActivity:GetLuckPassTime()
    return self._LuckyNode and self._LuckyNode:GetPassTime() or 0
end

function XRiftActivity:IsStageBelongLucky(stageId)
    return stageId == self:GetLuckRiftStageId()
end

--endregion

--region 排行榜

function XRiftActivity:UpdateRankData(data)
    self._RankData = data
end

function XRiftActivity:GetRankData()
    return self._RankData
end

--endregion

return XRiftActivity

--region 服务端类

---@class RiftChapterData 章节信息
---@field UnlockedLayerOrderMax number 已解锁最高层数
---@field PassedLayerOrderMax number 已通关最高层数
---@field RewardedLayerOrderMax number 已领取首通奖励最高层数
---@field TotalPassTime number 章节通关时间

---@class RiftFightLayerData 作战层信息
---@field ChapterId number 章节Id
---@field PluginDropRecords table 插件掉落信息
---@field StageGroup RiftStageGroupData 所有节点信息

---@class RiftStageGroupData 节点信息
---@field FightLayerId number 所属层Id
---@field NodeIndex number 节点索引
---@field StageDatas RiftStageData[] 有些节点为多关卡

---@class RiftStageData 关卡信息
---@field RiftStageId number 关卡表的Id（不是关卡Id）
---@field IsPassed boolean 当前是否通关（服务端有个同名的参数 表示历史是否首通 但是客户端用PassedLayerOrderMax来判断了 所以用不到）
---@field PassTime number 通关时间
---@field Wave number 当前怪物波次

--endregion

