local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- 通用角色筛选器预置
---@class XUiPanelCommonCharacterFilterV2P6 XUiPanelCommonCharacterFilterV2P6
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
    ---@type XTableCharacterFilterController
    self.ForceConfig = forceConfig  --强制使用的控制器参数，忽略父ui的控制器参数

    self.IsFold = false
    -- 常量
    self.CharacterListPrefabPath = CS.XGame.ClientConfig:GetString("CharacterListDefaultV2P6")
    -- 临时数据
    self._CurShowCharList = {} --玩家可见的筛选器的真实列表
    self._CacheSortList = nil -- 最后一次排序后的列表(一般与_CurShowCharList是同数据)
    self.CacheTagSelectChar = {} --记录tag最后一次选择的角色 { [btn] = char }
    self.CurTargetCharacter = nil -- 当前需要选择的character，通过改变这个值，筛选器在刷新的时候会使用select方法选中该角色
    self.LastSelectCharacter = nil -- OnSelect最后一次选中的角色
    self.CurSelectGrid = nil
    self.CurSelectTagBtn = nil -- 当前选择的按钮
    self._AfterInitSeleCharId = nil -- importList完成之后自动选择的角色
    self.DiyLists = {} -- diy列表的列表
    self.NotSort = nil
    self.FirstSelect = true -- 第一次选中格子后设为false
    -- 实体数据
    self.BtnElementTagDic = {}  -- [elementId] = btn
    self.BtnDiyTagDic = {} -- [DiyIndex] = btn
    self.AllCanSelectTags = {} -- 所有可以选择的标签 { btn1, btn2... }
    self.AllTagCb = {}  -- [btn] = fun,
    self.IsHideGeneralSkill = false
    self._SelectTagName = nil -- 当前选中的页签名字（成员排序使用）
    XMVCA.XCommonCharacterFilter:SetLastUseFilter(self)
end

function XUiPanelCommonCharacterFilterV2P6:SetGetCharIdFun(fun)
    self.GetIdFun = fun
end

-- v2.15 效应元素筛选排序调用
function XUiPanelCommonCharacterFilterV2P6:GetSelectTagName()
    return self._SelectTagName
end

