---管理右边‘仓库’技能列表的类
---@class XUiPanelLinkCraftActivityList
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkCraftActivityList = XClass(XUiNode, 'XUiPanelLinkCraftActivityList')
local XUiGridLinkCraftActivitySkillDetail = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityEdit/XUiGridLinkCraftActivitySkillDetail')

function XUiPanelLinkCraftActivityList:OnStart(linkId)
    --初始化技能UI的对象池
    self.GridSkill.gameObject:SetActiveEx(false)
    self._SkillGridPool = XObjectPool.New(function() 
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridSkill,self.ScrollList.content)
        local ctrl = XUiGridLinkCraftActivitySkillDetail.New(obj, self)
        
        return ctrl
    end)
    self._SkillGridUsingQueue = XQueue.New()
    
    self:Refresh(linkId, true)
end

function XUiPanelLinkCraftActivityList:OnDisable()
    if self._SkillGridDisplayTimeId then
        XScheduleManager.UnSchedule(self._SkillGridDisplayTimeId)
        self._SkillGridDisplayTimeId = nil
    end
end

function XUiPanelLinkCraftActivityList:Refresh(linkId, playAnimation)
    if self._IsRefreshing then
        return
    end
    self._IsRefreshing = true
    self._LinkId = linkId or self._LinkId
    
    if self._SkillGridDisplayTimeId then
        XScheduleManager.UnSchedule(self._SkillGridDisplayTimeId)
        self._SkillGridDisplayTimeId = nil
    end
    
    --回收技能UI
    while self._SkillGridUsingQueue:Count() > 0 do
        local grid = self._SkillGridUsingQueue:Dequeue()
        grid:Close()
        self._SkillGridPool:Recycle(grid)
    end
    
    local skillList = self._Control:GetLinkSkillListById(self._LinkId)
    if not XTool.IsTableEmpty(skillList) then
        local index = 1
        local skillListLength = #skillList
        --刷新技能UI
        if playAnimation then
            -- 每个格子初始化后间隔0.1s播放显示动画
            self._SkillGridDisplayTimeId = XScheduleManager.Schedule(function()
                local grid = self._SkillGridPool:Create()
                self._SkillGridUsingQueue:Enqueue(grid)
                grid.Transform:SetAsLastSibling()
                grid:Open()
                grid:SetSkillId(skillList[index])

                --克隆出来的UI使用索引区分用于引导定位
                grid.GameObject.name = 'GridLinkSkill'..index
                index = index + 1

                if index > skillListLength then
                    self._IsRefreshing = false
                end
            end, 0.1*XScheduleManager.SECOND, skillListLength)
        else
            
            for i, v in ipairs(skillList) do
                local grid = self._SkillGridPool:Create()
                self._SkillGridUsingQueue:Enqueue(grid)
                grid.Transform:SetAsLastSibling()
                grid:Open()
                grid:SetSkillId(v)

                --克隆出来的UI使用索引区分用于引导定位
                grid.GameObject.name = 'GridLinkSkill'..index
                index = index + 1
            end
            self._IsRefreshing = false
        end
        
    end
end

function XUiPanelLinkCraftActivityList:RefreshLinkSkill()
    self.Parent._PanelLink:Refresh()
end

return XUiPanelLinkCraftActivityList