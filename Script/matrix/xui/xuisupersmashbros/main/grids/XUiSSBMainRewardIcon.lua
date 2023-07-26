
local XUiSSBMainRewardIcon = XClass(nil, "XUiSSBMainRewardIcon")

function XUiSSBMainRewardIcon:Ctor(uiPrefab, onClickCb)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OnClickCb = onClickCb
    self:Init()
end

function XUiSSBMainRewardIcon:Init()
    self:ResetIcon()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, handler(self, self.OnClick))
end

function XUiSSBMainRewardIcon:ResetIcon()
    self:SetIconImage(nil)
    self:SetQualityImage(nil)
    self:SetReceived(false)
    self:SetLock(false)
    self:SetRedPoint(false)
end

function XUiSSBMainRewardIcon:Refresh(mode)
    self.Mode = mode
    self.RewardId = self:GetRewardId()
    if self.RewardId == 0 then
        self:ResetIcon()
        return
    end
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.RewardId)
    self:SetIconImage(self.GoodsShowParams.Icon)
    self:SetQualityImage(self.GoodsShowParams.QualityIcon)
    self:SetLock(not self.Mode:CheckUnlock())
    local isComplete = self.Mode:CheckComplete()
    if not isComplete then
        local canGet, isGet = self.Mode:CheckRewardReceiveStateByLevel(self.Mode:GetFirstCanGetRewardLevel())
        self:SetReceived(isGet)
    else
        self:SetReceived(true)
    end
    self:SetRedPoint(self.achievedTaskCount > 0 )
end

-- function XUiSSBMainRewardIcon:GetRewardId()
--     if not self.Mode then return 0 end
--     local rewardId = self.Mode:GetRewardId()
--     if rewardId and rewardId > 0 then
--         local rewards = XRewardManager.GetRewardList(rewardId)
--         if rewards then
--             for _, v in pairs(rewards) do
--                 return v.TemplateId or v.Id
--             end
--         end
--     end
--     return 0
-- end

-- 外面的奖励图标显示逻辑改为读表 cxldV2
function XUiSSBMainRewardIcon:GetRewardId()
    local resultRewardId = nil
    local itemId = 0
    
    local temp = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.RewardShowConfig)
    local supersmashRewardTaskList = {} --克隆一遍表 防止安卓上readOnly报错
    for k, v in pairs(temp) do
        supersmashRewardTaskList[k] = v
    end

    table.sort(supersmashRewardTaskList, function (a,b)
        return a.Order < b.Order
    end)
  
    local finishTaskList = {} -- 已完成且领取的任务列表
    local achievedTaskList = {} -- 已完成待领取的任务列表
    local unFinishTaskList = {} -- 未完成的任务列表
    for index, value in ipairs(supersmashRewardTaskList) do
        local taskId = value.TaskId
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

        if taskData then
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(achievedTaskList, taskId)
            elseif taskData.State == XDataCenter.TaskManager.TaskState.Finish then
                table.insert(finishTaskList, taskId)
            else
                table.insert(unFinishTaskList, taskId)
            end
        end
    end

    self.hasFinishTaskCount = #finishTaskList
    self.achievedTaskCount = #achievedTaskList
    self.unfinishTaskCount = #unFinishTaskList
    
    --1. 没有可领取奖励的任务，且有待完成条件的任务，显示待完成条件任务里优先级最大的
    --2. 没有可领取奖励的任务，且无待完成条件的任务（就是所有任务都完成且领取完奖励），显示特殊奖励列表里最后一个
    --3. 有可领取奖励的任务，显示可领取奖励任务里优先级最大的
    local taskId = nil -- 最终使用的task
    if self.achievedTaskCount == 0 then
        if self.hasFinishTaskCount < #supersmashRewardTaskList then
            taskId = unFinishTaskList[1]
        elseif self.hasFinishTaskCount == #supersmashRewardTaskList then
            taskId = supersmashRewardTaskList[#supersmashRewardTaskList].TaskId
        end
    elseif self.achievedTaskCount > 0 then
        taskId = achievedTaskList[self.achievedTaskCount]
    end

    -- 拿到需要展示的任务的奖励列表
    if taskId then
        local template = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        resultRewardId = template.RewardId
    end

    -- 从奖励列表拿到第一个物品id
    if resultRewardId and resultRewardId > 0 then
        local rewards = XRewardManager.GetRewardList(resultRewardId)
        if rewards and next(rewards) then
            itemId = rewards[1].TemplateId or rewards[1].Id
        end
    end

    return itemId
end

function XUiSSBMainRewardIcon:SetIconImage(imagePath)
    self.RImgIcon.gameObject:SetActiveEx(imagePath ~= nil)
    if not imagePath then return end
    self.RImgIcon:SetRawImage(imagePath)
end

function XUiSSBMainRewardIcon:SetQualityImage(quality)
    self.ImgQuality.gameObject:SetActiveEx(quality ~= nil)
    if not quality then return end
    self.ImgQuality:SetSprite(quality)
end

function XUiSSBMainRewardIcon:SetReceived(isReceived)
    self.IsReceived = isReceived
    self.ReceivedPanel.gameObject:SetActiveEx(isReceived)
end

function XUiSSBMainRewardIcon:SetLock(isLocked)
    self.IsLocked = isLocked
    self.Lock.gameObject:SetActiveEx(isLocked)
end

function XUiSSBMainRewardIcon:SetRedPoint(isShowRedPoint)
    self.CanGet = isShowRedPoint
    self.Red.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiSSBMainRewardIcon:OnClick()
    if self.OnClickCb then
        self.OnClickCb()
    end
    --[[
    if (not self.RewardId) or (self.RewardId == 0) then

        return
    elseif self.IsReceived then
        XLuaUiManager.Open("UiTip", self.RewardId)
        return
    elseif self.IsLocked then
        XLuaUiManager.Open("UiTip", self.RewardId)
        return
    elseif self.CanGet then
        XDataCenter.SuperSmashBrosManager.TakeScoreReward(self.Mode:GetFirstRewardCfgNotGet(), function(resultList)
                XUiManager.OpenUiObtain(resultList, nil, self.OnClickCb)
            end)
    else
        XLuaUiManager.Open("UiTip", self.RewardId)
        if self.OnClickCb then
            self.OnClickCb()
        end
    end
    ]]
end

return XUiSSBMainRewardIcon