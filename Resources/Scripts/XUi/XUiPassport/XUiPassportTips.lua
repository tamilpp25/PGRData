local XUiPassportTips = XLuaUiManager.Register(XLuaUi, "UiPassportTips")

function XUiPassportTips:OnAwake()
    self:AutoAddListener()
end

function XUiPassportTips:OnStart(rewardGoodsList, title, desc, closeCb, sureCb)
    self.Items = {}
    self.GridCommon.gameObject:SetActive(false)
    if title then
        self.TxtTitle.text = title
    end
    if desc then
        self.TxtDesc.text = desc
    end
    self.OkCallback = sureCb
    self.CancelCallback = closeCb
    self:Refresh(rewardGoodsList)
end

function XUiPassportTips:OnEnable()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Common_UiObtain)
end

-- function XUiPassportTips:AutoInitUi()
--     self.ScrView = self.Transform:Find("SafeAreaContentPane/ScrView"):GetComponent("Scrollbar")
--     self.PanelContent = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent")
--     self.GridCommon = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent/GridCommon")
--     self.BtnBack = self.Transform:Find("SafeAreaContentPane/BtnBack"):GetComponent("Button")
--     self.TxtTitle = self.Transform:Find("SafeAreaContentPane/GameObject/TxtTitle1"):GetComponent("Text")
--     self.BtnCancel = self.Transform:Find("SafeAreaContentPane/BtnCancel"):GetComponent("Button")
--     self.BtnSure = self.Transform:Find("SafeAreaContentPane/BtnSure"):GetComponent("Button")
-- end

function XUiPassportTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTongBlack, self.OnBtnSureClick)
end

function XUiPassportTips:OnBtnSureClick()
    self:Close()
    if self.OkCallback then
        self.OkCallback()
    end
end

function XUiPassportTips:Refresh(rewardGoodsList)
    rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    XUiHelper.CreateTemplates(self, self.Items, rewardGoodsList, XUiGridCommon.New, self.GridCommon, self.PanelContent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end