XUiPanelRoleModel = XClass(nil, "XUiPanelRoleModel")

--==============================--
-- RoleModelPool = {["model"] = model, ["weaponList"] = list, ["characterId"] = characterId}
--==============================--
function XUiPanelRoleModel:Ctor(ui, refName, hideWeapon, showShadow, loadClip, setFocus, fixLight, playEffectFunc, clearUiChildren)
    self.RefName = refName or "DefaultName"
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    if clearUiChildren then -- 初始化时是否清空model挂点下所有物体
        XTool.DestroyChildren(ui.gameObject)
    end
    self.RoleModelPool = {}
    self.HideWeapon = hideWeapon and true or false
    self.ShowShadow = showShadow
    self.SetFocus = setFocus
    self.FixLight = fixLight
    self.PlayEffectFunc = playEffectFunc
    if loadClip == nil then
        self.InitLoadClip = true
    else
        self.InitLoadClip = loadClip and true
    end
    self.LoadClip = self.InitLoadClip
end

--设置默认动画
function XUiPanelRoleModel:SetDefaultAnimation(animationName)
    self.DefaultAnimation = animationName
end

function XUiPanelRoleModel:UpdateRoleModel(roleName, targetPanelRole, targetUiName, cb, IsReLoadAnime, needController, IsReLoadController)
    if not roleName then
        XLog.Error("XUiPanelCharRole:UpdateRoleModel 函数错误: 参数roleName不能为空")
        return
    end

    local defaultAnimation = self.DefaultAnimation or XModelManager.GetUiDefaultAnimationPath(roleName)
    self.DefaultAnimation = nil

    local modelPool = self.RoleModelPool
    local curRoleName = self.CurRoleName
    local curModelInfo = modelPool[curRoleName]
    if curModelInfo then
        curModelInfo.Model.gameObject:SetActiveEx(false)
        curModelInfo.time = XTime.GetServerNowTimestamp()
    end
    if curRoleName ~= roleName then
        self.CurRoleName = roleName
    end

    local runtimeControllerName
    --特殊时装只加载配置的动画状态机Controller
    runtimeControllerName = XModelManager.GetUiFashionControllerPath(roleName)
    if not runtimeControllerName then
        --如果没有配置，再加载配置展示用的动画状态机Controller
        if needController then
            runtimeControllerName = XModelManager.GetUiDisplayControllerPath(roleName)
        end
    end

    --如果用状态机就不需要手动加载animclip了
    if runtimeControllerName then
        self.LoadClip = nil
    else
        self.LoadClip = self.InitLoadClip --复原成一开始传入的参数
    end

    local needRemove = nil
    local nowTime = XTime.GetServerNowTimestamp()
    for k, v in pairs(modelPool) do
        --不等于当前要显示的模型且时间超出5秒的都要删掉
        if k ~= roleName and v and v.time then
            local diff = nowTime - v.time
            if diff >= 5 then
                if needRemove == nil then
                    needRemove = {}
                end
                table.insert(needRemove, k)
            end
        end
    end

    --删除超时的模型
    if needRemove then
        for i = 1, #needRemove do
            local tempRoleName = needRemove[i]
            local modelInfo = modelPool[tempRoleName]
            if modelInfo.Model and modelInfo.Model:Exist() then
                CS.UnityEngine.Object.Destroy(modelInfo.Model.gameObject)
            end
            modelPool[tempRoleName] = nil
        end
    end

    local modelInfo = modelPool[roleName]
    if IsReLoadAnime then
        self:LoadModelAndReLoadAnime(modelInfo, targetUiName, roleName, defaultAnimation, cb, runtimeControllerName, IsReLoadController)
    else
        self:LoadModelAndNotReLoadAnime(modelInfo, targetUiName, roleName, defaultAnimation, cb, runtimeControllerName, IsReLoadController)
    end

end

function XUiPanelRoleModel:LoadModelAndNotReLoadAnime(modelInfo, targetUiName, roleName, defaultAnimation, cb, runtimeControllerName, IsReLoadController)--更新加载同一个模型时不重新加载动画
    if modelInfo then
        modelInfo.Model.gameObject:SetActiveEx(true)
        if IsReLoadController then
            self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
        else
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end
    else
        XModelManager.LoadRoleModel(self.CurRoleName, self.Transform, self.RefName, function(model)
            local tmpModelInfo = {}
            tmpModelInfo.Model = model
            tmpModelInfo.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)

            self.RoleModelPool[roleName] = tmpModelInfo

            if self.LoadClip then
                self:LoadAnimationClips(model.gameObject, defaultAnimation, function()
                    self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
                end)
            else
                self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
            end
        end)
    end
