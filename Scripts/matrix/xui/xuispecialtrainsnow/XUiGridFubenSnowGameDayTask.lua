---@class XUiGridFubenSnowGameDayTask
---@field Parent XUiFubenSnowGame
local XUiGridFubenSnowGameDayTask = XClass(nil, "XUiGridFubenSnowGameDayTask")

function XUiGridFubenSnowGameDayTask:Refresh(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Id = data.Id
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    -- 描述
    self.TxtDesc.text = config.Desc
    -- 显示进度
    if #config.Condition < 2 then
        self.ImgProgress.gameObject:SetActiveEx(true)
        self.TxtNumber.gameObject:SetActiveEx(true)
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtNumber.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgress.gameObject:SetActiveEx(false)
        self.TxtNumber.gameObject:SetActiveEx(false)
    end
    -- 奖励积分
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    if not rewards then
        return
    end
    local count = rewards[1] and rewards[1].Count
    self.TxtStar.text = count
end

function XUiGridFubenSnowGameDayTask:GetId()
    return self.Id
end

function XUiGridFubenSnowGameDayTask:PlayEffectAnimation(target, pathAnimTime)
    self.Effect.gameObject:SetActiveEx(true)
    self.EffectTimer = XUiHelper.DoWorldMove(self.Effect.transform, target, pathAnimTime, XUiHelper.EaseType.Sin, function()
        if XTool.UObjIsNil(self.Effect) then
            return
        end
        self.EffectTimer = nil
        self.Effect.gameObject:SetActiveEx(false)
    end)
end

return XUiGridFubenSnowGameDayTask