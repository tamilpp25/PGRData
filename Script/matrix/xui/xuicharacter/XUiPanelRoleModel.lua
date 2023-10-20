---@class XUiPanelRoleModel
local XUiPanelRoleModel = XClass(nil, "XUiPanelRoleModel")
local AnimeLayer = {
    Body = 0,
    Face = 1
}

local DefaultRoleAnimaName = "StandAct0101"
--==============================--
--- RoleModelPool = {["model"] = model, ["weaponList"] = list, ["characterId"] = characterId}
--==============================--
function XUiPanelRoleModel:Ctor(
ui,
refName,
hideWeapon,
showShadow,
loadClip,
setFocus,
fixLight,
playEffectFunc,
clearUiChildren,
useMultiModel)
    self.Ui = ui
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
    self.IsStandAnimaShowWeapon = false
    self.StandAnimaShowWeaponList = {}
    self.CueId = nil
    self.UiStandCallBack = {}
    self.NowFashionId = nil
    self.PlayUiStandCallBackList = {}
    self.AnimaPlayedCallBackList = {}
    self.IsStandAnimaHideNode = false
    if useMultiModel == nil then
        self.UseMultiModel = true
    end
end

--设置默认动画
function XUiPanelRoleModel:SetDefaultAnimation(animationName)
    self.DefaultAnimation = animationName
end

--[[    根据roleName从UiModel获取配置
    如果没有Display控制器，直接加载默认动画，否则加载控制器并播控制器默认动画
    PS:如果配置了Fasion控制层，直接以Fasion控制器为主
]]
function XUiPanelRoleModel:UpdateRoleModelWithAutoConfig(
roleName,
targetUiName,
cb,
isReLoadController,
needFightController)
    local displayController = XModelManager.GetUiDisplayControllerPath(roleName)
    local defaultAnimation = XModelManager.GetUiDefaultAnimationPath(roleName)
    self:UpdateRoleModel(
    roleName,
    nil,
    targetUiName,
    cb,
    defaultAnimation ~= nil,
    displayController ~= nil,
    isReLoadController,
    needFightController
    )
end

function XUiPanelRoleModel:UpdateRoleModel(
roleName,
targetPanelRole,
targetUiName,
cb,
IsReLoadAnime,
needDisplayController,
IsReLoadController,
needFightController)
    if not roleName then
        XLog.Error("XUiPanelCharRole:UpdateRoleModel 函数错误: 参数roleName不能为空")
        return
    end
    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(roleName, targetUiName)
    if self.UseMultiModel and isMultiModel then
        if not self.NewPanel then
            self.UseMultiModel = false
            self.NewPanel = XUiPanelRoleModel.New(
                    self.Ui,
                    self.RefName,
                    self.HideWeapon,
                    self.ShowShadow,nil,nil,nil,nil,nil,self.UseMultiModel)
        end
    end

    if self.NewPanel and isMultiModel then
        local minorModelId = XModelManager.GetMinorModelId(roleName, targetUiName)
        if not minorModelId then
            self.NewPanel = nil
        else
            self.NewPanel:UpdateRoleModel(
                    minorModelId,
                    targetPanelRole,
                    targetUiName,
                    cb,
                    IsReLoadAnime,
                    needDisplayController,
                    IsReLoadController,
                    needFightController)
        end
        
    end
    --特殊模型 && 单模型
    if isSpecialModel and not isMultiModel then
        roleName = XModelManager.GetSpecialModelId(roleName, targetUiName)
    end
    local defaultAnimation = self.DefaultAnimation or XModelManager.GetUiDefaultAnimationPath(roleName)
    self.DefaultAnimation = nil

    local modelPool = self.RoleModelPool
    local curRoleName = self.CurRoleName
    local curModelInfo = modelPool[curRoleName]
    if curModelInfo then
        if XTool.UObjIsNil(curModelInfo.Model.gameObject) then
            XLog.Error("[UpdateRoleModel] NullReferenceException: Object reference not set to an instance of an object")
            modelPool[curRoleName] = nil
            return
        end
        curModelInfo.Model.gameObject:SetActiveEx(false)
        curModelInfo.time = XTime.GetServerNowTimestamp()
    end
    if curRoleName ~= roleName then
        self.CurRoleName = roleName
    end

    local runtimeControllerName
    --特殊时装只加载配置的动画状态机Controller
    runtimeControllerName = (not needFightController) and XModelManager.GetUiFashionControllerPath(roleName)
    if not runtimeControllerName then
        --如果没有配置，再加载配置展示用的动画状态机Controller
        if needDisplayController then
            runtimeControllerName = XModelManager.GetUiDisplayControllerPath(roleName)
        end

        if needFightController then
            runtimeControllerName = XModelManager.GetUiControllerPath(roleName)
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
            --如果是多重模型，删除时一并删除副模型
            local isSpModel, isMulModel = XModelManager.CheckModelIsSpecial(tempRoleName, targetUiName)
            if isSpModel and isMulModel and self.NewPanel then
                local tempMinorModelId = XModelManager.GetMinorModelId(tempRoleName, targetUiName)
                if tempMinorModelId then
                    self.NewPanel.RoleModelPool[tempMinorModelId] = nil
                end
            end
        end
    end

    local modelInfo = modelPool[roleName]
    local cueId = self.CueId
    --UiStand播放背景音乐
    local uiStandVoiceCb = function(model)
        if cueId then
            if CS.XAudioManager.IsOpenFashionVoice == 1 then
                local cueInfo = { CueId = cueId, Info = nil }
                self:SetUiStandAnimaFinishCallback(model, function()
                    XSoundManager.Stop(cueInfo.CueId)
                    cueInfo.Info = XSoundManager.PlaySoundByType(cueInfo.CueId, XSoundManager.SoundType.Sound)
                end, function()
                    XSoundManager.StopByInfo(cueInfo.Info)
                end,false, true)
            end
        end
        
        if cb then
            cb(model)
        end
    end
    if IsReLoadAnime then
        self:LoadModelAndReLoadAnime(
        modelInfo,
        targetUiName,
        roleName,
        defaultAnimation,
        --[[cb]]uiStandVoiceCb,
        runtimeControllerName,
        IsReLoadController
        )
    else
        self:LoadModelAndNotReLoadAnime(
        modelInfo,
        targetUiName,
        roleName,
        defaultAnimation,
        --[[cb]]uiStandVoiceCb,
        runtimeControllerName,
        IsReLoadController
        )
    end
end

function XUiPanelRoleModel:LoadModelAndNotReLoadAnime(
modelInfo,
targetUiName,
roleName,
defaultAnimation,
cb,
runtimeControllerName,
IsReLoadController) --更新加载同一个模型时不重新加载动画
    if modelInfo then
        modelInfo.Model.gameObject:SetActiveEx(true)
        if IsReLoadController then
            self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
        else
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end
    else
        XModelManager.LoadRoleModel(
        self.CurRoleName,
        self.Transform,
        function(model)
            local tmpModelInfo = {}
            tmpModelInfo.Model = model
            tmpModelInfo.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)

            self.RoleModelPool[roleName] = tmpModelInfo
            if self.LoadClip then
                self:LoadAnimationClips(
                model.gameObject,
                defaultAnimation,
                function()
                    self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
                end
                )
            else
                self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
            end

            local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(self.CurRoleName, targetUiName)
            if self.NewPanel and isMultiModel then
                local newModelName = XModelManager.GetMinorModelId(self.CurRoleName, targetUiName)
                local info = self.NewPanel.RoleModelPool[newModelName]
                if info then
                    info.Model.transform:SetParent(model.transform, false)
                    info.Model.gameObject:SetLayerRecursively(model.gameObject.layer)
                end
            end
        end)
    end
end

function XUiPanelRoleModel:LoadModelAndReLoadAnime(
modelInfo,
targetUiName,
roleName,
defaultAnimation,
cb,
runtimeControllerName,
IsReLoadController) --更新加载同一个模型时重新加载动画
    if modelInfo then
        modelInfo.Model.gameObject:SetActiveEx(true)
        self:LoadSingleAnimationClip(
        modelInfo.Model.gameObject,
        defaultAnimation,
        function()
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end
        )
    else
        XModelManager.LoadRoleModel(
        self.CurRoleName,
        self.Transform,
        function(model)
            local tmpModelInfo = {}
            tmpModelInfo.Model = model
            tmpModelInfo.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)
            self.RoleModelPool[roleName] = tmpModelInfo

            self:LoadSingleAnimationClip(
            model.gameObject,
            defaultAnimation,
            function()
                self:RoleModelLoaded(roleName, targetUiName, cb)
            end
            )

            local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(self.CurRoleName, targetUiName)
            if self.NewPanel and isMultiModel then
                local newModelName = XModelManager.GetMinorModelId(self.CurRoleName, targetUiName)
                local info = self.NewPanel.RoleModelPool[newModelName]
                if info then
                    info.Model.transform:SetParent(model.transform, false)
                    info.Model.gameObject:SetLayerRecursively(model.gameObject.layer)
                end
            end
        end)
    end
