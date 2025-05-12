local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSceneRandomSetting : XLuaUi
local XUiSceneRandomSetting = XLuaUiManager.Register(XLuaUi, "UiSceneRandomSetting")

function XUiSceneRandomSetting:OnAwake()
    self.GridAssistantDic = {}
    self.CurSelectBackgroundData = nil
    self:InitButton()
    self:InitDynamicTable()

    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshByServer, self)
end

function XUiSceneRandomSetting:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.ToggleSceneFashion, self.OnToggleSceneFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSelectAllFashion, self.OnBtnSelectAllFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClick)
end

function XUiSceneRandomSetting:OnBtnBackClick()
    if self:ShowUnSaveTip(handler(self, self.Close), handler(self, self.Close), nil, CS.XTextManager.GetText("StrongholdQuickDeploySave"), CS.XTextManager.GetText("StrongholdQuickDeployBack")) then
        return
    end
    self:Close()
end

function XUiSceneRandomSetting:OnBtnMainUiClick()
    if self:ShowUnSaveTip(XLuaUiManager.RunMain, XLuaUiManager.RunMain, nil, CS.XTextManager.GetText("StrongholdQuickDeploySave"), CS.XTextManager.GetText("StrongholdQuickDeployBack")) then
        return
    end
    XLuaUiManager.RunMain()
end

function XUiSceneRandomSetting:OnToggleSceneFashionClick()
    if self.SwitchLock then
        return
    end
    self.SwitchLock = true

    local targetFlag = not XDataCenter.PhotographManager.GetIsBackgroundRandomFashion()
    local doFun = function ()
        XDataCenter.PhotographManager.SwitchRandomFashionRequest(targetFlag, function (res)
            self:RefreshServerButtonState()
            self:ChangeSceneSelectAndResetUploadSaveData() -- 重新刷新选择数据
            self.SwitchLock = false
        end)
    end
    if false == targetFlag  then
        if self:ShowUnSaveTip(doFun, doFun, function () self.SwitchLock = false end,
        CS.XTextManager.GetText("SaveAndClose"), CS.XTextManager.GetText("CloseDirectly")) then
            return
        else
            doFun()
        end
    else
        doFun()
    end
end

function XUiSceneRandomSetting:OnBtnSelectAllFashionClick()
    for index, grid in pairs(self.DynamicTableFashion:GetGrids()) do
        self:OnFashionGridClick(index, grid, self.BtnSelectAllFashion:GetToggleState())
    end
end

