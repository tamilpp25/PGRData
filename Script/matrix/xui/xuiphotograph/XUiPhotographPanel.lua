local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPhotographPanel = XClass(nil, "XUiPhotographPanel")
local XUiGridPhotographSceneBtn = require("XUi/XUiPhotograph/XUiGridPhotographSceneBtn")
local XUiGridPhotographCharacterBtn = require("XUi/XUiPhotograph/XUiGridPhotographCharacterBtn")
local XUiGridPhotographOtherBtn = require("XUi/XUiPhotograph/XUiGridPhotographOtherBtn")
local XUiGridPhotographPartnerBtn = require("XUi/XUiPhotograph/XUiGridPhotographPartnerBtn")
local XUiPhotographActionPanel = require("XUi/XUiPhotograph/XUiPhotographActionPanel")

local MenuBtnType = {
    Scene = 1,
    Character = 2,
    Fashion = 3,
    Action = 4,
    Partner = 5,
}

function XUiPhotographPanel:Ctor(rootUi, ui, setData, charId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.SetData = setData
    self.CurCharId = charId
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPhotographPanel:Init()
    self:InitMenuBtnGroup()
    self:InitDynamicTable()
    self.BtnPhotograph.CallBack = function () self:OnBtnPhotographClick() end
    self.BtnSynchronous.CallBack = function () self:OnBtnSynchronousClick() end
    self.BtnPhotographVertical.CallBack = function() self:OnBtnPhotographVerticalClick() end
    self.BtnHide.CallBack = function() self:OnBtnHideClick() end
    self.BtnSet.CallBack = function() self:OnBtnSetClick() end
    self.Btn.CallBack = function() self:OnBtnClick() end
    
    self.PanelTip.gameObject:SetActiveEx(false)
    self.ActionPanel = XUiPhotographActionPanel.New(self.PanelAction)
    self:UpdateViewState(not self.BtnHide:GetToggleState())
end

function XUiPhotographPanel:DefaultClick()
    self.PanelMenu:SelectIndex(self.CurMenuType or MenuBtnType.Scene)
    local data = XDataCenter.PhotographManager.GetSceneTemplateById(XDataCenter.PhotographManager.GetCurSceneId())
    self:SetInfoTextName(data.Name)
end

function XUiPhotographPanel:Show()
    self.GameObject:SetActiveEx(true)
    self:UpdateViewState(not self.BtnHide:GetToggleState())
end

function XUiPhotographPanel:Hide()
    self.GameObject:SetActiveEx(false)
    self:UpdateViewState(not self.BtnHide:GetToggleState())
end

function XUiPhotographPanel:InitMenuBtnGroup()
    self.MenuBtns = {
        self.BtnScene,
        self.BtnCharacter,
        self.BtnFashion,
        self.BtnAction,
        self.BtnPartner,
    }
    self.PanelMenu:Init(self.MenuBtns, function(index) self:OnSelectMenuBtn(index) end)
end

function XUiPhotographPanel:OnSelectMenuBtn(index, isDefault)
    if self.CurMenuType and self.CurMenuType == index then
        return
    end
    self.CurMenuType = index

    self.PanelSceneList.gameObject:SetActiveEx(false)
    self.PanelCharacterList.gameObject:SetActiveEx(false)
    self.PanelOtherList.gameObject:SetActiveEx(false)
    self.PanelPartner.gameObject:SetActiveEx(false)

    if index == MenuBtnType.Scene then
        self.PanelSceneList.gameObject:SetActiveEx(true)
        self.CurSceneIndex = XDataCenter.PhotographManager.GetSceneIndexById(XDataCenter.PhotographManager.GetCurSelectSceneId())
        --self.CurSceneIndex = 1
        self.DynamicTableScene:SetDataSource(XDataCenter.PhotographManager.GetSceneIdList())
        self.DynamicTableScene:ReloadDataASync(self.CurSceneIndex)
    elseif index == MenuBtnType.Character then
        self.PanelCharacterList.gameObject:SetActiveEx(true)
        self.DynamicTableCharacter:SetDataSource(XDataCenter.PhotographManager.GetCharacterList())
        self.CurCharIndex = XDataCenter.PhotographManager.GetCharIndexById(self.CurCharId)
        self.DynamicTableCharacter:ReloadDataASync(self.CurCharIndex)
    elseif index == MenuBtnType.Fashion then
        self.PanelOtherList.gameObject:SetActiveEx(true)
        self.FashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CurCharId)
        if not XTool.IsNumberValid(self.CurFashionIndex) then
            local char = XDataCenter.CharacterManager.GetCharacter(self.CurCharId)
            self.CurFashionIndex = XDataCenter.PhotographManager.GetFashionIndexByFashionList(char.FashionId, self.FashionList)
        end
        self.DynamicTableOther:SetDataSource(self.FashionList)
        self.DynamicTableOther:ReloadDataASync()
    elseif index == MenuBtnType.Action then
        self.PanelOtherList.gameObject:SetActiveEx(true)
        self.ActionList = XMVCA.XFavorability:GetCharacterActionById(self.CurCharId) or {}
        self.DynamicTableOther:SetDataSource(self.ActionList)
        self.DynamicTableOther:ReloadDataASync(self.CurActionIndex)
    elseif index == MenuBtnType.Partner then
        self.PanelPartner.gameObject:SetActiveEx(true)
        self.PartnerList = XDataCenter.PartnerManager.GetPartnerPhotographData()
        self.DynamicTablePartner:SetDataSource(self.PartnerList)
        self.DynamicTablePartner:ReloadDataASync(self.CurPartnerIndex or 1)
    end

    self:UpdateInfoType(index)

    self:PlayPanelListAnim(index)