end

local function GetDefaultAnimaName(loadAnimationClip)
    if not XTool.UObjIsNil(loadAnimationClip) and loadAnimationClip.Clips.Length > 0 then
        return loadAnimationClip.Clips[0].name
    end
    
    return ""
end

function XUiPanelRoleModel:SetPlayRoleAnimationCallback(model)
    local playRoleAnimation = model.gameObject:GetComponent(typeof(CS.XPlayRoleAnimation))

    if XTool.UObjIsNil(playRoleAnimation) then
        return
    end
    playRoleAnimation:SetPlayCallback(function(animaName, leftTime)
        for i = 1, #self.PlayUiStandCallBackList do
            self.PlayUiStandCallBackList[i](animaName, leftTime)
        end
    end)
end

local function RestoreModelNode(model, modelName, actionName)
    XModelManager.HandleUiModelNodeActive(actionName, modelName, model, true)
end

---设置播放UiStand时根据动画名隐藏或显示躯干的回调
function XUiPanelRoleModel:InitPlayUiStandCallBackList(model, defaultAnimaName)
    local curRoleName = self.CurRoleName
    local preAnimaName = ""
    
    self.PlayUiStandCallBackList = {}
    if curRoleName then
        if defaultAnimaName then
            XModelManager.HandleUiModelNodeActive(defaultAnimaName, curRoleName, model, false)
            preAnimaName = defaultAnimaName
        end
        
        self:AddUiStandPlayCallback(function(animaName, leftTime)
            if not string.IsNilOrEmpty(animaName) then
                if preAnimaName == animaName then
                    return
                end

                RestoreModelNode(model, curRoleName, preAnimaName)
                XModelManager.HandleUiModelNodeActive(animaName, curRoleName, model, false)
                preAnimaName = animaName
            end
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
        if not loadAnimationClip:Exist() then
            XLog.Error("XUiPanelRoleModel.LoadAnimation XLoadAnimationClip不存在")
            return
        end

        local clips = { defaultAnimation }
        if XTool.IsTableEmpty(clips) then
            XLog.Error("XUiPanelRoleModel.LoadAnimation error: defaultAnimation为空")
            return
        end

        local activeState = model.gameObject.activeSelf
        model.gameObject:SetActiveEx(false)
        loadAnimationClip:LoadAnimationClips(
        clips,
        function()
            model.gameObject:SetActiveEx(activeState)
            if cb then
                cb()
            end
        end
        )
    else
        if cb then
            cb()
        end
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
    loadAnimationClip:LoadSingleAnimationClip(
    defaultAnimation,
    function()
        model.gameObject:SetActiveEx(activeState)
        if cb then
            cb()
        end
    end
    )
end

function XUiPanelRoleModel:RoleModelLoaded(name, uiName, cb, runtimeControllerName)
    if not self.CurRoleName then
        return
    end
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then
        return
    end
    local model = modelInfo.Model

    XModelManager.SetRoleTransform(name, model, uiName)
    XModelManager.SetRoleCamera(name, model.transform.parent.parent.parent, uiName)

    if runtimeControllerName then
        local animator = model:GetComponent("Animator")
        local runtimeController = CS.LoadHelper.LoadUiController(runtimeControllerName, self.RefName)
        animator.runtimeAnimatorController = runtimeController
    end

    if self.SetFocus then
        CS.XGraphicManager.Focus = model.transform
    end

    -- UiStand通过动作控制节点显隐回调注册
    if self.LoadClip then
        local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        -- 在Callback前初始化回调列表
        if not XTool.UObjIsNil(loadAnimationClip) then
            self:SetPlayRoleAnimationCallback(model)
            self:InitPlayUiStandCallBackList(model, GetDefaultAnimaName(loadAnimationClip))
        end
    end

    if cb then
        cb(model)
    end
    uiName = uiName or self.RefName

    if not self.InitLoadClip then
        self.IsStandAnimaHideNode = XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, name, model, false)
    end

    -- 阴影要放在武器模型加载完之后
    if self.ShowShadow then
        CS.XShadowHelper.AddShadow(self.GameObject, true)
    end

    -- 只有不是三个模型同时出现的界面调用此接口
    if not self.FixLight then
        CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
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
--region---------------------------------加载Ui角色动作特效start---------------------------
--==============================--
--desc: (外部接口)加载当前Ui角色动作特效
--@characterId: 角色id
--@actionId: 动作Id
--==============================--
function XUiPanelRoleModel:LoadCharacterUiEffect(characterId, actionId, isNotSelf, weaponFashionId, isShowDefaultWeapon)
    if not characterId then
        return
    end
    
    local fashionId = nil

    if not self.NowFashionId then
        fashionId = XDataCenter.CharacterManager.GetShowFashionId(characterId, isNotSelf)
    else
        fashionId = self.NowFashionId    
    end
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId, actionId)
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then return end
    if not model.CharacterId then
        model.CharacterId = characterId
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
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
    if not actionId and model.NotUiStand1 then
        return
    end
    if not actionId then
        model.UiDefaultId = id
    end
    self:LoadCharacterUiEquipEffect(model, characterId, fashionId, actionId, isShowDefaultWeapon, weaponFashionId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载时装展示Ui角色动作特效
--@characterId: 角色id
--@fashionId: 时装Id
--==============================--
function XUiPanelRoleModel:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId, isShowDefaultWeapon, equipTemplateId)
    if not characterId then
        return
    end
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId)
    if not id or not effectPath then
        return
    end
    local model = self.RoleModelPool[self.CurRoleName]
    if not model.CharacterId then
        model.CharacterId = characterId
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
    local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if playRoleAnimation then
        local defaultAnimeName = playRoleAnimation.DefaultClip
        model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        if model.NotUiStand1 then
            return
        end
    else
        model.NotUiStand1 = true
        return
    end
    self:LoadCharacterUiEquipEffect(model, characterId, fashionId, nil, isShowDefaultWeapon, weaponFashionId, equipTemplateId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: 加载当前Q版角色动作特效
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:LoadCharacterCuteUiEffect(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then
        return
    end
    if not model.CharacterId then
        model.CharacterId = characterId
    end
    if XTool.UObjIsNil(model.Model.gameObject) then
        return
    end
    local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if not playRoleAnimation then
        return
    end
    -- Q版角色特殊处理 直接取默认动作id
    local actionId = playRoleAnimation.DefaultClip
    local id, rootName, effectPath = XCharacterCuteConfig.GetEffectInfo(characterId, actionId)
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载Ui角色默认动作特效
--==============================--
function XUiPanelRoleModel:LoadCurrentCharacterDefaultUiEffect()
    local model = self.RoleModelPool[self.CurRoleName]
    if model.NotUiStand1 or not model.UiDefaultId then
        return
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
    local fashionId = XDataCenter.CharacterManager.GetShowFashionId(model.CharacterId)
    local _, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(model.CharacterId, fashionId)
    self:LoadCharacterUiEquipEffect(model, model.CharacterId, fashionId)
    self:PlayCharacterUiEffect(model, model.UiDefaultId, rootName, effectPath)
end
--==============================--
--desc: 播放Ui角色动作特效
--==============================--
function XUiPanelRoleModel:PlayCharacterUiEffect(model, id, rootName, effectPath)
    if not id or not effectPath then
        return
    end
    self:GetModelUiEffect(model, id, rootName, effectPath)
    self:SetCurrentUiEffectActive(model.UiEffect, true)
    self:BindEffectByModel(model)
    self:SetReActiveUiEffect(model)
end

function XUiPanelRoleModel:LoadCharacterUiEquipEffect(model, characterId, fashionId, actionId, isShowDefaultWeapon, weaponFashionId, equipTemplateId)
    local equipModelIdList
    if equipTemplateId then
        local equip = { TemplateId = equipTemplateId }
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    else
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByCharacterId(characterId, isShowDefaultWeapon, weaponFashionId)
    end
    local idList, rootName2EffectPath = {}, {}
    for _, equipModelId in ipairs(equipModelIdList or {}) do
        if equipModelId and equipModelId ~= 0 then
            local effectId, name2EffectMap = XCharacterUiEffectConfig.GetEquipEffectInfo(equipModelId, fashionId, actionId)
            if effectId then
                table.insert(idList, effectId)
                for rootName, effectList in pairs(name2EffectMap or {}) do
                    rootName2EffectPath[rootName] = effectList
                end
            end
        end
    end
    if not XTool.IsTableEmpty(idList) then
        self:GetModelUiEquipEffect(model, table.concat(idList, "-"), rootName2EffectPath)
    end
end

function XUiPanelRoleModel:LoadCharacterUiEquipEffectOther(model, equip, fashionId, actionId, weaponFashionId)
    local idList, rootName2EffectPath = {}, {}
    local equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    for _, equipModelId in ipairs(equipModelIdList or {}) do
        if equipModelId ~= 0 then
            local effectId, name2EffectMap = XCharacterUiEffectConfig.GetEquipEffectInfo(equipModelId, fashionId, actionId)
            if effectId then
                table.insert(idList, effectId)
                for rootName, effectList in pairs(name2EffectMap or {}) do
                    rootName2EffectPath[rootName] = effectList
                end
            end
        end
    end
    if not XTool.IsTableEmpty(idList) then
        self:GetModelUiEquipEffect(model, table.concat(idList, "-"), rootName2EffectPath)
    end
end
--==============================--
--desc: 获取Ui角色动作特效
--==============================--
function XUiPanelRoleModel:GetModelUiEffect(model, id, rootNameArray, effectPathArray)
    if model.UiEffect and model.CurrentUiEffectId == id then
        return model.UiEffect
    end
    model.CurrentUiEffectId = id
    -- 不管上次的特效，因为XUiLoadPrefab已经处理了重复加载问题（XUiLoadPrefab组件同一个挂点只会生成一个Prefab，旧的会自动销毁）
    model.UiEffect = self:ClearUiEffectList(model.UiEffect)
    local uiEffectArray = model.UiEffect
    for idx, rootName in pairs(rootNameArray) do
        for _, effectPath in pairs(effectPathArray[idx] or {}) do
            local uiEffect = self:CreateUiEffect(model, id, rootName, effectPath)
            uiEffectArray[#uiEffectArray + 1] = uiEffect
        end
    end
    return uiEffectArray
end

--- 获取Ui角色武器特效
--------------------------
function XUiPanelRoleModel:GetModelUiEquipEffect(model, id, rootName2EffectPath)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, true)
    if model.UiEquipEffect and model.CurrentUiEquipEffectId == id then
        return model.UiEquipEffect
    end
    model.CurrentUiEquipEffectId = id
    model.UiEquipEffect = self:ClearUiEffectList(model.UiEquipEffect)
    local list = {}
    for rootName, effectPathList in pairs(rootName2EffectPath or {}) do
        for _, effectPath in ipairs(effectPathList or {}) do
            table.insert(list, self:CreateUiEffect(model, id, rootName, effectPath))
        end
    end
    model.UiEquipEffect = list
    
    return list
end
--==============================--
--desc: 生成Ui角色动作特效
--==============================--
function XUiPanelRoleModel:CreateUiEffect(model, id, rootName, effectPath)
    local parent  -- 搜挂点
    if not rootName or rootName == XCharacterUiEffectConfig.GetDefaultRootName() then
        parent = model.Model.gameObject
    else
        parent = model.Model.gameObject:FindGameObject(rootName)
        if not parent then
            parent = model.Model.gameObject
        end
    end
    local obj = CS.LoadHelper.InstantiateGameObject(effectPath)
    obj.transform:SetParent(parent.transform, false)
    obj.transform:SetLayerRecursively(parent.gameObject.layer)
    --local fx = parent:LoadPrefab(effectPath, false)
    -- 由于预制是在模型加载之后，需要再次添加阴影
    if self.ShowShadow then
        CS.XShadowHelper.AddShadow(obj.gameObject, true)
    end
    -- 只有不是三个模型同时出现的界面调用此接口 由于预制是在模型加载之后，需要再次添加阴影
    if not self.FixLight then
        CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
    end
    return obj
end

--动作播放完重新播放特效
function XUiPanelRoleModel:SetReActiveUiEffect(model)
    --local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if XTool.IsTableEmpty(model.UiEffect)
            and XTool.IsTableEmpty(model.UiEquipEffect) --[[or not playRoleAnimation]] then
        return
    end

    self:SetUiStandAnimaFinishCallback(model.Model, function()
        for _, effect in ipairs(model.UiEffect or {}) do
            if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
                effect.gameObject:SetActiveEx(false)
                effect.gameObject:SetActiveEx(true)
            end
        end

        for _, effect in ipairs(model.UiEquipEffect or {}) do
            if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
                effect.gameObject:SetActiveEx(false)
                effect.gameObject:SetActiveEx(true)
            end
        end
    end, nil, false, false)
    --playRoleAnimation:SetIsNotRemoveFinishCallback(true)
    --playRoleAnimation:SetFinishedCallback(function()
    --    for _, effect in ipairs(effectList or {}) do
    --        if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
    --            effect.gameObject:SetActiveEx(false)
    --            effect.gameObject:SetActiveEx(true)
    --        end
    --    end
    --end)
end

function XUiPanelRoleModel:SetCurrentUiEffectActive(effectList, isActive)
    if XTool.IsTableEmpty(effectList) then
        return
    end
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(isActive)
        end
    end
end

function XUiPanelRoleModel:ClearUiEffectList(effectList)
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            XUiHelper.Destroy(effect)
        end
    end
    return {}
end

function XUiPanelRoleModel:GetValidEffect(effectList)
    local list = {}
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            table.insert(list, effect)
        end
    end
    return list
end

--endregion------------------------------------加载Ui角色动作特效end---------------------------
--==============================--
--desc: 更新角色模型
--@characterId: 角色id
--@targetPanelRole: 目标面板
--@targetUiName: 目标ui名
--==============================--
function XUiPanelRoleModel:UpdateCharacterModel(
characterId,
targetPanelRole,
targetUiName,
cb,
weaponCb,
fashionId,
growUpLevel,
hideEffect,
isShowDefaultWeapon,
isNotSelf)
    self.StandAnimaShowWeaponList = {}
    
    local weaponFashionId

    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    local resourcesId
    if XTool.IsNumberValid(fashionId) then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
        self.NowFashionId = fashionId
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
        self.NowFashionId = XDataCenter.FashionManager.GetFashionIdByResId(resourcesId)
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
    
    self.IsStandAnimaShowWeapon = XDataCenter.EquipManager.CheckHasLoadEquipBySignboard(characterId, self.NowFashionId)
    self:SetCueId(self.NowFashionId)
    
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, 
            function(model)
                if not self.HideWeapon then
                    self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, hideEffect, nil, weaponFashionId, isShowDefaultWeapon) --- todo  cur equip
                end

                if self.IsStandAnimaShowWeapon and self.HideWeapon then
                    local equipUsage = XDataCenter.EquipManager.GetEquipAnimControllerBySignboard(characterId, self.NowFashionId)
                    local newCb = function(model)
                        self.StandAnimaShowWeaponList[#self.StandAnimaShowWeaponList + 1] = model
                        
                        if weaponCb then
                            weaponCb(model)
                        end
                    end
                    
                    self:UpdateCharacterWeaponModels(characterId, modelName, newCb, hideEffect, nil, weaponFashionId, isShowDefaultWeapon, equipUsage)
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
    local actionId = self:GetPlayingStateName(AnimeLayer.Body)
    self:LoadCharacterUiEffect(tonumber(characterId), actionId, isNotSelf, weaponFashionId, isShowDefaultWeapon)
end

---将callback保存在列表中，在执行回调时遍历callback列表
---@param model UnityEngine.GameObject 角色模型
---@param callback function 回调函数
---@param disableCallback function 模型销毁的回调
---@param isOnce boolean 是否只执行一次
---@param isInstantExecute boolean 是否立即执行
function XUiPanelRoleModel:SetUiStandAnimaFinishCallback(model, callback, disableCallback, isOnce, isInstantExecute)
    isOnce = isOnce or false
    isInstantExecute = isInstantExecute or false
    self.UiStandCallBack[#self.UiStandCallBack + 1] = { Callback = callback, IsOnce = isOnce }

    local playAnima = model.gameObject:GetComponent(typeof(CS.XPlayRoleAnimation))

    if not playAnima then
        return
    end

    if isInstantExecute then
        callback()
    end
    
    playAnima:SetIsNotRemoveFinishCallback(true)
    playAnima:SetFinishedCallback(function()
        for i = #self.UiStandCallBack, 1, -1  do
            local funcData = self.UiStandCallBack[i]
            local callbackFunc = funcData.Callback
            local isOnlyOnce = funcData.IsOnce

            callbackFunc()

            if isOnlyOnce then
                table.remove(self.UiStandCallBack, i)
            end
        end 
    end)
    if disableCallback ~= nil then
        playAnima:SetDisableCallback(disableCallback)
    end
end

function XUiPanelRoleModel:SetCueId(fashionId)
    if not fashionId then
        return
    end
    self.UiStandCallBack = {}    
    self.CueId = XDataCenter.FashionManager.GetCueIdByFashionId(fashionId)
end

--==============================--
--desc: 在查看其他玩家信息时，更新角色模型
--==============================--
function XUiPanelRoleModel:UpdateCharacterModelOther(
character,
weapon,
weaponFashionId,
targetPanelRole,
targetUiName,
cb)
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
    self:UpdateRoleModel(
    modelName,
    targetPanelRole,
    targetUiName,
    function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModelsOther(character, weapon, weaponFashionId, modelName)
        end

        local fashionId = character.FashionId or XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
        self:UpdateCharacterLiberationLevelEffect(modelName, characterId, character.LiberateLv, fashionId)

        if cb then
            cb(model)
        end

        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end
    )
    self:LoadCharacterUiEffectOther(character, nil, weapon, weaponFashionId)
end

function XUiPanelRoleModel:LoadCharacterUiEffectOther(character, actionId, weapon, weaponFashionId)
    if not character then
        return
    end
    local fashionId = character.FashionId or XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(character.Id, fashionId, actionId)
    local model = self.RoleModelPool[self.CurRoleName]

    if not model.CharacterId then
        model.CharacterId = character.Id
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
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
    if not actionId and model.NotUiStand1 then
        return
    end
    if not actionId then
        model.UiDefaultId = id
    end
    self:LoadCharacterUiEquipEffectOther(model, weapon, fashionId, actionId, weaponFashionId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end

--==============================--
--desc: 更新机器人角色模型
--==============================--
function XUiPanelRoleModel:UpdateRobotModel(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController
    , targetPanelRole, targetUiName)
    local resourcesId
    local nowFashionId
    if fashionId then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
        nowFashionId = fashionId
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
        nowFashionId = XDataCenter.FashionManager.GetFashionIdByResId(resourcesId)
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
    targetUiName = targetUiName or self.RefName
    local weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    
    self:SetCueId(nowFashionId)
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, true, equipTemplateId, weaponFashionId)
        end
        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end, nil, needDisplayController)
    
    self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId, nil, equipTemplateId)
end

--==============================--
--desc: 更新机器人角色模型 可以根据UseFashion使用角色涂装和角色武器涂装
--==============================--
function XUiPanelRoleModel:UpdateRobotModelNew(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
    local weaponFashionId
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        local robot2CharViewModel = character:GetCharacterViewModel()
        fashionId = robot2CharViewModel:GetFashionId()
        weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    else
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    self:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
end

--==============================--
--desc: 更新机器人角色模型 可以手动设置角色武器。武器涂装以机器人优先
--==============================--
function XUiPanelRoleModel:UpdateRobotModelWithWeapon(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
    local weaponFashionId
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        local robot2CharViewModel = character:GetCharacterViewModel()
        fashionId = robot2CharViewModel:GetFashionId()
        weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    else
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    if not XTool.IsNumberValid(weaponFashionId) then
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end
    
    self:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
end

--==============================--
--desc: 更新机器人角色模型 模型新显示逻辑的公共部分
--==============================--
function XUiPanelRoleModel:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
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
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, true, equipTemplateId, weaponFashionId)
        end
        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end, nil, needDisplayController)

    self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId, nil, equipTemplateId)
