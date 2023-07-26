local XUiCommonCharacterFilterTipsSort = XLuaUiManager.Register(XLuaUi, "UiCommonCharacterFilterTipsSort")
local XUiGridSortTagGroup = require("XUi/XUiCommonCharacterOptimization/XUiGridSortTagGroup")
-- 通用构造体角色排序界面

function XUiCommonCharacterFilterTipsSort:OnAwake()
    self.Grids = {}
    self.SelectTagType = CharacterSortTagType.Default    --排序的选择框是单选框，默认选择默认选项

    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSortClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
end

--- func desc
---@param characterList 传入以有存在字段名为Id值为CharacterID数据组成的构造体角色顺序表list etc:{ [1] = {Id = CharacterId}，[2] = {Id = CharacterId}...}
---@param cacheKeyName 缓存排序项并可查找其信息的keyName
---@param sortCb 排序器确认回调
function XUiCommonCharacterFilterTipsSort:OnStart(characterList, cacheKeyName, isAscendOrder, sortCb)
    self.CharacterList = characterList
    self.SortCb = sortCb
    self.CacheKeyName = cacheKeyName
    self.IsAscendOrder = isAscendOrder
end

function XUiCommonCharacterFilterTipsSort:OnEnable()
    self:RefreshSelectSortTag()
end

-- 选择标签(包括取消选中)
function XUiCommonCharacterFilterTipsSort:OnTagClick(tagType)
    self.SelectTagType = tagType
    for _, grid in pairs(self.Grids) do
        if grid.Id ~= tagType then
            grid:CancelSelect()
        end
    end
end

-- 生成并刷新UI选择项状态（记录了上一次使用的排序项状态）
function XUiCommonCharacterFilterTipsSort:RefreshSelectSortTag()
    local selectTagType = XDataCenter.CommonCharacterFiltManager.GetSortData(self.CacheKeyName)
    if selectTagType then -- 检测是否有上一次缓存过的排序tag信息
        self.SelectTagType = selectTagType
    end

    -- 生成排序项(UI表示排序项他拼好在ui里，不需要程序读表自动生成，所以排序项的gameObject名字要和Id严格一致)
    for tagTypeName, sortTagIndex in pairs(CharacterSortTagType) do
        local go = self.Panel.transform:Find(sortTagIndex)
        local grid = XUiGridSortTagGroup.New(go, self, sortTagIndex, self.SelectTagType == sortTagIndex)
        table.insert(self.Grids, grid)
    end
end

-- 点击排序
function XUiCommonCharacterFilterTipsSort:OnBtnSortClick()
    local resultSortList = XDataCenter.CommonCharacterFiltManager.DoSort(self.CharacterList, self.SelectTagType, self.IsAscendOrder)

    if self.SortCb then
        self.SortCb(resultSortList)
    end

    -- 排序时缓存
    local characterType = XCharacterConfigs.GetCharacterType(self.CharacterList[1].Id)
    XDataCenter.CommonCharacterFiltManager.SetSortData(self.SelectTagType, characterType) -- 自动缓存
    XDataCenter.CommonCharacterFiltManager.SetSelectListData(resultSortList, self.CacheKeyName)

    self:Close()
end

function XUiCommonCharacterFilterTipsSort:OnBtnBackClick()
    self:Close()
end

return XUiCommonCharacterFilterTipsSort