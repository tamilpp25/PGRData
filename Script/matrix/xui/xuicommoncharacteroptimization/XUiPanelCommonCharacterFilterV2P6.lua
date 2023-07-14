-- 通用角色筛选器预置
---@class XUiPanelCommonCharacterFilterV2P6 XUiPanelCommonCharacterFilterV2P6
---@field _Control XCharacterControl
local XUiPanelCommonCharacterFilterV2P6 = XClass(XUiNode, "XUiPanelCommonCharacterFilterV2P6")
local XGridCharacterV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterV2P6")

function XUiPanelCommonCharacterFilterV2P6:OnStart(forceConfig)
    if not self.Parent then
        XLog.Error("筛选器未传入父Ui")
        return
    end

    if not CheckClassSuper(self.Parent, XLuaUi) then
        XLog.Error("传入的UiProxy必须是XLuaUi")
        return
    end

    self.ForceConfig = forceConfig  --强制使用的控制器参数，忽略父ui的控制器参数

    self.IsFold = false
    -- 常量
    self.CharacterListPrefabPath = CS.XGame.ClientConfig:GetString("CharacterListDefaultV2P6")
    -- 临时数据
    self._CurShowCharList = {} --当前展示的角色列表
    self.CacheTagSelectChar = {} --记录tag最后一次选择的角色 { [btn] = char }
    self.CurTargetCharacter = nil -- 当前需要选择的character，通过改变这个值，筛选器在刷新的时候会使用select方法选中该角色
    self.LastSelectCharacter = nil -- OnSelect最后一次选中的角色
    self.CurSelectGrid = nil
    self.CurSelectTagBtn = nil -- 当前选择的按钮
    self._CacheSortList = nil
    self.DiyLists = {} -- diy列表的列表
    self.NotSort = nil
    self.FirstSelect = true -- 第一次选中格子后设为false
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ---@type XCommonCharacterFiltAgency
    local ag2 = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)
    self.FiltAgency = ag2
    -- 实体数据
    self.BtnElementTagDic = {}  -- [elementId] = btn
    self.BtnDiyTagDic = {} -- [DiyIndex] = btn
    self.AllCanSelectTags = {} -- 所有可以选择的标签 { btn1, btn2... }
    self.AllTagCb = {}  -- [btn] = fun,
    self:InitButton()
end

-- 获得当前ui角色模型的父节点
function XUiPanelCommonCharacterFilterV2P6:_GetParentPanelRoleModel()
    -- 隐藏模型
    local targetLuaUi = self.Parent
    if self.Parent.ParentUi then
        targetLuaUi = self.Parent.ParentUi
    end
    local targetModelGo = targetLuaUi.UiModelGo

    if not targetModelGo then
        return nil
    end
    local targetPanelRoleModel = targetModelGo.transform:FindTransform("PanelRoleModel")

    return targetPanelRoleModel
end

-- 绑定toggle单选按钮事件
function XUiPanelCommonCharacterFilterV2P6:HandleTagClickCallBack(t, targetBtn, dofiltCb)
    local doCb = function (proxy, force, selectCharId)
        -- 先检查是否为空列表 且是否允许进入空列表
        local filtDataRes = dofiltCb and dofiltCb(t) -- 获得当前标签的列表数据
        local isResEmpty = XTool.IsTableEmpty(filtDataRes)
        if isResEmpty then
            if self.ControllerConfig and self.ControllerConfig.DiableEmptyStatus then
                local _, index = table.contains(self.AllCanSelectTags, self.CurSelectTagBtn)
                self.PanelCharacterTypeBtns:SelectIndex(index) -- 禁止点击新的按钮 切换选回原来的按钮
                XUiManager.TipError(CS.XTextManager.GetText("EmptyCharacter"))
                return
            end
        end

        local targetPanelRoleModel = self:_GetParentPanelRoleModel()
        if targetPanelRoleModel then
            targetPanelRoleModel.gameObject:SetActiveEx(not isResEmpty)
        end

        -- 检测重复选择按钮
        if targetBtn == self.CurSelectTagBtn and not force then
            if selectCharId then
                self:DoSelectCharacter(selectCharId)
            end
            return
        end

        self.CurSelectTagBtn = targetBtn
        self._CacheSortList = nil -- 当前的列表数据(有排序)。每次切换tag清空，因为有可能数据有变化
        self._CurShowCharList = filtDataRes -- 缓存当前的列表数据(有排序)
        if self.OnTagClickCb then
            self.OnTagClickCb(targetBtn)
        end

        if selectCharId then
            self:DoSelectCharacter(selectCharId)
        else
            self:RefreshList()
        end
    end
    self.AllTagCb[targetBtn] = doCb
    XUiHelper.RegisterClickEvent(t, targetBtn, function ()
        doCb(self) -- 按钮选择标签必不做强刷
    end)
