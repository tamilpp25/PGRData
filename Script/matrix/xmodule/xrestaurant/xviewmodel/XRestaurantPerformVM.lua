local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

---@class XRestaurantPerformVM : XRestaurantViewModel 演出视图
---@field _OwnControl XRestaurantControl
---@field Data XRestaurantPerformData
---@field Property XRestaurantPerformProperty
local XRestaurantPerformVM = XClass(XRestaurantViewModel, "XRestaurantPerformVM")

local DefaultTimeFormat = "yyyy/MM/dd"
local CsDestroy = CS.UnityEngine.Object.Destroy

---@type table<string, UnityEngine.Texture2D>
local TextureCache

function XRestaurantPerformVM:InitData()
    TextureCache = {}
end

function XRestaurantPerformVM:OnRelease()
    if not XTool.IsTableEmpty(TextureCache) then
        for _, texture in pairs(TextureCache) do
            CsDestroy(texture)
        end
    end
    TextureCache = nil
    XRestaurantViewModel.OnRelease(self)
end

function XRestaurantPerformVM:UpdateViewModel()
    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
end

--- 产品数量发生变化时, 更新任务状态
---@param areaType number 产品区域
---@param productId number 产品Id
---@param characterId number 制作产品的员工Id
---@param count number 当次产品变化数量
---@param isHot number 当前产品是否为热销
--------------------------
function XRestaurantPerformVM:UpdateConditionWhenProductChange(areaType, productId, characterId, count, isHot)
    if self:IsFinish() or self:IsNotStart() then
        return
    end
    local taskIds = self:GetPerformTaskIds()
    local ConditionType = XMVCA.XRestaurant.ConditionType
    for _, taskId in ipairs(taskIds) do
        local taskData = self:GetTaskInfo(taskId)
        local conditions = self:GetConditions(taskId)
        for _, conditionId in pairs(conditions) do
            local conditionType = self._Model:GetConditionType(conditionId)
            local params = self:GetConditionParams(conditionId)
            if conditionType == ConditionType.ProductAdd then
                taskData:UpdateProductAdd(conditionId, params[1], params[3], areaType, productId, characterId, count)
            elseif conditionType == ConditionType.ProductConsume then
                taskData:UpdateProductConsume(conditionId, params[1], params[3], areaType, productId, characterId, count)
            elseif conditionType == ConditionType.HotSaleProductAdd then
                if self._OwnControl:IsCookArea(areaType) then
                    taskData:UpdateHotSaleProductAdd(conditionId, isHot, count)
                end
            elseif conditionType == ConditionType.HotSaleProductConsume then
                if self._OwnControl:IsCookArea(areaType) then
                    taskData:UpdateHotSaleProductConsume(conditionId, isHot, count)
                end
            elseif conditionType == ConditionType.SubmitProduct then
                local total = self._OwnControl:GetProduct(areaType, productId):GetCount()
                taskData:UpdateSubmitProduct(conditionId, params[1], areaType, productId, total)
            end
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_PERFORM_STATE_CHANGE)
end

function XRestaurantPerformVM:SetState(state)
    self.Data:SetState(state)
end

function XRestaurantPerformVM:_IsContainPhoto(taskId)
    local conditionIds = self:GetConditions(taskId)
    for _ , conditionId in ipairs(conditionIds) do
        local conditionType = self._Model:GetConditionType(conditionId)
        if XMVCA.XRestaurant:IsPhotoCondition(conditionType) then
            return true
        end
    end
    return false
end

--演出是否包含拍照任务
function XRestaurantPerformVM:IsContainPhoto(taskId)
    if XTool.IsNumberValid(taskId) then
        return self:_IsContainPhoto(taskId)
    else
        local taskIds = self:GetPerformTaskIds()
        for _, tId in ipairs(taskIds) do
            if self:_IsContainPhoto(tId) then
                return true
            end
        end
        return false
    end
end

function XRestaurantPerformVM:_IsContainIndent(taskId)
    local conditionIds = self:GetConditions(taskId)
    for _ , conditionId in ipairs(conditionIds) do
        local conditionType = self._Model:GetConditionType(conditionId)
        if XMVCA.XRestaurant:IsIndentCondition(conditionType) then
            return true
        end
    end
    return false
end

--是否包含订单类任务
function XRestaurantPerformVM:IsContainIndent(taskId)
    if XTool.IsNumberValid(taskId) then
        return self:_IsContainIndent(taskId)
    else
        local taskIds = self:GetPerformTaskIds()
        for _, tId in ipairs(taskIds) do
            if self:_IsContainIndent(tId) then
                return true
            end
        end
        return false
    end
