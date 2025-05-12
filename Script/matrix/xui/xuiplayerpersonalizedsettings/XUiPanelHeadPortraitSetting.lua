local XUiPanelHeadPortrait = require("XUi/XUiPlayer/XUiPanelHeadPortrait")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--==========================================XUiPanelHeadPortraitInfo==================================
local XUiPanelHeadPortraitInfo = XClass(XUiNode, 'XUiPanelHeadPortraitInfo')

function XUiPanelHeadPortraitInfo:OnStart()
    self.BtnHeadSure.CallBack = handler(self, self.OnBtnHeadPortraitSureClick)
end

-- 用于访问顶层Ui，主要是方便访问公共变量，后续如果该系统进行MVCA改造后，界面公共变量可转移到Control，直接访问Control
function XUiPanelHeadPortraitInfo:SetRootUi(root)
    self._RootUi = root
    self.BtnHeadCancel.CallBack = handler(self._RootUi, self._RootUi.OnBtnCancelClick)
end

function XUiPanelHeadPortraitInfo:OnBtnHeadPortraitSureClick()
    if self.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self._RootUi.TempHeadPortraitId ~= nil then
        if self._RootUi.TempHeadPortraitId == XPlayer.CurrHeadPortraitId then
            return
        end

        XDataCenter.HeadPortraitManager.ChangeHeadPortrait(self._RootUi.TempHeadPortraitId, function()
            self.Parent:RefreshHeadPortraitDynamicTable()
            self.Parent:SetHeadPortraitImgRole(self._RootUi.TempHeadPortraitId)
            XUiManager.TipText("HeadPortraitUsecomplete")
        end)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelHeadPortraitInfo:SetHeadPortraitDesc(info, Id ,curId)
    local isValid = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(Id)

    self.TxtHeadName.text = info.Name
    self.TxtDecs.text = info.WorldDesc
    self.TxtDecs.transform.anchoredPosition = Vector2.zero
    self.TxtCondition.text = info.LockDesc

    if Id == curId then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(true)
        self.BtnIsNotHave.gameObject:SetActiveEx(false)
    elseif not isValid then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(false)
        self.BtnIsNotHave.gameObject:SetActiveEx(true)
    else
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
    end
end


--===========================================XUiPanelHeadPortraitSetting===============================
local XUiPanelHeadPortraitSetting = XClass(XUiNode, 'XUiPanelHeadPortraitSetting')
local XUiGridHeadPortrait = require("XUi/XUiPlayer/XUiGridHeadPortrait")

function XUiPanelHeadPortraitSetting:OnStart(headProtraitInfo)
    self._PanelHeadProtraitInfo = XUiPanelHeadPortraitInfo.New(headProtraitInfo, self)
    self._PanelHeadProtraitInfo:SetRootUi(self.Parent)
    self:InitHeadPortraitDynamicTable()
end

function XUiPanelHeadPortraitSetting:OnDisable()
    self._PanelHeadProtraitInfo:Close()
    self:ShowPreviewHeadPortraitInPreviewPanelOnly()
    self.Parent.TempHeadPortraitId = 0
end

function XUiPanelHeadPortraitSetting:InitHeadPortraitDynamicTable()
    self._HeadPortraitDynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._HeadPortraitDynamicTable:SetProxy(XUiGridHeadPortrait, self, self.Parent)
    self._HeadPortraitDynamicTable:SetDelegate(self)
    self.Parent.GridHeadPortrait.gameObject:SetActiveEx(false)
end

function XUiPanelHeadPortraitSetting:ShowPreviewHeadPortrait()
    self.Parent.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self.Parent.OldPortraitSelectGrig = nil
    local IsTrueHeadPortrait = self:SetHeadPortraitImgRole(self.Parent.TempHeadPortraitId ~= 0 and self.Parent.TempHeadPortraitId or self.Parent.CurrHeadPortraitId)
    return IsTrueHeadPortrait
end

--只是设置个预览图片，不做其他逻辑
function XUiPanelHeadPortraitSetting:ShowPreviewHeadPortraitInPreviewPanelOnly()
    self.Parent.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self.Parent.OldPortraitSelectGrig = nil
    local info = XPlayerManager.GetHeadPortraitInfoById(self.Parent.CurrHeadPortraitId)
    XUiPlayerHead.InitPortrait(self.Parent.CurrHeadPortraitId, nil, self.Parent.Head)
    if (info ~= nil) then
        self.Parent.TempHeadPortraitId = self.Parent.CurrHeadPortraitId
    end
end

function XUiPanelHeadPortraitSetting:ShowHeadPortraitPanel()
    local isTrueHeadPortrait = self:ShowPreviewHeadPortrait()
    

    if not isTrueHeadPortrait then
        self.Parent._PanelNoSelectInfo:Open()
        self.Parent._PanelNoSelectInfo:RefreshData(CS.XTextManager.GetText("HeadFrameNoSelectTitle"), CS.XTextManager.GetText("HeadPortraitNoSelectHint"))
    else
        self.Parent._PanelNoSelectInfo:Close()
        self._PanelHeadProtraitInfo:Open()
    end
end

function XUiPanelHeadPortraitSetting:SetupHeadPortraitDynamicTable(index)
    self.PageDatas = XDataCenter.HeadPortraitManager.GetUnlockedHeadPortraitIds(XHeadPortraitConfigs.HeadType.HeadPortrait)
    self._HeadPortraitDynamicTable:SetDataSource(self.PageDatas)
    self._HeadPortraitDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelHeadPortraitSetting:RefreshHeadPortraitDynamicTable()
    self.Parent.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId or 0
    self._HeadPortraitDynamicTable:ReloadDataSync()
end

function XUiPanelHeadPortraitSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadPortraitRedPoint(grid)
    end
end

function XUiPanelHeadPortraitSetting:SetHeadPortraitRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.HeadPortraitManager.CheckIsNewHeadPortraitById(grid.HeadPortraitId), false)
end

function XUiPanelHeadPortraitSetting:SetHeadPortraitImgRole(headId)
    local info = XPlayerManager.GetHeadPortraitInfoById(headId)
    XUiPlayerHead.InitPortrait(headId, nil, self.Parent.Head)
    if (info ~= nil) then
        self.Parent.TempHeadPortraitId = headId
        if self.Parent.CurType == XHeadPortraitConfigs.HeadType.HeadPortrait then
            self.Parent:SetHeadTime(info, self._PanelHeadProtraitInfo, headId)
            self._PanelHeadProtraitInfo:SetHeadPortraitDesc(info, headId, self.Parent.CurrHeadPortraitId)
        end
        return true
    else
        return false
    end
end

return XUiPanelHeadPortraitSetting