end

-- region 初始化相关函数，在整个筛选器生命周期里有且只会有1次有效调用
function XUiPanelCommonCharacterFilterV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnFolder, self.OnBtnFolderClick)
    self:HandleTagClickCallBack(self, self.BtnAll, self.DoFiltAllClick)
    self:HandleTagClickCallBack(self, self.BtnRed, self.DoFiltRedClick)
    self:HandleTagClickCallBack(self, self.BtnUniframe, self.DoFiltUniframe)
    self:HandleTagClickCallBack(self, self.BtnSupport, self.DoFiltBtnSupport)

    table.insert(self.AllCanSelectTags, self.BtnAll)
    table.insert(self.AllCanSelectTags, self.BtnRed)
    table.insert(self.AllCanSelectTags, self.BtnUniframe)
    table.insert(self.AllCanSelectTags, self.BtnSupport)
end

-- 需外部手动调用传参初始化
--- 以下参数都为选传
---@param onChangeCharcterCb function 切换选中角色时回调
---@param onTagClickCb function 选中标签的回调
---@param stageId number
---@param refreshGridFuns function 要刷新的方法，如果传了自定义的grdiProxy就忽略
---@param gridProxy XUiBattleRoomRoleGrid 或继承了XUiBattleRoomRoleGrid的Grid
---@param checkInTeamFun function 一个传入角色id并返回bool变量的队伍检查方法，若传了且策划配置了需要使用队伍前置排序则会启用此方法来进行排序
---@param overrideSortList table 是否重写排序算法由程序员决定，追加的排序算法也可以使用此列表。传入的table必须以{CheckFunList ={}, SortFunList{}}，且CheckFunList，SortFunList应该使用枚举CharacterSortFunType为key
function XUiPanelCommonCharacterFilterV2P6:InitData(onChangeCharcterCb, onTagClickCb, stageId, refreshGridFuns, gridProxy, checkInTeamFun, overrideSortList)
    if self.IsInit then
        return
    end
    self.IsInit = true

    self.OnSeleCharacterCb = onChangeCharcterCb
    self.OnTagClickCb = onTagClickCb
    self.StageId = stageId
    self.RefreshGridFuns = refreshGridFuns
    self.GridProxy = gridProxy
    self.CheckInTeamFun = checkInTeamFun
    self.OverrideSortList = overrideSortList

    self.ControllerConfig = self.CharacterAgency:GetModelCharacterFilterController()[self.Parent.Name]
    if self.ForceConfig then
        self.ControllerConfig = self.ForceConfig
    end
    self.HideElementTags = {} -- value是tagId
    local hideIsomerTag = nil
    local hideRedTag = true

    -- 检测关卡限制独域tag
    if stageId then
        local limitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
        if limitType == XFubenConfigs.CharacterLimitType.Normal then
            hideIsomerTag = true
        end
    end

    -- 检测function限制独域tag
    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
    or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer) then
        hideIsomerTag = true
    end

    -- 检测控制器数据
    local config = self.ControllerConfig
    if config then
        -- 限制元素tag
        for k, tagId in pairs(config.BanElementTags or {}) do
            table.insert(self.HideElementTags, tagId)
        end

        if config.EnableFolder then
            self.BtnFolder.gameObject:SetActiveEx(true)
        end

        -- 检测支援标签开启
        self.BtnSupport.gameObject:SetActiveEx(config.EnableSupportTag)

        -- 检测红点标签开启
        if config.EnableRedDotTag then
            hideRedTag = false
        end

        -- 独域
        if config.ForceEnableUniframe then
            hideIsomerTag = false
        end

        -- 排序tag
        self.SortTagList = config.SortTagList

        if not string.IsNilOrEmpty(config.CharacterListPrefabPath)  then
            self.CharacterListPrefabPath = config.CharacterListPrefabPath
        end
    end

    -- 互斥
    if self.BtnSupport.gameObject.activeInHierarchy then
        hideRedTag = true
    end

    -- 隐藏独域
    self.BtnUniframe.gameObject:SetActiveEx(not hideIsomerTag)
    self.HideIsomerTag = hideIsomerTag
    -- 隐藏红点
    self.InitHideRedTag = hideRedTag
    self.BtnRed.gameObject:SetActiveEx(not hideRedTag)
    self:_InitTags()
    self:_InitDynamicTable()