-- 刷新全选框状态(每次切换角色刷新)
function XUiSceneRandomSetting:RefreshBtnSelectAllFashionState()
    local isAllSelect = self:CheckCharIsAllFashionSelect(self.CurSelectCharId)
    self.BtnSelectAllFashion:SetButtonState(isAllSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 涂装格子被点击/记录缓存数据
function XUiSceneRandomSetting:OnFashionGridClick(index, grid, forceTarget)
    local fashionId = self.FashionList[index]
    local charData = self.RecordCharFashionSelecteRandomList[self.CurSelectCharId]
    if not charData then
        self.RecordCharFashionSelecteRandomList[self.CurSelectCharId] = {}
    end
    local targetFlag = self.RecordCharFashionSelecteRandomList[self.CurSelectCharId][fashionId]

    if forceTarget ~= nil then
        targetFlag = forceTarget
    else
        targetFlag = self.RecordCharFashionSelecteRandomList[self.CurSelectCharId][fashionId]
        targetFlag = not targetFlag
    end

    self.RecordCharFashionSelecteRandomList[self.CurSelectCharId][fashionId] = targetFlag
    grid:SetSelect(targetFlag)
end

-- 角色是否无涂装勾选
function XUiSceneRandomSetting:CheckCharIsAllFashionUnSelect(charId)
    local data = self.RecordCharFashionSelecteRandomList[charId]
    if not data then
        return true
    end

    for fashionId, flag in pairs(data) do
        if flag then
            return false
        end
    end
    return true
end

-- 角色是否全部涂装勾选
function XUiSceneRandomSetting:CheckCharIsAllFashionSelect(charId)
    local data = self.RecordCharFashionSelecteRandomList[charId]
    if not data then
        return false
    end

    -- 服务端记录的涂装数据小于真实的涂装数据，则表示该角色下有已拥有的涂装但是还没有记录数据，返回false
    if XTool.GetTableCount(data) < #self.FashionList then
        return false
    end

    for fashionId, flag in pairs(data) do
        if not flag then
            return false
        end
    end

    return true
end

function XUiSceneRandomSetting:OnBtnSaveClick(cb)
    local isBackgroundRandomFashion = XDataCenter.PhotographManager.GetIsBackgroundRandomFashion()
    if not isBackgroundRandomFashion then
        return
    end

    -- 检查数据 以下数据必须要自动处理且不能提交
    -- 1.背景下不能没有随机角色，出现该情况要自动勾选上首席助理，若首席助理没有勾选涂装，则勾上其战中涂装
    -- 2.角色下不能没有随机时装，若勾选了角色却没有勾选随机涂装，保存时自动取消该角色的勾选
    local needTips = false
    local tipText = nil
    -- 第一遍检查 将勾选了角色但是没勾选涂装的角色自动取消勾选
    for charId, flag in pairs(self.RecordCharIsRandom) do
        if self:CheckCharIsAllFashionUnSelect(charId) then
            if flag then -- 如果从被勾选到被自动取消勾选，则提示
                needTips = true
                tipText = CS.XTextManager.GetText("RandomBackgroundCurCharFashionCannotEmpty")
            end
            self.RecordCharIsRandom[charId] = false
        end
    end

    -- 第二遍检查 将没有勾选角色的背景下自动勾选上首席助理，若首席助理没有勾选涂装，则勾上其战中涂装
    local charCount = 0
    for charId, flag in pairs(self.RecordCharIsRandom) do
        if flag then
            charCount = charCount + 1
        end
    end

    if charCount <= 0 then
        local chiefAssistantId = XPlayer.DisplayCharIdList[1]
        local xCharacter = XMVCA.XCharacter:GetCharacter(chiefAssistantId)
        self.RecordCharIsRandom[chiefAssistantId] = true
        if self:CheckCharIsAllFashionUnSelect(chiefAssistantId) then
            self.RecordCharFashionSelecteRandomList[chiefAssistantId] = { [xCharacter.FashionId] = true }
        end
        needTips = true
        tipText = CS.XTextManager.GetText("RandomBackgroundAllFashionCannotEmpty")
    end
    
    if needTips then
        XUiManager.PopupLeftTip(XUiHelper.GetText("TipTitle"), tipText)
    end

    -- 提交给服务端的数据
    -- 提交给服务端的数据略有不同，角色和涂装都是勾选了才加入列表，并不会用bool值表示是否勾选
    local data = {}
    data.BackgroundId = self.CurSelectBackgroundData.BackgroundId
    local charList = {}
    for k, grid in pairs(self.GridAssistantDic) do
        if grid.IsUse then
            local charData = {}
            charData.CharId = grid.CharacterId
            charData.IsRandom = (self.RecordCharIsRandom[grid.CharacterId]) and true or false

            local fashionData = {}
            local curCharFashionRecord = self.RecordCharFashionSelecteRandomList[grid.CharacterId]
            if curCharFashionRecord then
                for fashionId, flag in pairs(curCharFashionRecord) do
                    if flag then
                        table.insert(fashionData, fashionId)
                    end
                end
            end

            charData.RandomFashions = fashionData

            -- 如果助理不编入随机且没有随机时装，则不加入
            if XTool.IsTableEmpty(charData.RandomFashions) then
            else
                table.insert(charList, charData)
            end
        end
    end
    data.RandomChars = charList

    -- 必须是函数
    if cb and type(cb) ~= 'function' then
        cb = nil
    end
    XDataCenter.PhotographManager.EditRandomBackGroundFashionRequest(data, cb)
end

function XUiSceneRandomSetting:InitDynamicTable()
    local XDynamicBackgroundGrid = require('XUi/XUiSceneSettingMain/Grid/XDynamicBackgroundGrid')
    self.DynamicTableScene = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicTableScene:SetProxy(XDynamicBackgroundGrid, self)
    self.DynamicTableScene:SetDelegate(self)
    self.DynamicTableScene:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventScene(event, index, grid)
    end)
    
    local XDynamicFashionGrid = require('XUi/XUiSceneSettingMain/Grid/XDynamicFashionGrid')
    self.DynamicTableFashion = XDynamicTableNormal.New(self.ScrollFashionList)
    self.DynamicTableFashion:SetProxy(XDynamicFashionGrid, self)
    self.DynamicTableFashion:SetDelegate(self)
    self.DynamicTableFashion:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventFashion(event, index, grid)
    end)
    self.DynamicTableFashion:GetImpl().Grid.gameObject:SetActiveEx(false)
end