end

function XUiPanelRoleModel:UpdateCharacterResModel(resId, characterId, targetUiName, cb, growUpLevel, weaponFashionId)
    local modelName = XDataCenter.CharacterManager.GetCharResModel(resId)
    local fashionId = XDataCenter.FashionManager.GetFashionIdByResId(resId)
    
    if modelName then
        self:SetCueId(fashionId)
        self:UpdateRoleModel(modelName, nil, targetUiName, function(model)
            if not self.HideWeapon then
                self:UpdateCharacterWeaponModels(characterId, modelName, nil, nil, nil, weaponFashionId)
            end
            
            self:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId)

            if cb then
                cb(model)
            end
        end
        )
    end
    if fashionId then
        self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId)
    end
end

function XUiPanelRoleModel:UpdateCharacterModelByModelId(
modelId,
characterId,
targetPanelRole,
targetUiName,
cb,
growUpLevel,
showDefaultFx)
    if not modelId then
        return
    end
    
    self:UpdateRoleModel(modelId, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelId)
        end
        
        self:UpdateCharacterLiberationLevelEffect(modelId, characterId, growUpLevel, nil, showDefaultFx)

        if cb then
            cb(model)
        end
    end)
    
    local defaultFashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local fashionId
    if growUpLevel == 2 then --growUpLevel 2为第一套解放衣服 3，4为第二套解放衣服，解放的时装Id跟默认时装Id紧挨且按顺序+1
        fashionId = defaultFashionId + 1
    elseif growUpLevel >= 3 then
        fashionId = defaultFashionId + 2
    end

    local allFashionConfig = XFashionConfigs.GetFashionTemplates()
    if not fashionId or not allFashionConfig[fashionId] then
        fashionId = defaultFashionId
    end
    if fashionId then
        self:LoadResCharacterUiEffect(characterId, fashionId)
    end
