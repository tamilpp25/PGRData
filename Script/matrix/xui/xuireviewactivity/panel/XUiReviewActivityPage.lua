
local XUiReviewActivityPage = {}
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local TempPanel

XUiReviewActivityPage.ShowPanel = function(rootUi, page)
    XLuaUiManager.SetMask(true)
    local pagePanel = rootUi["PanelSequence" .. page]
    if not pagePanel then return end
    TempPanel = {}
    local currentActivityId = XDataCenter.ReviewActivityManager.GetActivityId()
    XTool.InitUiObjectByUi(TempPanel, pagePanel)
    XUiReviewActivityPage.ShowPageText(pagePanel, currentActivityId, page)
    XUiReviewActivityPage.ShowPageComponent(rootUi, pagePanel, currentActivityId, page)
    XUiReviewActivityPage.ShowPanelContinue(rootUi, page)
    XUiReviewActivityPage.PlayAnimation(rootUi, page)
    if TempPanel.TxtName then
        TempPanel.TxtName.text = CS.XTextManager.GetText("ReviewActivityPanelName") .. string.format("%02d", rootUi.ReadPage)
    end
    rootUi.ReadPage = rootUi.ReadPage + 1
    XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
        end, 3000)
end

XUiReviewActivityPage.OnDestroy = function(rootUi)
    local Components = rootUi.PageComponents
    for page, list in pairs(Components or {}) do
        for _, component in pairs(list or {}) do
            if component.OnDestroy then
                component:OnDestroy()
            end
        end
    end
end

XUiReviewActivityPage.UpdateModel = function(rootUi, modelType)
    if not rootUi.UiRoleModel then
        local uiModelRoot = rootUi.UiModelGo.transform
        rootUi.UiRoleModel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModel"), rootUi.Name, nil, true, nil, true, true)
        local modelTypeName = XReviewActivityConfigs.ModelTypeName[modelType]
        local getFunc = XDataCenter.ReviewActivityManager["Get" .. (modelTypeName or "") .. "CharacterId"]
        local charaId = XDataCenter.ReviewActivityManager.GetTopAbilityCharacterId()
        local cb = function()

        end
        rootUi.UiRoleModel:UpdateCharacterModel(charaId, rootUi.UiRoleModel, XModelManager.MODEL_UINAME.XUiReviewActivity, cb)
    end
    local uiRoleModel = rootUi.UiRoleModel
    if modelType == XReviewActivityConfigs.ModelType.None then
        uiRoleModel:HideRoleModel()
    else
        uiRoleModel:ShowRoleModel()
    end
end

XUiReviewActivityPage.ShowPageText = function(pagePanel, currentActivityId, page)
    local allTextCfgs = XReviewActivityConfigs.GetCfgByIdKey(
        XReviewActivityConfigs.TableKey.ActivityId2InfoDic,
        currentActivityId
    )
    local textCfgs = allTextCfgs[page]
    for _, textInfo in pairs(textCfgs or {}) do
        local text = TempPanel[textInfo.Key]
        if not text then
            goto nextInfo
        end
        local get = XDataCenter.ReviewActivityManager["Get" .. textInfo.DataName]
        if not get then
            goto nextInfo
        end
        local textFormat = string.gsub(textInfo.TextFormat, "\\n", "\n")
        XLog.Debug(textInfo, textFormat, get())
        text.text = CS.XTextManager.FormatString(textFormat, get())
        :: nextInfo ::
    end
end

XUiReviewActivityPage.ShowPageComponent = function(rootUi, pagePanel, currentActivityId, page)
    local allPageCfgs = XReviewActivityConfigs.GetCfgByIdKey(
        XReviewActivityConfigs.TableKey.ActivityId2PageDic,
        currentActivityId
    )
    local pageCfg = allPageCfgs[page]
    if not pageCfg then return end
    XUiReviewActivityPage.UpdateModel(rootUi, pageCfg.ModelType)
    if not rootUi.PageComponents then rootUi.PageComponents = {} end
    local Components = rootUi.PageComponents
    for _, componentName in pairs(pageCfg.Components or {}) do
        if not componentName or (componentName == "") then
            goto nextComponent
        end
        if not Components[page] then Components[page] = {} end
        if not Components[page][componentName] then
            local componentScript = require("XUi/XUiReviewActivity/Components/XUiReviewActivity" .. componentName)
            if componentScript then
                local component = componentScript.New(TempPanel[componentName])
                Components[page][componentName] = component
            end
        end
        Components[page][componentName]:OnShow()
        :: nextComponent ::
    end
end

XUiReviewActivityPage.ShowPanelContinue = function(rootUi, page)
    local maxPage = XDataCenter.ReviewActivityManager.GetTotlePageNum()
    if rootUi.PanelContinue then
        rootUi.PanelContinue.gameObject:SetActiveEx(page < maxPage)
    end
end

XUiReviewActivityPage.PlayAnimation = function(rootUi, page)
    if not rootUi.AnimationUObj then
        rootUi.AnimationUObj = rootUi.UiModel.UiNearRoot:GetComponent("UiObject")
    end
    if rootUi.UiModelCurrentAnimation then
        rootUi.UiModelCurrentAnimation:Stop()
    end
    if page < 3 then
        local anime = rootUi.AnimationUObj:GetObject("Bg" .. page .. "Enable")
        if anime then
            rootUi.UiModelCurrentAnimation = anime
            anime:Play()
        end
    end
end

return XUiReviewActivityPage