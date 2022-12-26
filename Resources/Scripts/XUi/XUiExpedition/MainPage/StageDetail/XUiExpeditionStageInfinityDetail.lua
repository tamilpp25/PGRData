-- 虚拟地平线无尽关显示组件
local XUiExpeditionStageInfinityDetail = {}

function XUiExpeditionStageInfinityDetail.OnEnable(component)

end

function XUiExpeditionStageInfinityDetail.RefreshData(component, stageData)

end

function XUiExpeditionStageInfinityDetail.OnDisable(component)

end

function XUiExpeditionStageInfinityDetail.OnUiDisable(component, ui)
    component.ImgSelect.gameObject:SetActiveEx(false)
    component.ChapterComponent:CancelSelect()
end

function XUiExpeditionStageInfinityDetail.OnDestroy(component)

end

function XUiExpeditionStageInfinityDetail.SetSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiExpeditionStageInfinityDetail.CancelSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiExpeditionStageInfinityDetail.OnClick(component)
    local stageDetail = component.RootUi:FindChildUiObj("UiExpeditionStageDetail")
    if stageDetail then stageDetail:RefreshChapter(component) end
    component.RootUi:OpenOneChildUi("UiExpeditionStageDetail", component)
end

function XUiExpeditionStageInfinityDetail.SetBuffList(component, ui)
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

function XUiExpeditionStageInfinityDetail.OnUiEnable(component, ui)
    if not component.Ui or component.Ui ~= ui then component.Ui = ui end
    local eStage = component.EStage
    ui.PanelStory.gameObject:SetActiveEx(false)
    ui.Panellist.gameObject:SetActiveEx(true)
    ui.PanelDropList.gameObject:SetActiveEx(false)
    ui.PanelEndless.gameObject:SetActiveEx(true)
    ui.TxtTitle.text = eStage:GetStageName()
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
    XUiExpeditionStageInfinityDetail.SetEndlessWave(ui)
    XUiExpeditionStageInfinityDetail.SetBuffList(component, ui)
    ui:PlayAnimation("PanellistEnable")
    CsXUiHelper.RegisterClickEvent(ui.BattleEnter, function() ui:OnEnterBattle() end)
    CsXUiHelper.RegisterClickEvent(ui.BtnClose, function() ui:Hide() end)
end

function XUiExpeditionStageInfinityDetail.SetEndlessWave(ui)
    ui.TxtEndlessWave.text = CS.XTextManager.GetText("ExpeditionInfiDetail", XDataCenter.ExpeditionManager.GetWave())
end

return XUiExpeditionStageInfinityDetail