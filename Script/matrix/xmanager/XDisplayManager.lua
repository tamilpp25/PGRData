XDisplayManagerCreator = function()
    ---@class XDisplayManager
    local XDisplayManager = {}

    local DisplayTable = nil
    local ContentTable = nil
    local Groups = {}
    local CharDict = {}
    local CurDisplayCharNew
    local NextCharId = nil
    
    function XDisplayManager.Init()
        DisplayTable = XDisplayConfigs.GetDisplayTable()
        ContentTable = XDisplayConfigs.GetContentTable()
        Groups = XDisplayConfigs.GetGroups()
    end

    function XDisplayManager.InitDisplayCharId(id)
        XDisplayManager.GetCharDict()
    end

    function XDisplayManager.GetDisplayTable(id)
        local tab = DisplayTable[id]
        if not tab then
            XLog.ErrorTableDataNotFound("XDisplayManager.GetDisplayTable", "tab", "Client/Display/Display.tab", "id", tostring(id))
        end
        return tab
    end

    function XDisplayManager.GetDisplayContentTable(id)
        local tab = ContentTable[id]
        if not tab then
            XLog.ErrorTableDataNotFound("XDisplayManager.GetDisplayTable", "tab", "Client/Display/DisplayContent.tab", "id", tostring(id))
        end
        return tab
    end

    function XDisplayManager.RandBehavior(modelName)
        local group = Groups[modelName]
        if not group then
            if not modelName then
                XLog.Error("XDisplayManager.RandContent 错误: 参数modelName不能为空")
            else
                XLog.ErrorTableDataNotFound("XDisplayManager.GetDisplayTable",
                "modelName", "Client/Display/Display.tab", "modelName", tostring(modelName))
            end
            return
        end
        local index = XMath.RandByWeights(group.Weights)
        local id = group.Ids[index]
        if not id then
            local tempStr = "XDisplayManager.GetDisplayTable错误：Client/Display/Display.tab 表中modelName: "
            XLog.Error(tempStr .. tostring(modelName) .. "对应配置项的index： " .. index .. "内容为空,检查index或者配置表")
            return
        end
        local displayTable = XDisplayManager.GetDisplayTable(id)
        local contentTable = XDisplayManager.GetDisplayContentTable(displayTable.ContentId)
        local result = {
            Action = displayTable.Action,
            Sound = contentTable.Sound,
            Text = contentTable.Text,
            Duration = contentTable.Duration,
        }
        return result
    end

    -- 设置首席助理
    function XDisplayManager.SetDisplayCharIdFirstRequest(id, cb)
        local data = {CharId = id}
        XNetwork.Call("SetDisplayCharIdFirstRequest", data, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res)
            end
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
        end)
    end

    -- 更换选中的助理
    function XDisplayManager.UpdatePlayerDisplayCharIdRequest(oldCharId, newCharId, cb)
        XNetwork.Call("UpdatePlayerDisplayCharIdRequest", {OldCharId = oldCharId, NewCharId = newCharId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            if cb then
                cb(res)
            end
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
        end)
    end

    -- 添加助理
    function XDisplayManager.AddPlayerDisplayCharIdRequest(charId, cb)
        XNetwork.Call("AddPlayerDisplayCharIdRequest", {CharId = charId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
            if cb then
                cb()
            end
        end)
    end

    function XDisplayManager.SetDisplayCharById(id, callback)
        if id == XPlayer.DisplayCharId then
            return
        end

        local newChar = XMVCA.XCharacter:GetCharacter(id)
        if not newChar then
            return
        end

        XNetwork.Call("ChangePlayerDisplayCharIdRequest", { CharId = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XPlayer.SetDisplayCharId(id)
            callback(id)
        end)
    end

    function XDisplayManager.GetCharDict()
        CharDict = {}
        local list = XMVCA.XCharacter:GetOwnCharacterList()
        for _, char in ipairs(list) do
            CharDict[char.Id] = char
        end
        return CharDict
    end

    -- 根据角色ID设置看板展示角色
    function XDisplayManager.SetDisplayCharByCharacterId(charId)
        if not charId then
            return
        end

        local newChar = XMVCA.XCharacter:GetCharacter(charId)
        if not newChar then
            return
        end
    end

    -- 获取看板展示角色 注意这个接口不会被助理队列同步协议同步刷新，
    function XDisplayManager.GetDisplayChar()
        local res = {}
        if not CurDisplayCharNew then
            return res
        end

        local charId = CurDisplayCharNew.Id 
        local isIn, index = table.contains(XPlayer.DisplayCharIdList, charId)
        -- 能进入这个判断 一般来说是随机了看板角色后，触发了更换助理队列的协议，且新的队列里没有上一次的看板角色
        if not isIn then
            local resCharId = XPlayer.DisplayCharIdList[1]
            local xChar = XMVCA.XCharacter:GetCharacter(resCharId)
            return xChar
        end

        return CurDisplayCharNew
    end

    -- 每次调用获取随机助理 会对 CurDisplayCharNew 进行一次赋值。 面板通过拿CurDisplayCharNew来进行展示
    -- 也可以通过 SetNextDisplayChar 强制设置下一次的助理来展示
    function XDisplayManager.GetRandomDisplayCharByList()
        if NextCharId then
            return XMVCA.XCharacter:GetCharacter(NextCharId)
        end

        local list = nil
        if XDataCenter.PhotographManager.GetIsBackgroundRandomFashion() then
            list = XDataCenter.PhotographManager.GetRandomCharIdListByRandomBackgroundId()
        else
            list = XTool.Clone(XPlayer.DisplayCharIdList)
        end

        if CurDisplayCharNew and #list > 1 then
            for k, v in pairs(list) do
                if v == CurDisplayCharNew.Id then
                    table.remove(list, k)
                end
            end            
        end
        local randomNum = XTool.Random(1, #list)
        local charId = list[randomNum]
        CurDisplayCharNew = XMVCA.XCharacter:GetCharacter(charId)

        return CurDisplayCharNew
    end

    -- 强制设置下一次随机方法返回的助理
    -- SetNextDisplayChar要成对使用 以set nil结束
    function XDisplayManager.SetNextDisplayChar(charId)
        NextCharId = charId
        if charId then
            CurDisplayCharNew = XMVCA.XCharacter:GetCharacter(charId)
        end
    end

    function XDisplayManager.GetNextDisplayChar()
        return NextCharId
    end

    function XDisplayManager.GetModelName(id)
        local character = XMVCA.XCharacter:GetCharacter(id)
        local quality
        if character then
            quality = character.Quality
        else
            quality = XMVCA.XCharacter:GetCharMinQuality(id)
        end
        return XMVCA.XCharacter:GetCharModel(id, quality)
    end

    -- 更换模型和加载展示状态机，完成后调用回调。
    function XDisplayManager.UpdateRoleModel(panelRoleModel, id, cb, fashionId)
        local state = {}

        -- 初始化信息
        state.Panel = panelRoleModel
        state.Id = id
        --state.Callback = cb
        state.IsLoading = true
        state.ModelName = XDisplayManager.GetModelName(id)

        state.RerollData = function()
            state.RollData = XDisplayManager.RandBehavior(state.ModelName)
        end

        --获取时装ModelName
        local resourcesId
        if fashionId then
            resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
        else
            resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(id)
        end

        local fashionModelName

        if resourcesId then
            fashionModelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
        else
            fashionModelName = XDisplayManager.GetModelName(id)
        end

        local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(fashionModelName, panelRoleModel.RefName)
        -- 特殊模型 && 非多重模型
        if isSpecialModel and not isMultiModel then
            fashionModelName = XModelManager.GetSpecialModelId(fashionModelName, panelRoleModel.RefName)
        end
        
        --获取Controller名字
        state.RuntimeControllerName = XModelManager.GetUiDisplayControllerPath(fashionModelName)

        -- 更换模型
        local callback = function(model)
            state.Model = model
            state.Animator = state.Model:GetComponent("Animator")
            XDisplayManager.OnAssetLoaded(state)
        end
        state.Callback = function()
            --由于状态机是在模型加载之后，需要状态机加载完之后, 重新根据动作加载对应特效
            local actionId = panelRoleModel:GetPlayingStateName(0) -- 0:只展示身体

            local weaponFashionId
            local characterId = tonumber(id)
            if XRobotManager.CheckIsRobotId(characterId) then
                local robotId = characterId
                characterId = XRobotManager.GetCharacterId(robotId)
                weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
            end
            panelRoleModel:LoadCharacterUiEffect(characterId, actionId, nil, weaponFashionId, nil)

            if cb then cb() end
        end
        panelRoleModel:UpdateCharacterModel(id, nil, panelRoleModel.RefName, callback, nil, fashionId)

        -- 加载animationController
        local runtimeController = CS.LoadHelper.LoadUiController(state.RuntimeControllerName, panelRoleModel.RefName)
        
        if runtimeController == nil or not runtimeController:Exist() then
            XLog.Error("XUiPanelDisplay RefreshSelf 错误: 展示角色的动画状态机加载失败: 状态机名称 " .. state.RuntimeControllerName .. " Ui名称：" .. panelRoleModel.RefName)
            return
        end
        state.RunTimeController = runtimeController
        if not state.Model then
            return
        end
        XDisplayManager.OnAssetLoaded(state)

        -- 两个都OK的时候触发回调
        return state
    end

    function XDisplayManager.OnAssetLoaded(state)
        if XTool.UObjIsNil(state.Model) or XTool.UObjIsNil(state.RunTimeController) then
            return
        end
        state.Animator.runtimeAnimatorController = state.RunTimeController
        state.IsLoading = false
        if not state.Model.activeSelf then
            return
        end
        if state.Callback then
            state.Callback(state.Model)
        end
    end

    XDisplayManager.Init()
    return XDisplayManager
end