end

function XUiPanelRoleModel:LoadModelAndReLoadAnime(modelInfo, targetUiName, roleName, defaultAnimation, cb, runtimeControllerName, IsReLoadController)--更新加载同一个模型时重新加载动画
    if modelInfo then
        modelInfo.Model.gameObject:SetActiveEx(true)
        self:LoadSingleAnimationClip(modelInfo.Model.gameObject, defaultAnimation, function()
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end)
    else
        XModelManager.LoadRoleModel(self.CurRoleName, self.Transform, self.RefName, function(model)
            local tmpModelInfo = {}
            tmpModelInfo.Model = model
            tmpModelInfo.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)
            self.RoleModelPool[roleName] = tmpModelInfo

            self:LoadSingleAnimationClip(model.gameObject, defaultAnimation, function()
                self:RoleModelLoaded(roleName, targetUiName, cb)
            end)
        end)
    end
end

function XUiPanelRoleModel:LoadAnimationClips(model, defaultAnimation, cb)
    if model == nil or not model:Exist() then
        XLog.Error("XUiPanelRoleModel.LoadAnimation 函数错误，参数model不能为空")
        return
    end

    local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))
    if loadAnimationClip == nil or not loadAnimationClip:Exist() then
        loadAnimationClip = model.gameObject:AddComponent(typeof(CS.XLoadAnimationClip))
        local clips = {}
        table.insert(clips, defaultAnimation)

        if not next(clips) or not loadAnimationClip:Exist() then
            XLog.Error("XUiPanelRoleModel.LoadAnimation playRoleAnimation = nil ")
            return
        end

        local activeState = model.gameObject.activeSelf
        model.gameObject:SetActiveEx(false)
        loadAnimationClip:LoadAnimationClips(clips, function()
            model.gameObject:SetActiveEx(activeState)
            if cb then cb() end
        end)
    else
        if cb then cb() end
    end
end

function XUiPanelRoleModel:LoadSingleAnimationClip(model, defaultAnimation, cb)
    if model == nil or not model:Exist() then
        local modelPool = self.RoleModelPool
        local curRoleName = self.CurRoleName
        local curModelInfo = modelPool[curRoleName]
        if curModelInfo then
            model = curModelInfo.Model.gameObject
        else
            XLog.Error("XUiPanelRoleModel.LoadAnimation model = nil ")
            return
        end
    end

    local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

    if loadAnimationClip == nil or not loadAnimationClip:Exist() then
        loadAnimationClip = model.gameObject:AddComponent(typeof(CS.XLoadAnimationClip))
    end

    local activeState = model.gameObject.activeSelf
    model.gameObject:SetActiveEx(false)
    loadAnimationClip:LoadSingleAnimationClip(defaultAnimation, function()
        model.gameObject:SetActiveEx(activeState)
        if cb then cb() end
    end)
end

function XUiPanelRoleModel:RoleModelLoaded(name, uiName, cb, runtimeControllerName)
    if not self.CurRoleName then return end
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then return end
    local model = modelInfo.Model

    XModelManager.SetRoleTransform(name, model, uiName)

    -- 阴影要放在武器模型加载完之后
    if self.ShowShadow then
        CS.XShadowHelper.AddShadow(self.GameObject)
    end

    -- 只有不是三个模型同时出现的界面调用此接口
    if not self.FixLight then
        CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
    end

    if runtimeControllerName then
        local animator = model:GetComponent("Animator")
        local runtimeController = CS.LoadHelper.LoadUiController(runtimeControllerName, self.RefName)
        animator.runtimeAnimatorController = runtimeController
    end

    if self.SetFocus then
        CS.XGraphicManager.Focus = model.transform
    end

    if cb then
        cb(model)
    end
end

function XUiPanelRoleModel:GetModelName(characterId)
    local quality
    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    if character then
        quality = character.Quality
    end

    return XDataCenter.CharacterManager.GetCharModel(characterId, quality)