end

function XUiPanelRoleModel:UpdateBossModel(modelName, targetUiName, targetPanelRole, cb, isReLoad)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
        end,
        true
        )
    end
end

function XUiPanelRoleModel:UpdateArchiveMonsterModel(modelName, targetUiName, targetPanelRole, cb)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
        end,
        true
        )
    end
end

local DoPartnerModelControl = function(modelName, model) -- 加载伙伴模型时同时加载“模型节点控制”配置
    local modelControlList = XPartnerConfigs.GetPartnerModelControlsByModel(modelName)
    if modelControlList then
        for nodeName, modelControl in pairs(modelControlList) do
            local parts
            if nodeName == XPartnerConfigs.DefaultNodeName then
                parts = model.transform
            else
                parts = model.gameObject:FindTransform(nodeName)
            end
            if not XTool.UObjIsNil(parts) then
                if modelControl.IsHide and modelControl.IsHide == 1 then
                    parts.gameObject:SetActiveEx(false)
                end
                if modelControl.Effect and not string.IsNilOrEmpty(modelControl.Effect) then
                    local effect = parts.gameObject:LoadPrefab(modelControl.Effect, false)
                    if effect then
                        effect.gameObject:SetActiveEx(true)
                    end
                end
            else
                XLog.Error("NodeName Is Wrong :" .. nodeName)
            end
        end
    end
end

function XUiPanelRoleModel:UpdatePartnerModel(
modelName,
targetUiName,
targetPanelRole,
cb,
isReLoad,
needController,
IsReLoadController)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
            self:LoadPartnerUiEffect(modelName, XPartnerConfigs.EffectParentName.ModelLoopEffect, false, false)
            --DoPartnerModelControl(modelName, model)
        end,
        isReLoad,
        needController,
        IsReLoadController
        )
    end
end

function XUiPanelRoleModel:UpdateSCBattleShowModel(
modelName,
weaponIdList,
targetUiName,
targetPanelRole,
cb,
isReLoad,
needController,
IsReLoadController)
    if modelName then
        self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model) 
            if cb then
                cb(model)
            end
            XModelManager.LoadRoleWeaponModel(model, weaponIdList, 
                    self.RefName, nil, false, self.GameObject, modelName)
        end, isReLoad, false, IsReLoadController, needController)
    end
end

