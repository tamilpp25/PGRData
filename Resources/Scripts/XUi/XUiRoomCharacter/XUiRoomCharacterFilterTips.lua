local XUiRoomCharacterFilterTips = XLuaUiManager.Register(XLuaUi, "UiRoomCharacterFilterTips")

local XUiGridFilterTagGroup = require("XUi/XUiRoomCharacter/XUiGridFilterTagGroup")

function XUiRoomCharacterFilterTips:OnAwake()
    self.FilterTagGroupList = {}
    self.SortTagBtnList = {}
    self.SortTagIdList = {}
    self.HideSortTagDic = nil
    self:InitComponent()
    self:AddListener()
end

-- hideSortTagDic : { [XRoomCharFilterTipsConfigs.EnumSortTag.xxx] = true } 即为隐藏
function XUiRoomCharacterFilterTips:OnStart(rootUi, filterType, sortType, characterType, hideFilter, hideSort, hideSortTagDic)
    hideSortTagDic = hideSortTagDic or {}
    self.RootUi = rootUi
    self.FilterType = filterType
    self.SortType = sortType
    self.CharacterType = characterType
    self.HideFilter = hideFilter
    self.HideSort = hideSort
    self.HideSortTagDic = hideSortTagDic

    XDataCenter.RoomCharFilterTipsManager.InitTemp(characterType)
    self:Refresh()
end

function XUiRoomCharacterFilterTips:Refresh()
    if not self.HideFilter then
        -- 筛选标签组
        self.PanelFilter.gameObject:SetActiveEx(true)
        local filterTagGroups = XRoomCharFilterTipsConfigs.GetFilterTagGroups(self.FilterType)
        for _, groupId in ipairs(filterTagGroups) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridFilterTagGroup)
            obj.transform:SetParent(self.FilterContent, false)
            obj.gameObject:SetActiveEx(true)

            local gridGroup = XUiGridFilterTagGroup.New(obj, self, groupId)
            gridGroup:Refresh()

            table.insert(self.FilterTagGroupList, gridGroup)
        end
    else
        self.PanelFilter.gameObject:SetActiveEx(false)
    end

    if not self.HideSort then
        -- 排序标签
        self.PanelSort.gameObject:SetActiveEx(true)
        local selectSortTagIndex
        local sortTags = XRoomCharFilterTipsConfigs.GetCharacterSortTags(self.SortType)
        for index, sortTabId in ipairs(sortTags) do
            local tabCharType = XRoomCharFilterTipsConfigs.GetCharacterSortTagCharType(sortTabId)
            if tabCharType == self.CharacterType or tabCharType == 0 then
                -- 排序标签的角色类型为当前的角色类型或通用，则生成
                local btnSortTag = CS.UnityEngine.Object.Instantiate(self.BtnSortTagGrid)
                btnSortTag.transform:SetParent(self.SortContent, false)
                btnSortTag.gameObject:SetActiveEx(true)
                btnSortTag:SetName(XRoomCharFilterTipsConfigs.GetCharacterSortTagName(sortTabId))
            

                self.SortTagBtnList[index] = btnSortTag
                self.SortTagIdList[index] = sortTabId
                if XDataCenter.RoomCharFilterTipsManager.CheckSortTagIsSelect(sortTabId, self.CharacterType) then
                    selectSortTagIndex = index
                end
                -- 隐藏指定的排序类型
                if self.HideSortTagDic[sortTabId] then
                    btnSortTag.gameObject:SetActiveEx(false)
                end
            end
        end

        self.SortGroup:Init(self.SortTagBtnList, function(index) self:OnSortGroupClick(index) end)
        self.SortGroup:SelectIndex(selectSortTagIndex or 1)
    else
        self.PanelSort.gameObject:SetActiveEx(false)
    end
end

function XUiRoomCharacterFilterTips:OnDestroy()
    XDataCenter.RoomCharFilterTipsManager.ClearTemp()
end

function XUiRoomCharacterFilterTips:InitComponent()
    self.GridFilterTagGroup.gameObject:SetActiveEx(false)
    self.BtnSortTagGrid.gameObject:SetActiveEx(false)
end

function XUiRoomCharacterFilterTips:AddListener()
    self.BtnSelect.CallBack = function() self:OnBtnSelectClick() end
    self.BtnCancel.CallBack = function() self:OnCancelClick() end
    self.BtnTanchuangCloseBig.CallBack = function() self:OnCancelClick() end
    self.BtnAllCategory.CallBack = function() self:OnBtnAllCategoryClick() end
end

function XUiRoomCharacterFilterTips:OnBtnAllCategoryClick()
    for _,group in ipairs(self.FilterTagGroupList) do
        group:ClearAllSelectTag()
    end
end

---
--- selectTagGroupDic是一个二维字典
--- Key:筛选组Id
--- Value:标签字典
---
--- 标签字典(组所勾选的标签)
--- Key:标签Id
--- Value:标签Id
function XUiRoomCharacterFilterTips:OnBtnSelectClick()
    if self.RootUi.Filter then
        local sortTagId = XDataCenter.RoomCharFilterTipsManager.GetSelectSortTag()
        local selectTagGroupDic = XDataCenter.RoomCharFilterTipsManager.GetSelectFilterTag()
        self.RootUi:Filter(selectTagGroupDic, sortTagId, function(filteredData)
            return self:IsThereFilterData(filteredData)
        end)
    else
        XLog.Error("XUiRoomCharacterFilterTips:OnBtnSelectClick函数错误，父UI未实现函数Filter")
    end
end

function XUiRoomCharacterFilterTips:IsThereFilterData(filteredData)
    if next(filteredData) == nil then
        XUiManager.TipText("CharacterFilterEmpty")
        return false
    else
        XDataCenter.RoomCharFilterTipsManager.UseTemp(self.CharacterType)
        self:Close()
        return true
    end
end

function XUiRoomCharacterFilterTips:OnSortGroupClick(index)
    XDataCenter.RoomCharFilterTipsManager.SetSelectSortTag(self.SortTagIdList[index])
end

function XUiRoomCharacterFilterTips:OnCancelClick()
    self:Close()
end