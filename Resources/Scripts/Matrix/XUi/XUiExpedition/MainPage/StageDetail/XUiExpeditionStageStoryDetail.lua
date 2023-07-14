--虚像地平线准备关关卡组件
local XUiExpeditionStageStoryDetail = {}
function XUiExpeditionStageStoryDetail.OnEnable(component)
    
end

function XUiExpeditionStageStoryDetail.RefreshData(component, stageData)
    
end

function XUiExpeditionStageStoryDetail.OnDisable(component)
    
end

function XUiExpeditionStageStoryDetail.OnDestroy(component)
    
end

function XUiExpeditionStageStoryDetail.SetSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiExpeditionStageStoryDetail.CancelSelect(component)
    component.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiExpeditionStageStoryDetail.OnClick(component)
    local stageDetail = component.RootUi:FindChildUiObj("UiExpeditionStageDetail")
    if stageDetail then stageDetail:RefreshChapter(component) end
    component.RootUi:OpenOneChildUi("UiExpeditionStageDetail", component)
end

function XUiExpeditionStageStoryDetail.OnUiEnable(component, ui)
    local eStage = component.EStage
    ui.PanelStory.gameObject:SetActiveEx(true)
    ui.Panellist.gameObject:SetActiveEx(false)
    ui.TxtStoryTitle.text = eStage:GetStageName()
    ui.TxtStoryDes.text = eStage:GetStageDes()
    ui.TxtStoryRecruit.text = eStage:GetDrawTimesRewardStr()
    ui:PlayAnimation("PanelStoryEnable")
    CsXUiHelper.RegisterClickEvent(ui.BtnClose, function() ui:Hide() end)
    CsXUiHelper.RegisterClickEvent(ui.StoryEnter, function() ui:OnStoryEnterClick() end)
end

function XUiExpeditionStageStoryDetail.OnUiDisable(component, ui)
    component.ImgSelect.gameObject:SetActiveEx(false)
    component.ChapterComponent:CancelSelect()
end
return XUiExpeditionStageStoryDetail