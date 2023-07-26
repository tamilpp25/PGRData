local XUiGridColorTableStage = XClass(nil, "UiGridColorTableStage")

function XUiGridColorTableStage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageCfg = nil
    self.GridCommonDic = {}

    self:InitUiObject()
    self:SetButtonCallBack()
end

function XUiGridColorTableStage:InitUiObject()
    self.Button = self.Transform:GetComponent("XUiButton")
    self.NormalIcon = XUiHelper.TryGetComponent(self.Transform, "Normal", "RawImage")
    self.NormalRewardList = XUiHelper.TryGetComponent(self.Transform, "Normal/RewardList")
    self.NormalGridCommon = XUiHelper.TryGetComponent(self.Transform, "Normal/RewardList/GridCommon")
    self.PressIcon = XUiHelper.TryGetComponent(self.Transform, "Press", "RawImage")
    self.PressRewardList = XUiHelper.TryGetComponent(self.Transform, "Press/RewardList")
    self.PressGridCommon = XUiHelper.TryGetComponent(self.Transform, "Press/RewardList/GridCommon")
    self.DisableIcon = XUiHelper.TryGetComponent(self.Transform, "Disable", "RawImage")
    self.DisableRewardList = XUiHelper.TryGetComponent(self.Transform, "Disable/RewardList")
    self.DisableGridCommon = XUiHelper.TryGetComponent(self.Transform, "Disable/RewardList/GridCommon")
end

function XUiGridColorTableStage:Refresh(base, stageCfg)
    self.Base = base
    self.StageCfg = stageCfg

    -- 通过标记
    local isPassed = XDataCenter.ColorTableManager.IsStagePassed(stageCfg.Id)
    self.Button:ShowTag(isPassed)
    
    -- 未解锁
    local isUnLock, desc = XDataCenter.ColorTableManager.IsStageUnlock(stageCfg.Id)
    self.Button:SetDisable(not isUnLock)
    if not isUnLock then
        self.Button:SetName(desc)
    end

    -- 首通奖励
    local stateList = {"Normal", "Press", "Disable"}
    for _, state in ipairs(stateList) do
        self[state.."Icon"]:SetRawImage(stageCfg.Icon)

        -- 刷新奖励
        local parent = self[state.."RewardList"]
        local gridCommon = self[state.."GridCommon"]
        for i = 1, parent.childCount do
            parent.transform:GetChild(i - 1).gameObject:SetActiveEx(false)
        end
        local rewardList = XRewardManager.GetRewardList(stageCfg.FirstRewardId)
        for i, reward in ipairs(rewardList) do
            local ui = nil
            if parent.childCount >= i then
                ui = parent.transform:GetChild(i - 1)
            else
                ui = CS.UnityEngine.Object.Instantiate(gridCommon, parent)
            end
            ui.gameObject:SetActiveEx(true)

            local instanceID = ui:GetInstanceID()
            local grid = self.GridCommonDic[instanceID]
            if grid == nil then
                grid = XUiGridCommon.New(ui)
                self.GridCommonDic[instanceID] = grid
            end
            grid:Refresh(reward)
            XUiHelper.TryGetComponent(ui, "ImgSelect").gameObject:SetActiveEx(isPassed)
        end
    end
end

function XUiGridColorTableStage:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnStageClicked)
end

function XUiGridColorTableStage:OnBtnStageClicked()
    local isUnLock, desc = XDataCenter.ColorTableManager.IsStageUnlock(self.StageCfg.Id)
    if isUnLock then
        self.Base:OpenStageDetail(self.StageCfg.Id)
    else
        XUiManager.TipError(desc)
    end
end

return XUiGridColorTableStage