function XUiPanelRoleModel:UpdateCharacterModelByFightNpcData(fightNpcData, cb, isCute, needDisplayController, customizeWeaponData, isSelfPlayer)
    local char = fightNpcData.Character
    if char then
        if isSelfPlayer then
            local charId = char.Id
            local tempChar = XMVCA.XCharacter:GetCharacter(charId)
            if tempChar then
                char = tempChar
            end
        end

        local modelName
        local fashionId = char.FashionId
        if isCute then
            modelName = XCharacterCuteConfig.GetCuteModelModelName(char.Id)
        elseif fashionId then
            local fashion = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
            modelName = XDataCenter.CharacterManager.GetCharResModel(fashion.ResourcesId)
        else
            -- modelName = XDataCenter.CharacterManager.GetCharModel(char.Id, char.Quality)
            modelName = self:GetModelName(char.Id)
        end

        if modelName then
            self:SetCueId(fashionId)
            self:UpdateRoleModel(modelName, nil, nil, function(model)
                self:UpdateEquipsModelsByFightNpcData(model, fightNpcData, modelName)
                self:UpdateCharacterLiberationLevelEffect(modelName, char.Id, char.LiberateLv, fashionId)
                if cb then
                    cb(model)
                end
                if isCute then
                    self:CloseRootMotion(model)
                end
            end,nil, needDisplayController)
        end
        
        if isCute then
            self:LoadCharacterCuteUiEffect(char.Id)
        elseif customizeWeaponData then
            self:LoadResCharacterUiEffect(char.Id, fashionId, fightNpcData.WeaponFashionId, nil, fightNpcData.Equips[1].TemplateId)
        else
            self:LoadResCharacterUiEffect(char.Id, fashionId)
        end
    end
end

function XUiPanelRoleModel:UpdateEquipsModelsByFightNpcData(charModel, fightNpcData, modelName)
    local weaponModelList = {}
    local tempWeaponCb = function(weaponModel)
        weaponModelList[#weaponModelList + 1] = weaponModel
    end
    XModelManager.LoadRoleWeaponModelByFight(charModel, fightNpcData, self.RefName, self.GameObject, modelName, tempWeaponCb)
    self:WeaponAnimationSync(weaponModelList, modelName)
end

--==============================--
--desc: 更新角色武器模型
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModels(
characterId,
modelName,
weaponCb,
hideEffect,
equipTemplateId,
weaponFashionId,
isShowDefaultWeapon,
equipUsage)
    local equipModelIdList = {}
    
    if equipTemplateId then
        local equip = { TemplateId = equipTemplateId }
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    else
        equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByCharacterId(characterId, isShowDefaultWeapon, weaponFashionId)
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

    local weaponModelList = {}
    local tempWeaponCb = function(weaponModel)
        weaponModelList[#weaponModelList + 1] = weaponModel
        if weaponCb then
            weaponCb(weaponModel)
        end
    end

    XModelManager.LoadRoleWeaponModel(
    roleModel.Model,
    equipModelIdList,
    self.RefName,
    tempWeaponCb,
    hideEffect,
    self.GameObject,
    modelName,
    equipUsage        
    )

    self:WeaponAnimationSync(weaponModelList, modelName)
end

--==============================--
--desc: 查看其他玩家角色信息时，更新角色武器模型
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModelsOther(
characterId,
equip,
weaponFashionId,
modelName,
weaponCb,
hideEffect)
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
    XModelManager.LoadRoleWeaponModel(
    roleModel.Model,
    equipModelIdList,
    self.RefName,
    weaponCb,
    hideEffect,
    self.GameObject,
    modelName
    )
end

---=================================================
--- 在当前播放中的动画播放完后执行回调
--- 如果动画被打断或是停止都会调用回调
---@overload fun(callBack:function)
---@param callBack function
---=================================================
local CheckAnimeFinish = function(animator, behaviour, animaName, callBack, layer)
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(layer)
    if (animatorInfo:IsName(animaName) and animatorInfo.normalizedTime >= 1) or not animatorInfo:IsName(animaName) then --normalizedTime的值为0~1，0为开始，1为结束。
        if callBack then
            callBack()
        end
        behaviour.enabled = false
    end
end

local AddPlayingAnimCallBack = function(obj, animator, animaName, callBack, layer)
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(layer)

    if not animatorInfo:IsName(animaName) or animatorInfo.normalizedTime >= 1 then --normalizedTime的值，0为开始，大于1为结束。
        return
    end

    local behaviour = obj.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = obj.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end

    behaviour.LuaUpdate = function()
        CheckAnimeFinish(animator, behaviour, animaName, callBack, layer)
    end
end
---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---@param layer number 状态机层级
---=================================================
function XUiPanelRoleModel:PlayAnima(AnimaName, fromBegin, callBack, errorCb, layer)
    local animatorlaye = layer or 0
    local IsCanPlay, animator = self:CheckAnimaCanPlay(AnimaName)
    local delay = 1
    
    if IsCanPlay and animator then
        if fromBegin then
            animator:Play(AnimaName, animatorlaye, 0)
        else
            animator:Play(AnimaName, animatorlaye)
        end

        self.AnimaPlayedCallBackList = {}
        --根据当前角色动画判断躯干显隐
        local hideNodeFunc = self:HideOrShowModelWithAction(AnimaName)
        local loadWeaponFunc = self:PlayWeaponAnima(AnimaName)
        if callBack then
            self:AddPlayedAnimCallBack(callBack)
        end

        local callBackList = self.AnimaPlayedCallBackList
        XScheduleManager.ScheduleOnce(function()
            if loadWeaponFunc then
                loadWeaponFunc()
            end
            if hideNodeFunc then
                hideNodeFunc()
            end
            if callBackList and #callBackList ~= 0 then
                AddPlayingAnimCallBack(self, animator, AnimaName, function()
                    for i = 1, #callBackList do
                        if callBackList[i] then
                            callBackList[i]()
                        end
                    end
                end, animatorlaye)
            end
        end, delay)
    else
        if errorCb then
            errorCb()
        end
    end
    return IsCanPlay
end

---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---@param layer number 状态机层级
---=================================================
function XUiPanelRoleModel:PlayAnimaCross(AnimaName, fromBegin, callBack, errorCb, layer)
    local animatorlaye = layer or 0
    local IsCanPlay, animator = self:CheckAnimaCanPlay(AnimaName)
    
    if IsCanPlay and animator then
        local delay = 0.25
        
        if fromBegin then
            --animator:Play(AnimaName, animatorlaye, 0)
            animator:CrossFadeInFixedTime(AnimaName, delay, animatorlaye, 0)
        else
            animator:CrossFadeInFixedTime(AnimaName, delay, animatorlaye)
            --animator:Play(AnimaName, animatorlaye)
        end
        
        self.AnimaPlayedCallBackList = {}
        --根据当前角色动画判断躯干显隐
        local hideNodeFunc = self:HideOrShowModelWithAction(AnimaName)
        local loadWeaponFunc = self:PlayWeaponAnima(AnimaName)
        if callBack then
            self:AddPlayedAnimCallBack(callBack)
        end
        
        local callBackList = self.AnimaPlayedCallBackList
        XScheduleManager.ScheduleOnce(function()
            if loadWeaponFunc then
                loadWeaponFunc()
            end
            if hideNodeFunc then
                hideNodeFunc()
            end
            if callBackList and #callBackList ~= 0 then
                AddPlayingAnimCallBack(self, animator, AnimaName, function()
                    for i = 1, #callBackList do
                        if callBackList[i] then
                            callBackList[i]()
                        end
                    end
                end, animatorlaye)
            end
        end, delay * XScheduleManager.SECOND + 1)
    else
        if errorCb then
            errorCb()
        end
    end
    return IsCanPlay
end

function XUiPanelRoleModel:HideOrShowModelWithAction(animaName)
    if not self.CurRoleName then
        return
    end
    
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then
        return
    end
    
    local model = modelInfo.Model
    local modelName = self.CurRoleName
    if not model or not modelName then
        return 
    end

    local isStandAnimaHide = self.IsStandAnimaHideNode
    local isHide = XModelManager.CheckUiModelNodeActive(animaName, modelName, model)
    local playCallback = nil
    local hideNodeFunc = function()
        if isStandAnimaHide then
            XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, true)
        end
        XModelManager.HandleUiModelNodeActive(animaName, modelName, model, false)
    end
    
    if isHide then
        if isStandAnimaHide then
            playCallback = function()
                RestoreModelNode(model, modelName, animaName)
                XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, false)
            end
        else
            playCallback = function()
                RestoreModelNode(model, modelName, animaName)
            end
        end
    else
        if isStandAnimaHide then
            playCallback = function()
                XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, false)
            end
        end
    end

    if playCallback then
        self:AddPlayedAnimCallBack(playCallback)
    end
    
    return hideNodeFunc
end