end

function XUiPhotographPanel:InitDynamicTable()
    self.DynamicTableScene = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicTableScene:SetProxy(XUiGridPhotographSceneBtn)
    self.DynamicTableScene:SetDelegate(self)

    self.DynamicTableCharacter = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicTableCharacter:SetProxy(XUiGridPhotographCharacterBtn)
    self.DynamicTableCharacter:SetDelegate(self)

    self.DynamicTableOther = XDynamicTableNormal.New(self.PanelOtherList)
    self.DynamicTableOther:SetProxy(XUiGridPhotographOtherBtn)
    self.DynamicTableOther:SetDelegate(self)
    
    self.DynamicTablePartner = XDynamicTableNormal.New(self.PanelPartner)
    self.DynamicTablePartner:SetProxy(XUiGridPhotographPartnerBtn)
    self.DynamicTablePartner:SetDelegate(self)
end

function XUiPhotographPanel:OnDynamicTableEvent(event, index, grid)
    if self.CurMenuType == MenuBtnType.Scene then -- 场景按钮格子事件处理回调
        self:OnDynamicTableSceneEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Character then -- 角色按钮格子事件处理回调
        self:OnDynamicTableCharacterEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Fashion then -- 涂装按钮格子事件处理回调
        self:OnDynamicTableFashionEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Action then -- 动作按钮格子事件处理回调
        self:OnDynamicTableActionEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Partner then
        self:OnDynamicTablePartner(event, index, grid)
    end
end

function XUiPhotographPanel:OnDynamicTableSceneEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        grid:Reset()
        grid:Refrash(data)
        if self.CurSceneIndex and self.CurSceneIndex == index then
            self.CurSceneGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(data.Name)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        local isHas = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneId)
        if not isHas then
            XUiManager.TipError(sceneTemplate.LockDec)
            return
        end
        if self.CurSceneIndex and self.CurSceneIndex == index then
            return
        end
        if self.CurSceneGrid ~= nil then
            self.CurSceneGrid:SetSelect(false)
        end
        self.CurSceneGrid = grid
        self.CurSceneIndex = index
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        self:SetInfoTextName(data.Name)
        grid:OnTouched(data)
    end
end

function XUiPhotographPanel:OnDynamicTableCharacterEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        grid:Reset()
        grid:Refrash(data)
        if self.CurCharIndex and self.CurCharIndex == index then
            self.CurCharGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(data.LogName)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurCharIndex and self.CurCharIndex == index then
            return
        end
        if self.CurCharGrid ~= nil then
            self.CurCharGrid:SetSelect(false)
        end
        self.CurCharGrid = grid
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        self.CurCharId = data.Id
        self.CurCharIndex = index
        self.CurFashionIndex = nil -- 切换角色清空涂装index 再次点击涂装会重新获取index
        self:SetInfoTextName(data.LogName)
        grid:OnTouched(self.CurCharId)
    end
end

