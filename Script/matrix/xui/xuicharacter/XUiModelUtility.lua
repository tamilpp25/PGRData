local XUiModelUtility = {}

---加载小模型及其特效并播放动画
---@param templateId number 辅助机Id
---@param panelRoleModelUi XUiPanelRoleModel 加载模型界面
---@param uiName string 需要加载模型的Ui名(XModelManager.MODEL_UINAME的枚举)
---@param loadCallback function 加载小模型解锁后的回调
---@param sToCAnimaFinishCallback function 播放完小模型动画后的回调
---@return userdata 播放的音频信息
function XUiModelUtility.LoadPartnerModelSToC(templateId, panelRoleModelUi, uiName, loadCallback,
    sToCAnimaFinishCallback)
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
        cvInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, modelConfig.SToCVoice)
    end

    -- 变形特效
    panelRoleModelUi:LoadPartnerUiEffect(modelConfig.StandbyModel, XPartnerConfigs.EffectParentName.ModelOffEffect,
        true, true)
    -- 动画
    panelRoleModelUi:PlayAnima(modelConfig.SToCAnime, true, sToCAnimaFinishCallback)

    return cvInfo
end

function XUiModelUtility.UpdateMonsterBossModel(panelRoleModel, modelId, targetUiName)
    panelRoleModel:UpdateBossModel(modelId, targetUiName)
    panelRoleModel:ShowRoleModel()
end

function XUiModelUtility.UpdateMonsterArchiveModel(ui, panelRoleModel, modelId, targetUiName, npcId, npcState,
    updateModelCallback)
    if string.IsNilOrEmpty(modelId) then
        return
    end

    local npcId = npcId or XMVCA.XArchive:GetMonsterNpcIdByModelId(modelId)

    if not XTool.IsNumberValid(npcId) then
        return
    end

    local effectDatas = XMVCA.XArchive:GetMonsterEffectDatas(npcId, npcState or 1)

    if not XTool.IsTableEmpty(ui.ModelUtilEffects) then
        for _, effect in pairs(ui.ModelUtilEffects) do
            if not XTool.UObjIsNil(effect) then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end

    ui.ModelUtilEffects = {}
    panelRoleModel:SetDefaultAnimation(XModelManager.GetUiDefaultAnimationPath(modelId))
    panelRoleModel:UpdateArchiveMonsterModel(modelId, targetUiName, nil, updateModelCallback)
    panelRoleModel:ShowRoleModel()

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
