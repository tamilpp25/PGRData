local XBigWorldTeachConfigModel = require("XModule/XBigWorldTeach/XBigWorldTeachConfigModel")

---@class XBigWorldTeachModel : XBigWorldTeachConfigModel
local XBigWorldTeachModel = XClass(XBigWorldTeachConfigModel, "XBigWorldTeachModel")
function XBigWorldTeachModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()

    self._TeachContentMap = false
    self._TeachTypeMap = false

    ---@type XQueue
    self._TeachUnlockQueue = XQueue.New()

    self._TeachLatestList = {}
    self._TeachUnlockServerDatas = {}
    self._TeachUnlockServerDataMap = {}
end

function XBigWorldTeachModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldTeachModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._TeachContentMap = false
    self._TeachTypeMap = false

    self._TeachUnlockQueue:Clear()

    self._TeachLatestList = {}
    self._TeachUnlockServerDatas = {}
    self._TeachUnlockServerDataMap = {}
end

function XBigWorldTeachModel:GetTeachContentMap()
    if not self._TeachContentMap then
        local teachConfigs = self:GetBigWorldHelpCourseConfigs()
        local contentConfigs = self:GetBigWorldHelpCourseDetailConfigs()

        self._TeachContentMap = {}
        for id, config in pairs(contentConfigs) do
            local teachConfig = teachConfigs[config.HelpCourseId]

            if teachConfig then
                if self._TeachContentMap[teachConfig.Id] == nil then
                    self._TeachContentMap[teachConfig.Id] = {}
                end

                table.insert(self._TeachContentMap[teachConfig.Id], config)
            end
        end
        for _, teachContents in pairs(self._TeachContentMap) do
            table.sort(teachContents, function(contentA, contentB)
                return contentA.Priority > contentB.Priority
            end)
        end
    end

    return self._TeachContentMap
end

function XBigWorldTeachModel:GetTeachTypeMap()
    if not self._TeachTypeMap then
        local teachConfigs = self:GetBigWorldHelpCourseConfigs()
        local teachGroupConfigs = self:GetBigWorldHelpCourseGroupConfigs()

        self._TeachTypeMap = {}
        for id, config in pairs(teachConfigs) do
            local teachGroupConfig = teachGroupConfigs[config.GroupId]

            if teachGroupConfig then
                if self._TeachTypeMap[teachGroupConfig.Id] == nil then
                    self._TeachTypeMap[teachGroupConfig.Id] = {}
                end

                table.insert(self._TeachTypeMap[teachGroupConfig.Id], config)
            end
        end
    end

    return self._TeachTypeMap
end

---@return XTableBigWorldHelpCourseDetail
function XBigWorldTeachModel:GetTeachContentByTeachIdAndIndex(teachId, index)
    local teachContents = self:GetTeachContentsByTeachId(teachId)

    if not XTool.IsTableEmpty(teachContents) then
        return teachContents[index]
    end

    return nil
end

---@return XTableBigWorldHelpCourseDetail[]
function XBigWorldTeachModel:GetTeachContentsByTeachId(teachId)
    local teachContentMap = self:GetTeachContentMap()

    if teachContentMap[teachId] then
        return teachContentMap[teachId]
    end

    return nil
end

---@return XTableBigWorldHelpCourse[]
function XBigWorldTeachModel:GetTeachsByGroupId(groupId)
    local teachMap = self:GetTeachTypeMap()

    if teachMap[groupId] then
        return teachMap[groupId]
    end

    return nil
end

function XBigWorldTeachModel:GetTeachUnlockTime(teachId)
    if self:CheckTeachIsUnlock(teachId) then
        return self._TeachUnlockServerDataMap[teachId].CreateTime
    end

    return 0
end

function XBigWorldTeachModel:GetTeachLatestList()
    return self._TeachLatestList
end

function XBigWorldTeachModel:GetTeachUnlockServerDatas()
    return self._TeachUnlockServerDatas
end

function XBigWorldTeachModel:GetTeachLatestValue()
    return 10
end

function XBigWorldTeachModel:CheckTeachIsUnlock(teachId)
    if not XTool.IsNumberValid(teachId) then
        return false
    end

    return self._TeachUnlockServerDataMap[teachId] ~= nil
end

function XBigWorldTeachModel:CheckTeachIsRead(teachId)
    if not XTool.IsNumberValid(teachId) then
        return false
    end

    if not self:CheckTeachIsUnlock(teachId) then
        return false
    end

    return self._TeachUnlockServerDataMap[teachId].IsRead or false
end

function XBigWorldTeachModel:UpdateTeachUnlockServerData(teachList)
    local latestCount = self:GetTeachLatestValue()

    self._TeachLatestList = {}
    self._TeachUnlockServerDatas = {}
    self._TeachUnlockServerDataMap = {}
    if not XTool.IsTableEmpty(teachList) then
        local count = table.nums(teachList)

        for i = count, 1, -1 do
            if latestCount >= count - i + 1 then
                table.insert(self._TeachLatestList, teachList[i])
            end

            self._TeachUnlockServerDataMap[teachList[i].Id] = teachList[i]
            table.insert(self._TeachUnlockServerDatas, teachList[i])
        end
    end
end

function XBigWorldTeachModel:UpdateTeachDataRead(teachId)
    if self:CheckTeachIsUnlock(teachId) then
        self._TeachUnlockServerDataMap[teachId].IsRead = true
    end
end

function XBigWorldTeachModel:AddTeachUnlockServerData(teachData)
    if teachData then
        local serverData = self._TeachUnlockServerDataMap[teachData.Id]
        local latestCount = self:GetTeachLatestValue()

        if serverData then
            local createTime = serverData.CreateTime

            serverData.IsRead = teachData.IsRead
            if createTime ~= teachData.CreateTime then
                serverData.CreateTime = createTime
                self._TeachLatestList = {}
                table.sort(self._TeachUnlockServerDatas, function(teachA, teachB)
                    return teachA.CreateTime > teachB.CreateTime
                end)
                for i = 1, table.nums(self._TeachUnlockServerDatas) do
                    if i <= latestCount then
                        table.insert(self._TeachLatestList, self._TeachUnlockServerDatas[i])
                    end
                end
            end
        else
            self._TeachUnlockServerDataMap[teachData.Id] = teachData
            table.insert(self._TeachUnlockServerDatas, 1, teachData)
            table.insert(self._TeachLatestList, 1, teachData)

            for i = latestCount + 1, table.nums(self._TeachLatestList) do
                self._TeachLatestList[i] = nil
            end
        end

        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_UNLOCK, teachData.Id)
    end
end

function XBigWorldTeachModel:AddTeachQueue(teachData)
    if teachData then
        self._TeachUnlockQueue:Enqueue(teachData)
    end
end

function XBigWorldTeachModel:GetTeachFromQueue()
    if not self._TeachUnlockQueue:IsEmpty() then
        return self._TeachUnlockQueue:Dequeue()
    end

    return nil
end

return XBigWorldTeachModel