function XUiPanelCommonCharacterFilterV2P6:_GetCharIdFun(char)
    local getFunId = self.GetIdFun and self.GetIdFun(char)
    if getFunId and type(getFunId) == 'number' then
        return getFunId
    end
    local rawData = char.RawData
    if rawData then
        return rawData.Id
    end
    return char.Id
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
    -- 未激活的按钮不注册
    if not targetBtn.gameObject.activeSelf then
        return
    end

    local doCb = function (proxy, force, selectCharId)
        -- 支援角色不参与效应筛选
        if targetBtn.gameObject.name == XEnumConst.Filter.TagName.BtnSupport and self:HasGeneralSkillFilter() then
            XUiManager.TipText("CharacterGeneralSkillTip")
            return
        end
        -- 先检查是否为空列表 且是否允许进入空列表
        local filtDataRes = dofiltCb and dofiltCb(t) -- 获得当前标签的列表数据
        local isResEmpty = XTool.IsTableEmpty(filtDataRes)
        if isResEmpty then
            -- 红点特殊处理 因为会随角色列表的空状态消失，不受其他功能影响
            if targetBtn.gameObject.name == XEnumConst.Filter.TagName.BtnRed then
                -- 将红点按钮移出可选按钮队列
                -- local _, index = table.contains(self.AllCanSelectTags, targetBtn)
                -- if index then
                --     table.remove(self.AllCanSelectTags, index)
                -- end
                -- 没有红点角色时按钮隐藏
                -- 有红点角色但选中的效应没有红点角色 按钮显示+飘字
                local isSourceDataEmpty = XTool.IsTableEmpty(self.SourceRedCharacterList)
                if isSourceDataEmpty then
                    targetBtn.gameObject:SetActiveEx(false) -- 注意：在refreshList时还会再检查一遍红点是否显示，那里也会可能将红点标签隐藏
                    self:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, force, selectCharId)
                else
                    targetBtn.gameObject:SetActiveEx(true)
                    XUiManager.TipText("CharacterGeneralSkillTip")
                end
                return
            end

            if not self.CurSelectTagBtn or XTool.UObjIsNil(self.CurSelectTagBtn) then
                self:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, force, selectCharId)
                return
            end

            if self:HasGeneralSkillFilter() then
                XUiManager.TipText("CharacterGeneralSkillTip")
                return
            end

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
                self:DoSelectCharacter(selectCharId, force)
            end
            return
        end
        self.ImportListTrigger = nil -- 只要执行了强制排序 就将触发器关闭，就算手动开启了触发器，但是不通过刷新调用，而是通过其他接口调用选择标签进行到此处，也会关闭触发器

        self.CurSelectTagBtn = targetBtn
        self._CacheSortList = nil -- 当前的列表数据(有排序)。每次切换tag清空，因为有可能数据有变化。清空此数据会触发重新排序
        self._CurShowCharList = filtDataRes -- 缓存当前的列表数据(有排序)
        if self.OnTagClickCb then
            self.OnTagClickCb(targetBtn)
        end

        if selectCharId then
            self:DoSelectCharacter(selectCharId, force)
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
function XUiPanelCommonCharacterFilterV2P6:_InitButton()
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
---@param overrideSortTable table 是否重写排序算法由程序员决定，追加的排序算法也可以使用此列表。传入的table必须以{CheckFunList ={}, SortFunList{}}，且CheckFunList，SortFunList应该使用枚举CharacterSortFunType为key
function XUiPanelCommonCharacterFilterV2P6:InitData(onChangeCharcterCb, onTagClickCb, stageId, refreshGridFuns, gridProxy, checkInTeamFun, overrideSortTable)
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
    self.OverrideSortTable = overrideSortTable

    self.ControllerConfig = XMVCA.XCharacter:GetModelCharacterFilterController()[self.Parent.Name]
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
    self:_InitButton()
    self:_InitTags()
    self:_InitDynamicTable()
    self:SetIsEarlyOnSelectTrigger()
    self:InitGeneralSkill()
end

function XUiPanelCommonCharacterFilterV2P6:_InitTags()
    self.EnableElementTags = {}
    self:_InitElementTagsData()
    self:_CreateTagsUi()
    self:_InitFoldTag()
end

function XUiPanelCommonCharacterFilterV2P6:_InitElementTagsData()
    local allElements = XMVCA.XCharacter:GetModelCharacterElement()
    local checkFun = function (id)
        if table.contains(self.HideElementTags, id) then
            return false
        end

        return true
    end

    for elementId, v in pairs(allElements) do
        if checkFun(elementId) and elementId <= XEnumConst.Filter.MaxEnableElementNum then --目前就5种元素
            table.insert(self.EnableElementTags, elementId)
        end
    end
end

function XUiPanelCommonCharacterFilterV2P6:_CreateTagsUi()
    -- 元素标签
    local allElements = XMVCA.XCharacter:GetModelCharacterElement()
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
    local grid = self.DynamicTable:GetGrid()
    if grid and grid.gameObject then
        grid.gameObject:SetActiveEx(false)
    end
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
        if charId == self:_GetCharIdFun(char) then
            index = k
            curChar = char
        end
    end

    return index, curChar
end

function XUiPanelCommonCharacterFilterV2P6:GetGridByCharId(charId)
    local index = self:GetCharInCurListIndex(charId)
    local grid = self.DynamicTable:GetGridByIndex(index)
    return grid
end

-- 检查标签是否显示
function XUiPanelCommonCharacterFilterV2P6:CheckTagIsActiveUse(tagName)
    local btn = self[tagName]
    if not btn then
        return false
    end

    -- 如果标签没有启用
    if not btn.gameObject.activeSelf then
        return false
    end

    return true
end

-- 可供外部手动调用，手动选择标签。注意，这个函数会自动调用 RefreshList
---@param isForce boolean:若重复选择相同的tag false:不会调用RefreshList，不会刷新和排序。true:强制调用RefreshList，且刷新排序
---@param charId number:将在选择tag后自动选择角色，且只调用一次RefreshList。
function XUiPanelCommonCharacterFilterV2P6:DoSelectTag(tagName, isForce, charId)
    local btn = self[tagName]
    if not btn then
        return
    end

    -- 如果标签没有启用
    if not btn.gameObject.activeSelf then
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
    if self.CurSelectTagBtn ~= btn then
        return
    end
    self.PanelCharacterTypeBtns:SelectIndex(index)
    self.IsFirstSelectTag = true
