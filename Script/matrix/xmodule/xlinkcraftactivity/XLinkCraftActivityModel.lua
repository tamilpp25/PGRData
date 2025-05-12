---@class XLinkCraftActivityModel : XModel
local XLinkCraftActivityModel = XClass(XModel, "XLinkCraftActivityModel")
local XTeam = require("XEntity/XTeam/XTeam")
local XLinkCraftActivityData = require('XModule/XLinkCraftActivity/XEntity/XLinkCraftActivityData')

local TableNormal = {
    LinkCraftActivity = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    LinkCraftChapter = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    LinkCraftStage =  { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    LinkCraftLink = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    LinkCraftSkill = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    LinkCraftClientConfig =  { DirPath = XConfigUtil.DirectoryType.Client,Identifier='Key',ReadFunc=XConfigUtil.ReadType.String },

}

local TablePrivate = {
}

local PrivateMap = {}

function XLinkCraftActivityModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('LinkCraft',TableNormal,XConfigUtil.CacheType.Normal)
    --self._ConfigUtil:InitConfigByTableKey('LinkCraft',TablePrivate,XConfigUtil.CacheType.Private)
end

function XLinkCraftActivityModel:ClearPrivate()
    --这里执行内部数据清理
    self._LocalTeam = nil
end

function XLinkCraftActivityModel:ResetAll()
    --这里执行重登数据清理
    
end

----------public start----------
--region 玩法队伍

---@return XTeam
function XLinkCraftActivityModel:GetLocalTeam()
    if not self._LocalTeam then
        self._LocalTeam = XTeam.New(self:GetTeamKey())
    end

    return self._LocalTeam

end

function XLinkCraftActivityModel:GetTeamKey()
    return 'XLinkCraftActivityTeam_'..XPlayer.Id
end
--endregion

--region 活动数据
function XLinkCraftActivityModel:InitActivityData(data)

    -- 活动结束等情况会出现空数据下发
    if XTool.IsTableEmpty(data) then
        self._ActivityData = nil
        return
    end
    
    local newData = XLinkCraftActivityData.New(data)
    -- 覆盖前需要把当前选择的章节存一下
    if self._ActivityData and self._ActivityData._CurChapterData then
        self:SetLastSelectChapterId(self._ActivityData._CurChapterData:GetChapterId())
    end
    
    -- 首通检查，用于新技能解锁提示
    PrivateMap.CheckFirstPass(self, self._ActivityData, newData)
    self._ActivityData = newData
end

function XLinkCraftActivityModel:GetActivityId()
    return self._ActivityData and self._ActivityData:GetCurActivityId() or 0
end

---@return XLinkCraftActivityData
function XLinkCraftActivityModel:GetActivityData()
    return self._ActivityData
end

function XLinkCraftActivityModel:GetLastPassStageByChapterId(chapterId)
    local id = XSaveTool.GetData(self:GetLastPassStageKey()..chapterId)
    return id 
end

function XLinkCraftActivityModel:SetSelectStageIdOfLinkStageTab(chapterId, stageId)
    XSaveTool.SaveData(self:GetLastPassStageKey()..chapterId, stageId)
end

function XLinkCraftActivityModel:GetLastPassStageKey()
    return 'XLinkCraftActivityLastPassStage_'..XPlayer.Id..'_'
end

--endregion

--region 技能解锁
function XLinkCraftActivityModel:SetSkillNewMark(skillIdList)
    if XTool.IsTableEmpty(skillIdList) then
        XSaveTool.SaveData(self:GetSkillNewMarkKey(), false)
    else
        XSaveTool.SaveData(self:GetSkillNewMarkKey(), skillIdList)
    end
end

function XLinkCraftActivityModel:GetNewSkill()
    return XSaveTool.GetData(self:GetSkillNewMarkKey())
end

function XLinkCraftActivityModel:GetSkillNewMarkKey()
    return 'XLinkCraftActivity'..tostring(self:GetActivityId())..XPlayer.Id
end
--endregion

function XLinkCraftActivityModel:SetLastSelectChapterId(chapterId)
    self._LastSelectedChapterId = chapterId
end

--- 这个数据在Model生存阶段不会被置空，只会被新的章节覆盖，用于当前章节丢失时保底
function XLinkCraftActivityModel:GetLastSelectChapterId()
    return self._LastSelectedChapterId
end

----------public end----------

----------private start----------

---@param model XLinkCraftActivityModel
---@param oldData XLinkCraftActivityData
---@param newData XLinkCraftActivityData
PrivateMap.CheckFirstPass = function(model, oldData, newData)
    if XTool.IsTableEmpty(oldData) then
        return
    end
    -- 比较通关数据
    local newSkillList = nil
    ---@param v XLinkCraftChapterData 
    for i, v in ipairs(newData._ChapterDataList) do
        if oldData._ChapterDataList[i] then
            for i2, v2 in ipairs(v._StageDatas) do
                -- 如果旧数据没有，则是新通关即首通
                if XTool.IsTableEmpty(oldData._ChapterDataList[i]._StageDatas[i2]) then
                    local cfg = model:GetLinkCraftStageCfgById(v2.StageId)
                    if cfg and XTool.IsNumberValid(cfg.LinkSkill) then
                        if newSkillList == nil then
                            newSkillList = {}
                        end
                        table.insert(newSkillList, cfg.LinkSkill)
                    end
                end
            end
        end
    end

    if not XTool.IsTableEmpty(newSkillList) then
        model:SetSkillNewMark(newSkillList)
    end
end

----------private end----------

----------config start----------
--region 基础读表
function XLinkCraftActivityModel:GetLinkCraftActivityTable()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftActivity)
end

