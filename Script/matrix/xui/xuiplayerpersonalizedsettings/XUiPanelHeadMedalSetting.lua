local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--==========================================XUiPanelHeadMedalInfo==================================
local XUiPanelHeadMedalInfo = XClass(XUiNode, 'XUiPanelHeadMedalInfo')

function XUiPanelHeadMedalInfo:OnStart()
    self.BtnHeadSure.CallBack = handler(self, self.OnBtnHeadMedalSureClick)
end

-- 用于访问顶层Ui，主要是方便访问公共变量，后续如果该系统进行MVCA改造后，界面公共变量可转移到Control，直接访问Control
function XUiPanelHeadMedalInfo:SetRootUi(root)
    self._RootUi = root
    self.BtnHeadCancel.CallBack = handler(self._RootUi, self._RootUi.OnBtnCancelClick)
end

function XUiPanelHeadMedalInfo:OnBtnHeadMedalSureClick()
    if self.BtnHeadSure.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self._RootUi.TempHeadMedalId ~= nil then
        local id = 0
        if self.BtnType == XHeadPortraitConfigs.BtnState.Use then
            id = self._RootUi.TempHeadMedalId
        end
        
        -- 判断是否已过期
        if XTool.IsNumberValid(id) then
            local medalData = XDataCenter.MedalManager.GetMedalById(id)
            local medalCfg = XMedalConfigs.GetMeadalConfigById(id)
            if medalCfg.KeepTime > 0 then
                if medalData == nil or medalData.IsExpired or XDataCenter.MedalManager.CheckMedalIsExpired(id) then
                    XUiManager.TipText('MedalOverdue')
                    return
                end
            end
        end

        XPlayer.ChangeMedal(id, function()
            if id == 0 then
                self._RootUi.TempHeadMedalId = 0
                XUiManager.TipText("HeadFrameNonUsecomplete")
            else
                XUiManager.TipText("HeadFrameUsecomplete")
            end
            self.Parent:RefreshHeadMedalDynamicTable()
            self.Parent:SetHeadMedalImgRole(self._RootUi.TempHeadMedalId)
            self.Parent:ShowHeadMedalPanel()
        end)
        
    end
    XEventManager.DispatchEvent(XEventId.EVENT_HEAD_PORTRAIT_RESETINFO)
end

function XUiPanelHeadMedalInfo:SetHeadMedalDesc(info, Id ,curId)
    local isValid = false
    local medalData = XDataCenter.MedalManager.GetMedalById(Id)

    if medalData then
        isValid = not medalData.IsLock
    else
        isValid = false
    end
    
    self.TxtHeadName.text = info.Name
    self.TxtDecs.text = info.Desc
    self.TxtDecs.transform.anchoredPosition = Vector2.zero
    self.TxtCondition.text = info.UnlockDesc

    if Id == curId then
        self.PanelTxt2.gameObject:SetActiveEx(true)
        self.TxtCondition2.text = XTime.TimestampToGameDateTimeString(medalData.Time)
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameNonUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.NonUse
    elseif not isValid then
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Disable)
        self.BtnIsUsing.gameObject:SetActiveEx(false)
        self.BtnIsNotHave.gameObject:SetActiveEx(true)
        self.PanelTxt2.gameObject:SetActiveEx(false)
    else
        self.PanelTxt2.gameObject:SetActiveEx(true)
        self.TxtCondition2.text = XTime.TimestampToGameDateTimeString(medalData.Time)
        self.BtnHeadSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHeadSure:SetName(CS.XTextManager.GetText("HeadFrameUse"))
        self.BtnType = XHeadPortraitConfigs.BtnState.Use
    end
end
--===========================================XUiPanelHeadMedalSetting===============================
local XUiPanelHeadMedalSetting = XClass(XUiNode, 'XUiPanelHeadMedalSetting')
local XUiGridHeadMedal = require('XUi/XUiPlayerPersonalizedSettings/XUiGridHeadMedal')

function XUiPanelHeadMedalSetting:OnStart(headMedal)
    self._PanelHeadMedalInfo = XUiPanelHeadMedalInfo.New(headMedal, self)
    self._PanelHeadMedalInfo:SetRootUi(self.Parent)
    self._PanelHeadMedalInfo:Close()
    self:InitHeadMedalDynamicTable()
end

function XUiPanelHeadMedalSetting:OnDisable()
    self._PanelHeadMedalInfo:Close()
    self:ShowPreviewHeadMedalInPreviewPanelOnly()
    self.Parent.TempHeadMedalId = 0
end

function XUiPanelHeadMedalSetting:InitHeadMedalDynamicTable()
    self._HeadMedalDynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._HeadMedalDynamicTable:SetProxy(XUiGridHeadMedal, self, self.Parent)
    self._HeadMedalDynamicTable:SetDelegate(self)
    self.Parent.GridHeadMedal.gameObject:SetActiveEx(false)
end