end

-- 可供外部手动调用。选中当前列表里的角色，如果没有则不执行
--- func desc
---@param charId number
---@param needSelect boolean 为true时 就算角色不在当前列表 也强制选中当前列表的第一个角色
function XUiPanelCommonCharacterFilterV2P6:DoSelectCharacter(charId, needSelect)
    if not XTool.IsNumberValid(charId) then
        return
    end

    local curTag = self.CurSelectTagBtn
    if not curTag then
        XLog.Error("执行DoSelectCharacter前，请先执行DoSelectTag")
    end
    
    local curChar = nil
    local index = nil
    index, curChar = self:GetCharInCurListIndex(charId)
    -- 角色不在列表的话默认选中第一个
    if not index then
        if needSelect then
            index = 1
        else
            return
        end
    end

    self:_DoSetGirdSelectStatusByCharId(charId)
    self:RefreshList(index)
end

-- 可供外部手动调用。选中当前列表的下标的角色
function XUiPanelCommonCharacterFilterV2P6:DoSelectIndex(index)
    local list = self:GetCurShowList()
    if index > #list then
        return
    end

    self:RefreshList()
end

-- 在禁用自动选择开启的时候该方法才生效。将某个角色切换成选中框状态
function XUiPanelCommonCharacterFilterV2P6:_DoSetGirdSelectStatusByCharId(charId)
    self.ForeceSelectCharIdTrigger = charId
end

-- 外部手动调用. 筛选器导入数据后必须通过DoSelectTag才能将CurShowList替换掉。只清空CurShowList和CacheSeleList是没用的，因为清空这两个数据只会触发重新排序，还是在原来的CurShowList数据上排序
-- 没有真正替换到SourceList
function XUiPanelCommonCharacterFilterV2P6:ImportList(characterList, afterInitSeleCharId)
    if XTool.IsTableEmpty(characterList) then
        return
    end
    
    -- 检测是否剔除还没解锁的角色
    if not self.ControllerConfig or not self.ControllerConfig.EnableShowFragment then
        local res = {}
        for k, character in pairs(characterList) do
            local id = self:_GetCharIdFun(character)
            if not XMVCA.XCharacter:CheckIsFragment(id) then
                table.insert(res, character)
            end
        end
        characterList = res
    end

    -- 过滤独域机体
    if self.HideIsomerTag then
        local res = {}
        for k, character in pairs(characterList) do
            local id = self:_GetCharIdFun(character)
            if XRobotManager.CheckIsRobotId(id) then
                id = XRobotManager.GetCharacterId(id)
            end
            if not XMVCA.XCharacter:GetIsIsomer(id) then
                table.insert(res, character)
            end
        end
        characterList = res
    end

    -- 玩家自机/机器人 源数据列表
    self.SourceCharacterList = characterList

    -- 导入后刷新，不改变标签
    afterInitSeleCharId = XTool.IsNumberValid(afterInitSeleCharId) and afterInitSeleCharId or nil
    self._AfterInitSeleCharId = afterInitSeleCharId

    -- 导入后trigger
    -- 该trigger的作用：如果重复选择同一个标签是不会刷新最新的排序数据的。该trigger为true后，下一次刷新时会触发一次强制排序，且强制调用OnSelectTag回调
    self.ImportListTrigger = true
end

-- 外部手动调用，开启支援选项
function XUiPanelCommonCharacterFilterV2P6:ImportSupportList(characterList)
    -- 好友/公会支援 数据列表
    self.SupportCharacterList = characterList
    self.ImportListTrigger = true
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

-- 是否加载完源数据
function XUiPanelCommonCharacterFilterV2P6:IsImportListComplete()
    return self.SourceCharacterList ~= nil
end

-- 是否第一次加载完可视数据
function XUiPanelCommonCharacterFilterV2P6:IsFirstRefreshComplete()
    return self.IsFirstRefresh