end

function XRestaurantPerformVM:GetPerformId()
    return self.Data:GetPerformId()
end

function XRestaurantPerformVM:GetTimeStr(format)
    format = format or DefaultTimeFormat
    return XTime.TimestampToGameDateTimeString(self.Data:GetUpdateTime(), format)
end

function XRestaurantPerformVM:IsFinish()
    return self.Data:IsFinish()
end

function XRestaurantPerformVM:IsNotStart()
    return self.Data:IsNotStart()
end

function XRestaurantPerformVM:IsOnGoing()
    return self.Data:IsOnGoing()
end

function XRestaurantPerformVM:GetState()
    return self.Data:GetState()
end

function XRestaurantPerformVM:IsIndent()
    return self:GetPerformType() == XMVCA.XRestaurant.PerformType.Indent
end

function XRestaurantPerformVM:IsPerform()
    return self:GetPerformType() == XMVCA.XRestaurant.PerformType.Perform
end

---@return table<number, number>
function XRestaurantPerformVM:GetStoryInfo()
    return self.Data:GetStoryInfo()
end

function XRestaurantPerformVM:GetPerformTaskIds()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.TaskIds or {}
end

function XRestaurantPerformVM:GetConditions(taskId)
    local template = self._Model:GetPerformTaskTemplate(taskId)
    return template and template.Conditions or {}
end

function XRestaurantPerformVM:GetConditionParams(conditionId)
    return self._Model:GetConditionParams(conditionId)
end

function XRestaurantPerformVM:GetTaskDesc(taskId)
    local template = self._Model:GetPerformTaskTemplate(taskId)
    return template and template.Desc or ""
end

function XRestaurantPerformVM:GetTaskDescWithProgress(taskId)
    local desc = self:GetTaskDesc(taskId)
    local progress = ""
    local conditions = self:GetConditions(taskId)
    local conditionType = XMVCA.XRestaurant.ConditionType
    local taskInfo = self:GetTaskInfo(taskId)
    for _, conditionId in pairs(conditions) do
        local value = taskInfo:GetScheduleValue(conditionId)
        local template = self._Model:GetConditionTemplate(conditionId)
        if template.Type == conditionType.CashierReward then
            progress = string.format("%s (%d/%d)", progress, value, template.Params[1])
        elseif template.Type == conditionType.SectionBuff then
            local count = value > 0 and 1 or 0
            progress = string.format("%s (%d/%d)", progress, count, 1)
        elseif template.Type == conditionType.HotSaleProductAdd 
                or template.Type == conditionType.HotSaleProductConsume then
            progress = string.format("%s (%d/%d)", progress, value, template.Params[1])
        elseif template.Type == conditionType.ProductAdd 
                or template.Type == conditionType.ProductConsume then
            progress = string.format("%s (%d/%d)", progress, value, template.Params[2])
        end
    end
    
    return string.format("%s %s", desc, progress)
end

function XRestaurantPerformVM:GetTaskInfo(taskId)
    return self.Data:GetTaskInfo(taskId)
end

function XRestaurantPerformVM:CheckPerformFinish()
    return self._Model:CheckPerformFinish(self:GetPerformId())
end

function XRestaurantPerformVM:CheckTaskFinsh(taskId)
    return self._Model:CheckPerformTaskFinish(self:GetPerformId(), taskId)
end

function XRestaurantPerformVM:GetPerformType()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.Type or 0
end

function XRestaurantPerformVM:GetPerformTitle()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.Name or ""
end

function XRestaurantPerformVM:GetPerformTitleWithStory()
    local title = self:GetPerformTitle()
    
    return string.format("%s：%s", title, self._Model:GetStoryNote(self:GetPerformStoryId()))
end

function XRestaurantPerformVM:GetPerformRewardId()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.RewardId or 0
end

function XRestaurantPerformVM:GetDescription()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and XUiHelper.ReplaceTextNewLine(template.Desc) or ""
end

function XRestaurantPerformVM:GetPerformIcon()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.Icon or 0
end

function XRestaurantPerformVM:GetPerformSmallIcon()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.SmallIcon or 0
end

function XRestaurantPerformVM:GetPerformTypeIcon()
    return self._Model:GetClientConfigValue("PerformTypeIcon", self:GetPerformType())
end

function XRestaurantPerformVM:GetPerformTypeTitle()
    return self._Model:GetClientConfigValue("PerformTypeTitle", self:GetPerformType())
end

function XRestaurantPerformVM:GetPerformTypeTitleIcon()
    return self._Model:GetClientConfigValue("PerformTypeTitleIocn", self:GetPerformType())