end

function XUiPanelCommonCharacterFilterV2P6:_InitTags()
    self.EnableElementTags = {}
    self:_InitElementTagsData()
    self:_CreateTagsUi()
    self:_InitFoldTag()
end

function XUiPanelCommonCharacterFilterV2P6:_InitElementTagsData()
    local allElements = self.CharacterAgency:GetModelCharacterElement()
    local checkFun = function (id)
        if table.contains(self.HideElementTags, id) then
            return false
        end

        return true
    end

    for elementId, v in pairs(allElements) do
        if checkFun(elementId) and elementId <= 5 then --目前就5种元素
            table.insert(self.EnableElementTags, elementId)
        end
    end
end

function XUiPanelCommonCharacterFilterV2P6:_CreateTagsUi()
    -- 元素标签
    local allElements = self.CharacterAgency:GetModelCharacterElement()
    self.BtnTag.gameObject:SetActiveEx(false)
    for k, tagId in ipairs(self.EnableElementTags) do
        local ui = self["BtnTag"..tagId]
        ui.gameObject:SetActiveEx(true)
        local btnTag = ui
        local btnName = "BtnElement"..tagId
        btnTag.gameObject.name = btnName
        self[btnName] = btnTag
        -- 元素图标
        local icon = allElements[tagId].Icon2
        btnTag:SetRawImage(icon)

        self.BtnElementTagDic[tagId] = btnTag
        table.insert(self.AllCanSelectTags, btnTag)
        -- 点击tag
        self:HandleTagClickCallBack(self, btnTag, function ()
            return self:DoFiltElementTagClick(tagId)
        end)
    end
    -- self.BtnUniframe.transform:SetAsLastSibling()
    -- self.BtnSupport.transform:SetAsLastSibling()
    
    -- 自定义标签
    if not self.ControllerConfig or not self.ControllerConfig.DiyTagNames then
        self.PanelCharacterTypeBtns:Init(self.AllCanSelectTags, function () end)
        return
    end
    for k, tagName in ipairs(self.ControllerConfig.DiyTagNames) do
        local ui = CS.UnityEngine.Object.Instantiate(self.BtnDiy.gameObject, self.BtnDiy.transform.parent)
        -- ui.transform:SetAsLastSibling()
        ui.gameObject:SetActiveEx(true)
        local btnTag = ui:GetComponent("XUiButton")
        self[tagName] = btnTag
        btnTag.gameObject.name = tagName
        btnTag:SetNameByGroup(0, tagName)
        self.BtnDiyTagDic[k] = btnTag
        table.insert(self.AllCanSelectTags, btnTag)
        -- 点击tag
        self:HandleTagClickCallBack(self, btnTag, function ()
            return self:DoFiltDiy(k)
        end)
    end

    -- self.BtnRed.transform:SetAsLastSibling()

    -- xuibutton仅拿来做状态切换 不做业务处理
    self.PanelCharacterTypeBtns:Init(self.AllCanSelectTags, function () end)
end

function XUiPanelCommonCharacterFilterV2P6:_InitFoldTag()
    if not self.ControllerConfig or not self.ControllerConfig.EnableFolder then
        self.BtnFolder.gameObject:SetActiveEx(false)
        self:DoUnfold()
        return
    end