function XUiPanelRoleModel:AddPlayedAnimCallBack(callback)
    if callback then
        self.AnimaPlayedCallBackList[#self.AnimaPlayedCallBackList + 1] = callback
    end
end

function XUiPanelRoleModel:PlayWeaponAnima(actionId)
    local weaponModelList = self.StandAnimaShowWeaponList
    local isStandAnimaShowWeapon = self.IsStandAnimaShowWeapon
    local animaCallback = function()
        if weaponModelList then
            for i = 1, #weaponModelList do
                weaponModelList[i].gameObject:SetActiveEx(isStandAnimaShowWeapon)
            end
        end
    end

    if not isStandAnimaShowWeapon then
        weaponModelList = self:LoadWeaponModelWhenPlayAnima(actionId)

        if weaponModelList then
            local callback = function()
                for i = 1, #weaponModelList do
                    weaponModelList[i].gameObject:SetActiveEx(true)
                end
            end

            self:AddPlayedAnimCallBack(animaCallback)
            return callback
        end
    end
    
    if not self:CheckHasLoadEquipWhenPlayAnima(actionId) and isStandAnimaShowWeapon then
        local callback = function()
            for i = 1, #self.StandAnimaShowWeaponList do
                self.StandAnimaShowWeaponList[i].gameObject:SetActiveEx(false)
            end
        end

        self:AddPlayedAnimCallBack(animaCallback)
        return callback
    end
end

function XUiPanelRoleModel:CheckHasLoadEquipWhenPlayAnima(actionId)
    local modelName = self.CurRoleName

    if not modelName then
        return false
    end
    
    local characterId = self.RoleModelPool[modelName].CharacterId

    if not characterId then
        return false
    end

    local fashionId = self.NowFashionId or XDataCenter.CharacterManager.GetShowFashionId(characterId)

    if not fashionId then
        return false
    end
    
    return XDataCenter.EquipManager.CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
end

function XUiPanelRoleModel:LoadWeaponModelWhenPlayAnima(actionId)
    local modelName = self.CurRoleName

    if not modelName then
        return
    end
    
    local characterId = self.RoleModelPool[modelName].CharacterId
    
    if not characterId then
        return 
    end
    
    local weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local roleModel = self.RoleModelPool[modelName].Model
    local equipModelIdList = {}
    local equipUsage = nil
    local weaponModelList = {}
    local weaponCb = function(model)
        weaponModelList[#weaponModelList + 1] = model
    end

    equipModelIdList = XDataCenter.EquipManager.GetEquipModelIdListByCharacterId(characterId, false, weaponFashionId)
    equipUsage = XDataCenter.EquipManager.GetEquipAnimControllerBySignboard(characterId, self.NowFashionId, actionId)
    --equipUsage = 1

    if not equipModelIdList or not next(equipModelIdList) or not roleModel or not equipUsage then
        return
    end
    
    XModelManager.LoadRoleWeaponModel(roleModel, equipModelIdList, self.RefName, weaponCb, false, self.GameObject, modelName, equipUsage)
    
    return weaponModelList
end

---=================================================
--- 播放身体动画（状态机层级0）
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---=================================================
function XUiPanelRoleModel:PlayBodyAnima(AnimaName, fromBegin, callBack, errorCb)
    self:PlayAnima(AnimaName, fromBegin, callBack, errorCb, AnimeLayer.Body)
end

---=================================================
--- 播放表情动画（状态机层级1）
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---=================================================
function XUiPanelRoleModel:PlayFaceAnima(AnimaName, fromBegin, callBack, errorCb)
    self:PlayAnima(AnimaName, fromBegin, callBack, errorCb, AnimeLayer.Face)
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
function XUiPanelRoleModel:StopAnima(oriAnima, force)

    local animator = self.RoleModelPool[self.CurRoleName].Model:GetComponent("Animator")
    local clips = animator:GetCurrentAnimatorClipInfo(0)
    local clip
    if clips and clips.Length > 0 then
        clip = clips[0].clip
    end


    -- 是否需要播放动作打断特效
    if self.PlayEffectFunc then
        self.PlayEffectFunc()
    end

    if force and clip or oriAnima == nil or (clip and clip.name == oriAnima) then
        -- 停止UI特效
        self.CurrentAnimationName = nil
        local model = self.RoleModelPool[self.CurRoleName]
        self:SetCurrentUiEffectActive(model.UiEffect, false)
        self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
        animator:Play(clip.name, 0, 0.999)
    end
end

---@return UnityEngine.Animator
function XUiPanelRoleModel:GetAnimator()
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then
        return nil
    end
    if not XTool.UObjIsNil(model.Model) then
        return model.Model:GetComponent("Animator")
    else
        return nil
    end
end

function XUiPanelRoleModel:GetComponent(componentType)
    if self.RoleModelPool[self.CurRoleName] then
        return self.RoleModelPool[self.CurRoleName].Model:GetComponent(componentType)
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

function XUiPanelRoleModel:SetModelZeroPos()
    local model = self.RoleModelPool[self.CurRoleName].Model
    if not model then return end
    
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
end

--- 获取正在播放动画名
---@param layerIndex number 状态机层级
---@return string
--------------------------
function XUiPanelRoleModel:GetPlayingStateName(layerIndex)
    local animator = self:GetAnimator()
    if XTool.UObjIsNil(animator) then
        return
    end

    if XTool.UObjIsNil(animator.runtimeAnimatorController) then
        return
    end
    
    local actionId
    local clips = animator.runtimeAnimatorController.animationClips
    local info = animator:GetCurrentAnimatorStateInfo(layerIndex)
    for i = 0, clips.Length - 1 do
        local clip = clips[i]
        if info:IsName(clip.name) then
            actionId = clip.name
            break
        end
    end
    return actionId
end

--==============================--
--desc: 更新角色解放特效
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect(
modelName,
characterId,
growUpLevel,
fashionId,
showDefaultFx)
    local modelInfo
    local isSpecialModel, _ = XModelManager.CheckModelIsSpecial(modelName)
    if isSpecialModel then
        if self.NewPanel then
            modelName = XModelManager.GetMinorModelId(modelName)
            modelInfo = modelName and self.NewPanel.RoleModelPool[modelName]
        else
            modelName = XModelManager.GetSpecialModelId(modelName)
            modelInfo = self.RoleModelPool[modelName]
        end
    else
        modelInfo = self.RoleModelPool[modelName]
    end
    local model = modelInfo and modelInfo.Model
    if not model then
        return
    end

    local liberationFx = modelInfo.LiberationFx

    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    local rootName, fxPath, aureoleId
    if showDefaultFx then
        --通过解放等级获取默认解放特效配置
        rootName, fxPath =        XDataCenter.CharacterManager.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    else
        -- 1.如果没有通过超解自定义手环
        --通过角色Id获取时装对应解放特效配置
        rootName, fxPath =        XDataCenter.CharacterManager.GetCharFashionLiberationEffectRootAndPath(characterId, growUpLevel, fashionId)
        aureoleId = character and XFashionConfigs.GetFashionCfgById(fashionId or character.FashionId).AureoleId
        fxPath = XFashionConfigs.GetAureoleEffectPathById(aureoleId)
        -- 2.如果有自定义手环
        local currLiberateAureoleId = character and character.LiberateAureoleId
        if XTool.IsNumberValid(currLiberateAureoleId) then
            fxPath = XFashionConfigs.GetAureoleEffectPathById(currLiberateAureoleId)
            liberationFx = nil -- 销毁替换之前的 刷新终解环
        end 
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
            XLog.Error(
            "XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect Error:can Not find rootTransform in this model, rootName is:" ..
            rootName
            )
            return
        end
        modelInfo.LiberationFx = rootTransform.gameObject:LoadPrefab(fxPath, false)
        modelInfo.AureoleId = aureoleId
        -- self:FixAurolePos(modelInfo.LiberationFx, characterId, modelInfo)
    else
        liberationFx:SetActiveEx(true)
    end
end

-- 给外部切换终解特效的接口
function XUiPanelRoleModel:SetLiberationEffect(modelName, rootName, aureoleId, characterId)
    if not aureoleId then
        return
    end

    local modelInfo
    local isSpecialModel, _ = XModelManager.CheckModelIsSpecial(modelName)
    if isSpecialModel then
        if self.NewPanel then
            modelName = XModelManager.GetMinorModelId(modelName)
            modelInfo = modelName and self.NewPanel.RoleModelPool[modelName]
        else
            modelName = XModelManager.GetSpecialModelId(modelName)
            modelInfo = self.RoleModelPool[modelName]
        end
    else
        modelInfo = self.RoleModelPool[modelName]
    end
    local model = modelInfo and modelInfo.Model
    local rootTransform = model.transform:FindTransform(rootName)

    local effectPath = XFashionConfigs.GetAureoleEffectPathById(aureoleId)
    modelInfo.LiberationFx = rootTransform.gameObject:LoadPrefab(effectPath, false)
    if modelInfo.LiberationFx then
        modelInfo.LiberationFx:SetActiveEx(true)
        modelInfo.AureoleId = aureoleId
        -- self:FixAurolePos(modelInfo.LiberationFx, characterId, modelInfo)
    end
end

-- 由于2.0版本 新增同一角色可佩戴不同角色的手环，需要进行位置修正
function XUiPanelRoleModel:FixAurolePos(auroeTrans, characterId, modelInfo)
    local defaultFashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local aureoleId = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)[defaultFashionId].AureoleId
    local aureoleConfig = aureoleId and XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.FashionAureole)[aureoleId]

    local tempEffectGo = nil
    local resource = nil
    if modelInfo.TempEffectGo then
        tempEffectGo = modelInfo.TempEffectGo
    else
        resource = CS.XResourceManager.Load(aureoleConfig.EffectPath)
        tempEffectGo = CS.UnityEngine.Object.Instantiate(resource.Asset, auroeTrans.transform.parent)
    end
    local tempTrans = tempEffectGo.transform:GetChild(0)
    
    -- 第一子物体同步
    local targetFixTrans = auroeTrans.transform:GetChild(0)
    local tempGoPostition = tempTrans.localPosition
    local tempGoRotation = tempTrans.localEulerAngles
    local targetPos = CS.UnityEngine.Vector3(tempGoPostition.x, tempGoPostition.y, 0)
    local targetRotation = CS.UnityEngine.Vector3(tempGoRotation.x, tempGoRotation.y, tempGoRotation.z)
    targetFixTrans.localPosition = targetPos
    targetFixTrans.localEulerAngles = targetRotation

    tempEffectGo:SetActiveEx(false)
    tempEffectGo.name = "TempAuroe"
    modelInfo.TempEffectGo = tempEffectGo

    if resource then
        CS.XResourceManager.Unload(resource)
    end