function XUiPhotographPanel:OnDynamicTableFashionEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.FashionList[index]
        grid:Reset()
        grid:RefrashFashion(data)
        if self.CurFashionIndex and self.CurFashionIndex == index then
            self.CurFashionGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(XDataCenter.FashionManager.GetFashionName(data))
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local fashionId = self.FashionList[index]
        local isHas = XDataCenter.FashionManager.CheckHasFashion(fashionId)
        if not isHas then
            XUiManager.TipError(CS.XTextManager.GetText("PhotoModeNoFashion"))
            return
        end
        local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
        if status == XDataCenter.FashionManager.FashionStatus.Lock then
            XUiManager.TipText("FashionNoGet")
            return
        end
        if self.CurFashionIndex and self.CurFashionIndex == index then
            return
        end
        if self.CurFashionGrid ~= nil then
            self.CurFashionGrid:SetSelect(false)
        end
        self.CurFashionGrid = grid
        self.CurFashionIndex = index
        self:SetInfoTextName(XDataCenter.FashionManager.GetFashionName(fashionId))
        grid:OnFashionTouched(self.CurCharId, self.FashionList[index])
    end
end

function XUiPhotographPanel:OnDynamicTableActionEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActionList[index]
        local charData = XDataCenter.PhotographManager.GetCharacterDataById(self.CurCharId)
        grid:Reset()
        grid:RefrashAction(data, charData)
        if self.CurActionIndex and self.CurActionIndex == index then
            self.CurActionGrid = grid
            grid:SetSelect(true)
        end
        self:SetInfoTextName()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local tryFashionId = self.RootUi.SelectFashionId
        local trySceneId = self.RootUi.CurrSeleSceneId
        local isHas = XMVCA.XFavorability:CheckTryCharacterActionUnlock(self.ActionList[index], XDataCenter.PhotographManager.GetCharacterDataById(self.CurCharId).TrustLv, tryFashionId, trySceneId)
        if not isHas then
            XUiManager.TipError(self.ActionList[index].config.ConditionDescript)
            return
        end
        if self.CurActionGrid ~= nil then
            self.CurActionGrid:SetSelect(false)
            if self.CurActionGrid ~= grid then
                self.RootUi.SignBoardPlayer:Stop(true)
            end
        end
        self.RootUi:PlayAnimation("PanelActionEnable")
        self.CurActionIndex = index
        self.CurActionGrid = grid
        self:SetInfoTextName(self.ActionList[index].config.Name)
        self.ActionPanel:SetTxtTitle(self.ActionList[index].config.Name)
        grid:OnActionTouched(self.ActionList[index])
    end
end

function XUiPhotographPanel:OnDynamicTablePartner(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local selected = self.CurPartnerIndex == index
        grid:Refresh(self.PartnerList[index], selected)
        if self.CurPartnerIndex and selected then
            self.CurPartnerGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridPartnerClick(grid, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if XTool.IsNumberValid(self.CurPartnerIndex) then
            return
        end
        local grids = self.DynamicTablePartner:GetGrids()
        local idx = 1
        self:OnGridPartnerClick(grids[idx], idx)
    end
end

function XUiPhotographPanel:OnGridPartnerClick(grid, index)
    if index == self.CurPartnerIndex then 
        return 
    end
    
    local state = grid:OnClickGrid()
    if not state then
        XUiManager.TipText("PhotoModePartnerLocked")
        return
    end
    if self.CurPartnerGrid then
        self.CurPartnerGrid:Select(false)
    end
    self.CurPartnerGrid = grid
    self.CurPartnerIndex = index
    self:SetInfoTextName(self.CurPartnerGrid:GetName())
end

function XUiPhotographPanel:OnBtnPhotographClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographBtnPhotograph)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_PHOTOGRAPH)
end

function XUiPhotographPanel:OnBtnPhotographVerticalClick()
    if XDataCenter.UiPcManager.IsPc() then
        return
    end
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographBtnPhotographVertical)
    RunAsyn(function()
        local fashionId = self.RootUi.SelectFashionId
        if not XTool.IsNumberValid(fashionId) then
            local char = XDataCenter.CharacterManager.GetCharacter(self.CurCharId)
            fashionId = char.FashionId
        end
        local tmpOrientation = CS.UnityEngine.Screen.orientation
        CS.UnityEngine.Screen.orientation = CS.UnityEngine.ScreenOrientation.Portrait
        CS.XResolutionManager.IsLandscape = false
        XLuaUiManager.Open("UiPhotographPortrait", tmpOrientation, self.CurCharId, fashionId, self.RootUi)
        local tmpIndex = self.CurMenuType
        self.CurMenuType = nil
        local signal, charId, newFashionId, oldCharId = XLuaUiManager.AwaitSignal("UiPhotographPortrait", "Refresh", self)
        if signal ~= XSignalCode.SUCCESS then return end
        self.RootUi:OnPortraitChanged(charId, newFashionId, oldCharId)
        self.CurCharId = charId
        self.PanelMenu:SelectIndex(tmpIndex or MenuBtnType.Scene)
        self.FashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CurCharId)
        self.CurFashionIndex = XDataCenter.PhotographManager.GetFashionIndexById(self.CurCharId, newFashionId)
        self:RefreshBtnSynchronous()
    end)
