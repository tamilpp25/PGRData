local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--部分光辉同行UI界面左下角的 任务迷你UI
local XUIBrilliantWalkMiniTaskPanel = XClass(nil, "XUIBrilliantWalkMiniTaskPanel")


function XUIBrilliantWalkMiniTaskPanel:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    
    --Grid的内存池
    self.GridPool = XStack.New() --奖励Grid内存池
    self.GridList = XStack.New() --正在使用的奖励Grid
    self.GridCommon.gameObject:SetActiveEx(false) --隐藏template
    self.BtnTask.CallBack =  function()
        self.RootUi:OnBtnTaskClick()
    end
end

function XUIBrilliantWalkMiniTaskPanel:OnEnable()
    self.RedPointID = XRedPointManager.AddRedPointEvent(self.BtnTask.ReddotObj, nil, self,{ XRedPointConditions.Types.CONDITION_BRILLIANTWALK_REWARD }, -1)
end

function XUIBrilliantWalkMiniTaskPanel:OnDisable()
    XRedPointManager.RemoveRedPointEvent(self.RedPointID)
end

--刷新界面
function XUIBrilliantWalkMiniTaskPanel:UpdateView(refreshGrid)
    local taskViweData = XDataCenter.BrilliantWalkManager.GetUIDataMiniTask()
    self.BtnTask:SetNameByGroup(1, taskViweData.TaskRewardProgress)
    self.BtnTask:SetNameByGroup(2, "/" .. taskViweData.MaxTaskRewardProgress)
    self:GridReturnPool()
    if refreshGrid then
        for _,itemData in pairs (taskViweData.TaskItemList) do
            local grid = self:GetGrid()
            grid:Refresh(itemData)
            grid.TxtCount.text = itemData.GetNum .. "/" .. itemData.TotleNum
            grid:SetUiActive(grid.TxtCount, true)
        end
    end
end

--提取奖励Grid
function XUIBrilliantWalkMiniTaskPanel:GetGrid()
    local item
    if self.GridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridCommon)
        object.transform:SetParent(self.Content, false)
        item = XUiGridCommon.New(object)
    else
        item = self.GridPool:Pop()
    end
    item.GameObject:SetActiveEx(true)
    self.GridList:Push(item)
    return item
end
--放回必杀模块Grid
function XUIBrilliantWalkMiniTaskPanel:GridReturnPool()
    while (not self.GridList:IsEmpty()) do
        local object = self.GridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.GridPool:Push(object)
    end
end

return XUIBrilliantWalkMiniTaskPanel