function XUiPanelHeadMedalSetting:ShowPreviewHeadMedal()
    -- 判断当前佩戴是否过期
    if XTool.IsNumberValid(XPlayer.CurrMedalId) and not XDataCenter.MedalManager.CheckMedalIsExpired(XPlayer.CurrMedalId) then
        self.Parent.CurrHeadMedalId = XPlayer.CurrMedalId
    else
        self.Parent.CurrHeadMedalId = 0
    end
    self.Parent.OldMedalSelectGrig = nil
    local IsTrueHeadMedal =self:SetHeadMedalImgRole(self.Parent.TempHeadMedalId ~= 0 and self.Parent.TempHeadMedalId or self.Parent.CurrHeadMedalId)
    return IsTrueHeadMedal
end

function XUiPanelHeadMedalSetting:ShowPreviewHeadMedalInPreviewPanelOnly()
    -- 判断当前佩戴是否过期
    if XTool.IsNumberValid(XPlayer.CurrMedalId) and not XDataCenter.MedalManager.CheckMedalIsExpired(XPlayer.CurrMedalId) then
        self.Parent.CurrHeadMedalId = XPlayer.CurrMedalId
    else
        self.Parent.CurrHeadMedalId = 0
    end
    
    self.Parent.OldMedalSelectGrig = nil

    if not XTool.IsNumberValid(self.Parent.CurrHeadMedalId) then
        self.Parent.ImgMedalIcon.gameObject:SetActiveEx(false)
        return
    end
    local cfg = XMedalConfigs.GetMeadalConfigById(self.Parent.CurrHeadMedalId)

    if not cfg then
        self.Parent.ImgMedalIcon.gameObject:SetActiveEx(false)
        return
    end
    self.Parent.ImgMedalIcon.gameObject:SetActiveEx(true)
    self.Parent.ImgMedalIcon:SetRawImage(cfg.MedalImg)

    XDataCenter.MedalManager.LoadMedalEffect(self.Parent, self.Parent.ImgMedalIcon, self.Parent.CurrHeadMedalId)

    if (cfg ~= nil) then
        self.Parent.TempHeadMedalId = self.Parent.CurrHeadMedalId
    end
end

function XUiPanelHeadMedalSetting:ShowHeadMedalPanel()
    local isTrueHeadMedal = self:ShowPreviewHeadMedal()

    if isTrueHeadMedal then
        self._PanelHeadMedalInfo:Open()
        self.Parent._PanelNoSelectInfo:Close()
    else
        self.Parent._PanelNoSelectInfo:Open()
        self._PanelHeadMedalInfo:Close()
        self.Parent._PanelNoSelectInfo:RefreshData(CS.XTextManager.GetText("HeadFrameNoSelectTitle"), CS.XTextManager.GetText("HeadMedalNoSelectHint"))
    end

end

function XUiPanelHeadMedalSetting:SetupHeadMedalDynamicTable(index)
    self.PageDatas = XDataCenter.MedalManager.GetMedals()
    self._HeadMedalDynamicTable:SetDataSource(self.PageDatas)
    self._HeadMedalDynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelHeadMedalSetting:RefreshHeadMedalDynamicTable()
    -- 判断当前佩戴是否过期
    if XTool.IsNumberValid(XPlayer.CurrMedalId) and not XDataCenter.MedalManager.CheckMedalIsExpired(XPlayer.CurrMedalId) then
        self.Parent.CurrHeadMedalId = XPlayer.CurrMedalId
    else
        self.Parent.CurrHeadMedalId = 0
    end
    self._HeadMedalDynamicTable:ReloadDataSync()
end

function XUiPanelHeadMedalSetting:SetHeadMedalRedPoint(grid)
    grid:ShowRedPoint(XDataCenter.MedalManager.CheckIsNewMedalById(grid.HeadMedalId, XMedalConfigs.MedalType.Normal))
end

function XUiPanelHeadMedalSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
        self:SetHeadMedalRedPoint(grid)
    end
end

function XUiPanelHeadMedalSetting:SetHeadMedalImgRole(medalId)
    if not XTool.IsNumberValid(medalId) then
        self.Parent.ImgMedalIcon.gameObject:SetActiveEx(false)
        return false
    end
    local cfg = XMedalConfigs.GetMeadalConfigById(medalId)

    if not cfg then
        self.Parent.ImgMedalIcon.gameObject:SetActiveEx(false)
        return false
    end
    self.Parent.ImgMedalIcon.gameObject:SetActiveEx(true)
    self.Parent.ImgMedalIcon:SetRawImage(cfg.MedalImg)

    XDataCenter.MedalManager.LoadMedalEffect(self.Parent, self.Parent.ImgMedalIcon, medalId)

    if (cfg ~= nil) then
        self.Parent.TempHeadMedalId = medalId
        if self.Parent.CurType == XHeadPortraitConfigs.HeadType.Medal then
            self.Parent:SetHeadTime(cfg,self._PanelHeadMedalInfo, medalId)
            self._PanelHeadMedalInfo:SetHeadMedalDesc(cfg, medalId, self.Parent.CurrHeadMedalId)
        end
        return true
    else
        return false
    end
end

return XUiPanelHeadMedalSetting