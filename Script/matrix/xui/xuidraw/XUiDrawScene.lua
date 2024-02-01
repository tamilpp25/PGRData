---@class XUiDrawScene
local XUiDrawScene = XClass(nil,"XUiDrawScene")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

---@param ui XUi
function XUiDrawScene:Ctor(ui)
    self.Ui = ui
end

function XUiDrawScene:InitScene()
    if not XTool.UObjIsNil(self.ModelRoot) then
        return
    end
    self.ModelRoot = self.Root:FindTransform("PanelModelCase1")
    ---@type XUiPanelRoleModel
    self.PanelRoleModel = XUiPanelRoleModel.New(self.ModelRoot, self.Ui.Name, false, true, true, true, false)
end

function XUiDrawScene:RefreshScene(drawCfg, modelId)
    self.DrawCfg = drawCfg
    local beLoadModelId = modelId or drawCfg.ModelId 
    --self.Ui:PlayAnimation("DarkEnable",function()
        self:LoadScene(drawCfg.ScenePath,drawCfg.UiModelPath,function()
            if self.DrawCfg.Type == XDrawConfigs.ModelType.Role then
                self:LoadRoleModel(tonumber(beLoadModelId),drawCfg.IsHideWeapon == 1,function()
                    --self.Ui:PlayAnimation("DarkDisable")
                end)
            elseif self.DrawCfg.Type == XDrawConfigs.ModelType.Weapon then
                self:LoadWeaponModel(beLoadModelId,function()
                    --self.Ui:PlayAnimation("DarkDisable")
                end)
            elseif self.DrawCfg.Type == XDrawConfigs.ModelType.Partner then
                self:LoadPartnerModel(tonumber(beLoadModelId),function()
                    --self.Ui:PlayAnimation("DarkDisable")
                end)
            end
        end)
    --end)
end

---@param modelId number
function XUiDrawScene:LoadRoleModel(modelId,isHideWeapon,cb)
    self.PanelRoleModel.HideWeapon = isHideWeapon
    local fashtionId = XMVCA.XCharacter:GetCharacterTemplate(modelId).DefaultNpcFashtionId
    --XDataCenter.DisplayManager.UpdateRoleModel(self.PanelRoleModel, modelId, nil, fashtionId)
    self.PanelRoleModel:UpdateCharacterModel(modelId, self.ModelRoot, self.Ui.Name, function(model)
        self:SetModelTransform(model)
        model.gameObject:SetActiveEx(true)
        if cb then
            cb()
        end
        --local animeID = XDataCenter.DrawManager.GetDrawShowCharacter(modelId).AnimeID
        --local voiceId = XDataCenter.DrawManager.GetDrawShowCharacter(modelId).VoiceId
        --if animeID then
        --    self.PanelRoleModel:PlayAnima(animeID)
        --end
        --if voiceId then
        --    self.CvInfo = CS.XAudioManager.PlayCv(voiceId)
        --end
    end,nil,fashtionId,0,true,true,true)
    --XModelManager.LoadRoleModel(modelId, self.ModelRoot, function(model)
    --    --self.Ui.DragPanel.Target = model.transform
    --    ---@type UnityEngine.Animator
    --    self.Animator = model:GetComponent("Animator")
    --    if not Animator then
    --        self.Animator = model:AddComponent("Animator")
    --    end
    --    if self.Animator and controllerPath then
    --        local animatorController = CS.LoadHelper.LoadUiController(controllerPath,"UiDrawScene"..self.DrawCfg.Id)
    --        self.Animator.runtimeAnimatorController = animatorController
    --    end
    --end)
end

---@param modelId string
function XUiDrawScene:LoadWeaponModel(modelId,cb)
    --self.PanelRoleModel:UpdateCharacterWeaponModelsOther(nil,tonumber(modelId),nil,false)
    local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(tonumber(modelId), self.Ui.Name, 0)
    XModelManager.LoadWeaponModel(modelConfig.ModelId, self.ModelRoot.gameObject, modelConfig.TransformConfig, self.Ui.Name,function(model) 
        self:SetModelTransform(model)
        if cb then
            cb()
        end
    end,{showEffect = true, gameObject = self.Ui.GameObject})
end

---@param templateId string
function XUiDrawScene:LoadPartnerModel(templateId,cb)
    --self.PanelRoleModel:UpdatePartnerModel(modelId, self.Ui.Name,nil,nil,true,true,true)
    -- 待机模型
    
    self.CvInfo = XUiModelUtility.LoadPartnerModelSToC(templateId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiDrawShow, function(SModel)
        SModel.gameObject:SetActiveEx(true)
        self:SetModelTransform(SModel)
        if cb then
            cb()
        end
    end, function()
        local modelConfig = XDataCenter.PartnerManager.GetPartnerModelConfigById(templateId)
        -- 战斗模型
        self.PanelRoleModel:UpdatePartnerModel(modelConfig.CombatModel, XModelManager.MODEL_UINAME.XUiDrawShow, nil, function(CModel)
            CModel.gameObject:SetActiveEx(true)
            self:SetModelTransform(CModel)
        end, false, true)
        -- 出生特效
        self.PanelRoleModel:LoadPartnerUiEffect(modelConfig.CombatModel, XPartnerConfigs.EffectParentName.ModelOnEffect, true, true)
        -- 动画
        self.PanelRoleModel:PlayAnima(modelConfig.CombatBornAnime, true)
    end)
end

---@param sceneUrl string
---@param modelUrl string
function XUiDrawScene:LoadScene(sceneUrl, modelUrl,cb)
    self.Ui:LoadUiScene(sceneUrl, modelUrl,function() 
        self.Root = self.Ui.UiModelGo.transform
        self:InitScene()
        if cb then
            cb()
        end
    end)
end
---@param model UnityEngine.GameObject
function XUiDrawScene:SetModelTransform(model)
    if self.DrawCfg.ModelPosition then
        local position = XTool.ConvertStringToVector3(self.DrawCfg.ModelPosition)
        self.ModelRoot.position = position
    end

    if self.DrawCfg.ModelRotation then
        local rotation = XTool.ConvertStringToVector3(self.DrawCfg.ModelRotation)
        self.ModelRoot.eulerAngles = rotation
    end

    if self.DrawCfg.ModelScale then
        local scale = XTool.ConvertStringToVector3(self.DrawCfg.ModelScale)
        self.ModelRoot.localScale = scale
    end
end

return XUiDrawScene