XUiPanelCharacterList = XClass(nil, "XUiPanelCharacterList")

local TextManager = CS.XTextManager
local tableInsert = table.insert
local tableSort = table.sort

local Sort = function(a, b)
    if a.IsLocked ~= b.IsLocked then
        return not a.IsLocked
    end
    if a.Data.Quality ~= b.Data.Quality then
        return a.Data.Quality > b.Data.Quality
    end
    if a.Data.Level ~= b.Data.Level then
        return a.Data.Level > b.Data.Level
    end
    return a.Data.Id > b.Data.Id
end

function XUiPanelCharacterList:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)

    self.AllCharList = {}           --全部成员
    self.CharacterList = {}         --展示的成员
    self:InitDynamicTable()
end

function XUiPanelCharacterList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicTable:SetProxy(XUiPlayerInfoCharacterGrid)
    self.DynamicTable:SetDelegate(self)
    self.PlayerInfoCharacterGrid.gameObject:SetActiveEx(false)
end

function XUiPanelCharacterList:Show()
    self.GameObject:SetActiveEx(true)
    self.PanelScore.gameObject:SetActiveEx(true)
    self.AppearanceShowType = self.RootUi.Data.AppearanceShowType or XPlayerInfoConfigs.CharactersAppearanceType.All

    if self.RootUi.IsOpenFromSetting then
        --从设置面板进入，使用预览数据
        for _,v in  pairs(self.RootUi.Data.CharacterShow) do
            local temData = { Data = v, IsLocked = false }
            tableInsert(self.CharacterList, temData)
        end
        self:Refresh(true)
    else
        self:Refresh()
        if self:HasPermission() then
            XDataCenter.PlayerInfoManager.RequestPlayerCharacterListData(self.RootUi.Data.Id, function(data)
                for _,v in pairs(data)  do
                    local temData = { Data = v, IsLocked = false }
                    tableInsert(self.CharacterList, temData)
                end
                self:Refresh(true)
            end)
        end
    end
end

function XUiPanelCharacterList:Refresh(hasPermission)
    local hasCharacterDisplay = self:HasCharacterDisplay()
    self:SetupDynamicTable(hasPermission,hasCharacterDisplay)
end

function XUiPanelCharacterList:SetupDynamicTable(hasPermission, hasCharacterDisplay, index)
    self.DynamicTable:SetDataSource(self:HandleData(hasPermission,hasCharacterDisplay))
    self.DynamicTable:ReloadDataSync(index and index or 1)
end

--==============================--
--desc: 是否拥有权限查看信息
--@return: 有true，无false
--==============================--
function XUiPanelCharacterList:HasPermission()
    self.AppearanceSettingInfo = self.RootUi.Data.AppearanceSettingInfo and
            self.RootUi.Data.AppearanceSettingInfo.CharacterType or XUiAppearanceShowType.ToSelf

    local isFriend = XDataCenter.SocialManager.CheckIsFriend(self.RootUi.Data.Id)
    local hasPermission = (self.AppearanceSettingInfo == XUiAppearanceShowType.ToAll)
            or (self.AppearanceSettingInfo == XUiAppearanceShowType.ToFriend and isFriend)
    return hasPermission
end

--==============================--
--desc: 自选成员展示时是否有设置成员
--==============================--
function XUiPanelCharacterList:HasCharacterDisplay()
    --展示类型为自选成员，没有设置成员时返回false
    local hasCharacterDisplay = not (self.AppearanceShowType == XPlayerInfoConfigs.CharactersAppearanceType.Select and #self.CharacterList < 1)
    return hasCharacterDisplay
end

--==============================--
--desc: 处理动态列表的数据源
--@return: 有序的成员表，全部展示包括未拥有成员
--==============================--
function XUiPanelCharacterList:HandleData(hasPermission, hasCharacterDisplay)
    local isLoadData = hasPermission and hasCharacterDisplay

    if not isLoadData then
        self.PanelScore.gameObject:SetActiveEx(false)
        self.PanelCharacterNone.gameObject:SetActiveEx(true)
        if not hasPermission then
            self.EmptyText.text = TextManager.GetText("PlayerInfoWithoutPermission")
        else
            self.EmptyText.text = TextManager.GetText("PlayerInfoCharacterEmpty")
        end
        return {}
    end

    self.PanelCharacterNone.gameObject:SetActiveEx(false)

    if self.AppearanceShowType == XPlayerInfoConfigs.CharactersAppearanceType.All then
        -- 全成员展示，数据源包括未解锁成员
        local score = 0
        local allCharList = {}          --最终数据，拥有成员排在前面
        local characterListById = {}    --拥有成员字典,Id做索引，用来查询未解锁成员

        for _, v in ipairs(self.CharacterList) do
            characterListById[v.Data.Id] = v
            local characterShowScoreList = XPlayerInfoConfigs.GetCharacterShowScore(v.Data.Id)
            local addScore = characterShowScoreList[v.Data.Quality] and characterShowScoreList[v.Data.Quality] or 0
            score = score + addScore
        end
        self.PanelScore.gameObject:SetActiveEx(true)
        self.TxtScore.text = score

        for k, v in pairs(XCharacterConfigs.GetCharacterTemplates()) do
            local temData = { IsLocked = true }
            if characterListById[k] then
                tableInsert(allCharList, characterListById[k])
            else
                temData.Data = v
                tableInsert(allCharList, temData)
            end
        end

        tableSort(allCharList, function(item1, item2) return Sort(item1, item2) end)

        self.AllCharList = allCharList

        return allCharList
    else
        -- 自选成员展示，数据源不包括未解锁成员
        self.PanelScore.gameObject:SetActiveEx(false)

        return self.CharacterList
    end
end

function XUiPanelCharacterList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi.Data.Id)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.AppearanceShowType == XPlayerInfoConfigs.CharactersAppearanceType.All then
            grid:UpdateGrid(self.AllCharList[index], self.AppearanceShowType, self.RootUi.Data.AssistCharacterDetail)
        else
            grid:UpdateGrid(self.CharacterList[index], self.AppearanceShowType, self.RootUi.Data.AssistCharacterDetail)
        end
    end
end

function XUiPanelCharacterList:Close()
    self.AllCharList = {}
    self.CharacterList = {}
    self.AppearanceShowType = nil
    self.GameObject:SetActiveEx(false)
end