end

function XUiPanelCommonCharacterFilterV2P6:_InitDynamicTable()
    -- 选择作战层的滑动列表
    local charListPrefab = nil
    if self.CharacterListPrefabPath then
        charListPrefab = self.PanelList:LoadPrefab(self.CharacterListPrefabPath)
    else
        local cacheComp = self.PanelList:GetComponent(typeof(CS.XUiCachePrefab))
        charListPrefab = CS.UnityEngine.Object.Instantiate(cacheComp.go, self.PanelList)
    end
    self.CharListPrefab = charListPrefab
    self.DynamicTable = XDynamicTableNormal.New(charListPrefab)
    local gridProxy = self.GridProxy or XGridCharacterV2P6
    self.DynamicTable:SetProxy(gridProxy, self, self)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventCharacterList(event, index, grid)
    end)
end
-- endregion

-- 外部手动调用,请在动态列表加载完 且ui onable后再调用该接口
function XUiPanelCommonCharacterFilterV2P6:InitFoldState()
    if self._IsInitFoldState then
        return
    end

    if not self.ControllerConfig or not self.ControllerConfig.EnableFolder then
        return
    end

    --检测折叠功能开启
    local key = "XUiPanelCommonCharacterFilterV2P6"..self.Parent.Name
    local isSetFold = XSaveTool.GetData(key)
    local foldParent = self.CharListPrefab:FindTransform("AnimFold")
    if not foldParent then
        XLog.Error("该筛选列表预置体"..self.CharacterListPrefabPath.."没有折叠动画 AnimFold ，但是配置表仍然开启了折叠功能EnableFolder，请查看配置表CharacterFilterController的" .. self.ControllerConfig.UiName)
        return
    end
    if isSetFold then
        self:DoFold()
    else
        self:DoUnfold()
    end
end

-- 获得当前角色id的列表中的下标
function XUiPanelCommonCharacterFilterV2P6:GetCharInCurListIndex(charId)
    if not XTool.IsNumberValid(charId) then
        return
    end

    local list = self:GetCurShowList()
    local index = nil
    local curChar = nil
    for k, char in pairs(list) do
        if charId == char.Id then
            index = k
            curChar = char
        end
    end

    return index, curChar
end

-- 可供外部手动调用，手动选择标签。注意，这个函数会自动调用 RefreshList
---@param isForce boolean:若重复选择相同的tag false:不会调用RefreshList，不会刷新和排序。true:强制调用RefreshList，且刷新排序
---@param charId number:将在选择tag后自动选择角色，且只调用一次RefreshList。
function XUiPanelCommonCharacterFilterV2P6:DoSelectTag(btnName, isForce, charId)
    local btn = self[btnName]
    if not btn then
        return
    end

    local cb = self.AllTagCb[btn]
    if not cb then
        return
    end
    cb(self, isForce, charId)

    local _, index = table.contains(self.AllCanSelectTags, btn)
    if not index then
        return
    end
    self.PanelCharacterTypeBtns:SelectIndex(index)
end

-- 可供外部手动调用。选中当前列表里的角色，如果没有则不执行
function XUiPanelCommonCharacterFilterV2P6:DoSelectCharacter(charId)
    if self.CurCharacte and charId == self.CurTargetCharacter.Id then
        return
    end
    
    local curChar = nil
    local index = nil
    index, curChar = self:GetCharInCurListIndex(charId)
    if not index then
        return
    end

    self.CacheTagSelectChar[self.CurSelectTagBtn] = curChar
    self:_DoSetGirdSelectStatusByCharId(charId)
    self:RefreshList(index)
end

-- 可供外部手动调用。选中当前列表的下标的角色
function XUiPanelCommonCharacterFilterV2P6:DoSelectIndex(index)
    local list = self:GetCurShowList()
    if index > #list then
        return
    end

    self.CacheTagSelectChar[self.CurSelectTagBtn] = list[index]
    self:RefreshList()
end

-- 在禁用自动选择开启的时候该方法才生效。将某个角色切换成选中框状态
function XUiPanelCommonCharacterFilterV2P6:_DoSetGirdSelectStatusByCharId(charId)
    self.ForeceSelectCharIdTrigger = charId