end

---=================================================
--- 材质控制器相关特效需要跟模型绑定
---@param effect UnityEngine.GameObject
---=================================================
function XUiPanelRoleModel:BindEffect(effect)
    if XTool.UObjIsNil(effect) then
        return
    end
    if self.CurRoleName and self.RoleModelPool[self.CurRoleName] and self.RoleModelPool[self.CurRoleName].RenderingProxy then
        self.RoleModelPool[self.CurRoleName].RenderingProxy:BindEffect(effect)
        effect.gameObject:SetActiveEx(false)
        effect.gameObject:SetActiveEx(true)
    end
end

function XUiPanelRoleModel:BindEffectByModel(model)
    if model.UiEffect then
        for i = 1, #model.UiEffect do
            self:BindEffect(model.UiEffect[i])
        end
    end
    
    if model.UiEquipEffect then
        for i = 1, #model.UiEquipEffect do
            self:BindEffect(model.UiEquipEffect[i])
        end
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
---@param effectPath string 特效路径
---@param isBindEffect boolean 材质控制器相关特效和模型绑定
---=================================================
function XUiPanelRoleModel:LoopLoadEffect(effectPath, isBindEffect)
    if not effectPath then
        return
    end
    if isBindEffect == nil then
        isBindEffect = false
    end
    if self.EffectMaxCount == nil then
        self.EffectMaxCount = 1
    end
    if self.EffectingIndex == nil then
        self.EffectingIndex = 0
    end

    local effectParentKey = self.EffectingIndex % self.EffectMaxCount
    self:LoadEffect(effectPath, effectParentKey, isBindEffect, false)
    self.EffectingIndex = self.EffectingIndex + 1
end

local CreateEffectParentName = function(name)
    return name and string.format("Customize_%s", name) or "Default_EffectParent"
end

---=================================================
---根据PartnerUiEffect加载辅助机特效
---@param modelName string 辅助机模型名字(来自【PartnerModel.tab】StandbyModel/CombatModel字段)
---@param effectParentName string 生成一个前缀Customize_+ effectParentName的节点,特效将挂载在其下。(XPartnerConfigs.EffectParentName枚举)
---@param isBindEffect boolean|nil 材质控制器相关特效和模型绑定
---@param isDisableOldEffect boolean|nil 为true时UnActive指定节点名下挂载的特效
---@param isUseModelParent boolean|nil 为true时该特效节点挂载在模型下
---=================================================
function XUiPanelRoleModel:LoadPartnerUiEffect(modelName, effectParentName, isBindEffect, isDisableOldEffect, isUseModelParent)
    if isDisableOldEffect then
        self:HideEffectByParentName(effectParentName)
    end

    if not modelName then
        return
    end

    if isBindEffect == nil then
        isBindEffect = false
    end

    self.EffectParentDic = self.EffectParentDic or {}
    self.EffectDic = self.EffectDic or {}

    local parentName = CreateEffectParentName(effectParentName)

    if isUseModelParent then
        parentName = modelName .. parentName
    end
    
    local effectInfo = XDataCenter.PartnerManager.GetPartnerUiEffect(modelName, effectParentName)
    local curModelInfo = self:GetModelInfoByName(self.CurRoleName)
    local effectParent = self.EffectParentDic[parentName]

    if not effectInfo then
        return 
    end

    if not curModelInfo or XTool.UObjIsNil(curModelInfo.Model) then
        XLog.Error("获取模型失败!请检查模型是否加载成功!")
        return
    end

    if effectInfo.BoneRootName then
        local node = curModelInfo.Model.transform:FindTransform(effectInfo.BoneRootName)

        if XTool.UObjIsNil(node) then
            XLog.Error("找不到同名骨骼!骨骼名:" .. effectInfo.BoneRootName)
            return
        end
        
        effectParent = node:FindTransform(parentName)

        if XTool.UObjIsNil(effectParent) then
            effectParent = CS.UnityEngine.GameObject(tostring(parentName))
            effectParent.transform:SetParent(node, false)
        end
    else
        if not effectParent or XTool.UObjIsNil(effectParent) then
            local parentTransform = nil
            
            if isUseModelParent or effectParentName == XPartnerConfigs.EffectParentName.ModelLoopEffect then
                parentTransform = curModelInfo.Model.transform
            else
                parentTransform = self.Transform
            end

            effectParent = CS.UnityEngine.GameObject(tostring(parentName))
            effectParent.transform:SetParent(parentTransform, false)
            self.EffectParentDic[parentName] = effectParent
        end
    end
    
    for i, effectPath in pairs(effectInfo.EffectPath) do
        local effectNode = effectParent.transform:FindTransform(effectParentName .. i)
        local effect = nil

        if not effectNode or XTool.UObjIsNil(effectNode) then
            effectNode = CS.UnityEngine.GameObject(effectParentName .. i)
            effectNode.transform:SetParent(effectParent.transform, false)
        end
        
        effect = effectNode:LoadPrefab(effectPath)
        self.EffectDic[parentName] = self.EffectDic[parentName] or {}
        self.EffectDic[parentName][effectPath] = effect

        if effect == nil or XTool.UObjIsNil(effect) then
            XLog.Error("加载的特效为空! 路径：" .. effectPath)
            return
        end

        if isBindEffect then
            self:BindEffect(effect)
        end

        effectNode.gameObject:SetActiveEx(false)
        effectNode.gameObject:SetActiveEx(true)
    end
end

---=================================================
---生成指定名称的父节点并在其下加载特效
---@param effectPath string 特效路径
---@param effectParentName any 生成一个前缀Customize_+ effectParentName的节点,特效将挂载在其下。不指定时默认生成一个Default_EffectParent节点供挂载
---@param isBindEffect boolean|nil 材质控制器相关特效和模型绑定
---@param isDisableOldEffect boolean|nil 为true时UnActive指定节点名下挂载的特效
---@param isUseModelParent boolean|nil 为true时该特效节点挂载在模型下
---=================================================
function XUiPanelRoleModel:LoadEffect(effectPath, effectParentName, isBindEffect, isDisableOldEffect, isUseModelParent)
    if isDisableOldEffect then
        self:HideEffectByParentName(effectParentName)
    end

    if not effectPath then
        return
    end
    if isBindEffect == nil then
        isBindEffect = false
    end

    self.EffectParentDic = self.EffectParentDic or {}
    self.EffectDic = self.EffectDic or {}

    local parentName = CreateEffectParentName(effectParentName)
    local effectParent = self.EffectParentDic[parentName]

    if effectParent == nil then
        local curModelInfo = self:GetModelInfoByName(self.CurRoleName)
        local model
        if curModelInfo then
            model = curModelInfo.Model.transform
        end
        local parentTransform = isUseModelParent and model or self.Transform
        effectParent = CS.UnityEngine.GameObject(tostring(parentName))
        effectParent.transform:SetParent(parentTransform, false)
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