end

-- 是否完成第一次排序
function XUiPanelCommonCharacterFilterV2P6:IsFirstSortComplete()
    return self.IsFirstSort
end

-- 是否完成第一次筛选项选择(包含初始化的自动选择)
function XUiPanelCommonCharacterFilterV2P6:IsFirstSelectTagComplete()
    return self.IsFirstSelectTag
end

function XUiPanelCommonCharacterFilterV2P6:IsCurListEmpty()
    local dataList = self:GetCurShowList()
    return XTool.IsTableEmpty(dataList)
end

function XUiPanelCommonCharacterFilterV2P6:ShowEmpty(showEmpty)
    self.PanelEmptyList.gameObject:SetActiveEx(showEmpty)
end

---@param forceIndex number
---@param forceReSort boolean 强制刷新列表数据和排序
---@param isEarlyOnSelect boolean 提前于刷新动态列表【调用选中角色回调】(每次传参只触发一次)，注意通过这个参数调用的回调不会带grid      
function XUiPanelCommonCharacterFilterV2P6:RefreshList(forceIndex, forceResort, isEarlyOnSelect)
    if XTool.IsTableEmpty(self.SourceCharacterList) then
        XLog.Warning("[XUiPanelCommonCharacterFilterV2P6] 空角色列表")
        return
    end
    
    if isEarlyOnSelect then
        self:SetIsEarlyOnSelectTrigger()
    end

    local curTag = self.CurSelectTagBtn
    if not curTag then -- 默认选中BtnAll
        self:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true, self._AfterInitSeleCharId)
        self._AfterInitSeleCharId = nil
        return
    end

    if self.ImportListTrigger then
        self:DoSelectTag(curTag.gameObject.name, true, self._AfterInitSeleCharId)
        self._AfterInitSeleCharId = nil
        return
    end

    self._SelectTagName = curTag.gameObject.name
    local dataList = self:GetCurShowList(forceResort)
    if not dataList then
        return
    end

    local index = 1
    -- 暂时关闭缓存标签角色功能
    -- local cacheChar = self.CacheTagSelectChar[self.CurSelectTagBtn] or dataList[1]
    local cacheChar = self.LastSelectCharacter
    if cacheChar then
        index = self:GetCharInCurListIndex(self:_GetCharIdFun(cacheChar)) or index
    end

    -- 检查是否缓存了当前页签选中过的角色 ，forceIndex的优先级大于缓存角色的优先级
    index = forceIndex or index
    
    local showEmpty = XTool.IsTableEmpty(dataList)
    self:ShowEmpty(showEmpty)
    self.TxtNone.text = CS.XTextManager.GetText("EmptyCharacter")
    if self.CurSelectTagBtn.gameObject.name == XEnumConst.Filter.TagName.BtnSupport then -- 支援标签的空文本不一样
        self.TxtNone.text = CS.XTextManager.GetText("EmptySupporter")
    end
    local showRedBtn = not self.InitHideRedTag and self:CheckHasRed()
    self.BtnRed.gameObject:SetActiveEx(showRedBtn)
    -- table.insert(self.AllCanSelectTags, self.BtnRed)
    -- local _, indexT = table.contains(self.AllCanSelectTags, self.BtnRed)
    -- if not indexT and showRedBtn then
    -- elseif indexT and not showRedBtn then
    --     table.remove(self.AllCanSelectTags, indexT)
    -- end

    -- 是否禁用切换标签自动选择格子
    self.CurTargetCharacter = dataList[index]
    if self.ControllerConfig and self.ControllerConfig.DisableAutoSeleGrid then
        self.CurTargetCharacter = nil
    end

    -- index 是让滑动列表定位的。 CurTargetCharacter是让刷新列表时激活对应格子选中状态的
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataASync(index)
    self.IsFirstRefresh = true

    -- 提前刷新
    if self.IsEarlyOnSelectTrigger then
        self.IsEarlyOnSelectTrigger = nil
        if self.CurTargetCharacter then
            self:OnSelect(self.CurTargetCharacter, index)
        end
    end
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
    local sortFunList = { CharacterSortFunType.InTeam, CharacterSortFunType.Level, CharacterSortFunType.Ability, CharacterSortFunType.GeneralElement, CharacterSortFunType.Quality, CharacterSortFunType.Priority } -- 默认的排序算法
    if not XTool.IsTableEmpty(self.SortTagList) then
        sortFunList = self.SortTagList
    end

    -- 检查是否有重写的排序算法。
    local overrideList = self.OverrideSortTable
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

    local sortRes = XMVCA.XCommonCharacterFilter:DoSortFilterV2P6(self._CurShowCharList, sortFunList, nil, overrideList, self.GetIdFun)
    self._CurShowCharList = sortRes
    self._CacheSortList = sortRes
    self.IsFirstSort = true

    return self._CurShowCharList