end

function XRestaurantPerformVM:GetUnlockConditions()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.UnlockConditionIds or 0
end

function XRestaurantPerformVM:GetUnlockConditionDesc()
    local conditions = self:GetUnlockConditions()
    for _, conditionId in ipairs(conditions) do
        local result, desc = XConditionManager.CheckCondition(conditionId)
        if not result then
            return desc
        end
    end
    local tip = self._Model:GetClientConfigValue("PerformNotStartText", 1)
    return string.format(tip, self:GetPerformTypeTitle())
end

function XRestaurantPerformVM:GetUnlockText()
    local index = self:GetPerformType()
    local tip = self._Model:GetClientConfigValue("PerformUnlockText", index)
    return string.format(tip, self:GetPerformTitle())
end

function XRestaurantPerformVM:GetPerformStoryId()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.StoryId or 0
end

function XRestaurantPerformVM:GetTalkStoryTalkIds()
    local storyId = self:GetPerformStoryId()
    if not XTool.IsNumberValid(storyId) then
        return {}
    end
    return self._Model:GetTalkStoryTalkIds(storyId)
end

function XRestaurantPerformVM:GetTalkStoryDurations()
    local storyId = self:GetPerformStoryId()
    return self._Model:GetTalkStoryDurations(storyId)
end

function XRestaurantPerformVM:GetIndentNpcName()
    if XMain.IsEditorDebug then
        if not self:IsIndent() then
            XLog.Error("不是订单无法获取NPC Id, 请检查配置")
        end
    end
    local template = self._Model:GetOrderModelTemplate(self:GetPerformId())
    if not template then
        return ""
    end
    return self._Model:GetNpcName(template.NpcId)
end

function XRestaurantPerformVM:GetIndentNpcId()
    if XMain.IsEditorDebug then
        if not self:IsIndent() then
            XLog.Error("不是订单无法获取NPC Id, 请检查配置")
        end
    end
    local template = self._Model:GetOrderModelTemplate(self:GetPerformId())
    return template and template.NpcId or 0
end

function XRestaurantPerformVM:GetIndentTitleText()
    local name = self:GetIndentNpcName()
    return string.format(self._Model:GetClientConfigValue("OrderTitleText", 1), name)
end

function XRestaurantPerformVM:GetIndentFoodInfo()
    return self._Model:GetIndentFoodInfo(self:GetPerformId())
end

function XRestaurantPerformVM:GetIndentNpcReplay()
    local template = self._Model:GetOrderModelTemplate(self:GetPerformId())
    if not template then
        return ""
    end
    return XUiHelper.ReplaceTextNewLine(template.RePlay)
end

--region 拍照

function XRestaurantPerformVM:GetPhotoElementName(eleId)
    local template = self._Model:GetPhotoElementTemplate(eleId)
    return template and template.Name or ""
end

function XRestaurantPerformVM:GetPhotoElementRelativePath(eleId)
    local template = self._Model:GetPhotoElementTemplate(eleId)
    return template and template.RelativePath or ""
end

function XRestaurantPerformVM:GetPhotoElementType(eleId)
    local template = self._Model:GetPhotoElementTemplate(eleId)
    return template and template.Type or ""
end

function XRestaurantPerformVM:GetPhotoElementParams(eleId)
    local template = self._Model:GetPhotoElementTemplate(eleId)
    return template and template.Params or {}
end

function XRestaurantPerformVM:GetPhotoName()
    return self.Data:GetPhotoName()
end

function XRestaurantPerformVM:SetPhotoName(name)
    self.Data:SetPhotoName(name)
end

function XRestaurantPerformVM:GetPhotoTaskFinshTip(taskId)
    local name = self:GetTaskDesc(taskId)
    return string.format(self._Model:GetClientConfigValue("PhotoTaskFinishTip", 1), name)
end

function XRestaurantPerformVM:SetPhotoTexture(func)
    local fileName = self:GetPhotoName()
    if string.IsNilOrEmpty(fileName) then
        func(nil)
        return
    end
    if TextureCache then
        local tex = TextureCache[fileName]
        if tex then
            func(tex)
            return
        end
    end
    CS.XTool.LoadLocalAlbumImg(fileName, function(tex)
        if tex then
            TextureCache[fileName] = tex
        end
        func(tex)
    end)
end

function XRestaurantPerformVM:GetDefaultPhoto()
    local template = self._Model:GetPerformTemplate(self:GetPerformId())
    return template and template.DefaultPhoto or ""
end

--endregion

return XRestaurantPerformVM