end

-- 外部手动调用
function XUiPanelCommonCharacterFilterV2P6:ImportList(characterList)
    if XTool.IsTableEmpty(characterList) then
        return
    end

    -- 检测是否剔除还没解锁的角色
    if not self.ControllerConfig or not self.ControllerConfig.EnableShowFragment then
        local res = {}
        for k, character in pairs(characterList) do
            local id = character.Id
            local rawData = character.RawData
            if rawData and rawData.Id then
                id = rawData.Id
            end
            if not self.CharacterAgency:CheckIsFragment(id) then
                table.insert(res, character)
            end
        end
        characterList = res
    end

    -- 过滤独域机体
    if self.HideIsomerTag then
        local res = {}
        for k, character in pairs(characterList) do
            local id = character.Id
            if XRobotManager.CheckIsRobotId(id) then
                id = XRobotManager.GetCharacterId(id)
            end
            if not XCharacterConfigs.IsIsomer(id) then
                table.insert(res, character)
            end
        end
        characterList = res
    end

    -- 玩家自机/机器人 源数据列表
    self.SourceCharacterList = characterList

    -- 导入后刷新，不改变标签
    local curTag = self.CurSelectTagBtn
    if curTag then
        local name = curTag.gameObject.name
        self:DoSelectTag(name, true)
    else
        self:DoSelectTag("BtnAll", true)
    end
end

-- 外部手动调用，开启支援选项
function XUiPanelCommonCharacterFilterV2P6:ImportSupportList(characterList)
    -- 好友/公会支援 数据列表
    self.SupportCharacterList = characterList
end

-- 外部手动调用，自定义标签选项，可以按顺序一次性传多个自定义标签的数据
function XUiPanelCommonCharacterFilterV2P6:ImportDiyLists(...)
    if not self.ControllerConfig then
        return
    end
    local lists = {...}
    if #lists > #self.ControllerConfig.DiyTagNames then
        XLog.Error("导入的列表数量大于自定义标签数量")
    end

    self.DiyLists = lists
end

function XUiPanelCommonCharacterFilterV2P6:IsCurListEmpty()
    local dataList = self:GetCurShowList()
    return XTool.IsTableEmpty(dataList)
end

