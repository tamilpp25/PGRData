local XUiModelUtility = {}

---加载小模型及其特效并播放动画
---@param templateId number 辅助机Id
---@param panelRoleModelUi XUiPanelRoleModel 加载模型界面
---@param uiName string 需要加载模型的Ui名(XModelManager.MODEL_UINAME的枚举)
---@param loadCallback function 加载小模型解锁后的回调
---@param sToCAnimaFinishCallback function 播放完小模型动画后的回调
---@return userdata 播放的音频信息
function XUiModelUtility.LoadPartnerModelSToC(templateId, panelRoleModelUi, uiName, loadCallback, sToCAnimaFinishCallback)
    local modelConfig = XDataCenter.PartnerManager.GetPartnerModelConfigById(templateId)
    local cvInfo = nil

    if not modelConfig then
        XLog.Error("获取辅助机模型配置失败！ParnterId: " .. templateId)
        return
    end

    if not panelRoleModelUi then
        XLog.Error("XUiPanelPoleModel为空！")
        return
    end

    panelRoleModelUi:UpdatePartnerModel(modelConfig.StandbyModel, uiName, nil, loadCallback, false, true)
    -- 音效
    if modelConfig.SToCVoice and modelConfig.SToCVoice > 0 then
        cvInfo = XSoundManager.PlaySoundByType(modelConfig.SToCVoice, XSoundManager.SoundType.Sound)
    end

    -- 变形特效
    panelRoleModelUi:LoadPartnerUiEffect(modelConfig.StandbyModel, XPartnerConfigs.EffectParentName.ModelOffEffect, true, true)
    -- 动画
    panelRoleModelUi:PlayAnima(modelConfig.SToCAnime, true, sToCAnimaFinishCallback)

    return cvInfo
end

-- v2.6 v2.7 幻痛囚笼部分模型要使用图鉴的配置来控制, v2.7还无望公用此功能
function XUiModelUtility.UpdateModelByArchive(ui, panelRoleModel, modelId, targetUiName, npcState)
    if modelId == "Mb1BruceloongMd010001UI" or modelId == "Mb1StarknightMd010001UI" then
        local npcId = XArchiveConfigs.GetMonsterNpcIdByModelId(modelId)
        if not npcId then
            panelRoleModel:UpdateBossModel(modelId, targetUiName)
            panelRoleModel:ShowRoleModel()
            return
        end
        npcState = npcState or 1
        XUiModelUtility.UpdateModelByArchiveMonsterNpcData(ui, panelRoleModel, npcId, npcState, nil, targetUiName)
        return
    end

    panelRoleModel:UpdateBossModel(modelId, targetUiName)
    panelRoleModel:ShowRoleModel()
end

---@param panelRoleModel XUiPanelRoleModel
---@param modelId string
function XUiModelUtility.UpdateModelByArchiveMonsterNpcData(ui, panelRoleModel, npcId, npcState, updateModelCallback, targetUiName)
    if ui.ModelUtilHideParts then
        for _, prats in pairs(ui.ModelUtilHideParts) do
            if not XTool.UObjIsNil(prats) then
                prats.gameObject:SetActiveEx(true)
            end
        end
    end
    if ui.ModelUtilEffects then
        for _, effect in pairs(ui.ModelUtilEffects) do
            if not XTool.UObjIsNil(effect) then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end
    ui.ModelUtilHideParts = {}
    ui.ModelUtilEffects = {}

    local transData = XArchiveConfigs.GetMonsterTransDatas(npcId, npcState)
    local effectDatas = XArchiveConfigs.GetMonsterEffectDatas(npcId, npcState)
    local modelId = XArchiveConfigs.GetMonsterModel(npcId)

    panelRoleModel:SetDefaultAnimation(transData and transData.StandAnime)
    panelRoleModel:UpdateArchiveMonsterModel(modelId, targetUiName, nil, updateModelCallback)
    panelRoleModel:ShowRoleModel()

    if transData then
        for _, node in pairs(transData.HideNodeName or {}) do
            local parts = panelRoleModel.GameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                parts.gameObject:SetActiveEx(false)
                table.insert(ui.ModelUtilHideParts, parts)
            else
                XLog.Error("HideNodeName Is Wrong :" .. node)
            end
        end

        -- 材质控制器，怪物皮肤
        if XTool.IsNumberValid(transData.ScriptPartId) then
            if panelRoleModel.Transform.childCount > 0 then
                local curModelInfo = panelRoleModel:GetModelInfoByName(panelRoleModel:GetCurRoleName())
                if curModelInfo then
                    local transform = curModelInfo.Model and curModelInfo.Model.transform
                    if transform then
                        local t = transform:GetComponent(typeof(CS.XCharSkinDisplay))
                        if not XTool.UObjIsNil(t) then
                            t:Revert(transData.ScriptPartId)
                            t:ToState(transData.ScriptPartId, 1)
                        else
                            XLog.Error("配置了材质参数但是找不到脚本 CS.XCharSkinDisplay, transDatas.ScriptPartId:" .. transData.ScriptPartId)
                        end
                    end
                end
            end
        end
    end

    if effectDatas then
        for node, effectPath in pairs(effectDatas) do
            local parts = panelRoleModel.GameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                local effect = parts.gameObject:LoadPrefab(effectPath, false)
                if effect then
                    effect.gameObject:SetActiveEx(true)
                    table.insert(ui.ModelUtilEffects, effect)
                end
            else
                XLog.Error("EffectNodeName Is Wrong :" .. node)
            end
        end
    end
end

return XUiModelUtility