end
-----------------------------------加载Ui角色动作特效start---------------------------
--==============================--
--desc: (外部接口)加载当前Ui角色动作特效
--@characterId: 角色id
--@actionId: 动作Id
--==============================--
function XUiPanelRoleModel:LoadCharacterUiEffect(characterId, actionId)
    if not characterId then return end
    local fashionId = XDataCenter.CharacterManager.GetShowFashionId(characterId)
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId, actionId)
    local model = self.RoleModelPool[self.CurRoleName]
    if not model.CharacterId then model.CharacterId = characterId end
    if model.CurrentUiEffect then
        model.CurrentUiEffect.gameObject:SetActiveEx(false)
    end
    if not model.NotUiStand1 then
        local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
        if playRoleAnimation then
            local defaultAnimeName = playRoleAnimation.DefaultClip
            model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        else
            model.NotUiStand1 = true
            return
        end
    end
    if not actionId and model.NotUiStand1 then return end
    if not id or not effectPath then
        return
    end
    if not actionId then model.UiDefaultId = id end
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载时装展示Ui角色动作特效
--@characterId: 角色id
--@fashionId: 时装Id
--==============================--
function XUiPanelRoleModel:LoadResCharacterUiEffect(characterId, fashionId)
    if not characterId then return end
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId)
    if not id or not effectPath then
        return
    end
    local model = self.RoleModelPool[self.CurRoleName]
    if not model.CharacterId then model.CharacterId = characterId end
    if model.CurrentUiEffect then
        model.CurrentUiEffect.gameObject:SetActiveEx(false)
    end
    local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if playRoleAnimation then
        local defaultAnimeName = playRoleAnimation.DefaultClip
        model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        if model.NotUiStand1 then return end
    else
        model.NotUiStand1 = true
        return
    end
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载Ui角色默认动作特效
--==============================--
function XUiPanelRoleModel:LoadCurrentCharacterDefaultUiEffect()
    local model = self.RoleModelPool[self.CurRoleName]
    if model.NotUiStand1 or not model.UiDefaultId then return end
    if model.CurrentUiEffect then
        model.CurrentUiEffect.gameObject:SetActiveEx(false)
    end
    local fashionId = XDataCenter.CharacterManager.GetShowFashionId(model.CharacterId)
    local _, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(model.CharacterId, fashionId)
    self:PlayCharacterUiEffect(model, model.UiDefaultId, rootName, effectPath)
end
--==============================--
--desc: 播放Ui角色动作特效
--==============================--
function XUiPanelRoleModel:PlayCharacterUiEffect(model, id, rootName, effectPath)
    local fx = self:GetModelUiEffect(model, id, rootName, effectPath)
    if not fx then return end
    fx.gameObject:SetActiveEx(true)
    model.CurrentUiEffect = fx
end
--==============================--
--desc: 获取Ui角色动作特效
--==============================--
function XUiPanelRoleModel:GetModelUiEffect(model, id, rootName, effectPath)
    if not model.UiEffect then model.UiEffect = {} end
    if not model.UiEffectParent then model.UiEffectParent = {} end
    if not model.UiEffect[id] then
        model.UiEffect[id] = self:CreateUiEffect(model, id, rootName, effectPath)
    end
    return model.UiEffect[id]
end
--==============================--
--desc: 生成Ui角色动作特效
--==============================--
function XUiPanelRoleModel:CreateUiEffect(model, id, rootName, effectPath)
    local parent -- 搜挂点
    if not rootName then
        parent = model.Model.gameObject
    else
        parent = model.Model.gameObject:FindGameObject(rootName)
        if not parent then parent = model.Model.gameObject end
    end
    local fx = parent:LoadPrefab(effectPath, false)
    -- XUiLoadPrefab组件同一个挂点只会生成一个Prefab，旧的会自动销毁，这里为每个挂点存储已生成的Id作比对
    if model.UiEffectParent[parent.name] then
        model.UiEffect[model.UiEffectParent[parent.name]] = nil
    end
    model.UiEffectParent[parent.name] = id
    return fx
