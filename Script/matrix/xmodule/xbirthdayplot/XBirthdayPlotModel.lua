
---@class XBirthDayData
---@field Mon number 月份
---@field Day number 天数
---@field UnlockCg table<number, number> 已解锁Cg
---@field NextActiveYear number 下次生日年份
---@field IsChange number 是否修改过生日（为1时已经修改过）
---@field SingleStoryId table<number, number> 已解锁单人剧情Id
---@field ShowEndTime number 单人剧情展示结束时间戳

---@class XBirthdayPlotModel : XModel
---@field _BirthDay XBirthDayData
local XBirthdayPlotModel = XClass(XModel, "XBirthdayPlotModel")

local TableKey = {
    BirthdayPeriod = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "StoryChapterId" },
    SingleStory = {},
    FavorLevelIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Level" },
}

function XBirthdayPlotModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("NewBirthdayPlot", TableKey)
    
    self._SingleStoryList = {} --当期生日单人剧情
    
    self._ActiveChapterId = 0 --当前激活的ChapterId, 只有生日当天才会有值
    self._CachePeriodId = 0
    
    self._BirthDay = {}
    
    self._MaxFavorLevel = {}
end

function XBirthdayPlotModel:ClearTemp()
    self._SingleStoryList = {}
    self._MaxFavorLevel = {}
end

function XBirthdayPlotModel:ClearPrivate()
    self:ClearTemp()
end

function XBirthdayPlotModel:ResetAll()
    self:ClearTemp()
    self._BirthDay = nil
end

---@return XTableBirthdayPeriod
function XBirthdayPlotModel:GetBirthdayPeriod(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BirthdayPeriod, id)
end

function XBirthdayPlotModel:GetBeginMovieId()
    --生日结束剧情Id为第一列
    return self:GetBirthdayMovieId(1)
end

function XBirthdayPlotModel:GetEndMovieId()
    --生日结束剧情Id为第一列
    return self:GetBirthdayMovieId(2)
end

function XBirthdayPlotModel:GetBirthdayMovieId(index)
    if not XTool.IsNumberValid(self._ActiveChapterId) then
        return
    end
    local detailEntityList =  XMVCA.XArchive:GetArchiveStoryDetailList(self._ActiveChapterId)
    --生日剧情的Order会比单人剧情优先级更改
    local detailEntity = detailEntityList and detailEntityList[1] or nil
    if not detailEntity then
        return
    end
    return detailEntity:GetStoryId(index)
end

function XBirthdayPlotModel:IsSingleStory()
    if not XTool.IsNumberValid(self._ActiveChapterId) then
        return false
    end
    local template = self:GetBirthdayPeriod(self._ActiveChapterId)
    return template and template.IsSingleStory == 1 or false
end

function XBirthdayPlotModel:SetActiveChapterId(chapterId)
    self._ActiveChapterId = chapterId
    self._CachePeriodId = nil
end

function XBirthdayPlotModel:UpdateBirthday(birthday)
    if not self._BirthDay then
        self._BirthDay = {}
    end
    for k, v in pairs(birthday) do
        self._BirthDay[k] = v
    end

    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_SET_BIRTHDAY, self:GetBirthday())
end

function XBirthdayPlotModel:DoViewSingleStory(singleStoryId)
    if not self._BirthDay then
        self._BirthDay = {}
    end
    if not self._BirthDay.SingleStoryId then
        self._BirthDay.SingleStoryId = {}
    end
    self._BirthDay.SingleStoryId[singleStoryId] = singleStoryId
end

function XBirthdayPlotModel:IsViewSingleStory(singleStoryId)
    if not self._BirthDay then
        return false
    end
    if not self._BirthDay.SingleStoryId then
        return false
    end
    
    return self._BirthDay.SingleStoryId[singleStoryId] ~= nil
end

---@return XBirthDayData
function XBirthdayPlotModel:GetBirthday()
    return self._BirthDay
end

---@return number[]
function XBirthdayPlotModel:GetSingleStoryList()
    if not XTool.IsTableEmpty(self._SingleStoryList) and self._CachePeriodId == self._ActiveChapterId then
        return self._SingleStoryList
    end
    local list = {}

    ---@type table<number, XTableSingleStory>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SingleStory)

    for _, template in pairs(templates) do
        local periodChapterIds = template.PeriodChapterIds or {}
        local isContain = table.contains(periodChapterIds, self._ActiveChapterId)
        if isContain then
            table.insert(list, template.Id)
        end
    end
    
    self._SingleStoryList = list
    self._CachePeriodId = self._ActiveChapterId
    
    return list
end

-- 获取当前生日剧情的索引
---@return number
function XBirthdayPlotModel:GetIndexByPeriodChapterIds(periodChapterIds)
    local isContain, index = table.contains(periodChapterIds, self._ActiveChapterId)
    return isContain and index or 0
end

---@return XTableSingleStory
function XBirthdayPlotModel:GetSingleStory(storyId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SingleStory, storyId)
end

function XBirthdayPlotModel:GetMaxFavorLevel(storyId)
    return self._MaxFavorLevel[storyId]
end

function XBirthdayPlotModel:SetMaxFavorLevel(storyId, level)
    self._MaxFavorLevel[storyId] = level
end

---@return XTableFavorLevelIcon
function XBirthdayPlotModel:GetFavorLevelConfig(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FavorLevelIcon, level)
end


return XBirthdayPlotModel