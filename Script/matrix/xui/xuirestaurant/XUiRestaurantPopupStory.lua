local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiGridPerformTask : XUiNode
---@field _Control XRestaurantControl
local XUiGridPerformTask = XClass(XUiNode, "XUiGridPerformTask")

local ColorStr = {
    Enough = "#FFFFFF",
    NotEnough = "#FB7272"
}

function XUiGridPerformTask:OnStart(performId)
    self.PerformId = performId
    self.GridFood.gameObject:SetActiveEx(false)
    self.GridDesc.gameObject:SetActiveEx(false)
    self.GridFoods = {}
    self.GridDescList = {}
end

function XUiGridPerformTask:Refresh(taskIds)
    local perform = self._Control:GetPerform(self.PerformId)
    local isOrderType = perform:IsContainIndent()
    self.Type1.gameObject:SetActiveEx(not isOrderType)
    self.Type2.gameObject:SetActiveEx(isOrderType)

    if isOrderType then
        self:RefreshFood(taskIds)
    else
        self:RefreshText(taskIds)
    end
end

function XUiGridPerformTask:RefreshText(taskIds)
    if XTool.IsTableEmpty(taskIds) then
        return
    end
    for index, taskId in ipairs(taskIds) do
        local grid = self.GridDescList[index]
        if not grid then
            local ui = index == 1 and self.GridDesc or XUiHelper.Instantiate(self.GridDesc, self.Type1)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridDescList[index] = grid
            ui.gameObject:SetActiveEx(true)
        end
        self:RefreshDescGrid(grid, taskId)
    end
end

function XUiGridPerformTask:RefreshFood(taskIds)
    local perform = self._Control:GetPerform(self.PerformId)
    local schedule = {}
    for _, taskId in ipairs(taskIds) do
        local taskInfo = perform:GetTaskInfo(taskId)
        local dict = taskInfo:GetSchedules()
        for conditionId, value in pairs(dict) do
            schedule[conditionId] = value
        end
    end
    
    if XTool.IsTableEmpty(schedule) then
        return
    end
    local index = 1
    for conditionId, value in pairs(schedule) do
        local params = perform:GetConditionParams(conditionId)
        local grid = self.GridFoods[index]
        if not grid then
            local ui = index == 1 and self.GridFood or XUiHelper.Instantiate(self.GridFood, self.Type2)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridFoods[index] = grid
            ui.gameObject:SetActiveEx(true)
        end
        self:RefreshFoodGrid(grid, params[1], params[2], value)
        index = index + 1
    end
end

function XUiGridPerformTask:RefreshFoodGrid(grid, paramId, target, value)
    if not grid then
        return
    end
    local areaType = math.floor(paramId / 10000)
    local foodId = paramId % 10000
    local food = self._Control:GetProduct(areaType, foodId)
    grid.TxtName.text = food:GetName()
    local colorStr = target > value and ColorStr.NotEnough or ColorStr.Enough
    grid.TxtNeed.text = string.format("<color=%s>%d</color>/%d", colorStr, value, target)
    grid.RImgFood:SetRawImage(food:GetProductIcon())
    grid.ImgQuality:SetSprite(food:GetQualityIcon(false))
end

function XUiGridPerformTask:RefreshDescGrid(grid, taskId)
    if not grid then
        return
    end
    local perform = self._Control:GetPerform(self.PerformId)
    grid.TxtTask.text = perform:GetTaskDescWithProgress(taskId)
    grid.ImgComplete.gameObject:SetActiveEx(perform:CheckTaskFinsh(taskId))
end


---@class XUiRestaurantPopupStory : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantPopupStory = XLuaUiManager.Register(XLuaUi, "UiRestaurantPopupStory")

local XUiGridMessage = require("XUi/XUiRestaurant/XUiGrid/XUiGridMessage")

function XUiRestaurantPopupStory:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantPopupStory:InitUi()
    self.GridChats = {}
    self.GridChat.gameObject:SetActiveEx(false)
    self.GridFoods.gameObject:SetActiveEx(false)
    self.GridRewards = {}
end

function XUiRestaurantPopupStory:InitCb()
    local close = function() 
        self:Close()
    end
    
    self.BtnClose.CallBack = close
    self.BtnWndClose.CallBack = close
    
    self.BtnPost.CallBack = function() 
        self:OnBtnPostClick()
    end
end

