local XUiGridSimulationChallenge = XClass(nil, "XUiGridSimulationChallenge")
local IsThisTransformPlayAnim = false

function XUiGridSimulationChallenge:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridList = {}
    self:SetHasPlay(false)
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridSimulationChallenge:InitAutoScript()
    self:AutoAddListener()
end

function XUiGridSimulationChallenge:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridSimulationChallenge:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridSimulationChallenge:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridSimulationChallenge:AutoAddListener()
end

function XUiGridSimulationChallenge:PlayEnableAnime(index)
    if self:GetHasPlay() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local rect = self.UseGrid:GetComponent("RectTransform")
    local beforePlayPosY = rect.anchoredPosition.y
    local canvasGroup = self.Transform:Find("Grid"):GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    XScheduleManager.ScheduleOnce(function() 
        if not XTool.UObjIsNil(self.Transform) and self.GameObject.activeInHierarchy then
            self.Transform:Find("Animation/GridEnable"):PlayTimelineAnimation(function ()
                canvasGroup.alpha = 1
                rect.anchoredPosition = Vector2(rect.anchoredPosition.x, beforePlayPosY) -- 播放完的回调也强设一遍目标值
            end)
            self:SetHasPlay(true)
        end 
    end, (index - 1) * 95)
end

function XUiGridSimulationChallenge:SetHasPlay(flag)
    IsThisTransformPlayAnim = flag
end

function XUiGridSimulationChallenge:GetHasPlay()
    return IsThisTransformPlayAnim
end

-- auto
function XUiGridSimulationChallenge:UpdateGrid(manager, index, currUseMinIndex)
    currUseMinIndex = currUseMinIndex or 1
    self:PlayEnableAnime(index - (currUseMinIndex - 1))
    self.Manager = manager
    self.TxtProgress.text = manager:ExGetProgressTip()
    self.TxtName.text = manager:ExGetName()
    self.RImgChallenge:SetRawImage(manager:ExGetIcon())
    
    -- 时间
    self:RemoveTimer()
    self.TxtTime.text = manager:ExGetRunningTimeStr()   -- 先显示一遍 因为倒计时太慢了
    self.Timer = XScheduleManager.ScheduleForever(function()
        self.TxtTime.text = manager:ExGetRunningTimeStr()
    end, XScheduleManager.SECOND, 0)

    -- 奖励
    local rewardId = manager:ExGetRewardId()
    if rewardId ~= self.RewardId then
        self.RewardId = rewardId

        -- 先把上一个占用这个格子的数据给清除
        for k, grid in pairs(self.GridList) do
            grid.GameObject:SetActive(false)
        end 

        local rewards = {}
        if rewardId > 0 then
            rewards = XRewardManager.GetRewardList(rewardId) 
        end
    
        if rewards then
            for i, item in ipairs(rewards) do
                local grid
                if self.GridList[i] then
                    grid = self.GridList[i]
                else
                    local ui = self.PanelReward:Find("Reward"..i)
                    grid = XUiGridCommon.New(nil, ui)
                    grid.Transform:SetParent(self.GridCommon.parent, false)
                    self.GridList[i] = grid
                end
                grid:Refresh(item)
                grid.GameObject:SetActive(true)
            end
        end
    end

    self:RefreshRedPoint()
    
    local locked = manager:ExGetIsLocked()
    self.PanelLock.gameObject:SetActiveEx(locked)
    self.BtnDownload.gameObject:SetActiveEx(false)
    self.TxtLock.text = manager:ExGetLockTip()
    self.TxtLock.gameObject:SetActiveEx(locked)
    
end

function XUiGridSimulationChallenge:RefreshRedPoint()
    self.ImgRedPoint.gameObject:SetActiveEx(self.Manager:ExCheckIsShowRedPoint())
end

function XUiGridSimulationChallenge:RefreshProgress()
    self.TxtProgress.text = self.Manager:ExGetProgressTip()
end

function XUiGridSimulationChallenge:OnDestroy()
    self:RemoveTimer()
end

function XUiGridSimulationChallenge:RemoveTimer()
    if not self.Timer then return end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiGridSimulationChallenge:OnClickSelf()
    local chapterType
    if type(self.Manager.ExChapterType) == "number" then
        chapterType = self.Manager.ExChapterType
    elseif self.Manager.ExGetChapterType and type(self.Manager.ExGetChapterType) == "function" then
        chapterType = self.Manager:ExGetChapterType()
    end
    if not XMVCA.XSubPackage:CheckSubpackage(chapterType) then
        return
    end
    self.Manager:ExOpenMainUi()
end

return XUiGridSimulationChallenge