end

---@param grid XGridCharacterV2P6
function XUiPanelCommonCharacterFilterV2P6:OnDynamicTableEventCharacterList(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local char = self:GetCurShowList()[index]
        -- CurTargetCharacter 自动选择，如果没有自动选择，则SetSelect不要清除掉手动选择的LastSelectCharacter选中框
        local isCurChar = (self.CurTargetCharacter or self.LastSelectCharacter) == char
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
            if self.ControllerConfig and self.ControllerConfig.DisableAutoSeleGrid and self.ForeceSelectCharIdTrigger and self.ForeceSelectCharIdTrigger == self:_GetCharIdFun(char) then
                grid:SetSelect(true)
            else
                grid:SetSelect(isCurChar)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local char = self:GetCurShowList()[index]
        self:OnSelect(char, index, grid)
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
    if self.ForceSeleCbTrigger then
        self.ForceSeleCbTrigger = nil
        goto countinueDoSelect
    end

    if self.NextNotOnSelectTrigger then
        self.NextNotOnSelectTrigger = nil
        return
    end

    if self.LastSelectCharacter == char and not self.HasDisabled then
        return
    end

    ::countinueDoSelect::
    self.OnSeleCharacterCb(char, index, grid, self.FirstSelect)
    self.CacheTagSelectChar[self.CurSelectTagBtn] = char

    -- 如果禁用自动选择 则不会记录上一次选择的角色  以免刷新时会将框刷出来
    if not (self.ControllerConfig and self.ControllerConfig.DisableAutoSeleGrid) then
        self.LastSelectCharacter = char
    end

    self.CurTargetCharacter = nil -- 选中目标后清除自动选则的目标数据
    self.FirstSelect = false
    self.HasDisabled = false
end

-- 所有筛选项tag的点击回调 begin
function XUiPanelCommonCharacterFilterV2P6:DoFiltAllClick()
    return self:CheckGeneralSkillFilter(self.SourceCharacterList)
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltElementTagClick(tagId)
    local tagaData = self.IsHideGeneralSkill and { Element = { tagId } } or { Elements = { tagId } } -- Elements会筛选效应元素
    self:CheckAddGeneralSkillFilter(tagaData)
    return XMVCA.XCommonCharacterFilter:DoFilter(self.SourceCharacterList, tagaData)
end

function XUiPanelCommonCharacterFilterV2P6:DoFiltUniframe()
    local tagaData = { Career = {4} } -- 先锋型的职业id是 4
    self:CheckAddGeneralSkillFilter(tagaData)
    return XMVCA.XCommonCharacterFilter:DoFilter(self.SourceCharacterList, tagaData)
end

-- 检查当前是否有红点角色
function XUiPanelCommonCharacterFilterV2P6:CheckHasRed()
    local sources = self:CheckGeneralSkillFilter(self.SourceCharacterList)
    for k, character in pairs(sources) do
        if not XRobotManager.CheckIsRobotId(self:_GetCharIdFun(character)) and XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER, XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY}, self:_GetCharIdFun(character)) then
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
    local sources = self:CheckGeneralSkillFilter(self.SourceCharacterList)
    for k, character in pairs(sources) do
        if not XRobotManager.CheckIsRobotId(self:_GetCharIdFun(character)) and XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER, XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY}, self:_GetCharIdFun(character)) then
            table.insert(res, character)
        end
    end

    self.SourceRedCharacterList = res
    return self:CheckGeneralSkillFilter(res)
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

    return self:CheckGeneralSkillFilter(self.DiyLists[diyIndex])
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
    local charIdBeforeFold = self.LastSelectCharacter and self:_GetCharIdFun(self.LastSelectCharacter)
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

    -- 折叠后自动选择全选标签 但是还是要选择之前的角色
    self:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true, charIdBeforeFold)
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