---读取特效节点
function XUiPanelRoleModel:GetEffectObj(effectParentName, effectPath)
    local parentName = CreateEffectParentName(effectParentName)
    if XTool.IsTableEmpty(self.EffectDic) or XTool.IsTableEmpty(self.EffectDic[parentName]) then return end
    return self.EffectDic[parentName][effectPath]
end

function XUiPanelRoleModel:HideEffectByParentName(effectParentName)
    if self.EffectDic == nil then
        return
    end
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

function XUiPanelRoleModel:RemoveRoleModelPool()
    local modelPool = self.RoleModelPool
    for _, modelInfo in pairs(modelPool or {}) do
        if modelInfo.Model and modelInfo.Model:Exist() then
            CS.UnityEngine.Object.Destroy(modelInfo.Model.gameObject)
        end
    end
    self.RoleModelPool = {}
end

function XUiPanelRoleModel:UpdateCuteModelWithoutUiEffect(robotId, isNotCuteUiEffect)
    self:UpdateCuteModel(robotId, nil, nil, nil, nil, nil,
            nil, nil, nil, isNotCuteUiEffect)
end

---=================================================
---更新Q版角色模型 参数都是复制自UpdateRobotModel
---希望以后统一通用接口,所以进行了二次封装并加上一定注解
---期待一个有缘人统一模型加载参数对象 by ljb
---@param robotId number|nil Robot.tab的robotId
---@param characterId number|nil Character.tab的characterId
---@param equipTemplateId number|nil Equip.tab的equipId
---@param weaponCb function|nil 武器模型加载后回调
---@param fashionId number|nil 模型皮肤id
---@param modelCb function|nil 武器模型加载后回调
---@param needDisplayController boolean
---@param targetPanelRole
---@param targetUiName
---=================================================
function XUiPanelRoleModel:UpdateCuteModel(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController
    , targetPanelRole, targetUiName, isNotCuteUiEffect)
    if not characterId then
        characterId = XRobotManager.GetCharacterId(robotId)
    end
    local modelName = XCharacterCuteConfig.GetCuteModelModelName(characterId)
    local weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    self:UpdateCuteModelByModelName(characterId, fashionId, equipTemplateId, weaponFashionId, weaponCb, modelName,
            modelCb, needDisplayController, targetPanelRole, targetUiName, isNotCuteUiEffect)
end

---=================================================
---更新Q版角色模型 UpdateCuteModel()的二次封装
---@param characterId number|nil
---@param fashionId number|nil
---@param equipTemplateId number|nil
---@param weaponFashionId number|nil
---@param weaponCb function|nil
---@param modelName string
---@param modelCb function|nil
---@param needDisplayController boolean
---@param targetPanelRole
---@param targetUiName
---=================================================
function XUiPanelRoleModel:UpdateCuteModelByModelName(characterId, fashionId, equipTemplateId, weaponFashionId, weaponCb, modelName
, modelCb, needDisplayController, targetPanelRole, targetUiName, isNotCuteUiEffect)
    if not modelName or modelName == "" then
        return
    end
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon and XTool.IsNumberValid(equipTemplateId) then
            self:UpdateCharacterWeaponModels(
                    characterId,
                    modelName,
                    weaponCb,
                    true,
                    equipTemplateId,
                    weaponFashionId
            )
        end

        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
        -- Q版模型禁止动画移动
        self:CloseRootMotion(model)
    end, nil, needDisplayController)

    if isNotCuteUiEffect then
        return
    end
    self:LoadCharacterCuteUiEffect(characterId)
end

-- 禁止动画根节点移动
function XUiPanelRoleModel:CloseRootMotion(model)
    local animator = model:GetComponent("Animator")
    animator.applyRootMotion = false                        
end

---=================================================
--- 播放'AnimaName'动画，融合过渡
---@overload fun(animaName:string)
---@param animaName string
---@param crossDuration number@两个动作的融合时长
---@param animatorLayer number@动画层
---=================================================
function XUiPanelRoleModel:CrossFadeAnim(animaName, crossDuration, animatorLayer)
    local IsCanPlay, animator = self:CheckAnimaCanPlay(animaName)
    if IsCanPlay and animator then
        animator:CrossFade(animaName, crossDuration or 0.2, animatorLayer or 0)
    end
    return IsCanPlay
end

function XUiPanelRoleModel:GetCurRoleName()
    return self.CurRoleName
end

---@param dataModel XDlcHuntModel
function XUiPanelRoleModel:UpdateDlcModel(dataModel, targetUiName, callback)
    local characterId = nil
    local weaponFashionId = nil
    local weaponId = dataModel:GetWeaponId()
    local modelName = dataModel:GetModelId()
    local fashionId = nil
    local targetPanelRole = nil
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
                if not weaponId then
                    if callback then callback() end
                    return
                end
                self:UpdateCharacterWeaponModels(characterId, modelName, callback, true, weaponId, weaponFashionId)
            end, nil, nil)
    self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId)
end

-- 开启/关闭头部跟随
function XUiPanelRoleModel:SetXPostFaicalControllerActive(flag)
    if not self.CurRoleName then
        return
    end
    
    local curModelInfo = self:GetModelInfoByName(self.CurRoleName)
    local model
    if curModelInfo then
        model = curModelInfo.Model.transform
    end
    
    if not model then
        return
    end
    
    local targetComponent = model:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end

    targetComponent.enabled = true
    targetComponent:ActiveInput(flag)
end

function XUiPanelRoleModel:SetLocalPosition(v3)
    if not self.CurRoleName then
        return
    end
    
    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.localPosition = v3
end

function XUiPanelRoleModel:SetLocalRotation(v3)
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.localEulerAngles = v3
end

function XUiPanelRoleModel:SetWorldPosition(v3)
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.position = v3
end

function XUiPanelRoleModel:GetTransform()
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    return curModelInfo.Model.transform
end

-- 同步武器动画
function XUiPanelRoleModel:WeaponAnimationSync(weaponModelList, modelName)
    if XTool.IsTableEmpty(weaponModelList) then
        return
    end
    local isAnimReset = XEquipConfig.GetEquipAnimIsReset(modelName)
    if not isAnimReset then
        return
    end
    local roleModel = self.RoleModelPool[modelName]
    if not roleModel or XTool.UObjIsNil(roleModel.Model.gameObject) then
        return
    end
    local playRoleAnimation = roleModel.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if not playRoleAnimation then
        return
    end
    local defaultAnimeName = playRoleAnimation.DefaultClip
    if defaultAnimeName ~= "UiStand1" then
        return
    end
    local defaultAnimeLength = 0
    for i = 0, playRoleAnimation.Clips.Length - 1 do
        local clip = playRoleAnimation.Clips[i]
        if clip and clip.name == defaultAnimeName then
            defaultAnimeLength = clip.length
            break
        end
    end
    self:AddUiStandPlayCallback(function(animaName, leftTime)
        local layerIndex = 0
        for _, weaponModel in pairs(weaponModelList or {}) do
            if XTool.UObjIsNil(weaponModel) then
                goto CONTINUE
            end
            ---@type UnityEngine.Animator
            local weaponAnim = weaponModel:GetComponent("Animator")
            if XTool.UObjIsNil(weaponAnim) or XTool.UObjIsNil(weaponAnim.runtimeAnimatorController) then
                goto CONTINUE
            end
            local stateInfo = weaponAnim:GetCurrentAnimatorStateInfo(layerIndex)
            local length = stateInfo.length
            -- 角色动作时长和武器动作时长不一致时跳过武器动作重置
            if length <= 0 or math.abs(defaultAnimeLength - length) > 0.05 then
                goto CONTINUE
            end
            local time = leftTime / length
            weaponAnim:Play(stateInfo.shortNameHash, layerIndex, time)
            :: CONTINUE ::
        end
    end)
end

---将添加UiStand完成时的回调队列
function XUiPanelRoleModel:AddUiStandPlayCallback(callback)
    self.PlayUiStandCallBackList[#self.PlayUiStandCallBackList + 1] = callback
end

return XUiPanelRoleModel
