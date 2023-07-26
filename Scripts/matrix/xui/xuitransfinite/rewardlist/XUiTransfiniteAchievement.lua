---@class XUiTransfiniteAchievement:XLuaUi
local XUiTransfiniteAchievement = XLuaUiManager.Register(XLuaUi, "UiTransfiniteSuccess")
local XViewModelTransfiniteAchievement = require("XEntity/XTransfinite/ViewModel/XViewModelTransfiniteAchievement")
local XUiTransfiniteRewardGrid = require("XUi/XUiTransfinite/RewardList/XUiTransfiniteRewardGrid")

function XUiTransfiniteAchievement:Ctor()
    ---@type XViewModelTransfiniteAchievement
    self._ViewModel = XViewModelTransfiniteAchievement.New()
    ---@type XUiTransfiniteRewardTitlePanel
    --self._TitlePanel = XUiTransfiniteRewardTitlePanel.New(self)
    self._DynamicTable = nil
    self._FuncRefreshMaskCache = function()
        self:RefreshMaskCache()
    end
end

function XUiTransfiniteAchievement:OnAwake()
    self._TitleText = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Tanchuang01/Text", "Text")
    self._TxtNormalLv = XUiHelper.TryGetComponent(self.TxtNormalLvTitle.transform.parent, "TxtLv", "Text")
    self._DynamicTable = XDynamicTableNormal.New(self.AchievementPanel)
    self._DynamicTable:SetProxy(XUiTransfiniteRewardGrid)
    self._DynamicTable:SetDelegate(self)
    self.RewardPanel.gameObject:SetActiveEx(false)
    self._UiEffectMaskObject = XUiHelper.TryGetComponent(self.AchievementPanel, "", "XUiEffectMaskObject")
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnReceive, self.OnReceiveFinishRewards)
    self:UpdateTitle()
end

function XUiTransfiniteAchievement:OnStart(stageGroup)
    if self._ViewModel and stageGroup then
        self._ViewModel:SetStageGroup(stageGroup)
    end
end

function XUiTransfiniteAchievement:OnEnable()
    self:Refresh()

    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
end

function XUiTransfiniteAchievement:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.Refresh, self)
end

function XUiTransfiniteAchievement:Refresh()
    local achievementDatas, startIndex = self._ViewModel:GetAchievementDataListAndStartIndex()
    self._DynamicTable:SetDataSource(achievementDatas)
    self._DynamicTable:ReloadDataSync(startIndex)
end

function XUiTransfiniteAchievement:OnReceiveFinishRewards()
    local finishTaskIdList = self._ViewModel:GetFinishTaskIdList()
    XDataCenter.TransfiniteManager.RequestFinishMultiTask(finishTaskIdList, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiTransfiniteAchievement:RefreshMaskCache()
    self._UiEffectMaskObject:RefreshCache()
end

---@param grid XUiTransfiniteRewardGrid
function XUiTransfiniteAchievement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, XTransfiniteConfigs.RewardType.AchievementReward)

        local uiLoadEffect1 = XUiHelper.TryGetComponent(grid.EffectNormal, "", "XUiLoadEffect")
        if uiLoadEffect1 then
            uiLoadEffect1:SetLoadedCallback(self._FuncRefreshMaskCache)
        end

        local uiLoadEffect2 = XUiHelper.TryGetComponent(grid.EffectSenior, "", "XUiLoadEffect")
        if uiLoadEffect2 then
            uiLoadEffect2:SetLoadedCallback(self._FuncRefreshMaskCache)
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        grid:SetData(data)
        grid:Refresh()
    end
end

function XUiTransfiniteAchievement:UpdateTitle()
    self._ViewModel:UpdateScoreTitle()
    local data = self._ViewModel:GetDataScoreTitle()
    self.SeniorLock.gameObject:SetActiveEx(not data.SeniorIsUnlock)
    self.TxtNormalLvTitle.text = data.NormalTitle
    self.TxtSeniorLvTitle.text = data.SeniorTitle
    self.ImgNormal:SetRawImage(data.NormalIcon)
    self.ImgSenior:SetRawImage(data.SeniorIconLv)

    if self.TxtSeniorCurrent and self.TxtJuniorCurrent then
        if data.SeniorLvText == false then
            self.TxtSeniorLv.gameObject:SetActiveEx(false)
            self.TxtSeniorCurrent.gameObject:SetActiveEx(true)
        else
            self.TxtSeniorLv.text = data.SeniorLvText
            self.TxtSeniorLv.gameObject:SetActiveEx(true)
            self.TxtSeniorCurrent.gameObject:SetActiveEx(false)
        end
        if data.NormalLvText == false then
            self._TxtNormalLv.gameObject:SetActiveEx(false)
            self.TxtJuniorCurrent.gameObject:SetActiveEx(true)
        else
            self._TxtNormalLv.text = data.NormalLvText
            self._TxtNormalLv.gameObject:SetActiveEx(true)
            self.TxtJuniorCurrent.gameObject:SetActiveEx(false)
        end
    else
        self.TxtSeniorLv.text = data.SeniorLvText
        self._TxtNormalLv.text = data.NormalLvText
    end

    self._TitleText.text = data.Title
end

return XUiTransfiniteAchievement