function XUiPanelCommonCharacterFilterV2P6:GetCurSelectTagName()
    if not self.CurSelectTagBtn then
        return
    end

    if XTool.UObjIsNil(self.CurSelectTagBtn) then
        return
    end

    return self.CurSelectTagBtn.gameObject.name
end

function XUiPanelCommonCharacterFilterV2P6:IsTagSupport()
    return self.CurSelectTagBtn == self.BtnSupport
end

-- 下一次刷新不排序
function XUiPanelCommonCharacterFilterV2P6:SetNotSortTrigger()
    self.NotSort = true
end

-- 下一次刷新强制调用选中回调
function XUiPanelCommonCharacterFilterV2P6:SetForceSeleCbTrigger()
    self.ForceSeleCbTrigger = true
end

-- 下一次触发OnSelect也不调用，优先级比 ForceSeleCbTrigger 低
function XUiPanelCommonCharacterFilterV2P6:SetNextNotOnSelectTrigger()
    self.NextNotOnSelectTrigger = true
end

function XUiPanelCommonCharacterFilterV2P6:SetIsEarlyOnSelectTrigger()
    self.IsEarlyOnSelectTrigger = true
end

function XUiPanelCommonCharacterFilterV2P6:SetPlayUiFoldAnim(isPlay)
    self.IsPlayUiFoldAnim = isPlay
end

function XUiPanelCommonCharacterFilterV2P6:PlayAnimation(animeName, finCb)
    if self.IsPlayUiFoldAnim then
        local uiAnim = self.Parent.Transform:Find("Animation"):FindTransform(animeName)
        if not XTool.UObjIsNil(uiAnim) and uiAnim.gameObject.activeInHierarchy then
            uiAnim:PlayTimelineAnimation()
        end
    end

    local animTrans = self.Transform:Find("Animation"):FindTransform(animeName)
    if not animTrans.gameObject.activeInHierarchy then
        return
    end
    animTrans:PlayTimelineAnimation(finCb)
end

function XUiPanelCommonCharacterFilterV2P6:StopAnimation(animeName, isTriggerFinishCallBack, isEvaluate)
    local animTrans = self.Transform:Find("Animation"):FindTransform(animeName)
    if not animTrans.gameObject.activeInHierarchy then
        return
    end
    animTrans:StopTimelineAnimation(isTriggerFinishCallBack, isEvaluate)
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
    self.HasDisabled = true
    local key = "XUiPanelCommonCharacterFilterV2P6"..self.Parent.Name
    XSaveTool.SaveData(key, self.IsFold)
    self:CloseGeneralSkillPanel()
end

function XUiPanelCommonCharacterFilterV2P6:OnDestroy()
    self:StopFoldAnim()
    XMVCA.XCommonCharacterFilter:RemoveFilterProxyByTransfrom(self.Transform)
    XMVCA.XCommonCharacterFilter:SetLastUseFilter(nil)
end


--region v2.14 效应筛选

