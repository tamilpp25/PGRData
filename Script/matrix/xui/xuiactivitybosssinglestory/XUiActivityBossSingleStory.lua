local XUiActivityBossSingleStory=XLuaUiManager.Register(XLuaUi,"UiActivityBossSingleStory")
local XUiBossSingleStoryGrid=require("XUi/XUiActivityBossSingleStory/XUiBossSingleStoryGrid")

---定义最大索引值，以支持不定长的数量
local maxIndex=100

--region 生命周期
function XUiActivityBossSingleStory:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiActivityBossSingleStory:OnStart()
    self:RefreshStoryGird()
end

--endregion

--region 初始化
function XUiActivityBossSingleStory:InitUi()
    self.StoryGrids={}
    local curSectionId=XDataCenter.FubenActivityBossSingleManager.GetCurSectionId()
    local count=XFubenActivityBossSingleConfigs.GetStoryCount(curSectionId)
    --先隐藏所有按钮
    for i=1,maxIndex,1 do
        if self["GridStory"..i] then
            self["GridStory"..i].gameObject:SetActiveEx(false)
        else
            break
        end
    end
    --显示并设置控制器
    for i=1,count,1 do
        if self["GridStory"..i] then
            self["GridStory"..i].gameObject:SetActiveEx(true)
            self.StoryGrids[i]=XUiBossSingleStoryGrid.New(self["GridStory"..i],self)
        end
    end
end

function XUiActivityBossSingleStory:InitCb()
    self.BtnBack.CallBack=function()
        self:Close() 
    end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
end
--endregion

--region 数据更新
function XUiActivityBossSingleStory:RefreshStoryGird()
    local curSectionId=XDataCenter.FubenActivityBossSingleManager.GetCurSectionId()
    local storyIds=XFubenActivityBossSingleConfigs.GetStoryIds(curSectionId)
    for i, grid in ipairs(self.StoryGrids) do
        if storyIds[i] then
            grid:Refresh(i,storyIds[i])
        end
    end
end

--endregion

--region 事件响应

--endregion

return XUiActivityBossSingleStory