function XUiPanelCommonCharacterFilterV2P6:ShowEmpty(showEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(showEmpty)
end

function XUiPanelCommonCharacterFilterV2P6:RefreshList(forceIndex, forceReSort)
    local dataList = self:GetCurShowList(forceReSort)
    if not dataList then
        return
    end

    -- 暂时关闭缓存标签角色功能
    -- local cacheChar = self.CacheTagSelectChar[self.CurSelectTagBtn] or dataList[1]
    -- for k, char in pairs(dataList) do
    --     if char.Id == cacheChar.Id then
    --         index = k
    --         break
    --     end
    -- end
    -- 检查是否缓存了当前页签选中过的角色 ，forceIndex的优先级大于缓存角色的优先级
    local index = forceIndex or 1
    
    local showEmpty = XTool.IsTableEmpty(dataList)
    self:ShowEmpty(showEmpty)
    self.TxtNone.text = CS.XTextManager.GetText("EmptyCharacter")
    if self.CurSelectTagBtn.gameObject.name == "BtnSupport" then -- 支援标签的空文本不一样
        self.TxtNone.text = CS.XTextManager.GetText("EmptySupporter")
    end
    local showRedBtn = not self.InitHideRedTag and self:CheckHasRed()
    self.BtnRed.gameObject:SetActiveEx(showRedBtn)

    -- 是否禁用切换标签自动选择格子
    self.CurTargetCharacter = dataList[index]
    if self.ControllerConfig and self.ControllerConfig.DisableAutoSeleGrid then
        self.CurTargetCharacter = nil
    end

    -- index 是让滑动列表定位的。 CurTargetCharacter是让刷新列表时激活对应格子选中状态的
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataASync(index)
end

-- 只刷新格子的数据(不支持传入RefreshFun参数的自定义刷新)
function XUiPanelCommonCharacterFilterV2P6:OnlyRefreshData()
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        local char = self:GetCurShowList()[k]

        if self.RefreshGridFuns then
            self.RefreshGridFuns(k, grid, char)
        elseif grid.SetData then
            grid:SetData(char, k)
        end
    end
end

-- 返回当前展示的列表排序后的结果
function XUiPanelCommonCharacterFilterV2P6:GetCurShowList(forceReSort)
    if XTool.IsTableEmpty(self.SourceCharacterList) then
        XLog.Error("源数据角色列表为空，检查是否有通过ImportSupportList导入角色列表")
        return
    end

    if XTool.IsTableEmpty(self._CurShowCharList) then
        return {}
    end

    -- 如果不是角色或机器人id，不参与排序。请自行在源数据列表里排序，常用于支援或者自定义标签的id
    if self:IsTagSupport() then
        return self._CurShowCharList  -- 原样返回
    end

    -- 如果启动了禁止排序触发器，触发后原样返回并关闭触发器
    if self.NotSort then
        self.NotSort = false
        return self._CurShowCharList
    end

    -- 只有当强制刷新参数forceReSort为true，或者没有缓存列表_CacheSortList。才会重新排序
    if self._CacheSortList and not forceReSort then
        return self._CacheSortList
    end

    -- 根据不同的筛选器模式 启用不同的排序算法  特殊重写CheckInTeam
    local sortFunList = {CharacterSortFunType.InTeam, CharacterSortFunType.Level, CharacterSortFunType.Ability, CharacterSortFunType.Quality, CharacterSortFunType.Priority} -- 默认的排序算法
    if not XTool.IsTableEmpty(self.SortTagList) then
        sortFunList = self.SortTagList
    end

    -- 检查是否有重写的排序算法。
    local overrideList = self.OverrideSortList
    if self.CheckInTeamFun then
        if XTool.IsTableEmpty(overrideList) then
            overrideList = {CheckFunList = {}, SortFunList = {}}
        end
        if XTool.IsTableEmpty(overrideList.CheckFunList) then
            overrideList.CheckFunList = {}
        end
        if XTool.IsTableEmpty(overrideList.SortFunList) then
            overrideList.SortFunList = {}
        end
        overrideList.CheckFunList[CharacterSortFunType.InTeam] = function (idA, idB)
            local inTeamA = self.CheckInTeamFun(idA)
            local inTeamB = self.CheckInTeamFun(idB)
            if inTeamA ~= inTeamB then
                return true
            end
        end
        overrideList.SortFunList[CharacterSortFunType.InTeam] = function (idA, idB)
            local inTeamA = self.CheckInTeamFun(idA)
            local inTeamB = self.CheckInTeamFun(idB)
            if inTeamA ~= inTeamB then
                return inTeamA
            end
        end
    end
    if not XTool.IsTableEmpty(self.SortTagList) and table.contains(self.SortTagList, CharacterSortFunType.InTeam) and not self.CheckInTeamFun then
        XLog.Error("界面 "..self.Parent.Name.."配置表启用了队伍排序(InTeam)检查算法，但是未传入CheckInTeamFun参数，请程序检查InitData调用时是否传入")
    end

    local sortRes = self.FiltAgency:DoSortFilterV2P6(self._CurShowCharList, sortFunList, nil, overrideList)
    self._CurShowCharList = sortRes
    self._CacheSortList = sortRes

    return self._CurShowCharList
end

---@param grid XGridCharacterV2P6
function XUiPanelCommonCharacterFilterV2P6:OnDynamicTableEventCharacterList(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local char = self:GetCurShowList()[index]
        local isCurChar = self.CurTargetCharacter == char
        if isCurChar then
            self.CurSelectGrid = grid
            self:OnSelect(char, index, grid)
        end
      
        if self.RefreshGridFuns then
            self.RefreshGridFuns(index, grid, char)
        elseif grid.SetData then
            grid:SetData(char, index)
        end
        
        if grid.SetSelect then
            -- 禁用自动选择，所以不会去除掉手动选择的状态
            if self.ControllerConfig and self.ControllerConfig.DisableAutoSeleGrid and self.ForeceSelectCharIdTrigger and self.ForeceSelectCharIdTrigger == char.Id then
                grid:SetSelect(true)
            else
                grid:SetSelect(isCurChar)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local char = self:GetCurShowList()[index]
        self.CurTargetCharacter = char
        self:OnSelect(char, index, grid)
        self.CacheTagSelectChar[self.CurSelectTagBtn] = char
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelect(false)
        end
        if grid.SetSelect then
            grid:SetSelect(true)
        end
        self.CurSelectGrid = grid

        -- 手动选择后删除掉强制选择状态记录的角色
        self.ForeceSelectCharIdTrigger = nil
    end

    -- 兼容战斗房间选人检测的AOP方法
    local roomDetialProxy = self.Parent and self.Parent.Proxy
    if roomDetialProxy and roomDetialProxy.AOPOnDynamicTableEventAfter and XTool.IsNumberValid(index) and index > 0 then
        roomDetialProxy:AOPOnDynamicTableEventAfter(self.Parent, event, index, grid)
    end
end

function XUiPanelCommonCharacterFilterV2P6:OnSelect(char, index, grid)
    if self.LastSelectCharacter == char then
        return
    end
    self.OnSeleCharacterCb(char, index, grid, self.FirstSelect)
    self.LastSelectCharacter = char
    self.FirstSelect = false
end

-- 所有筛选项tag的点击回调 begin
function XUiPanelCommonCharacterFilterV2P6:DoFiltAllClick()
    return self.SourceCharacterList
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltElementTagClick(tagId)
    local tagaData = { Element = {tagId}}
    return self.FiltAgency:DoFilter(self.SourceCharacterList, tagaData)
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltUniframe()
    local tagaData = { Career = {4} } -- 先锋型的职业id是 4
    return self.FiltAgency:DoFilter(self.SourceCharacterList, tagaData)
end

-- 检查当前是否有红点角色
function XUiPanelCommonCharacterFilterV2P6:CheckHasRed()
    for k, character in pairs(self.SourceCharacterList) do
        if not XRobotManager.CheckIsRobotId(character.Id) and XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER, XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY}, character.Id) then
            return true
        end
    end
    return false
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltRedClick()
    if self.InitHideRedTag then
        return
    end

    local res = {}
    for k, character in pairs(self.SourceCharacterList) do
        if not XRobotManager.CheckIsRobotId(character.Id) and XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER, XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY}, character.Id) then
            table.insert(res, character)
        end
    end

    return res
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltBtnSupport()
    if not self.SupportCharacterList then
        return
    end

    return self.SupportCharacterList
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltDiy(diyIndex)
    if XTool.IsTableEmpty(self.DiyLists) then
        return
    end

    local targetList = self.DiyLists[diyIndex]
    return targetList