function XUiPanelCommonCharacterFilterV2P6:InitGeneralSkill()
    self:CloseGeneralSkillPanel()
    local btnType = self.ControllerConfig and self.ControllerConfig.BtnGeneralSkillType or CS.XGame.ClientConfig:GetInt("DefaultShowCharacterBtnSKillType")
    if not self.IsHideGeneralSkill and btnType == XEnumConst.Filter.BtnGeneralSkillType.Left then
        self.BtnSkillLeft.gameObject:SetActiveEx(true)
        self.BtnSkillBottom.gameObject:SetActiveEx(false)
        self.BtnBg.gameObject:SetActiveEx(false)
    elseif not self.IsHideGeneralSkill and btnType == XEnumConst.Filter.BtnGeneralSkillType.Bottom then
        self.BtnSkillLeft.gameObject:SetActiveEx(false)
        self.BtnSkillBottom.gameObject:SetActiveEx(true)
        self.BtnBg.gameObject:SetActiveEx(true)
    else
        self.BtnSkillLeft.gameObject:SetActiveEx(false)
        self.BtnSkillBottom.gameObject:SetActiveEx(false)
        self.BtnBg.gameObject:SetActiveEx(false)
        return
    end

    self:InitGeneralSkillList()
    self:OnChooseGeneralSkill(0) -- 默认选择全部

    XUiHelper.RegisterClickEvent(self, self.BtnSkillLeft, self.OpenGeneralSkillPanel)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillBottom, self.OpenGeneralSkillPanel)
    XUiHelper.RegisterClickEvent(self, self.BtnEmpty, self.CloseGeneralSkillPanel)
end

--- 外部设置是否屏蔽效应相关逻辑（效应元素和效应筛选）
function XUiPanelCommonCharacterFilterV2P6:SetHideGeneralSkill(isHide)
    self.IsHideGeneralSkill = isHide
end

function XUiPanelCommonCharacterFilterV2P6:InitCharacterGeneralSkill()
    self._GeneralSkillMap = {}
    for _, char in pairs(self.SourceCharacterList) do
        local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(char.Id)
        for _, skillId in pairs(generalSkillIds) do
            if not self._GeneralSkillMap[skillId] then
                self._GeneralSkillMap[skillId] = true
            end
        end
    end
end

function XUiPanelCommonCharacterFilterV2P6:OpenGeneralSkillPanel()
    if self:IsTagSupport() then
        XUiManager.TipText("GeneralSkillSupportFilterTip")
        return
    end

    self:StopAnimation("PanelGeneralSkillDisable", false)
    self.PanelGeneralSkill.gameObject:SetActiveEx(true)
    self:InitCharacterGeneralSkill()
    self:PlayAnimation("PanelGeneralSkillEnable")
    for i, uiObject in ipairs(self._GridSkillAnims) do
        uiObject.CanvasGroup.alpha = 0
        self._GridSkillTimers[i] = XScheduleManager.ScheduleOnce(function()
            uiObject.GridSkillEnable:PlayTimelineAnimation()
        end, i * 80)
    end
end

function XUiPanelCommonCharacterFilterV2P6:CloseGeneralSkillPanel()
    if self._GridSkillTimers then
        for _, timer in pairs(self._GridSkillTimers) do
            XScheduleManager.UnSchedule(timer)
        end
        self._GridSkillTimers = {}
    end
    self:StopAnimation("PanelGeneralSkillEnable", false)
    self:PlayAnimation("PanelGeneralSkillDisable", function()
        self.PanelGeneralSkill.gameObject:SetActiveEx(false)
    end)
end

function XUiPanelCommonCharacterFilterV2P6:InitGeneralSkillList()
    local configs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()
    local count = #configs
    self._GridSkills = {}
    self._GridSkillAnims = {}
    self._GridSkillTimers = {}
    XUiHelper.RefreshCustomizedList(self.GridSkill.parent, self.GridSkill, count + 1, function(index, grid)
        local id
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        if index <= count then
            local config = configs[index]
            id = config.Id
            uiObject.BtnSingle.gameObject:SetActiveEx(true)
            uiObject.BtnAll.gameObject:SetActiveEx(false)
            uiObject.BtnSingle:SetRawImage(config.IconTranspose)
            uiObject.BtnSingle:SetNameByGroup(0, config.Name)
            uiObject.BtnSingle.CallBack = function()
                self:OnClickGridGeneralSkill(id)
            end
        else
            id = 0
            uiObject.BtnSingle.gameObject:SetActiveEx(false)
            uiObject.BtnAll.gameObject:SetActiveEx(true)
            uiObject.BtnAll.CallBack = function()
                self:OnClickGridGeneralSkill(id)
            end
        end
        self._GridSkills[id] = uiObject
        table.insert(self._GridSkillAnims, uiObject)
    end)
end