end
--------------------------------------加载Ui角色动作特效end---------------------------
--==============================--
--desc: 更新角色模型
--@characterId: 角色id
--@targetPanelRole: 目标面板
--@targetUiName: 目标ui名
--==============================--
function XUiPanelRoleModel:UpdateCharacterModel(characterId, targetPanelRole, targetUiName, cb, weaponCb, fashionId, growUpLevel, hideEffect)
    local weaponFashionId

    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    local resourcesId
    if XTool.IsNumberValid(fashionId) then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    end

    local modelName
    if resourcesId then
        modelName = XDataCenter.CharacterManager.GetCharResModel(resourcesId)
    else
        modelName = self:GetModelName(characterId)
    end
    if not modelName then
        return
    end

    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, hideEffect, nil, weaponFashionId)   --- todo  cur equip
        end

        if not hideEffect then
            self:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId)
        end

        if cb then
            cb(model)
        end

        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end)
    self:LoadCharacterUiEffect(tonumber(characterId))
end

--==============================--
--desc: 在查看其他玩家信息时，更新角色模型
--==============================--
function XUiPanelRoleModel:UpdateCharacterModelOther(character, weapon, weaponFashionId, targetPanelRole, targetUiName, cb)

    local characterId = character.Id
    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    local template = XDataCenter.FashionManager.GetFashionTemplate(character.FashionId)
    local resourcesId = template.ResourcesId

    local modelName
    if resourcesId then
        modelName = XDataCenter.CharacterManager.GetCharResModel(resourcesId)
    else
        local quality
        if character then
            quality = character.Quality
        end

        modelName = XDataCenter.CharacterManager.GetCharModel(characterId, quality)
    end
    if not modelName then
        return
    end

    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModelsOther(character, weapon, weaponFashionId, modelName)
        end

        if cb then
            cb(model)
        end

        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end)
    self:LoadCharacterUiEffectOther(character)
end

function XUiPanelRoleModel:LoadCharacterUiEffectOther(character, actionId)
    if character then return end
    local fashionId = character.FashionId or XCharacterConfigs.GetCharacterTemplate(character.Id).DefaultNpcFashtionId
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(character.Id, fashionId, actionId)
    local model = self.RoleModelPool[self.CurRoleName]

    if not model.CharacterId then model.CharacterId = character.Id end
    if model.CurrentUiEffect then
        model.CurrentUiEffect.gameObject:SetActiveEx(false)
    end
    if not model.NotUiStand1 then
        local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
        if playRoleAnimation then
            local defaultAnimeName = playRoleAnimation.DefaultClip
            model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        else
            model.NotUiStand1 = true
            return
        end
    end
    if not actionId and model.NotUiStand1 then return end
    if not id or not effectPath then
        return
    end
    if not actionId then model.UiDefaultId = id end
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end


--==============================--
--desc: 更新机器人角色模型
--==============================--
function XUiPanelRoleModel:UpdateRobotModel(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb)
    local resourcesId
    if fashionId then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    end

    local modelName
    if resourcesId then
        modelName = XDataCenter.CharacterManager.GetCharResModel(resourcesId)
    else
        modelName = self:GetModelName(characterId)
    end
    if not modelName then
        return
    end

    self:UpdateRoleModel(modelName, nil, nil, function(model)
        if not self.HideWeapon then
            local weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, true, equipTemplateId, weaponFashionId)
        end
        if modelCb then modelCb(model) end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end)
    self:LoadResCharacterUiEffect(characterId, fashionId)
end

function XUiPanelRoleModel:UpdateCharacterResModel(resId, characterId, targetUiName, cb, growUpLevel, weaponFashionId)
    local modelName = XDataCenter.CharacterManager.GetCharResModel(resId)
    local fashionId = XDataCenter.FashionManager.GetFashionIdByResId(resId)

    if modelName then
        self:UpdateRoleModel(modelName, nil, targetUiName, function(model)
            if not self.HideWeapon then
                self:UpdateCharacterWeaponModels(characterId, modelName, nil, nil, nil, weaponFashionId)
            end

            self:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId)

            if cb then
                cb(model)
            end
        end)
    end
    if fashionId then self:LoadResCharacterUiEffect(characterId, fashionId) end
end

