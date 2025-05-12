local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- 更换选择助理弹窗界面
local XUiFavorabilityLineRoomCharacterSelect = XLuaUiManager.Register(XLuaUi, "UiFavorabilityLineRoomCharacterSelect")
local XUiGridFavorabilityCharacterSelect = require("XUi/XUiFavorability/XUiGridFavorabilityCharacterSelect")

--region 生命周期
function XUiFavorabilityLineRoomCharacterSelect:OnAwake()
    self.OrgSelected = nil
    self.Count=0
    self.ChangeCache={}
    self:InitButtonEvent()
    self:InitDynamicTable()
end

function XUiFavorabilityLineRoomCharacterSelect:OnStart(currCharacter)
    self.OrgSelected = currCharacter
end

function XUiFavorabilityLineRoomCharacterSelect:OnEnable()
    self:RefreshDynamicTable()
end
--endregion


--region 初始化
function XUiFavorabilityLineRoomCharacterSelect:InitButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiFavorabilityLineRoomCharacterSelect:InitDynamicTable()
    self.DynamicTableCharacter = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTableCharacter:SetProxy(XUiGridFavorabilityCharacterSelect,self)
    self.DynamicTableCharacter:SetDelegate(self)
    self.GridChar.gameObject:SetActiveEx(false)
end
--endregion


--region 数据处理
function XUiFavorabilityLineRoomCharacterSelect:GetCharaterList()
    self.Count=0
    local result = {}
    local charaList = XMVCA.XCharacter:GetCharacterList()
    --筛选
    for k, character in pairs(charaList) do
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(character.Id) 
        if isOwn then
            local isin,index=table.contains(XPlayer.DisplayCharIdList, character.Id)
            if not isin or index~=1 then --不是助理或是但不是首席
                local value =
                {
                    -- 设置默认信任度等级
                    Id = character.Id,
                    TrustLv = character.TrustLv or 1,
                    IsAssistant=isin,
                    IsSelected=isin
                }
                if self.OrgSelected and self.OrgSelected.Id == character.Id then
                    value.IsOrg = true
                    value.IsSelected = true
                end
                table.insert(result, value)
                self.Count= isin and self.Count+1 or self.Count
            end
        end
    end
   
    --排序
    table.sort(result, function (characterA, characterB)
        if characterA.IsOrg ~= characterB.IsOrg then
            return characterA.IsOrg
        end

        if characterA.IsAssistant ~= characterB.IsAssistant then
            return characterA.IsAssistant==true
        end
    
        if characterA.TrustLv == characterB.TrustLv then
            return characterA.Id < characterB.Id
        end
        return characterA.TrustLv > characterB.TrustLv
    end)

    return result
end

-- 将所有的格子设为非选中
function XUiFavorabilityLineRoomCharacterSelect:SetAllGridCancelSelect(exceptId)
    for k, data in pairs(self.CharaList) do
        if data.Id ~= exceptId then -- 排除的格子
            data.IsSelected = false
        end
    end

    -- 并刷新格子状态
    for i = 1, self.DynamicTableCharacter.Imp.TotalCount - 1 do
        local grid = self.DynamicTableCharacter:GetGridByIndex(i)
        if grid then
            grid:RefreshSelectedState()
        end
    end
end

function XUiFavorabilityLineRoomCharacterSelect:SetSelectedCurrChar(characterId, isSelcted)
    if not isSelcted and characterId == self.SelectedCharaterId then -- 只有点击被选择的格子，才能取消（该格子类型都是单选格子）
        self.SelectedCharaterId = nil
    end

    if isSelcted then
        self.SelectedCharaterId = characterId
    end
end

function XUiFavorabilityLineRoomCharacterSelect:SubmitSelectResult(selectData)
    -- 这个函数需要判断3种情况
    -- 1.既有old也有new：替换
    -- 2.只有new：新增
    -- 3.只有old：移除
    if  selectData.oldData and selectData.newData then --1.替换
        local newCharId = selectData.newData.Id
        local oldCharId = selectData.oldData.Id

        XDataCenter.DisplayManager.UpdatePlayerDisplayCharIdRequest(oldCharId, newCharId, function(res)
            if res.DisplayCharIdList and table.contains(res.DisplayCharIdList,newCharId) then
                local charConfig = XMVCA.XCharacter:GetCharacterTemplate(newCharId)
                local name = charConfig.Name.. "·"..charConfig.TradeName
            end
        end)
    elseif selectData.oldData and not selectData.newData then -- 2.移除
        if XPlayer.DisplayCharIdList and #XPlayer.DisplayCharIdList <= 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityNotRemoveOnlyAssist"))
            return
        end

        XNetwork.Call("RemovePlayerDisplayCharIdRequest", {CharId = selectData.oldData.Id}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(selectData.oldData.Id)
            local name = charConfig.Name.. "·"..charConfig.TradeName
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityRemoveAssistSucc", name))
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
        end)
    elseif not selectData.oldData and selectData.newData then -- 2.新增
        XDataCenter.DisplayManager.AddPlayerDisplayCharIdRequest(selectData.newData.Id)
    end
end
--endregion


--region 数据更新
function XUiFavorabilityLineRoomCharacterSelect:RefreshDynamicTable()
    self.CharaList = self:GetCharaterList()
    if not self.CharaList or not next(self.CharaList) then
        self.ImgNonePerson.gameObject:SetActiveEx(true) -- 无助理背景标签
        return
    else
        self.ImgNonePerson.gameObject:SetActiveEx(false)
    end
    self.DynamicTableCharacter:SetDataSource(self.CharaList)
    self.DynamicTableCharacter:ReloadDataASync()
end
--endregion

--region 事件
-- [监听动态列表事件]
function XUiFavorabilityLineRoomCharacterSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.CharaList[index], self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClick()
    end
end

function XUiFavorabilityLineRoomCharacterSelect:OnBtnConfirmClick()
    -- 所有变动都会记录在字典中，处理替换类组合
    local requestData={}
    local oldIndex=1
    local newIndex=1
    for i, changeData in pairs(self.ChangeCache) do
        --助理变动：移除助理
        if changeData.IsAssistant and not changeData.IsSelected then
            if not requestData[oldIndex] then requestData[oldIndex]={} end
            requestData[oldIndex].oldData=changeData
            oldIndex=oldIndex+1
        end
        
        --非助理变动：新增助理
        if not changeData.IsAssistant and changeData.IsSelected then
            if not requestData[newIndex] then requestData[newIndex]={} end
            requestData[newIndex].newData=changeData
            newIndex=newIndex+1
        end
    end
    --提交所有变动
    for i, changeData in pairs(requestData) do
        if changeData then
            self:SubmitSelectResult(changeData)
        end
    end
    
    self:Close()
end

function XUiFavorabilityLineRoomCharacterSelect:OnBtnTanchuangCloseClick()
    if not XTool.IsTableEmpty(self.ChangeCache) then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"),XUiHelper.GetText('FavorabilityCharacterSelectChangeTips'),XUiManager.DialogType.Normal,nil,function() 
            self:OnBtnConfirmClick()
        end)
    else
        self:Close()
    end
end

--点击角色格子时的有效性判定（数目是否超限）
function XUiFavorabilityLineRoomCharacterSelect:OnGridClickRequest(wantSelect)
    if wantSelect then
        if self.Count<CS.XGame.Config:GetInt("AssistantNum")-1 then
            self.Count=self.Count+1
            return true
        else
            XUiManager.TipText('FavorabilityCharacterSelectOverflowTips')
            return false
        end
    else
        self.Count=self.Count-1
        return true
    end
end
--endregion