function XUiPanelCommonCharacterFilterV2P6:OnClickGridGeneralSkill(id)
    if id ~= 0 and not self._GeneralSkillMap[id] then
        XUiManager.TipText("GeneralSkillCharacterEmpty")
        return
    end
    self:OnChooseGeneralSkill(id)
    self:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true)
    self:CloseGeneralSkillPanel()
    self:UpdateElementStateByGeneralSkill()
end

function XUiPanelCommonCharacterFilterV2P6:OnChooseGeneralSkill(id)
    self._CurChooseSkillId = id
    for skillId, uiObject in pairs(self._GridSkills) do
        if id == skillId then
            if skillId == 0 then
                local txtAll = XUiHelper.GetText("CharacterGeneralSkillAll")
                self.BtnSkillLeft:SetRawImageVisible(false)
                self.BtnSkillLeft:SetNameByGroup(0, XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("CharacterGeneralSkillDesc2", txtAll)))
                self.BtnSkillBottom:SetRawImageVisible(false)
                self.BtnSkillBottom:SetNameByGroup(0, XUiHelper.GetText("CharacterGeneralSkillDesc1", txtAll))
            else
                local configs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()
                self.BtnSkillLeft:SetRawImageVisible(true)
                self.BtnSkillLeft:SetRawImage(configs[skillId].IconTranspose)
                self.BtnSkillLeft:SetNameByGroup(0, XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("CharacterGeneralSkillDesc2", "")))
                self.BtnSkillBottom:SetRawImageVisible(true)
                self.BtnSkillBottom:SetRawImage(configs[skillId].IconTranspose)
                self.BtnSkillBottom:SetNameByGroup(0, XUiHelper.GetText("CharacterGeneralSkillDesc1", ""))
            end
            uiObject.ImgChoose.gameObject:SetActiveEx(true)
        else
            uiObject.ImgChoose.gameObject:SetActiveEx(false)
        end
    end

    if self.BtnSupport.gameObject.activeSelf then
        self.BtnSupport:SetButtonState(XTool.IsNumberValid(id) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
end

function XUiPanelCommonCharacterFilterV2P6:HasGeneralSkillFilter()
    return XTool.IsNumberValid(self._CurChooseSkillId)
end

function XUiPanelCommonCharacterFilterV2P6:CheckAddGeneralSkillFilter(tagaData)
    if self:HasGeneralSkillFilter() then
        tagaData.GeneralSkill = { self._CurChooseSkillId }
    end
end

function XUiPanelCommonCharacterFilterV2P6:CheckGeneralSkillFilter(source)
    if self:HasGeneralSkillFilter() then
        local tagData = { GeneralSkill = { self._CurChooseSkillId } }
        return XMVCA.XCommonCharacterFilter:DoFilter(source, tagData)
    end
    return source
end

function XUiPanelCommonCharacterFilterV2P6:UpdateElementStateByGeneralSkill()
    local hasGeneralSkill = self:HasGeneralSkillFilter()

    local datas
    for _, tagId in ipairs(self.EnableElementTags) do
        local btn = self["BtnTag" .. tagId]
        if btn then
            if hasGeneralSkill then
                datas = self:DoFiltElementTagClick(tagId)
                btn:SetButtonState(XTool.IsTableEmpty(datas) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
            else
                btn:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    end

    if hasGeneralSkill then
        datas = self:DoFiltUniframe()
        self.BtnUniframe:SetButtonState(XTool.IsTableEmpty(datas) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

        datas = self:DoFiltRedClick()
        self.BtnRed:SetButtonState(XTool.IsTableEmpty(datas) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    else
        self.BtnUniframe:SetButtonState(CS.UiButtonState.Normal)
        self.BtnRed:SetButtonState(CS.UiButtonState.Normal)
    end

    if self.ControllerConfig then
        for k, tagName in ipairs(self.ControllerConfig.DiyTagNames) do
            local btn = self[tagName]
            if btn then
                if hasGeneralSkill then
                    datas = self:DoFiltDiy(k)
                    btn:SetButtonState(XTool.IsTableEmpty(datas) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
                else
                    btn:SetButtonState(CS.UiButtonState.Normal)
                end
            end
        end
    end
end

--endregion

return XUiPanelCommonCharacterFilterV2P6