function XUiPanelRoleModel:UpdateCharacterModelByModelId(modelId, characterId, targetPanelRole, targetUiName, cb, growUpLevel, showDefaultFx)
    if not modelId then return end

    self:UpdateRoleModel(modelId, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelId)
        end

        self:UpdateCharacterLiberationLevelEffect(modelId, characterId, growUpLevel, nil, showDefaultFx)

        if cb then
            cb(model)
        end
    end)
    local defaultFashionId = XCharacterConfigs.GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local fashionId
    if growUpLevel == 2 then --growUpLevel 2为第一套解放衣服 3，4为第二套解放衣服，解放的时装Id跟默认时装Id紧挨且按顺序+1
        fashionId = defaultFashionId + 1
    elseif growUpLevel >= 3 then
        fashionId = defaultFashionId + 2
    else
        fashionId = defaultFashionId
    end
    if fashionId then
        self:LoadResCharacterUiEffect(characterId, fashionId)
    end
end

function XUiPanelRoleModel:UpdateBossModel(modelName, targetUiName, targetPanelRole, cb, isReLoad)
    if modelName then
        self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
            if cb then
                cb(model)
            end
        end, true)
    end
end

function XUiPanelRoleModel:UpdateArchiveMonsterModel(modelName, targetUiName, targetPanelRole, cb)
    if modelName then
        self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
            if cb then
                cb(model)
            end
        end, true)
    end
end

function XUiPanelRoleModel:UpdatePartnerModel(modelName, targetUiName, targetPanelRole, cb, isReLoad, needController, IsReLoadController)
    if modelName then
        self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
            if cb then
                cb(model)
            end
        end, isReLoad, needController, IsReLoadController)
    end
end

function XUiPanelRoleModel:UpdateCharacterModelByFightNpcData(fightNpcData, cb)
    local char = fightNpcData.Character
    if char then
        local modelName
        local fashionId = char.FashionId

        if fashionId then
            local fashion = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
            modelName = XDataCenter.CharacterManager.GetCharResModel(fashion.ResourcesId)
        else
            -- modelName = XDataCenter.CharacterManager.GetCharModel(char.Id, char.Quality)
            modelName = self:GetModelName(char.Id)
        end



        if modelName then
            self:UpdateRoleModel(modelName, nil, nil, function(model)
                self:UpdateEquipsModelsByFightNpcData(model, fightNpcData, modelName)
                self:UpdateCharacterLiberationLevelEffect(modelName, char.Id, char.LiberateLv, fashionId)
                if cb then
                    cb(model)
                end
            end)
        end
        self:LoadResCharacterUiEffect(char.Id, fashionId)
    end
end

function XUiPanelRoleModel:UpdateEquipsModelsByFightNpcData(charModel, fightNpcData, modelName)
    XModelManager.LoadRoleWeaponModelByFight(charModel, fightNpcData, self.RefName, self.GameObject, modelName)
end

--==============================--
--desc: 更新角色武器模型
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, hideEffect, equipTemplateId, weaponFashionId)
    local equipModelIdList = {}

    if equipTemplateId then
        local equip = { TemplateId = equipTemplateId }
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    else
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByCharacterId(characterId, hideEffect, weaponFashionId)
    end

    if not equipModelIdList or not next(equipModelIdList) then
        return
    end

    if not modelName then
        modelName = self:GetModelName(characterId)
    end

    local roleModel = self.RoleModelPool[modelName]
    if not roleModel then
        return
    end

    XModelManager.LoadRoleWeaponModel(roleModel.Model, equipModelIdList, self.RefName, weaponCb, hideEffect, self.GameObject, modelName)
end

--==============================--
--desc: 查看其他玩家角色信息时，更新角色武器模型
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModelsOther(characterId, equip, weaponFashionId, modelName, weaponCb, hideEffect)
    local equipModelIdList = {}
    if weaponFashionId and weaponFashionId ~= 0 then
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    else
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip)
    end

    if not equipModelIdList or not next(equipModelIdList) then
        return
    end

    if not modelName then
        modelName = self:GetModelName(characterId)
    end

    local roleModel = self.RoleModelPool[modelName]
    if not roleModel then
        return
    end
    XModelManager.LoadRoleWeaponModel(roleModel.Model, equipModelIdList, self.RefName, weaponCb, hideEffect, self.GameObject)
end