function XLinkCraftActivityModel:GetLinkCraftChapterTable()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftChapter)
end

function XLinkCraftActivityModel:GetLinkCraftStageTable()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftStage)
end

function XLinkCraftActivityModel:GetLinkCraftLinkTable()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftLink)
end

function XLinkCraftActivityModel:GetLinkCraftSkillTable()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftSkill)
end

function XLinkCraftActivityModel:GetLinkCraftClientConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.LinkCraftClientConfig)
end
--endregion

--region 按条件读取配置
---@return XTableLinkCraftActivity
function XLinkCraftActivityModel:GetLinkCraftActivityCfgById(activityId)
    local cfg = self:GetLinkCraftActivityTable()[activityId]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetLinkCraftActivityCfgById',nil,TableNormal.LinkCraftActivity.DirPath,'activityId',activityId)        
        return
    end
    return cfg
end

function XLinkCraftActivityModel:GetLinkCraftChapterCfgById(chapterId)
    local cfg = self:GetLinkCraftChapterTable()[chapterId]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetLinkCraftChapterCfgById',nil,TableNormal.LinkCraftChapter.DirPath,'chapterId',chapterId)
        return
    end
    return cfg
end

---@return XTableLinkCraftStage
function XLinkCraftActivityModel:GetLinkCraftStageCfgById(stageId)
    local cfg = self:GetLinkCraftStageTable()[stageId]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetLinkCraftStageCfgById',nil,TableNormal.LinkCraftStage.DirPath,'stageId',stageId)
        return
    end
    return cfg
end

---stageId是对应Stage.tab表的Id
---@return XTableLinkCraftStage
function XLinkCraftActivityModel:GetLinkCraftStageCfgByStageId(stageId)
    local cfgs = self:GetLinkCraftStageTable()
    for i, cfg in pairs(cfgs) do
        if cfg.StageId == stageId then
            return cfg
        end
    end
end

function XLinkCraftActivityModel:GetLinkCraftLinkCfgById(linkId)
    local cfg = self:GetLinkCraftLinkTable()[linkId]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetLinkCraftLinkCfgById',nil,TableNormal.LinkCraftLink.DirPath,'linkId',linkId)
        return
    end
    return cfg
end

function XLinkCraftActivityModel:GetLinkCraftSkillCfgById(skillId)
    local cfg = self:GetLinkCraftSkillTable()[skillId]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetLinkCraftSkillCfgById',nil,TableNormal.LinkCraftSkill.DirPath,'skillId',skillId)
        return
    end
    return cfg
end

function XLinkCraftActivityModel:GetClientConfigString(key)
    local cfg = self:GetLinkCraftClientConfig()[key]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetClientConfigString',nil,TableNormal.LinkCraftClientConfig.DirPath,'key',key)
        return
    end
    return cfg.Value[1]
end

function XLinkCraftActivityModel:GetClientConfigStringList(key)
    local cfg = self:GetLinkCraftClientConfig()[key]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetClientConfigString',nil,TableNormal.LinkCraftClientConfig.DirPath,'key',key)
        return
    end
    return cfg.Value
end

function XLinkCraftActivityModel:GetClientConfigInt(key)
    local cfg = self:GetLinkCraftClientConfig()[key]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetClientConfigString',nil,TableNormal.LinkCraftClientConfig.DirPath,'key',key)
        return 0
    end

    if string.IsNumeric(cfg.Value[1]) then
        return math.floor(tonumber(cfg.Value[1]))
    end
    
    return 0
end

function XLinkCraftActivityModel:GetClientConfigIntList(key)
    local cfg = self:GetLinkCraftClientConfig()[key]

    if not cfg then
        XLog.ErrorTableDataNotFound('XLinkCraftActivityModel:GetClientConfigString',nil,TableNormal.LinkCraftClientConfig.DirPath,'key',key)
        return
    end
    local list = {}
    for i, v in ipairs(cfg.Value) do
        local num = 0

        if string.IsNumeric(v) then
            num = math.floor(tonumber(v))
        end
        
        table.insert(list, num)
    end
    return list
end
--endregion

----------config end----------


return XLinkCraftActivityModel