end
-- 所有筛选项tag的点击回调 end

-- 折叠
function XUiPanelCommonCharacterFilterV2P6:OnBtnFolderClick()
    if self.IsFold then
        self:DoUnfold()
    else
        self:DoFold()
    end
end

function XUiPanelCommonCharacterFilterV2P6:SetFoldCallback(foldCb, unfoldCb)
    self.FoldCb = foldCb
    self.UnfoldCb = unfoldCb
end

-- 折叠
function XUiPanelCommonCharacterFilterV2P6:DoFold()
    local charIdBeforeFold = self.CurTargetCharacter and self.CurTargetCharacter.Id
    -- 1.筛选器折叠 初始化状态时用1f快速播放完，避免玩家看到筛选器进入动画
    if self._IsInitFoldState then
        CS.XUiManager.Instance:SetMask(true)
        self:PlayAnimation("AnimFold", function ()
            CS.XUiManager.Instance:SetMask(false)
        end)
    else
        self:PlayAnimation("AnimFold1F")
    end
    -- 2.格子折叠
    self:DoPlayGridFoldOrUnfoldAnim(true)
    -- 3.触发回调
    if self.FoldCb then
        self.FoldCb(self._IsInitFoldState)
    end
    self.IsFold = true
    self._IsInitFoldState = true

    -- 折叠后刷新标签
    self:DoSelectTag("BtnAll")
    -- 折叠后自动选择全选标签 但是还是要选择之前的角色
    if charIdBeforeFold then
        self:DoSelectCharacter(charIdBeforeFold)
    end
