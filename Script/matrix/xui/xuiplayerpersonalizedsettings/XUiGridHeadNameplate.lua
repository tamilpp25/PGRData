local XUiGridHeadNameplate = XClass(XUiNode, 'XUiGridHeadNameplate')
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")

function XUiGridHeadNameplate:OnStart(rootUi)
    self._RootUi = rootUi
    self.BtnRole.CallBack = handler(self, self.OnBtnRoleClick)
    self._PanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
end

function XUiGridHeadNameplate:OnBtnRoleClick()
    self.Base:SetHeadNameplateImgRole(self.HeadNameplateId)
    self:SetSelectShow(self.Base)
    if self.Base.OldNameplateSelectGrig then
        self.Base.OldNameplateSelectGrig:SetSelectShow(self.Base)
    end
    self.Base.OldNameplateSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:ShowHeadNameplatePanel()
    self.Base:RefreshHeadNameplateDynamicTable()
end

function XUiGridHeadNameplate:UpdateGrid(NameplateCfg, parent)
    self.Base = parent
    self.HeadNameplateId = NameplateCfg.Id

    self:SetSelectShow(parent)

    self._PanelNameplate:UpdateDataById(self.HeadNameplateId)

    local isTimeLimit = not NameplateCfg:IsNamepalteForever()
    self.SelIconTime.gameObject:SetActiveEx(isTimeLimit)
end

function XUiGridHeadNameplate:SetSelectShow(parent)
    local accessor = self._RootUi or parent

    if accessor.TempHeadNameplateId == self.HeadNameplateId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if accessor.CurrHeadNameplateId == self.HeadNameplateId then
        self:ShowTxt(true)
        if not self.Base.OldNameplateSelectGrig then
            self.Base.OldNameplateSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiGridHeadNameplate:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiGridHeadNameplate:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end


function XUiGridHeadNameplate:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.MedalManager.CheckNameplateNew(self.HeadNameplateId) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        local accessor = self._RootUi or self.Base

        XDataCenter.MedalManager.SetNameplateRedPointDic(self.HeadNameplateId)
        accessor:ShowHeadNameplateRedPoint()
    end
end

return XUiGridHeadNameplate