end

function XUiPhotographPanel:OnBtnHideClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographBtnHide)
    local select = self.BtnHide:GetToggleState()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_HIDE_UI, not select)
    self:UpdateViewState(not select)
end

function XUiPhotographPanel:OnBtnSetClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographBtnSet)
    XLuaUiManager.Open("UiPhotographSet", self.SetData)
end

function XUiPhotographPanel:OnBtnClick()
    local select = self.BtnHide:GetToggleState()
    if select then
        self.BtnHide:SetButtonState(CS.UiButtonState.Normal)
        self:OnBtnHideClick()
    end
end

function XUiPhotographPanel:OnBtnSynchronousClick()
    XDataCenter.PhotographManager.ChangeDisplay(XDataCenter.PhotographManager.GetCurSelectSceneId(), self.RootUi.SelectCharacterId, self.RootUi.SelectFashionId, function ()
        self.RootUi.CurCharacterId = self.RootUi.SelectCharacterId
        self.RootUi.CurFashionId = self.RootUi.SelectFashionId
        self:RefreshBtnSynchronous()
        XUiManager.TipText("PhotoModeChangeSuccess")
    end)
end

function XUiPhotographPanel:RefreshBtnSynchronous()
    self.BtnSynchronous.gameObject:SetActiveEx(self.RootUi:CheckHasChanged() and not self.BtnHide:GetToggleState())
end

function XUiPhotographPanel:UpdateViewState(show)
    self.PanelMenu.gameObject:SetActiveEx(show)
    self.BtnSynchronous.gameObject:SetActiveEx(show)
    self.BtnSet.gameObject:SetActiveEx(show)
    self.BtnPhotographVertical.gameObject:SetActiveEx(show and not XDataCenter.UiPcManager.IsPc())
    self.PanelContent.gameObject:SetActiveEx(show)
    self:RefreshBtnSynchronous()
    self.Btn.gameObject:SetActiveEx(not show and self.GameObject.activeInHierarchy)
    --self.PanelTip.gameObject:SetActiveEx(show)
end

function XUiPhotographPanel:UpdateInfoType(btnType)
    local isAction = btnType == MenuBtnType.Action
    self.TxtAction.gameObject:SetActiveEx(isAction)
    self.TxtScene.gameObject:SetActiveEx(btnType == MenuBtnType.Scene)
    self.TxTFashion.gameObject:SetActiveEx(btnType == MenuBtnType.Fashion)
    self.TxTCharacter.gameObject:SetActiveEx(btnType == MenuBtnType.Character)
    self.TxTPartner.gameObject:SetActiveEx(btnType == MenuBtnType.Partner)
    self.ActionPanel:SetViewState(isAction)
    local isPlaying = self.RootUi.SignBoardPlayer.Status == 1 or self.RootUi.SignBoardPlayer.Status == 3
    self:RefreshActionPanel(isPlaying, self.RootUi.SignBoardActionId ~= nil)
    if not isAction then
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE, false)
    end
end

function XUiPhotographPanel:RefreshActionPanel(isPlaying, cacheAnim)
    self.ActionPanel:Refresh(isPlaying, cacheAnim)
    self.ActionPanel:SetBtnPlayState(self.RootUi.SignBoardPlayer.Status == 3)
end

function XUiPhotographPanel:ClearActionCache()
    self.CurActionIndex = nil
    self.CurActionGrid = nil
end

function XUiPhotographPanel:SetInfoTextName(textName)
    if not textName or textName == "" then
        self.TxtName.text = CSXTextManagerGetText("PhotoModeNotChooseText")
        return
    end

    self.TxtName.text = textName
end

function XUiPhotographPanel:PlayPanelListAnim(menuBtnType)
    self.RootUi:PlayAnimation("Qiehuan")
    --if menuBtnType == MenuBtnType.Scene then
        --self.RootUi:PlayAnimation("PanelSceneListEnable")
    --elseif menuBtnType == MenuBtnType.Character then
        --self.RootUi:PlayAnimation("PanelCharacterListEnable")
    --elseif menuBtnType == MenuBtnType.Fashion or menuBtnType == MenuBtnType.Action then
        --self.RootUi:PlayAnimation("PanelOtherListEnable")
    --end
    if menuBtnType == MenuBtnType.Action then
        self.RootUi:PlayAnimation("PanelActionEnable")
    end
end

return XUiPhotographPanel