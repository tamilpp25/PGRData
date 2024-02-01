---@class XUiTransfiniteChallengeReward
local XUiTransfiniteChallengeReward = XClass(nil, "XUiTransfiniteChallengeReward")

function XUiTransfiniteChallengeReward:Ctor(rootUi, uiPrefab, viewModel)
    XTool.InitUiObjectByUi(self, uiPrefab)

    self._RootUi = rootUi
    ---@type XViewModelTransfiniteGift
    self._ViewModel = viewModel
    self._DynamicTable = XDynamicTableNormal.New(self.ChallengeListPanel)
    self._DynamicTable:SetProxy(XDynamicGridTask, self._RootUi)
    self._DynamicTable:SetDelegate(self)
    self.TaskGrid.gameObject:SetActiveEx(false)
end

function XUiTransfiniteChallengeReward:Update()
    local challengeDatas = self._ViewModel:GetChallengeDataList()

    if not challengeDatas or #challengeDatas == 0 then
        self.ChallengeTaskEmpty.gameObject:SetActiveEx(true)
        self.ChallengeListPanel.gameObject:SetActiveEx(false)
    else
        self._DynamicTable:SetDataSource(challengeDatas)
        self._DynamicTable:ReloadDataSync()
    end
end

function XUiTransfiniteChallengeReward:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

function XUiTransfiniteChallengeReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self._DynamicTable:GetData(index)
        grid:ResetData(taskData)
    end
end

return XUiTransfiniteChallengeReward