function XUiRestaurantPopupStory:OnBtnPostClick()
    self._Control:RequestFinishPerform(self.PerformanceId, function() 
        self:Close()
    end)
end

function XUiRestaurantPopupStory:OnStart(performanceId)
    self.PerformanceId = performanceId
    
    self:RefreshView()
end

function XUiRestaurantPopupStory:RefreshView()
    local perform = self._Control:GetPerform(self.PerformanceId)
    self.Record = perform:GetStoryInfo()
    if self.TxtChatTitle and self.TxtChatTitle.gameObject.activeInHierarchy then
        self.TxtChatTitle.text = perform:GetPerformTitleWithStory()
    end

    if self.RImgTitle and self.RImgTitle.gameObject.activeInHierarchy then
        self.TxtChatTitle.text = perform:GetPerformTypeTitleIcon()
    end
    self.TxtTitle.text = perform:GetPerformTypeTitle()

    self:SetupChatDynamicTable()
    local isFinished = perform:IsFinish()
    self.PanelTask.gameObject:SetActiveEx(not isFinished)
    local isShowPhoto = isFinished
    self.PanelPhoto.gameObject:SetActiveEx(isShowPhoto)
    self.PanelMessage.gameObject:SetActiveEx(isFinished)
    self.PanelReward.gameObject:SetActiveEx(not isFinished)
    self.BtnPost.gameObject:SetActiveEx(not isFinished)
    if isFinished then
        self:RefreshIndent()
        self:RefreshPhoto()
    else
        --已完成，但是还未领取
        local isUnclaimed = self._Control:CheckPerformFinish(self.PerformanceId)
        self.BtnPost:SetDisable(not isUnclaimed, isUnclaimed)
        self:RefreshDemand()
    end
    self:RefreshReward()
end

--任务需求
function XUiRestaurantPopupStory:RefreshDemand()
    local perform = self._Control:GetPerform(self.PerformanceId)
    local taskIds = perform:GetPerformTaskIds()
    if not self.GridTaskUi then
        self.GridTaskUi = XUiGridPerformTask.New(self.GridTask, self, self.PerformanceId)
    end
    self.GridTaskUi:Refresh(taskIds)
end

--任务奖励
function XUiRestaurantPopupStory:RefreshReward()
    local perform = self._Control:GetPerform(self.PerformanceId)
    local rewardId = perform:GetPerformRewardId()
    local rewardList = XRewardManager.GetRewardList(rewardId)
    for idx, reward in ipairs(rewardList) do
        local grid = self.GridRewards[idx]
        if not grid then
            local ui = idx == 1 and self.Grid256 or XUiHelper.Instantiate(self.Grid256, self.ListReward)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewards[idx] = grid
        end
        grid:Refresh(reward)
    end
end

function XUiRestaurantPopupStory:RefreshPhoto()
    local perform = self._Control:GetPerform(self.PerformanceId)
    self.TxtPhotoTime.text = perform:GetTimeStr("yyyy.MM.dd")
    self.RImgPhoto:SetRawImage(perform:GetDefaultPhoto())
    --perform:SetPhotoTexture(function(tex)
    --    if not tex then
    --        self.RImgPhoto:SetRawImage(perform:GetDefaultPhoto())
    --    else
    --        self.RImgPhoto.texture = tex
    --    end
    --end)
end

function XUiRestaurantPopupStory:RefreshIndent()
    local perform = self._Control:GetPerform(self.PerformanceId)
    self.TxtMsgTime.text = perform:GetTimeStr()
    self.ImgRole:SetRawImage(perform:GetPerformSmallIcon())
    self.TxtMessage.text = perform:GetDescription()
end

function XUiRestaurantPopupStory:SetupChatDynamicTable()
    local perform = self._Control:GetPerform(self.PerformanceId)
    self.DataList = perform:GetTalkStoryTalkIds()
    
    for index, taskId in ipairs(self.DataList) do
        local grid = self.GridChats[index]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridChat, self.Content)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridMessage.New(ui, self)
            self.GridChats[index] = grid
        end
        grid:Refresh(taskId, index)
    end
end

function XUiRestaurantPopupStory:GetTalkMessage(talkId)
    local business = self._Control:GetBusiness()
    local template = business:GetTalkTemplate(talkId)
    if template.Type == XMVCA.XRestaurant.MessageType.Auto then
        return template.Reply
    end
    local index = self.Record[talkId]
    return template.Answers[index]
end