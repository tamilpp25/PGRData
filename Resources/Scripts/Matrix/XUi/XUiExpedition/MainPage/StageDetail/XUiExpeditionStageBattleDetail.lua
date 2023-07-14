--虚像地平线战斗关关卡组件
local XUiExpeditionStageBattleDetail = {}
local XUiExpeditionStageBuffIcon = require("XUi/XUiExpedition/MainPage/StageDetail/XUiExpeditionStageBuffIcon")

function XUiExpeditionStageBattleDetail.OnEnable(component)
    
end

function XUiExpeditionStageBattleDetail.RefreshData(component, stageData)

end

function XUiExpeditionStageBattleDetail.OnDisable(component)
    
end

function XUiExpeditionStageBattleDetail.OnDestroy(component)
    
end

function XUiExpeditionStageBattleDetail.SetSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiExpeditionStageBattleDetail.CancelSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiExpeditionStageBattleDetail.OnClick(component)
    local stageDetail = component.RootUi:FindChildUiObj("UiExpeditionStageDetail")
    if stageDetail then stageDetail:RefreshChapter(component) end
    component.RootUi:OpenOneChildUi("UiExpeditionStageDetail", component)
end

function XUiExpeditionStageBattleDetail.SetDropList(eStage, detailUi)
    if not detailUi.GridList then detailUi.GridList = {} end
    detailUi.ImgFirstReward.gameObject:SetActiveEx(detailUi.EStage:GetIsPass())
    if eStage:GetIsPass() then
        for j = 1, #detailUi.GridList do
            detailUi.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end
    local rewardId = eStage:GetFirstRewardId()
    if not rewardId or rewardId == 0 then
        for j = 1, #detailUi.GridList do
            detailUi.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if detailUi.GridList[i] then
                grid = detailUi.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(detailUi.GridCommon)
                grid = XUiGridCommon.New(detailUi.RootUi, ui)
                grid.Transform:SetParent(detailUi.PanelDropContent, false)
                detailUi.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end
    for j = 1, #detailUi.GridList do
        if j > rewardsCount then
            detailUi.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end

function XUiExpeditionStageBattleDetail.SetBuffList(component, ui)
    if not ui.BuffList then ui.BuffList = {} end
    local buffList = component.EStage:GetStageEvents()
    ui.GridBuff.gameObject:SetActiveEx(false)
    ui.StageBuffCfgList = {}
    for i = 1, #buffList do
        if not ui.BuffList[i] then
            local prefab = CS.UnityEngine.GameObject.Instantiate(ui.GridBuff.gameObject)
            prefab.transform:SetParent(ui.PanelBuffContent, false)
            ui.BuffList[i] = XUiExpeditionStageBuffIcon.New(prefab, component.RootUi)
        end
    end
    for i = 1, #ui.BuffList do
        if buffList[i] then
            ui.BuffList[i]:RefreshData(buffList[i])
            ui.BuffList[i]:Show()
            table.insert(ui.StageBuffCfgList, buffList[i])
        else
            ui.BuffList[i]:Hide()
        end
    end
    for i = 1, #buffList do
        ui.BuffList[i].BtnClick.CallBack = function()
            local BuffTipsType = XDataCenter.ExpeditionManager.BuffTipsType.StageBuff
            XLuaUiManager.Open("UiExpeditionBuffTips", BuffTipsType, ui.StageBuffCfgList)
        end
    end 
    ui.ImgBattleBuffEmpty.gameObject:SetActiveEx(#buffList == 0)
end

function XUiExpeditionStageBattleDetail.OnUiEnable(component, ui)
    if not component.Ui or component.Ui ~= ui then component.Ui = ui end
    local eStage = component.EStage
    ui.PanelStory.gameObject:SetActiveEx(false)
    ui.Panellist.gameObject:SetActiveEx(true)
    ui.PanelDropList.gameObject:SetActiveEx(true)
    ui.PanelEndless.gameObject:SetActiveEx(false)
    ui.TxtTitle.text = eStage:GetStageName()
    ui.TxtBattleRecruit.text = eStage:GetDrawTimesRewardStr()
    for i = 1, 3 do
        ui["GridStar" .. i].gameObject:SetActiveEx(false)
    end
    local stageTarget = eStage:GetStageTargetDesc()
    for i = 1, 2 do
        if stageTarget[i] then
            ui["GridStar" .. i].gameObject:SetActiveEx(true)
            ui["TxtStarActive" .. i].text = stageTarget[i]
        end
    end
    ui.TxtATNums.text = 0
    XUiExpeditionStageBattleDetail.SetDropList(eStage, ui)
    XUiExpeditionStageBattleDetail.SetBuffList(component, ui)
    ui:PlayAnimation("PanellistEnable")
    CsXUiHelper.RegisterClickEvent(ui.BattleEnter, function() ui:OnEnterBattle() end)
    CsXUiHelper.RegisterClickEvent(ui.BtnClose, function() ui:Hide() end)
end

function XUiExpeditionStageBattleDetail.OnUiDisable(component, ui)
    component.ImgSelect.gameObject:SetActiveEx(false)
    component.ChapterComponent:CancelSelect()
end

return XUiExpeditionStageBattleDetail