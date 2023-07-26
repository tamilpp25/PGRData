local XUiPanelTrialGrid = XClass(nil, "XUiPanelTrialGrid")

function XUiPanelTrialGrid:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.RewardPanelList = {}
    XTool.InitUiObject(self)
    self:InitUiAfterAuto()
    XEventManager.AddEventListener(XEventId.EVENT_TRIAL_LEVEL_FINISH, self.OnSettleTrial, self)
end

function XUiPanelTrialGrid:InitUiAfterAuto()
end

function XUiPanelTrialGrid:Init(uiRoot, parent)
    self.UiRoot = uiRoot
    self.Parent = parent
    self:CloseFx()
end
-- 更新数据
function XUiPanelTrialGrid:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    -- 设Icon
    local iconpath = self.ItemData.Picture
    self.UiRoot:SetUiSprite(self.ImgIcon, iconpath)

    -- 设置状态
    self:SetTrialItemState()

    if self.IsNotFirstFx then
        self:SetTrialItemRewardFx()
    else
        self.IsNotFirstFx = true
    end
    -- 设置名字
    self.TxtNameB.text = itemData.Name

    -- 推荐等级
    local stagecfg = XDataCenter.FubenManager.GetStageCfg(itemData.StageId)
    local level = stagecfg.RecommandLevel or 1
    self.TxtLevel.text = CS.XTextManager.GetText("RecommendLevelDesc", level)

    -- 解锁条件
    if itemData.ConditionExplain then
        local conditiontext = ""
        for _, v in ipairs(itemData.ConditionExplain) do
            conditiontext = conditiontext .. v .. "\n"
        end
        self.TxtLock.text = conditiontext
    end

    -- 设置奖励
    self:SetReward(itemData)
end

function XUiPanelTrialGrid:SetReward(itemData)
    local rewards = XRewardManager.GetRewardList(itemData.RewardId)
    self.RewardListData = rewards
    local rewardCount = #rewards

    for i = 1, rewardCount do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.PanelReward)
            ui.transform:SetParent(self.UiContent, false)
            ui.gameObject:SetActive(true)
            ui.gameObject.name = string.format("PanelReward%d", i)
            panel = XUiGridCommon.New(self.UiRoot, ui)
            table.insert(self.RewardPanelList, i, panel)
        end
    end

    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i].GameObject:SetActive(i <= rewardCount)
        if i <= rewardCount then
            self.RewardPanelList[i]:Refresh(rewards[i])
        end
    end
end

-- 通关改状态
function XUiPanelTrialGrid:OnSettleTrial(res)
    if res then
        if self.ItemData then
            local StageId = res
            if self.ItemData.StageId == StageId then
                XDataCenter.TrialManager.TrialLevelPassState(self.ItemData.Id)
                self:SetTrialItemState()
            end
        end
    end
end

-- 奖励领取后改进度
function XUiPanelTrialGrid:AfterRewardGetedPro(cb)
    local prolen = XTrialConfigs.GetForTotalLength()
    if self.ItemData.Id > prolen then
        local index = self.ItemData.Id - prolen
        self.Parent:SetTypeTrialSignlePro(index, cb)
    else
        self.Parent:SetTypeTrialSignlePro(self.ItemData.Id, cb)
    end
end

-- 设置状态
function XUiPanelTrialGrid:SetTrialItemState()
    local id = self.ItemData.Id
    if XDataCenter.TrialManager.TrialLevelLock(id) then --解锁的
        self.ImgLock.gameObject:SetActiveEx(false)
        if XDataCenter.TrialManager.TrialLevelFinished(id) then
            if XDataCenter.TrialManager.TrialRewardGeted(id) then
                self.ImgCanGet.gameObject:SetActiveEx(false)
                self.ImgGeted.gameObject:SetActiveEx(true)
            else
                self.ImgCanGet.gameObject:SetActiveEx(true)
                self.ImgGeted.gameObject:SetActiveEx(false)
            end
        else
            self.ImgCanGet.gameObject:SetActiveEx(false)
            self.ImgGeted.gameObject:SetActiveEx(false)
        end
    else
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgCanGet.gameObject:SetActiveEx(false)
        self.ImgGeted.gameObject:SetActiveEx(false)
    end
end

-- 关闭特效，防止特效透ui。
function XUiPanelTrialGrid:CloseFx()
    self.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiPanelTrialGrid:OpenFx()
    self.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiPanelTrialGrid:SetTrialItemRewardFx()
    if self.ItemData and self.ItemData.Id then
        local id = self.ItemData.Id
        if XDataCenter.TrialManager.TrialLevelLock(id) and XDataCenter.TrialManager.TrialLevelFinished(id) and not XDataCenter.TrialManager.TrialRewardGeted(id) then
            self:OpenFx()
            return
        end
    end
    self:CloseFx()
end

return XUiPanelTrialGrid