---=================================================
--- 在当前播放中的动画播放完后执行回调
---@overload fun(callBack:function)
---@param callBack function
---=================================================
local CheckAnimeFinish = function(animator, behaviour, animaName, callBack)--如果动画被打断或是停止都会调用回调
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0);
    if (animatorInfo:IsName(animaName) and animatorInfo.normalizedTime >= 1) or not animatorInfo:IsName(animaName) then--normalizedTime的值为0~1，0为开始，1为结束。
        if callBack then callBack() end
        behaviour.enabled = false
    end
end

local AddPlayingAnimCallBack = function(obj, animator, animaName, callBack)
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(0);

    if not animatorInfo:IsName(animaName) or animatorInfo.normalizedTime >= 1 then--normalizedTime的值为0~1，0为开始，1为结束。
        return
    end

    local behaviour = obj.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = obj.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end

    behaviour.LuaUpdate = function()
        CheckAnimeFinish(animator, behaviour, animaName, callBack)
    end
end
---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---=================================================
function XUiPanelRoleModel:PlayAnima(AnimaName, fromBegin, callBack, errorCb)
    local IsCanPlay, animator = self:CheckAnimaCanPlay(AnimaName)
    if IsCanPlay and animator then
        if fromBegin then
            animator:Play(AnimaName, 0, 0);
        else
            animator:Play(AnimaName)
        end
        if callBack then
            XScheduleManager.ScheduleOnce(function()
                AddPlayingAnimCallBack(self, animator, AnimaName, callBack)
            end, 1)
        end
    else
        if errorCb then
            errorCb()
        end
    end
    return IsCanPlay
end
---=================================================
--- 检查'AnimaName'动画，是否能够播放
---@overload fun(AnimaName:string)
---@param AnimaName string
---=================================================
function XUiPanelRoleModel:CheckAnimaCanPlay(AnimaName)
    local IsCanPlay = false
    local animator
    if self.CurRoleName and self.RoleModelPool[self.CurRoleName] and self.RoleModelPool[self.CurRoleName].Model then
        animator = self.RoleModelPool[self.CurRoleName].Model:GetComponent("Animator")
        if XModelManager.CheckAnimatorAction(animator, AnimaName) then
            IsCanPlay = true
        end
    end
    return IsCanPlay, animator
end

---=================================================
--- 无参数时，结束播放当前动画，恢复成站立动画
---
--- 有参数时，只有当前动画为'oriAnima'，才结束播放动画
---@overload fun()
---@param oriAnima string
---=================================================
function XUiPanelRoleModel:StopAnima(oriAnima)
    local animator = self.RoleModelPool[self.CurRoleName].Model:GetComponent("Animator")
    local clip = animator:GetCurrentAnimatorClipInfo(0)[0].clip

    -- 是否需要播放动作打断特效
    if self.PlayEffectFunc then
        self.PlayEffectFunc()
    end

    if oriAnima == nil or clip.name == oriAnima then
        -- 停止UI特效
        local model = self.RoleModelPool[self.CurRoleName]
        if model.CurrentUiEffect then
            model.CurrentUiEffect.gameObject:SetActiveEx(false)
        end

        animator:Play(clip.name, 0, 0.999);
    end
end

function XUiPanelRoleModel:GetAnimator()
    if self.RoleModelPool[self.CurRoleName] then
        return self.RoleModelPool[self.CurRoleName].Model:GetComponent("Animator")
    else
        return nil
    end
end

function XUiPanelRoleModel:ShowRoleModel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(true)
    end
end

function XUiPanelRoleModel:HideRoleModel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

--==============================--
--desc: 更新角色解放特效
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId, showDefaultFx)
    local modelInfo = self.RoleModelPool[modelName]
    local model = modelInfo and modelInfo.Model
    if not model then return end

    local liberationFx = modelInfo.LiberationFx

    local rootName, fxPath
    if showDefaultFx then
        --通过解放等级获取默认解放特效配置
        rootName, fxPath = XDataCenter.CharacterManager.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    else
        --通过角色Id获取时装对应解放特效配置
        rootName, fxPath = XDataCenter.CharacterManager.GetCharFashionLiberationEffectRootAndPath(characterId, growUpLevel, fashionId)
    end

    if not rootName or not fxPath then
        if liberationFx then
            liberationFx:SetActiveEx(false)
        end
        return
    end

    if not liberationFx then
        local rootTransform = model.transform:FindTransform(rootName)
        if XTool.UObjIsNil(rootTransform) then
            XLog.Error("XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect Error:can Not find rootTransform in this model, rootName is:" .. rootName)
            return
        end
        modelInfo.LiberationFx = rootTransform.gameObject:LoadPrefab(fxPath, false)
    else
        liberationFx:SetActiveEx(true)
    end