end

-- 展开
function XUiPanelCommonCharacterFilterV2P6:DoUnfold()
    if self._IsInitFoldState then
        CS.XUiManager.Instance:SetMask(true)
        self:PlayAnimation("AnimUnFold", function ()
            CS.XUiManager.Instance:SetMask(false)
        end)
    else
        self:PlayAnimation("AnimUnFold1F")
    end
    self:DoPlayGridFoldOrUnfoldAnim(false)
    if self.UnfoldCb then
        self.UnfoldCb(self._IsInitFoldState)
    end
    self.IsFold = false
    self._IsInitFoldState = true
end

-- 直接控制阿尔法值：原因
-- 动态列表刷新时会隐藏、回收节点，通过grid去播放动画会使有些格子无法被get到。且隐藏的动画是不能播放的
function XUiPanelCommonCharacterFilterV2P6:DoPlayGridFoldOrUnfoldAnim(isFold)
    self:StopFoldAnim()

    local currAlpha = 1
    local duration = 0.3
    local addValue = -0.1
    if isFold then
        currAlpha = 1  
        duration = self._IsInitFoldState and 0.3 or 0
        addValue = self._IsInitFoldState and -0.1 or -1
    else
        currAlpha = 0 
        duration = self._IsInitFoldState and 0.4 or 0
        addValue = self._IsInitFoldState and 0.1 or 1
    end

    if self.DynamicTable then
        local contentTrans = self.DynamicTable:GetImpl().transform:GetComponent("ScrollRect").content
        local childCount = contentTrans.childCount
        local allCg = {}
        for i = 0, childCount - 1 do
            local foldParent = contentTrans:GetChild(i):FindTransform("FoldParent")
            if XTool.UObjIsNil(foldParent) then
                return
            end
            local cg = foldParent:GetComponent("CanvasGroup")
            if XTool.UObjIsNil(cg)  then
                return
            end
            if cg.gameObject.activeInHierarchy then
                table.insert(allCg, cg)
            else
                cg.alpha = isFold and 0 or 1 -- 如果是隐藏的是不能在update做变化的，直接设置它的目标alpha值
            end
        end

        self["FoldAnim"..currAlpha] = XUiHelper.Tween(duration , function ()
            currAlpha = currAlpha + addValue
            for k, cg in pairs(allCg) do
                cg.alpha = currAlpha
            end
        end, function ()
            -- 结束时再设置一遍目标值保底
            for k, cg in pairs(allCg) do
                cg.alpha = isFold and 0 or 1
            end
        end)
    end
end

function XUiPanelCommonCharacterFilterV2P6:IsTagSupport()
    return self.CurSelectTagBtn == self.BtnSupport
end

-- 下一次刷新不排序
function XUiPanelCommonCharacterFilterV2P6:SetNotSortTrigger()
    self.NotSort = true
end

function XUiPanelCommonCharacterFilterV2P6:PlayAnimation(animeName, finCb)
    local animTrans = self.Transform:Find("Animation"):FindTransform(animeName)
    if not animTrans.gameObject.activeInHierarchy then
        return
    end
    animTrans:PlayTimelineAnimation(finCb)
end

function XUiPanelCommonCharacterFilterV2P6:StopFoldAnim()
    if self.FoldAnim1 then
        XScheduleManager.UnSchedule(self.FoldAnim1)   
        self.FoldAnim1 = nil
    end

    if self.FoldAnim0 then
        XScheduleManager.UnSchedule(self.FoldAnim0)   
        self.FoldAnim0 = nil
    end
end

function XUiPanelCommonCharacterFilterV2P6:OnDisable()
    local key = "XUiPanelCommonCharacterFilterV2P6"..self.Parent.Name
    XSaveTool.SaveData(key, self.IsFold)
end

function XUiPanelCommonCharacterFilterV2P6:OnRelease()
    self:StopFoldAnim()
end

return XUiPanelCommonCharacterFilterV2P6