function XUiSceneRandomSetting:RefreshDynamicTableScene()
    local list = XDataCenter.PhotographManager.GetRandomBackgroundPool()
    table.sort(list, function (dataA, dataB)
        return dataA.BackgroundId > dataB.BackgroundId
    end)
    self.RandomBackgroundPool = list
    if not self.CurSelectedBackgroundIndex then
        self.CurSelectedBackgroundIndex = 1
    end
    self.DynamicTableScene:SetDataSource(list)
    self.DynamicTableScene:ReloadDataASync(self.CurSelectedBackgroundIndex)
    self.CurSelectBackgroundData = list[self.CurSelectedBackgroundIndex]
end

---动态列表的事件回调
function XUiSceneRandomSetting:OnDynamicTableEventScene(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --根据索引获取指定的场景数据
        local sceneData = self.RandomBackgroundPool[index]
        local sceneId = sceneData.BackgroundId
        --更新当前元素
        grid:RefreshDisplay(sceneId)

        local selected = index == self.CurSelectedBackgroundIndex
        grid:SetSelect(selected)
        if selected then
            if grid ~= self.CurSelectedBackgroundGrid then
                self:ChangeSceneSelectAndResetUploadSaveData()
            end

            self.CurSelectedBackgroundGrid = grid
            self.CurSelectedBackgroundIndex = index
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSelectedBackgroundGrid == grid then
            return
        end

        local doFun = function ()
            if self.CurSelectedBackgroundGrid then
                self.CurSelectedBackgroundGrid:SetSelect(false)
            end
            grid:SetSelect(true)
    
            local sceneData = self.RandomBackgroundPool[index]
            self.CurSelectBackgroundData = sceneData
            self.CurSelectedBackgroundIndex = index
            self.CurSelectedBackgroundGrid = grid
            self:ChangeSceneSelectAndResetUploadSaveData()
        end

        -- 弹窗提示检测
        if self:ShowUnSaveTip(doFun, doFun, nil, CS.XTextManager.GetText("StrongholdQuickDeploySave"), CS.XTextManager.GetText("StrongholdQuickDeployBack")) then
            return
        end
        doFun()
    end
end

-- 切换场景选择，重置需要提交的保存数据
function XUiSceneRandomSetting:ChangeSceneSelectAndResetUploadSaveData()
    -- 每次切换场景时同步一次服务器记录的涂装打勾的随机数据，不能每次切角色同步，因为之后玩家要操作打勾
    self.RecordCharFashionSelecteRandomList = {}
    self.RecordCharIsRandom = {}
    for k, charaDataByServer in pairs(self.CurSelectBackgroundData.RandomChars) do
        local fashionData = {}
        for i, fashionId in pairs(charaDataByServer.RandomFashions) do
            fashionData[fashionId] = true
        end
        self.RecordCharFashionSelecteRandomList[charaDataByServer.CharId] = fashionData
        self.RecordCharIsRandom[charaDataByServer.CharId] = charaDataByServer.IsRandom
    end
    self.CopyRecordCharFashionData = XTool.Clone(self.RecordCharFashionSelecteRandomList)
    self.CopyRecordCharIsRandomData = XTool.Clone(self.RecordCharIsRandom)
    -- 刷新助理
    self:RefreshAssistant()
    -- 刷新涂装列表
    self:RefreshDynamicTableFashion()
end

-- 直接交互：目前只有切换角色选择时才会刷新
function XUiSceneRandomSetting:RefreshDynamicTableFashion()
    local fashionList = XDataCenter.FashionManager.GetCharacterOwnFashionIdList(self.CurSelectCharId)
    table.sort(fashionList, function (fashionIdA, fashionIdB)
        return fashionIdA > fashionIdB
    end)
    self.FashionList = fashionList
    self.FashionSelectIndex = 1
    self.DynamicTableFashion:SetDataSource(fashionList)
    self.DynamicTableFashion:ReloadDataASync(self.FashionSelectIndex)
end

function XUiSceneRandomSetting:OnDynamicTableEventFashion(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local fashionId = self.FashionList[index]
        grid:Refresh(fashionId)
        local isCurFashionInRandomFashionList = self.RecordCharFashionSelecteRandomList[self.CurSelectCharId] and self.RecordCharFashionSelecteRandomList[self.CurSelectCharId][fashionId]
        grid:SetSelect(isCurFashionInRandomFashionList)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnFashionGridClick(index, grid)
        self:RefreshBtnSelectAllFashionState() -- 每次手动勾选涂装刷新当前的全选按钮状态，当手动勾选完所有的涂装后，全选按钮应该也自动变成勾状态
    end
end

-- 刷新服务端交互按钮状态（保存按钮，开启关闭随机场景涂装按钮）
function XUiSceneRandomSetting:RefreshServerButtonState()
    local isBackgroundRandomFashion = XDataCenter.PhotographManager.GetIsBackgroundRandomFashion()
    self.ToggleSceneFashion:SetButtonState(isBackgroundRandomFashion and CS.UiButtonState.Select or CS.UiButtonState.Disable)
    self.BtnSave:SetButtonState(isBackgroundRandomFashion and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.PanelLock.gameObject:SetActiveEx(not isBackgroundRandomFashion)
end

function XUiSceneRandomSetting:SetSingleAssistantGridSelected(index)
    for k = 1, #self.GridAssistantDic, 1 do
        local grid = self.GridAssistantDic[k]
        grid:SetSelect(k == index)
        if k == index then
            self.CurSelectCharId = grid.CharacterId
        end
    end
    self:RefreshDynamicTableFashion()
    self:RefreshBtnSelectAllFashionState()
end

-- 直接交互：目前只有触发切换场景时才会刷新
function XUiSceneRandomSetting:RefreshAssistant()
    local XRandomSettingAssistantGrid = require('XUi/XUiSceneSettingMain/Grid/XRandomSettingAssistantGrid')

    -- 使用前清空
    if not XTool.IsTableEmpty(self.GridAssistantDic) then
        for k, grid in pairs(self.GridAssistantDic) do
            grid.GameObject:SetActiveEx(false)
            grid.IsUse = false
        end
    end

    local assistantList = XPlayer.DisplayCharIdList
    for i, id in ipairs(assistantList) do
        local grid = self.GridAssistantDic[i]
        if not grid then
            local uiGo = XUiHelper.Instantiate(self.GridAssistant, self.GridAssistant.transform.parent)
            grid = XRandomSettingAssistantGrid.New(uiGo, self)
            grid:SetClickCallBack(function (characterId)
                self:SetSingleAssistantGridSelected(i)
            end)
            grid:SetJoinClickCallBack(function (characterId, btnJoinRandom)
                self:SetSingleAssistantGridSelected(i)

                local flag = btnJoinRandom:GetToggleState()
                if self:CheckCharIsAllFashionUnSelect(characterId) and flag then
                    btnJoinRandom:SetButtonState(CS.UiButtonState.Normal)
                    XUiManager.TipMsg(CS.XTextManager.GetText("RandomBackgroundCannotJoinRandomCauseFashionUnSelect"))
                    return
                end

                self.RecordCharIsRandom[characterId] = flag
            end)
            self.GridAssistantDic[i] = grid
        end
        grid:Refresh(id, self.RecordCharIsRandom)
        grid.GameObject:SetActiveEx(true)
        grid.IsUse = true
    end
    -- 默认选择第一个
    self.GridAssistantDic[1]:OnBtnClick()
    self.CurSelectCharId = self.GridAssistantDic[1].CharacterId
    self.GridAssistant.gameObject:SetActiveEx(false)
end

function XUiSceneRandomSetting:OnEnable()
    -- 刷新场景列表 会自动刷新角色，涂装
    self:RefreshDynamicTableScene()
    self:RefreshServerButtonState()
end

-- 目前只有保存按钮会触发
function XUiSceneRandomSetting:RefreshByServer()
    -- 刷新场景触发数据刷新
    self:RefreshDynamicTableScene()
    self:ChangeSceneSelectAndResetUploadSaveData()
end


function XUiSceneRandomSetting:ShowUnSaveTip(confirmFun, cancelFun, closeFun, confirmText, cancelText)
    local isBackgroundRandomFashion = XDataCenter.PhotographManager.GetIsBackgroundRandomFashion()
    if not isBackgroundRandomFashion then
        return false
    end

    if not self.TempBtnTextData then
        self.TempBtnTextData = 
        {
            sureText =  nil,
            closeText =  nil,
        }
    end

    self.TempBtnTextData.sureText = confirmText
    self.TempBtnTextData.closeText = cancelText

    if not XTool.DeepCompare(self.RecordCharFashionSelecteRandomList, self.CopyRecordCharFashionData) or not XTool.DeepCompare(self.RecordCharIsRandom, self.CopyRecordCharIsRandomData) then
        XLuaUiManager.Open("UiDialog", nil, CS.XTextManager.GetText("Theatre3SetTeamBackTip"), XUiManager.DialogType.Normal, closeFun, function ()
            self:OnBtnSaveClick(confirmFun)
        end, self.TempBtnTextData, cancelFun)
        return true
    end

    return false
end

function XUiSceneRandomSetting:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshByServer, self)
end

return XUiSceneRandomSetting