end


---=================================================
--- 材质控制器相关特效需要跟模型绑定
---@param effect GameObject
---=================================================
function XUiPanelRoleModel:BindEffect(effect)
    XLog.Debug("bind effect " .. self.CurRoleName)
    if self.CurRoleName and self.RoleModelPool[self.CurRoleName] and self.RoleModelPool[self.CurRoleName].RenderingProxy then
        self.RoleModelPool[self.CurRoleName].RenderingProxy:BindEffect(effect)
    end
end

---=================================================
--- 设置LoadEffect接口最大加载特效数量，默认最大是1
---=================================================
function XUiPanelRoleModel:SetEffectMaxCount(value)
    self.EffectMaxCount = value
end

---=================================================
--- 加载特效，可支持多次加载特效，需要提前设置EffectMaxCount
---@param effectPath 特效路径
---@param isBindEffect 材质控制器相关特效和模型绑定
---=================================================
function XUiPanelRoleModel:LoopLoadEffect(effectPath, isBindEffect)
    if not effectPath then return end
    if isBindEffect == nil then isBindEffect = false end
    if self.EffectMaxCount == nil then self.EffectMaxCount = 1 end
    if self.EffectingIndex == nil then self.EffectingIndex = 0 end

    local effectParentKey = self.EffectingIndex % self.EffectMaxCount
    self:LoadEffect(effectPath, effectParentKey, isBindEffect, false)
    self.EffectingIndex = self.EffectingIndex + 1
end

---=================================================
---生成指定名称的父节点并在其下加载特效
---@param effectPath 特效路径
---@param effectParentName 生成一个前缀Customize_+ effectParentName的节点，特效将挂载在其下。不指定时默认生成一个Default_EffectParent节点供挂载
---@param isBindEffect 材质控制器相关特效和模型绑定
---@param isDisableOldEffect 为true时UnActive指定节点名下挂载的特效
---=================================================
local CreateEffectParentName = function(name)
    return name and string.format("Customize_%s", name) or "Default_EffectParent"
end

function XUiPanelRoleModel:LoadEffect(effectPath, effectParentName, isBindEffect, isDisableOldEffect)
    if isDisableOldEffect then
        self:HideEffectByParentName(effectParentName)
    end

    if not effectPath then return end
    if isBindEffect == nil then isBindEffect = false end

    self.EffectParentDic = self.EffectParentDic or {}
    self.EffectDic = self.EffectDic or {}

    local parentName = CreateEffectParentName(effectParentName)
    local effectParent = self.EffectParentDic[parentName]

    if effectParent == nil then
        effectParent = CS.UnityEngine.GameObject(tostring(parentName))
        effectParent.transform:SetParent(self.Transform, false)
        self.EffectParentDic[parentName] = effectParent
    end
    local effect = effectParent:LoadPrefab(effectPath)

    self.EffectDic[parentName] = self.EffectDic[parentName] or {}
    self.EffectDic[parentName][effectPath] = effect


    if effect == nil or XTool.UObjIsNil(effect) then
        XLog.Error(string.format("特效路径%s加载的特效为空", effectPath))
        return
    end

    if isBindEffect then
        self:BindEffect(effect)
    end

    effect.gameObject:SetActiveEx(false)
    effect.gameObject:SetActiveEx(true)
end

function XUiPanelRoleModel:HideEffectByParentName(effectParentName)
    if self.EffectDic == nil then return end
    local parentName = CreateEffectParentName(effectParentName)
    for _, effect in pairs(self.EffectDic[parentName] or {}) do
        if effect and not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelRoleModel:HideAllEffects()
    for _, effectGroup in pairs(self.EffectDic or {}) do
        for _, effect in pairs(effectGroup or {}) do
            if effect and not XTool.UObjIsNil(effect) then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiPanelRoleModel:GetModelInfoByName(name)
    return self.RoleModelPool[name]
end